#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

if (system("which rsync") != 0)
{
    plan skip_all => "rsync required for this test";
}
elsif ($^O eq "solaris" or $^O eq "sunos")
{
    plan skip_all => "diff -q required for this test";	
}
else
{
    plan tests => 1;

	`"$^X" -Ilib script/remotediff -q t/data/file1 t/data/file2`;
	my $ret = $?;
	
	# diff exit status = 1 if files differ
	is($ret >> 8, 1, "remotediff - local diff quiet no tty");
}
