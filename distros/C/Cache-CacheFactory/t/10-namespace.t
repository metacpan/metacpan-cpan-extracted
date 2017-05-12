#!perl -T

use strict;
use warnings;

use Test::More;
use Cache::CacheFactory;
eval "use Cache::MemoryCache";
plan skip_all => "Cache::MemoryCache required for testing namespace policies" if $@;

plan tests => 8;

my ( $cache, $namespace, $key );
my %vals = (
    'test_namespace1 key1' => 'value for test_namespace1 key1',
    'test_namespace1 key2' => 'value for test_namespace1 key2',
    'test_namespace2 key1' => 'value for test_namespace2 key1',
    'test_namespace2 key2' => 'value for test_namespace2 key2',
    );

$namespace = 'test_namespace1';
ok( $cache = Cache::CacheFactory->new(
    namespace => $namespace,
    storage   => 'memory',
    ), "construct namespaced cache" );
is( $cache->get_namespace(), $namespace, "namespace set after constructor" );

$namespace = 'test_namespace1';
$key       = 'key1';
$cache->set(
    key  => $key,
    data => $vals{ "$namespace $key" },
    );

$namespace = 'test_namespace2';
$key       = 'key1';
$cache->set_namespace( $namespace );
is( $cache->get_namespace(), $namespace, "namespace change via set_namespace()" );
is( $cache->get( $key ), undef, "$namespace fetch $key" );

$namespace = 'test_namespace2';
$key       = 'key1';
$cache->set_namespace( $namespace );
$cache->set(
    key  => $key,
    data => $vals{ "$namespace $key" },
    );

$namespace = 'test_namespace2';
$key       = 'key2';
$cache->set_namespace( $namespace );
$cache->set(
    key  => $key,
    data => $vals{ "$namespace $key" },
    );

$namespace = 'test_namespace1';
$key       = 'key1';
$cache->set_namespace( $namespace );
is( $cache->get( $key ), $vals{ "$namespace $key" }, "$namespace fetch $key" );

$namespace = 'test_namespace1';
$key       = 'key2';
$cache->set_namespace( $namespace );
is( $cache->get( $key ), undef, "$namespace fetch $key" );

$namespace = 'test_namespace1';
$key       = 'key2';
$cache->set_namespace( $namespace );
is( $cache->get( $key ), undef, "$namespace fetch $key" );

$namespace = 'test_namespace1';
$key       = 'key2';
$cache->set_namespace( $namespace );
$cache->set(
    key  => $key,
    data => $vals{ "$namespace $key" },
    );

$namespace = 'test_namespace2';
$key       = 'key2';
$cache->set_namespace( $namespace );
is( $cache->get( $key ), $vals{ "$namespace $key" }, "$namespace fetch $key" );

#  Clean-up.
foreach $namespace ( qw/test_namespace1 test_namespace2/ )
{
    foreach $key ( qw/key1 key2/ )
    {
        $cache->remove( $key );
    }
}
