#!/usr/bin/env perl

use strict;
use warnings;
use autodie qw(:all);

use Data::Dumper;
use Test::Most tests => 19;

BEGIN { use_ok('Class::Simple::Readonly::Cached') }

my $cache  = {};
my $object = Class::Simple->new();
$object->val('test_value');
my $cached_object = Class::Simple::Readonly::Cached->new(
	object => $object,
	cache  => $cache,
);

ok($cached_object, 'new() returns a defined object');
isa_ok($cached_object, 'Class::Simple::Readonly::Cached', 'object is correct class');
isa_ok($cached_object->object(), 'Class::Simple', 'inner object is correct class');

# First call is a cache miss; result is fetched from the inner object.
is($cached_object->val(), 'test_value', 'first call fetches from inner object');
diag(Data::Dumper->new([$cache])->Dump()) if($ENV{'TEST_VERBOSE'});
is($cache->{'Class::Simple::Readonly::Cached::val::'}, 'test_value',
	'value is stored in the cache after the first call');

my $state = $cached_object->state();
ok($state, 'state() returns a defined value');
diag(Data::Dumper->new([$state])->Dump()) if($ENV{'TEST_VERBOSE'});
cmp_deeply($state,
	{ misses => { 'Class::Simple::Readonly::Cached::val::' => 1 }, hits => undef },
	'state: one miss, no hits after the first call');

# Second call should be served from cache.
is($cached_object->val(), 'test_value', 'second call returns cached value');
$state = $cached_object->state();
diag(Data::Dumper->new([$state])->Dump()) if($ENV{'TEST_VERBOSE'});
cmp_deeply($state,
	{ misses => { 'Class::Simple::Readonly::Cached::val::' => 1 },
	  hits   => { 'Class::Simple::Readonly::Cached::val::' => 1 } },
	'state: one miss, one hit after two calls');

is($cached_object->val(), 'test_value', 'third call also returns cached value');
$state = $cached_object->state();
diag(Data::Dumper->new([$state])->Dump()) if($ENV{'TEST_VERBOSE'});
cmp_deeply($state,
	{ misses => { 'Class::Simple::Readonly::Cached::val::' => 1 },
	  hits   => { 'Class::Simple::Readonly::Cached::val::' => 2 } },
	'state: one miss, two hits after three calls');

diag(Data::Dumper->new([$cache])->Dump()) if($ENV{'TEST_VERBOSE'});
cmp_deeply($cache,
	{ 'Class::Simple::Readonly::Cached::val::' => 'test_value' },
	'white-box: cache hash contains exactly the expected entry');

# Mutate the inner object's state; the cache should still return the old value.
$object->val('new_value');
is($cached_object->val(), 'test_value', 'cache shields stale reads after mutation');

# Manually reset the cache entry to force a re-fetch.
$cached_object->{'cache'}{'Class::Simple::Readonly::Cached::val::'} = undef;
is($cached_object->val(), 'new_value', 'fresh value returned after manual cache reset');
cmp_deeply($cache,
	{ 'Class::Simple::Readonly::Cached::val::' => 'new_value' },
	'white-box: cache updated after reset');

# Double-wrap warning
{
	local $SIG{__WARN__} = sub {
		my $warn = shift;
		like($warn, qr/is already cached/, 'double-wrap produces the expected warning');
	};
	Class::Simple::Readonly::Cached->new(object => $object, cache => $cache);
}

# DESTROY should clear cache entries belonging to this instance.
{
	ok(defined($cache->{'Class::Simple::Readonly::Cached::val::'}),
		'cache entry exists before DESTROY');
	$cached_object->DESTROY();
	ok(!defined($cache->{'Class::Simple::Readonly::Cached::val::'}),
		'cache entry removed after DESTROY');
}
