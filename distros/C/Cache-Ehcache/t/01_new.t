use strict;
use Test::More tests => 2;

BEGIN { use_ok 'Cache::Ehcache' }

my $cache = Cache::Ehcache->new(
    server    => 'http://hogehoge:9090/ehcache/rest',
    namespace => 'hogehoge',
);
is( $cache->server, 'http://hogehoge:9090/ehcache/rest/' );
