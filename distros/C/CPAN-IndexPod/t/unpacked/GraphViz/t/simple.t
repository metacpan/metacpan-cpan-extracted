#!/usr/bin/perl -w

use lib '../lib', 'lib';
use GraphViz;
use Test::More tests => 29;

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

  is($result, $expect);
}


__DATA__
-- test --
$g = GraphViz->new();
-- expect --
digraph test {
}

-- test --
$g = GraphViz->new(directed => 1)
-- expect --
digraph test {
}

-- test --
$g = GraphViz->new(directed => 0)
-- expect --
graph test {
}

-- test --
$g = GraphViz->new(rankdir => 1)
-- expect --
digraph test {
	rankdir=LR;
}

-- test --
$g = GraphViz->new();
$g->add_node(label => 'London');
-- expect --
digraph test {
	node1 [label="London"];
}

-- test --
$g = GraphViz->new(directed => 0);
$g->add_node('London');
-- expect --
graph test {
	London [label="London"];
}

-- test --
$g = GraphViz->new();
$g->add_node('London', label => 'Big smoke');
-- expect --
digraph test {
	London [label="Big smoke"];
}

-- test --
$g = GraphViz->new();
$g->add_node('London', label => 'Big\nsmoke');
-- expect --
digraph test {
	London [label="Big\nsmoke"];
}

-- test --
$g = GraphViz->new();
$g->add_node('London', label => 'Big smoke', color => 'red');
-- expect --
digraph test {
	London [color="red", label="Big smoke"];
}

-- test --
$g = GraphViz->new(sort => 1);
$g->add_node('London');
$g->add_node('Paris');
-- expect --
digraph test {
	London [label="London"];
	Paris [label="Paris"];
}

-- test --
$g = GraphViz->new(sort => 1);
$g->add_node('London');
$g->add_edge('London' => 'London');
-- expect --
digraph test {
	London [label="London"];
	London -> London;
}

-- test --
$g = GraphViz->new(sort => 1);
$g->add_node('London');
$g->add_edge('London' => 'London', label => 'Foo');
-- expect --
digraph test {
	London [label="London"];
	London -> London [label="Foo"];
}

-- test --
$g = GraphViz->new(sort => 1);
$g->add_node('London');
$g->add_edge('London' => 'London', color => 'red');
-- expect --
digraph test {
	London [label="London"];
	London -> London [color="red"];
}

-- test --
$g = GraphViz->new(sort => 1);
$g->add_node('London');
$g->add_node('Paris');
$g->add_edge('London' => 'Paris');
-- expect --
digraph test {
	London [label="London"];
	Paris [label="Paris"];
	London -> Paris;
}

-- test --
$g = GraphViz->new(sort => 1);
$g->add_node('London');
$g->add_node('Paris');
$g->add_edge('London' => 'Paris');
$g->add_edge('Paris' => 'London');
-- expect --
digraph test {
	London [label="London"];
	Paris [label="Paris"];
	London -> Paris;
	Paris -> London;
}

-- test --
$g = GraphViz->new(sort => 1);
$g->add_node('London');
$g->add_node('Paris');
$g->add_edge('London' => 'London');
$g->add_edge('Paris' => 'Paris');
$g->add_edge('London' => 'Paris');
$g->add_edge('Paris' => 'London');
-- expect --
digraph test {
	London [label="London"];
	Paris [label="Paris"];
	London -> London;
	London -> Paris;
	Paris -> London;
	Paris -> Paris;
}

-- test --
$g = GraphViz->new(sort => 1);
$g->add_node('London');
$g->add_node('Paris', label => 'City of\nlurve');
$g->add_node('New York');

$g->add_edge('London' => 'Paris');
$g->add_edge('London' => 'New York', label => 'Far');
$g->add_edge('Paris' => 'London');
-- expect --
digraph test {
	London [label="London"];
	"New York" [label="New York"];
	Paris [label="City of\nlurve"];
	London -> "New York" [label="Far"];
	London -> Paris;
	Paris -> London;
}

-- test --
# Test clusters
$g = GraphViz->new(sort => 1);

$g->add_node('London', cluster => 'Europe');
$g->add_node('Paris', label => 'City of\nlurve', cluster => 'Europe');
$g->add_node('New York');

$g->add_edge('London' => 'Paris');
$g->add_edge('London' => 'New York', label => 'Far');
$g->add_edge('Paris' => 'London');
-- expect --
digraph test {
	"New York" [label="New York"];
	London -> "New York" [label="Far"];
	subgraph cluster_Europe {
		label="Europe";
		London [label="London"];
		Paris [label="City of\nlurve"];
		London -> Paris;
		Paris -> London;
	}
}

-- test --
$g = GraphViz->new({directed => 0, sort => 1});

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
-- expect --
graph test {
	node7 [label="10"];
	node8 [label="12"];
	node9 [label="14"];
	node10 [label="15"];
	node11 [label="16"];
	node1 [label="2"];
	node2 [label="3"];
	node3 [label="4"];
	node4 [label="6"];
	node5 [label="8"];
	node6 [label="9"];
	node7 -- node1;
	node8 -- node1;
	node8 -- node2;
	node8 -- node3;
	node9 -- node1;
	node10 -- node2;
	node11 -- node1;
	node11 -- node3;
	node3 -- node1;
	node4 -- node1;
	node4 -- node2;
	node5 -- node1;
	node5 -- node3;
	node6 -- node2;
}

