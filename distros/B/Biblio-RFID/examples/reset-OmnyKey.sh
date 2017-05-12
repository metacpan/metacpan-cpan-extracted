#!/bin/sh -x

sudo mount -t usbfs none /proc/bus/usb
id=`lsusb | grep OmniKey | cut -d" " -f2,4 | sed -e 's! !/!' -e 's!:!!'`
sudo ./examples/usbreset /proc/bus/usb/$id
