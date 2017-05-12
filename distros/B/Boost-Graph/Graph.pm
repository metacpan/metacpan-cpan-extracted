package Boost::Graph;
our $VERSION = '1.4';
#####################################################################################
# Graph.pm
# David Burdick, 11/08/2004
# 
# The main module for the Perl Boost interface
#####################################################################################
use strict;
use Boost::Graph::Directed;
use Boost::Graph::Undirected;

#______________________________________________________________________________________________________________
### Variables
#
# net_id - unique identifier for network
# net_name - name of the network
# _edges - a hash of hashes. First key is first node, second key is second node.
# _nodes - a hash where keys are the the node objects, value is the node_id
# _nodes_lookup - a hash where keys are the unique id for nodes, value is actual object
# _nodecount - the number of nodes in the network 
# _edgecount - the number of edges in the network 
# _node_neighbors - hash on node id, stores a hash whose keys are node ids of its neighbors
#
#______________________________________________________________________________________________________________
### ALGORITHMS
## C++
# breadth_first_search($start_node)
# depth_first_search($start_node)
#
## Perl
# transitive_links($nodes) - receives a listref of nodes and returns a listref of nodes that are (disjoint 
#                             from the input set) transitive connectors of the input set in the current network.
#                             The transitive distance is limited to one node. (i.e. given a and c as input, and 
#                             with edges a-b and b-c, then node b will be returned)
#______________________________________________________________________________________________________________
sub new {
  my $this = shift;
  my %args = @_;
  my $class = ref($this) || $this;
  my $self = {};
  $self->{_nodecount} = 0;
  $self->{_edgecount} = 0;
  if($args{'directed'}) { # connect to C++ libraries
    $self->{_directed} = 1;
    $self->{_bgi} = new Boost::Graph::Directed;
  } else {
    $self->{_directed} = 0;
    $self->{_bgi} = new Boost::Graph::Undirected;
  }
  $self->{net_name} = $args{net_name} if $args{net_name};
  $self->{net_id} = $args{net_id} if $args{net_id};
    
  bless $self, $class;
  return($self);
}
#______________________________________________________________________________________________________________
sub add_edge {
  my ($self, %args) = @_;
  my ($node1, $node2);
  # check for simple edge add
  if(@_ == 3) {
    $node1=$_[1];
    $node2=$_[2];
  } else {
    return unless $args{node1} && $args{node2};
    $node1=$args{node1};
    $node2=$args{node2};
  }
  

  my $weight = $args{weight};
  my $edge_obj = $args{edge};
  $weight or $weight=1.0; 
  $edge_obj or $edge_obj=1;

  # add nodes/get node_id
  my $node1_id = $self->_get_node_id($node1);
  my $node2_id = $self->_get_node_id($node2);
  return undef if $node1_id==0 || $node2_id==0; # problem!
  # check for duplicate edge 
  return 0 if $self->has_edge($node1,$node2);

  # add neighbors
  $self->{_node_neighbors}->{$node1_id}->{$node2_id} = 1;
  $self->{_node_neighbors}->{$node2_id}->{$node1_id} = 1;
  # add parents
  $self->{_node_parents}->{$node2_id}->{$node1_id} = 1;
  # store edge and edge_object
  if($node1_id < $node2_id || $self->{_directed}) {
      $self->{_edges}->{$node1_id}->{$node2_id} = $edge_obj;
  } else {
    $self->{_edges}->{$node2_id}->{$node1_id} = $edge_obj;    
  }
  $self->{_edgecount}++;
  $self->{_bgi}->_addEdge($node1_id,$node2_id,$weight); # C++
  return 1;
}
#______________________________________________________________________________________________________________
sub add_node {
  my ($self, $node) = @_;
  my $isnew = $self->{_nodecount}+1;
  my $node_id = $self->_get_node_id($node);
  if($isnew == $node_id) {
    $self->{_bgi}->_addNode($node_id); # C++
    return 1;
  } else {
    return 0;
  }
}
#______________________________________________________________________________________________________________
sub get_edge {
  my ($self,$source,$sink) = @_;
  my @edges;
  my $source_id = $self->_get_node_id($source);
  my $sink_id = $self->_get_node_id($sink);
  my $a = $self->{_nodes_lookup}->{$source_id};
  my $b = $self->{_nodes_lookup}->{$sink_id};
  return [$a, $b, $self->{_edges}->{$source_id}->{$sink_id}];
}
#______________________________________________________________________________________________________________
sub get_edges {
  my ($self) = @_;
  my @edges;
  foreach my $source (keys %{$self->{_edges}}) {
    foreach my $sink (keys %{$self->{_edges}->{$source}}) {
      my $a = $self->{_nodes_lookup}->{$source};
      my $b = $self->{_nodes_lookup}->{$sink};
      push @edges, [$a, $b, $self->{_edges}->{$source}->{$sink}];
    }
  }
  return \@edges; 
}
#______________________________________________________________________________________________________________
sub get_nodes {  
  my ($self) = @_;
  my @nodes = values %{$self->{_nodes_lookup}};
  return \@nodes;
}
#______________________________________________________________________________________________________________
sub has_edge {
  my ($self,$node1,$node2) = @_;
  if($self->has_node($node1) && $self->has_node($node2)) {
    my $node1_id = $self->_get_node_id($node1);
    my $node2_id = $self->_get_node_id($node2);
    return undef if $node1_id==0 || $node2_id==0; # problem!
    # check for duplicate edge being careful not to make empty hashes on the first id. don't check reverse for directed graphs
    if ($self->{_edges}->{$node1_id}) {
      return 1 if $self->{_edges}->{$node1_id}->{$node2_id};
    } elsif ($self->{_edges}->{$node2_id} && !$self->{_directed}) {
      return 1 if $self->{_edges}->{$node2_id}->{$node1_id};
    }
  }
  return undef;
}
#______________________________________________________________________________________________________________
sub has_node {  
  my ($self,$node,$id_name) = @_;
  return undef unless $node;
  if($id_name) {
    foreach  my $n (values %{$self->{_nodes_lookup}}) {
      return 1 if $n->{$id_name} eq $node->{$id_name};
    }
  } else {
    return 1 if $self->{_nodes}->{$node};
  }
  return undef;
}
#______________________________________________________________________________________________________________
sub neighbors {
  my ($self,$root) = @_;
  my $ids = $self->_neighbors($root);
  my @nodes;
  foreach my $nid (@$ids) {
    push @nodes, $self->{_nodes_lookup}->{$nid};
  }
  return \@nodes;
}
#______________________________________________________________________________________________________________
sub children_of_directed {
  my ($self,$source) = @_;
  die "children_of_directed(...) only for directed graphs." unless $self->{_directed}; 
  return [] unless $self->has_node($source);
  my $nid = $self->_get_node_id($source);
  # retrieve ids of children and return objects
  if($self->{_edges}->{$nid}) {
    my @nodeids = keys %{ $self->{_edges}->{$nid} };
    my @node_objs;
    foreach my $id (@nodeids) {
      push @node_objs, $self->{_nodes_lookup}->{$id};
    }    
    return \@node_objs;
  } 
  return [];
}
#______________________________________________________________________________________________________________
sub parents_of_directed {
  my ($self,$source) = @_;
  die "parents_of_directed(...) only for directed graphs." unless $self->{_directed}; 
  return [] unless $self->has_node($source);
  my $nid = $self->_get_node_id($source);
  # retrieve ids of parents and return objects
  if($self->{_node_parents}->{$nid}) { 
    my @nodeids = keys %{ $self->{_node_parents}->{$nid} };
    my @node_objs;
    foreach my $id (@nodeids) {
      push @node_objs, $self->{_nodes_lookup}->{$id};
    }    
    return \@node_objs;
  } 
  return [];
}
#______________________________________________________________________________________________________________
sub nodecount {
  my ($self) = @_;
  return $self->{_nodecount};
}
#______________________________________________________________________________________________________________
sub edgecount {
  my ($self) = @_;
  return $self->{_edgecount};
}
#______________________________________________________________________________________________________________
sub add_path {
  my ($self,@path) = @_;
  for(my $i=0; $i<@path; $i++) {
    last if ($i+1)>=@path;
    $self->add_edge(node1=>$path[$i],node2=>$path[$i+1]);
  }
  return 1;
}
#______________________________________________________________________________________________________________
sub has_path {
  my ($self,@path) = @_;
  for(my $i=0; $i<@path; $i++) {
    last if ($i+1)>=@path;
    my $has = $self->has_edge($path[$i],$path[$i+1]);
    return 0 if !$has;
  }
  return 1;
}
#______________________________________________________________________________________________________________
### Private methods
# returns a listref of node ids for the neighbors of the node
sub _neighbors {
  my ($self,$root) = @_;
  if($self->has_node($root)) {
    my @result = keys %{ $self->{_node_neighbors}->{$self->_get_node_id($root)} };
    return \@result;
  }
  return undef;
}
#______________________________________________________________________________________________________________
# returns node's unique id. If node doesn't exist, it is added
sub _get_node_id {
  my ($self, $node) = @_;
  my $node_id;
  return undef unless $node;
  if($self->{_nodes}->{$node}) {
    $node_id = $self->{_nodes}->{$node};
  } else {
    $node_id = ++$self->{_nodecount};
    $self->{_nodes}->{$node} = $node_id;
    $self->{_nodes_lookup}->{$node_id} = $node;
  }
  return $node_id;
}
#______________________________________________________________________________________________________________
# takes a listref of node_ids and returns a listref of the actual objects
sub _get_node_list {
  my ($self,$node_order) = @_;
  return undef unless $node_order;
  my @traversed_nodes;
  foreach my $nid (@$node_order) {
    push @traversed_nodes, $self->{_nodes_lookup}->{$nid} if $self->{_nodes_lookup}->{$nid};
  }
  return \@traversed_nodes;
}



