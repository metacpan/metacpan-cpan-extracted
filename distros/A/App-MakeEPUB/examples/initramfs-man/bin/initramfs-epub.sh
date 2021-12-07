#!/bin/sh

EPUBDIR=epub
MANPAGES="
busybox
cpio
date
dd
dmesg
halt
insmod
kbd_mode
loadkeys
losetup
mount
pivot_root
poweroff
reboot
setfont
sh
sleep
blkid
cryptsetup
dmsetup
dumpe2fs
hwclock
lvm
modprobe
mount.fuse
rmmod
udevadm
udevd
vgchange
"

[ -e "$EPUBDIR" ] && rm -rf "$EPUBDIR"

mkdir -p $EPUBDIR/OEBPS

create_html () {
    MANPAGE=$1
    man $MANPAGE \
    | bin/clean-utf8-man.pl \
    | rman -f HTML -r off \
    | tidy -asxml -utf8 -bare -f tidy.errors \
    | bin/mangle-rman-html.pl -title "$MANPAGE" \
    > $EPUBDIR/OEBPS/$MANPAGE.html
}

for p in $MANPAGES; do
    create_html $p
done

make-epub -output initramfs-manpages.epub \
          -creator 'Mathias Weidner' \
	  -publisher 'Mathias Weidner' \
          -title 'Initramfs Man Pages' \
	  -rights 'CC BY-SA 3.0' \
	  -level2 '_tag:h2' \
          -tocdepth 2 \
	  $EPUBDIR

epubcheck initramfs-manpages.epub
