#
# BioPerl module for Bio::Network::ProteinNet
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::Network::ProteinNet - a representation of a protein interaction graph.

=head1 SYNOPSIS

  # Read in from file
  my $graphio = Bio::Network::IO->new(-file   => 'human.xml',
                                      -format => 'psi25');
  my $graph = $graphio->next_network();

  my @edges = $gr->edges;

  for my $edge (@edges) {
    for my $node ($edge->[0],$edge->[1]) {
      my @proteins = $node->proteins;
      for my $protein (@proteins) {
        print $protein->display_id," ";
      }
    }
  }

=head1 Perl Graph module

The bioperl-network package uses the Perl Graph module, use version .86 or greater.

=head2 Working with Nodes

A Node object represents either a protein or a protein complex. Nodes can
be retrieved through their identifiers:

  # Get a node (represented by a sequence object) from the graph.
  my $node = $graph->get_nodes_by_id('UniProt:P12345');

  # A node that's a protein can be treated just like a Sequence object
  print $node->seq;

  # Remove a node by specifying its identifier
  $graph->remove_nodes($graph->get_nodes_by_id('UniProt:P12345'));

  # How many nodes are there?
  my $ncount = $graph->nodes();

  # Get interactors of your favourite protein
  my $node = $graph->get_nodes_by_id('RefSeq:NP_023232');
  my @neighbors = $graph->neighbors($node); 
  print "      NP_023232 interacts with ";
  print join " ,", map{$_->primary_id()} @neighbors;
  print "\n";

  # Annotate your sequences with interaction info
  my @seq_objects = ($seq1, $seq2, $seq3);
  for my $seq (@seq_objects) {
    if ( $graph->get_nodes_by_id($seq->accession_number) ) {
       my $node = $graph->get_nodes_by_id( $seq->accession_number);
       my @neighbors = $graph->neighbors($node);
       for my $n (@neighbors) {
          my $ft = Bio::SeqFeature::Generic->new(
                    -primary_tag => 'Interactor',
                    -tag         => { id => $n->accession_number }
                   );
          $seq->add_SeqFeature($ft);
        }
     }
  }

  # Get proteins with > 10 interactors
  my @nodes = $graph->nodes();
  my @hubs;
  for my $node (@nodes) {
    if ($graph->neighbors($node) > 10) {
       push @hubs, $node;
    }
  }
  print "the following proteins have > 10 interactors:\n";
  print join "\n", map {$_->primary_id()} @hubs;

  # Get clustering coefficient of a given node.
  my $id = "RefSeq:NP_023232";
  my $cc = $graph->clustering_coefficient($graph->get_nodes_by_id($id));
  if ($cc != -1) {  ## result is -1 if cannot be calculated
    print "CC for $id is $cc";
  }

=head2 Working with Edges

  # How many edges are there?
  my $ecount = $graph->edges;

  # Get all the paired nodes, or edges, in the graph as an array
  my @edges = $graph->edges

=head2 Working with Interactions

  # How many interactions are there?
  my $icount = $graph->interactions;

  # Retrieve all interactions
  my @interx = $graph->interactions;

  # Get interactions above a threshold confidence score
  for my $interx (@interx) {
	 if ($interx->weight > 0.6) {
		 print $interx->primary_id, "\t", $interx->weight, "\n";
	 }
  }

=head2 Working with Graphs

  # Get graph density
  my $density = $graph->density();

  # Get connected sub-graphs
  my @graphs = $graph->connected_components();

  # Copy interactions from one graph to another
  $graph1->add_interactions_from($graph2);


=head2 Creating networks from your own data

If you have interaction data in your own format, e.g. 

  <interaction id>  <protein id 1>  <protein id 2>  <score>

A simple approach would look something like this:

  my $io = Bio::Root::IO->new(-file => 'mydata');
  my $graph = Bio::Network::ProteinNet->new(refvertexed => 1);

  while (my $l = $io->_readline() ) {
     my ($id, $nid1, $nid2, $sc) = split /\s+/, $l;

     my $prot1 = Bio::Seq->new(-accession_number => $nid1);
     my $prot2 = Bio::Seq->new(-accession_number => $nid2);

     # create new Interaction object based on an id and weight
     my $interaction = Bio::Network::Interaction->new(-id   => $id,
                                                    -weight => $sc );
     $graph->add_interaction(-nodes => [($prot1,$prot2)]),
                             -interaction => $interaction );
  }


