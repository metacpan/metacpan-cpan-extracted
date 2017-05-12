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
	my $min_tp = 1.22;
	eval "use Test::Pod $min_tp";
	plan ('skip_all' => "Test::Pod $min_tp required for testing POD") if $@;
}

all_pod_files_ok ();
