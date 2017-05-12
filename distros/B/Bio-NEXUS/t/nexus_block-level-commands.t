#!/usr/bin/env perl

######################################################
# 
# Thanks to Mikhail and Vivek for the original version, 2006
#
# $Id: nexus_block-level-commands.t,v 1.10 2012/02/07 21:49:27 astoltzfus Exp $
#
# Reference : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2

use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';

use Bio::NEXUS;

##############################################
#
#	Testing generic block-level methods
#
##############################################

########### 1. Adding a block ##############
print "\n--- Testing addition ---\n";

my $nexus_file = "t/data/compliant/04_block_level_methods.nex";

my $nex_obj;

eval {
	$nex_obj = new Bio::NEXUS($nexus_file);
};

is($@, '', 'Parsing successful');
my $num_of_blocks = scalar @{$nex_obj->get_blocks()};
is($num_of_blocks, 3, "There are 3 blocks");


print "Creating a new block (cloning an existing)...\n";
my $new_char_block = $nex_obj->get_block('characters', 'protein')->clone();
$new_char_block->set_title('protein_clone');
print "Adding the block\n";
$nex_obj->add_block($new_char_block);

$num_of_blocks = scalar @{$nex_obj->get_blocks()};
is($num_of_blocks, 4, "There are 4 blocks");

#print Dumper $nex_obj->get_blocks();


########### 2. Creating a block ##############
print "\n--- Testing creation of a block ---\n";

my $block_string = 
"BEGIN CHARACTERS;
    title dna;
    dimensions nchar=33;
    format
        datatype=dna
        missing=?
        gap=-   
        ;       
        
    matrix
        A   ---atgcaagtggctgacatatcctta------
        B   ---------------------atggct------
        C   ---atgggt------------ttttct------
        D   ---atgggt------gacgttgaaaaaggtcaa
        ;       
END;";

print "Creating a block from a string variable\n";
$new_char_block = undef;
eval {
		#$new_char_block = Bio::NEXUS->create_block('characters', block_string);
		$new_char_block = Bio::NEXUS->create_block('characters');
		
};
#is ($@, '', 'Block created successfully');
#is ($new_char_block->get_title(), 'dna', 'Title is correct');
#my $otus = scalar($new_char_block->get_otus);
#is ($otus, 4, 'Number of OTUs is correct');

#print Dumper $new_char_block;
#print "Adding a new block\n";


########### 3. Removing a block ##############
print "\n--- Testing deletion ---\n";
eval {
		$nex_obj = new Bio::NEXUS($nexus_file);
};

$num_of_blocks = scalar @{$nex_obj->get_blocks()};
is ($num_of_blocks, 3, 'The object has 3 blocks');

print "Removing the trees block...\n";
eval {
		$nex_obj->remove_block('trees', 'tb_1');
};
is ($@, '', 'No warnings during deletion');
$num_of_blocks = scalar @{$nex_obj->get_blocks()};
is ($num_of_blocks, 2, 'The object has 2 blocks');

print "Removing the characters block\n";
eval {
		$nex_obj->remove_block('characters', 'protein');
};
is ($@, '', 'No errors during deletion');
$num_of_blocks = scalar @{$nex_obj->get_blocks()};
is ($num_of_blocks, 1, 'The object has 1 block');

print "Removing a block that doesn't exist\n";
print "should this be tested?\n";

#print Dumper $nex_obj;


########### 4. Renaming OTUs ##############
print "\n--- Testing the renaming of OTUs ---\n";
eval {
		$nex_obj = new Bio::NEXUS($nexus_file);
};

is(@{$nex_obj->get_otus()}[0], 'A', "First OTU is 'A'");

print "Renaming the 'A' OTU to 'human'\n";
$nex_obj->rename_otus({'A' => 'human'});
is(@{$nex_obj->get_otus()}[0], 'human', "First OTU is now 'human'");
is(@{$nex_obj->get_otus()}[1], 'B', "Second OTU is 'B'");
#print Dumper $nex_obj;
print "Warning: The taxon name is not renamed in the Trees block (the tree node)\n";

$nex_obj->rename_otus({'human' => 'A'});
isnt(@{$nex_obj->get_otus()}[0], 'human', "First OTU is not 'human' anymore");



########### 5. ##############















