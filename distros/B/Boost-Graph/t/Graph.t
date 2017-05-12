#!/usr/local/bin/perl

use strict;
use Test::More qw(no_plan);
#use lib qw(/workspace/dburdick/boost/test/lib/perl5/site_perl/5.8.5/i686-linux-thread-multi/auto/ /workspace/dburdick/boost/test/lib/perl5/site_perl/5.8.5/i686-linux-thread-multi/);
use lib qw(blib/lib);
use Boost::Graph;
use Boost::Graph::Directed;
use Boost::Graph::Undirected;
use t::testNode;
use Data::Dumper;


#______________________________________________________________________________________________________
# GENERAL TESTS
my $graph = new Boost::Graph();
my $node0 = new t::testNode(id=>'0');
my $node1 = new t::testNode(id=>'1');
my $node2 = new t::testNode(id=>'2');
my $node3 = new t::testNode(id=>'3');
my $node4 = new t::testNode(id=>'4');
my $node5 = new t::testNode(id=>'5');
my $node6 = new t::testNode(id=>'6');
my $node7 = new t::testNode(id=>'7');
#______________________________________________________________________________________________________
# _get_node_id
my $node0_id = $graph->_get_node_id($node0);
my $node1_id = $graph->_get_node_id($node1);
is($node1_id, 2, 'Check _get_node_id');
#______________________________________________________________________________________________________
# add_node
my $ret = $graph->add_node($node2);
is($ret, 1, 'check add_node() for insertion of new node');
$ret=undef;
$ret = $graph->add_node($node1);
is($ret, 0, 'check add_node() for insertion of existing node');
$ret=undef;
#______________________________________________________________________________________________________
# add path
$graph = new Boost::Graph();
$graph->add_path($node0, $node1, $node2, $node3);
is($graph->has_edge($node0,$node1),1,'add_path 0-1');
is($graph->has_edge($node1,$node2),1,'add_path 1-2');
is($graph->has_edge($node2,$node3),1,'add_path 2-3');
#______________________________________________________________________________________________________
# has path
$graph = new Boost::Graph();
$graph->add_path($node0, $node1, $node2, $node3);
is($graph->has_path($node0, $node1, $node2, $node3),1,'has_path 0-1-2-3');
is($graph->has_path($node1, $node2, $node3),1,'has_path sub path 1-2-3');
is($graph->has_path($node1, $node3, $node2),0,'has_path bad path');


#______________________________________________________________________________________________________
# UNDIRECTED GRAPHS
print "# UNDIRECTED GRAPHS\n";

# add_edge (simple)
$graph = new Boost::Graph();
$ret = $graph->add_edge($node0,$node1);
is($ret, 1, 'check add_edge() for insertion of new edge');
is($graph->_get_node_id($node0),1, 'check add_edge() for proper node_id');
is($graph->_get_node_id($node1),2, 'check add_edge() for proper node_id');
$ret=undef;
$ret = $graph->add_edge($node0,$node1);
is($ret, 0, 'check add_edge for insertion of same edge with same objects');
$ret=undef;
#______________________________________________________________________________________________________
# add_edge (named parameters)
$graph = new Boost::Graph();
$ret = $graph->add_edge(node1=>$node0, node2=>$node1, weight=>1.0, edge=>'test obj');
is($ret, 1, 'check add_edge() for insertion of new edge');
is($graph->_get_node_id($node0),1, 'check add_edge() for proper node_id');
is($graph->_get_node_id($node1),2, 'check add_edge() for proper node_id');
$ret=undef;
$ret = $graph->add_edge(node1=>$node0, node2=>$node1, weight=>1.0, edge=>'test obj2');
is($ret, 0, 'check add_edge for insertion of same edge with same objects');
$ret=undef;
#______________________________________________________________________________________________________
# get_nodes
$graph = new Boost::Graph();
$ret = $graph->add_edge(node1=>$node0, node2=>$node1, weight=>1.0, edge=>'test obj1');
$ret = $graph->add_edge(node1=>$node1, node2=>$node2, weight=>1.0, edge=>'test obj2');
$ret = $graph->add_edge(node1=>$node2, node2=>$node0, weight=>1.0, edge=>'test obj3');
my $nodes = $graph->get_nodes();
my @seen = (0,0,0);
foreach my $n (@$nodes) {
	$seen[0] = 1 if $n == $node0;
	$seen[1] = 1 if $n == $node1;
	$seen[2] = 1 if $n == $node2;
}
is($seen[0], 1, 'check get_nodes, recieve node 0');
is($seen[1], 1, 'check get_nodes, recieve node 1');
is($seen[2], 1, 'check get_nodes, recieve node 2');
@seen=undef;
$nodes=undef;
#______________________________________________________________________________________________________
# get_edges
my $edges = $graph->get_edges();
@seen = (0,0,0);
foreach my $e (@$edges) {
	$seen[0] = 1 if $e->[0] == $node0 && 
									$e->[1] == $node1 && 
									$e->[2] eq 'test obj1';
	$seen[1] = 1 if $e->[0] == $node1 && 
									$e->[1] == $node2 && 
									$e->[2] eq 'test obj2';
	$seen[2] = 1 if $e->[0] == $node0 && 
									$e->[1] == $node2 && 
									$e->[2] eq 'test obj3';
}
is($seen[0], 1, 'check get_edges, recieve edge 0-1');
is($seen[1], 1, 'check get_edges, recieve edge 1-2');
is($seen[2], 1, 'check get_edges, recieve edge 0-2');
@seen=undef;
#______________________________________________________________________________________________________
# neighbors
$graph = new Boost::Graph();
$ret = $graph->add_edge(node1=>$node0, node2=>$node1);
$ret = $graph->add_edge(node1=>$node0, node2=>$node2);
$ret = $graph->add_edge(node1=>$node1, node2=>$node3);

