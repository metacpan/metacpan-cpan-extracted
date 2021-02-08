#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

if(not $ENV{AUTHOR_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

eval 'use Test::Vars';

plan(skip_all => 'Test::Vars required for detecting unused variables') if $@;

all_vars_ok(ignore_vars => { '$self' => 0 });
