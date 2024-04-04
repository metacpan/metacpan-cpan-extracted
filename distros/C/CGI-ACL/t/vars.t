#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Needs 'Test::Vars';

if($ENV{'AUTHOR_TESTING'}) {
	Test::Vars->import();
	all_vars_ok(ignore_vars => { '$self' => 0 });
} else {
	plan(skip_all => 'Author tests not required for installation');
}
