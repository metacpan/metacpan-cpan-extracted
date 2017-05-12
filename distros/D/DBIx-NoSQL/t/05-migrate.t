#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use t::Test;

my ( $store, $store_file, $model );
$store_file = t::Test->tmp_sqlite;
#$store_file = t::Test->test_sqlite( remove => 1 );
$store = DBIx::NoSQL->new( database => $store_file );

ok( $store );

$model = $store->model( 'Artist' );
$model->field( Xyzzy => ( index => 1 ) );

$store->model( 'Artist' )->set( 1 => { Xyzzy => 1, rank => 'rank2' } );
$store->model( 'Artist' )->set( 2 => { Xyzzy => 2, rank => 'rank1' } );
$store->model( 'Artist' )->set( 3 => { Xyzzy => 3 } );

$model->field( rank => ( index => 1 ) );

$store->reindex;

cmp_deeply( [ $store->search( 'Artist' )->order_by( 'rank' )->fetch ], [
    { Xyzzy => 3 },
    { Xyzzy => 2, rank => 'rank1' },
    { Xyzzy => 1, rank => 'rank2' },
] );

done_testing;
