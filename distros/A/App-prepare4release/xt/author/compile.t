#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all);

BEGIN {
	eval {
		require Test::Compile;
		Test::Compile->import;
		1;
	} or skip_all 'Test::Compile is required for this author test';
}

all_pm_files_ok();
