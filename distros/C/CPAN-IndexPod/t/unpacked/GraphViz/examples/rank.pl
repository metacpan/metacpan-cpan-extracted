#!/usr/bin/perl -w
#
# An example showing the new ranking code

use strict;
use lib '../lib';
use GraphViz;

my $g = GraphViz->new();

$g->add_node('London');
$g->add_node('Paris', label => 'City of\nlurve', rank => 'top');
$g->add_node('New York');
$g->add_node('Boston', rank => 'top');

$g->add_edge('Paris' => 'London');
$g->add_edge('London' => 'New York', label => 'Far');
$g->add_edge('Boston' => 'New York');

$g->as_png("rank.png");
#warn $g->_as_debug();
