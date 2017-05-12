#!/usr/bin/env perl

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: treesblock_methods.t,v 1.11 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.11 $


# Written by Mikhail Bezruchko, Vivek Gopalan (gopalan@umbi.umd.edu)
# Reference: perldoc Test::Tutorial, Test::Simple, Test::More
# Date: 6 December 2006

use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;
use Bio::NEXUS;

print "Testing TreesBlock.pm module (its methods)...\n";

my $nexus_file= "t/data/compliant/01_basic.nex";

my ($nexus_obj, $blocks, $trees_block);
eval {
    $nexus_obj = new Bio::NEXUS($nexus_file);    # create an object
    $blocks          = $nexus_obj->get_blocks();
    $trees_block = $nexus_obj->get_block("trees");
};

is($@, '', 'File was parsed without any problems');
isa_ok($trees_block, "Bio::NEXUS::TreesBlock", "trees_block is of appropriate data-type");

### Getters:
my $trees;
eval {
	$trees = $trees_block->get_trees();
};
is ($@, '', "processed w/o errors");
is (scalar @{$trees}, 1, "number of trees is correct");
isa_ok ($trees->[0], 'Bio::NEXUS::Tree', 'the only element of the trees array is a Tree object: ');
my $tree_one = $trees_block->get_tree("basic_bush");
is ($trees_block->get_title, undef, 'title is not set');
is ($tree_one->get_name(), 'basic_bush', "the tree name is correct");

#print Dumper $trees_block;

### Setters:
$trees_block->set_title('trees_block_title');
is ($trees_block->get_title(), 'trees_block_title', "the trees_block title is correct");

$tree_one->set_name('basic_bush_changed');
isnt ($trees_block->get_tree('basic_bush'), undef, 'the original tree was untouched');
#print Dumper $trees_block;

$trees_block->set_translate({'A' => 'a_thaliana'});
print "test this somehow...\n";
print "translate(): ", $trees_block->translate('A'), "\n";
print "translate(): ", $trees_block->translate('B'), "\n";

$trees_block->set_translate({}); # remove the 'translators'

$trees_block->set_trees([]); # removing trees from the block
$trees = undef;
eval {
	$trees = $trees_block->get_trees();
};
is ($@, '', "get_trees() call didn't throw any errors");
is (scalar @{$trees}, 0, "number of trees is correct");
is ($trees_block->get_tree('basic_bush'), undef, 'basic_bush is no longer there');

### Add
$trees_block->add_tree($tree_one);
is (scalar @{$trees_block->get_trees()}, 1, "there is 1 tree in the 'trees_block'");

my $str_tree = "(((((((A:3,B:1):1[100],C:2):1[90],D:3):1[80],E:4):1[70],F:5):1[60],G:6):1[50],H:7):1[40]";
my $str_tree_with_nhx = "(A:0.00161[&&NHX:G=ENSG00000189395:O=ENST00000342416.2:S=HUMAN],((B:0[&&NHX:G=ENSG00000205275:O=ENST00000338938.2:S=HUMAN],C:0[&&NHX:G=ENSG00000188384:O=ENST00000342039.2:S=HUMAN]):0[&&NHX:B=10:D=Y:S=HUMAN],D:0[&&NHX:G=ENSG00000205271:O=ENST00000379430.1:S=HUMAN]):0.00161[&&NHX:B=10:D=Y:S=HUMAN])[&&NHX:B=0:D=Y:S=HUMAN]";
eval {
	$trees_block->add_tree_from_newick($str_tree, "basic_ladder");
	$trees_block->add_tree_from_newick($str_tree_with_nhx, "some_nhx");
};
is ($@, '', "trees in newick & nhx format were parsed w/o errors");
is (scalar @{$trees_block->get_trees()}, 3, "there are 3 trees in the 'trees_block'");
print "how should this be tested?\n";
is ($trees_block->get_tree('basic_ladder')->as_string_inodes_nameless(), ($str_tree . ";"), "string representation matches the original tree");
is ($trees_block->get_tree('some_nhx')->as_string_inodes_nameless(), ($str_tree_with_nhx . ";"), "string representation matches the original tree");
print "more tests are needed...\n";

