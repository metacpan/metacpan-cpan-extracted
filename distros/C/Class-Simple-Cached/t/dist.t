#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN {
	if($ENV{'AUTHOR_TESTING'}) {
		eval {
			require Test::Distribution;
		};
		if($@) {
			plan(skip_all => 'Test::Distribution not installed');
		} else {
			Test::Distribution->import();
		}
	} else {
		plan(skip_all => 'Author tests not required for installation');
	}
}
