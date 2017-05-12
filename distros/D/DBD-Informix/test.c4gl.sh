#!/bin/ksh
#
# @(#)$Id: test.c4gl.sh,v 2015.1 2015/10/29 11:46:10 jleffler Exp $
#
# Test whether DBD::Informix can be built with I4GL
#
# Copyright 1997 Jonathan Leffler
# Copyright 2000 Informix Software Inc
# Copyright 2002 IBM
# Copyright 2015 Jonathan Leffler

(
set -x
export INFORMIXSQLHOSTS=/usr/informix/etc/sqlhosts
export INFORMIXDIR=/usr/informix/6.05.UC1
export PATH=$INFORMIXDIR/bin:$PATH
ESQL=c4gl perl Makefile.PL
make
make test
)

