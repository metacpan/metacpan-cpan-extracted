#!/bin/bash
# bin/setup_macos.sh - macOS Setup, Infrastructure & RAM-Disk Engine for AmberDB
# Uses macOS native hdiutil, diskutil, and launchd (No external drivers required)
#
# Usage:
#   ./bin/setup_macos.sh ramdisk-start [size] [project_name]
#   ./bin/setup_macos.sh ramdisk-stop  [project_name]
#   ./bin/setup_macos.sh status
#   ./bin/setup_macos.sh cron-install
#   ./bin/setup_macos.sh cron-remove
#   ./bin/setup_macos.sh service-install
#   ./bin/setup_macos.sh service-remove

set -e

ACTION="${1:-status}"
ARG2="$2"
ARG3="$3"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Resolve project name
if [ -n "$ARG3" ]; then
    PROJECT_NAME="$ARG3"
elif [ -n "$ARG2" ] && [ "$ACTION" != "ramdisk-start" ] && [ "$ACTION" != "start" ] && [ "$ACTION" != "mount" ]; then
    PROJECT_NAME="$ARG2"
else
    PROJECT_NAME="$(basename "$PROJECT_DIR")"
fi

VOLUME_NAME="AmberDB_RAM"
VOLUME_PATH="/Volumes/$VOLUME_NAME"
if [ -d "$PROJECT_DIR/table" ]; then
    DB_DIR="$PROJECT_DIR"
    APP_DIR="$(dirname "$PROJECT_DIR")"
elif [ -d "$PROJECT_DIR/dbstore" ]; then
    DB_DIR="$PROJECT_DIR/dbstore"
    APP_DIR="$PROJECT_DIR"
elif [ -d "$PROJECT_DIR/dbase" ]; then
    DB_DIR="$PROJECT_DIR/dbase"
    APP_DIR="$PROJECT_DIR"
else
    DB_DIR="$PROJECT_DIR"
    APP_DIR="$PROJECT_DIR"
fi

if [ "$PROJECT_NAME" == "dbstore" ] || [ "$PROJECT_NAME" == "dbase" ]; then
    PROJECT_NAME="$(basename "$APP_DIR")"
fi

USER_NAME="$4"
if [ -n "$USER_NAME" ] && [ -n "$PROJECT_NAME" ] && [ "$PROJECT_NAME" != "$USER_NAME" ] && [ "$PROJECT_NAME" != "amberdb" ]; then
    PROJECT_RAM="$VOLUME_PATH/$USER_NAME/$PROJECT_NAME"
elif [ -n "$USER_NAME" ]; then
    PROJECT_RAM="$VOLUME_PATH/$USER_NAME"
else
    PROJECT_RAM="$VOLUME_PATH/$PROJECT_NAME"
fi

LOCAL_RAM="$DB_DIR/ramdisk"
LIB_DIR="$APP_DIR/lib"
DAEMON_PL="$SCRIPT_DIR/amberdb_daemon.pl"
PLIST_LABEL="com.amberdb.$PROJECT_NAME"
PLIST_FILE="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

calc_sectors() {
    local raw="$1"
    local num=$(echo "$raw" | grep -o -E '[0-9]+')
    local unit=$(echo "$raw" | tr '[:lower:]' '[:upper:]' | grep -o -E '[MGK]')

    if [ "$unit" == "G" ]; then
        echo $(( num * 1024 * 2048 ))
    elif [ "$unit" == "K" ]; then
        echo $(( num * 2 ))
    else
        # Default MB
        echo $(( num * 2048 ))
    fi
}

