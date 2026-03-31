#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all);

BEGIN {
	eval {
		require Test::Synopsis;
		Test::Synopsis->import;
		1;
	} or skip_all 'Test::Synopsis is required for this author test';
}

all_synopsis_ok();
