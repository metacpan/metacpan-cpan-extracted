#!perl -wT

use strict;
use warnings;
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
			use_ok('CGI::Lingua');
			use warnings::unused -global;
		}
	}

	if(not $ENV{AUTHOR_TESTING}) {
		plan(skip_all => 'Author tests not required for installation');
	} else {
		new_ok('CGI::Lingua' => [ supported => ['en-gb'] ]);
		plan tests => 2;
	}
}
