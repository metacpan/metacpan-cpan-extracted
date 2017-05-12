#!/usr/bin/env perl

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: uncat_shared-commands.t,v 1.8 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.8 $


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
#	Testing some common nexus commands
#	that appear in several blocks
#
##############################################

# 1. [No]Tokens
# Blocks: Characters (Format), Codons (GeneticCode), Sets (CharPartition, TaxPartition, TreePartition), Assumptions (WtSet, ...)

# 1.a Characters #

my $file_one = "t/data/compliant/04_shared_commands_01.nex";

my ($nex_obj, $char_block);

eval {
	$nex_obj = new Bio::NEXUS($file_one);
};

$char_block = $nex_obj->get_block('characters');
SKIP: {
skip "get_statelabels() is not complete", 1;
is($char_block->get_statelabels()->[0], 'red', 'state labels match expected');
}
is($char_block->{'format'}->{'tokens'}, 1, "Tokens = 1");

my $file_two = "t/data/compliant/04_shared_commands_02.nex";

$nex_obj = undef;
$char_block = undef;

eval {
	$nex_obj = new Bio::NEXUS($file_two);
};

$char_block = $nex_obj->get_block('characters');
is($char_block->{'format'}->{'notokens'}, 1, "notokens = 1");


#######################################
#	We might not need this test...
#######################################

my $file_three = "t/data/compliant/04_shared_commands_03.nex";


$nex_obj = undef;
$char_block = undef;

eval {
	$nex_obj = new Bio::NEXUS($file_three);
};

$char_block = $nex_obj->get_block('characters');

# 1.b Assumptions #
print "Testing [No]Tokens of Assumptions Block\n";

$file_one = "t/data/compliant/04_shared_commands_04.nex";

$nex_obj = undef;
my $assum_block = undef;

eval {
	$nex_obj = new Bio::NEXUS($file_one);
};

$assum_block = $nex_obj->get_block('assumptions');
SKIP: {
	skip "_is_tokens is not complete", 1;
is($assum_block->{'assumptions'}->{'_is_tokens'}, 1, '_is_tokens = 0');
}
#print Dumper $assum_block;
#print "fix this !\n";

$file_two = "t/data/compliant/04_shared_commands_05.nex";

$nex_obj = undef;
$assum_block = undef;

eval {
	$nex_obj = new Bio::NEXUS($file_two);
};

$assum_block = $nex_obj->get_block('assumptions');
SKIP: {
	skip "_is_tokens is not complete", 1;
is($assum_block->{'assumptions'}->{'_is_tokens'}, 0, '_is_tokens = 0');
}
#print Dumper $assum_block;
#print "fix this !\n";
