use strict;

use Test::More;

plan skip_all => "Undefined MEMCACHED_SERVER env variable -  memcached tests are skipped"
  unless $ENV{MEMCACHED_SERVER};

plan tests => 200;

use Cache::Memcached::Fast;
use Cache::Memcached::Fast::Logger;

my $cache = new Cache::Memcached::Fast( {
    servers => [ $ENV{MEMCACHED_SERVER} ],
    namespace => 'test:'
} );

my $logger = Cache::Memcached::Fast::Logger->new( cache => $cache );

for ( 0 .. 99 ) {
    $logger->log( { counter => $_, string => "test_$_" } );
}

my $counter = 0;

# Test - reading all logs
$logger->read_all( sub { ok( $_[0] && exists $_[0]->{counter} && $_[0]->{counter} == $counter++ ); 1 } );

for ( 0 .. 99 ) {
    $logger->log( { counter => $_, string => "test_$_" } );
}

$counter = 0;

# Tests for partly reading of logs

# read first 50 log items - emulation of terminate in middle phase for example ...
$logger->read_all( sub { $counter < 50 ? scalar( ok( $_[0] && exists $_[0]->{counter} && $_[0]->{counter} == $counter++ ), 1 ) : 0 } );

# read second 50 log items
$logger->read_all( sub { ok( $_[0] && exists $_[0]->{counter} && $_[0]->{counter} == $counter++ ); 1 } );
