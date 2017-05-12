#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: tree_methods-02.t,v 1.6 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.6 $


# Written by Vivek Gopalan (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;
use Bio::NEXUS;

my ($tree,$tree_block,$text_value, $nexus_obj);


################## 1. Tree functions test ######################################


print "---- Test for various functions in the Bio::NEXUS::Tree and Bio::NEXUS::Node modules\n"; 


$text_value =<<STRING;
#NEXUS

BEGIN TAXA;
      dimensions ntax=8;
      taxlabels A B C D E F G H;  
END;

BEGIN TREES;
 tree basic_ladder = (((((((A:3,B:1):1[100],C:2):1[90],D:3):1[80],E:4):1[70],F:5):1[60],G:6):1[50],H:7):1[40];

END;

STRING

# tree basic = (((((((A:1,B:1)inode7:1[100],C:2)inode6:1[90],D:3)inode5:1[80],E:4)inode4:1[70],F:5)inode3:1[60],G:6)inode2:1[50],H:7)root[40];

#                              +-----A
#                          +---+
#                   	   |   +-----B
#                      +---+    
#                 +----+   +---------C
#                 |    |        
#             +---+    +-------------D
#             |   |             
#         +---+   +------------------E
#         |   |                 
#     +---+   +----------------------F
#     |   |                     
#     +   +--------------------------G
#     |                         
#     +------------------------------H



eval {
   $nexus_obj = new Bio::NEXUS;
   $nexus_obj->read({'format'=>'string','param'=>$text_value}); 			    # create an object
   $tree_block = $nexus_obj->get_block('trees');
};

is( $@,'', 'TreesBlock object created and parsed');                # check that we got something

#$nexus_obj->write("test1.nex");
$tree = $tree_block->get_tree();

my $node_H = $tree->find('H');
my $node_A = $tree->find('A');

print $tree->as_string,"\n";

is(@{$tree->get_nodes}, 15, "15 nodes defined: 8 otus + 7 root");

## Testing Functions on Root node
print "####  Testing node functions on Root node\n";

my $root_node = $tree->get_rootnode;
is($root_node->get_parent, undef, "Rootnode parent is not defined");
is($root_node->get_length, 1, "Branch length of root node is correct");
is(@{$root_node->get_children}, 2, "No. of children for root node is correct");
is($root_node->get_total_length,38, "Total lengths of the branches from the root node is correct"); ### ????
is($root_node->get_support_value,40, "Root node support value is correct");
is($root_node->get_name,"root", "Root name label is correct");
is($root_node->get_depth,0, "Depth of root node is correct");
is($root_node->get_distance($node_H),7, "Distance of root to node H is correct"); 
is($root_node->get_distance($node_A),9, "Distance of root to node A is correct");  
is($root_node->is_sibling($node_H), 0, "Node H is not the sibilings of the rootnode");
is(@{$root_node->get_siblings},0, " No siblings to the root node");
is($root_node->is_otu,0, "Root node identified as OTU or (Terminal Node) correctly");
is($root_node->is_otu,0, "Root node identified as OTU or (Terminal Node) correctly");
#is($root_node->prune);

is($node_A->mrca($node_H)->get_name,'root', "Most recent common ancestor of node A and H is identified correctly");  
#mrca of A is B =  mrca of B is A 
is($node_H->mrca($node_A)->get_name,'root', "Most recent common ancestor of node A and H is identified correctly");  

#Consistency check - Distance from A to B =  distance from B to A 
is($root_node->get_distance($node_H),$node_H->get_distance($root_node), "Consistency check for the distance between nodes: distance(AB) = distance(BA)"); 

print "####  Testing node functions on node H\n";

is($node_H->get_parent->get_name, 'root', "Parent of Node 'H' parent is defined correctly");
is($node_H->get_length, 7, "Branch length of node H is correct");
is(@{$node_H->get_children}, 0, "No. of children for Node H is correct");
is($node_H->get_total_length,7, "Total lengths of the branches the node H is correct"); ### ????
is($node_H->get_support_value,undef, "Node H support value is correct");
is($node_H->get_name,'H', "Node H label is correct");
is($node_H->get_depth,1, "Depth of Node H  is correct");
is($node_H->get_distance($root_node),7, "Distance of node H to root node is correct");
is($node_H->get_distance($node_A),16, "Distance of node H to node A is correct");
is($node_H->is_sibling($node_A), 0, "Node A is not the sibilings of Node H");
is(@{$node_H->get_siblings},1, "No. of siblings to the Node H is correct");
is($node_H->is_otu,1, "Node H identified as an OTU (Terminal Node) correctly");

print "####  Testing node functions on cloned node H\n";
# Cloned nodes properties 
my $node_H_clone = $node_H->clone;

$node_H_clone->set_length(10);
$node_H_clone->set_support_value(100);
$node_H_clone->set_name('H_clone');

#Checking the original and the cloned nodes
is($node_H->get_name,'H', "(Original) node name label is correct");
is($node_H->get_length,7, "(Original) depth of node H is correct");
is($node_H->get_support_value,undef, "(Original) node H support value is correct");
is($node_H_clone->get_name,'H_clone', "(Cloned) node name label is correct");
is($node_H_clone->get_depth,1, "(Cloned) depth of node H is correct");
is($node_H_clone->get_support_value,100, "(Cloned) node H support value is correct");


