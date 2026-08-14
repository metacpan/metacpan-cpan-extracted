#!/bin/sh
set -eu

target_uid="${KARR_UID:-}"
target_gid="${KARR_GID:-}"

if [ -z "$target_uid" ] || [ -z "$target_gid" ]; then
    if [ -d /work ]; then
        work_uid="$(stat -c '%u' /work)"
        work_gid="$(stat -c '%g' /work)"
    else
        work_uid=1000
        work_gid=1000
    fi

    : "${target_uid:=$work_uid}"
    : "${target_gid:=$work_gid}"
fi

: "${target_uid:=1000}"
: "${target_gid:=1000}"

mkdir -p /home/karr

if [ "$target_uid" = "0" ] && [ "$target_gid" = "0" ]; then
    export HOME=/root
    exec karr "$@"
fi

chown "$target_uid:$target_gid" /home/karr
export HOME=/home/karr

# ssh looks itself up with getpwuid() and refuses to start at all when the uid
# it runs as has no passwd entry -- "No user exists for uid 1000". We drop to
# whoever owns /work, a host uid this image knows nothing about, so an ssh://
# remote failed here even once openssh-client was installed. The fixed-user
# image does not need this: useradd wrote its entry at build time.
if ! getent passwd "$target_uid" >/dev/null 2>&1; then
    echo "karr:x:${target_uid}:${target_gid}:karr:/home/karr:/bin/sh" >> /etc/passwd
fi

exec gosu "$target_uid:$target_gid" karr "$@"