# --- Action: STATUS / RAMDISK-STATUS ---
if [ "$ACTION" == "status" ] || [ "$ACTION" == "--status" ] || [ "$ACTION" == "ramdisk-status" ]; then
    echo "================================================================="
    echo " AmberDB macOS Infrastructure & RAM-Disk Status Monitor"
    echo "================================================================="
    echo "Platform:       macOS ($(sw_vers -productVersion 2>/dev/null || uname -s))"
    echo "Project Name:   $PROJECT_NAME"
    echo "Project Root:   $PROJECT_DIR"
    echo "Local RAM Path: $LOCAL_RAM"
    echo "RAM Volume:     $VOLUME_PATH"

    if [ -d "$VOLUME_PATH" ] && [ -d "$PROJECT_RAM" ]; then
        echo "RAM-Disk:       ACTIVE (Mounted on $PROJECT_RAM)"
    elif [ -d "$VOLUME_PATH" ]; then
        echo "RAM-Disk:       VOLUME ACTIVE ($VOLUME_PATH mounted, project $PROJECT_NAME not initialized)"
    else
        echo "RAM-Disk:       INACTIVE (Running on local storage)"
    fi

    # Check launchd watchdog
    if crontab -l 2>/dev/null | grep -q "amberdb_daemon.pl watchdog"; then
        echo "Cron Watchdog:  REGISTERED (crontab)"
    elif [ -f "$HOME/Library/LaunchAgents/com.amberdb.$PROJECT_NAME.watchdog.plist" ]; then
        echo "Cron Watchdog:  REGISTERED (launchd agent)"
    else
        echo "Cron Watchdog:  NOT REGISTERED"
    fi

    # Check launchd background daemon
    if [ -f "$PLIST_FILE" ]; then
        echo "Launchd Service: INSTALLED ($PLIST_LABEL)"
    else
        echo "Launchd Service: NOT INSTALLED"
    fi

    echo "================================================================="
    exit 0
fi

# --- Action: CRON-INSTALL ---
if [ "$ACTION" == "cron-install" ] || [ "$ACTION" == "cron" ]; then
    echo "[SETUP] Configuring cron watchdog for AmberDB ($PROJECT_NAME)..."
    PERL_BIN="$(which perl 2>/dev/null || echo "/usr/bin/perl")"

    (crontab -l 2>/dev/null | grep -v "amberdb_daemon.pl watchdog" ; echo "*/5 * * * * $PERL_BIN -I$LIB_DIR $DAEMON_PL watchdog --dbase_dir $PROJECT_DIR >/dev/null 2>&1") | crontab -
    echo "[SUCCESS] Watchdog scheduled in crontab (every 5 minutes)."
    exit 0
fi

# --- Action: CRON-REMOVE ---
if [ "$ACTION" == "cron-remove" ]; then
    echo "[SETUP] Removing cron watchdog for AmberDB ($PROJECT_NAME)..."
    if crontab -l 2>/dev/null | grep -q "amberdb_daemon.pl watchdog"; then
        (crontab -l 2>/dev/null | grep -v "amberdb_daemon.pl watchdog") | crontab -
        echo "[SUCCESS] Removed watchdog from crontab."
    fi
    exit 0
fi

# --- Action: SERVICE-INSTALL ---
if [ "$ACTION" == "service-install" ] || [ "$ACTION" == "service" ]; then
    echo "[SETUP] Installing macOS LaunchAgent '$PLIST_LABEL'..."
    mkdir -p "$HOME/Library/LaunchAgents"

    PERL_BIN="$(which perl 2>/dev/null || echo "/usr/bin/perl")"

    cat <<EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PERL_BIN</string>
        <string>-I$LIB_DIR</string>
        <string>$DAEMON_PL</string>
        <string>run</string>
        <string>--dbase_dir</string>
        <string>$PROJECT_DIR</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$PROJECT_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/$PLIST_LABEL.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/$PLIST_LABEL.err</string>
</dict>
</plist>
EOF

    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    launchctl load "$PLIST_FILE"

    echo "[SUCCESS] macOS LaunchAgent installed and loaded!"
    echo "  Plist  : $PLIST_FILE"
    echo "  Logs   : /tmp/$PLIST_LABEL.log"
    exit 0
fi

# --- Action: SERVICE-REMOVE ---
if [ "$ACTION" == "service-remove" ]; then
    echo "[SETUP] Removing macOS LaunchAgent '$PLIST_LABEL'..."
    if [ -f "$PLIST_FILE" ]; then
        launchctl unload "$PLIST_FILE" 2>/dev/null || true
        rm -f "$PLIST_FILE"
        echo "[SUCCESS] LaunchAgent removed."
    fi
    exit 0
