#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: uncat_datablock_clustalw.t,v 1.7 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.7 $


# Written by Gopalan Vivek (gopalan@umbi.umd.edu)
# Refernce : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date : 28th July 2006

use strict;
use warnings;
use Test::More 'no_plan';

use Bio::NEXUS;
use Data::Dumper;

######################################
#
#	Tests for DATA block - ClustalW
#
######################################

my ( $nexus, $blocks, $character_block, $taxa_block, $tree_block );

print "\n";
print "--- Testing Data Block - ClustalW output ---\n";
my $file_name = "t/data/compliant/data-block_clustalw.nex";

######
eval {
    $nexus = new Bio::NEXUS($file_name);    # create an object
    $blocks          = $nexus->get_blocks;
    $character_block = $nexus->get_block("Characters");
};

## Check whether the files are read successfully
is( $@, '', 'Parsing nexus files' );

## Check for all the blocks

is( @{$blocks}, 2, "2 blocks are present, DATA block parsed successfully " );
isa_ok( $character_block, "Bio::NEXUS::CharactersBlock", 'Bio::NEXUS::CharactersBlock object present' );

# Get all otus as ARRAY ref
my $otus = $character_block->get_otuset->get_otus;

# Check if ntax and number of otus parsed are same
is( $character_block->get_ntax, scalar @{$otus}, "ntax and  number of OTUS tallied" );
# Get the first OTU and get the number of characters in it
is( $character_block->get_nchar, scalar @{$otus->[0]->get_seq}, "nchar and  number of OTUS tallied" );
#print Dumper $character_block;
