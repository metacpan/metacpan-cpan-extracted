#!perl -w

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;

eval 'use Test::NoPlan qw / all_plans_ok /';

if($@) {
	plan(skip_all => 'Test::NoPlan required for test verification');
} else {
	all_plans_ok();
}
