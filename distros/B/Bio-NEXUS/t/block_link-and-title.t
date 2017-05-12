#!/usr/bin/env perl

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: block_link-and-title.t,v 1.7 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.7 $

# Written by Mikhail Bezruchko, Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date: 27 November, 2006

use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';

use Bio::NEXUS;

##############################################
#
#	Testing 'link' and 'title' private 
#	commands
#
##############################################

################################
# 1. Testing 'title' command
################################

my $file_one = "t/data/compliant/04_private-commands.nex";
my ($nex_obj, $blocks, $taxa_block, $char_block, $trees_block);
eval {
		$nex_obj = new Bio::NEXUS($file_one);
		$taxa_block = $nex_obj->get_block('taxa');
		$char_block = $nex_obj->get_block('characters');
		$trees_block = $nex_obj->get_block('trees');
};
is($@, '', 'Parsing successful');
is($taxa_block->get_ntax(), 4, 'ntax is correct');
is($taxa_block->get_title(), 'some_family', 'Taxa blocks\'s title is correct');
isnt($char_block->get_title(), 'ProTEin', 'Char block title is not "foo"');
is($char_block->get_title(), 'protein', 'Char block title is correct');

print "Changing taxa block's 'title'...\n";
$taxa_block->set_title('ome_familys');
is($taxa_block->get_title(), 'ome_familys', 'Taxa blocks\'s title is correct');

################################
# 2. Testing 'link' command
################################

is($char_block->get_link()->{'taxa'}, 'some_family', "Char block's 'link' for 'taxa' is correct");
print "Changing link for taxa...\n";
my %link_taxa = ('taxa' => 'ome_familys');
$char_block->set_link(\%link_taxa);
is($char_block->get_link()->{'taxa'}, 'ome_familys', "Char block's 'link' for 'taxa' is correct");




