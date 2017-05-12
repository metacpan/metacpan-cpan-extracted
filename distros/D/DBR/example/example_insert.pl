#!/usr/bin/perl

use strict;
use lib qw'lib ../lib ../../lib';
####### Provision the sandbox DB, for examples/testing only ###########
use DBR::Sandbox( schema => 'music', writeconf => 'generated_dbr.conf', reuse => 1 ); 
#######################################################################

# Here is the real code:

use DBR ( conf => 'generated_dbr.conf', logpath => 'dbr_example.log', loglevel => 'debug3', use_exceptions => 1 );

my $music   = dbr_connect('music'); # dbr_connect is imported into your scope when you 'use DBR (...)'


my $artists = $music->artist->all;

print "Artists:\n\n";
while (my $artist = $artists->next){
    print $artist->name . "\n";
    
    while ( my $album = $artist->albums->next ){
        print "\tAlbum " . $album->name . "\n";
        
        my $track_id = $music->track->insert(
                 album_id => $album->album_id,
                 name     => 'Track ' . int(rand(100000)),
                ) or die "failed to insert";
        
        print "\t\tinserted track_id $track_id\n";
    }
}
