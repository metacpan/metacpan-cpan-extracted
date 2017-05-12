#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More;

my $dbr = setup_schema_ok('music');

my $dbh = $dbr->connect('music');
ok($dbh, 'dbr connect');
my $rv;

my %ALBUMCOUNTS = (
		   'Artist A' => 1,
		   'Artist B' => 2,
		  );
# Repeat the whole test twice to test both query modes (Unregistered and Prefetch)
for(1..2){

      my $artists = $dbh->artist->all();
      ok( defined($artists) , 'select all artists');

      # this will loop four times
      while (my $artist = $artists->next()) {

	    my $albumcount;
	    ok( $albumcount = $ALBUMCOUNTS{$artist->name} , 'artist name');

	    my $albums = $artist->albums;
	    ok($albums, 'retrieve albums');
	    my $ct;
	    while(my $album = $albums->next){
		  my $date = $album->date_released;
		  ok(defined($date), '$date defined');
		  $ct++;
	    }

	    # It's important to test the number of albums to ensure that the split-query
	    # logic is functioning correctly, and not over-reporting records.
	    diag("$ct albums. reference count: $albumcount");
	    ok($ct == $albumcount,"correct number of albums");
      }

}

done_testing();
