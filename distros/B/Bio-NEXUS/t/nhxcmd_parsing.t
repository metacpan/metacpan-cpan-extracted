#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: nhxcmd_parsing.t,v 1.9 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.9 $


# Written by Vivek Gopalan (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;
use Bio::NEXUS;


################## 1. NHX tree  ######################################

print "\n--- Tree containing NHX commands\n"; 

my $file_name = "t/data/compliant/tree-nhx.nex";


my ($nexus_obj, $tree, $tree_block, $root_node);

eval {
   $nexus_obj = new Bio::NEXUS($file_name);
   $tree_block = $nexus_obj->get_block('trees');
   $tree = $tree_block->get_tree('TF342628');
   $root_node = $tree->get_rootnode();

};
print $@;

is( $@, '', 'an object created and parsed');                # check that we got something

#$tree = $tree_block->get_tree();
#is(@{$tree->get_nodes},9,"9 nodes defined: 8 otus + 1 root");
#is(@{$tree->get_node_names},8,"8 OTUs defined ");

#$nexus_obj->write('test.nex'); ## Debug code
ok( $root_node->contains_nhx_tag('S'), "Should contain the 'S' tag");
ok( !$root_node->contains_nhx_tag('Y'), "Should NOT contain the 'Y' tag");

my @tags = $root_node->get_nhx_tags();
is($tags[0], 'B', "The elements of tags should match the expected");
isnt($tags[1], 'B', "... checking for incorrect tags");

my @values = $root_node->get_nhx_values('B');
is( $values[0], '0', "The value of 'B' tag should be a list with one element - '0'");
is( $values[1], undef, "The list of values of 'B' tag should be of length 1");

print "Setting an NHX tag values...\n";
$root_node->set_nhx_tag('D', ['N']);
@values = $root_node->get_nhx_values('D');
is( $values[0], 'N', "The tag value now should be changed");

print "Adding a new NHX tag...\n";
$root_node->set_nhx_tag('T', ['some_NCBI_taxonomy_ID_goes_here']);
@values = $root_node->get_nhx_values('T');
ok($root_node->contains_nhx_tag('T'), "The tag 'T' has been added");
is ($values[0], 'some_NCBI_taxonomy_ID_goes_here', "'T' tag and a value were successfully added");

print "Adding a new value to an existing tag and checking if it is present...\n";
$root_node->add_nhx_tag_value('S', 'Chimp');
is ($root_node->check_nhx_tag_value_present('S','Chimp'), 1, "The S tag has chimp as value" );

is($root_node->add_nhx_tag_value('S', 'Chimp'),0, "Value for the tag already present and hence not added");
$root_node->add_nhx_tag_value('S', 'Chimp');
@values = $root_node->get_nhx_values('S');
is (scalar @values, 2, "The S tag should now contain 2 elements - after trying to add same values to the tag");


print "to_string: ", $root_node->nhx_command_to_string(), "\n";

#$Data::Dumper::Maxdepth = 4;
#print Dumper $root_node;
