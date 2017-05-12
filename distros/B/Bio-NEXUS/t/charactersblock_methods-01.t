#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: charactersblock_methods-01.t,v 1.6 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.6 $



# Written by Gopalan Vivek (gopalan@umbi.umd.edu), Mikhail Bezruchko
# Refernce: http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date: 30th October 2006

use strict;
use warnings;
use Test::More 'no_plan';

use Bio::NEXUS;
use Data::Dumper;


###########################################################
#	This file tests the handling 
#	of the Characters block
###########################################################
#
#	Associated input files:
#
#
###########################################################


println ("01_characters.t");

my ($nex1, $nex2);


# We will start with a basic ("safe") file which can be
# parsed without problems, and gradually add
# elements/commands/sub-commands

# Test 01: load the initial, "safe" file that should work
$nex1 = new Bio::NEXUS("t/data/compliant/02_characters-block_initial.nex");
my $char_block = $nex1->get_block("Characters");

ok($nex1->isa("Bio::NEXUS"), "nex1 is a Bio::NEXUS");
ok(defined $char_block, "char_block is defined");


# Check if the character block is what
# it should be


sub println {
	print shift;
	print "\n";
}
