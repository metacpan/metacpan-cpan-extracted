#!/usr/bin/perl -w
#
# @(#)$Id: dblist.t,v 56.2 1997/06/25 23:03:39 johnl Exp $ 
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#
# Portions Copyright (C) 1996,1997 Jonathan Leffler
#
# List of available databases:
#   @ary = $DBI->data_sources('Sqlflex');

use DBD::SqlflexTest qw(stmt_ok stmt_fail stmt_note all_ok);

@ary = DBI->data_sources('Sqlflex');

if (!defined @ary)
{
	print "1..1\n";
	&stmt_note("# Test: DBI->data_sources('Sqlflex'):\n");
	&stmt_fail();
}
else
{
	$x = @ary;
	print "1..$x\n";
	&stmt_note("# Test: DBI->data_sources('Sqlflex'):\n");
	foreach $db (@ary)
	{
		&stmt_note("# Database: $db\n");
		&stmt_ok(0);
	}
}

&all_ok();

exit 0;
