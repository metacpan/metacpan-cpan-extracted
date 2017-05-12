#!/usr/bin/perl

use Test;
BEGIN { plan tests => 11 }

use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);
ok( 1 );

########################################################################

my $sqldb = DBIx::SQLEngine->new( 'dbi:NullP:' );
ok( $sqldb and ref($sqldb) =~ m/^DBIx::SQLEngine/ );

my $record_class = $sqldb->record_class('foo');
ok( $record_class and ! ref($record_class) and $record_class =~ 'DBIx::SQLEngine::Record' );

########################################################################

# The record interface requires information about the columns, which isn't 
# available in our bogus NullP environment, so we'll define them explicitly.

$record_class->columnset( 
  DBIx::SQLEngine::Schema::ColumnSet->new(  
    DBIx::SQLEngine::Schema::Column->new( type => 'text', name => 'bar' ),
    DBIx::SQLEngine::Schema::Column->new( type => 'text', name => 'buz' ),
  ) 
);

########################################################################

$record_class->fetch_select( );
ok( $sqldb->last_query, 'select * from foo' );

$record_class->fetch_select( criteria => { bar => 'Baz' } );
ok( $sqldb->last_query, 'select * from foo where bar = ?/Baz' );

$record_class->select_record( 'Baz' );
ok( $sqldb->last_query, 'select * from foo where bar = ? limit 1/Baz' );

$record_class->select_record( { bar => 'Baz' } );
ok( $sqldb->last_query, 'select * from foo where bar = ? limit 1/Baz' );

$record_class->new_and_save( buz => 'Baz' );
ok( $sqldb->last_query, 'insert into foo (bar, buz) values (NULL, ?)/Baz' );

$record_class->new_with_values( bar => 'Baz', buz => 'Blee' )->insert_record;
ok( $sqldb->last_query, 'insert into foo (bar, buz) values (?, ?)/Baz/Blee' );

$record_class->new_with_values( bar => 'Baz', buz => 'Blee' )->update_record;
ok( $sqldb->last_query, 'update foo set bar = ?, buz = ? where bar = ?/Baz/Blee/Baz' );

$record_class->new_with_values( bar => 'Baz' )->delete_record();
ok( $sqldb->last_query, 'delete from foo where bar = ?/Baz' );

########################################################################

1;
