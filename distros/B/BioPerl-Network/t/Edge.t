# This is -*-Perl-*- code#
# Bioperl Test Harness Script for Modules

use strict;

BEGIN {
	use Bio::Root::Test;
	test_begin(-tests => 9,
			   -requires_module => 'Graph');

	use_ok('Bio::Network::Edge');
	use_ok('Bio::Network::Node');
	use_ok('Bio::Seq');
}

my $verbose = test_debug();

my $seq1 = Bio::Seq->new(-seq => "aaaaaaa");
my $seq2 = Bio::Seq->new(-seq => "ttttttt");
my $seq3 = Bio::Seq->new(-seq => "ccccccc");

my $node1 = Bio::Network::Node->new(-protein => $seq1);
my $node2 = Bio::Network::Node->new(-protein => [($seq2,$seq3)]);

my $edge = Bio::Network::Edge->new(-nodes => [($node1,$node2)]);
isa_ok $edge, 'Bio::Network::Edge';
my $count = $edge->nodes;
ok $count == 2;

my @nodes = $edge->nodes;
ok $#nodes == 1;

# It's possible to construct an Edge with 1 Node,
# interacting with itself
$edge = Bio::Network::Edge->new(-nodes => [($node1)]);
isa_ok $edge, 'Bio::Network::Edge';
$count = $edge->nodes;
ok $count == 1;

@nodes = $edge->nodes;
ok scalar @nodes == 1;

__END__

