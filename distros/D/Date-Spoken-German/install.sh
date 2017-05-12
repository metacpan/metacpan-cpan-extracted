#!/bin/sh

make clean
/usr/bin/env perl Makefile.PL
make
make test
make install