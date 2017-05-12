#!/usr/bin/perl

use Test;
use strict;
use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);

########################################################################

BEGIN { require 'test_drivers/get_test_dsn.pl' }

BEGIN { plan tests => 36 }

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
  ok( $rows->[0]->{'name'} eq 'Sam' and $rows->[0]->{'color'} eq 'green' );

   # use Data::Dumper;
   # warn Dumper( $rows );

  ok( $rows->[0]->{'id'} );
  ok( $rows->[0]->{'id'} ne $rows->[1]->{'id'} );
  ok( $rows->[1]->{'id'} ne $rows->[2]->{'id'} );
  ok( $rows->[2]->{'id'} );
  
  $sqldb->do_insert( table => $table, sequence => 'id', 
			values => { name=>'Dave', color=>'blue' } );
  
  $sqldb->do_insert( table => $table, sequence => 'id', 
			values => { name=>'Bill', color=>'blue' } );
  ok( 1 );
  
  $rows = $sqldb->fetch_select( table => $table );
  ok( ref $rows and scalar @$rows == 5 );

}

SELECT_CRITERIA_SINGLE: {

  my $rows = $sqldb->fetch_select( table => $table, criteria => {name=>'Dave'});
  ok( ref $rows and scalar @$rows == 1 and $rows->[0]->{'name'} eq 'Dave' );
  
  $rows = $sqldb->fetch_select( table => $table, criteria => "name = 'Dave'" );
  ok( ref $rows and scalar @$rows == 1 and $rows->[0]->{'name'} eq 'Dave' );
  
  $rows = $sqldb->fetch_select( table => $table, criteria => {name=>'Mike'});
  ok( ref $rows and scalar @$rows == 0 );
  
  $rows = $sqldb->fetch_select( sql => "select * from $table where name = 'Dave'" );
  ok( ref $rows and scalar @$rows == 1 and $rows->[0]->{'name'} eq 'Dave' );
  
  $rows = $sqldb->fetch_select( sql => [ "select * from $table where name = ?", 'Dave' ] );
  ok( ref $rows and scalar @$rows == 1 and $rows->[0]->{'name'} eq 'Dave' );
  
  $rows = $sqldb->fetch_select( sql => "select * from $table", criteria => [ "name = ?", 'Dave' ] );
  ok( ref $rows and scalar @$rows == 1 and $rows->[0]->{'name'} eq 'Dave' );

}

SELECT_CRITERIA_MULTI: {

  my $rows = $sqldb->fetch_select( table => $table, criteria =>{color=>'blue'});
  ok( ref $rows and scalar @$rows == 2 and ( $rows->[0]->{'name'} eq 'Dave' or $rows->[1]->{'name'} eq 'Dave' ) );

  $rows = $sqldb->fetch_select( table => $table, criteria => {color=>'blue', name=>'Dave'});
  ok( ref $rows and scalar @$rows == 1 and $rows->[0]->{'name'} eq 'Dave' );
  
  $rows = $sqldb->fetch_select( sql => "select * from $table where name = 'Dave'", criteria => {color=>'blue'});
  ok( ref $rows and scalar @$rows == 1 and $rows->[0]->{'name'} eq 'Dave' );

  $rows = $sqldb->fetch_select( sql => "select * from $table where color = 'blue'", criteria => {name=>'Dave'});
  ok( ref $rows and scalar @$rows == 1 and $rows->[0]->{'name'} eq 'Dave' );

}

SELECT_CRITERIA_ONE: {

  my $row = $sqldb->fetch_one_row( table => $table, criteria => {name=>'Dave'});
  ok( ref $row and $row->{'name'} eq 'Dave' );

  $row = $sqldb->fetch_one_row( table => $table, criteria => {name=>'Mike'});
  ok( ! $row );

  my $value = $sqldb->fetch_one_value( table => $table, columns => 'name', criteria => {name=>'Dave'});
  ok( $value eq 'Dave' );

  $value = $sqldb->fetch_one_value( table => $table, columns => 'name', criteria => {name=>'Mike'});
  ok( ! $value );

}

VISIT_SELECT: {

  my ($row) = $sqldb->visit_select( table => $table, criteria => {name=>'Dave'}, sub { $_[0] });
  ok( ref $row and $row->{'name'} eq 'Dave' );

  $row = $sqldb->visit_select( table => $table, criteria => {name=>'Mike'}, sub { $_[0] });
  ok( ! $row );

  my ($value) = $sqldb->visit_select( table => $table, columns => 'name', criteria => {name=>'Dave'}, sub { $_[0]->{name} });
  ok( $value eq 'Dave' );

  $value = $sqldb->visit_select( table => $table, columns => 'name', criteria => {name=>'Mike'}, sub { $_[0]->{name} });
  ok( ! $value );
}

UPDATE: {

  $sqldb->do_update( table => $table, criteria => { name=>'Dave' }, values => { color=>'yellow' } );
  ok( 1 );
  
  my $rows = $sqldb->fetch_select( table => $table, criteria =>{name=>'Dave'} );
  ok( ref $rows and scalar @$rows == 1 and $rows->[0]->{'color'} eq 'yellow' );

}

USE_OF_LITERAL_EXPRESSIONS: {

  $sqldb->do_update( table => $table, criteria => { name=>\"'Dave'" }, values => { color=>\"'mauve'" } );
  ok( 1 );
  
  my $rows = $sqldb->fetch_select( table=>$table, criteria=>{name=>\"'Dave'"} );
  ok( ref $rows and scalar @$rows == 1 and $rows->[0]->{'color'} eq 'mauve' );

}

DELETE: {

  $sqldb->do_delete( table => $table, criteria => { name=>'Sam' } );
  ok( 1 );
  
  my $rows = $sqldb->fetch_select( table => $table );
  ok( ref $rows and scalar @$rows == 4 );

}

DROP_TABLE: {

  $sqldb->do_drop_table( $table );
  ok( 1 );

}

########################################################################

1;
