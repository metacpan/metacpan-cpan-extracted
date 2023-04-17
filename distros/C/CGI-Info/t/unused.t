#!perl -wT

use strict;
use warnings;
use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval {
		eval 'use warnings::unused 0.04';
	};
	if($@) {
		plan(skip_all => 'warnings::unused needed for test for unused variables');
	} else {
		use_ok('CGI::Info');
		new_ok('CGI::Info');
		plan(tests => 2);
	}
} else {
	plan(skip_all => 'Author tests not required for installation');
}
