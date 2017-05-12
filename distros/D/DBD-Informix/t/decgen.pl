#!/usr/bin/perl -w
#
#   @(#)$Id: decgen.pl,v 2003.1 2003/01/03 19:02:36 jleffler Exp $
#
#   Create exhaustive list of DECIMAL & MONEY types for DBD::Informix
#
# Copyright 1997    Jonathan Leffler
# Copyright 2000    Informix Software Inc
# Copyright 2002-03 IBM

foreach $type ('DECIMAL', 'MONEY')
{
	print "CREATE TEMP TABLE dbd_ix_${type}\n(\n";
	print "    col000  SERIAL NOT NULL {PRIMARY KEY}{XPS 8.30 rejects PK},\n";
	$prefix = ($type eq 'MONEY') ? "mon" : "dec";
	$colno = 1;
	for ($scale = 1; $scale <= 32; $scale++)
	{
		foreach $precision ('', 0..$scale)
		{
			$pad = ($precision ne '' ? ',' : '');
			printf("    $prefix%03d  %s(%s%s%s),\n",
					$colno++, $type, $scale, $pad, $precision)
				unless ($type eq 'MONEY' && $scale == 1 && $precision eq '');
		}
	}
	print "    dummy  CHAR(1)\n) WITH NO LOG;\n\n";
}
