#!/bin/bash
# bin/setup_linux.sh - Linux Setup, Infrastructure & RAM-Disk Engine for AmberDB
# Handles Linux tmpfs RAM-disk, crontab/systemd watchdog, and permissions.
# Run with sudo / root privileges (or via amberdb_setup.pl)
#
# Usage:
#   sudo ./bin/setup_linux.sh ramdisk-start [size] [project_name]
#   sudo ./bin/setup_linux.sh ramdisk-stop  [project_name]
#   ./bin/setup_linux.sh status
#   sudo ./bin/setup_linux.sh cron-install [user]
#   sudo ./bin/setup_linux.sh cron-remove
#   sudo ./bin/setup_linux.sh service-install [user]
#   sudo ./bin/setup_linux.sh service-remove
#   sudo ./bin/setup_linux.sh perms [user]

set -e

ACTION="${1:-status}"
ARG2="$2"
ARG3="$3"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Resolve project name
if [ -n "$ARG3" ]; then
    PROJECT_NAME="$ARG3"
elif [ -n "$ARG2" ] && [ "$ACTION" != "ramdisk-start" ] && [ "$ACTION" != "start" ] && [ "$ACTION" != "mount" ] && [ "$ACTION" != "cron-install" ] && [ "$ACTION" != "service-install" ] && [ "$ACTION" != "perms" ]; then
    PROJECT_NAME="$ARG2"
else
    PROJECT_NAME="$(basename "$PROJECT_DIR")"
fi

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

LOCAL_RAM="$DB_DIR/ramdisk"
LOCK_DIR="$DB_DIR/lock"
LIB_DIR="$APP_DIR/lib"
DAEMON_PL="$SCRIPT_DIR/amberdb_daemon.pl"
SERVICE_NAME="amberdb-$PROJECT_NAME"
CRON_FILE="/etc/cron.d/amberdb-$PROJECT_NAME"

# Determine run user
RUN_USER="$SUDO_USER"
if [ -z "$RUN_USER" ]; then
    RUN_USER="$(id -un 2>/dev/null || echo "root")"
fi
if [ "$ACTION" == "cron-install" ] || [ "$ACTION" == "service-install" ] || [ "$ACTION" == "perms" ]; then
    if [ -n "$ARG2" ]; then
        RUN_USER="$ARG2"
    fi
fi

# Determine ramdisk size if start
SIZE="${ARG2:-512M}"

# Root check helper
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "[ERROR] Root privileges required! Please run with sudo: sudo $0 $ACTION"
        exit 1
    fi
}

