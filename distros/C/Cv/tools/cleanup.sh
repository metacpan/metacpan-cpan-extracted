#!/bin/sh -x

pkg_delete -f /var/db/pkg/opencv*
rm -rf /usr/local/include/opencv*
rm -rf /usr/local/share/opencv
rm -rf /usr/local/share/examples/opencv
rm -f /usr/local/lib/libopencv_*
rm -f /usr/local/lib/libcxcore*
rm -f /usr/local/lib/libcv*
rm -f /usr/local/lib/libml*
rm -f /usr/local/lib/libhighgui*
rm -f /usr/local/libdata/pkgconfig/opencv.pc
rm -f /usr/local/lib/pkgconfig/opencv.pc
