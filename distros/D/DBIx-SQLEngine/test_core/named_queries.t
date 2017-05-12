#!/usr/bin/perl

use Test;
BEGIN { plan tests => 14 }

use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);
ok( 1 );

########################################################################

my $sqldb = DBIx::SQLEngine->new( 'dbi:NullP:' );
ok( $sqldb and ref($sqldb) =~ m/^DBIx::SQLEngine/ );

########################################################################

$sqldb->define_named_query( 'select_foo', 'select * from foo' );
$sqldb->fetch_select( named_query => 'select_foo' );
ok( $sqldb->last_query, 'select * from foo' );

$sqldb->fetch_named_query( 'select_foo' );
ok( $sqldb->last_query, 'select * from foo' );

########################################################################

$sqldb->define_named_query( 'insert_foo', [ 'insert into foo (bar) values (?)', \$1 ] );
$sqldb->do_insert( named_query => [ 'insert_foo', 'Baz' ] );
ok( $sqldb->last_query, 'insert into foo (bar) values (?)/Baz' );

$sqldb->do_named_query( 'insert_foo', 'Baz' );
ok( $sqldb->last_query, 'insert into foo (bar) values (?)/Baz' );

########################################################################

$sqldb->define_named_query( 'update_foo', { action => 'update', table => 'foo', values => { bar => \$1 } } );
$sqldb->do_update( named_query => [ 'update_foo', 'Baz' ] );
ok( $sqldb->last_query, 'update foo set bar = ?/Baz' );

$sqldb->do_named_query( 'update_foo', 'Baz' );
ok( $sqldb->last_query, 'update foo set bar = ?/Baz' );

########################################################################

$sqldb->define_named_query( 'delete_foo', sub { 'delete from foo' } );
$sqldb->do_delete( named_query => 'delete_foo' );
ok( $sqldb->last_query, 'delete from foo' );

$sqldb->do_named_query( 'delete_foo' );
ok( $sqldb->last_query, 'delete from foo' );

########################################################################

my $queries = <<'/';
select_bar: select * from bar
insert_bar: [ 'insert into bar (foo) values (?)', \$1 ]
update_bar: { action => 'update', table => 'bar', values => { foo => \$1 } }
delete_bar: "delete " . "from" . " bar"
/

my %queries = map { split /\:\s*/, $_, 2 } split "\n", $queries;
$sqldb->define_named_queries_from_text( %queries );

$sqldb->fetch_select( named_query => 'select_bar' );
ok( $sqldb->last_query, 'select * from bar' );

$sqldb->do_insert( named_query => [ 'insert_bar', 'Baz' ] );
ok( $sqldb->last_query, 'insert into bar (foo) values (?)/Baz' );

$sqldb->do_update( named_query => [ 'update_bar', 'Baz' ] );
ok( $sqldb->last_query, 'update bar set foo = ?/Baz' );

$sqldb->do_delete( named_query => 'delete_bar' );
ok( $sqldb->last_query, 'delete from bar' );

########################################################################

1;
