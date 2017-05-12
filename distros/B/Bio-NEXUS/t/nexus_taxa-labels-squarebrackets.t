#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: nexus_taxa-labels-squarebrackets.t,v 1.10 2007/09/21 07:30:27 rvos Exp $
# $Revision: 1.10 $


# Written by Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

# To test the effect of taxa label strings.

#use Test::More tests => 4;
use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;

use Bio::NEXUS;

my ($nexus, $tree, $tree_block, $taxa_block, $file_name);

################## #
#   1. testing the Comments processing in the NEXUS files 
#      a) comments within NEXUS words
#      b) special characters in comments
######################################

print "\n---- comment-interrupted labels in taxname list and in char labels\n"; 

$file_name = 't/data/compliant/01_taxa-labels-squarebrackets.nex';

eval {
   $nexus      = new Bio::NEXUS( $file_name ); 					    # create an object
};

is( $@,'', 'NEXUS object created and parsed');                # check that we got something
print $@;
$taxa_block = $nexus->get_block("Taxa");
ok(grep(/Two/, @{$nexus->get_block("Characters")->get_charlabels}) > 0,"comment-interrupted label properly set in character label in Characters block");
ok(grep(/word/, @{$taxa_block->get_taxlabels}) > 0,"comment-interrupted label properly set in Taxa block");

# end
