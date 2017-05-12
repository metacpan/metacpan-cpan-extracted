#!/usr/bin/perl

use strict;
use Test::More qw(no_plan);
use Algorithm::SocialNetwork;
use Graph;

my $g = Graph->new();
$g->add_edges([qw(a b)],[qw(b c)]);

my $algo = Algorithm::SocialNetwork->new(graph => $g);

is($algo->ClusteringCoefficient('b'),0);

$g->add_edge(qw(a c));
$algo->graph($g);

# Weight are not set, should be exactly the same as ClusteringCoefficient()
is($algo->WeightedClusteringCoefficient('a'),0.5);
is($algo->WeightedClusteringCoefficient('b'),0.5);
is($algo->WeightedClusteringCoefficient('c'),0.5);

# Weighted, so the result is different
$g->set_edge_weight('a','b',0.1);
$g->set_edge_weight('b','c',0.8);
$algo->graph($g);
is($algo->WeightedClusteringCoefficient('a'),0.8/2);
is($algo->WeightedClusteringCoefficient('b'),1/2);
is($algo->WeightedClusteringCoefficient('c'),0.1/2);

$g = Graph->new();
$g->add_edge('a','b');
$algo->graph($g);
is($algo->WeightedClusteringCoefficient('b'),undef);
