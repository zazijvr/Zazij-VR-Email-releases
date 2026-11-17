#!/usr/bin/env bash
# Instalace ZažijVR Email jako AppImage (Linux). Další verze si aplikace stahuje sama.
#
#   scripts/install-appimage.sh                  stáhne poslední verzi z GitHubu
#   scripts/install-appimage.sh cesta.AppImage   nainstaluje místní soubor
#
# Bez sudo – vše jde do domovské složky. Aplikace musí být ve složce, kam smí uživatel
# zapisovat (~/Applications), jinak by se při aktualizaci nemohla sama vyměnit.
set -euo pipefail

RELEASES_REPO="zazijvr/Zazij-VR-Email-releases"
APP_DIR="$HOME/Applications"
APP="$APP_DIR/ZazijVR-Email.AppImage"
ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
DESKTOP="$HOME/.local/share/applications/zazijvr-email.desktop"

mkdir -p "$APP_DIR" "$ICON_DIR" "$(dirname "$DESKTOP")"

if [ -n "${1:-}" ]; then
  echo "📦 Instaluji $1"
  cp "$1" "$APP.new"
else
  echo "☁️  Zjišťuji poslední verzi…"
  URL=$(curl -fsSL "https://github.com/$RELEASES_REPO/releases/latest/download/latest.json" \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["platforms"]["linux-x86_64"]["url"])')
  echo "📥 Stahuji $URL"
  curl -fL --progress-bar -o "$APP.new" "$URL"
fi
chmod +x "$APP.new"
mv -f "$APP.new" "$APP"

# Ikona z AppImage
TMP=$(mktemp -d)
( cd "$TMP" && "$APP" --appimage-extract 'usr/share/icons/hicolor/*/apps/*.png' >/dev/null 2>&1 || true )
ICON_SRC=$(ls -S "$TMP"/squashfs-root/usr/share/icons/hicolor/*/apps/*.png 2>/dev/null | head -n 1 || true)
[ -n "$ICON_SRC" ] && cp "$ICON_SRC" "$ICON_DIR/zazijvr-email.png"
rm -rf "$TMP"

cat > "$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=ZažijVR Email
Comment=E-mail a kalendář ZažijVR
Exec="$APP"
Icon=zazijvr-email
StartupWMClass=zazijvr-email
Categories=Network;Email;Calendar;
Terminal=false
StartupNotify=true
EOF
command -v update-desktop-database >/dev/null && update-desktop-database "$(dirname "$DESKTOP")" >/dev/null 2>&1 || true

echo "✅ Nainstalováno do $APP – aplikaci najdete v nabídce jako „ZažijVR Email“."
if command -v pacman >/dev/null && pacman -Qq 2>/dev/null | grep -qx 'zažij-vr-email'; then
  echo "ℹ️  Starou verzi z balíčku odeberte: sudo pacman -R zažij-vr-email"
fi
