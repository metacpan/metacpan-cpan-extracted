#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: uncat_ntax-nchar-dimensions.t,v 1.10 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.10 $


# Written by Mikhail Bezruchko, Gopalan Vivek (gopalan@umbi.umd.edu)
# Refernce : http://www.perl.com/pub/a/2004/05/07/testing.html?page=2
# Date : 28th July 2006

use strict;
use warnings;
use Test::More 'no_plan';
use Bio::NEXUS;
use Data::Dumper;

######################################
#
#	Testing is the module recognizes
#	mistakes in the matrix dimensions
#
######################################

print "\n--- Testing if matrix dimension are interpreted correctly\n";

my $file_one = 't/data/compliant/simple_taxa_and_chars.nex';

print "\nFirst file \n";

# The following should work without problems
my ($nex_one);
eval {
		$nex_one = new Bio::NEXUS( $file_one );
};

# now check if the char-s block matches expected
is( $@,'', 'NEXUS file parsed successfully without error');    
is($nex_one->get_block('characters')->get_nchar, 6, 'nchar should be 6');


my $file_two = <<STRING;
#NEXUS
BEGIN TAXA;
    dimensions ntax=4;
    taxlabels A B C D;  
END;
BEGIN CHARACTERS;
	[the nchar is greater than the actual number of characters]
    dimensions nchar=12;
    format
        datatype=protein missing=? gap=- ;
    matrix
        A   -MQG-?
        B   ---G--
        C   -MGG--
        D   -MGTGQ
        ;
END;
STRING

print "Second file with wrong NCHAR(=12)\n";
# The following should warn the client
my ($nex_two);
eval {
		$nex_two = new Bio::NEXUS();
		$nex_two->read({'format' => 'string', 'param' => $file_two});
};

TODO: {
	local $TODO = 'format validation is not a part of the test suite, yet';	
	ok( $@ ne '', 'Failed parsing NEXUS file');    
}

my $file_three = <<STRING;
#NEXUS
BEGIN TAXA;
    dimensions ntax=4;
    taxlabels A B C D;  
END;
BEGIN CHARACTERS;
	[the nchar is less than the actual number of characters]
    dimensions nchar=2;
    format
        datatype=protein missing=? gap=- ;
    matrix
        A   -MQG-?
        B   ---G--
        C   -MGG--
        D   -MGTGQ
        ;
END;
STRING

print "Second file with wrong NCHAR(=2)\n";
# The following should warn the client
my ($nex_three);
eval {
		$nex_three = new Bio::NEXUS();
		$nex_three->read({'format' => 'string', 'param' => $file_three});
};

TODO: {
	local $TODO = 'format validation is not a part of the test suite, yet';	
	ok( $@ ne '', 'Failed parsing NEXUS file');    
}


