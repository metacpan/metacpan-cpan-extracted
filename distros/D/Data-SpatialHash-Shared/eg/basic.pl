#!/usr/bin/env perl
# Basic 2D insert, radius search, and k-nearest-neighbour
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

my $s = Data::SpatialHash::Shared->new(undef, 1000, 0, 1.0);

my %h;
$h{$_} = $s->insert(rand() * 100, rand() * 100, $_) for 1 .. 200;

my @near = $s->query_radius(50, 50, 10);
printf "found %d entities within radius 10 of (50,50)\n", scalar @near;

my @nn = $s->query_knn(50, 50, 5);
print "5 nearest to (50,50): @nn\n";

my $st = $s->stats;
printf "stats: count=%d load_factor=%.2f max_chain=%d\n",
    $st->{count}, $st->{load_factor}, $st->{max_chain};
