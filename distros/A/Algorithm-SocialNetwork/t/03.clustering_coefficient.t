#!/usr/bin/perl

use strict;
use Test::More qw(no_plan);
use Algorithm::SocialNetwork;
use Graph;

my $g = Graph->new();
my @input = ([qw(a b)],[qw(b c)]);
$g->add_edges(@input);

my $algo = Algorithm::SocialNetwork->new(graph => $g);

is($algo->ClusteringCoefficient('b'),0);

$g->add_edge(qw(a c));
$algo->graph($g);

is($algo->ClusteringCoefficient('a'),0.5);
is($algo->ClusteringCoefficient('b'),0.5);
is($algo->ClusteringCoefficient('c'),0.5);

$g = Graph->new();
$g->add_edge('a','b');
$algo->graph($g);
is($algo->ClusteringCoefficient('b'),undef);
