#!/usr/bin/perl -w

######################################################
# $Id: matrix_polymorphic-and-uncertain.t,v 1.11 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.11 $

# Written by Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date : 28th July 2006

use strict;
use warnings;
use Test::More 'no_plan';

use Bio::NEXUS;
use Data::Dumper;

######################################
#
#	Tests for polymorphism and uncertainty (ambiguity) stored in matrix data of the characters block.
#
######################################

####################################
#      1. Polymorphism test
######################################

my ( $nexus, $blocks, $character_block, $taxa_block, $tree_block );

print "\n------ Testing Polymorphism\n";
my $file_name = "t/data/compliant/02_character-polymorphic.nex";

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
my $chars          = $seq_array_hash->{'taxon_1'};
is( @{$chars}, 9, "9 characters are present in taxon_1" );
is( ref $chars->[0], 'HASH', "Hash reference" );
is( $chars->[0]->{'type'},
    'polymorphism', "Polymorphic character state parsed correctly" );
is( $chars->[1]->{'type'},
    'polymorphism', "Polymorphic character state parsed correctly" );
is( $chars->[8], '-', "Generic character state parsed correctly" );

####################################
#      2. Uncertainty test
######################################
print "\n------ Testing Uncertainity\n";

{
    my ( $nexus, $blocks, $character_block, $taxa_block, $tree_block );

    $file_name = "t/data/compliant/02_character-uncertain.nex";

######
    eval {
        $nexus = new Bio::NEXUS($file_name);    # create an object
        $blocks          = $nexus->get_blocks;
        $character_block = $nexus->get_block("Characters");
    };

    is( $@, '', 'Parsing nexus files' )
      ;    ## Check whether the files are read successfully

    is( @{$blocks}, 2, "2 blocks are present" );    ## Check for all the blocks
    isa_ok( $character_block, "Bio::NEXUS::CharactersBlock",
        'Bio::NEXUS::CharactersBlock object present' );

    my $seq_array_hash = $character_block->get_otuset->get_seq_array_hash;
    my $chars          = $seq_array_hash->{'taxon_1'};

    is( @{$chars}, 9, "9 characters are present in taxon_1" );
    is( ref $chars->[0], 'HASH', "Hash reference" );
    is( $chars->[0]->{'type'},
        'uncertainty', "Uncertainty character state parsed correctly" );
    is( $chars->[1]->{'type'},
        'uncertainty', "Uncertainty character state parsed correctly" );
    is( $chars->[8], '-', "Generic character state parsed correctly" );
}

####################################
#      2. Polymorphism & Uncertainty test
######################################
print "\n------ Testing Polymorphism & Uncertainty\n";

{
    my ( $nexus, $blocks, $character_block, $taxa_block, $tree_block );

    $file_name = "t/data/compliant/02_character-polymorphic-uncertain.nex";

######
    eval {
        $nexus = new Bio::NEXUS($file_name);    # create an object
        $blocks          = $nexus->get_blocks;
        $character_block = $nexus->get_block("Characters");
    };

    is( $@, '', 'Parsing nexus files' )
      ;    ## Check whether the files are read successfully

    is( @{$blocks}, 2, "2 blocks are present" );    ## Check for all the blocks
    isa_ok( $character_block, "Bio::NEXUS::CharactersBlock",
        'Bio::NEXUS::CharactersBlock object present' );

    my $seq_array_hash = $character_block->get_otuset->get_seq_array_hash;
    my $chars          = $seq_array_hash->{'taxon_1'};

    is( @{$chars}, 9, "9 characters are present in taxon_1" );
    is( ref $chars->[0], 'HASH', "Hash reference" );
    is( $chars->[0]->{'type'}, 'uncertainty', "Uncertainty character state parsed correctly" );
    is( $chars->[1]->{'type'}, 'polymorphism', "Polymorphic character state parsed correctly" );
    is( $chars->[8], '-', "Generic character state parsed correctly" );
}
exit;
