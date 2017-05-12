#!/usr/bin/perl

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: nexus_add-otu-clone.t,v 1.6 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.6 $


# Written by Mikhail Bezruchko
# Refernce: http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date: 30th October 2006

use strict;
use warnings;

eval { require Clone::PP };
if ( $@ ) {
	require Test::More;
	Test::More->import( 'skip_all' => 'Clone::PP not installed' );
	exit 0;
}
else {
	require Test::More;
	Test::More->import( 'no_plan' );
}

eval "use Test::Deep";
my $skip = "false";
$skip = "true" if $@;

print "\n";
print "I will skip the tests that use Test::Deep; the module is not installed" if $skip eq "true";

use Bio::NEXUS;
use Data::Dumper;

# This set of tests checks the Bio::NEXUS::add_otu_clone()
# method. While most modules that implement nexus blocks
# contain the add_otu_clone() method, it should be called
# on a Bio::NEXUS object. Calling the method on a block
# object will add an OTU clone only to that object, leaving
# the parent nexus object (if any) in an incosistent state.

print "\n";
print "\n";

print "--- nex_obj_01 ---\n";
my $nex_obj_01 = new Bio::NEXUS('t/data/compliant/01_basic.nex');
isa_ok($nex_obj_01, 'Bio::NEXUS');

eval {
    $nex_obj_01->add_otu_clone('A', 'A');
};
isnt ($@, '', "original OTU's name and clone OTU's names cannot be the same");

eval {
    $nex_obj_01->add_otu_clone('A', 'B');
};
isnt ($@, '', "desired clone OTU name cannot match an existing OTU");

$nex_obj_01->add_otu_clone('A', 'A_clone');
# 'taxa' block
my $taxa_block = $nex_obj_01->get_block('taxa');
is ($taxa_block->get_ntax(), '5', 'ntax = 5');

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	cmp_deeply ($taxa_block->get_taxlabels(), set('A', 'A_clone', 'B', 'C', 'D'), "taxlabel structure is updated");
}

# 'characters' block
my $char_block = $nex_obj_01->get_block('characters');
#print Dumper $char_block;
my $orig_otu = $char_block->get_otuset()->get_otu('A');
my $clone_otu = $char_block->get_otuset()->get_otu('A_clone');
if (defined $orig_otu && defined $clone_otu) {
    if ($orig_otu->get_name() eq 'A' && $clone_otu->get_name() eq 'A_clone') {
	# do some testing
	is ($orig_otu->get_seq_string(), $clone_otu->get_seq_string(), "seq-s match");
	
	my $clone_seq = $clone_otu->get_seq();
	$clone_seq->[0] = 'Q';
	$clone_otu->set_seq($clone_seq);
	isnt ($char_block->get_otuset()->get_otu('A')->get_seq_string(),
	    $char_block->get_otuset()->get_otu('A_clone')->get_seq_string(),
	      "seq-s are different");
    }
}

# 'trees' block
my $trees_block = $nex_obj_01->get_block('trees');
#print Dumper $trees_block;
my $tree = $trees_block->get_trees()->[0];

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	cmp_deeply($tree->get_node_names(), set('A', 'B', 'C', 'D', 'A_clone'), "OTUs in the tree are as expected");
}

my $orig_node = $tree->find('A');
my $clone_node = $tree->find('A_clone');
my $orig_parent = $orig_node->get_parent();
my $clone_parent = $clone_node->get_parent();
is ($orig_parent->get_name(), $clone_parent->get_name(), 'parents match');
is ($orig_node->get_length(), 0, '$orig_node.length = 0');
is ($clone_node->get_length(), 0, '$clone_node.length = 0');

print "\n";
print "--- nex_obj_02 ---\n";
my $nex_obj_02 = new Bio::NEXUS('t/data/compliant/02_character-polymorphic-uncertain.nex');
$nex_obj_02->add_otu_clone('taxon_1', 'taxon_1_clone');
# a more 'involved' characters block (ambiguity/polymorphic data)
$char_block = $nex_obj_02->get_block('characters');
my $orig_seq = $char_block->get_otuset()->get_otu('taxon_1')->get_seq();
my $clone_seq = $char_block->get_otuset()->get_otu('taxon_1_clone')->get_seq();
#print Dumper $orig_seq;
#print Dumper $clone_seq;

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	is_deeply($orig_seq, $clone_seq, "seq-s match");
}

