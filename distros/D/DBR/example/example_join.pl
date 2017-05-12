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

print "\n========================================\n\n";

print "Do a join\n";
print "Albums where artist name like \%Artist\%, with a fair or poor rating:\n\n";

my $albums = $music->album->where(
				 'artist.name' => LIKE '%Artist%',
				 rating        => 'fair poor',
				);

while (my $album = $albums->next) {

      print $album->name . "\n";

}


print "\n========================================\n\n";


print "Do a subquery\n";
print "Artists where track name like \%Track\%, with an album rating of fair or poor:\n\n";
my $artists = $music->artist->where(
				   'albums.tracks.name' => LIKE '%Track%',
                   'albums.rating'      => 'fair poor'
				  );

while (my $artist = $artists->next) {

      print $artist->name . "\n";
      
}

print "\n========================================\n\n";


print "Do a join AND a subquery\n";
print "Albums where artist name like \%Artist\%, with a fair or poor rating, and track name like Track\%B\% :\n\n";

my $album = $music->album->where(
				'artist.royalty_rate' => GT 2.01,
				'rating'        => 'fair poor sucks',
				'tracks.name' => LIKE 'Track%B%',
				'artist.name' => LIKE '%Artist%' # yes, I'm querying crazy crazy things
			);

while (my $album = $album->next) {

      print $album->name . "\n";

}
