# This is -*-Perl-*- code#
# Bioperl Test Harness Script for Modules

use strict;

BEGIN {
	use Bio::Root::Test;
	test_begin(-tests => 171,
			   -requires_module => 'Graph',
			   -requires_module => 'XML::Twig' );

	use_ok('Bio::Network::ProteinNet');
	use_ok('Bio::Network::IO');
}

my $verbose = test_debug();

#
# read old DIP format
#
my $io = Bio::Network::IO->new(
  -format => 'dip_tab',
  -file   => test_input_file("tab1part.tab"),
  -threshold => 0.6);
ok(defined $io);
ok my $g1 = $io->next_network();
ok my $node = $g1->get_nodes_by_id('PIR:A64696');
my @proteins = $node->proteins;
ok $proteins[0]->accession_number eq 'PIR:A64696';
ok $node = $g1->nodes_by_id('PIR:A64696');
@proteins = $node->proteins;
ok $proteins[0]->accession_number eq 'PIR:A64696';
my %ids = $g1->get_ids_by_node($node);
my $x = 0;
my @ids = qw(A64696 2314583 3053N);
for my $k (keys %ids) {
	ok ( $ids{$k} eq $ids[$x++] );
}
#
# test deleting nodes
#
ok $g1->edges == 79;
ok $g1->vertices == 76;
# now remove 2 nodes: this removes 4 edges
my $g2 = $g1->delete_vertices($g1->get_nodes_by_id('DIP:3082N'), 
									   $g1->get_nodes_by_id('DIP:3083N') );
ok $g2->edges == 75;
ok $g2->vertices == 74;
#
# test for identifiers and Annotations
#
ok $node = $g1->get_nodes_by_id('PIR:A64696');
@proteins = $node->proteins;
ok $proteins[0]->accession_number eq 'PIR:A64696';
my $ac = $proteins[0]->annotation;
@ids = $ac->get_Annotations('dblink');
ok $ids[0]->primary_id eq "A64696";
ok $ids[1]->primary_id eq "3053N";
ok $ids[2]->primary_id eq "2314583";
#
# test some basic graph properties from Graph
#
ok sprintf("%.3f",$g2->density), "0.028";
ok $g2->is_connected eq "";
ok $g2->is_forest eq "";
ok $g2->is_tree eq "";
ok $g2->is_empty eq "";
ok $g2->is_cyclic == 1;
ok $g2->expect_undirected;
#
# get connected subgraphs
#
my @components = $g2->connected_components();
ok scalar @components == 7;
#
# before deleting 3048N, 3047N has 2 neighbours
#
my @n1 = $g2->neighbors($g2->get_nodes_by_id('DIP:3047N'));
ok scalar @n1 == 2;

ok $g2->delete_vertices($g2->get_nodes_by_id('DIP:3048N'));
#
# after deleting there is only 1 interactor
#
@n1 = $g2->neighbors($g2->get_nodes_by_id('DIP:3047N'));
ok scalar @n1 == 1;
my $ncount = $g2->neighbor_count($g2->get_nodes_by_id('DIP:3047N'));
ok $ncount == 1;
#
# check that no undefs are left after node removal 
#
my @edges = $g2->edges;
for my $edgeref (@edges) {
	my %interactions = $g2->get_interactions(@$edgeref);
	for my $interaction (values %interactions) {
		ok $interaction->primary_id;
	}
}
#
# get an Interaction by its id
#
ok my $interx = $g2->get_interaction_by_id('DIP:4368E');
ok $interx->primary_id eq 'DIP:4368E';
#
# count all edges
# 
my $count = 0;
ok $g2->edges == 74;

my @n = $g2->neighbors($g2->get_nodes_by_id('DIP:3075N'));
ok scalar @n == 12;

ok $g2->remove_nodes($g2->get_nodes_by_id('DIP:3075N'));
ok scalar $g2->edges == 62;
#
# test connected_components
#
@components = $g2->connected_components();
ok scalar @components == 17;
#
# test isolated_vertices
#
my @ucnodes = $g2->isolated_vertices;
ok scalar @ucnodes == 10;
#
# test clustering_coefficent
#
ok  sprintf("%.3f", $g2->clustering_coefficient($g2->get_nodes_by_id('PIR:B64525'))) == 0.022;
#
# test get_nodes_by_id() method
#
ok defined $g2->get_nodes_by_id('PIR:B64525');
is $g2->get_nodes_by_id('B64'), undef;
#
# test subgraph
#
$io = Bio::Network::IO->new
(-format => 'psi10',
 -file   => test_input_file("bovin_small_intact.xml"));
