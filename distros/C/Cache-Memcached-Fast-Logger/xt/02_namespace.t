use strict;

use Test::More;

plan skip_all => "Undefined MEMCACHED_SERVER env variable -  memcached tests are skipped"
  unless $ENV{MEMCACHED_SERVER};

plan tests => 152;

use Cache::Memcached::Fast;
use Cache::Memcached::Fast::Logger;

my $cache = new Cache::Memcached::Fast( {
    servers => [ $ENV{MEMCACHED_SERVER} ],
    namespace => 'test:'
} );

my $logger1 = Cache::Memcached::Fast::Logger->new( cache => $cache, namespace => 'log1:' );
my $logger2 = Cache::Memcached::Fast::Logger->new( cache => $cache, namespace => 'log2:' );

for ( 0 .. 99 ) {
    $logger1->log( { counter => $_, string => "test_$_" } );
}

for ( 0 .. 49 ) {
    $logger2->log( { counter => $_, string => "test_$_" } );
}

my $counter1 = 0;
my $counter2 = 0;

$logger1->read_all( sub { ok( $_[0] && exists $_[0]->{counter} && $_[0]->{counter} == $counter1++ ); 1 } );
ok( $counter1 == 100 );

$logger2->read_all( sub { ok( $_[0] && exists $_[0]->{counter} && $_[0]->{counter} == $counter2++ ); 1 } );
ok( $counter2 == 50 );
