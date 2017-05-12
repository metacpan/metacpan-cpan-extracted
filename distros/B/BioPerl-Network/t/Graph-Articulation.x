# This is -*-Perl-*- code#
# Bioperl Test Harness Script for Modules

use strict;

BEGIN {
	use Bio::Root::Test;
	test_begin(-tests => 53,
			   -requires_module => 'Graph');

	use_ok('Bio::Network::IO');
	use_ok('Bio::Network::Node');
}

my $verbose = test_debug();

# tests for Graph's problematic articulation_points()
# As of 2/2008 this test suite is still not reliably passing -
# I run it 5 times and I'll get an error 1 out of 5:
# Can't locate object method "proteins" via package "Bio::Network::Node...

#
# read old DIP format
#
my $io = Bio::Network::IO->new(
  -format => 'dip_tab',
  -file   => test_input_file("tab1part.tab"),
  -threshold => 0.6);
ok(defined $io);
ok my $g1 = $io->next_network();

my @nodes = $g1->articulation_points();
ok $#nodes == 12;
my $nodes = $g1->articulation_points();
ok $nodes == 13;
#
# test articulation_points, but first check that each Node
# in network exists as an object
#
$io = Bio::Network::IO->new
(-format => 'psi10',
 -file   => test_input_file("bovin_small_intact.xml"));
my $g = $io->next_network();

@nodes = $g->nodes;
ok scalar @nodes == 23;

foreach my $node (@nodes) {
	my @seqs = $node->proteins;
	ok $seqs[0]->display_id;
}

# ($ap, $bc, $br) = $g->biconnectivity;

@nodes = $g->articulation_points;
ok scalar @nodes == 4; # OK, inspected in Cytoscape

my @eids = qw(Q29462 P16106 Q27954 P53619);
foreach my $node (@nodes) {
 	my @seqs = $node->proteins;
 	ok my $id = $seqs[0]->display_id;
 	ok grep /$id/, @eids;
}
#
# additional articulation_points tests
# arath_small-02.xml is PSI MI version 1.0
#
ok $io = Bio::Network::IO->new
  (-format => 'psi10',
	-file   => test_input_file("arath_small-02.xml"));
ok $g1 = $io->next_network();
ok $g1->nodes == 73;
ok $g1->interactions == 516;
@nodes = $g1->articulation_points;
ok scalar @nodes == 8;

for my $node (@nodes) {
	for my $prot ( $node->proteins) {
		ok $prot->display_id;
	}
}

__END__
