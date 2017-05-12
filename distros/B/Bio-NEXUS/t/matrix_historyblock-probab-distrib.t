#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: matrix_historyblock-probab-distrib.t,v 1.8 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.8 $


# Written by Gopalan Vivek (gopalan@umbi.umd.edu)
# Refernce : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date : 28th July 2006

use strict;
use warnings;
use Test::More 'no_plan';

use Bio::NEXUS;
use Data::Dumper;

######################################
#
#	Tests for probability distribution in History block 
#
######################################

######################################

print "\n--- Testing probability distribution values in history block\n";

my $file_one = "t/data/compliant/history-block_probab-distrib.nex";

######
print "\n------ Testing History Block functions\n";

my ($nexus, $history_block);
eval {
	$nexus = new Bio::NEXUS($file_one);
	$history_block = $nexus->get_block('history', 'foo');
};
is($@, '', 'Not expecting any errors or warnings');

## Check whether the files are read successfully
is( $@, '', 'Parsing nexus files' );

#print Dumper $history_block;
isa_ok( $history_block, "Bio::NEXUS::HistoryBlock", 'Bio::NEXUS::HistoryBlock object present' );

{
## Test Characterstates of OTU 'A'

	my $seq_array_hash = $history_block->get_otuset->get_seq_array_hash;
	my $chars          = $seq_array_hash->{'A'}; ## 'A'

		is( @{$chars}, 6, "6 characters are present in taxon A" );
	is( ref $chars->[0], 'HASH', "Hash reference" );
	is( $chars->[0]->{'type'}, 'polymorphism', "Polymorphic character state parsed correctly" );
	is( $chars->[1]->{'type'}, 'polymorphism', "Polymorphic character state parsed correctly" );
	is( $chars->[0]->{'states'}->{0}, 1, "State frequency value parsed correctly" );
	is( $chars->[2]->{'states'}->{1}, 1, "State frequency value parsed correctly" );
}

{
## Test character states of internal node 'root'

	my $seq_array_hash = $history_block->get_otuset->get_seq_array_hash;
	my $chars          = $seq_array_hash->{'root'}; ## internal node name 

		is( @{$chars}, 6, "6 characters are present in internal node 'root' " );
	is( ref $chars->[0], 'HASH', "Hash reference" );
	is( $chars->[0]->{'type'}, 'polymorphism', "Polymorphic character state parsed correctly" );
	is( $chars->[1]->{'type'}, 'polymorphism', "Polymorphic character state parsed correctly" );
	is( $chars->[0]->{'states'}->{0}, 0.5, "State frequency value parsed correctly" );
	is( $chars->[2]->{'states'}->{1}, 0.5, "State frequency value parsed correctly" );
}