fi

# --- Action: STOP / RAMDISK-STOP / UNMOUNT ---
if [ "$ACTION" == "stop" ] || [ "$ACTION" == "--stop" ] || [ "$ACTION" == "ramdisk-stop" ] || [ "$ACTION" == "unmount" ]; then
    echo "[RAM-DISK] Stopping AmberDB RAM-Disk for project '$PROJECT_NAME'..."

    # 1. Remove local symlink and restore empty dirs
    if [ -L "$LOCAL_RAM" ]; then
        rm -f "$LOCAL_RAM"
        mkdir -p "$LOCAL_RAM"/{tables,config,schema,lock,pids}
    fi

    # 2. Clean project folder from RAM disk
    if [ -d "$PROJECT_RAM" ]; then
        rm -rf "$PROJECT_RAM"
    fi

    # 3. Detach volume if no other project folders remain
    if [ -d "$VOLUME_PATH" ]; then
        REMAINING=$(find "$VOLUME_PATH" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | grep -v "^\." | wc -l | tr -d ' ')
        if [ "$REMAINING" -eq "0" ]; then
            echo "[RAM-DISK] No other projects active. Detaching RAM-Disk $VOLUME_PATH..."
            hdiutil detach "$VOLUME_PATH" -force 2>/dev/null || true
        fi
    fi

    echo "[SUCCESS] macOS RAM-Disk unmounted and restored to local storage for '$PROJECT_NAME'."
    exit 0
fi

# --- Action: START / RAMDISK-START / MOUNT ---
if [ "$ACTION" == "start" ] || [ "$ACTION" == "--start" ] || [ "$ACTION" == "ramdisk-start" ] || [ "$ACTION" == "mount" ]; then
    SIZE_RAW="${ARG2:-512M}"
    echo "[RAM-DISK] Initializing macOS APFS RAM-Disk for '$PROJECT_NAME' ($SIZE_RAW)..."

    SECTORS=$(calc_sectors "$SIZE_RAW")

    # 1. Mount RAM disk block device if volume not already present
    if [ ! -d "$VOLUME_PATH" ]; then
        echo "[RAM-DISK] Allocating $SECTORS sectors via hdiutil..."
        RAMDEV=$(hdiutil attach -nomount "ram://$SECTORS" | tr -d '[:space:]')

        echo "[RAM-DISK] Formatting $RAMDEV with APFS as '$VOLUME_NAME'..."
        diskutil eraseVolume APFS "$VOLUME_NAME" "$RAMDEV" >/dev/null 2>&1 || \
        diskutil eraseVolume HFS+ "$VOLUME_NAME" "$RAMDEV" >/dev/null
    fi

    # 2. Create isolated project folder on RAM volume
    mkdir -p "$PROJECT_RAM"/{table,config,schema,lock,pids}

    # 3. Link dbstore/ramdisk to /Volumes/AmberDB_RAM/<ProjectName>
    if [ -e "$LOCAL_RAM" ]; then
        rm -rf "$LOCAL_RAM"
    fi
    mkdir -p "$(dirname "$LOCAL_RAM")"
    ln -sfn "$PROJECT_RAM" "$LOCAL_RAM"

    echo ""
    echo "[SUCCESS] macOS RAM-Disk is ready and configured for AmberDB!"
    echo "  Project:      $PROJECT_NAME"
    echo "  RAM Storage:  $PROJECT_RAM"
    echo "  Local Link:   $LOCAL_RAM -> $PROJECT_RAM"
    echo "  |-- table/    (DB & Index acceleration files)"
    echo "  |-- config/   (Compiled config files)"
    echo "  |-- schema/   (Table & DBase schema files)"
    echo "  |-- lock/     (Flock lock files)"
    echo "  \\-- pids/    (Process & mutex files)"
    echo ""
    exit 0
fi

echo "Unknown action: $ACTION"
echo "Usage: $0 {ramdisk-start|ramdisk-stop|status|cron-install|cron-remove|service-install|service-remove} [args]"
exit 1
