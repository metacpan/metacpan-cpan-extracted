#!/usr/bin/env perl
use strict; use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

# Spatial join / nearest-facility: assign each "customer" to its closest "store"
# using query_knn(..., 1).

my @stores = map { [ rand()*100, rand()*100 ] } 1 .. 8;
my $idx = Data::SpatialHash::Shared->new(undef, scalar(@stores), 0, 10);
$idx->insert(@{$stores[$_]}, $_) for 0 .. $#stores;   # value = store index

my %assigned;
for (1 .. 200) {
    my @c = (rand()*100, rand()*100);
    my ($store) = $idx->query_knn(@c, 1);
    $assigned{$store}++;
}

printf "store %d at (%5.1f,%5.1f): %3d customers\n",
    $_, @{$stores[$_]}, ($assigned{$_} // 0) for 0 .. $#stores;