$nodes = $graph->neighbors($node0);
@seen = (0,0);
foreach my $n (@$nodes) {
	$seen[0] = 1 if $n == $node1;
	$seen[1] = 1 if $n == $node2;
}
is($seen[0], 1, 'check neighbors, 1 is neighbor of 0');
is($seen[1], 1, 'check neighbors, 1 is neighbor of 0');
is($nodes->[2], undef, 'check that only two neighbors of 0');
@seen=undef;
$nodes=undef;
#______________________________________________________________________________________________________
# transitive_links
$graph = new Boost::Graph();
$ret = $graph->add_edge(node1=>$node0, node2=>$node1);
$ret = $graph->add_edge(node1=>$node0, node2=>$node2);
$ret = $graph->add_edge(node1=>$node0, node2=>$node5);
$ret = $graph->add_edge(node1=>$node1, node2=>$node2);
$ret = $graph->add_edge(node1=>$node1, node2=>$node3);
$ret = $graph->add_edge(node1=>$node2, node2=>$node6);
$ret = $graph->add_edge(node1=>$node3, node2=>$node4);
$ret = $graph->add_edge(node1=>$node4, node2=>$node5);

my @inputs = ($node0,$node3,$node5);
# output should be nodes 2 and 5 as hotspots
my $hotspots = $graph->transitive_links(\@inputs);
@seen = (0,0);
foreach my $n (@$hotspots) {
	$seen[0] = 1 if $n == $node1;
	$seen[1] = 1 if $n == $node4;
}
is($seen[0], 1, 'check node1 is hotspot');
is($seen[1], 1, 'check node4 is hotspot');
is($seen[2], undef, 'check only two hotspots returned');
@seen=undef;
#______________________________________________________________________________________________________
# Breadth & Depth first search
$graph = new Boost::Graph();
$ret = $graph->add_edge(node1=>$node0, node2=>$node1);
$ret = $graph->add_edge(node1=>$node0, node2=>$node4);
$ret = $graph->add_edge(node1=>$node1, node2=>$node2);
$ret = $graph->add_edge(node1=>$node1, node2=>$node3);
$ret = $graph->add_edge(node1=>$node4, node2=>$node5);
$ret = $graph->add_edge(node1=>$node4, node2=>$node6);
$ret = $graph->add_edge(node1=>$node5, node2=>$node7);

my $bfs = $graph->breadth_first_search($node0);
is($bfs->[0]->{id},0,"Breadth First Search (0 root): 0");
is($bfs->[1]->{id},1,"Breadth First Search (0 root): 1");
is($bfs->[2]->{id},4,"Breadth First Search (0 root): 4");
is($bfs->[3]->{id},2,"Breadth First Search (0 root): 2");
is($bfs->[4]->{id},3,"Breadth First Search (0 root): 3");
is($bfs->[5]->{id},5,"Breadth First Search (0 root): 5");
is($bfs->[6]->{id},6,"Breadth First Search (0 root): 6");
is($bfs->[7]->{id},7,"Breadth First Search (0 root): 7");
$bfs=undef;

