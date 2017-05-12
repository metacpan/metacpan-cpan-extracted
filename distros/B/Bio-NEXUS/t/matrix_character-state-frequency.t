#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: matrix_character-state-frequency.t,v 1.10 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.10 $


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
#	Tests for state frequency.
#
######################################

my ( $nexus, $blocks, $character_block, $taxa_block, $tree_block );

print "\n";
print "--- Testing Character State Frequency ---\n";
my $file_name = "t/data/compliant/02_character-state-frequency.nex";

######
eval {
    $nexus = new Bio::NEXUS($file_name);    # create an object
    $blocks          = $nexus->get_blocks;
    $character_block = $nexus->get_block("Characters");
};

## Check whether the files are read successfully
is( $@, '', 'Parsing nexus files' );

## Check for all the blocks

is( @{$blocks}, 2, "2 blocks are present" );
isa_ok( $character_block, "Bio::NEXUS::CharactersBlock",
    'Bio::NEXUS::CharactersBlock object present' );
my $seq_array_hash = $character_block->get_otuset->get_seq_array_hash;
my $chars          = $seq_array_hash->{'taxon_1'}; ## 'taxon_1'

is( @{$chars}, 3, "3 characters are present in taxon_1" );
is( ref $chars->[0], 'HASH', "Hash reference" );
is( $chars->[0]->{'type'},
    'polymorphism', "Polymorphic character state parsed correctly" );
is( $chars->[1]->{'type'},
    'polymorphism', "Polymorphic character state parsed correctly" );
is( $chars->[0]->{'states'}->{0},
    0.25, "State frequency value parsed correctly" );
is( $chars->[2]->{'states'}->{2}, 0.2, "State frequency value parsed correctly" );

