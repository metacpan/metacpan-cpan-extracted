# This is -*-Perl-*- code#
# Bioperl Test Harness Script for Modules

use strict;

BEGIN {
	use Bio::Root::Test;
	test_begin(-tests => 32,
			   -requires_module => 'Graph');

	use_ok('Bio::Network::ProteinNet');
	use_ok('Bio::Network::Node');
	use_ok('Bio::Seq');
}

my $verbose = test_debug();

my $seq1 = Bio::Seq->new(-seq => "aaaaaaa",-display_id => 1);
my $seq2 = Bio::Seq->new(-seq => "ttttttt",-display_id => 2);
my $seq3 = Bio::Seq->new(-seq => "ggggggg",-display_id => 3);

#
# 1 protein
#
my $node = Bio::Network::Node->new(-protein => $seq1);
ok $node->is_complex == 0;
my $count = $node->proteins;
ok $count == 1;

my @proteins = $node->proteins;
ok $proteins[0]->seq eq "aaaaaaa";
ok $proteins[0]->display_id == 1;
is $node->subunit_number($proteins[0]), undef;
$node->subunit_number($proteins[0],52);
ok $node->subunit_number($proteins[0]) == 52;

#
# 1 or more proteins, but no subunit composition
#
$node = Bio::Network::Node->new(-protein => [($seq1,$seq2,$seq3)]);
ok $node->is_complex == 1;
@proteins = $node->proteins;
my $x = 0;
my @seqs = qw(aaaaaaa ggggggg ttttttt);
for my $protein (@proteins) {
	ok $protein->seq eq $seqs[$x++];
	is $node->subunit_number($protein), undef;
}
$count = $node->proteins;
ok $count == 3;

$node = Bio::Network::Node->new(-protein => [($seq1)]);
ok $node->is_complex == 0;

#
# 1 or more proteins, specifying subunit composition
#
$node = Bio::Network::Node->new(-protein => [ [($seq1, 2) ],
														  [ ($seq2, 3) ],
														  [ ($seq3, 1)] ]);
ok $node->is_complex == 1;
@proteins = $node->proteins;
$x = 0;
@seqs = qw(aaaaaaa ggggggg ttttttt);
my @nums = (2,1,3);
for my $protein (@proteins) {
	ok $protein->seq eq $seqs[$x];
	ok $node->subunit_number($protein) == $nums[$x++];
}
$count = $node->proteins;
ok $count == 3;

$node = Bio::Network::Node->new(-protein => [ [($seq3, 1)] ]);
ok $node->is_complex == 0;
ok $node->proteins == 1;

$node = Bio::Network::Node->new(-protein => [ [($seq3, 1)],
														  [($seq2, 1)] ] );
ok $node->is_complex == 1;
ok $node->proteins == 2;
$node->is_complex(0);
ok $node->is_complex == 0;

$node->subunit_number($seq2,2);
ok $node->subunit_number($seq2) == 2;

__END__