print "\n";
print "--- nex_obj_03 ---\n";
my $nex_obj_03 = new Bio::NEXUS('t/data/compliant/history-block_probab-distrib.nex');
$nex_obj_03->add_otu_clone('A', 'A_clone');
# 'history' block
my $hist_block = $nex_obj_03->get_block('history');

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	cmp_deeply($hist_block->get_taxlabels(), supersetof('A_clone', 'A'), "the taxlabels now contains the new OTU");
}

$clone_otu = $hist_block->get_otuset()->get_otu('A_clone');
isa_ok($clone_otu, 'Bio::NEXUS::TaxUnit');
is($clone_otu->get_seq()->[0]->{'type'}, 'polymorphism',
   "1st character is polymorphic, as expected");
# 'history' block also contains phylo tree(s)
my $hist_tree = $hist_block->get_trees()->[0];

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	cmp_deeply($tree->get_node_names(), set('A', 'B', 'C', 'D', 'A_clone'), "OTUs in the tree are as expected");
}

# cloning the clone
$nex_obj_03->add_otu_clone('A_clone', 'A_clone_again');
# 'taxa' block
$taxa_block = $nex_obj_03->get_block('taxa');
is ($taxa_block->get_ntax(), "6", 'ntax = 6');
# 'char', 'tree' blocks
$char_block = $nex_obj_03->get_block('characters');

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	cmp_deeply($char_block->get_taxlabels(), set('A', 'A_clone', 'A_clone_again', 'B', 'C', 'D'), "taxlabels match");
}

# 'treesblock' block
$trees_block = $nex_obj_03->get_block('trees');
$tree = $trees_block->get_trees()->[0];

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	cmp_deeply($tree->get_node_names(), set('A', 'A_clone', 'A_clone_again', 'B', 'C', 'D'), "otu-node names match the expected");
}

$orig_node = $tree->find('A');
my $clone_node_1 = $tree->find('A_clone');
my $clone_node_2 = $tree->find('A_clone_again');

my $parent_of_clone_1 = $clone_node_1->get_parent();
my $parent_of_clone_2 = $clone_node_2->get_parent();

if (defined $parent_of_clone_1 && defined $parent_of_clone_2) {
    is($parent_of_clone_1->get_name(), $parent_of_clone_2->get_name(),
       "[a_clone] and [a_clone_again] have the same parent");
    #print "par_1: ", $parent_of_clone_1->get_name(), "\n";
}
else {
    # fail the test !!!
    print "Warning: the node(s) object was(were) not created properly";
}

my $parent_of_original = $orig_node->get_parent();
#print "orig_node name ", $orig_node->get_name(), "\n";
#print "orig_node parent name ", $parent_of_original->get_name(), "\n";
my $parent_of_clone_1_parent = $parent_of_clone_1->get_parent();
#print "parent_of_clone_1 name ", $parent_of_clone_1->get_name(), "\n";
#print "parent_of_clone_1 parent name ", $parent_of_clone_1_parent->get_name(), "\n";

if (defined $parent_of_original && defined $parent_of_clone_1_parent) {
    is ($parent_of_original->get_name(), $parent_of_clone_1_parent->get_name(),
	"the original otu [A] and the parent of new clones have the same parent");
}
else {
    # fail the test !!!
    print "Warning: the node(s) object was(were) not created properly";
}

#$nex_obj_03->write("-");

print "\n";
print "--- nex_obj_04 ---\n";

# 'SETS' block
my $nex_obj_04 = new Bio::NEXUS("t/data/compliant/KOG0003.nex");

my $sets_block = $nex_obj_04->get_block('sets');
# we'll clone the 'homo_sapiens' otu, and then
# will check if the clone is in the sets that
# contain the original otu.

# Let's create an additional set, so that 'homo_sapiens'
# is in multiple sets.
my $invertebrates = $sets_block->get_taxset('invertebrates');
my $vertebrates = $sets_block->get_taxset('vertebrates');

