#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use t::Test;

my ( $store, $store_file, $model );
$store_file = t::Test->tmp_sqlite;
#$store_file = t::Test->test_sqlite( remove => 1 );

$store = DBIx::NoSQL->new();
ok( $store );

$store->connect( $store_file );
ok( $store->dbh );

dies_ok {
    $store->storage->do( 'Xyzzy' )
} 'bad syntax';

$model = $store->model( 'Album' );
$model->field( name => ( index => 1 ) );
$model->field( date => ( index => 1 ) );

$store->model( 'Artist' )->set( 1 => { Xyzzy => 1 } );
$store->model( 'Artist' )->set( 2 => { Xyzzy => 2 } );
$store->model( 'Artist' )->set( 3 => { Xyzzy => 3 } );

my $randid = $store->model( 'Artist' )->set( { moo => 'cow' });
is length($randid),36, 'Randomish id set';

ok( $store->exists( 'Artist' => 1 ) );
ok( $store->exists( 'Artist' => 2 ) );
ok( $store->exists( 'Artist' => 3 ) );
ok( ! $store->exists( 'Artist' => 4 ) );
ok( ! $store->exists( 'Artist' => 42 ) );

is( $store->search( 'Artist', { key => 1 } )->count, 1 );
is( $store->search( 'Artist' )->count, 4 );
is( $store->search( 'Artist', { key => { -in => [qw/ 1 3 /] } } )->count, 2 );
cmp_deeply( [ $store->search( 'Artist', { key => 1 } )->fetch ], [
    { Xyzzy => 1 },
] );

cmp_deeply( $store->model( 'Artist' )->get( 1 ), { Xyzzy => 1 } );

$store->model( 'Album' )->set( 3 => { name => 'Xyzzy', date => '20010101' } );
$store->model( 'Album' )->set( 4 => { name => 'Xyzz_' } );

cmp_deeply( [ $store->search( 'Album', { name => 'Xyzzy' } )->fetch ], [
    { name => 'Xyzzy', date => re(qr/^\d+$/), },
] );
is( $store->search( 'Album', { name => { -like => 'Xyz%' } } )->count, 2 );

like( ( $store->search( 'Artist' )->order_by( 'key DESC' )->prepare )[0],
    qr/^SELECT __Store__\.__value__ FROM Artist me  ?JOIN __Store__ __Store__ ON \( __Store__.__key__ = me.key AND __Store__.__model__ = 'Artist' \) ORDER BY key DESC$/ );

like( ( $store->search( 'Artist' )->order_by([ 'key DESC', 'name' ])->prepare )[0],
    qr/^SELECT __Store__\.__value__ FROM Artist me  ?JOIN __Store__ __Store__ ON \( __Store__.__key__ = me.key AND __Store__.__model__ = 'Artist' \) ORDER BY key DESC, name$/ );

$store->delete( 'Artist' => 3 );
is( $store->get( 'Artist' => 3 ), undef );
is( $store->search( 'Artist', { key => { -in => [qw/ 1 3 /] } } )->count, 1 );

done_testing;
