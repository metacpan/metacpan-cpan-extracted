#!perl -w

use strict;

use Test::Most;

if($ENV{AUTHOR_TESTING}) {
	eval 'use Test::Prereq';
	plan(skip_all => 'Test::Prereq required to test dependencies') if $@;
	prereq_ok();
} else {
	plan(skip_all => 'Author tests not required for installation');
}