-- test --
$g = GraphViz->new(sort => 1);

$g->add_node('London', label => ['Heathrow', 'Gatwick']);
$g->add_node('Paris', label => 'CDG');
$g->add_node('New York', label => 'JFK');

$g->add_edge('London' => 'Paris', from_port => 0);

$g->add_edge('New York' => 'London', to_port => 1);
-- expect --
digraph test {
	London [label="<port0>Heathrow|<port1>Gatwick", shape="record"];
	"New York" [label="JFK"];
	Paris [label="CDG"];
	"London":port0 -> Paris;
	"New York" -> "London":port1;
}

-- test --
$g = GraphViz->new(width => 30, height => 20, pagewidth => 8.5, pageheight=> 11, sort => 1);
$g->add_node('London');
$g->add_node('Paris');
$g->add_edge('London' => 'London');
$g->add_edge('Paris' => 'Paris');
$g->add_edge('London' => 'Paris');
$g->add_edge('Paris' => 'London');
-- expect --
digraph test {
	size="30,20";
	ratio=fill
	page="8.5,11";
	London [label="London"];
	Paris [label="Paris"];
	London -> London;
	London -> Paris;
	Paris -> London;
	Paris -> Paris;
}

-- test --
$g = GraphViz->new(concentrate => 1, sort => 1)
-- expect --
digraph test {
	concentrate=true;
}

-- test --
$g = GraphViz->new(epsilon => 0.001, random_start => 1, sort => 1)
-- expect --
digraph test {
	epsilon=0.001;
	start=rand;
}

-- test --
# Test incremental buildup
$g = GraphViz->new(sort => 1);

$g->add_node('London');
$g->add_node('London', cluster => 'Europe');
$g->add_node('London', color => 'blue');
$g->add_node('Paris');
$g->add_node('Paris', label => 'City of\nlurve');
$g->add_node('Paris', cluster => 'Europe');
$g->add_node('Paris', color => 'green');
$g->add_node('New York');
$g->add_node('New York', color => 'yellow');

$g->add_edge('London' => 'Paris');
$g->add_edge('London' => 'New York', label => 'Far', color => 'red');
$g->add_edge('Paris' => 'London');
-- expect --
digraph test {
	"New York" [color="yellow", label="New York"];
	London -> "New York" [color="red", label="Far"];
	subgraph cluster_Europe {
		label="Europe";
		London [color="blue", label="London"];
		Paris [color="green", label="City of\nlurve"];
		London -> Paris;
		Paris -> London;
	}
}

-- test --
$g = GraphViz->new(node => { shape => 'box' }, edge => { color => 'red' }, graph => { rotate => "90" }, sort => 1);
$g->add_node('London');
$g->add_node('Paris', label => 'City of\nlurve');
$g->add_node('New York');

$g->add_edge('London' => 'Paris');
$g->add_edge('London' => 'New York', label => 'Far');
$g->add_edge('Paris' => 'London');

-- expect --
digraph test {
	node [shape="box"];
	edge [color="red"];
	graph [rotate="90"];
	London [label="London"];
	"New York" [label="New York"];
	Paris [label="City of\nlurve"];
	London -> "New York" [label="Far"];
	London -> Paris;
	Paris -> London;
}


-- test --
$g = GraphViz->new(sort => 1);
$g->add_node('a');
$g->add_node('b');
$g->add_node('c');
$g->add_node('d');
$g->add_node('e');
$g->add_node('f');

-- expect --
digraph test {
	a [label="a"];
	b [label="b"];
	c [label="c"];
	d [label="d"];
	e [label="e"];
	f [label="f"];
}

-- test --
$g = GraphViz->new(sort => 1);
$g->add_edge('a' => 'b');
$g->add_edge('b' => 'c');
$g->add_edge('c' => 'a');

-- expect --
digraph test {
	a [label="a"];
	b [label="b"];
	c [label="c"];
	a -> b;
	b -> c;
	c -> a;
}

-- test --
$g = GraphViz->new(sort => 1);

$g->add_node('London');
$g->add_node('Paris', label => 'City of\nlurve', rank => 'top');
$g->add_node('New York');
$g->add_node('Boston', rank => 'top');

$g->add_edge('Paris' => 'London');
$g->add_edge('London' => 'New York', label => 'Far');
$g->add_edge('Boston' => 'New York');

-- expect --
digraph test {
	Boston [label="Boston", rank="top"];
	London [label="London"];
	"New York" [label="New York"];
	Paris [label="City of\nlurve", rank="top"];
	Boston -> "New York";
	London -> "New York" [label="Far"];
	Paris -> London;
	{rank=same; Boston; Paris}
}

-- test --
$g = GraphViz->new(sort => 1, no_overlap => 1);

$g->add_node('London');
$g->add_node('Paris', label => 'City of\nlurve', rank => 'top');
$g->add_node('New York');
$g->add_node('Boston', rank => 'top');

$g->add_edge('Paris' => 'London');
$g->add_edge('London' => 'New York', label => 'Far');
$g->add_edge('Boston' => 'New York');

-- expect --
digraph test {
	overlap=false;
	Boston [label="Boston", rank="top"];
	London [label="London"];
	"New York" [label="New York"];
	Paris [label="City of\nlurve", rank="top"];
	Boston -> "New York";
	London -> "New York" [label="Far"];
	Paris -> London;
	{rank=same; Boston; Paris}
}