=head1 DESCRIPTION

A ProteinNet is a representation of a protein interaction network.
Its functionality comes from the L<Graph> module of Perl and from BioPerl,
the nodes or vertices in the network are Sequence objects.

=head2 Nodes

A node is one or more BioPerl sequence objects, a L<Bio::Seq> or 
L<Bio::Seq::RichSeq> object. Essentially the graph can use any objects 
that implement L<Bio::AnnotatableI> and L<Bio::IdentifiableI> interfaces 
since these objects hold useful identifiers. This is relevant since the 
identity of nodes is determined by their identifiers.

=head2 Interactions and Edges

Since bioperl-network is built on top of the L<Graph> and L<Graph::Undirected> 
modules of Perl it uses its formal model as well. An Edge corresponds to a 
pair of nodes, and there is only one Edge per pair. An Interaction is an 
attribute of an Edge, and there can be 1 or more Interactions per Edge. So

  $ecount = $network->edges

Tells you how many paired nodes there are and

  $icount = $network->interactions

Tells you how many node-node interactions there are. An Interaction is 
equivalent to one experiment or one experimental observation. 

=head1 FOR DEVELOPERS

In this module, the nodes or vertexes are represented by L<Bio::Seq>
objects containing database identifiers but usually
without sequence, since the data is parsed from protein-protein
interaction data.

Interactions should be L<Bio::Network::Interaction> objects, which are 
L<Bio::IdentifiableI> implementing objects. At present Interactions only 
have an identifier and a weight() method, to hold confidence data.

A ProteinNet object has the following internal data, aside from the data
structures of Graph itself:

=over 2

=item _id_map

Look-up hash ('_id_map') for finding a node using any of its ids. The keys
are standard identifiers (e.g. "GenBank:A12345") and the values are 
memory addresses used by Graph (e.g. "Bio::Network::Node=HASH(0x1bc53e4)"). 

=item _interx_id_map

Look-up hash for Interactions ('_interx_id_map'),used for retrieving an 
Interaction object using an identifier.  The keys are primary ids of the 
Interaction (e.g. "DIP:2341E") and the values are addresses of 
Interactions (e.g. "Bio::Network::Interaction=HASH(0x1bc46f2)"). 

=back

The function of these hashes is either to facilitate fast lookups or 
to cache data.

=head1 API CHANGES

These modules were first released as part of the core BioPerl package
and were called Bio::Graph. Bio::Graph was copied to a separate package,
bioperl-network, and renamed Bio::Network. All of the modules were
revised and a new module, Interaction.pm, was added. The
functionality of the PSI MI parser, IO/psi.pm, was significantly
enhanced.

Graph manipulation in Bio::Graph was based on the Bio::Graph::SimpleGraph 
module by Nat Goodman. The first release as a separate package, 
bioperl-network, replaced SimpleGraph with the Perl Graph package. Other 
API changes were also made, partly to keep nomenclature consistent with 
BioPerl, partly to use the terms used by the interaction databases, and 
partly to accomodate the differences between Graph and 
Bio::Graph::SimpleGraph.

The advantages to using Graph are that Bioperl developers are not
responsible for maintaining the code that actually handles graph
manipulation and there is more functionality in Graph than in SimpleGraph.

=over 13

=item Bio::Graph::Edge

Bio::Graph::Edge has been replaced by Bio::Network::Interaction
and Bio::Network::Edge 

=item next_graph()

This method has been replaced by next_network().

=item union()

The union() method has been removed since it was not performing a true
union. It has been replaced by L<add_interaction_from>

=item remove_nodes()

remove_nodes() is now an alias to Graph::delete_vertices

=item _get_ids_by_db() 

_get_ids_by_db() has been renamed L<get_ids_by_node>

=item add_node()

add_node() is now an alias to Graph::add_vertex

=item components()

components() is now an alias to Graph::connected_components

=item edge_count()

edge_count() is now an alias to Graph::edges

=item node_count() 

node_count() is now an alias to Graph::vertices

=item nodes_by_id() 

nodes_by_id() is now an alias to L<get_nodes_by_id>

=item edge_by_id() 

This method has been removed since edges no longer have identifiers,
Interactions do. Use L<get_interaction_by_id>

=item unconnected_nodes() 

unconnected_nodes() is now an alias to Graph::isolated_vertices

