#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most tests => 16;
use Test::NoWarnings;

BEGIN { use_ok('Class::Simple::Cached') }

# ── Basic get/set cycle with a hash-ref cache ─────────────────────────────

my $cache = {};
{
	my $cached_obj = Class::Simple::Cached->new(cache => $cache);

	ok($cached_obj, 'Created Class::Simple::Cached object');

	$cached_obj->val('foo');

	ok($cached_obj->can('val'), "Object can 'val'");

	is($cached_obj->val(), 'foo', 'Value retrieved correctly from the underlying object');

	is($cache->{'Class::Simple::Cached:val'}, 'foo', "Cache entry for 'val' exists and is correct");

	# Change the underlying object directly — the cached value must not change
	$cached_obj->{object}->val('bar');

	is($cached_obj->val(), 'foo', 'Cached value is served even after underlying object changes');

	undef $cached_obj;
}

ok(!exists($cache->{'Class::Simple::Cached:val'}), 'Cache is cleared when object is destroyed');

# ── Methods returning undef are cached via UNDEF_SENTINEL ────────────────

{
	my $cache2 = {};
	my $obj2   = Class::Simple::Cached->new(cache => $cache2);

	# First call: object returns undef; sentinel should be stored
	my $v = $obj2->undef_method();
	ok(!defined($v), 'First undef getter returns undef');

	# Sentinel is stored so subsequent calls do not re-invoke the object
	ok(exists($cache2->{'Class::Simple::Cached:undef_method'}),
		'Sentinel is stored in cache for undef return');

	my $v2 = $obj2->undef_method();
	ok(!defined($v2), 'Second undef getter still returns undef (from cache)');
}

# ── Setter updates both the underlying object and the cache ──────────────

{
	my $cache3 = {};
	my $obj3   = Class::Simple::Cached->new(cache => $cache3);

	$obj3->colour('red');
	is($cache3->{'Class::Simple::Cached:colour'}, 'red', 'Setter stores value in cache');
	is($obj3->colour(), 'red', 'Getter returns setter value');
}

# ── Array-setter undef path uses $key not $param (bug fix) ──────────────
# Previously $cache->{$param} was used (missing class prefix), so a different
# key was stored from the one the getter would look up.

{
	my $cache4 = {};
	my $obj4   = Class::Simple::Cached->new(cache => \%{$cache4});

	# Class::Simple stores an arrayref when passed an arrayref; the wrapper
	# passes \@_ for multi-arg setters.  Force the setter path with two args.
	$obj4->multi('a', 'b');

	# The cache key must include the class prefix
	ok(!exists($cache4->{'multi'}),
		'Array-setter does not write to bare $param key (was the bug)');
}

# ── clone() returns a new instance sharing the same cache ────────────────

{
	my $cache5 = {};
	my $obj5   = Class::Simple::Cached->new(cache => $cache5);
	$obj5->tag('alpha');
	my $clone = $obj5->new();
	isa_ok($clone, 'Class::Simple::Cached', 'Clone is a Class::Simple::Cached');
	is($clone->tag(), 'alpha', 'Clone sees value from shared cache');
}
