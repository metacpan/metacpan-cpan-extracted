#!/usr/bin/perl -T

use strict;
use warnings;

BEGIN {
	use Test::More;
	if (not $ENV {'TEST_AUTHOR'}) {
		plan ('skip_all' => 'Set $ENV{TEST_AUTHOR} to a true value to run the tests');
	}
}

BEGIN {
	eval 'use Test::CheckChanges';
	plan ('skip_all' => 'Test::CheckChanges required for testing the Changes file') if $@;
}

BEGIN {
	plan ('skip_all' => 'Makefile required for testing the Changes file') unless -f 'Makefile';
}

ok_changes ();
