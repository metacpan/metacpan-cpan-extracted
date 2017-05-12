#!perl -T

use strict;
use warnings;

use Test::More;
use Cache::CacheFactory;
eval "use Cache::MemoryCache";
plan skip_all => "Cache::MemoryCache required for testing expiry policies" if $@;

plan tests => 9;

my ( $cache, $key, $set_time, $set_attempts, $max_attempts, $val );
my %vals = (
    'valid-2 prune-10' => 'value for valid-2 prune-10 key',
    'valid-10 prune-2' => 'value for valid-10 prune-2 key',
    );
$max_attempts = 3;

ok( $cache = Cache::CacheFactory->new(
    storage  => 'memory',
    pruning  => 'time',
    validity => 'time',
    ), "construct cache" );

$set_attempts = 0;
while( ++$set_attempts <= $max_attempts )
{
    $set_time = time();
    $key = 'valid-2 prune-10';
    $cache->set(
        key         => $key,
        data        => $vals{ $key },
        valid_until => '2 seconds',
        prune_after => '10 seconds',
        );
    $key = 'valid-10 prune-2';
    $cache->set(
        key         => $key,
        data        => $vals{ $key },
        valid_until => '10 seconds',
        prune_after => '2 seconds',
        );
    last if time() < $set_time + 2;
    diag( "Setup of cache values took more than 2 seconds, " .
        ( ( $set_attempts == $max_attempts ) ?
        "we'll just have to skip those tests." :
        "let's try setting them again." ) );
}

SKIP:
{
    skip "Cache set was too far in the past, test would be stale now." => 4
        if time() >= $set_time + 2;

    $key = 'valid-2 prune-10';
    is( $val = $cache->get( $key ), $vals{ $key }, "immediate $key fetch" );
    diag( "$key set time $set_time, read time " . time() )
        if $val ne $vals{ $key };

    skip "Cache set was too far in the past, test would be stale now." => 3
        if time() >= $set_time + 2;

    $key = 'valid-10 prune-2';
    is( $val = $cache->get( $key ), $vals{ $key }, "immediate $key fetch" );
    diag( "$key set time $set_time, read time " . time() )
        if $val ne $vals{ $key };

    $cache->purge();

    skip "Cache set was too far in the past, test would be stale now." => 2
        if time() >= $set_time + 2;

    $key = 'valid-2 prune-10';
    is( $val = $cache->get( $key ), $vals{ $key },
        "post-purge immediate $key fetch" );
    diag( "$key set time $set_time, read time " . time() )
        if $val ne $vals{ $key };

    skip "Cache set was too far in the past, test would be stale now." => 1
        if time() >= $set_time + 2;

    $key = 'valid-10 prune-2';
    is( $val = $cache->get( $key ), $vals{ $key },
        "post-purge immediate $key fetch" );
    diag( "$key set time $set_time, read time " . time() )
        if $val ne $vals{ $key };
}

sleep( 3 ) if time() < $set_time + 3;

$key = 'valid-2 prune-10';
is( $cache->get( $key ), undef, "delayed $key fetch" );

$key = 'valid-10 prune-2';
is( $cache->get( $key ), $vals{ $key }, "delayed $key fetch" );

$cache->purge();

$key = 'valid-2 prune-10';
is( $cache->get( $key ), undef, "post-purge delayed $key fetch" );

$key = 'valid-10 prune-2';
is( $cache->get( $key ), undef, "post-purge delayed $key fetch" );

#  Clean-up.
foreach $key ( keys( %vals ) )
{
    $cache->remove( $key );
}
