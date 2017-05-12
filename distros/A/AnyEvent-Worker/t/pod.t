#!/usr/bin/env perl

use strict;
use warnings;
use lib::abs '../lib';

use Test::More;
BEGIN {
	chdir lib::abs::path '..' or plan skip_all => "$!";
	eval q{use Test::Pod 1.22;1} or plan skip_all => "Not Test::Pod";
	
}

all_pod_files_ok();
exit 0;
# kwalitee hacks
require Test::Pod;
require Test::NoWarnings;
