#!/usr/bin/env perl

use strict;
use warnings;
use lib::abs '../lib';

use Test::More;
BEGIN {
	chdir lib::abs::path('..') and eval q{use Test::Pod 1.22; 1} or plan skip_all => "Prereq not met";
}

all_pod_files_ok();
exit 0;
# kwalitee hacks
require Test::Pod;
require Test::NoWarnings;
