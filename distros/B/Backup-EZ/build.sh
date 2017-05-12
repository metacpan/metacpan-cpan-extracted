#!/bin/sh

rm -f *.gz
rm -f MANIFEST
perl Makefile.PL && make && make test && make manifest && make dist
