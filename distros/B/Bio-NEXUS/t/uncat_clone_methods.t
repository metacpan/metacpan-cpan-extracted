#!/usr/bin/env perl

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: uncat_clone_methods.t,v 1.16 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.16 $


# Written by Mikhail Bezruchko, Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date: 30 November, 2006

use strict;
use warnings;
use Data::Dumper;
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

##############################################
#
#	Testing 'clone' methods
#	the main purpose of this test is to make sure that:
#	1. the clone() method copies the structure (object) in its entirety
#	2. whenever appropriate, the actual values are copied, not the references (deep copy vs. shallow copy)
#
##############################################

#	Bio::NEXUS
#	this is a complex 'clone' method - will be tested last

#	Bio::NEXUS::Block 
#	this should be a very generic 'clone' - most subclasses should override this method, unless there is some perl magic universal clone...

#	Bio::NEXUS::CharactersBlock - inherited?
print "\n--- Testing Bio::NEXUS::CharactersBlock \n";

my $nexus_file= "t/data/compliant/04_charactersblock_methods_05.nex";


my $nex_obj = new Bio::NEXUS($nexus_file);
my $char_block_one = $nex_obj->get_block('characters');
# clone the block
my $char_block_two = $char_block_one->clone();

# verify that blocks are cloned properly

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	cmp_deeply ($char_block_one, $char_block_two, "Structures are equivalent: Using Test::Deep to do a deep comparison");
}

is($char_block_one->find_taxon('taxon_1'), $char_block_one->find_taxon('taxon_1'), "both have 'taxon_1'");
is($char_block_one->get_ntax(), $char_block_two->get_ntax(), "'ntax' values are same");
is($char_block_one->get_nchar(), $char_block_two->get_nchar(), "'nchar' values are same");
is($char_block_one->get_type(), $char_block_two->get_type(), "block types are same");
is($char_block_one->get_title(), $char_block_two->get_title(), "titles are same");
is($char_block_one->get_link()->{'taxa'}, $char_block_two->get_link()->{'taxa'}, "taxa links are same");
is($char_block_one->get_taxlabels()->[0], $char_block_one->get_taxlabels()->[0], "taxa in corresponding locations are same");

is($char_block_one->get_otuset()->get_otu('taxon_3')->get_seq_string(),
	$char_block_one->get_otuset()->get_otu('taxon_3')->get_seq_string(), 
	"taxon_3 char sequences are same");

print "Changing char_block_one\n";
$char_block_one->rename_otus({'taxon_1' => 'tax_1_modified'});
$char_block_one->set_title('char_modified');
$char_block_one->set_link({'taxa' => 'different_taxa'});

SKIP: {
			  Test::More::skip( "clone() not finished", 1 );
#print Dumper $char_block_one;
#print Dumper $char_block_two;

			  isnt($char_block_one->find_taxon('taxon_1'), $char_block_two->find_taxon('taxon_1'), "one of the blocks doesn't have 'taxon_1'");
			  print "Warning: this bug is most likely due to errors in 'rename_otus()' method\n";
}

is($char_block_one->get_ntax(), $char_block_two->get_ntax(), "'ntax' values are same");
is($char_block_one->get_nchar(), $char_block_two->get_nchar(), "'nchar' values are same");
is($char_block_one->get_type(), $char_block_two->get_type(), "block types are same");
isnt($char_block_one->get_title(), $char_block_two->get_title(), "titles are different");
isnt($char_block_one->get_link()->{'taxa'}, $char_block_two->get_link()->{'taxa'}, "taxa links are different");

is($char_block_one->get_otuset()->get_otu('taxon_3')->get_seq_string(),
	$char_block_one->get_otuset()->get_otu('taxon_3')->get_seq_string(), 
	"taxon_3 char sequences are same");

#	Bio::NEXUS::CodonsBlock - inherited?

#	Bio::NEXUS::DataBlock - inherited?

#	Bio::NEXUS::DistancesBlock - inherited?

#	Bio::NEXUS::Functions - doesnt have any

#	Bio::NEXUS::HistoryBlock - inherited?

#	Bio::NEXUS::MatrixBlock - inherited?

