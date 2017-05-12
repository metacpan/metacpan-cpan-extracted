#!/bin/sh

# change settings here to match your setup
# (mount point and loopback device)

umount /mnt/test
losetup -d /dev/loop4

exit 0

