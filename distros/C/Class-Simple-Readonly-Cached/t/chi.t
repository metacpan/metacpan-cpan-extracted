#!perl -w

use strict;
use warnings;
use autodie qw(:all);

use Test::Most tests => 42;
use Test::NoWarnings;
use CHI;

BEGIN {
	use_ok('Class::Simple::Readonly::Cached');
}

CHI: {
	my $cache = CHI->new(driver => 'RawMemory', global => 1);
	$cache->on_set_error('die');
	$cache->on_get_error('die');
	my $l = new_ok('Class::Simple::Readonly::Cached' =>
		[ cache => $cache, object => t::x->new() ]);

	cmp_ok($l->isa('t::x'),                        '==', 1, 'isa finds embedded object');
	cmp_ok($l->isa('Class::Simple::Readonly::Cached'), '==', 1, 'isa finds wrapper class');
	cmp_ok($l->isa('UNIVERSAL'),                    '==', 1, 'isa inheritance chain');
	cmp_ok($l->isa('CHI'),                          '==', 0, 'isa returns false for unrelated class');

	ok($l->barney('betty') eq 'betty', 'barney with arg');
	ok($l->barney()        eq 'betty', 'barney cached first call');
	ok($l->barney()        eq 'betty', 'barney cached second call');

	my @abc = $l->abc();
	is(scalar(@abc), 3, 'abc returns 3 elements');
	is($abc[0], 'a', 'abc[0]');
	is($abc[1], 'b', 'abc[1]');
	is($abc[2], 'c', 'abc[2]');

	@abc = $l->abc();
	is(scalar(@abc), 3, 'abc returns 3 elements on cached call');
	is($abc[0], 'a', 'abc[0] cached');
	is($abc[1], 'b', 'abc[1] cached');
	is($abc[2], 'c', 'abc[2] cached');

	my @a = $l->a();
	is(scalar(@a), 1, 'a returns 1 element');
	is($a[0], 'a', 'a[0]');
	@a = $l->a();
	is(scalar(@a), 1, 'a returns 1 element on cached call');
	is($a[0], 'a', 'a[0] cached');

	ok($l->echo('foo') eq 'foo', 'echo foo');
	ok($l->echo('foo') eq 'foo', 'echo foo cached');
	ok($l->echo('bar') eq 'bar', 'echo bar');
	ok($l->echo('bar') eq 'bar', 'echo bar cached');
	ok($l->echo('foo') eq 'foo', 'echo foo cross-call cache isolation');

	my @empty = $l->empty();
	is(scalar(@empty), 0, 'empty method returns empty list');
	ok(!defined($l->empty()), 'empty method returns undef in scalar context');
	ok(!defined($l->empty()), 'empty method returns undef on second call');

	my @notdef = $l->notdefined();
	is(scalar(@notdef), 1, 'notdefined returns a 1-element list');
	ok(!defined($notdef[0]), 'notdefined element is undef');
	@notdef = $l->notdefined();
	is(scalar(@notdef), 1, 'notdefined cached: still 1 element');
	ok(!defined($notdef[0]), 'notdefined cached element is still undef');

	# White-box: verify cache key format and stored value types.
	is($cache->get('Class::Simple::Readonly::Cached::barney::'),      'betty', 'cache key: barney no-arg');
	is($cache->get('Class::Simple::Readonly::Cached::barney::betty'), 'betty', 'cache key: barney with arg');
	is($cache->get('Class::Simple::Readonly::Cached::echo::foo'),     'foo',   'cache key: echo foo');
	is($cache->get('Class::Simple::Readonly::Cached::echo::bar'),     'bar',   'cache key: echo bar');
	is(ref($cache->get('Class::Simple::Readonly::Cached::a::')),   'ARRAY', 'list result stored as arrayref');
	is(ref($cache->get('Class::Simple::Readonly::Cached::abc::')), 'ARRAY', 'abc result stored as arrayref');

	my $hits = $l->state()->{hits};
	my $hit_count = 0;
	$hit_count += $_ for values %{$hits // {}};
	is($hit_count, 9, 'total cache hits');

	my $misses = $l->state()->{misses};
	my $miss_count = 0;
	$miss_count += $_ for values %{$misses // {}};
	is($miss_count, 8, 'total cache misses');

	diag($l->x()->x()) if($ENV{'TEST_VERBOSE'});
}

package t::x;

sub new {
	my $proto = shift;
	return bless {}, ref($proto) || $proto;
}

sub barney { return 'betty' }

sub abc { return ('a', 'b', 'c') }

sub a { return 'a' }

sub x {
	my $rc = Class::Simple->new();
	$rc->x('y');
	return $rc;
}

sub empty { }

sub notdefined { return (undef) }

sub echo {
	my $self = shift;
	return wantarray ? @_ : $_[0];
}

1;
