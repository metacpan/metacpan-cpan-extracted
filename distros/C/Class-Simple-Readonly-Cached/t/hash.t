#!perl -w

use strict;
use warnings;
use autodie qw(:all);

use Class::Simple;
use Test::Most tests => 51;
use Test::NoWarnings;

BEGIN {
	use_ok('Class::Simple::Readonly::Cached');
}

HASH: {
	my $cache  = {};
	my $cached = new_ok('Class::Simple::Readonly::Cached' =>
		[ cache => $cache, object => x->new() ]);

	ok($cached->can('object'),  'can() finds "object"');
	ok($cached->can('barney'),  'can() finds delegated "barney"');
	ok($cached->can('abc'),     'can() finds delegated "abc"');
	ok(!$cached->can('xyz'),    'can() correctly returns false for unknown method');
	ok($cached->isa('Class::Simple::Readonly::Cached'), 'isa() self check');

	ok($cached->barney('betty') eq 'betty', 'barney with arg');
	ok($cached->barney()        eq 'betty', 'barney cached first call');
	ok($cached->barney()        eq 'betty', 'barney cached second call');

	my @abc = $cached->abc();
	is(scalar(@abc), 3, 'abc returns 3 elements');
	is($abc[0], 'a', 'abc[0]');
	is($abc[1], 'b', 'abc[1]');
	is($abc[2], 'c', 'abc[2]');

	@abc = $cached->abc();
	is(scalar(@abc), 3, 'abc still returns 3 elements on second call (cached)');
	is($abc[0], 'a', 'abc[0] cached');
	is($abc[1], 'b', 'abc[1] cached');
	is($abc[2], 'c', 'abc[2] cached');

	my $uncached = x->new();

	# Scalar context on a method that returns a list: should return last element.
	my $abc  = $cached->abc();
	my $abc2 = $uncached->abc();
	cmp_ok($abc, 'eq', $abc2, 'scalar context on list method matches uncached result');

	# Array context on a method previously called in scalar context.
	my $def  = $cached->def();
	is($def, 'f', 'def in scalar context returns last element');
	my $def2 = $uncached->def();
	is($def, $def2, 'def scalar matches uncached');
	my @def = $cached->def();
	is(scalar(@def), 3, 'def in list context after scalar context returns full list');

	my @a = $cached->a();
	is(scalar(@a), 1, 'a returns 1 element');
	is($a[0], 'a', 'a[0]');
	@a = $cached->a();
	is(scalar(@a), 1, 'a cached: still 1 element');
	is($a[0], 'a', 'a[0] cached');

	ok($cached->echo('foo') eq 'foo', 'echo foo');
	ok($cached->echo('foo') eq 'foo', 'echo foo cached');
	ok($cached->echo('bar') eq 'bar', 'echo bar');
	ok($cached->echo('bar') eq 'bar', 'echo bar cached');
	ok($cached->echo('foo') eq 'foo', 'echo foo again (cross-arg cache isolation)');

	my @empty = $cached->empty();
	is(scalar(@empty), 0, 'empty method returns empty list');
	ok(!defined($cached->empty()),  'empty method returns undef in scalar context');
	ok(!defined($cached->empty()),  'empty method returns undef on second call');

	# White-box: verify exact cache key format and stored values.
	is($cache->{'Class::Simple::Readonly::Cached::barney::'},      'betty', 'cache key: barney no-arg');
	is($cache->{'Class::Simple::Readonly::Cached::barney::betty'}, 'betty', 'cache key: barney with arg');
	is($cache->{'Class::Simple::Readonly::Cached::echo::foo'},     'foo',   'cache key: echo foo');
	is($cache->{'Class::Simple::Readonly::Cached::echo::bar'},     'bar',   'cache key: echo bar');
	is(ref($cache->{'Class::Simple::Readonly::Cached::a::'}),   'ARRAY', 'list result stored as arrayref');
	is(ref($cache->{'Class::Simple::Readonly::Cached::abc::'}), 'ARRAY', 'abc result stored as arrayref');

	is(ref($cached->object()), 'x', 'object() returns the inner object');

	my $hits = $cached->state()->{hits};
	my $hit_count = 0;
	$hit_count += $_ for values %{$hits // {}};
	is($hit_count, 9, 'total cache hits');

	my $misses = $cached->state()->{misses};
	my $miss_count = 0;
	$miss_count += $_ for values %{$misses // {}};
	is($miss_count, 9, 'total cache misses');

	# Caching objects that return objects: the inner object's method should
	# be callable on the returned (uncached) object reference.
	my $simple = new_ok('Class::Simple');
	my $one    = new_ok('Class::Simple');
	$one->one('1');
	$simple->one($one);
	my $two = new_ok('Class::Simple');
	$two->two('2');
	$two->two($two);

	$cached = new_ok('Class::Simple::Readonly::Cached' =>
		[ cache => $cache, object => $simple ]);
	cmp_ok($one->one(),            '==', 1, 'inner object method works directly');
	cmp_ok($cached->one()->one(),  '==', 1, 'cached->one()->one() first call');
	cmp_ok($cached->one()->one(),  '==', 1, 'cached->one()->one() second call (cache hit)');
}

package x;

sub new {
	my $proto = shift;
	return bless {}, ref($proto) || $proto;
}

sub barney {
	return 'betty';
}

sub abc {
	return ('a', 'b', 'c');
}

sub def {
	return ('d', 'e', 'f');
}

sub a {
	return 'a';
}

sub empty {
}

sub echo {
	my $self = shift;
	return wantarray ? @_ : $_[0];
}

1;
