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
	eval 'use Test::Synopsis';
	plan ('skip_all' => 'Test::Synopsis required for testing the synopsis') if $@;
}

all_synopsis_ok ();