#	Bio::NEXUS::Node 
print "\n--- Testing Bio::NEXUS::Node\n";
$nex_obj = undef;
$nex_obj = new Bio::NEXUS('t/data/compliant/02_characters-block_initial.nex');
my $node_1 = $nex_obj->get_block('trees')->get_tree('basic_bush')->find('A');
my $node_2 = $node_1->clone();


SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";

	Test::More::skip( "Note: the cmp_deeply() may not work properly with node", 1 );
	# verify that the objects are 'deep copied'
	#print Dumper $node_1;
	#print Dumper $node_2;
	# "Note: the cmp_deeply() may not work properly with node\n";
	cmp_deeply ($node_1, $node_2, "Structures are equivalent: Using Test::Deep to do a deep comparison");
}

is ($node_1->get_name(), $node_2->get_name(), "Node names are same");
is ($node_1->get_length(), $node_2->get_length(), "Node lengths are same");
is ($node_1->nhx_command_to_string(), $node_2->nhx_command_to_string(), "Node NHX comments are same");

print "changing node_1...\n";
$node_1->set_name('human');
$node_1->set_length(314);
my $nhx_obj = new Bio::NEXUS::NHXCmd('&&NHX:G=ENSG00000189395:O=ENST00000342416.2:S=HUMAN');
$node_1->set_nhx_obj($nhx_obj);

isnt ($node_1->get_name(), $node_2->get_name(), "Node names are not same");
isnt ($node_1->get_length(), $node_2->get_length(), "Node lengths are not same");
isnt ($node_1->nhx_command_to_string(), $node_2->nhx_command_to_string(), "Node NHX comments are not same");

print "Note: How can we test the children nodes?\n";

#	Bio::NEXUS::NotesBlock - inherited?

#	Bio::NEXUS::SetsBlock - inherited?

#	Bio::NEXUS::SpanBlock - inherited?

#	Bio::NEXUS::TaxUnit 
print "\n--- Testing Bio::NEXUS::TaxUnit\n";
my $tu_1 = new Bio::NEXUS::TaxUnit('A', str_to_arrayref('-MQVADISLQG--DAKKGANLFKTRCAQCHTLKAGEGNKI-----------GPELHG-?'));
my $tu_2 = $tu_1->clone();

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	#skip "Note: the cmp_deeply() may not work properly with node";
	# compare the objects:
	cmp_deeply ($tu_1, $tu_2, "Structures are equivalent: Using Test::Deep to do a deep comparison");
}

is ($tu_1->get_name(), $tu_2->get_name(), "TU names are same");
is ($tu_1->get_seq_string(), $tu_2->get_seq_string(), "TU seq-s are same");
eval {
		print "...testing 'get_seq_string()'... ", $tu_1->get_seq_string(), "\n";
};
is ($@, '', 'get_seq_string() works fine');

print "Changing tu_1\n";
$tu_1->set_name('A_Thaliana');
$tu_1->set_seq(str_to_arrayref('-------MAGG--DIKKGANLFKTRCAQCHTVEKDGGNKI-----------GPALHG--'));

isnt ($tu_1->get_name(), $tu_2->get_name(), "TU names are different");
isnt ($tu_1->get_seq_string(), $tu_2->get_seq_string(), "TU seq-s are different");

#	Bio::NEXUS::TaxUnitSet 
print "\n--- Testing Bio::NEXUS::TaxUnitSet\n";

