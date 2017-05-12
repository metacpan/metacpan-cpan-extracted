#!/usr/bin/env perl

use strict;
use lib::abs '../lib';

BEGIN {
	return if $^O eq 'MSWin32';
	require Test::NoWarnings;
	Test::NoWarnings->import;
}

BEGIN {
	require Test::More;
	my $test_count = 2;
	$test_count-- if $^O eq 'MSWin32';
	Test::More->import( tests => $test_count );
}

BEGIN { $ENV{DEBUG_MEM} = 0 }
use Dash::Leak sub { fail "Should not be called" };

my $memuse = 'x'x1000000;# allocate at least 1Mb
leaksz "check", sub { fail "Should not be called" };
ok 1;
