#!perl -wT

use strict;
use warnings;
use CHI;
use Test::Most;

my $can_test = 1;

if($ENV{AUTHOR_TESTING}) {
	eval {
		use Test::Requires {
			'warnings::unused' => 0.04
		};
	};
	if($@) {
		plan(skip_all => 'Test::Requires needed for test');
		$can_test = 0;
	}
}

if($can_test) {
	BEGIN {
		if($ENV{AUTHOR_TESTING}) {
			use_ok('Class::Simple::Readonly::Cached');
			# eval 'use warnings::unused -global';
			eval 'use warnings::unused';
		}
	}

	if(not $ENV{AUTHOR_TESTING}) {
		plan(skip_all => 'Author tests not required for installation');
	} else {
		new_ok('Class::Simple::Readonly::Cached' =>
			[ cache => CHI->new(driver => 'RawMemory', global => 1) ]
		);
		plan tests => 2;
	}
}