#______________________________________________________________________________________________________________
### PERL ALGORITHMS
# transitive_links($nodes) - receives a listref of nodes and returns a listref of nodes that are (disjoint 
#                             from the input set) transitive connectors of the input set in the current network.
#                             The transitive distance is limited to one node. (i.e. given a and c as input, and 
#                             with edges a-b and b-c, then node b will be returned)
sub transitive_links {
  my ($self,$roots) = @_;
  return undef unless $roots;
  my %rootids; # keys are id's for input nodes
  my %hotspots; # keys are id's for hotspot nodes in the graph, values are the nodes
  
  # get id's for each node that's in the graph (none added)
  foreach my $node (@$roots) {
    $rootids{$self->_get_node_id($node)} = 1 if $self->has_node($node);
  }
  # find transitive nodes for each input node
  foreach my $nid (keys %rootids) {
    my $nbors = $self->_neighbors($self->{_nodes_lookup}->{$nid});
    foreach my $nbor_id (@$nbors) {
      next if $hotspots{$nbor_id} || $rootids{$nbor_id}; # skip node if it's a hotspot already or in the input list
      my $oneoff_nbors = $self->_neighbors($self->{_nodes_lookup}->{$nbor_id});

      # this node is a hotspot if the neighbors contain a node in the input list that is not the start node
#      my $num_oons = scalar @{$oneoff_nbors};
      foreach my $oneoff_nbors_id (@$oneoff_nbors) {
        next if $hotspots{$nbor_id};
#        my $oneoff_nbors_id = $oneoff_nbors->[$i];
        if ($rootids{$oneoff_nbors_id} && $oneoff_nbors_id != $nid) {
          $hotspots{$nbor_id} = $self->{_nodes_lookup}->{$nbor_id};
        }
      }
    }
  }
  my @retlist = values %hotspots;
  return \@retlist;
}
#______________________________________________________________________________________________________________
# Depth First Search with node level information
sub depth_first_search_levels {
  my ($self,$node) = @_;
  return unless $self->has_node($node) && $self->{_directed};
  my @ret;
  $self->_depth_first_search_levels(\@ret,$node,0);
  return \@ret;
}
sub _depth_first_search_levels {
  my ($self,$ret,$node,$depth) = @_;
  my %tmp;
  $tmp{node} = $node;
  $tmp{depth} = $depth;
  push @$ret,\%tmp;
  foreach my $child (@{$self->children_of_directed($node)}) {
    $self->_depth_first_search_levels($ret,$child,$depth+1);
  }
}
#______________________________________________________________________________________________________________





