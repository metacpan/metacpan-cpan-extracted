#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

if(not $ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

eval "use Test::Vars";

plan skip_all => "Test::Vars required for detecting unused variables" if $@;

all_vars_ok();
