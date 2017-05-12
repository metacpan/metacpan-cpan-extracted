#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use Test::Deep qw/blessed/;
use t::Test;

my ( $store, $store_file, $model, $result );
$store_file = t::Test->tmp_sqlite;
#$store_file = t::Test->test_sqlite( remove => 1 );

$store = DBIx::NoSQL->connect( $store_file );
ok( $store );

ok( ! $store->exists( 'Artist' => 'Smashing Pumpkins' ) );

$store->set( 'Artist' => 'Smashing Pumpkins' => {
    name => 'Smashing Pumpkins',
    genre => 'rock',
    website => 'smashingpumpkins.com',
} );

ok( $store->exists( 'Artist' => 'Smashing Pumpkins' ) );

$store->set( 'Artist' => 'Tool' => {
    name => 'Tool',
    genre => 'rock',
} );

is( $store->search( 'Artist' )->count, 2 );

my $artist = $store->get( 'Artist' => 'Smashing Pumpkins' );
cmp_deeply( $artist, {
    name => 'Smashing Pumpkins',
    genre => 'rock',
    website => 'smashingpumpkins.com',
} );

$store->model( 'Artist' )->index( 'name' );
$store->model( 'Artist' )->reindex;

cmp_deeply( [ $store->search( 'Artist' )->order_by( 'name DESC' )->all ], [
    {
        name => 'Tool',
        genre => 'rock',
    },
    {
        name => 'Smashing Pumpkins',
        genre => 'rock',
        website => 'smashingpumpkins.com',
    },
] );

SKIP: {
    skip "DateTime required for this test", 1 unless eval { require DateTime };
    
    $store->model( 'Album' )->index( 'released' => ( isa => 'DateTime' ) );

    $store->set( 'Album' => 'Siamese Dream' => {
        artist => 'Smashing Pumpkins',
        released => DateTime->new( year => 1993, month => 1, day => 1, hour => 0, minute => 0, second => 0 ),
    } );

    my $album = $store->get( 'Album' => 'Siamese Dream' );
    my $released = $album->{ released };

    is ref($released ) => 'DateTime';
    is( $released->year, 1993 );
    is( $released->day, 1 );
}

done_testing;
