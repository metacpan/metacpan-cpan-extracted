#!/usr/bin/perl

use Test;
BEGIN { plan tests => 14 }

use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);
ok( 1 );

########################################################################

my $sqldb = DBIx::SQLEngine->new( 'dbi:NullP:' );
ok( $sqldb and ref($sqldb) =~ m/^DBIx::SQLEngine/ );

my $table = $sqldb->table('foo');
ok( $table and ref($table) eq 'DBIx::SQLEngine::Schema::Table' );

########################################################################

$table->fetch_select( );
ok( $sqldb->last_query, 'select * from foo' );

$table->fetch_select( criteria => { bar => 'Baz' } );
ok( $sqldb->last_query, 'select * from foo where bar = ?/Baz' );

$table->do_insert( values => { bar => 'Baz' } );
ok( $sqldb->last_query, 'insert into foo (bar) values (?)/Baz' );

$table->do_update( values => { bar => 'Baz' } );
ok( $sqldb->last_query, 'update foo set bar = ?/Baz' );

$table->do_delete( );
ok( $sqldb->last_query, 'delete from foo' );

$table->do_delete( criteria => { bar => 'Baz' } );
ok( $sqldb->last_query, 'delete from foo where bar = ?/Baz' );

########################################################################

# The row interface requires information about the columns, which isn't 
# available in our bogus NullP environment, so we'll define them explicitly.

$table->columnset( 
  DBIx::SQLEngine::Schema::ColumnSet->new(  
    DBIx::SQLEngine::Schema::Column->new( type => 'text', name => 'bar' ),
    DBIx::SQLEngine::Schema::Column->new( type => 'text', name => 'buz' ),
  ) 
);

########################################################################

$table->select_row( { bar => 'Baz' } );
ok( $sqldb->last_query, 'select * from foo where bar = ? limit 1/Baz' );

$table->insert_row( { bar => 'Baz' } );
ok( $sqldb->last_query, 'insert into foo (bar) values (?)/Baz' );

$table->insert_row( { bar => 'Baz', buz => 'Blee' } );
ok( $sqldb->last_query, 'insert into foo (bar, buz) values (?, ?)/Baz/Blee' );

$table->update_row( { bar => 'Baz', buz => 'Blee' } );
ok( $sqldb->last_query, 'update foo set bar = ?, buz = ? where bar = ?/Baz/Blee/Baz' );

$table->delete_row( { bar => 'Baz' } );
ok( $sqldb->last_query, 'delete from foo where bar = ?/Baz' );

########################################################################

1;
