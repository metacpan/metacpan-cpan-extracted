#!/usr/bin/perl -w
#
# A example which takes in text file and represents each word as a
# node and places edges where the nodes are used together.

use strict;
use lib '../lib';
use GraphViz;

my $graph = GraphViz->new(layout => 'neato', directed => 0, concentrate => 1, epsilon => 0.001, random_start => 1, no_overlap => 1m);

open(IN, shift || '../README');

my @words;
while (<IN>) {
  tr/[^A-Za-z]+/ /cs;
  push @words, split(/\s+/, lc);
}
@words = grep { ! /^\s*$/ } @words;

my %words;
my $lastword = shift @words;
foreach my $word (@words) {
  $words{$lastword}{$word}++;
  $lastword = $word;
}

foreach my $left (keys %words) {
  foreach my $right (keys %{$words{$left}}) {
    if ($words{$left}{$right} == 1) {
      $graph->add_edge($left => $right, weight => $words{$left}{$right} - 1);
    } else {
      $graph->add_edge($left => $right);
    }
  }
}

#warn $graph->_as_debug;
$graph->as_png("text.png");
#print $graph->as_text;


