#
# $Id$

use strict;

use Test::More tests => 17;

BEGIN { use_ok( 'Cache::Weak' ); }

my $ns = "test";
my ($key, $value) = ("foo", \$ns);

# create and check instance
my $cache = Cache::Weak->new();
isa_ok( $cache, 'Cache::Weak', 'new()' );

# check default namespace
is( $cache->namespace, &Cache::Weak::DEFAULT_NAMESPACE, 'default namespace');

# check custom namespace
ok( $cache->namespace($ns), 'namespace($ns)' );
is( $cache->namespace, $ns, 'namespace() eq $ns' );

# check basic set/get methods
ok( $cache->set($key, $value), 'set($key, $value)' );
is( $cache->get($key), $value, 'get($key) eq $value' );

# check object removing & exists() method
$cache->set($key, $value);
ok( $cache->exists($key), 'exists($key) before remove($key)');
ok( defined $cache->get($key), 'get($key) before remove($key)' );
ok( $cache->remove($key), 'remove($key)' );
ok(!defined $cache->get($key), 'get($key) after remove($key)');
ok(!$cache->exists($key), 'exists($key) after remove($key)');

# check purge
$cache->set($key, $value);
my $initial_size = $cache->count();
{
	my $new_objects = 3;
	my @values = 1..$new_objects;
	for ( my $i = 1; $i <= 3; $i++ ) {
		$cache->set($i, \$values[ $i - 1 ]);
	}
	is( $cache->count(), $initial_size + $new_objects, 'cache size before purge()' );
}
ok( $cache->purge(), 'purge()' );
is( $cache->count(), $initial_size, 'cache size after purge()' );

# check cache clearing
$cache->set($key, $value);
ok( $cache->clear(), 'clear()' );
ok(!$cache->count(), 'cache size after clear()' );

