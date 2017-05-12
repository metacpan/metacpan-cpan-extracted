#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: nexus_taxa-labels-quoted.t,v 1.7 2007/09/21 07:30:27 rvos Exp $
# $Revision: 1.7 $


# Written by Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;

use Bio::NEXUS;
my ($nexus,$blocks,$character_block,$taxa_block,$tree_block,$file_name);

################## 1.  Quoted string - 1 ; a) OTU name 'OTU C',b) charlabel 'Char 3',and c) tree name 'the ladder tree'  #####################################

print "\n---- Quoted string - 1 ; a) OTU name \'OTU C\' (single quotes) ,b) charlabel \"Char 3\",and c) tree name \"the ladder tree\" \n"; 

$file_name = 't/data/compliant/quoted-strings2.nex';

eval {
   $nexus      = new Bio::NEXUS( $file_name); 
};

print "\n$@\n" if $@ ne '';;
is( $@,'', 'NEXUS object created and parsed');                # check that we got something
ok(grep(/OTU_C/, @{$nexus->get_block('taxa')->get_taxlabels}),"taxa label 'OTU C' parsed correctly in Taxa block");
ok(grep(/OTU_C/, @{$nexus->get_block("Characters")->get_taxlabels}) > 0,"taxa label 'OTU C' parsed correctly in  Characters Block");
ok(grep(/OTU_C/, @{$nexus->get_block("Trees")->get_tree->get_node_names}) > 0,"taxa label 'OTU C' parsed correctly in the Tree");
is($nexus->get_block("Trees")->get_tree->get_name ,'the_ladder_tree',"the quoted tree name \'the ladder tree\' parsed correctly");
