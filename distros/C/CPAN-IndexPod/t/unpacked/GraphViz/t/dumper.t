#!/usr/bin/perl -w

use lib '../lib', 'lib';
use GraphViz::Data::Grapher;
use Test::More tests => 1;

my @lines = <DATA>;

foreach my $lines (split '-- test --', (join "", @lines)) {
  my($test, $expect) = split '-- expect --', $lines;
  next unless $test;
  $expect =~ s|^\n||mg;
  $expect =~ s|\n$||mg;

  $test =~ s|^\n||mg;
  $test =~ s|\n$||mg;

  my $g;
  eval $test;

  my $result = $g->_as_debug;

  $result =~ s|^\n||mg;
  $result =~ s|\n$||mg;

  is($result, $expect, "got expected graph");
}


__DATA__
-- test --
my @d = ("red", { a => [3, 1, 4, 1], b => { q => 'a', w => 'b'}}, "blue", undef, GraphViz::Data::Grapher->new(), 2);

$g = GraphViz::Data::Grapher->new(\@d);

-- expect --
digraph test {
	GraphViz [color="red", label="GraphViz"];
	node1 [color="blue", label="<port0>@", shape="record"];
	node2 [color="black", label="<port0>red|<port1>%|<port2>blue|<port3>undef|<port4>Object|<port5>2", shape="record"];
	node3 [color="brown", label="<port0>a|<port1>b", shape="record"];
	node4 [color="blue", label="<port0>@", shape="record"];
	node5 [color="black", label="<port0>3|<port1>1|<port2>4|<port3>1", shape="record"];
	node6 [color="blue", label="<port0>%", shape="record"];
	node7 [color="brown", label="<port0>q|<port1>w", shape="record"];
	node8 [color="blue", label="<port0>a", shape="record"];
	node9 [color="blue", label="<port0>b", shape="record"];
	"node1":port0 -> node2;
	"node2":port4 -> GraphViz;
	"node2":port1 -> node3;
	"node3":port0 -> node4;
	"node3":port1 -> node6;
	"node4":port0 -> node5;
	"node6":port0 -> node7;
	"node7":port0 -> node8;
	"node7":port1 -> node9;
}