my @temp_animals = (@{$invertebrates}, @{$vertebrates});
my $temp_sets = { 'animals' => \@temp_animals };
$sets_block->add_taxsets($temp_sets);

#print Dumper $sets_block->get_taxsets();

my $animals = $sets_block->get_taxset('animals');

$nex_obj_04->add_otu_clone("Homo_sapiens_4507761", "Homo_sapiens_4507761_clone");

#print Dumper $invertebrates;
#print Dumper $vertebrates;
#print Dumper $animals;
#print Dumper $sets_block->get_taxset('fungi');

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	cmp_deeply($invertebrates, set("Anopheles_gambiae_agCT55686", "Caenorhabditis_elegans_17554758", "Drosophila_melanogaster_7295730"), "invertebrates set is correct");
	cmp_deeply($vertebrates, set("Homo_sapiens_4507761", "Homo_sapiens_4507761_clone"), "vertebrates set is correct");
	cmp_deeply($animals, supersetof("Homo_sapiens_4507761_clone"), "animals set contains the clone");
}

print "\n";
print "--- nex_obj_05 ---\n";
# 'SPAN' block

my $nex_file = 
"#NEXUS

[This file is based on 'PF00237_20.nex' downloaded from 'www.molevol.org/nexplorer' on 3/20/2007]
[This file was checked by nexfix.pl, v1.11 on Wed Jan 31 23:13:43 2007]

BEGIN TAXA;
	TITLE PF00237_20;
	DIMENSIONS ntax=20;
	TAXLABELS  Arabidopsis_thaliana_AAF99734.1 Arabidopsis_thaliana_AAC18792.1 Drosophila_melanogaster_AAF46195.1 Homo_sapiens_BAB79462.1 Caenorhabditis_elegans_AAL32251.1 Saccharomyces_cerevisiae_CAA82023.1 Saccharomyces_cerevisiae_CAA89472.1 Neurospora_crassa_CAC18189.1 Schizosaccharomyces_pombe_CAB10153.1 Schizosaccharomyces_pombe_CAA18285.1 Encephalitozoon_cuniculi_CAD25673.1 Guillardia_theta_AAK39769.1 Arabidopsis_thaliana_CAB79638.1 Arabidopsis_thaliana_AAG51551.1 Oryza_sativa_BAB39116.1 Chlamydomonas_reinhardtii_AAO53243.1 Pisum_sativum_AAA33656.1 Drosophila_melanogaster_AAF48662.2 Plasmodium_falciparum_AAN37255.1 Schizosaccharomyces_pombe_CAA20776.1;
END;

[ characters block that contains protein data has been removed ]

BEGIN TREES;
[Note: This tree contains information on the topology, 
          branch lengths (if present), and the probability
          of the partition indicated by the branch.]
	TREE con_50_majrule = (Arabidopsis_thaliana_AAF99734.1:0.071794,Arabidopsis_thaliana_AAC18792.1:0.009610,(((Drosophila_melanogaster_AAF46195.1:0.170704,Caenorhabditis_elegans_AAL32251.1:0.229112)inode4:0.064934[0.68],Homo_sapiens_BAB79462.1:0.139297,Encephalitozoon_cuniculi_CAD25673.1:0.484353,(Guillardia_theta_AAK39769.1:0.445892,Plasmodium_falciparum_AAN37255.1:1.993525)inode5:0.329802[0.55],(((((Arabidopsis_thaliana_CAB79638.1:0.346973,Arabidopsis_thaliana_AAG51551.1:0.034434)inode10:0.245809[1.00],Oryza_sativa_BAB39116.1:0.444862)inode9:0.483883[1.00],(Chlamydomonas_reinhardtii_AAO53243.1:0.426211,Pisum_sativum_AAA33656.1:0.466457)inode11:0.438813[0.99])inode8:0.231879[0.54],Drosophila_melanogaster_AAF48662.2:1.138563)inode7:0.497603[0.94],Schizosaccharomyces_pombe_CAA20776.1:0.937445)inode6:0.969732[1.00])inode3:0.090416[0.50],(((Saccharomyces_cerevisiae_CAA82023.1:0.005945,Saccharomyces_cerevisiae_CAA89472.1:0.013871)inode14:0.223094[1.00],Neurospora_crassa_CAC18189.1:0.185303)inode13:0.093729[0.75],(Schizosaccharomyces_pombe_CAB10153.1:0.008704,Schizosaccharomyces_pombe_CAA18285.1:0.021410)inode15:0.272533[1.00])inode12:0.150677[0.61])inode2:0.215442[0.98])root;
