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
  $sqldb->do_insert( table => $table, sequence => 'id', 
			values => { name=>'Dave', color=>'blue' } );
  $sqldb->do_insert( table => $table, sequence => 'id', 
			values => { name=>'Bill', color=>'blue' } );
  
  my $rows = $sqldb->fetch_select( table => $table, order => 'id' );
  ok( ref $rows and scalar @$rows == 5 );
}

NULL_VALUE_LOGIC: {

  my $rows = $sqldb->fetch_select( table=>$table, criteria=>{ name=>undef() } );
  ok( ref $rows and scalar @$rows == 0 );
  
  $sqldb->do_update( table => $table, criteria => { name=>\"'Dave'" }, values => { name=>undef() } );
  ok( 1 );
  
  if ( $sqldb->dbms_null_becomes_emptystring ) { 
    skip("Skipping: This database does not support storing null values.", 0);
  } else {
    $rows = $sqldb->fetch_select( table=>$table, criteria=>{ name=>undef() } );
    ok( (ref $rows and scalar @$rows == 1 and $rows->[0]->{'color'} eq 'blue'), 1, "Couldn't select null value rows" );
  }
}

DROP_TABLE: {

  $sqldb->do_drop_table( $table );
  ok( 1 );

}

########################################################################

1;
