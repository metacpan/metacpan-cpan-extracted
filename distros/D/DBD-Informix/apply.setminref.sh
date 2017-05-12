#!/bin/sh
#
# @(#)$Id: apply.setminref.sh,v 1.1 2015/11/01 06:32:00 jleffler Exp $
#
# Apply setminref.pl to appropriate files

exec perl setminref.pl $(grep -lEr -e ':(PERL|DBI)_(MIN|REF)VERSION:' .)
