#!perl

use strict;
use lib 't/lib';

use MyAdapter;
use MyCache;
use MyLog;

use Test::More tests => 8;

my $credentials  = {
    user => 'password'
};

my $adapter = MyAdapter->new(
    credentials => $credentials,
    cache       => MyCache->new,
    log         => MyLog->new
);

ok( $adapter );
ok( $adapter->authenticate( 'user', 'password' ) );
ok( !$adapter->authenticate( 'john', 'password' ) );

like( $adapter->log->messages->[-2], qr/Caching successful authentication status '1' for user 'user'/ );

is_deeply( scalar $adapter->cache->hash, { 'user:password' => 1 } );

$adapter->credentials( {} );

ok( $adapter->authenticate( 'user', 'password' ) );

like( $adapter->log->messages->[-1], qr/Successfully authenticated user 'user' from cache/ );

$adapter->cache->clear;

ok( !$adapter->authenticate( 'user', 'password' ) );
