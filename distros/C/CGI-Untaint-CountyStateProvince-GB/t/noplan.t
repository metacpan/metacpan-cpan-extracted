#!perl -w

use strict;
use warnings;

use Test::Most;

unless($ENV{RELEASE_TESTING}) {
    plan( skip_all => "Author tests not required for installation" );
}

eval 'use Test::NoPlan qw / all_plans_ok /';
if($@) {
	plan skip_all => 'Test::NoPlan required for test verification';
} else {
	all_plans_ok();
}
