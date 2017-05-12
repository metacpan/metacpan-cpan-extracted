#!/usr/bin/perl

use Test;
use strict;
use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);

########################################################################

BEGIN { require 'test_drivers/get_test_dsn.pl' }

BEGIN { plan tests => 7 }

########################################################################

ok( $sqldb );

########################################################################

my $table = 'sqle_test';

CREATE_TABLE: {

  $sqldb->do_drop_table( $table ) if $sqldb->detect_table($table, 'quietly');
  $sqldb->do_create_table( $table, [
    { name => 'id', type => 'sequential' },
    { name => 'name', type => 'text', length => 16 },
    { name => 'color', type => 'text', length => 8 },
  ]);
  ok( 1 );

}

INSERTS_AND_SELECTS: {

  $sqldb->do_insert( table => $table, sequence => 'id', 
			values => { name=>'Sam', color=>'green' } );
  $sqldb->do_insert( table => $table, sequence => 'id', 
			values => { name=>'Ellen', color=>'orange' } );
  $sqldb->do_insert( table => $table, sequence => 'id', 
			values => { name=>'Sue', color=>'purple' } );
  ok( 1 );
  
  my $rows = $sqldb->fetch_select( table => $table, order => 'id' );
  ok( ref $rows and scalar @$rows == 3 );

}

SELECT_UNION: {

  my $rows = $sqldb->fetch_select( union => [
    { table => $table, criteria => {color=>'orange'} },
    { table => $table, criteria => {color=>'purple'} },
  ] );

  ok( ref $rows and scalar @$rows == 2 );
  ok( $rows->[0]->{'name'} eq 'Ellen' or $rows->[1]->{'name'} eq 'Ellen' );

}

DROP_TABLE: {

  $sqldb->do_drop_table( $table );
  ok( 1 );

}

########################################################################

1;
