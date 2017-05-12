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

SELECT_CRITERIA_JOIN: {

  if ( $sqldb->dbms_select_table_as_unsupported ) {
    skip("Skipping: This database does not support selects with table aliases.", 0);
    skip("Skipping: This database does not support selects with table aliases.", 0);
    skip("Skipping: This database does not support selects with table aliases.", 0);
  } else {

    my $rows = $sqldb->fetch_select( table => ["$table as a", "$table as b"] );
    ok( ref $rows and scalar @$rows == 25 );
  
    $rows = $sqldb->fetch_select( table => [ "$table as a", "$table as b" ], criteria => { 'a.color'=>'blue'});
    ok( ref $rows and scalar @$rows == 10 );
    
    $rows = $sqldb->fetch_select( table => [ "$table as a", inner_join=>[ 'a.color = b.color' ],  "$table as b" ]);
    ok( ref $rows and scalar @$rows == 7 );
  }

}

DROP_TABLE: {

  $sqldb->do_drop_table( $table );
  ok( 1 );

}

########################################################################

1;
