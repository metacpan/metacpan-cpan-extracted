#!/usr/bin/env perl

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: uncat_equals_methods.t,v 1.10 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.10 $


# Written by Mikhail Bezruchko, Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date: 30 November, 2006

use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';

use Bio::NEXUS;

##############################################
#
#       Testing 'equals()' methods
#
##############################################

my $assum_file = "t/data/compliant/04_equals_methods.nex";

print "\n";
is (1, 1, "Blank");

#	Bio::NEXUS   
# very complex - will be tested last

#	Bio::NEXUS::AssumptionsBlock 
print "--- Testing Bio::NEXUS::AssumptionsBlock ---\n";

my $assum_block_1 = new Bio::NEXUS::AssumptionsBlock();
my $assum_block_2 = new Bio::NEXUS::AssumptionsBlock();
$assum_block_1->set_title("block");
$assum_block_2->set_title("block");
is ($assum_block_1->equals($assum_block_2), 1, "blocks are equals");

$assum_block_1->set_title("block_1");
is ($assum_block_1->equals($assum_block_2), 0, " after set_title(): blocks are not equals");
$assum_block_1->set_title("block");

# $assum_block_1->set_otus(['A', 'B', 'C']); -> throws an error
# is ($assum_block_1->equals($assum_block_2), 0, "after set_otus(): blocks are not equal");


# create a weightset object
# add it to the block
# is ($assum_block_1->equals($assum_block_2), 0, "after set_wt(): blocks are not equal");
# change is back

is ($assum_block_1->equals($assum_block_2), 1, "equal");

SKIP: {
skip "set_ntax() may not be needed at all", 1;
# Note: why do we need the set_ntax() method? what would be an example of its use?
$assum_block_1->set_ntax(5);
is ($assum_block_1->equals($assum_block_2), 0, "after set_ntax(): blocks are not equals");
print Dumper $assum_block_1;
print Dumper $assum_block_2;
}

$assum_block_1 = undef;
$assum_block_2 = undef;
eval {
	my $nex_obj = new Bio::NEXUS($assum_file);
	$assum_block_1 = $nex_obj->get_block('assumptions', 'proteinweight');
	$assum_block_2 = $assum_block_1->clone(); # given that clone() method is tested and is working...
};

SKIP: {
	skip "Bio::NEXUS::AssumptionsBlock: clone() and equals()", 1;
	is ($assum_block_1->equals($assum_block_2), 1, "after reading from 'file' and cloning: equal");
}

# manipulate individual scores (score of a particular character) and compare again
# broken solution - later replace with a method call
SKIP: {
skip "Bio::NEXUS::AssumptionsBlock::equals()", 1;
$assum_block_1->{'assumptions'}->[0]->{'weights'}->[0] = '1';
is ($assum_block_1->equals($assum_block_2), 0, "after modifying 'wtset' vector: not equal");
}

is_deeply ($assum_block_1, $assum_block_2, "is_deeply()");

$assum_block_1->set_title("protein_wt_modified");
#print Dumper $assum_block_1;
#print Dumper $assum_block_2;
# "Note: possible bug. clone doesn't seem to be working\n";

my $wt_set_1= $assum_block_1->get_assumptions();
#print Dumper $wt_set_1;



#	Bio::NEXUS::Block 
# what kind of blocks/data should be used for testing?

#	Bio::NEXUS::CharactersBlock 

#	Bio::NEXUS::CodonsBlock 
# not implmented/inherited

#	Bio::NEXUS::DataBlock 
# not implmented/inherited

#	Bio::NEXUS::DistancesBlock 
# not implmented/inherited

#	Bio::NEXUS::Functions 
# no need for it

#	Bio::NEXUS::HistoryBlock 

#	Bio::NEXUS::MatrixBlock 
# not implmented/inherited

#	Bio::NEXUS::Node 

#	Bio::NEXUS::NotesBlock 
# not implmented/inherited

#	Bio::NEXUS::SetsBlock 

#	Bio::NEXUS::SpanBlock 

#	Bio::NEXUS::TaxUnit 
# not implmented/inherited

#	Bio::NEXUS::TaxUnitSet 

#	Bio::NEXUS::TaxaBlock 

#	Bio::NEXUS::Tree 

#	Bio::NEXUS::TreesBlock 

#	Bio::NEXUS::UnalignedBlock 

#	Bio::NEXUS::UnknownBlock
# not implmented/inherited

#	Bio::NEXUS::WeightSet

#	Bio::NEXUS::NHXCmd
print "--- Testing Bio::NEXUS::NHXCmd ---\n";

my $nhx_1 = new Bio::NEXUS::NHXCmd('&&NHX:G=ENSG00000189395:O=ENST00000342416.2:S=HUMAN');
# exact replica of nhx_1
my $nhx_2 = new Bio::NEXUS::NHXCmd('&&NHX:G=ENSG00000189395:O=ENST00000342416.2:S=HUMAN');
# changing ENSG00000189395 to ENSG000001893956 (added a '6' to the end)
my $nhx_3 = new Bio::NEXUS::NHXCmd('&&NHX:G=ENSG000001893956:O=ENST00000342416.2:S=HUMAN');
# renamed the 'S' tag to 'T' 
my $nhx_4 = new Bio::NEXUS::NHXCmd('&&NHX:G=ENSG00000189395:O=ENST00000342416.2:T=HUMAN');
# adding a new tag
my $nhx_5 = new Bio::NEXUS::NHXCmd('&&NHX:G=ENSG00000189395:O=ENST00000342416.2:S=HUMAN:B=1');
# same as nhx_1, but the order of tags is different
my $nhx_6 = new Bio::NEXUS::NHXCmd('&&NHX:S=HUMAN:O=ENST00000342416.2:G=ENSG00000189395');

#print Dumper $nhx_1;
#print Dumper $nhx_6;
ok ($nhx_1->equals($nhx_2), "nhx_1 == nhx_2");
ok (!$nhx_1->equals($nhx_3), "nhx_1 != nhx_3");
ok (!$nhx_1->equals($nhx_4), "nhx_1 != nhx_4");
ok (!$nhx_1->equals($nhx_5), "nhx_1 != nhx_5");
ok ($nhx_1->equals($nhx_6), "nhx_1 == nhx_6");

#print "nhx_1: ", $nhx_1->to_string(), "\n";


