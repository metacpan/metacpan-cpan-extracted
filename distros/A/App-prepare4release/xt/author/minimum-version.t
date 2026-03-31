#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(skip_all);

BEGIN {
	eval {
		require Test::MinimumVersion;
		Test::MinimumVersion->import;
		1;
	} or skip_all 'Test::MinimumVersion is required for this author test';
}

# After `perl Makefile.PL`, MYMETA.json exists; META.yml is often absent until release.
all_minimum_version_from_mymetajson_ok();
