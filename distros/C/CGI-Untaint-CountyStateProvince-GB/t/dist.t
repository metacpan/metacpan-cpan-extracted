use strict;
use warnings;

use Test::Most;

BEGIN {
	if($ENV{RELEASE_TESTING}) {
		eval {
			require Test::Distribution;
		};
		if($@) {
			plan(skip_all => 'Test::Distribution not installed');
		} else {
			import Test::Distribution;
		}
	} else {
		plan(skip_all => 'Author tests not required for installation');
	}
}
