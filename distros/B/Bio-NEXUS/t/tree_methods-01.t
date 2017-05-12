#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: tree_methods-01.t,v 1.5 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.5 $


# Written by Vivek Gopalan (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;
use Bio::NEXUS;

my ($tree,$tree_block,$text_value);

################## 1. Bush Rake tree  ######################################

print "\n---- Bush rake:basal polytomy, all branch lengths = 1\n"; 
$text_value =<<STRING;
#NEXUS

BEGIN TAXA;
      dimensions ntax=8;
      taxlabels A B C D E F G H;  
END;

BEGIN TREES;
       tree basic_rake = (A:1,B:1,C:1,D:1,E:1,F:1,G:1,H:1);
END;
STRING

my $nexus_obj;

eval {
   $nexus_obj = new Bio::NEXUS;
   $nexus_obj->read({'format'=>'string','param'=>$text_value}); 			    # create an object
   $tree_block = $nexus_obj->get_block('trees');
};
is( $@, '', 'TreesBlock object created and parsed');                # check that we got something
$tree = $tree_block->get_tree();
is(@{$tree->get_nodes},9,"9 nodes defined: 8 otus + 1 root");
is(@{$tree->get_node_names},8,"8 OTUs defined ");


################## 2. Maximally Asymmetric tree  #######################################

print "---- maximally asymmetric tree, branch lengths = time \n"; 
$text_value =<<STRING;
#NEXUS

BEGIN TAXA;
      dimensions ntax=8;
      taxlabels A B C D E F G H;  
END;

BEGIN TREES;
       tree basic_ladder = (((((((A:1,B:1):1,C:2):1,D:3):1,E:4):1,F:5):1,G:6):1,H:7);
END;

STRING

eval {
   $nexus_obj = new Bio::NEXUS;
   $nexus_obj->read({'format'=>'string','param'=>$text_value}); 			    # create an object
   $tree_block = $nexus_obj->get_block('trees');
};

is( $@,'', 'TreesBlock object created and parsed');                # check that we got something


$tree = $tree_block->get_tree();

is(@{$tree->get_nodes},15,"15 nodes defined: 8 otus + 7 root");
is(@{$tree->get_node_names},8,"8 OTUs defined ");

################## 3. Symmetric bifurcating tree, all branch lengths = 1 #######################################

print "---- symmetric bifurcating tree, all branch lengths = 1 \n"; 
$text_value =<<STRING;
#NEXUS

BEGIN TAXA;
      dimensions ntax=8;
      taxlabels A B C D E F G H;  
END;

BEGIN TREES;
       tree basic_bush = (((A:1,B:1):1,(C:1,D:1):1):1,((E:1,F:1):1,(G:1,H:1):1):1);
END;

STRING

eval {
   $nexus_obj = new Bio::NEXUS;
   $nexus_obj->read({'format'=>'string','param'=>$text_value}); 			    # create an object
   $tree_block = $nexus_obj->get_block('trees');
};

is( $@,'', 'TreesBlock object created and parsed');                # check that we got something

$tree = $tree_block->get_tree();
is(@{$tree->get_nodes},15,"15 nodes defined: 8 otus + 7 root");
is(@{$tree->get_node_names},8,"8 OTUs defined ");
