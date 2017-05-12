#!/usr/bin/perl

use strict;

sub skip_test { print "1..0 # Skipped: $_[0]\n"; exit }

BEGIN {
   eval { require Test::More };
   skip_test('Test::More required for Test::Pod') if $@;
   Test::More->import();
}

# --------------------------------------------------

eval "use Test::Pod 1.12";
plan skip_all => "Test::Pod 1.12 required for testing POD" if $@;
all_pod_files_ok();
