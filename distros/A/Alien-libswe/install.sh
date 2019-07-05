#!/bin/sh
perl Makefile.PL
make
make test
make install
make clean
rm MANIFEST.bak
rm -rf _alien
rm Makefile.old
