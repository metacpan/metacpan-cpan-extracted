#!perl
use strict;
use warnings;
use Test::More;

BEGIN {
	eval {
		require Test::Version;
		Test::Version->import;
		1;
	} or plan skip_all => 'Test::Version is required for this author test';
}

version_all_ok();
done_testing;
