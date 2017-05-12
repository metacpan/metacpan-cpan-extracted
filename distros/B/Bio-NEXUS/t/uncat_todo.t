#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: uncat_todo.t,v 1.5 2007/09/21 07:30:27 rvos Exp $
# $Revision: 1.5 $


# Written by Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;

eval {
use Bio::NEXUS;
};
is($@,'','Bio::NEXUS module loaded successfully');


=pod

SKIP: {
	 print "\n$@\n" if $@ ne '';;
	 skip('Error loading nexus file\n', 6) if $@ ne '';
	 is( $@,'', 'Bio::NEXUS object created and parsed');                # check that we got something
	    TODO: {
	       local $TODO = ' : ERROR IN PARSING THE SPACES IN THE LABELS';
	       ok(grep(/OTU_C/, @{$nexus->get_block('taxa')->get_taxlabels}),"taxa label 'OTU C' parsed correctly in Taxa block");
	       ok(grep(/OTU_C/, @{$nexus->get_block("Characters")->get_taxlabels}) > 0,"taxa label 'OTU C' parsed correctly in  Characters Block");
	       ok(grep(/OTU_C/, @{$nexus->get_block("Trees")->get_tree->get_node_names}) > 0,"taxa label 'OTU C' parsed correctly in the Tree");
	       is($nexus->get_block("Trees")->get_tree->get_name ,'the_ladder_tree',"the quoted tree name \'the ladder tree\' parsed correctly");
	    }
}

=cut
