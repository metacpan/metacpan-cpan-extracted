#!/usr/bin/perl

use Test;
BEGIN { plan tests => 20 }

use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);
ok( 1 );

########################################################################

my $sqldb = DBIx::SQLEngine->new( 'dbi:NullP:' );
ok( $sqldb and ref($sqldb) =~ m/^DBIx::SQLEngine/ );

########################################################################

$sqldb->next_result( hashref => [ 
  { id => 201, name => "Dave Jones" },
  { id => 482, name => "Same Spade" } 
] );
$rows = $sqldb->fetch_select( table => 'foo' );
ok( $sqldb->last_query, 'select * from foo' );
ok( scalar @$rows == 2 and $rows->[0]->{name} eq "Dave Jones" );

$sqldb->next_result( hashref => [ 
  { id => 201, name => "Dave Jones", bar => 'Baz'  } 
] );
$rows = $sqldb->fetch_select( table => 'foo', criteria => { bar => 'Baz' } );
ok( $sqldb->last_query, 'select * from foo where bar = ?/Baz' );
ok( scalar @$rows == 1 and $rows->[0]->{name} eq "Dave Jones" );

########################################################################

$sqldb->next_result( rowcount => 1 );
$rows = $sqldb->do_insert( table => 'foo', values => { bar => 'Baz' } );
ok( $sqldb->last_query, 'insert into foo (bar) values (?)/Baz' );
ok( $rows == 1 );

$sqldb->next_result( rowcount => 0 );
$rows = $sqldb->do_insert( table => 'foo', values => { bar => 'Baz' } );
ok( $sqldb->last_query, 'insert into foo (bar) values (?)/Baz' );
ok( $rows == 0 );

########################################################################

$sqldb->next_result( rowcount => 4 );
$rows = $sqldb->do_update( table => 'foo', values => { bar => 'Baz' } );
ok( $sqldb->last_query, 'update foo set bar = ?/Baz' );
ok( $rows == 4 );

$sqldb->next_result( rowcount => 1 );
$rows = $sqldb->do_update( table => 'foo', values => { bar => 'Baz' } );
ok( $sqldb->last_query, 'update foo set bar = ?/Baz' );
ok( $rows == 1 );

$sqldb->next_result( rowcount => 0 );
$rows = $sqldb->do_update( table => 'foo', values => { bar => 'Baz' } );
ok( $sqldb->last_query, 'update foo set bar = ?/Baz' );
ok( $rows == 0 );

########################################################################

$sqldb->next_result( rowcount => 4 );
$rows = $sqldb->do_delete( table => 'foo' );
ok( $sqldb->last_query, 'delete from foo' );
ok( $rows == 4 );

$sqldb->next_result( rowcount => 0 );
$rows = $sqldb->do_delete( table => 'foo', criteria => { bar => 'Baz' } );
ok( $sqldb->last_query, 'delete from foo where bar = ?/Baz' );
ok( $rows == 0 );

########################################################################

1;
