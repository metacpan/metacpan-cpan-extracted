#!/usr/bin/perl -w


use strict;
use warnings;

########################################################
## this file demonstrates the different subroutine 
## avaliable in DBIx::XML::DataLoader::Date
#########################################################

use DBIx::XML::DataLoader::Date;
my $date=DBIx::XML::DataLoader::Date->new();
print "the Time is ", $date->nowTime(), "\n";
print "the Date is ", $date->nowDate(), "\n";
print "the Day is ", $date->nowDay(), "\n";


print "The Full date and time is:  ", $date->now(), "\n"; 



__END__




########################################################
## The output from this script would look like this
#########################################################

the Time is 10:14:28
the Date is 10/28/2002
the Day is Mon
The Full date and time is:  Time 11:10:39 Date 10/28/2002
