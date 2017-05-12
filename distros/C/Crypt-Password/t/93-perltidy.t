#!/usr/bin/perl -w
#
#  t/93-perltidy.t - test whitespace conformance using perltidy
#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

use strict;
use Test::More;
use FindBin qw($Bin);
plan skip_all => 'set TEST_TIDY or TEST_ALL to enable this test'
	unless $ENV{TEST_TIDY}
		or $ENV{TEST_ALL};
my $perltidy = "$Bin/../perltidy.pl";
plan skip_all => 'no perltidy.pl script; run this from a git clone'
	unless -x $perltidy;
plan "no_plan";

my $output = qx($perltidy -t);
my $rc     = $?;

ok( !$rc, "all files tidy" );
diag($output) if $rc;

