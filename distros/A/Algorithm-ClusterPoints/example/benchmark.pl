#!/usr/bin/perl

use warnings;
use strict;

use Benchmark qw(timethis);
use Math::Random qw(random_normal);

use Algorithm::ClusterPoints;

# Latitude stats:
# Minimum: 10.318842
# Maximum: 14.124424
# Mean: 11.24719
# Standard Deviation: 0.805771


# Longitude stats:
# Minimum: 21.097507
# Maximum: 24.912207
# Mean: 22.474358
# Standard Deviation: 0.974835

@ARGV = (3, 30, 300, 3_000, 30_000, 300_000) unless @ARGV;

for my $n (@ARGV) {
    # for my $dimension (2, 3) {
    for my $dimension (2, 3, 4) {
        my @coords;
        for (1..$dimension) {
            # push @coords, [random_normal($n, 11.24719, 0.805771)];
            push @coords, [map { 11.24719 + 3 * 0.805771 * rand } 1..$n];
        }
        # my @x = random_normal($n, 11.24719, 0.805771);
        # my @y = random_normal($n, 22.47436, 0.974835);

        print STDERR "$n points generated, dimension: $dimension\n";

        timethis (-1, sub {
                          my $clp = Algorithm::ClusterPoints->new(radius => 0.01, dimension => $dimension);
                          for my $i (0..$#{$coords[0]}) {
                              $clp->add_point(map $_->[$i], @coords);
                          }
                          my @clusters = $clp->clusters_ix
                      }
                 );
    }
}