END;

BEGIN ASSUMPTIONS;
	TITLE proteinweight;
	LINK taxa=PF00237_20;
	LINK characters=protein;
	WTSET CORE_column_scores (VECTOR TOKENS) = 
	0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 - 0 0 0 0 0 0 0 1 1 1 1 1 1 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 - - 2 1 1 2 2 2 2 2 2 2 2 0 - - - 2 2 2 2 2 2 2 2 2 2 3 3 3 3 3 3 3 2 2 2 3 3 3 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 - - - - - - - - - - - - - - -;
END;

[characters block containing DNA data has been removed]

BEGIN CHARACTERS;
	TITLE intron;
	LINK taxa=PF00237_20;
	DIMENSIONS nchar=31;
	FORMAT datatype=standard gap=- missing=?;
	CHARLABELS
	 '49-1' '61-1' '66-0' '79-0' '111-0' '114-0' '123-1' '137-0' '148-1' '158-0' '169-0' '172-1' '173-0' '182-0' '182-1' '222-0' '223-0' '225-0' '225-2' '227-0' '235-0' '238-0' '251-1' '271-2' '272-0' '274-1' '284-1' '297-0' '307-0' '340-0' '342-0';
	MATRIX
	Arabidopsis_thaliana_AAF99734.1	0000000100000000000010000101000
	Homo_sapiens_BAB79462.1	0000001100000100000001000000100
	Drosophila_melanogaster_AAF46195.1	0000000100000000000000000000000
	Caenorhabditis_elegans_AAL32251.1	0000000000010000001000000100000
	Encephalitozoon_cuniculi_CAD25673.1	0000000000000000000000000000000
	Plasmodium_falciparum_AAN37255.1	0000000000000000000000000000000
	Schizosaccharomyces_pombe_CAA20776.1	0000000000000000000000000000000
	Drosophila_melanogaster_AAF48662.2	0000000001000000000000100000000
	Saccharomyces_cerevisiae_CAA89472.1	0000000000000000000010000000000
	Arabidopsis_thaliana_CAB79638.1	0101010000100000010000000010001
	Neurospora_crassa_CAC18189.1	0000100000000010000000001000000
	Guillardia_theta_AAK39769.1	0000000000000000000000000000000
	Chlamydomonas_reinhardtii_AAO53243.1	0010000000001000000100010000000
	Arabidopsis_thaliana_AAC18792.1	0000101100000000000010000101000
	Arabidopsis_thaliana_AAG51551.1	0000010000100000100000100000000
	Pisum_sativum_AAA33656.1	0000000010000000000000000000000
	Schizosaccharomyces_pombe_CAA18285.1	0000000000000000000000000000000
	Saccharomyces_cerevisiae_CAA82023.1	0000000000000000000010000000000
	Oryza_sativa_BAB39116.1	1000010000100001000000100000010
	Schizosaccharomyces_pombe_CAB10153.1	0000000000000000000000000000000
	;
END;

