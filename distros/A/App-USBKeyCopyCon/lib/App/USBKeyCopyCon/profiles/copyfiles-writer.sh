#!/bin/bash
#
# This script is responsible for copying data to a USB key.  When it is
# invoked, the following environment variables will be passed in:
#
#  USB_BLOCK_DEVICE  Path to raw block device (eg: /dev/sdb)
#
#  USB_MOUNT_DIR     Path to a mount point reserved for this process
#
#  USB_MASTER_ROOT   Path to source data to be copied to the key
#
#  USB_VOLUME_NAME   The volume name to apply
#

set -e;  # abort with non-zero exit status if any command fails

die () {
    echo "$@"
    exit 1
}

test -n "${USB_BLOCK_DEVICE}" || die "USB_BLOCK_DEVICE not set"
test -n "${USB_MOUNT_DIR}"    || die "USB_MOUNT_DIR not set"
test -n "${USB_MASTER_ROOT}"  || die "USB_MASTER_ROOT not set"

echo "Preparing to copy to: ${USB_BLOCK_DEVICE}"
echo "  Mount point: ${USB_MOUNT_DIR}"
echo "  Master root: ${USB_MASTER_ROOT}"

# We'll specifically refer to the first partition

FS_BLOCK_DEVICE="${USB_BLOCK_DEVICE}1"

STEPS=7

# Format the device

mkfs -t vfat -n ${USB_VOLUME_NAME} ${FS_BLOCK_DEVICE}

echo "{1/${STEPS}}"

# Mount the device

test -d ${USB_MOUNT_DIR} || mkdir -p ${USB_MOUNT_DIR}
mount ${FS_BLOCK_DEVICE} ${USB_MOUNT_DIR}
echo "{2/${STEPS}}"

# Copy the files

cp -r ${USB_MASTER_ROOT}/. ${USB_MOUNT_DIR}
echo "{3/${STEPS}}"

# Unmount the volume (graceful unmount to ensure data is synced)

umount ${FS_BLOCK_DEVICE}
echo "{4/${STEPS}}"

# Remount the volume
sleep 1
mount ${FS_BLOCK_DEVICE} ${USB_MOUNT_DIR}
echo "{5/${STEPS}}"

# Check the file contents
cd ${USB_MOUNT_DIR}
COPY_SUM="$(find . -type f -print0 | xargs -0 md5sum | sort | md5sum - | awk '{print $1}')"
cd /

ORIG_SUM="$(cat ${USB_MASTER_ROOT}.md5sum)"

test "$ORIG_SUM" = "$COPY_SUM" || die "Checksum of copied files does not match"
echo "{6/${STEPS}}"

# Unmount the volume

umount ${FS_BLOCK_DEVICE}
echo "{7/${STEPS}}"

exit 0;
