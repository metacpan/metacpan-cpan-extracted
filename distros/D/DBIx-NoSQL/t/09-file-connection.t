#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use t::Test;

my ( $store, $store_file );
$store_file = t::Test->tmp_sqlite;

ok( DBIx::NoSQL::Store->_is_likely_file_connection( $store_file ) );
ok( DBIx::NoSQL::Store->_is_likely_file_connection( "$store_file" ) );
ok( DBIx::NoSQL::Store->_is_likely_file_connection( "test" ) );
ok( DBIx::NoSQL::Store->_is_likely_file_connection( "test" ) );
ok( ! DBIx::NoSQL::Store->_is_likely_file_connection( "dbi:*" ) );
ok( ! DBIx::NoSQL::Store->_is_likely_file_connection( [] ) );

{
    $store = DBIx::NoSQL->connect( "$store_file" );
    ok( $store );

    $store->model( 'Artist' )->set( 1 => { Xyzzy => 1 } );
    ok( $store->exists( 'Artist' => 1 ) );
}

done_testing;
