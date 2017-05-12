# This is -*-Perl-*- code#
# Bioperl Test Harness Script for Modules#

use strict;

BEGIN {
	use Bio::Root::Test;
	test_begin(-tests => 22,
			   -requires_module => 'Graph',
			   -requires_module => 'XML::Twig');

	use_ok('Bio::Network::IO');
	use_ok('Bio::Network::Node');
}

my $verbose = test_debug();

#
# PSI XML from DIP
#
ok my $io = Bio::Network::IO->new
  (-format => 'psi10',
	-file   => test_input_file("psi_xml.dat"));
ok my $g1 = $io->next_network();
is $g1->edge_count, 3;
is $g1->node_count, 4;
is $g1->is_connected, 1;
my $n = $g1->get_nodes_by_id('O24853');
my @proteins = $n->proteins;
is $proteins[0]->species->node_name, "Helicobacter pylori 26695";
is $proteins[0]->primary_seq->desc, "hypothetical HP0001";
my @rts = $g1->articulation_points;
is scalar @rts, 1; # correct, by inspection in Cytoscape
@proteins = $rts[0]->proteins;
my $seq = $proteins[0];
is $seq->desc, "hypothetical HP0001"; # correct, by inspection in Cytoscape

#
# PSI XML from IntAct
#
ok $io = Bio::Network::IO->new
  (-format => 'psi10',
	-file   => test_input_file("sv40_small.xml"));
ok $g1 = $io->next_network();
is $g1->edge_count, 3;
is $g1->node_count, 5;
is $g1->is_connected, "";

$n = $g1->get_nodes_by_id("P03070");
@proteins = $n->proteins;
is $proteins[0]->species->scientific_name, "Simian virus 40";
is $proteins[0]->primary_seq->desc, "Large T antigen";

my @components = $g1->connected_components;
is scalar @components, 2;

# there was an intermittent bug in articulation_points() here
# but not in the invocation above, this appears to be fixed
# in Graph v. .86
@rts = $g1->articulation_points;
is scalar @rts, 1;
@proteins = $rts[0]->proteins;
$seq = $proteins[0];
is $seq->desc, "Erythropoietin receptor precursor";

#
# GO terms
#
$n = $g1->get_nodes_by_id("EBI-474016");
@proteins = $n->proteins;

#
# PSI XML from HPRD
#
# The individual files from HPRD are not standard PSI, problems parsing them
ok $io = Bio::Network::IO->new
  (-format => 'psi10',
	-file   => test_input_file("00001.xml"));
# ok $g1 = $io->next_network(); 

__END__

