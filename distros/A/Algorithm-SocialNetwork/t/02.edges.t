#!/usr/bin/perl -l

use strict;
use Test::More qw(no_plan);
use Algorithm::SocialNetwork;
use Graph;

sub mysort {
    sort {
        ($a->[0] cmp $b->[0]) || ($a->[1] cmp $b->[1])
    } @_;
}

my $g = Graph->new();
my @input = ([qw(a b)],[qw(b c)],[qw(b d)],[qw(c d)]);
$g->add_edges(@input);

my $algo = Algorithm::SocialNetwork->new(graph => $g);
my @edges  = $algo->edges qw(a c d);
my @wanted = ([qw(c d)]);
ok eq_array(\@edges,\@wanted);

@edges  = mysort $algo->edges qw(a b c);
@wanted = mysort ([qw(a b)],[qw(b c)]);
ok eq_array(\@edges,\@wanted);

@edges  = mysort $algo->edges(qw(a b c d));
@wanted = mysort @input;
ok eq_set(\@edges,\@wanted);
