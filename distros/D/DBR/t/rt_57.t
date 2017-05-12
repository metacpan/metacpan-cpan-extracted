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

# Repeat the whole test twice to test both query modes (Unregistered and Prefetch)
for(1){

      my $albums = $dbh->album->all;
      ok ($albums, 'albums');

      my $ctA;
      while ( $albums->next ) {
	    $ctA++;
      }

      ok ($ctA, 'first pass ->next');

      my $ctB;
      while ( $albums->next ) {
	    $ctB++;
      }

      ok ($ctB, 'second pass ->next');

}

done_testing();