my $dfs = $graph->depth_first_search($node0);
is($dfs->[0]->{id},0,"Depth First Search (0 root): 0");
is($dfs->[1]->{id},1,"Depth First Search (0 root): 1");
is($dfs->[2]->{id},2,"Depth First Search (0 root): 2");
is($dfs->[3]->{id},3,"Depth First Search (0 root): 3");
is($dfs->[4]->{id},4,"Depth First Search (0 root): 4");
is($dfs->[5]->{id},5,"Depth First Search (0 root): 5");
is($dfs->[6]->{id},7,"Depth First Search (0 root): 7");
is($dfs->[7]->{id},6,"Depth First Search (0 root): 6");
$dfs=undef;
#______________________________________________________________________________________________________
# Dijkstras Shortest path
$graph = new Boost::Graph();
$graph->add_edge(node1=>$node0, node2=>$node1, weight=>1);
$graph->add_edge(node1=>$node0, node2=>$node4, weight=>1);
$graph->add_edge(node1=>$node1, node2=>$node2, weight=>1);
$graph->add_edge(node1=>$node1, node2=>$node3, weight=>1);
$graph->add_edge(node1=>$node4, node2=>$node5, weight=>1);
$graph->add_edge(node1=>$node4, node2=>$node6, weight=>1);
$graph->add_edge(node1=>$node5, node2=>$node7, weight=>1);
$graph->add_edge(node1=>$node0, node2=>$node7, weight=>4);
my $dijk = $graph->dijkstra_shortest_path($node0,$node7);
is($dijk->{weight},3,"Dijkstra weight 0->7: 3");
is($dijk->{path}->[0]->{id},0,"Dijkstra path 0->7: 0");
is($dijk->{path}->[1]->{id},4,"Dijkstra path 0->7: 4");
is($dijk->{path}->[2]->{id},5,"Dijkstra path 0->7: 5");
is($dijk->{path}->[3]->{id},7,"Dijkstra path 0->7: 7");
$dijk=undef;
#______________________________________________________________________________________________________
# all pairs shortest path: Johnson
$graph = new Boost::Graph();
$graph->add_edge(node1=>$node0, node2=>$node1, weight=>3);
$graph->add_edge(node1=>$node0, node2=>$node2, weight=>8);
$graph->add_edge(node1=>$node0, node2=>$node4, weight=>4);
$graph->add_edge(node1=>$node1, node2=>$node3, weight=>1);
$graph->add_edge(node1=>$node1, node2=>$node4, weight=>7);
$graph->add_edge(node1=>$node2, node2=>$node1, weight=>4);
$graph->add_edge(node1=>$node3, node2=>$node0, weight=>2);
$graph->add_edge(node1=>$node3, node2=>$node2, weight=>5);
$graph->add_edge(node1=>$node4, node2=>$node3, weight=>6);
my $allp = $graph->all_pairs_shortest_paths_johnson($node0,$node3);
is($allp,2, "All Pairs Shortest Path Johnson for 0->3: 2");
$allp=undef;
#______________________________________________________________________________________________________
# all pairs shortest path: Floyd Warshall
$graph = new Boost::Graph();
$graph->add_edge(node1=>$node0, node2=>$node1, weight=>3);
$graph->add_edge(node1=>$node0, node2=>$node2, weight=>8);
$graph->add_edge(node1=>$node0, node2=>$node4, weight=>4);
$graph->add_edge(node1=>$node1, node2=>$node3, weight=>1);
$graph->add_edge(node1=>$node1, node2=>$node4, weight=>7);
$graph->add_edge(node1=>$node2, node2=>$node1, weight=>4);
$graph->add_edge(node1=>$node3, node2=>$node0, weight=>2);
$graph->add_edge(node1=>$node3, node2=>$node2, weight=>5);
$graph->add_edge(node1=>$node4, node2=>$node3, weight=>6);
$allp = $graph->all_pairs_shortest_paths_floyd_warshall($node0,$node3);
is($allp,2, "All Pairs Shortest Path Floyd-Warshall for 0->3: 2");
$allp=undef;
#______________________________________________________________________________________________________# connected components
$graph=undef;
$graph = new Boost::Graph();
$graph->add_edge($node0, $node1);
$graph->add_edge($node0, $node4);
$graph->add_edge($node4, $node1);
$graph->add_edge($node2, $node5);
$graph->add_edge($node3,$node3);
my $components = $graph->connected_components();
for(my $i=0; $i<@$components; $i++) {
  if (@{ $components->[$i] }==3) {
    @seen=undef;
    foreach my $n (@{ $components->[$i] }) {
      $seen[0]=1 if $n == $node0;
      $seen[1]=1 if $n == $node1;
      $seen[2]=1 if $n == $node4;      
    }
    is($seen[0], 1, 'connected_components node0 in 0/1/4 cluster');
    is($seen[1], 1, 'connected_components node1 in 0/1/4 cluster');
    is($seen[2], 1, 'connected_components node4 in 0/1/4 cluster');
  } elsif (@{ $components->[$i] }==2) {  
    @seen=undef;
    foreach my $n (@{ $components->[$i] }) {
      $seen[0]=1 if $n == $node2;
      $seen[1]=1 if $n == $node5;
    }
    is($seen[0], 1, 'connected_components node2 in 2/5 cluster');
    is($seen[1], 1, 'connected_components node5 in 2/5 cluster');
  } elsif (@{ $components->[$i] }==1) {  
    is($components->[$i]->[0],$node3,'connected_components node3 from edge 3-3');
  }
}
@seen=undef;
$components=undef;