#______________________________________________________________________________________________________________
### C++ ALGORITHMS
# Breadth First Search
sub breadth_first_search {
  my ($self,$start_node) = @_;
  return undef unless $start_node && $self->has_node($start_node);
  
  my $start_node_id = $self->_get_node_id($start_node);
  return undef unless $start_node_id;
  my @node_order = $self->{_bgi}->breadthFirstSearch($start_node_id);
  return $self->_get_node_list(\@node_order);
}
#______________________________________________________________________________________________________________
# Depth First Search
sub depth_first_search {
  my ($self,$start_node) = @_;
  return undef unless $start_node && $self->has_node($start_node);
  
  my $start_node_id = $self->_get_node_id($start_node);
  return undef unless $start_node_id;
  my @node_order = $self->{_bgi}->depthFirstSearch($start_node_id);
  return $self->_get_node_list(\@node_order);
}
#______________________________________________________________________________________________________________
### Shortest Paths Algorithms ###
#______________________________________________________________________________________________________________
# Dijkstra's Shortest Paths
# returns hashref: {path|weight}. path is a listref, weight is a scalar
sub dijkstra_shortest_path {
  my ($self,$start_node,$end_node) = @_;
  return undef unless $start_node && $self->has_node($start_node) && $end_node && $self->has_node($end_node);
  
  my %ret;
  my $start_id = $self->_get_node_id($start_node);
  my $end_id = $self->_get_node_id($end_node);
  my ($path_wt,@node_order) = $self->{_bgi}->dijkstraShortestPath($start_id,$end_id);
  $ret{weight}=$path_wt;
  $ret{path}=$self->_get_node_list(\@node_order);

  return \%ret;
}
#______________________________________________________________________________________________________________
# Johnsons All Pairs Shortest Paths
# returns path weight.
sub all_pairs_shortest_paths_johnson {
  my ($self,$start_node,$end_node) = @_;
  return undef unless $start_node && $self->has_node($start_node) && $end_node && $self->has_node($end_node);
  
  my $ret;
  my $start_id = $self->_get_node_id($start_node);
  my $end_id = $self->_get_node_id($end_node);
  $ret = $self->{_bgi}->allPairsShortestPathsJohnson($start_id,$end_id);

  return $ret;
}
#______________________________________________________________________________________________________________
# Floyd-Warshall All Pairs Shortest Paths
# returns path weight.
sub all_pairs_shortest_paths_floyd_warshall {
  my ($self,$start_node,$end_node) = @_;
  return undef unless $start_node && $self->has_node($start_node) && $end_node && $self->has_node($end_node);
  
  my $ret;
  my $start_id = $self->_get_node_id($start_node);
  my $end_id = $self->_get_node_id($end_node);
  $ret = $self->{_bgi}->allPairsShortestPathsFloydWarshall($start_id,$end_id);

  return $ret;
}
#______________________________________________________________________________________________________________
### Minimum Spanning Tree Algorithms ###
#______________________________________________________________________________________________________________
### Connected Components Algorithms ###
#______________________________________________________________________________________________________________
# Connected Components
sub connected_components {
  my ($self) = @_;
  die "connected_components(...) only for undirected graphs." if $self->{_directed}; 
  
  my @clusters; # list of listrefs that represent the connected clusters
  my @components = $self->{_bgi}->connectedComponents();
  for(my $node_id=0; $node_id<@components; $node_id++) {
    my $cluster = $components[$node_id];
    my $node_obj = $self->{_nodes_lookup}->{$node_id};
    if (defined($node_obj)) {
      push @{ $clusters[$cluster] }, $node_obj;
    }
  }
  shift @clusters if !defined($clusters[0]); # remove empty 0 node (we use non-zero indexing for node ids)
  return \@clusters;
}
#______________________________________________________________________________________________________________


