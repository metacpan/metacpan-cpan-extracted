#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: tree_support-values.t,v 1.7 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.7 $


# Written by Vivek Gopalan (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;
use Bio::NEXUS;

my ($tree, $tree_block, $file_name, $nexus_obj);


################## 1. Branch support value parsing #######################################

print "---- Test for parsing branch support values (non-NHX) values from the tree \n"; 

$file_name = "t/data/compliant/trees_branch-support-values.nex";

# tree basic = (((((((A:1,B:1)inode7:1[100],C:2)inode6:1[90],D:3)inode5:1[80],E:4)inode4:1[70],F:5)inode3:1[60],G:6)inode2:1[50],H:7)root[40];

eval {
   $nexus_obj = new Bio::NEXUS($file_name);
   $tree_block = $nexus_obj->get_block('trees');
};

is( $@,'', 'TreesBlock object created and parsed');                # check that we got something

#$nexus_obj->write("test1.nex");
$tree = $tree_block->get_tree();

my $node_H = $tree->find('H');
my $root_node = $tree->get_rootnode;

my $root_node_clone = $root_node->clone;
$root_node->set_nhx_tag('S',['Human']);

print $tree->as_string,"\n";

is(@{$tree->get_nodes},15,"15 nodes defined: 8 otus + 7 root");

is($root_node->get_support_value,40,"Root node support values returned correctly as 40");
is($node_H->get_support_value,undef,"Undefined support values returned correctly");

