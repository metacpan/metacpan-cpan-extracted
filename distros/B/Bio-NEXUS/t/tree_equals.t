#!/usr/bin/env perl

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: tree_equals.t,v 1.11 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.11 $


# Written by Mikhail Bezruchko, Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date: 30 November, 2006

use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';
use Bio::NEXUS;

##############################################
#	testing the equality method
#	of the Tree.pm, Node.pm,
##############################################

print "\n";

my ($nex_obj, $trees_block);

eval {
	$nex_obj = Bio::NEXUS->new("t/data/compliant/basic-trees.nex");
	$trees_block = $nex_obj->get_block("Trees");
};

is ($@, '', "file parsed w/o problems");

#print Dumper $trees_block;
print ">This block contains ", scalar @{$trees_block->get_trees()}, " trees\n";

# 1. testing equality of topology

print "\ntype: bush\n";
my $tree_1 = $trees_block->get_tree("bush");
my $tree_2 = $trees_block->get_tree("bush_isomer");
my $tree_3 = $trees_block->get_tree("bush_diff");
# rename all trees to have same name
$tree_2->set_name($tree_1->get_name());
$tree_3->set_name($tree_1->get_name());

#ok ($tree_1->_equals_test($tree_2), "_equals_test: bushes ARE equal");
#ok (!$tree_1->_equals_test($tree_3), "_equals_test: bushes are NOT equal");
### === ###
ok ($tree_1->equals($tree_2), "equals: tree_1 == tree_2");
ok (!$tree_1->equals($tree_3), "equals: tree_1 != tree_2");

print "\ntype: ladder\n";
$tree_1 = $trees_block->get_tree("ladder_one");
$tree_2 = $trees_block->get_tree("ladder_one_isomer_1");
$tree_3 = $trees_block->get_tree("ladder_one_isomer_2");
my $tree_4 = $trees_block->get_tree("ladder_one_diff");
# rename all trees to have same name
$tree_2->set_name($tree_1->get_name());
$tree_3->set_name($tree_1->get_name());
$tree_4->set_name($tree_1->get_name());

#ok ($tree_1->_equals_test($tree_2), "_equals_test: tree_1 == tree_2");
#ok ($tree_1->_equals_test($tree_3), "_equals_test: tree_1 == tree_3");
#ok ($tree_2->_equals_test($tree_3), "_equals_test: tree_2 == tree_3");
#ok (!$tree_1->_equals_test($tree_4), "_equals_test: tree_1 != tree_4");
### === ###
ok ($tree_1->equals($tree_2), "equals: tree_1 == tree_2");
ok ($tree_1->equals($tree_3), "equals: tree_1 == tree_3");
ok ($tree_2->equals($tree_3), "equals: tree_2 == tree_3");
ok (!$tree_1->equals($tree_4), "equals: tree_1 != tree_4");

print "\ntype: rake\n";
$tree_1 = $trees_block->get_tree("rake_one");
$tree_2 = $trees_block->get_tree("rake_one_isomer_1");
$tree_3 = $trees_block->get_tree("rake_one_diff");
print "tree name: ", $tree_1->get_name(), "\n";
# rename all trees to have same name
$tree_2->set_name($tree_1->get_name());
$tree_3->set_name($tree_1->get_name());

ok ($tree_1->equals($tree_2), "equals: tree_1 == tree_2");
ok (!$tree_1->equals($tree_3), "equals: tree_1 != tree_3");

print "\ntype: mixed or other\n";
$tree_1 = $trees_block->get_tree("thing_one");
$tree_2 = $trees_block->get_tree("thing_one_isomer_1");
$tree_3 = $trees_block->get_tree("thing_one_diff");
print "tree name: ", $tree_1->get_name(), "\n";
# rename all trees to have same name
$tree_2->set_name($tree_1->get_name());
$tree_3->set_name($tree_1->get_name());

ok ($tree_1->equals($tree_1), "equals: tree_1 == tree_1");
ok ($tree_1->equals($tree_2), "equals: tree_1 == tree_2");
ok (!$tree_1->equals($tree_3), "equals: tree_1 != tree_3");

$tree_1 = $trees_block->get_tree("thing_two");
$tree_2 = $trees_block->get_tree("thing_two_isomer_1");
$tree_3 = $trees_block->get_tree("thing_two_diff");
print "tree name: ", $tree_1->get_name(), "\n";
# rename all trees to have same name
$tree_2->set_name($tree_1->get_name());
$tree_3->set_name($tree_1->get_name());

ok ($tree_1->equals($tree_1), "equals: tree_1 == tree_1");
ok ($tree_1->equals($tree_2), "equals: tree_1 == tree_2");
ok (!$tree_1->equals($tree_3), "equals: tree_1 != tree_3");

$tree_1 = $trees_block->get_tree("TF342628");
$tree_2 = $trees_block->get_tree("TF342628_diff_1");
print "tree name: ", $tree_1->get_name(), "\n";
# rename all trees to have same name
$tree_2->set_name($tree_1->get_name());

ok ($tree_1->equals($tree_1), "equals: tree_1 == tree_1");
ok (!$tree_1->equals($tree_2), "equals: tree_1 != tree_2");

# 2. Attributes
print "\ntesting the equality of attributes\n";
print "nhx comments\n";
$tree_1 = $trees_block->get_tree("nhx_one");
$tree_2 = $trees_block->get_tree("nhx_one_diff_1");
$tree_3 = $trees_block->get_tree("nhx_one_diff_2");
print "tree name: ", $tree_1->get_name(), "\n";
# rename all trees to have same name
$tree_2->set_name($tree_1->get_name());
$tree_3->set_name($tree_1->get_name());

ok ($tree_1->equals($tree_1), "equals: tree_1 == tree_1");
ok (!$tree_1->equals($tree_2), "equals: tree_1 != tree_2");
ok (!$tree_1->equals($tree_3), "equals: tree_1 != tree_3");

print "\n? ...\n";
$tree_1 = $trees_block->get_tree("attr_one");
$tree_2 = $trees_block->get_tree("attr_one_diff_1");
$tree_3 = $trees_block->get_tree("attr_one_diff_2");
$tree_4 = $trees_block->get_tree("attr_one_diff_3");
print "tree name: ", $tree_1->get_name(), "\n";
# rename all trees to have same name
$tree_2->set_name($tree_1->get_name());
$tree_3->set_name($tree_1->get_name());
$tree_4->set_name($tree_1->get_name());

ok ($tree_1->equals($tree_1), "equals: tree_1 == tree_1");
ok (!$tree_1->equals($tree_2), "equals: tree_1 != tree_2");
ok (!$tree_1->equals($tree_3), "equals: tree_1 != tree_3");
ok (!$tree_1->equals($tree_4), "equals: tree_1 != tree_4");


#print Dumper $tree_1;


