#!/usr/bin/perl

use strict;

sub skip_test { print "1..0 # Skipped: $_[0]\n"; exit }

BEGIN {
   eval { require Test::More };
   skip_test('Test::More required for testing Test::Pod::Coverage') if $@;
   Test::More->import();
}

# --------------------------------------------------

eval "use Test::Pod::Coverage 0.08";
plan skip_all => "Test::Pod::Coverage 0.08 required for testing POD coverage" if $@;
all_pod_coverage_ok();
