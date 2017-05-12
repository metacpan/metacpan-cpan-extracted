#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use t::Test;

my ( $store, $store_file, $model, $result );
$store_file = t::Test->tmp_sqlite;

{
    $store = DBIx::NoSQL->connect( $store_file );
    $store->set( Song => 1 => { key => 1, artist => 1 } );
}

{
    $store = DBIx::NoSQL->connect( $store_file );
    lives_ok { $store->model( 'Song' )->index( $_ ) for qw/ artist album title name loved station / };
    is( $store->search( Song => { artist => 1 } )->all, 1 );
}

done_testing;