#<link rel="stylesheet" href="http://search.cpan.org/s/style.css" type="text/css">
#<link rel="alternate" type="application/rss+xml" title="RSS 1.0" href="http://search.cpan.org/uploads.rdf">

1;
__END__

=head1 NAME

Boost::Graph - Perl interface to the Boost-Graph C++ libraries.

=head1 SYNOPSIS

  use Boost::Graph;
  # Create an empty instance of a Graph
  my $graph = new Boost::Graph(directed=>0, net_name=>'Graph Name', net_id=>1000); 

  # add edges
  $graph->add_edge(node1=>'a', node2=>'b', weight=>1.1, edge=>'edge name');
  $graph->add_edge(node1=>$node1, node2=>$node2, weight=>2.3, edge=>$edge_obj);

=head1 ABSTRACT

  Boost::Graph is a perl interface to the Boost-Graph C++ libraries that offer
  many efficient and peer reviewed algorithms. 

=head1 DESCRIPTION

Boost::Graph is a perl interface to the Boost-Graph C++ libraries that offer
many efficient and peer reviewed algorithms. 

=head1 INSTALLATION

Installation works as with any other CPAN distribution. This package comes bundled with the Boost Graph 
C++ Library, version 1.33. This allows the package to install without any extra installation steps. 
However, if you would like to use a different version of Boost, you can edit the following line in 
Directed/Makefile.PL and Undirected/Makefile.PL to point to your installation:
   
  'INC' => '-I. -I../include -I/usr/local/include/boost-1_33/', 

