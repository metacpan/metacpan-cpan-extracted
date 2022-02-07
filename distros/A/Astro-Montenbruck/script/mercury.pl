#!/usr/bin/env perl
use 5.22.0;
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib ("$Bin/../lib");

our $VERSION = 0.01;

use Astro::Montenbruck::Ephemeris::Planet qw/$ME/;
use Astro::Montenbruck::Ephemeris qw/find_positions/;

my $jd = 2458630.5; # Standard Julian date for May 27, 2019, 00:00 UTC.
my $t  = ($jd - 2451545) / 36525; # Convert Julian date to centuries since epoch 2000.0

find_positions($t, [$ME], sub {
    my ($id, $lambda, $beta, $delta) = @_;
    print "$id lambda: $lambda, beta: $beta, delta: $delta\n";
})