BEGIN SPAN;
	TITLE metadata_for_this_family;
	LINK taxa=PF00237_20;
	SPANDEX version=0.1;
	ADD to=taxa attributes=(pfam_id) source=pfam data=
		PF00237_20,
		;
	ADD to=taxlabels attributes=(species,accession) source=GENBANK data=
		Arabidopsis_thaliana_AAF99734.1	Arabidopsis_thaliana	AAF99734.1,
		Arabidopsis_thaliana_AAC18792.1	Arabidopsis_thaliana	AAC18792.1,
		Drosophila_melanogaster_AAF46195.1	Drosophila_melanogaster	AAF46195.1,
		Homo_sapiens_BAB79462.1	Homo_sapiens	BAB79462.1,
		Caenorhabditis_elegans_AAL32251.1	Caenorhabditis_elegans	AAL32251.1,
		Saccharomyces_cerevisiae_CAA82023.1	Saccharomyces_cerevisiae	CAA82023.1,
		Saccharomyces_cerevisiae_CAA89472.1	Saccharomyces_cerevisiae	CAA89472.1,
		Neurospora_crassa_CAC18189.1	Neurospora_crassa	CAC18189.1,
		Schizosaccharomyces_pombe_CAB10153.1	Schizosaccharomyces_pombe	CAB10153.1,
		Schizosaccharomyces_pombe_CAA18285.1	Schizosaccharomyces_pombe	CAA18285.1,
		Encephalitozoon_cuniculi_CAD25673.1	Encephalitozoon_cuniculi	CAD25673.1,
		Guillardia_theta_AAK39769.1	Guillardia_theta	AAK39769.1,
		Arabidopsis_thaliana_CAB79638.1	Arabidopsis_thaliana	CAB79638.1,
		Arabidopsis_thaliana_AAG51551.1	Arabidopsis_thaliana	AAG51551.1,
		Oryza_sativa_BAB39116.1	Oryza_sativa	BAB39116.1,
		Chlamydomonas_reinhardtii_AAO53243.1	Chlamydomonas_reinhardtii	AAO53243.1,
		Pisum_sativum_AAA33656.1	Pisum_sativum	AAA33656.1,
		Drosophila_melanogaster_AAF48662.2	Drosophila_melanogaster	AAF48662.2,
		Plasmodium_falciparum_AAN37255.1	Plasmodium_falciparum	AAN37255.1,
		Schizosaccharomyces_pombe_CAA20776.1	Schizosaccharomyces_pombe	CAA20776.1,
		;
	METHOD ancestor program=BUGS parameters=(loglikelihood=-2.179E+2, alpha=2.639E-1, beta=3.179E+0, burnin=1000, monitor=1000) version=unix-0.600;
	METHOD ancestral_introns program=BUGS;
	METHOD alignment_quality program=t-coffee version=2.03;
	METHOD alignment program=clustalw version=1.83;
	METHOD phylogeny program=MrBayes version=3.0B4;
END;

[ history block has been removed ]
";

my $nex_obj_05 = new Bio::NEXUS();
$nex_obj_05->read( { 'format' => 'string', 'param' => $nex_file } );
my $span_block = $nex_obj_05->get_block('span');

#print Dumper $nex_obj_05->get_taxlabels();
$nex_obj_05->add_otu_clone('Neurospora_crassa_CAC18189.1',
'Neurospora_crassa_CAC18189.1_clone');

my $taxlabels_data = $span_block->get_data('taxlabels');
#print Dumper $taxlabels_data;

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	foreach my $taxon ( @{ $taxlabels_data } ) {
		foreach my $entry ( @{ $taxon } ) {
			if ($entry eq 'Neurospora_crassa_CAC18189.1') {
				#print "Found it!\n";
				#print Dumper $taxon;
      			cmp_deeply($taxon, supersetof('Neurospora_crassa_CAC18189.1', 'Neurospora_crassa_CAC18189.1_clone'), "now the entry for the orginal OTU contains the clone as well");
			}
		}
	}
}

print "\n";
print "--- nex_obj_06 ---\n";
my $nex_obj_06 = new Bio::NEXUS('t/data/compliant/unaligned_simple_01.nex');
# 'Unaligned' block
# original OTUS: taxon_1, taxon_2, taxon_3, taxon_4
my $unalign_block = $nex_obj_06->get_block('unaligned');
is ($unalign_block->find_taxon('taxon_3'), 1, "taxon_3 exists");
is ($unalign_block->find_taxon('taxon_3_clone'), 0, "taxon_3_clone does NOT exist... yet");

$nex_obj_06->add_otu_clone('taxon_3', 'taxon_3_clone');

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	#print Dumper $unalign_block;
	cmp_deeply($unalign_block->get_taxlabels(), set('taxon_1', 'taxon_2', 'taxon_3', 'taxon_4', 'taxon_3_clone'), "taxlabels struct is updated");
}

my $seq_string = $unalign_block->get_otuset()->get_otu('taxon_3_clone')->get_seq_string();
is($seq_string, 'ACCAGGACTAGATCAAG', "sequence was cloned properly");

#$nex_obj_06->write('-');
