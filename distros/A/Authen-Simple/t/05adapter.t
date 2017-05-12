#!perl

use strict;
use lib 't/lib';

use MyAdapter;
use MyCache;
use MyLog;

use Test::More tests => 5;

my $credentials  = {
    user => 'password'
};

my $adapter = MyAdapter->new(
    credentials => $credentials,
    log         => MyLog->new
);

ok( $adapter );
ok( $adapter->authenticate( 'user', 'password' ) );
ok( !$adapter->authenticate( 'john', 'password' ) );
like( $adapter->log->messages->[0], qr/Successfully authenticated user 'user'/ );
like( $adapter->log->messages->[1], qr/Failed to authenticate user 'john'/ );
