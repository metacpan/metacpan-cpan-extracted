#!/usr/bin/perl

use strict;
use Test::More qw(no_plan);
use Algorithm::SocialNetwork;
use Graph;

my $g = Graph->new();
my @input = ([qw(a b)],[qw(b c)]);
$g->add_edges(@input);

my $algo = Algorithm::SocialNetwork->new(graph => $g);
is($algo->ClosenessCentrality('b'), 1);
is($algo->ClosenessCentrality('a'), 1/3);

$g = Graph->new(undirected => 1);
$g->add_edges(@input);
$algo->graph($g);
is($algo->ClosenessCentrality('b'), 1/2);
is($algo->ClosenessCentrality('a'), 1/3);
