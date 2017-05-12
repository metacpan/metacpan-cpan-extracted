# This is -*-Perl-*- code#
# Bioperl Test Harness Script for Modules

use strict;

BEGIN {
	use Bio::Root::Test;
	test_begin(-tests => 17,
			   -requires_module => 'Graph');

	use_ok('Bio::Network::IO');
	use_ok('Bio::Seq');
}

my $verbose = test_debug();

#
# read new DIP format
#
my $io = Bio::Network::IO->new(
    -format => 'dip_tab',
    -file   => test_input_file("tab4part.tab"));
my $g1 = $io->next_network();
ok $g1->edges == 5;
ok $g1->vertices == 7;
#
# read old DIP format
#
$io = Bio::Network::IO->new(
  -format => 'dip_tab',
  -file   => test_input_file("tab1part.tab"),
  -threshold => 0.6);
ok(defined $io);
ok $g1 = $io->next_network();
ok my $node = $g1->get_nodes_by_id('PIR:A64696');
my @proteins = $node->proteins;
ok $proteins[0]->accession_number, 'PIR:A64696';
my %ids = $g1->get_ids_by_node($node);
my $x = 0;
my @ids = qw(A64696 2314583 3053N);
for my $k (keys %ids) {
	ok $ids{$k} eq $ids[$x++];
}
#
# test write to filehandle...
#
my $out_file = test_output_file();
my $out =  Bio::Network::IO->new(
  -format => 'dip_tab',
  -file   => ">".$out_file);
ok(defined $out);
ok $out->write_network($g1);
#
# can we round trip, is the output the same as original format?
#
my $io2 = Bio::Network::IO->new(
  -format   => 'dip_tab',
  -file     => $out_file);
ok defined $io2;
ok	my $g2 = $io2->next_network();
ok $node = $g2->get_nodes_by_id('PIR:A64696');
@proteins = $node->proteins;
ok $proteins[0]->accession_number eq 'PIR:A64696';

__END__

