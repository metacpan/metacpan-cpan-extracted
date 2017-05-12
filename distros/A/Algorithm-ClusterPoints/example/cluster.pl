#!/usr/bin/perl

use strict;
use warnings;

use Algorithm::ClusterPoints;

use Data::Dumper;

my $clp = Algorithm::ClusterPoints->new(radius => 0.1, min_size => 2, ordered => 1);

while (<DATA>) {
    next if /^\s*(?:#.*)?$/;
    chomp;
    my ($x, $y) = split;
    $clp->add_point($x, $y);
}

my @clusters_ix = $clp->clusters_ix;

print Data::Dumper->Dump([\@clusters_ix], ['clusters_ix']);

for my $i (0..$#clusters_ix) {
    print( join( ' ',
                 "cluster $i:",
                 map {
                     my ($x, $y) = $clp->point_coords($_);
                     "($_: $x, $y)"
                 } @{$clusters_ix[$i]}
               ), "\n"
         );
}

my @clusters = $clp->clusters;
print Data::Dumper->Dump([\@clusters], ['clusters']);

__DATA__
0.43 0.62
0.50 0.65
0.49 0.32
0.95 0.20
0.09 0.09
0.61 0.55
0.72 0.42
0.83 0.11
0.62 0.71
0.52 0.97
0.44 0.53
0.01 0.08
0.55 0.32
0.30 0.68
0.67 0.47
0.27 0.62
0.12 0.15
0.28 0.65
0.37 0.38
0.16 0.35
0.66 0.33
0.16 0.79
0.83 0.27
0.77 0.13
0.73 0.07
0.36 0.44
0.53 0.27
0.50 0.19
0.61 0.17
0.47 0.28
0.13 0.15
0.55 0.58
0.36 0.58
0.62 0.30
0.64 0.97
0.88 0.61
0.12 0.24
0.35 0.18
0.40 0.54
0.90 0.20
0.14 0.74
