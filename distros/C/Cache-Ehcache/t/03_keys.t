use strict;
use warnings;
use Test::More;
use IO::Socket::INET;

use Cache::Ehcache;

my $skip = 1;
my $addr = "127.0.0.1:8080";
my $sock =
  IO::Socket::INET->new( PeerAddr => $addr, Proto => 'tcp', Timeout => 3 );
if ($sock) {
    $sock->send("GET /ehcache/rest/foo\n\n");
    my $buf;
    $sock->recv( $buf, 1024 );
    $skip = 0 if ($buf);
}
if ($skip) {
    plan skip_all => "No Ehcache Server running at $addr\n";
    exit 0;
}
else {
    plan tests => 9;
}

my $cache = Cache::Ehcache->new(
    server    => 'http://127.0.0.1:8080/ehcache/rest/',
    namespace => "Cache_Ehcache_Test",
);

isa_ok( $cache, 'Cache::Ehcache' );

ok( $cache->set( "key1", "val1" ), "set key1 as val1" );
ok( $cache->set( "key2", "val2" ), "set key2 as val2" );

is( $cache->get("key1"), "val1", "get key1 is val1" );
is( $cache->get("key2"), "val2", "get key2 is val2" );

ok( $cache->set( "key2", "val-replace" ), "set key2 as val-replace" );
is( $cache->get("key2"), "val-replace", "get key2 is val-replace" );

$cache->delete("key1");
ok( !$cache->get("key1"), "get key1 properly failed" );

$cache->clear;
ok( !$cache->get("key2"), "get key2 properly failed" );
