#!perl

# Make sure we can read a NorthStar format catalogue. In this case
# it is the pointing catalogue.

# Author: Tim Jenness (tjenness@cpan.org)
# Copyright (C) 2007 Particle Physics and Astronomy Research Council

use strict;
use warnings;
use Test::More tests => 4;

require_ok( 'Astro::Catalog' );

# Create a new catalogue from the DATA handle
my $cat = new Astro::Catalog(Format => 'Northstar', Data => \*DATA );

isa_ok( $cat, "Astro::Catalog");

my $total = 2;
is( $cat->sizeof, $total, "count number of sources");

# The remaining tests actually test the catalog filtering
# search by substring
my @results = $cat->filter_by_id("GL2591");
is( scalar(@results), 1, "search by ID - \"GL2591\"");


__DATA__
m35 06:45:59.93 -20:45:15.1 j2000 7200s 5
gl2591 20:29:24.7 40:11:18.87 j2000

