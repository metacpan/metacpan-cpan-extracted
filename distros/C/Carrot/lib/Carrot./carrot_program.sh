#!/bin/sh

PERL_MINUS_I=`echo "$0" | sed -e 's,/\?Carrot./carrot_[a-z_]*.sh,,'`

exec /usr/bin/perl -e 'require Carrot; require(Carrot::main());' \
	-W -I$PERL_MINUS_I \
	-- \
	--carrot-main=Carrot./carrot_program.pl \
	$@
