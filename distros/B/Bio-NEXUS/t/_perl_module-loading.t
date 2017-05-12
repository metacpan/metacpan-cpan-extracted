#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: _perl_module-loading.t,v 1.6 2007/09/21 07:30:27 rvos Exp $
# $Revision: 1.6 $

# Written by Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

#use Test::More tests => 4;
use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;

use Bio::NEXUS;

############################ 1. Empty NEXUS Object ########################################
print "\n---- Empty NEXUS object creation\n";

my $nexus; 			    			 # create an NEXUS object
my $tree;  

eval {
   $nexus	 = new Bio::NEXUS(); 			    # create an object
   $tree	 = new Bio::NEXUS::Tree;
};
is( $@,'', 'NEXUS object and Bio::NEXUS::Tree object created successfully without error');  

isa_ok($nexus,'Bio::NEXUS', 'NEXUS object defined');               			 
isa_ok($tree,'Bio::NEXUS::Tree', 'Tree object defined');               			



############################ 2. Reading simple NEXUS file #########################################

my ($blocks,$character_block,$taxa_block,$tree_block);

eval {
      $nexus 		      = new Bio::NEXUS("t/data/compliant/01_basic.nex"); 			    # create an object
      $blocks 		      = $nexus->get_blocks; 			   	
      $character_block	      = $nexus->get_block("Characters"); 	
      $taxa_block 	      = $nexus->get_block("taxa");             
      $tree_block 	      = $nexus->get_block("Trees"); 	
};

## Check whether the files are read successfully

is( $@,'', 'NEXUS file parsed successfully without error');    
isa_ok($nexus,'Bio::NEXUS', 'NEXUS object defined');               


## Check the content of the NEXUS file

print "---- Contents of t/data/compliant/01_basic.nex\n";
ok( defined $nexus->get_blocks, 'NEXUS file parsed and object created successfully');    
ok( defined $blocks, 'Blocks are defined');               				

## Check for all the blocks

is(@{$blocks},3,"3 blocks are present");
isa_ok( $taxa_block, 'Bio::NEXUS::TaxaBlock', 'Bio::NEXUS::TaxaBlock object present');            
isa_ok( $character_block,"Bio::NEXUS::CharactersBlock", 'Bio::NEXUS::CharactersBlock object present');
isa_ok($tree_block,"Bio::NEXUS::TreesBlock", "Bio::NEXUS::TreesBlock object present" );              

my $taxa_labels = $taxa_block->get_taxlabels;

## Check for all the tree

$tree 	= $tree_block->get_tree();
isa_ok($tree, 'Bio::NEXUS::Tree', "Bio::NEXUS::TREE Object defined" );          			

print "---- Contents of Taxa block\n";
is(@{$taxa_labels},4," 4 taxa labels defined");
is($character_block->get_nchar,5," 5 characters defined ");
is( ref $tree,'Bio::NEXUS::Tree', 'Bio::NEXUS::Tree object present');                            
is(@{$tree->get_node_names},4,"4 OTU defined ");
is(@{$tree->get_nodes},7,"7 Nodes defined: 4 OTUs + 3 internal ");

