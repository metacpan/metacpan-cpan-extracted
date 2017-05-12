#!/usr/bin/perl -w
#
# This is a simple example of constructing
# undirected graphs. It shows factors, kinda ;-)


use strict;
use lib '../lib';
use GraphViz;

my $g = GraphViz->new(layout => 'neato', directed => 0, no_overlap => 1);

foreach my $i (1..16) {
  my $used = 0;
  $used = 1 if $i >= 2 and $i <= 4;
  foreach my $j (2..4) {
    if ($i != $j && $i % $j == 0) {
      $g->add_edge($i => $j);
      $used = 1;
    }
  }
  $g->add_node($i) if $used;
}

#print $g->_as_debug;
#print $g->as_text;
$g->as_png("undirected.png");

