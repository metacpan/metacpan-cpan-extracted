#!/usr/bin/perl 

######################################################
#
# $Id: uncat_write.t,v 1.2 2010/09/22 19:59:00 astoltzfus Exp $
# $Revision: 1.2 $
#
# Reference : http://www.perl.com/pub/a/2004/05/07/testing.html
#
# written by Arlin to test methods implemented for Val Guignon
#
use strict;
use warnings;
use Test::More 'no_plan';
use Bio::NEXUS;
use Data::Dumper;

##############################
#
#	uncat_file_read.t
#
##############################

print "\n--- Testing file writing \n";

my $filename = "t/data/compliant/04_equals_methods.nex";
my $nexus_object = new Bio::NEXUS($filename);

# Write out the data to a temp file, test for execution errors (weak test)
#
# but this should be done with a legitimate temp file: see methods in 
#    http://www.unix.org.ua/orelly/perl/cookbook/ch07_06.htm
#
eval { 
	$nexus_object->write("test.nex");
}; 
is( $@,'', 'nexus object written to file without errors');         

my $nexus_data = '';
my $nexus_handle;
open($nexus_handle, ">", \$nexus_data); # open a memory file

eval { 
	$nexus_object->write($nexus_handle);
	close($nexus_handle);
}; 
is( $@,'', 'nexus object written to memory file without errors');         


# Read the data back into a second nexus 
# my $other_nexus = . . .  
# compare the two nexus objects via block comparisons -- see 04_equals_methods.nex 
# (note that the equals methods are not completely finished) 

# Now do the same thing with writing it out to a memory file 

# leave us a "TODO" note about what needs to be done to finish this test suite
TODO: {
	local $TODO = ': Add global equality test when needed methods are ready';
}

