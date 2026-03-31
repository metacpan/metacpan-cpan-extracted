#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all);

BEGIN {
	eval {
		require Test::Portability::Files;
		Test::Portability::Files->import;
		1;
	} or skip_all 'Test::Portability::Files is required for this author test';
}

run_tests();
