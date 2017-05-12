#!/bin/sh

perl Makefile.PL && \
make realclean && \
rm -f MANIFEST && \
perl Makefile.PL && \
make && \
make manifest && \
make test && \
make dist
