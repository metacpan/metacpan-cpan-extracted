#!/usr/bin/perl

use Test::More qw(no_plan);

use Graph::Undirected;
use Algorithm::SocialNetwork;

my $G3 = Graph::Undirected->new();
$G3->add_edges([qw(a b)], [qw(b c)]);

my $algo = Algorithm::SocialNetwork->new(graph => $G3);
my $BC = $algo->BetweenessCentrality();
is($BC->{a},0);
is($BC->{b},2);
is($BC->{c},0);

is($algo->BetweenessCentrality('b'),2);

my @BCab = $algo->BetweenessCentrality('a','b');
my @wanted = (0,2);
eq_array(\@BCab,\@wanted);