#______________________________________________________________________________________________________
# DIRECTED GRAPHS
print "# DIRECTED GRAPHS\n";
$graph = new Boost::Graph(directed=>1);

# children_of
$ret = $graph->add_edge(node1=>$node0, node2=>$node1);
$ret = $graph->add_edge(node1=>$node0, node2=>$node2);
$ret = $graph->add_edge(node1=>$node1, node2=>$node3);
my $children = $graph->children_of_directed($node0);
@seen = (0,0);
foreach my $n (@$children) {
	$seen[0] = 1 if $n == $node1;
	$seen[1] = 1 if $n == $node2;
}
is($seen[0], 1, 'check children of node0 has node1');
is($seen[1], 1, 'check children of node0 has node2');
@seen=undef;
#______________________________________________________________________________________________________
$children = $graph->children_of_directed($node1);
is($children->[0], $node3, 'check children_of node1 has node3');
is($children->[1], undef, 'chech children_of node1 has no more nodes');
#______________________________________________________________________________________________________
# breadth_first_search
$graph = new Boost::Graph(directed=>1);
$ret = $graph->add_edge(node1=>$node0, node2=>$node1);
$ret = $graph->add_edge(node1=>$node0, node2=>$node4);
$ret = $graph->add_edge(node1=>$node1, node2=>$node2);
$ret = $graph->add_edge(node1=>$node1, node2=>$node3);
$ret = $graph->add_edge(node1=>$node4, node2=>$node5);
$ret = $graph->add_edge(node1=>$node4, node2=>$node6);
$ret = $graph->add_edge(node1=>$node5, node2=>$node7);