# --- Action: STATUS / RAMDISK-STATUS ---
if [ "$ACTION" == "status" ] || [ "$ACTION" == "--status" ] || [ "$ACTION" == "ramdisk-status" ]; then
    echo "================================================================="
    echo " AmberDB Linux Infrastructure & RAM-Disk Status Monitor"
    echo "================================================================="
    echo "Platform:       Linux ($(uname -r 2>/dev/null || uname -s))"
    echo "Project Name:   $PROJECT_NAME"
    echo "Project Root:   $PROJECT_DIR"
    echo "RAM-Disk Path:  $LOCAL_RAM"

    if [ -L "$LOCAL_RAM" ]; then
        LINK_TARGET=$(readlink "$LOCAL_RAM" 2>/dev/null || true)
        echo "RAM-Disk:       ACTIVE (Symlink -> $LINK_TARGET)"
    elif mount | grep -q "$LOCAL_RAM.*tmpfs"; then
        MOUNT_INFO=$(mount | grep "$LOCAL_RAM.*tmpfs" | awk '{print $1, $4, $5, $6}')
        echo "RAM-Disk:       ACTIVE (tmpfs mounted on $LOCAL_RAM)"
        echo "Details:        $MOUNT_INFO"
    else
        echo "RAM-Disk:       INACTIVE (Running on local storage)"
    fi

    # Check cron status
    if [ -f "$CRON_FILE" ]; then
        echo "Cron Watchdog:  REGISTERED ($CRON_FILE)"
    elif crontab -l 2>/dev/null | grep -q "amberdb_daemon.pl watchdog"; then
        echo "Cron Watchdog:  REGISTERED (User crontab)"
    else
        echo "Cron Watchdog:  NOT REGISTERED"
    fi

    # Check systemd status
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet "$SERVICE_NAME.service" 2>/dev/null; then
            echo "Systemd Service: RUNNING ($SERVICE_NAME.service)"
        elif [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
            echo "Systemd Service: INSTALLED (inactive)"
        else
            echo "Systemd Service: NOT INSTALLED"
        fi
    fi

    echo "================================================================="
    exit 0
fi

# --- Action: CRON-INSTALL ---
if [ "$ACTION" == "cron-install" ] || [ "$ACTION" == "cron" ]; then
    echo "[SETUP] Configuring cron watchdog for AmberDB ($PROJECT_NAME)..."
    PERL_BIN="$(which perl 2>/dev/null || echo "/usr/bin/perl")"
    CRON_LINE="*/5 * * * * $RUN_USER $PERL_BIN -I$LIB_DIR $DAEMON_PL watchdog --dbase_dir $PROJECT_DIR >/dev/null 2>&1"

    if [ -d "/etc/cron.d" ] && [ "$EUID" -eq 0 ]; then
        cat <<EOF > "$CRON_FILE"
# AmberDB Self-Healing Watchdog for $PROJECT_NAME
# Runs every 5 minutes to ensure background sync engine is healthy.
$CRON_LINE
EOF
        chmod 0644 "$CRON_FILE"
        echo "[SUCCESS] Cron watchdog registered in $CRON_FILE (User: $RUN_USER)"
    else
        echo "[INFO] Registering in current user's crontab..."
        (crontab -l 2>/dev/null | grep -v "amberdb_daemon.pl watchdog" ; echo "*/5 * * * * $PERL_BIN -I$LIB_DIR $DAEMON_PL watchdog --dbase_dir $PROJECT_DIR >/dev/null 2>&1") | crontab -
        echo "[SUCCESS] Cron watchdog added to crontab."
    fi
    exit 0
fi

# --- Action: CRON-REMOVE ---
if [ "$ACTION" == "cron-remove" ]; then
    echo "[SETUP] Removing cron watchdog for AmberDB ($PROJECT_NAME)..."
    if [ -f "$CRON_FILE" ]; then
        rm -f "$CRON_FILE"
        echo "[SUCCESS] Removed $CRON_FILE"
    fi
    if crontab -l 2>/dev/null | grep -q "amberdb_daemon.pl watchdog"; then
        (crontab -l 2>/dev/null | grep -v "amberdb_daemon.pl watchdog") | crontab -
        echo "[SUCCESS] Removed watchdog from crontab."
    fi
    exit 0
fi

# --- Action: SERVICE-INSTALL ---
if [ "$ACTION" == "service-install" ] || [ "$ACTION" == "service" ]; then
    check_root
    echo "[SETUP] Installing systemd service '$SERVICE_NAME.service'..."

    PERL_BIN="$(which perl 2>/dev/null || echo "/usr/bin/perl")"
    UNIT_FILE="/etc/systemd/system/$SERVICE_NAME.service"

    cat <<EOF > "$UNIT_FILE"
[Unit]
Description=AmberDB Continuous Sync Daemon ($PROJECT_NAME)
After=network.target

[Service]
Type=simple
User=$RUN_USER
WorkingDirectory=$PROJECT_DIR
ExecStart=$PERL_BIN -I$LIB_DIR $DAEMON_PL run --dbase_dir $PROJECT_DIR
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    chmod 0644 "$UNIT_FILE"
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME.service"
    systemctl start "$SERVICE_NAME.service"

    echo "[SUCCESS] Systemd service $SERVICE_NAME installed and started!"
    echo "  Status : systemctl status $SERVICE_NAME"
    echo "  Logs   : journalctl -u $SERVICE_NAME -f"
    exit 0
fi

# --- Action: SERVICE-REMOVE ---
if [ "$ACTION" == "service-remove" ]; then
    check_root
    echo "[SETUP] Removing systemd service '$SERVICE_NAME.service'..."
    systemctl stop "$SERVICE_NAME.service" 2>/dev/null || true
    systemctl disable "$SERVICE_NAME.service" 2>/dev/null || true
    rm -f "/etc/systemd/system/$SERVICE_NAME.service"
    systemctl daemon-reload
    echo "[SUCCESS] Systemd service $SERVICE_NAME removed."
    exit 0
fi

# --- Action: PERMS ---
if [ "$ACTION" == "perms" ] || [ "$ACTION" == "chown" ]; then
    check_root
    echo "[SETUP] Setting permissions for user '$RUN_USER' on dbstore..."
    chown -R "$RUN_USER":"$RUN_USER" "$PROJECT_DIR/dbstore" 2>/dev/null || chown -R "$RUN_USER" "$PROJECT_DIR/dbstore"
    chmod -R 0775 "$PROJECT_DIR/dbstore"
    echo "[SUCCESS] Permissions configured."
    exit 0
fi

# Require root for RAM-disk operations
check_root

# --- Action: STOP / RAMDISK-STOP / UNMOUNT ---
if [ "$ACTION" == "stop" ] || [ "$ACTION" == "--stop" ] || [ "$ACTION" == "ramdisk-stop" ] || [ "$ACTION" == "unmount" ]; then
    echo "[RAM-DISK] Stopping AmberDB RAM-Disk for project '$PROJECT_NAME'..."

    if mount | grep -q "$LOCAL_RAM.*tmpfs"; then
        umount "$LOCAL_RAM" 2>/dev/null || umount -l "$LOCAL_RAM" 2>/dev/null
    fi

    mkdir -p "$LOCAL_RAM"/{tables,config,schema,lock,pids}
    if [ -n "$RUN_USER" ]; then
        chown -R "$RUN_USER" "$LOCAL_RAM" 2>/dev/null || true
    fi
    echo "[SUCCESS] Linux tmpfs RAM-Disk unmounted and restored to local storage for '$PROJECT_NAME'."
    exit 0
fi

# --- Action: START / RAMDISK-START / MOUNT ---
if [ "$ACTION" == "start" ] || [ "$ACTION" == "--start" ] || [ "$ACTION" == "ramdisk-start" ] || [ "$ACTION" == "mount" ]; then
    echo "[RAM-DISK] Mounting Linux tmpfs RAM-Disk for '$PROJECT_NAME' ($SIZE)..."

    mkdir -p "$LOCAL_RAM"

    if ! mount | grep -q "$LOCAL_RAM.*tmpfs"; then
        mount -t tmpfs -o size="$SIZE",mode=0777 tmpfs "$LOCAL_RAM"
    fi

    mkdir -p "$LOCAL_RAM"/{table,config,schema,lock,pids}
    chmod -R 0777 "$LOCAL_RAM" 2>/dev/null || true
    if [ -n "$RUN_USER" ]; then
        chown -R "$RUN_USER" "$LOCAL_RAM" 2>/dev/null || true
    fi

    echo ""
    echo "[SUCCESS] Linux tmpfs RAM-Disk mounted and configured for AmberDB!"
    echo "  Project:      $PROJECT_NAME"
    echo "  RAM Storage:  $LOCAL_RAM ($SIZE)"
    echo "  |-- table/    (DB & Index acceleration files)"
    echo "  |-- config/   (Compiled config files)"
    echo "  |-- schema/   (Table & DBase schema files)"
    echo "  |-- lock/     (Flock lock files)"
    echo "  \\-- pids/    (Process & mutex files)"
    echo ""
    exit 0
fi

echo "Unknown action: $ACTION"
echo "Usage: sudo $0 {ramdisk-start|ramdisk-stop|status|cron-install|cron-remove|service-install|service-remove|perms} [args]"
exit 1
