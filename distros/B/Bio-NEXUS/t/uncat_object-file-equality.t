#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: uncat_object-file-equality.t,v 1.7 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.7 $


# Written by Mikhail Bezruchko, Gopalan Vivek (gopalan@umbi.umd.edu)
# Refernce : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date : 28th July 2006

use strict;
use warnings;
use Test::More 'no_plan';
use Bio::NEXUS;
use Data::Dumper;

##############################
#
#	Tests for object equality,
#	file equality, etc.
#
##############################

print "\n--- Testing file equality \n";

my $file_one = "t/data/compliant/04_object-file-equality_01.nex";
my $file_two = "t/data/compliant/04_object-file-equality_01.nex";


# Read in the first "file"
my ($nex_one, $blocks_one, $taxa_block_one, $characters_block_one, $trees_block_one);
eval {
	$nex_one = new Bio::NEXUS($file_one);
	$blocks_one = $nex_one->get_blocks;
	$taxa_block_one = $nex_one->get_block('taxa');
	$characters_block_one = $nex_one->get_block('characters');
	$trees_block_one = $nex_one->get_block('trees');
};

# Read in the second "file"
my ($nex_two, $blocks_two, $taxa_block_two, $characters_block_two, $trees_block_two);
eval {
	$nex_two = new Bio::NEXUS($file_two);
	$blocks_two = $nex_two->get_blocks;
	$taxa_block_two = $nex_two->get_block('taxa');
	$characters_block_two = $nex_two->get_block('characters');
	$trees_block_two = $nex_two->get_block('trees');
};

# Testing equality of the individual blocks
ok ($taxa_block_one->equals($taxa_block_two), 'the taxa blocks should be equal');
ok ($trees_block_one->equals($trees_block_two), 'the tree blocks should be equal');

TODO: {
	local $TODO = ': Implement deep check for charactersblock';
	ok (!($characters_block_one->equals($characters_block_two)), 'the characters block should NOT be equal');
	ok (!($nex_one->equals($nex_two)), 'two Bio::NEXUS objects should NOT be equal'); # Testing the equality of the whole file
}

