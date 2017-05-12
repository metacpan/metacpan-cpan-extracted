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

	my $min_tpc = 1.08;
	eval "use Test::Pod::Coverage $min_tpc";
	plan (
		'skip_all' => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
	) if $@;

	my $min_pc = 0.18;
	eval "use Pod::Coverage $min_pc";
	plan ('skip_all' => "Pod::Coverage $min_pc required for testing POD coverage") if $@;

}

all_pod_coverage_ok ();
