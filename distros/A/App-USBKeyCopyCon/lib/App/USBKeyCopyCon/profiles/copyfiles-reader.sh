#!/bin/bash
#
# This script is responsible for copying data from a USB 'Master' key.
# When it is invoked, the following environment variables will be passed in:
#
#  USB_BLOCK_DEVICE  Path to raw block device (eg: /dev/sdb)
#
#  USB_MOUNT_DIR     Path to a mount point reserved for this process
#
#  USB_MASTER_ROOT   Path to directory for files to be copied from the key
#

set -e;  # abort with non-zero exit status if any command fails

die () {
    echo "$@"
    exit 1
}

test -n "${USB_BLOCK_DEVICE}" || die "USB_BLOCK_DEVICE not set"
test -n "${USB_MOUNT_DIR}"    || die "USB_MOUNT_DIR not set"
test -n "${USB_MASTER_ROOT}"  || die "USB_MASTER_ROOT not set"

echo "Preparing to copy from: ${USB_BLOCK_DEVICE}"

# We'll specifically refer to the first partition

FS_BLOCK_DEVICE="${USB_BLOCK_DEVICE}1"

# Mount the device

test -d ${USB_MOUNT_DIR} || mkdir -p ${USB_MOUNT_DIR}
mount ${FS_BLOCK_DEVICE} ${USB_MOUNT_DIR}

# Copy the files

sleep 1
echo "Copying the files ..."
cp -r ${USB_MOUNT_DIR}/. ${USB_MASTER_ROOT}


# Get a checksum for the source files on the USB device

sleep 1
echo "Verifying copied files ..."
cd ${USB_MOUNT_DIR}
ORIG_SUM="$(find . -type f -print0 | xargs -0 md5sum | sort | md5sum - | awk '{print $1}')"

cd ${USB_MASTER_ROOT}
COPY_SUM="$(find . -type f -print0 | xargs -0 md5sum | sort | md5sum - | awk '{print $1}')"

test "$ORIG_SUM" = "$COPY_SUM" || die "Checksum of copied files does not match"

# Unmount the volume (graceful unmount to ensure data is synced)

sleep 1
echo "Unmounting USB device ..."
umount ${FS_BLOCK_DEVICE}

# Save the checksum

echo "$ORIG_SUM" > ${USB_MASTER_ROOT}.md5sum

echo "Successfully read master key";

exit 0;