# breadth first traverse 
my $traversal = $graph->breadth_first_search($node0);
$bfs = $graph->breadth_first_search($node0);
is($bfs->[0]->{id},0,"Breadth First Search (0 root): 0");
is($bfs->[1]->{id},1,"Breadth First Search (0 root): 1");
is($bfs->[2]->{id},4,"Breadth First Search (0 root): 4");
is($bfs->[3]->{id},2,"Breadth First Search (0 root): 2");
is($bfs->[4]->{id},3,"Breadth First Search (0 root): 3");
is($bfs->[5]->{id},5,"Breadth First Search (0 root): 5");
is($bfs->[6]->{id},6,"Breadth First Search (0 root): 6");
is($bfs->[7]->{id},7,"Breadth First Search (0 root): 7");
$bfs=undef;
#______________________________________________________________________________________________________
# depth first traverse
$dfs = $graph->depth_first_search($node0);
is($dfs->[0]->{id},0,"Depth First Search (0 root): 0");
is($dfs->[1]->{id},1,"Depth First Search (0 root): 1");
is($dfs->[2]->{id},2,"Depth First Search (0 root): 2");
is($dfs->[3]->{id},3,"Depth First Search (0 root): 3");
is($dfs->[4]->{id},4,"Depth First Search (0 root): 4");
is($dfs->[5]->{id},5,"Depth First Search (0 root): 5");
is($dfs->[6]->{id},7,"Depth First Search (0 root): 7");
is($dfs->[7]->{id},6,"Depth First Search (0 root): 6");
$dfs=undef;
#______________________________________________________________________________________________________
my $dfsl = $graph->depth_first_search_levels($node0);
is($dfsl->[0]->{node}->{id},0,"Depth First Search Levels (0 root): 0");
is($dfsl->[0]->{depth},0,"Depth First Search Levels (0 root) depth(0): 0");
is($dfsl->[1]->{node}->{id},4,"Depth First Search Levels (0 root): 4");
is($dfsl->[1]->{depth},1,"Depth First Search Levels (0 root) depth(4): 1");
is($dfsl->[2]->{node}->{id},5,"Depth First Search Levels (0 root): 5");
is($dfsl->[2]->{depth},2,"Depth First Search Levels (0 root) depth(5): 2");
is($dfsl->[3]->{node}->{id},7,"Depth First Search Levels (0 root): 7");
is($dfsl->[3]->{depth},3,"Depth First Search Levels (0 root) depth(7): 3");
is($dfsl->[4]->{node}->{id},6,"Depth First Search Levels (0 root): 6");
is($dfsl->[4]->{depth},2,"Depth First Search Levels (0 root) depth(6): 2");
is($dfsl->[5]->{node}->{id},1,"Depth First Search Levels (0 root): 1");
is($dfsl->[5]->{depth},1,"Depth First Search Levels (0 root) depth(1): 1");
is($dfsl->[6]->{node}->{id},2,"Depth First Search Levels (0 root): 2");
is($dfsl->[6]->{depth},2,"Depth First Search Levels (0 root) depth(2): 2");
is($dfsl->[7]->{node}->{id},3,"Depth First Search Levels (0 root): 3");
is($dfsl->[7]->{depth},2,"Depth First Search Levels (0 root) depth(3): 2");
#______________________________________________________________________________________________________
# Dijkstras Shortest path
$graph = new Boost::Graph(directed=>1);
$graph->add_edge(node1=>$node0, node2=>$node1, weight=>1);
$graph->add_edge(node1=>$node0, node2=>$node4, weight=>1);
$graph->add_edge(node1=>$node1, node2=>$node2, weight=>1);
$graph->add_edge(node1=>$node1, node2=>$node3, weight=>1);
$graph->add_edge(node1=>$node4, node2=>$node5, weight=>1);
$graph->add_edge(node1=>$node4, node2=>$node6, weight=>1);
$graph->add_edge(node1=>$node5, node2=>$node7, weight=>1);
$graph->add_edge(node1=>$node0, node2=>$node7, weight=>4);
$dijk = $graph->dijkstra_shortest_path($node0,$node7);
is($dijk->{weight},3,"Dijkstra weight 0->7: 3");
is($dijk->{path}->[0]->{id},0,"Dijkstra path 0->7: 0");
is($dijk->{path}->[1]->{id},4,"Dijkstra path 0->7: 4");
is($dijk->{path}->[2]->{id},5,"Dijkstra path 0->7: 5");
is($dijk->{path}->[3]->{id},7,"Dijkstra path 0->7: 7");
#______________________________________________________________________________________________________
# all pairs shortest path
$graph = new Boost::Graph(directed=>1);
$graph->add_edge(node1=>$node0, node2=>$node1, weight=>3);
$graph->add_edge(node1=>$node0, node2=>$node2, weight=>8);
$graph->add_edge(node1=>$node0, node2=>$node4, weight=>-4);
$graph->add_edge(node1=>$node1, node2=>$node3, weight=>1);
$graph->add_edge(node1=>$node1, node2=>$node4, weight=>7);
$graph->add_edge(node1=>$node2, node2=>$node1, weight=>4);
$graph->add_edge(node1=>$node3, node2=>$node0, weight=>2);
$graph->add_edge(node1=>$node3, node2=>$node2, weight=>-5);
$graph->add_edge(node1=>$node4, node2=>$node3, weight=>6);
$allp = $graph->all_pairs_shortest_paths_johnson($node0,$node2);
is($allp,-3, "All Pairs Shortest Path Johnson for 0->2: -3");
$allp=undef;

# test changed graph!
$graph->add_edge(node1=>$node0, node2=>$node6, weight=>1);
$allp = $graph->all_pairs_shortest_paths_johnson($node0,$node6);
is($allp,1, "All Pairs Shortest Path Johnson for (Altered graph) 0->6: 1");
$allp=undef;
#______________________________________________________________________________________________________
