note, the Boost Library location on the example system is located in /usr/local/include/boost-1_33/

See http://www.boost.org/libs/graph/doc/

=head1 Methods

=head3 new [Constructor]

To add edges and nodes to a graph, you must first instantiate the class using this method.

  Input Parameters [Optional]:
  - directed: set to 1 for a directed graph (edges with source and sink nodes)
  - net_name: a name for the graph
  - net_id: an id stored in the object for the graph 

  Returns:
  An empty instance of the Boost::Graph object

  Usage: 
  my $graph = new Boost::Graph();
  my $graph = new Boost::Graph(directed=>0, net_name=>'Graph Name', net_id=>1000);

=head3 Accessors

=head4 add_edge

The method adds the given nodes and the edge between them to the graph. In and
undirected graph, the order of the nodes does not matter. In a directed graph, node1
is the source and node2 is the sink. The edge parameter can be used to store an object along
with the pairing. The weight parameter can give a numeric value to the edge (default 1.0).

There are two ways to use this method:

  $graph->add_edge($node1,$node2);

  -- or --  

  $graph->add_edge(node1=>$node1, node2=>$node2, weight=>$weight, edge=>$edge);

The first method simply adds the edge to the graph with the default weight of 1.0 and no edge object. In a directed
graph, the first node is used as the source and the second as the sink. If you would like to specify an edge weight
or include an object with the edge, use the named parameter version. 

  Named Parameters version:
  - node1: the source node
  - node2: the sink node
  - weight: the weight value for the edge (a number) [optional]
  - edge: an scalar or object to be associated with the edge [optional]

  Returns:
  1 if the edge is new, 0 if edge exists already.

=head4 add_node

  $graph->add_node($node);

Adds the node to the network (only needed for disjoint nodes). Returns 1 if node is new, 0 if node exists already.

=head4 get_edges

  $graph->get_edges(); 

Returns a reference to a list of edges that are 3 part lists: [node1, node2, edge_object].

