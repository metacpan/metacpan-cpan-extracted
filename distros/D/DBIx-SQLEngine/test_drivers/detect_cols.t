#!/usr/bin/perl

use Test;
use strict;
use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);

########################################################################

BEGIN { require 'test_drivers/get_test_dsn.pl' }

BEGIN { plan tests => 8 }

########################################################################

ok( $sqldb );

########################################################################

my $table = 'sqle_test';

FETCH_COLUMN_INFO_1: {
  if ( $sqldb =~ /AnyData/ ) {
    skip("Skipping: AnyData incorrectly caches columns before table exists.",0);
  } else {
    my @cols = $sqldb->detect_table( $table, 'quietly' );
    ok( scalar( @cols ) == 0 );
  }
}

CREATE_TABLE: {

  unless ( $sqldb =~ /AnyData/ ) {
    $sqldb->do_drop_table( $table ) if $sqldb->detect_table($table, 'quietly');
  }
  $sqldb->do_create_table( $table, [
    { name => 'id', type => 'sequential' },
    { name => 'name', type => 'text', length => 16 },
    { name => 'color', type => 'text', length => 8 },
  ]);
  ok( 1 );
}

FETCH_COLUMN_INFO_EXISTS: {
  # warn "detect";
  my @cols = $sqldb->detect_table( $table );
  # warn "cols $#cols";
  ok( scalar( @cols ) == 3 );
}

FETCH_COLUMN_INFO_WITHROW: {

  $sqldb->do_insert( table => $table, sequence => 'id', 
			values => { name=>'Sam', color=>'green' } );

  # warn "detect";
  my @cols = $sqldb->detect_table( $table );
  # warn "cols $#cols";
  ok( scalar( @cols ) == 3 );
}

FETCH_COLUMN_NONEXISTANT: {
  # warn "detect 51";
  my @cols = $sqldb->detect_table( 'area_51_secrets', 'quietly' );
  # warn "cols $#cols";
  ok( scalar( @cols ) == 0 );
  # warn "done";
}

DROP_TABLE: {

  $sqldb->do_drop_table( $table );
  ok( 1 );

}

FETCH_COLUMN_INFO_DROPPED: {
  my @cols = $sqldb->detect_table( $table, 'quietly' );
  # warn "Columns: " . join(', ', map "'$_'", @cols );
  if ( $sqldb =~ /AnyData/ ) {
    skip("Skipping: AnyData incorrectly caches columns before table exists.",0);
  } else {
    my @cols = $sqldb->detect_table( $table, 'quietly' );
    ok( scalar( @cols ) == 0 );
  }
}

########################################################################

1;