=item object_id()

object_id() is now an alias to Interaction::primary_id()

=back

=head1  REQUIREMENTS

To use this module you need Graph.pm, version .80 or greater. To 
read XML data (e.g. PSI XML) you will need XML::Twig.

=head1 SEE ALSO

L<Bio::Network::IO>
L<Bio::Network::Edge>
L<Bio::Network::Node>
L<Bio::Network::Interaction>
L<Bio::Network::IO::dip>
L<Bio::Network::IO::psi>

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists. Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHORS

Brian Osborne bosborne at alum.mit.edu
Richard Adams richard.adams@ed.ac.uk

Maintained by Brian Osborne

The first version of this package was based on the Bio::Graph::SimpleGraph
module written by Nat Goodman.

=cut

package Bio::Network::ProteinNet;
use strict;
use Graph 0.86;
use Bio::Network::Interaction;
use Bio::Root::Root;
use vars qw($GRAPH_ARRAY_INDEX @ISA);
@ISA = qw( Graph::Undirected Bio::Root::Root );

# A Graph object is an array reference, therefore we need
# to add all our additional data at a specific, arbitrary index 
$GRAPH_ARRAY_INDEX = 5;


=head2 get_interaction_by_id

 Name      : get_interaction_by_id
 Purpose   : Get an interaction using an id
 Usage     : $interx = $g->get_interaction_by_id($id)
 Returns   : One or more Interactions
 Arguments : One or more Interaction identifiers, the primary id

=cut

