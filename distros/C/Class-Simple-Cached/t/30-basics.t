#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most tests => 7;

BEGIN { use_ok('Class::Simple::Cached') }

# Create a new caching object using a hash ref as the cache.
my $cache = {};
{
	my $cached_obj = Class::Simple::Cached->new(cache => $cache);

	ok($cached_obj, 'Created Class::Simple::Cached object');

	# Set a value using the 'val' method.
	# Class::Simple is assumed to work with a get/set style interface.
	$cached_obj->val('foo');

	# Test that the underlying object exists and responds to 'val'
	ok($cached_obj->can('val'), "Object can 'val'");

	# Retrieve the value; the first retrieval should call the underlying object
	is($cached_obj->val(), 'foo', 'Value retrieved correctly from the underlying object');

	# Since the call above was cached, the cache should now contain the value.
	is($cache->{'Class::Simple::Cached:val'}, 'foo', "Cache entry for 'val' exists and is correct" );

	# Now, change the underlying object's value directly.
	#column (This is just to show that the cache does not update automatically.)
	$cached_obj->{object}->val('bar');

	# But because of caching, the retrieved value is still the cached one:
	is($cached_obj->val(), 'foo', 'Cached value remains unchanged even though underlying object changed');

	# Clear the cache by destroying the object
	undef $cached_obj;
}

ok(!exists($cache->{'Class::Simple::Cached:val'}), 'Cache has been cleared');
