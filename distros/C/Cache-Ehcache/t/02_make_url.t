use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('Cache::Ehcache'); }

my $cache = Cache::Ehcache->new( namespace => 'foo', );
is( $cache->_make_url,        'http://localhost:8080/ehcache/rest/foo' );
is( $cache->_make_url("bar"), 'http://localhost:8080/ehcache/rest/foo/bar' );
