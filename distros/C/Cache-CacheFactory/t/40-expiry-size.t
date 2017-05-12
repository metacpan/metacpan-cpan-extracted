#!perl -T

use strict;
use warnings;

use Test::More;
use Cache::CacheFactory;
eval "use Cache::MemoryCache";
plan skip_all => "Cache::MemoryCache required for testing expiry policies" if $@;

plan tests => 5;

my ( $cache, $key );
my %vals = (
    '1k' => join( "\n", ( '1' x 49 ) x 20 ),
    '3k' => join( "\n", ( '3' x 49 ) x 60 ),
    );

ok( $cache = Cache::CacheFactory->new(
    storage   => 'memory',
    pruning   => { 'size' => { max_size => 2200, } },
    ), "construct cache" );

$key = '1k';
$cache->set(
    key          => $key,
    data         => $vals{ $key },
    );
is( $cache->get( $key ), $vals{ $key }, "immediate $key fetch" );
$cache->purge();
is( $cache->get( $key ), $vals{ $key }, "post-purge $key fetch" );

$cache->clear();

$key = '3k';
$cache->set(
    key          => $key,
    data         => $vals{ $key },
    );
is( $cache->get( $key ), $vals{ $key }, "immediate $key fetch" );
$cache->purge();
is( $cache->get( $key ), undef, "post-purge $key fetch" );

$cache->clear();
