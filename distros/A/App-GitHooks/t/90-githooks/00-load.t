#!/usr/bin/env perl

use strict;
use warnings;

use Test::Compile qw();
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;

ok(
	defined(
		my $test = Test::Compile->new()
	),
	'Instantiate a new Test::Compile object.',
);

ok(
	$test->pl_file_compiles( 'bin/githooks' ),
	'The githooks utility compiles.',
);
