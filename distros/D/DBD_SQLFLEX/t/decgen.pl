#!/usr/bin/perl -w
#
#       @(#)$Id: decgen.pl,v 54.1 1997/03/27 17:28:59 johnl Exp $
#
#       Create exhaustive list of DECIMAL & MONEY types for DBD::Sqlflex
#
#       Copyright (C) 1997 Jonathan Leffler

foreach $type ('DECIMAL', 'MONEY')
{
	print "CREATE TABLE ${type}_test\n(\n";
	print "    col000  SERIAL NOT NULL PRIMARY KEY CONSTRAINT PK_${type},\n";
	$colno = 1;
	for ($scale = 1; $scale <= 32; $scale++)
	{
		foreach $precision ('', 0..$scale)
		{
			$pad = ($precision ne '' ? ',' : '');
			printf("    col%03d  %s(%s%s%s),\n",
					$colno++, $type, $scale, $pad, $precision)
				unless ($type eq 'MONEY' && $scale == 1 && $precision eq '');
		}
	}
	print "    dummy  CHAR(1)\n);\n\n";
}
