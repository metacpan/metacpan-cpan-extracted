#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

BEGIN {
	if($ENV{AUTHOR_TESTING}) {
		eval {
			require Test::MinimumVersion;
		};
		if($@) {
			plan(skip_all => 'Test::MininumVersion not installed');
		} else {
			import Test::MinimumVersion;
			all_minimum_version_ok('5.8');
		}
	} else {
		plan(skip_all => 'Author tests not required for installation');
	}
}
