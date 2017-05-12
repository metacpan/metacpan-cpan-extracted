#!perl

use strict;
use lib 't/lib';

use MyAdapter;
use MyCache;
use MyLog;

use Test::More tests => 7;

my $credentials  = {
    user => 'password'
};

my $adapter = MyAdapter->new(
    credentials => $credentials,
    log         => MyLog->new
);

ok( $adapter );

$adapter->callback( sub { undef } );

ok( $adapter->authenticate( 'user', 'password' ) );
like( $adapter->log->messages->[-1], qr/Successfully authenticated user 'user'/ );

$adapter->callback( sub { 1 } );

ok( $adapter->authenticate( 'user', 'password' ) );
like( $adapter->log->messages->[-1], qr/Callback returned a true value/ );

$adapter->callback( sub { 0 } );

ok( !$adapter->authenticate( 'user', 'password' ) );
like( $adapter->log->messages->[-1], qr/Callback returned a false value/ );
