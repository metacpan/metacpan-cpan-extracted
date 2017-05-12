#!/usr/bin/perl -w
#
# This program shows the usage of GraphViz::Parse::Yacc
# to graph the Perl grammar

use strict;
use lib '../lib';
use GraphViz::Parse::Yacc;

my $g = GraphViz::Parse::Yacc->new('perly.output');
#print $g->as_text();
$g->as_png("yacc.png");



