#!perl

# Test UKIRT Bright Standards catalogue format read

# Astro::Catalog test harness
use Test::More tests => 5;

# strict
use strict;

#load test
use File::Spec;
use Data::Dumper;

# load modules
require_ok("Astro::Catalog");

my $cat = new Astro::Catalog( Format => 'UKIRTBS', Data => \*DATA );
isa_ok( $cat, "Astro::Catalog" );

my $star = $cat->popstar();
my $id = $star->id;
is($id,147064,"Last ID");

my $c = $star->coords;
is($star->ra, "00 04 19.57", "star RA");
is($star->dec,"-16 31 41.53",  "star dec");

__DATA__
    9098  0.005145878-0.307427168   26.   -4.  4.6B9.5Vn
  147064  0.007713899-0.293330848   37.  -55.  5.8K0