my $g = $io->next_network();
ok $g->edges == 15;
ok $g->nodes == 23;

@ids = qw(EBI-354674 EBI-444335 EBI-349968 EBI-354657
			 EBI-302230 EBI-640775 EBI-640793 EBI-79764);
my @nodes = $g->get_nodes_by_id(@ids);
ok scalar @nodes == 8;
my $sg = $g->subgraph(@nodes);
ok $sg->edges == 5;
ok $sg->nodes == 8;

@nodes = $g->get_nodes_by_id($ids[0]);
$sg = $g->subgraph(@nodes);
ok $sg->edges == 0;
ok $sg->nodes == 1;
#
# test internal method _all_pairs()
#
my @pairs = $g->_all_pairs(@ids);
ok $#pairs == 27;
@pairs = $g->_all_pairs("A","B");
ok scalar @pairs == 1;
#
# test the add_interactions_from() method
#
$io = Bio::Network::IO->new
    (-format => 'dip_tab',
     -file   => test_input_file("tab4part.tab"));
$g1 = $io->next_network();

my $io2 = Bio::Network::IO->new
    (-format => 'dip_tab',
     -file   => test_input_file("tab3part.tab"));
$g2 = $io2->next_network();

ok $g1->edges == 5;
ok $g1->nodes == 7;
ok $g2->edges == 3;
ok $g2->nodes == 5;

ok my $node1 = $g1->get_nodes_by_id("UniProt:Q09472");
ok my $node2 =	$g1->get_nodes_by_id("UniProt:P04637");
my %interx = $g1->get_interactions($node1,$node2);
ok scalar keys %interx == 1;

ok $node1 = $g1->get_nodes_by_id("UniProt:P10243");
ok $node2 =	$g1->get_nodes_by_id("GenBank:2134877");
%interx = $g1->get_interactions($node1,$node2);
ok scalar keys %interx == 1;

is my $ix = $g1->get_interaction_by_id("DIP:16E"), undef;
is $ix = $g1->get_interaction_by_id("DIP:19E"), undef;

$g1->add_interactions_from($g2);
#
# $g1 should have 2 more Interactions with new interaction ids and
# the same number of nodes and edges, $g2 should be unaffected
#
ok $g1->edges == 5;
ok $g1->nodes == 7;
ok $g2->edges == 3;
ok $g2->nodes == 5;

ok $node1 = $g1->get_nodes_by_id("UniProt:Q09472");
ok $node2 =	$g1->get_nodes_by_id("UniProt:P04637");
%interx = $g1->get_interactions($node1,$node2);
ok scalar keys %interx == 2;

ok $node1 = $g1->get_nodes_by_id("UniProt:P10243");
ok $node2 =	$g1->get_nodes_by_id("GenBank:2134877");
%interx = $g1->get_interactions($node1,$node2);
ok scalar keys %interx == 2;

ok $ix = $g1->get_interaction_by_id("DIP:16E");
ok $ix->weight == 3;
ok $ix = $g1->get_interaction_by_id("DIP:19E");
ok $ix->weight == 12;
#
# test that removing a node removes its edges correctly
#
ok $io = Bio::Network::IO->new
  (-format => 'psi10',
	-file   => test_input_file("sv40_small.xml"));
ok $g1 = $io->next_network();
ok $g1->edge_count == 3;
ok $g1->node_count == 5;
ok $g1->is_connected == 0;
@components = $g1->connected_components;
ok scalar @components == 2;

my $n = $g1->get_nodes_by_id("EBI-617321");
my @ns = $g1->edges_at($n);
ok scalar @ns == 2;
$g1->remove_nodes($n);
ok $g1->edge_count == 1;
ok $g1->node_count == 4;
@components = $g1->connected_components;
ok scalar @components == 3;
@ns = $g1->isolated_vertices;
ok scalar @ns == 2;
@ns = $g1->unconnected_nodes;
ok scalar @ns == 2;
@ns = $g1->self_loop_vertices;
ok @ns == 0;
#
# test components
#
@components = $g1->components;
ok scalar @components == 3;
#
# random
#
$n = $g1->get_random_node;
isa_ok( $n, 'Bio::Network::Node');
my $e = $g1->get_random_edge;
isa_ok( $e->[0], 'Bio::Network::Node');

__END__

Need to test:

_get_ids
