#!perl -T

use strict;
use warnings;

use strict;
use Test::More;
use Cache::CacheFactory;
eval "use Cache::MemoryCache";
plan skip_all => "Cache::MemoryCache required for testing deep-cloning options" if $@;

plan tests => 22;

my ( $cache, $key, $newval, $oldval );
my %vals = (
    'deep ref key1'        => [ 'value for deep ref key1' ],
    'deep ref key2'        => [ 'value for deep ref key2' ],
    'shared deep ref key1' => [ 'value for shared deep ref' ],
    'shared deep ref key2' => 'placeholder - replaced below',
    'changed value 1'      => 'this is a changed value 1',
    'changed value 2'      => 'this is a changed value 2',
    );
$vals{ 'shared deep ref key2' } = $vals{ 'shared deep ref key1' };


#
#
#  First we test the default behaviour.
#

ok( $cache = Cache::CacheFactory->new(
    storage   => 'memory',
    ), "construct default cache" );

#
#  Independent key tests first.

$key     = 'deep ref key1';
$cache->set(
    key  => $key,
    data => $vals{ $key },
    );

$key       = 'deep ref key1';
is_deeply( $cache->get( $key ), $vals{ $key }, "default immediate fetch $key" );

$key     = 'deep ref key2';
$cache->set(
    key  => $key,
    data => $vals{ $key },
    );

$key     = 'deep ref key2';
is_deeply( $cache->get( $key ), $vals{ $key }, "default immediate fetch $key" );

$key     = 'deep ref key1';
$oldval  = $vals{ $key }->[ 0 ];
$newval  = $vals{ 'changed value 1' };
$vals{ $key }->[ 0 ] = $newval;
is_deeply( $cache->get( $key ), [ $oldval ], "default post-change fetch $key" );

$key     = 'deep ref key2';
is_deeply( $cache->get( $key ), $vals{ $key }, "default post-change fetch $key" );

$key     = 'deep ref key1';
$vals{ $key }->[ 0 ] = $oldval;
undef $oldval;

#
#  Shared key tests second.

$key     = 'shared deep ref key1';
$cache->set(
    key  => $key,
    data => $vals{ $key },
    );

$key       = 'shared deep ref key1';
is_deeply( $cache->get( $key ), $vals{ $key }, "default immediate fetch $key" );

$key     = 'shared deep ref key2';
$cache->set(
    key  => $key,
    data => $vals{ $key },
    );

$key     = 'shared deep ref key2';
is_deeply( $cache->get( $key ), $vals{ $key }, "default immediate fetch $key" );

is_deeply( $cache->get( 'shared deep ref key1' ), $cache->get( 'shared deep ref key2' ), "default immediate shared key comparison" );

$key     = 'shared deep ref key1';
$oldval  = $vals{ $key }->[ 0 ];
$newval  = $vals{ 'changed value 2' };
$vals{ $key }->[ 0 ] = $newval;
is_deeply( $cache->get( $key ), [ $oldval ], "default post-change fetch $key" );

$key     = 'shared deep ref key2';
is_deeply( $cache->get( $key ), [ $oldval ], "default post-change fetch $key" );

is_deeply( $cache->get( 'shared deep ref key1' ), $cache->get( 'shared deep ref key2' ), "default post-change shared key comparison" );

$key     = 'shared deep ref key1';
$vals{ $key }->[ 0 ] = $oldval;
undef $oldval;



#
#
#  Now for the no_deep_clone test.
#

ok( $cache = Cache::CacheFactory->new(
    storage       => 'memory',
    no_deep_clone => 1,
    ), "construct no_deep_clone cache" );

#
#  Independent key tests first.

$key     = 'deep ref key1';
$cache->set(
    key  => $key,
    data => $vals{ $key },
    );

$key       = 'deep ref key1';
is_deeply( $cache->get( $key ), $vals{ $key }, "no_deep_clone immediate fetch $key" );

$key     = 'deep ref key2';
$cache->set(
    key  => $key,
    data => $vals{ $key },
    );

$key     = 'deep ref key2';
is_deeply( $cache->get( $key ), $vals{ $key }, "no_deep_clone immediate fetch $key" );

$key     = 'deep ref key1';
$oldval  = $vals{ $key }->[ 0 ];
$newval  = $vals{ 'changed value 1' };
$vals{ $key }->[ 0 ] = $newval;
is_deeply( $cache->get( $key ), $vals{ $key }, "no_deep_clone post-change fetch $key" );

$key     = 'deep ref key2';
is_deeply( $cache->get( $key ), $vals{ $key }, "no_deep_clone post-change fetch $key" );

$key     = 'deep ref key1';
$vals{ $key }->[ 0 ] = $oldval;
undef $oldval;

#
#  Shared key tests second.

$key     = 'shared deep ref key1';
$cache->set(
    key  => $key,
    data => $vals{ $key },
    );

$key       = 'shared deep ref key1';
is_deeply( $cache->get( $key ), $vals{ $key }, "no_deep_clone immediate fetch $key" );

$key     = 'shared deep ref key2';
$cache->set(
    key  => $key,
    data => $vals{ $key },
    );

$key     = 'shared deep ref key2';
is_deeply( $cache->get( $key ), $vals{ $key }, "no_deep_clone immediate fetch $key" );

is_deeply( $cache->get( 'shared deep ref key1' ), $cache->get( 'shared deep ref key2' ), "no_deep_clone immediate shared key comparison" );

$key     = 'shared deep ref key1';
$oldval  = $vals{ $key }->[ 0 ];
$newval  = $vals{ 'changed value 2' };
$vals{ $key }->[ 0 ] = $newval;
is_deeply( $cache->get( $key ), $vals{ $key }, "no_deep_clone post-change fetch $key" );

$key     = 'shared deep ref key2';
is_deeply( $cache->get( $key ), $vals{ $key }, "no_deep_clone post-change fetch $key" );

is_deeply( $cache->get( 'shared deep ref key1' ), $cache->get( 'shared deep ref key2' ), "no_deep_clone post-change shared key comparison" );

$key     = 'shared deep ref key1';
$vals{ $key }->[ 0 ] = $oldval;
undef $oldval;
