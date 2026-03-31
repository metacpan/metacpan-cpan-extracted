#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all);

BEGIN {
	skip_all 'set RELEASE_TESTING=1 to run Test::DependentModules (slow / network)'
		unless $ENV{RELEASE_TESTING};

	eval {
		require Test::DependentModules;
		Test::DependentModules->import('test_all_dependents');
		1;
	} or skip_all 'Test::DependentModules is required for this author test';
}

test_all_dependents('App::prepare4release');
