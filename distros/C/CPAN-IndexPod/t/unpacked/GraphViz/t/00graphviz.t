#!/usr/bin/perl -w
use strict;
use IPC::Run qw(run);
use Test::More tests => 1;

my $in;
eval { run ["dot", '-v'], \$in };

if ($@) {
  warn $@;
  warn "****************************************************************\n";
  warn "GraphViz.pm has not been able to find the graphviz program 'dot'\n";
  warn "GraphViz.pm needs graphviz to function\n";
  warn "Please install graphviz first: http://www.graphviz.org/\n";
  warn "****************************************************************\n";
  ok(0, "graphviz not installed");
} else {
  ok(1, "graphviz found");
}
