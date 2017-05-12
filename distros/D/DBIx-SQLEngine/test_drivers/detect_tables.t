#!/usr/bin/perl

use Test;
use strict;
use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);

########################################################################

BEGIN { require 'test_drivers/get_test_dsn.pl' }

########################################################################

if ( $sqldb->dbms_detect_tables_unsupported() ) {
  plan tests => 1;
  skip("Skipping: This database does not support retrieving table names.", 0);
  exit 0;
}

plan tests => 11;

ok( $sqldb );

########################################################################

my $table = 'sqle_test';

my $count = 0;

DETECT_TABLES: {
  ok( eval { $count = scalar ($sqldb->detect_table_names); 1; } );
}

CREATE_TABLE: {

  $sqldb->do_drop_table( $table ) if $sqldb->detect_table($table, 'quietly');
  $sqldb->do_create_table( $table, [
    { name => 'id', type => 'sequential' },
    { name => 'name', type => 'text', length => 16 },
    { name => 'color', type => 'text', length => 8 },
  ]);
  ok( 1 );

}

ADDED_TABLE: {
  my $newcount = scalar ($sqldb->detect_table_names);
  ok( $count < $newcount );
  $count = $newcount;
  ok( scalar grep { $_ =~ /$table\W?\Z/ } $sqldb->detect_table_names );
}

TABLESET: {

  ok( ref( $sqldb->tables ) );

  ok( scalar( $sqldb->tables->table_names ) > 0, 1, "Couldn't detect tables" );
  ok( scalar( $sqldb->tables->table_names ) == scalar ($sqldb->detect_table_names) );

  ok( scalar grep { $_ =~ /$table\W?\Z/ } $sqldb->tables->table_names );
}

DROP_TABLE: {

  $sqldb->do_drop_table( $table );
  ok( 1 );

}

DROPPED_TABLE: {
  # warn "Tables: " . join(', ', $sqldb->detect_table_names );
  if ( $sqldb =~ /AnyData/ ) {
    skip("Skipping: AnyData incorrectly keeps columns after table dropped.", 0);
  } else {
    ok( $count > scalar ($sqldb->detect_table_names) );
  }
}

########################################################################

1;
