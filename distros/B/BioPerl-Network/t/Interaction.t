# This is -*-Perl-*- code#
# Bioperl Test Harness Script for Modules

use strict;

BEGIN {
	use Bio::Root::Test;
	test_begin(-tests => 23,
			   -requires_module => 'Graph');

	use_ok('Bio::Network::ProteinNet');
	use_ok('Bio::Network::Interaction');
	use_ok('Bio::Network::Node');
	use_ok('Bio::Seq');
	use_ok('Bio::Annotation::Comment');
	use_ok('Bio::Annotation::Collection');
	use_ok('Bio::Annotation::OntologyTerm');
}

my $verbose = test_debug();

my $g = Bio::Network::ProteinNet->new();

my $seq1 = Bio::Seq->new(-seq => "aaaaaaa");
my $seq2 = Bio::Seq->new(-seq => "ttttttt");
my $seq3 = Bio::Seq->new(-seq => "ccccccc");

my $node1 = Bio::Network::Node->new(-protein => $seq1);
my $node2 = Bio::Network::Node->new(-protein => [($seq2,$seq3)]);

my $interx = Bio::Network::Interaction->new(-weight => 2,
														  -id => "A");
$g->add_interaction(-nodes => [($node1,$node2)],
						  -interaction => $interx);

$interx = Bio::Network::Interaction->new(-weight => 3,
														-id => "B");
$g->add_interaction(-nodes => [($node1,$node2)],
						  -interaction => $interx);

$interx = $g->get_interaction_by_id("A");

ok $interx->primary_id eq "A";
ok $interx->object_id eq "A";
ok $interx->weight == 2;
my @nodes = $interx->nodes;
ok $#nodes == 1;
my @proteins = $nodes[0]->proteins;
ok $proteins[0]->seq eq "aaaaaaa";
@proteins = $nodes[1]->proteins;
ok $proteins[0]->seq eq "ttttttt";

my $nodes = $interx->nodes;
ok $nodes == 2;
#
# set values
#
$interx->primary_id("B");
ok $interx->primary_id eq "B";
$interx->weight(7);
ok $interx->weight == 7;
#
# check that Bio::Seq objects are automatically converted to Nodes
#
$interx = Bio::Network::Interaction->new(-weight => 2,
													  -id => "C");
$g->add_interaction(-nodes => [($seq1,$seq2)],
						  -interaction => $interx);

$interx = $g->get_interaction_by_id("C");
ok $interx->primary_id eq "C";
#
# add and remove Annotations
#
my $comment = Bio::Annotation::Comment->new;
$comment->text("Reliable");
my $coll = Bio::Annotation::Collection->new();
$coll->add_Annotation('comment',$comment);
ok $interx->annotation($coll);
my @anns = $coll->get_Annotations('comment');
ok scalar @anns == 1;
ok $anns[0]->as_text, "Comment: Reliable";
my @keys = $coll->get_all_annotation_keys;
ok $keys[0] eq 'comment';
$coll->remove_Annotations('comment');
@anns = $coll->get_Annotations('comment');
ok scalar @anns == 0;

my $term = Bio::Annotation::OntologyTerm->new
(-term => "",
 -name => "N-acetylgalactosaminyltransferase",
 -label => "test",
 -identifier => "000045",
 -definition => "Catalysis of galactossaminylation",
 -ontology => "GO",
 -tagname => "cellular component");
$coll->add_Annotation($term);
ok $interx->annotation($coll);


__END__
