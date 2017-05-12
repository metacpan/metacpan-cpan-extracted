#!/usr/bin/env perl
use strict;
use warnings;
use Test::Most;
use t::Test;

my ( $store, $store_file, $model );
$store_file = t::Test->tmp_sqlite;
#$store_file = t::Test->test_sqlite( remove => 1 );

$store = DBIx::NoSQL->new( database => $store_file );

ok( $store->stash );

$store->stash->value( 'Xyzzy', 1 );
is( $store->stash->value( 'Xyzzy' ), 1 );

done_testing;
