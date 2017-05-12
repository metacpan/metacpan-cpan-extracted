#!/usr/bin/perl

use strict;

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More tests => 14;
use DBR::Config::Scope;

my $dbr = setup_schema_ok('rt_40');

my $dbh = $dbr->connect('rt_40');
ok($dbh, 'dbr connect');
my $rv;
# Repeat the whole test twice to test both query modes (Unregistered and Prefetch)
for my $ct (1..2){
      my $albums = $dbh->album->where(
				      'artist.name' => 'Artist A'
				     );
      ok( defined($albums) , 'select albums where artist.name = "Artist A"');

      # this will loop four times
      while (my $album = $albums->next()) {
	    ok( $album->date_released, 'fetch date_released' );

	    ok ( $album->date_released( 'now' ) ,        '->date_released("now")'     ); # Do it nowwwww
	    ok ( $album->set( date_released => 'now' ) , 'set(date_released => "now")'); # Do it nowwwww

	    ok($album->name, 'fetch name');
	    ok ( $album->set( name => 'New name' ) , 'set(name => "New name")'); # Do it nowwwww
      }

}
