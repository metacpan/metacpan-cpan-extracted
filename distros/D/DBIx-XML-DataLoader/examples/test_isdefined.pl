#!/usr/bin/perl -w

use strict;
use warnings;

#############################################################
## This file demonstrates the DBIx::XML::DataLoader::IsDefined module
#############################################################

 use DBIx::XML::DataLoader::IsDefined;

{
print "\nExample One\n\n";

        my $test_a=0;
        my $test_b="";
	
	if(defined $test_a){print "TEST A:", $test_a, "\n";}
	if(defined $test_b){print "TEST B:", $test_b, "\n";}
        my $value_a=DBIx::XML::DataLoader::IsDefined->verify($test_a);
        my $value_b=DBIx::XML::DataLoader::IsDefined->verify($test_b);

	if(defined $value_a){print "VALUE TEST A:", $value_a, "\n";}
	if(defined $value_b){print "VALUE TEST B:", $value_b, "\n";}
}

## or 

{
print "\n\nExample Two\n\n";

	my $d=DBIx::XML::DataLoader::IsDefined->new();
        my $test_a=0;
        my $test_b="";
        if(defined $test_a){print "TEST A:",  $test_a, "\n";}
        if(defined $test_b){print "TEST B:",  $test_b, "\n";}

        my $value_a=$d->verify($test_a);
        my $value_b=$d->verify($test_b);
        if(defined $value_a){print "VALUE TEST A:",  $value_a, "\n";}
        if(defined $value_b){print "VALUE TEST B:",  $value_b, "\n";}

}



__END__

###############
############## The output from this script would look like ###############

Example One

TEST A:0
TEST B:
VALUE TEST A:0


Example Two

TEST A:0
TEST B:
VALUE TEST A:0






