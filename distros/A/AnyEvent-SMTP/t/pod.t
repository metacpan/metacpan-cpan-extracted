#!/usr/bin/env perl -w

use strict;
use Test::More;
use lib::abs "../lib";
BEGIN {
	my $lib = lib::abs::path( ".." );
	chdir $lib or plan skip_all => "Can't chdir to dist $lib";
}

# Ensure a recent version of Test::Pod
eval "use Test::Pod 1.22; 1"
	or plan skip_all => "Test::Pod 1.22 required for testing POD";

all_pod_files_ok();
exit;