sub get_interaction_by_id {
	my ($self,@ids) = @_;
	$self->throw("I need an identifier!") unless (@ids);
	my @interx;
	for my $id (@ids) {
	   my @temp;
		push @temp, $self->[$GRAPH_ARRAY_INDEX]->{'_interx_id_map'}->{$id};
		$self->warn("More than 1 Interaction retrieved using id $id") if ($#temp > 0);
		push @interx,@temp;
	}
	scalar @interx == 1 ? return $interx[0] : return @interx;
}

=head2 get_nodes_by_id

 Name      : get_nodes_by_id
 Purpose   : Get node using an id
 Usage     : $node = $g->get_nodes_by_id($id)
 Returns   : One node
 Arguments : One or more protein identifiers

=cut

sub get_nodes_by_id {
	my $self = shift;
	my @ids = @_;
	my @nodes  = $self->_ids(@ids);
	unless (@nodes) {
		my $str = join " ",@ids;
		$self->warn("No nodes retrieved using these ids: $str");
		return 0;
	}
	if ($#nodes > 0) {
		my $str = join " ",@ids;
		#$self->warn("Returning >1 node retrieved using these ids: $str");
		return @nodes;
	}
	$nodes[0];
}

=head2 get_interactions

  Name      : get_interactions
  Purpose   : Get 1 or more Interaction objects given a pair of nodes 
  Usage     : @interx = $g->get_interactions($n1,$n2)
  Returns   : A hash of Interaction objects where the key is the primary
              id of the Interaction and the value is the Interaction
  Arguments : 2 nodes
  Notes     : 

=cut

sub get_interactions {
	my ($self,@nodes) = @_;

	$self->throw("The get_interactions method needs 2 nodes, not ". 
					 scalar @nodes . " nodes") if ($#nodes != 1);

	for my $node (@nodes) {
		$self->throw("Node must be a Bio::Network::Node object, not a [". ref($node) . "].") 
		  unless ($node->isa("Bio::Network::Node"));
	}

	my $interactions = $self->get_edge_attributes(@nodes);
	%$interactions;
}

=head2 add_id_to_interaction

 Name      : add_id_to_interaction
 Purpose   : Store identifiers in an internal hash that is used to look
             up interactions by id - this does not add ids to Interaction 
             objects. 
 Usage     : $g->add_id_to_interaction($id,$interaction)
 Arguments : Identifier and Interaction object.
 Returns   : 
 Notes     : The identifier should be concatenated
             with a database or namespace name in order to make
             accurate comparisons when you are merging data from different 
             formats. Examples: DIP:3455E.
             Use _get_standard_name() to find a standardized name.

See L<_get_standard_name>

=cut

sub add_id_to_interaction {
	my ($g,$id,$interx) = @_;

	$g->throw("Node must be a Bio::Network::Interaction object, not a ["
		   . ref($interx) . "]." ) unless ($interx->isa("Bio::Network::Interaction"));

	$g->[$GRAPH_ARRAY_INDEX]->{'_interx_id_map'}->{$id} = $interx if $id;
}

=head2 add_id_to_node

 Name      : add_id_to_node
 Purpose   : Store identifiers in an internal hash that is used to look
             up nodes by id - this does not add ids to Node objects
             or their associated Annotation objects. 
 Usage     : $g->add_id_to_node($id,$node)   or
             $g->add_id_to_node(\@ids,$node)
 Arguments : Identifier (or reference to an array of identifiers), node.
 Returns   : 
 Notes     : The identifier should be concatenated
             with a database or namespace name in order to make
             accurate comparisons when you are merging data from different 
             formats. Examples: DIP:3455N, UniProt:Q45772, GenBank:7733911.
             Use _get_standard_name() to find a standardized name.

See L<_get_standard_name>

=cut

sub add_id_to_node {
	my ($g,$id,$node) = @_;

	$g->throw("Node must be a Bio::Network::Node object, not a ["
			 . ref($node) . "]." ) unless ($node->isa("Bio::Network::Node"));
	$g->throw("Node $node does not exist, cannot add edge")
	  unless ($g->has_node($node));

	if (ref $id eq "ARRAY") {
		my @ids = @$id;
		for my $id (@ids) {
			next unless $id;
			$g->[$GRAPH_ARRAY_INDEX]->{'_id_map'}->{$id} = $node;
		}
	} else {
		$g->[$GRAPH_ARRAY_INDEX]->{'_id_map'}->{$id} = $node if $id;
	}	
}

=head2 add_interactions_from

 Name        : add_interactions_from
 Purpose     : To copy interactions from one graph to another
 Usage       : $graph1->add_interactions_from($graph2)
 Returns     : void
 Arguments   : A Graph object of the same class as the calling object. 
 Description : This method copies interactions from the graph passed as the 
               argument to the calling graph. To take account of 
               differing IDs identifying the same protein, all ids are
               compared. The following rules are used:

         1. If a pair of nodes exist in both graphs then:
            a. No Interactions with the same primary id will be copied
               from $graph2 to $graph1.
            b. All other Interactions from $graph2 will be copied
               to $graph1, even if these nodes do not interact in $graph1.

         2. Nodes are never copied from $graph2 to $graph1. This is rather 
            conservative but prevents the problem of having duplicated,
            identical nodes in $graph1 due to the same protein being identified 
            by different ids in the 2 graphs.

         So, for example 

              Interaction   N1    N2   Comment

    Graph 1:  E1            P1    P2
              E2            P3    P4
              E3            P1    P4

    Graph 2:  E1            P1    P2   E1 will not be copied to Graph1
              X2            P1    P3   X2 will be copied to Graph 1
              X3            P1    P4   X3 will be copied to Graph 1
              X4            Z4    Z5   Nothing copied to Graph1

         There are measures one could take to allow copying nodes from $graph2
         to $graph1, currently unimplemented:

         1. Use sequence, if available, and some threshold measure of similarity,
            or length, to prove that proteins are not identical and can be copied.

         2. Use species information. For example, if $graph1 is entirely composed
            of human proteins then any non-human proteins could be copied to
            $graph1 without risk (and cross-species interactions are fairly common
            due the nature of interaction experiments).

         3. Use namespace or dataspace when assessing identity. For example, assume
            that all nodes in $graph1 are identified by Swissprot ids. Assume a 
            protein in $graph2 is also identified by a Swissprot id, not found in
            $graph1. This could be reasonable grounds for allowing the protein in
            $graph2 to be copied to $graph1.

          4. Some combination of the above.

=cut

sub add_interactions_from {
	my ($graph1, $graph2) = @_;
	my $class = ref($graph1);
	$graph1->throw("add_interaction_from() needs a ". $class . " object, not a [".
					 ref($graph2). "] object") unless ($graph2->isa($class));
	my (%common_ids,%common_nodes);
	
	# get identifiers found in both graphs
	for my $id ( (keys %{$graph1->[$GRAPH_ARRAY_INDEX]->{'_id_map'}}),
					 (keys %{$graph2->[$GRAPH_ARRAY_INDEX]->{'_id_map'}}) ) {
		$common_ids{$id}++;
	}
	# get nodes corresponding to identifiers found in both graphs
	for my $id (keys %common_ids) {
		if ($common_ids{$id} == 2) {
			if (defined $graph1->[$GRAPH_ARRAY_INDEX]->{'_id_map'}{$id} &&
				 defined $graph2->[$GRAPH_ARRAY_INDEX]->{'_id_map'}{$id} ) {
				$common_nodes{$graph2->[$GRAPH_ARRAY_INDEX]->{'_id_map'}{$id}} =
				  $graph1->[$GRAPH_ARRAY_INDEX]->{'_id_map'}{$id};
			}
		}
	}
	# get all the edges in $graph2, if both nodes for a given edge are in
	# $graph1 then interactions can be copied, unless it's already in $graph1
	my @edges = $graph2->edges;
	for my $edgeref (@edges) {
		if (defined $common_nodes{$edgeref->[0]} &&
			 defined $common_nodes{$edgeref->[1]} ) {
			my $attref2 = $graph2->get_edge_attributes($edgeref->[0],$edgeref->[1]);	# nothing		
			if ($graph1->has_edge($common_nodes{$edgeref->[0]},
										 $common_nodes{$edgeref->[1]}) ) {
				# interactions for the given pair are in both graphs...
				my $attref1 = $graph1->get_edge_attributes($common_nodes{$edgeref->[0]},
															          $common_nodes{$edgeref->[1]});
				for my $interxid (keys %$attref2) {
				#...so check to see if their primary id's are the same or not
					unless (defined $attref1->{$interxid}) {
					$graph1->add_interaction(-nodes => [($common_nodes{$edgeref->[0]},
																	 $common_nodes{$edgeref->[1]})],
													 -interaction => $attref2->{$interxid});						
					}
				}
			} else {
				# a pair of nodes in $graph2 interact but don't interact in $graph1
				for my $interxid (keys %$attref2) {
					$graph1->add_interaction(-nodes => [($common_nodes{$edgeref->[0]},
																	 $common_nodes{$edgeref->[1]})],
													 -interaction => $attref2->{$interxid});
				}
			}	
		}
	}
}

=head2 subgraph

 Name      : subgraph
 Purpose   : Construct a subgraph of nodes from another network, including
             all Interactions.
 Usage     : my $subgraph = $graph->subgraph(@nodes).
 Returns   : A subgraph composed of nodes, edges, and Interactions from the 
             original graph.
 Arguments : A list of nodes.

=cut

sub subgraph {
	my ($self,@nodes) = @_;
	my $class = ref($self);
	my $subgraph = new $class;
	my @pairs = ();

	$subgraph->add_node(@nodes);

	# retrieve and add interacting pairs of nodes and Interactions
	@pairs = $self->_all_pairs(@nodes) if ($#nodes > 0);
	for my $pair (@pairs) {
		if ( $self->has_edge(@$pair) ) {
			my $ref = $self->get_edge_attributes(@$pair);
			for my $id (keys %$ref) {
				$subgraph->add_interaction(-nodes       => $pair,
													-interaction => $ref->{$id} );
			}
		}
	}
	# add isolated nodes that weren't found as interacting pairs, above
	for my $node (@nodes) {
		$subgraph->add_node($node) unless ($subgraph->has_node($node))
	}
	$subgraph;
}

=head2 get_ids_by_node

 Name     : get_ids_by_node
 Purpose  : Gets all ids for a node
 Arguments: A Bio::SeqI object
 Returns  : A hash: Keys are db ids, values are identifiers
 Usage    : my %ids = $gr->get_ids_by_node($seqobj);

=cut

sub get_ids_by_node {
	my %ids;
	my $self = shift;
	while (my $node = shift @_ ){
		$node->throw("I need a Bio::Network::Node object, not a [" .ref($node) ."]")
		  unless ( $node->isa('Bio::Network::Node') );
		## If Bio::Seq get dbxref ids as well.
		my @proteins = $node->proteins;
		for my $protein (@proteins) {
			my $ac = $protein->annotation();	
			for my $an ($ac->get_Annotations('dblink')) {
				$ids{$an->database()} = $an->primary_id();
			}
		}
	}
	return %ids;
}

=head2 add_interaction

 Name        : add_interaction
 Purpose     : Adds an Interaction to a graph.
 Usage       : $gr->add_interaction(-interaction => $interx
                                    -nodes => \@nodes );
 Arguments   : An Interaction object and a reference to an array holding 
               a pair of nodes
 Returns     :
 Description : This is the method to use to add an interaction to a graph.

=cut

sub add_interaction {
	my $self = shift;
   my ($interx,$nodesref) = $self->_rearrange([qw(INTERACTION NODES)],@_);
   my @nodes = @$nodesref;	
   #my $interxid = $interx->primary_id;

	$self->throw("The add_edge method needs 2 nodes, not ". scalar @nodes . 
					 " nodes") if ($#nodes != 1);

	for my $node (@nodes) {
		unless ( $node->isa("Bio::Network::Node") ) {
			if ( $node->isa("Bio::Seq") ) {
				# $self->warn("Node must be a Bio::Node object, not a [Bio::Seq]. " . 
				#				"Will make a Node object from it.");
				$node = Bio::Network::Node->new(-protein => [($node)]);
			} else {			
				$self->throw("Cannot make an interaction using a [". ref($node) . 
								 "].") 
			}
		}
   }

   $self->add_edge($nodes[0], $nodes[1]);
	$self->set_edge_attribute($nodes[0], $nodes[1], $interx->primary_id, $interx);
	$self->add_id_to_interaction($interx->primary_id, $interx);
	# Store the node names in the Interaction object
	$interx->{_nodes} = $nodesref;
}


=head2 add_edge

 Name        : add_edge
 Purpose     : 
 Usage       : $gr->add_edge(@nodes)
 Arguments   : A pair of nodes
 Returns     :
 Description : 

=cut

sub add_edge {
	my ($self,@nodes) = @_;

	$self->throw("The add_edge method needs 2 nodes, not ". scalar @nodes . 
					 " nodes")  if ($#nodes != 1);

	for my $node (@nodes) {
		$self->throw("Node must be a Bio::Network::Node object, not a [". ref($node) . "].") 
		  unless ($node->isa("Bio::Network::Node"));
	}
	$self->SUPER::add_edge(@nodes);
}

=head2 add_vertex

 Name        : add_vertex
 Purpose     : Adds a node to a graph.
 Usage       : $gr->add_vertex($n)
 Arguments   : A Bio::Network::Node object
 Returns     :
 Description : 

=cut

sub add_vertex {
	my ($self,$node) = @_;
	$self->throw("Node must be a Node object, not a ["
	 . ref($node) . "]") unless ($node->isa("Bio::Network::Node"));

	if ($self->has_node($node)) {
	#	$self->warn("Graph already has node with id " . $node->display_id 
	#					. ", will not add it.");
		return;
	} 
	$self->SUPER::add_vertex($node);
}

=head2 add_node

 Name        : add_node
 Purpose     : Alias to add_vertex
 Usage       : $gr->add_node($node)
 Arguments   : A Bio::Network::Node object
 Returns     : 
 Description : 

=cut

sub add_node {
	my ($self,$node) = @_;
   $self->add_vertex($node);
}

=head2 clustering_coefficient

 Name      : clustering_coefficient
 Purpose   : Determines the clustering coefficient of a node, a number 
             in range 0-1 indicating the extent to which the neighbors of
             a node are interconnnected.
 Arguments : A Node or a text identifier
 Returns   : The clustering coefficient. 0 is a valid result.
             If the CC is not calculable ( if the node has <2 neighbors),
                returns -1.
 Usage     : my $node = $gr->get_nodes_by_id('P12345');
             my $cc   = $gr->clustering_coefficient($node);

=cut

sub clustering_coefficient {
	my  ($self,$node)  = @_;

	$self->throw("[$node] is an incorrect parameter, not present in the graph")
		unless defined($node);
	$self->throw("[$node] is an incorrect parameter, not present in the graph")
		unless ($node->isa("Bio::Network::Node"));	

	my @n = $self->neighbors($node);
	my $n_count = scalar @n;
	my $c = 0;

	## calculate cc if we can
	if ($n_count >= 2){
		for (my $i = 0; $i <= $#n; $i++ ) {
			for (my $j = $i+1; $j <= $#n; $j++) {
				if ($self->has_edge($n[$i], $n[$j])){
					$c++;
				}
			}
		}
		$c = 2 * $c / ($n_count *($n_count - 1));
		return $c; # can be 0 if unconnected. 
	}else{
		return -1; # if value is not calculable
	}
}

=head2 remove_nodes

 Name      : remove_nodes
 Purpose   : Alias to Graph::delete_vertices
 Usage     : $graph2 = $graph1->remove_nodes($node);
 Arguments : A single Node object or a list of Node objects
 Returns   : A Graph with the given nodes deleted
 Notes     :

=cut

sub remove_nodes {
	my ($self,@nodes) = @_;
	my $g = $self->SUPER::delete_vertices(@nodes);
	$g;
}

=head2 get_random_edge

 Name      : get_random_edge
 Purpose   : Alias to Graph::random_edge
 Usage     : $edge = $graph1->get_random_edge;
 Arguments : 
 Returns   : An Edge object
 Notes     :

=cut

sub get_random_edge {
	my $self = shift;
	my $e = $self->random_edge;
	$e;
}

=head2 get_random_node

 Name      : get_random_node
 Purpose   : Alias to Graph::random_vertex
 Usage     : $node = $graph1->get_random_node;
 Arguments : 
 Returns   : A Node object
 Notes     :

=cut

sub get_random_node {
	my $self = shift;
	my $n = $self->random_vertex;
	$n;
}

=head2 is_forest

 Name      : is_forest
 Purpose   : Determine if a graph is a forest (2 or more trees)
 Usage     : if ($gr->is_forest){ ..... }
 Arguments : none
 Returns   : 1 or ""

=cut

sub is_forest {
	my $self = shift;
	return 1 if (!$self->is_connected && !$self->is_cyclic);
	return "";
}

=head2 is_tree

 Name      : is_tree
 Purpose   : Determine if the graph is a tree
 Usage     : if ($gr->is_tree){ ..... }
 Arguments : None
 Returns   : 1 or ""

=cut

sub is_tree {
	my $self = shift;
	return 1 if ($self->is_connected && !$self->is_cyclic);
	return "";
}

=head2 is_empty

 Name      : is_empty
 Purpose   : Determine if graph has no nodes
 Usage     : if ($gr->is_empty){ ..... }
 Arguments : None
 Returns   : 1 or ""

=cut

sub is_empty {
	my $self = shift;
	my @nodes = $self->vertices;
	return 1 if (scalar @nodes == 0);
	return "";
}

sub unconnected_nodes {
	my $self = shift;
	return $self->SUPER::isolated_vertices;
}

=head2 articulation_points

 Name      : articulation_points
 Purpose   : Find nodes in a graph that if removed will fragment
             the graph into sub-graphs.
 Usage     : my @nodes = $gr->articulation_points
                            or
             my $count = $gr->articulation_points
 Arguments : None
 Returns   : An array or a count of the array of nodes that will fragment 
             the graph if deleted. 
 Notes     : This method is currently broken due to bugs in Graph v. .69
             and later

=cut

sub articulation_points {
 	my $self = shift;
 	my @nodes = $self->SUPER::articulation_points; 
 	wantarray ? @nodes : scalar @nodes;
}

=head2 is_articulation_point

 Name      : is_articulation_point
 Purpose   : Determine if a given node is an articulation point or not. 
 Usage     : if ($gr->is_articulation_point($node)) {....}
 Arguments : A node (Sequence object)
 Returns   : 1 if node is an articulation point, 0 if it is not 
 Notes     : This method is currently broken due to bugs in Graph v. .69

=cut

sub is_articulation_point {
	my ($self,$node) = @_;

	$self->throw("$node is an incorrect parameter, not present in the graph")
		unless ( $node->isa("Bio::Network::Node") );
	
 	my @artic_points = $self->articulation_points();
 	grep /$node/,@artic_points ? return 1 : return 0;
}

=head2 nodes

 Name     : nodes
 Purpose  : Alias to Graph::vertices()
 Arguments: 
 Returns  : An integer
 Usage    : my $count = $graph->nodes;

=cut

sub nodes {
    my $self = shift;
	 if (wantarray) {
		 my @ns = $self->vertices;
		 return @ns;
	 } else {
		 return scalar $self->vertices;		 
	 }
}

=head2 has_node

 Name     : has_node
 Purpose  : Alias to Graph::has_vertex
 Arguments: 
 Returns  : True if the node exists
 Usage    : if ( $graph->has_node($node) ){ ... }

=cut

sub has_node {
    my ($self,$node) = @_;
	 return $self->has_vertex($node);		
}


=head2 interactions

 Name     : interactions
 Purpose  : Count the total number of Interactions in the network (an Edge can 
            have one or more Interactions) or retrieve all the Interactions in 
            the network as an array
 Usage    : my $count = $gr->interactions or
            my @interx = $gr->interactions
 Arguments:
 Returns  : A number or an array of Interactions
 Notes    :

=cut

sub interactions {
	my $self = shift;
	if (wantarray) {
		my @interx;
		for my $id (keys %{$self->[$GRAPH_ARRAY_INDEX]->{'_interx_id_map'}}) {
			push @interx, $self->[$GRAPH_ARRAY_INDEX]->{'_interx_id_map'}->{$id};
		}
		return @interx;
	} else {
		return scalar keys %{$self->[$GRAPH_ARRAY_INDEX]->{'_interx_id_map'}};
	}
}

=head2 nodes_by_id

  Name      : nodes_by_id
  Purpose   : Alias to get_nodes_by_id
  Notes     : Deprecated

=cut

sub nodes_by_id {
	my $self = shift;
	my @ids = @_;
	return $self->get_nodes_by_id(@ids);
}

=head2 edge_count

 Name     : edge_count
 Purpose  : Alias to edges()
 Notes    : Deprecated, use edges()

=cut

sub edge_count {
	my $self = shift;
	return scalar $self->edges;
}

=head2 neighbor_count

 Name      : neighbor_count
 Purpose   : Alias to Graph::neighbors
 Usage     : my $count = $gr->neighbor_count($node)
 Arguments : A node
 Returns   : An integer
 Notes     : Deprecated

=cut

sub neighbor_count{
	my ($self,$node) = @_;
	return scalar $self->SUPER::neighbors($node);
}

=head2 node_count

 Name     : node_count
 Purpose  : Alias to Graph::vertices()
 Notes    : Deprecated, use nodes()

=cut

sub node_count {
	my $self = shift;
	return scalar $self->vertices;
}

=head2 components

 Name      : components
 Purpose   : Alias to Graph::connected_components
 Usage     : my @components = $gr->components
 Arguments :
 Returns   : 
 Notes     : Deprecated

=cut

sub components {
	my $self = shift;
	return $self->connected_components;
}

=head2 unconnected_nodes

 Name      : unconnected_nodes
 Purpose   : Alias to Graph::isolated_vertices
 Arguments : None
 Returns   : An array of unconnected nodes
 Notes     : Deprecated

=cut

=head2 _all_pairs

 Name      : _all_pairs
 Purpose   : Find unique set of all pairwise combinations
 Usage     : my @pairs = $self->_all_pairs(@arr)
 Arguments : An array
 Returns   : An array of array references, each array in the 2nd dimension
             is a 2-element array

=cut

sub _all_pairs {
	my ($self,@arr) = @_;
	my @pairs = ();
	$self->throw("Must pass an array with at least 2 elements to _all_pairs()") 
	  unless ($#arr > 0);
	for (my $x = 0 ; $x < $#arr ; $x++) {
		for (my $y = $x ; $y < $#arr ; $y++ ) {
			push @pairs, [($arr[$x],$arr[($y + 1)])];
		}
	}
	@pairs;
}

=head2 _ids

 Name      : _ids
 Purpose   : 
 Usage     : 
 Arguments : 
 Returns   : 

=cut

sub _ids {
	my $self = shift;
	my @refs;
	while (my $id = shift) {
		push @refs, $self->[$GRAPH_ARRAY_INDEX]->{'_id_map'}->{$id};
	}
	return @refs;
}

1;

__END__

=head2 next_interaction

 Name      : next_interaction
 Purpose   : Retrieve Interactions using an edge
 Usage     : while (my $interx = $edge->next_interaction){ ... }
 Returns   : Interactions, one by one.
 Arguments :

=cut

sub next_interaction {


}

=head2 next_edge

 Name      : next_edge
 Purpose   : Retrieve all edges
 Usage     : while (my $edge = $graph->next_edge){ ... }
 Returns   : Edges, one by one.
 Arguments :

=cut

sub next_edge {


}

=head2 next_node

 Name      : next_node
 Purpose   : Retrieve all nodes
 Usage     : while (my $node = $graph->next_node){ ... }
 Returns   : Nodes, one by one.
 Arguments :

=cut

sub next_node {

}