$tu_1 = new Bio::NEXUS::TaxUnit('A', str_to_arrayref('-MQVADISLQG--DAKKGANLFKTRCAQCHTLKAGEGNKI-----------GPELHG-?'));
$tu_2 = new Bio::NEXUS::TaxUnit('B', str_to_arrayref('-------MAGG--DIKKGANLFKTRCAQCHTVEKDGGNKI-----------GPALHG--'));
my $tu_3 = new Bio::NEXUS::TaxUnit('C', str_to_arrayref('-MG----FSAG--DLKKGEKLFTTRCAQCHTLKEGEGNKV-----------GPALHG--'));
sub str_to_arrayref {
		my ($str) = @_;
		return [ split(//,$str) ];

}
my $tu_array = [$tu_1, $tu_2];
my $tu_set_1 = new Bio::NEXUS::TaxUnitSet($tu_array);
my $tu_set_2 = $tu_set_1->clone();

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
# compare the objects
cmp_deeply ($tu_set_1, $tu_set_2, "Structures are equivalent: Using Test::Deep to do a deep comparison");
}

is (scalar @{$tu_set_1->get_otus()}, scalar @{$tu_set_2->get_otus()}, "Number of OTUs is same");
is ($tu_set_1->get_otu_names()->[0], $tu_set_2->get_otu_names()->[0], "First OTU's names are same");

print "Changing tu_set_1\n";
$tu_set_1->add_otu($tu_3);
#print Dumper $tu_set_1;
$tu_set_1->get_otu('A')->set_name('A_Thaliana');
isnt (scalar @{$tu_set_1->get_otus()}, scalar @{$tu_set_2->get_otus()}, "Number of OTUs is not same");
isnt ($tu_set_1->get_otu_names()->[0], $tu_set_2->get_otu_names()->[0], "First OTU's names are not same");

#print Dumper $tu_set_1;
#print Dumper $tu_set_2;

#	Bio::NEXUS::TaxaBlock - inherited?

#	Bio::NEXUS::Tree 
print "\n--- Testing Bio::NEXUS::Tree\n";

# "Bush rake:basal polytomy, all branch lengths = 1" 

my $nexus_file_1 = "t/data/compliant/basic-rake.nex";


my ($nexus_obj, $trees_block, $tree_one);

eval {
   $nexus_obj = new Bio::NEXUS($nexus_file_1);
   $trees_block = $nexus_obj->get_block('trees');
};
is( $@, '', 'TreesBlock object created and parsed'); # check that we got something
$tree_one = $trees_block->get_tree();

$nhx_obj = undef;
$nhx_obj = new Bio::NEXUS::NHXCmd('&&NHX:G=ENSG00000189395:O=ENST00000342416.2:S=HUMAN');
$tree_one->find('B')->set_nhx_obj($nhx_obj);

# check the tree
my $otus = scalar @{$tree_one->get_nodes};
is($otus, 9, "9 nodes defined: 8 otus + 1 root");
is(scalar @{$tree_one->get_node_names}, 8, "8 OTUs defined ");

# clone the tree
my $tree_two = $tree_one->clone();

SKIP: {
	# Test::Deep is required
	eval { require Test::Deep };
	Test::More::skip( "Test::Deep is not installed", 1 ) if $skip eq "true";
	Test::More::skip( "Note: the cmp_deeply() may not work properly with node", 1 );
# compare the trees before fiddling with them
print "Note: cmp_deeply() may not work properly with trees\n";
cmp_deeply ($tree_one, $tree_two, "Structures contain the same data: Using Test::Deep to do a deep comparison");
}

is($tree_one->get_name(), $tree_two->get_name(), "Names are same");
is($tree_one->as_string(), $tree_two->as_string(), "String representation is same");
is(scalar @{$tree_one->get_nodes()}, scalar @{$tree_two->get_nodes()}, "Number of nodes is same");
is($tree_one->get_tree_length(), $tree_two->get_tree_length(), "Tree lengths are same");
is($tree_one->get_depth()->{'F'}, $tree_two->get_depth()->{'F'}, "Depths of the 'F' node are same");
is($tree_one->max_depth(), $tree_two->max_depth(), "Max-depths are same");
is($tree_one->find('A')->get_name(), $tree_two->find('A')->get_name(), "Both trees contain 'A' node");

print "Changing tree_one\n";
$tree_one->set_name('modified_original');
$tree_one->find('F')->set_length(3);
$tree_one->find('A')->set_name('A_Thaliana');

isnt($tree_one->get_name(), $tree_two->get_name(), "Names are not same");
isnt($tree_one->as_string(), $tree_two->as_string(), "String representation is not same");
is(scalar @{$tree_one->get_nodes()}, scalar @{$tree_two->get_nodes()}, "Number of nodes is same");
#is($tree_one->get_tree_length(), $tree_two->get_tree_length(), "Tree lengths are same");
is($tree_one->get_depth()->{'F'}, $tree_two->get_depth()->{'F'}, "Depths of the 'F' node are same");
#is($tree_one->max_depth(), $tree_two->max_depth(), "Max-depths are same");
is($tree_one->find('A'), undef, "tree_one doesn't have 'A' node");
isnt($tree_two->find('A'), undef, "tree_two has 'A' node");

print "test Tree class using char-state/funky char block\n";



#	Bio::NEXUS::TreesBlock 

#	Bio::NEXUS::UnalignedBlock - inherited?

#	Bio::NEXUS::UnknownBlock - inherited?

#	Bio::NEXUS::AssumptionsBlock
print "\n--- Testing Bio::NEXUS::AssumptionsBlock ---\n";
print "write tests for this module (class)!\n";
$nex_obj = undef;
$nex_obj = new Bio::NEXUS("t/data/compliant/02_wtset-scores.nex");
my $assum_block_1 = $nex_obj->get_block("assumptions", "proteinweight");
# cloning the block
my $assum_block_2 = $assum_block_1->clone();

print "This one may fail...\n";
is_deeply($assum_block_1, $assum_block_2, "The two blocks contain the same data");
# test individual parts, just in case
is ($assum_block_1->get_assumptions()->[0]->get_name(), $assum_block_2->get_assumptions()->[0]->get_name(), "The wtset names are same");

# comparing the weights
is ($assum_block_1->get_assumptions()->[0]->{'weights'}->[0], 
	$assum_block_2->get_assumptions()->[0]->{'weights'}->[0], 
	"The corresponging weights are same");

# changing the weights array (a sub-structure)
my $temp_storage = $assum_block_1->{'assumptions'}->[0]->{'weights'}->[0]; 
$assum_block_1->{'assumptions'}->[0]->{'weights'}->[0] = '1';

SKIP: {
Test::More::skip( "Bio::NEXUS::Assumptions::clone() has to be finished",3 ); 

#print "assum_block_1: ", @{$assum_block_1->get_assumptions()->[0]->{'weights'}}, "\n";
#print "assum_block_2: ", @{$assum_block_2->get_assumptions()->[0]->{'weights'}}, "\n";

isnt ($assum_block_1->get_assumptions()->[0]->{'weights'}->[0], 
	$assum_block_2->get_assumptions()->[0]->{'weights'}->[0], 
	"The corresponging weights are NOT same");
# from Test::Deep
# at this point, there is no guarantee that the eq_deeply() actually works.
my $is_eq = eq_deeply ($assum_block_1->get_assumptions()->[0]->{'weights'}, $assum_block_1->get_assumptions()->[0]->{'weights'});
ok (!$is_eq, "the corresponding weight arrays contain different values");
$is_eq = eq_deeply ($assum_block_1, $assum_block_2);
ok (!$is_eq, "the objects are different");
}


# reverting to original
$assum_block_1->{'assumptions'}->[0]->{'weights'}->[0] = $temp_storage;

# changing 'title';
$temp_storage = $assum_block_1->get_title();
$assum_block_1->set_title('new_title');

SKIP: {
	Test::More::skip( "Test::Deep is not installed on this machine", 1 ) if $skip eq "true";
my $is_eq = eq_deeply ($assum_block_1, $assum_block_2);
ok (!$is_eq, "the objects are different");
}

# reverting to original
$assum_block_1->set_title($temp_storage);


#	Bio::NEXUS::WeightSet - does not have any, yet
print "\n--- Testing Bio::NEXUS::WeightSet ---\n";

my @weights_array = split (//, '--00000000000000113003333333333333333333333333330111112111133333344333333333333333333333333233333333334434333335553444444444344444433333333333333322010100---');
my $wtset_1 = new Bio::NEXUS::WeightSet();
$wtset_1->{'_is_token'} = 1;
$wtset_1->{'is_wt'} = 1;
$wtset_1->{'name'} = 'CORE_column_scores';
$wtset_1->{'type'} = 'VECTOR';
$wtset_1->{'weights'} = \@weights_array;

#my $wtset_2 = $wtset_1->clone();

#print Dumper $wt_set_1;








