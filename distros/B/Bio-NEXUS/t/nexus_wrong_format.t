#!/usr/bin/perl -w

######################################################
# Author: Chengzhi Liang, Weigang Qiu, Peter Yang, Thomas Hladish, Brendan
# $Id: nexus_wrong_format.t,v 1.7 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.7 $


# Written by Gopalan Vivek (gopalan@umbi.umd.edu)
# Reference : perldoc Test::Tutorial, Test::Simple, Test::More
# Date : 28th July 2006

#use Test::More tests => 4;
use Test::More 'no_plan';
use strict;
use warnings;
use Data::Dumper;
use Bio::NEXUS;

### NEXUS file with wrong token
# Always the NEXUS file should begin with '#NEXUS' file. The following NEXUS 
#string does not contain the '#' before the NEXUS and hence the file should not 
#be read correctly and the parser should give error message.

my $text_value =<<STRING;
NEXUS

BEGIN TAXA;
      dimensions ntax=4;
      taxlabels A B C D;  
END;

BEGIN CHARACTERS;
      dimensions nchar=5;
      format datatype=protein gap=-;
      charlabels 1 2 3 4 Five;
      matrix
A     MA-LL
B     MA-LE
C     MEATY
D     ME-TE
END;

BEGIN TREES;
       tree "basic bush" = ((A:1,B:1):1,(C:1,D:1):1);
END;

STRING

## 1. NEXUS file in wrong format

my $nexus_obj;
eval {
   $nexus_obj = new Bio::NEXUS;
   $nexus_obj->read({'format'=>'string','param'=>$text_value}); 			    # create an object
};

TODO: {
	local $TODO = 'format validation is not a part of the test suite, yet';
	isnt( $@,'', 'Wrong NEXUS file format identified successfully');                # check that we got something
	print "Wrong input NEXUS format - Error message : \n";
	print "\n$@\n";
}


