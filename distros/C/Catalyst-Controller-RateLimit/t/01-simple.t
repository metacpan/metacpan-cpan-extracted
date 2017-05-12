#! perl
use warnings;
use strict;

use Catalyst::Controller::RateLimit::Queue;
use Cache::Memcached::Fast;
use Test::More;
if ( ! $ENV{  MEMCACHED_SERVER } ) {
    plan skip_all => '$ENV{MEMCACHED_SERVER} is not set';
}
plan tests => 5;

my $c = Catalyst::Controller::RateLimit::Queue->new(
    cache => new Cache::Memcached::Fast( {
        servers => [
            $ENV{MEMCACHED_SERVER}
        ]
    }
    ),
    expires => 5,
    prefix => 'test_queue'
);
my $oldsize = $c->size;
$c->append( 1 );
is( $c->size, $oldsize + 1, 'append/size' );
$c->append( 1 );
is( $c->size, $oldsize + 2, 'yet another' );
sleep 3;
$c->append( 1 );
sleep 3;
is( $c->size, 1, 'expiring' );
ok( $c->clear, 'clearing' );
foreach ( 1 .. 15 ) {
    if ( ! fork  ) {

        my $sub_cache = Catalyst::Controller::RateLimit::Queue->new(
            cache => new Cache::Memcached::Fast( {
                servers => [
                    'zoo.rambler.ru:10010'
                ]
            }
            ),
            expires => 60,
            prefix => 'test_queue'
        );
        foreach ( 1 .. 100 ) {
            $sub_cache->append( 'data' );
        };
        exit;
    }
}
1 while (waitpid -1, 0) != -1;
is( $c->size, 1500, 'concurrency');
