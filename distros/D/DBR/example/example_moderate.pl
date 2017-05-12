#!/usr/bin/perl
use strict;
use lib qw'lib ../lib ../../lib';
####### Provision the sandbox DB, for examples/testing only ###########
use DBR::Sandbox( schema => 'music', writeconf => 'generated_dbr.conf', reuse => 1 ); 
#######################################################################

# Here is the real code:

use DBR ( conf => 'generated_dbr.conf', logpath => 'dbr_example.log', loglevel => 'debug3', use_exceptions => 1 );



my $music = dbr_connect('music'); # dbr_connect is imported into your scope when you 'use DBR (...)'


print "The choices for rating are:\n";
foreach my $rating ( $music->album->enum('rating') ){
      print "\t $rating \t ( " . $rating->handle . " )\n";
}

print "\n\n";
my $artists = $music->artist->all;


print "Artists:\n";
my $ct;
while (my $artist = $artists->next){

      print "\t" . $artist->name . "\t Royalty Rate: " . $artist->royalty_rate . "\n";
      my $albums = $artist->albums;


      while (my $album = $albums->next){

 	    print "\t\t Album:   '" . $album->name . "'\n";
 	    print "\t\t Rating:   " . $album->rating . " (" . $album->rating->handle .")\n"; # rating is an enum. Enums and other translators are "magic" objects
 	    print "\t\t Released: " . $album->date_released . "\n";

	    my $tracks = $album->tracks;
 	    while (my $track = $tracks->next){

 		  print "\t\t\t Track: '" . $track->name . "'\n";
 	    }
 	    print "\t\t ( No tracks )\n" unless $tracks->count;
 	    print "\n";

      }

      if ($albums->count){
	    print "\t\t ( ${\ $albums->count } albums )\n";
      }else{
	    print "\t\t ( No albums )\n";
      }

      print "\n";
}
