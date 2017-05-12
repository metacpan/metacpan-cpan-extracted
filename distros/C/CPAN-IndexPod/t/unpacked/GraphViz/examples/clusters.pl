#!/usr/bin/perl -w
#
# This is a simple idea which illustrates the use
# of clusters to, well, cluster nodes together

use strict;
use lib '../lib';
use GraphViz;

my $g = GraphViz->new();

$g->add_node('London', cluster => 'Europe');
$g->add_node('Paris', label => 'City of\nlurve', cluster => 'Europe');
$g->add_node('New York');

$g->add_edge('London' => 'Paris');
$g->add_edge('London' => 'New York', label => 'Far');
$g->add_edge('Paris' => 'London');

#print $g->_as_debug;
#print $g->as_text;
$g->as_png("clusters.png");