### Other methods...
$trees_block->set_trees([]); # reset the tree:
$trees_block->add_tree($tree_one);
$trees_block->rename_otus({'B' => 'chimp'});
# check if taxlabels contains 'B' (it shouldnt)
my @taxa = @{$trees_block->get_taxlabels()};
my $has_taxon = 0;
foreach my $taxon (@taxa) {
	if ($taxon eq 'B') {
		$has_taxon = 1;
		last;
	}
}
is ($has_taxon, 0, "taxon 'B' successfully renamed");
my $node = $trees_block->get_tree('basic_bush_changed')->find('A');
isnt ($node, undef, "there is a node named 'A'");
$node = undef;
$node = $trees_block->get_tree('basic_bush_changed')->find('B');
is ($node, undef, "there is no node named 'B'");
$node = undef;
$node = $trees_block->get_tree('basic_bush_changed')->find('chimp');
isnt ($node, undef, "there is a node named 'chimp'");
is ($node->get_length(), 1, "the length of node 'chimp' is 1");
#print Dumper $node;

### Tree/subtree methods
$trees_block = undef;
$trees_block = new Bio::NEXUS::TreesBlock();
$trees_block->set_title('trees_block_title');
$str_tree = "(((((((A:3,B:1):1[100],C:2):1[90],D:3):1[80],E:4):1[70],F:5):1[60],G:6):1[50],H:7):1[40]";
$str_tree_with_nhx = "(A:0.00161[&&NHX:G=ENSG00000189395:O=ENST00000342416.2:S=HUMAN],((B:0[&&NHX:G=ENSG00000205275:O=ENST00000338938.2:S=HUMAN],C:0[&&NHX:G=ENSG00000188384:O=ENST00000342039.2:S=HUMAN]):0[&&NHX:B=10:D=Y:S=HUMAN],D:0[&&NHX:G=ENSG00000205271:O=ENST00000379430.1:S=HUMAN]):0.00161[&&NHX:B=10:D=Y:S=HUMAN])[&&NHX:B=0:D=Y:S=HUMAN]";
eval {
	$trees_block->add_tree_from_newick($str_tree, "basic_ladder");
	$trees_block->add_tree_from_newick($str_tree_with_nhx, "some_nhx");
};
is ($@, '', "trees in newick & nhx format were parsed w/o errors");
$trees_block->add_tree($tree_one);
is (scalar @{$trees_block->get_trees()}, 3, "there are 3 trees in the 'trees_block'");
eval {
	$trees_block = $trees_block->select_tree('basic_ladder');
};
is ($@, '', "select_tree('basic_ladder') call didn't throw any errors");
is ($trees_block->get_title(), 'trees_block_title', "block's title is in tact");
is (scalar @{$trees_block->get_trees()}, 1, "the trees_block now has only 1 block");
is ($trees_block->get_tree('some_nhx'), undef, "'some_nhx' isnt there");
is ($trees_block->get_tree('basic_bush_changed'), undef, "'basic_bush_changed' isnt there");
isnt ($trees_block->get_tree('basic_ladder'), undef, "'basic_ladder' is there");
isa_ok ($trees_block->get_tree('basic_ladder'), "Bio::NEXUS::Tree");

# select_subtree
$trees_block = undef;
$trees_block = new Bio::NEXUS::TreesBlock();
$trees_block->set_title('block_title');
$trees_block->add_tree_from_newick('((A:1,B:1):1,(C:1,D:1):1)', 'basic_bush');
eval {
	$trees_block->select_subtree('inode5');
};
isnt ($@, '', "inode5 doesn't exist, so we must expect an error");
eval {
	$trees_block->select_subtree('inode2');
};
is ($@, '', "select_subtree() call didnt give any errors"); 
print Dumper $trees_block;
is (scalar @{$trees_block->get_tree('basic_bush')->get_nodes()}, 3, "there are 2 nodes left");
print $trees_block->get_tree('basic_bush')->as_string_inodes_nameless(), "\n";
isnt ($trees_block->get_tree('basic_bush')->find('A'), undef, "taxon 'A' is in the tree");
is ($trees_block->get_tree('basic_bush')->find('J'), undef, "taxon 'J' is not in the tree");

eval {
	my @otus = @{$trees_block->get_otus()};
	print "is this a bug?\n";
};
SKIP: {
# OTUs and Taxlabels seem to be used interchangibly
# in treesblock. get_otus is a Block.pm method which
# returns otus based on 'otuset' object. treesblock
# inherits the method, but it does not contain the
# 'otuset' object, so it throws an error when this
# method is called. see the source code.
# ~Mikhail 1/31/2007

skip "get_otus() needs to be added in TreesBlock.pm", 1;

is ($@, '', "get_otus() call didn't throw any errors");
}

# translate
# reroot_tree
# reroot_all_trees
# select_otus
# select_subtree
# exclude_subtree 

# clone() and equals() methods are tested in a separate file