=head4 get_nodes

  $graph->get_nodes();

Returns a reference to a list of all the nodes.

=head4 has_edge

  $graph->has_edge($node1,$node2);

Returns 1 if the given edge is in the graph.

=head4 has_node

  $graph->has_node($node);

Returns 1 if the passed node is in the network (checks for identical object makeup).

=head4 neighbors

  $graph->neighbors($node);

Returns the nodes that are neighbors of this node.

=head4 children_of_directed

  $graph->children_of_directed($node);

Returns a listref of the nodes that are children of the input node. For Directed graphs only.

=head4 parents_of_directed

  $graph->parents_of_directed($node);

Returns a listref of the nodes that are parents of the input node. For Directed graphs only.

=head4 nodecount

  $graph->nodecount();

Returns the number of nodes in the graph.

=head4 edgecount

  $graph->edgecount();

Returns the number of edges in the graph.

=head3 Paths and Cycles

Paths and cycles are simple extensions of edges: paths are edges starting from where the previous edge ended, and cycles are paths returning back to the start vertex of the first edge.

=head4 add_path

  $graph->add_path($a, $b, $c, ..., $x, $y, $z)

Add the edges $a-$b, $b-$c, ..., $x-$y, $y-$z to the graph. Returns the graph.

=head4 has_path

  $graph->has_path($a, $b, $c, ..., $x, $y, $z)

Return true if the graph has all the edges $a-$b, $b-$c, ..., $x-$y, $y-$z, false otherwise.


=head1 Graph Algorithms

=head4 breadth_first_search

  $graph->breadth_first_search($start_node);

Receives the start node and returns a listref of nodes from a breadth first traversal of the graph.

=head4 depth_first_search

  $graph->depth_first_search($start_node);

Receives the start node and returns a listref of nodes from a depth first traversal of the graph.

=head4 dijkstra_shortest_path

  $graph->dijkstra_shortest_path($start_node,$end_node);

Dijkstra's Shortest Path algorithm finds the shortest weighted-path between the start and end nodes.

Returns a hashref with keys:

  - path: path is a listref of the nodes in the path
  - weight: weight is a scalar giving the total weight of the path

=head4 all_pairs_shortest_paths_johnson

  $graph->all_pairs_shortest_paths_johnson($start_node,$end_node);

Johnsons' All pairs shortest paths, computes the shortest path between all nodes. Good for sparce graphs. 

The first time this method is called, the shortest path between each pair 
of nodes in the graph is computed. The total weight of the path between the start and end node is returned. Unless 
the graph is altered, the original matrix does not need to be re-computed.

=head4 all_pairs_shortest_paths_floyd_warshall

  $graph->all_pairs_shortest_paths_floyd_warshall($start_node,$end_node);

Floyd-Warshall's All pairs shortest paths, computes the shortest path between all nodes. Good for dense graphs.

The first time this method is called, the shortest path between each pair 
of nodes in the graph is computed. The total weight of the path between the start and end node is returned. Unless 
the graph is altered, the original matrix does not need to be re-computed.

=head4 connected_components

  $graph->connected_components();
  
For an undirected graph, returns the nodes of the connected components of the graph as a list of 
anonymous arrays. The ordering of the anonymous arrays or the ordering of the nodes inside the 
anonymous arrays (the components) is undefined.

=head4 transitive_links

  $graph->transitive_links($nodes); 

Receives a listref of nodes and returns a listref of nodes that are (disjoint 
from the input set) transitive connectors of the input set in the current network.
The transitive distance is limited to one node. (i.e. given a and c as input, and 
with edges a-b and b-c, then node b will be returned). Note: Perl Implementation, not part of the BGL.


=head2 EXPORT

None by default.


=head1 SEE ALSO

The Boost Graph Library (BGL): http://www.boost.org/libs/graph/doc/

=head1 AUTHOR

David Burdick, E<lt>dburdick@systemsbiology.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by David Burdick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut



