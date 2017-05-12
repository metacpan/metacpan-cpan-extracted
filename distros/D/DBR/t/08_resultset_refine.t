#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More;
use DBR::Util::Operator;

my $dbr = setup_schema_ok('music');

my $dbh = $dbr->connect('music');
ok($dbh, 'dbr connect');
my $rv;
# Repeat the whole test twice to test both query modes (Unregistered and Prefetch)
for(1..2){
      my $albums = $dbh->album->all->where( name => LIKE 'Album%' )->where(date_released => GT 'November 26th 2005');
      ok($albums, 'retrieve albums');
      while(my $album = $albums->next){
	    my $tracks = $album->tracks;
	    ok($tracks, 'retrieve tracks');
	    my $rtracks = $tracks->where(name => LIKE '%A%');
	    ok($rtracks, 'retrieve refined tracks');
	    my $rtct;

	    my $precount = $rtracks->count;
	    ok( $precount, "Pre-count" );
	    while (my $track = $rtracks->next){
		  $rtct++;
		  ok($track->track_id, 'track has id');
		  ok($track->name, 'track has name');
	    }

	    ok( $precount == $rtct, "pre count ($precount) == actual count ($rtct)");
	    ok( $rtracks->count == $rtct, "reported count (" . $rtracks->count . ") == actual count ($rtct)");
      }


}

done_testing();
