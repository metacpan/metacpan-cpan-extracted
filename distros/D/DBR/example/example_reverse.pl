#!/usr/bin/perl

use strict;
use lib qw'lib ../lib ../../lib';
####### Provision the sandbox DB, for examples/testing only ###########
use DBR::Sandbox( schema => 'music', writeconf => 'generated_dbr.conf', reuse => 1 ); 
#######################################################################

# Here is the real code:

use DBR ( conf => 'generated_dbr.conf', logpath => 'dbr_example.log', loglevel => 'debug3', use_exceptions => 1 );
use DBR::Util::Operator; # Imports operators into your class. ( NOT LIKE NOTLIKE GE LE BETWEEN AND OR... )

my $music   = dbr_connect('music'); # dbr_connect is imported into your scope when you 'use DBR (...)'

my $albums = $music->album->where(name => LIKE 'Alb%') or die "failed to fetch albums";


my $record;
print "Albums:\n";
while (my $album = $albums->next){
      print "\t" . $album->name . "\n";

	  print "\t\t Artist: " . $album->artist->name if $album->artist;

      print "\n";
}
