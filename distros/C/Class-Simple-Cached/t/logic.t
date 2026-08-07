#!/usr/bin/env perl

=head1 NAME

t/logic.t - Formal equivalence-partition proofs for Class::Simple::Cached

=head1 DESCRIPTION

Each subtest below is a formal proof, not an integration smoke-test.

=head3 FORMAL SPECIFICATION

    ── Getter dispatch (cache-hit path) ──────────────────────────────────
    rc : CacheValue
    ──────────────────────────────────────────────────────────────────────
    Partition G1: ¬ref(rc) ∧ rc ≠ SENTINEL  ⟹  result! = rc
    Partition G2: ¬ref(rc) ∧ rc = SENTINEL  ⟹  result! = undef
    Partition G3: ref(rc) = 'ARRAY'         ⟹  result! = @{rc}
    Partition G4: ref(rc) ≠ '' ∧ ≠ 'ARRAY' ⟹  result! = rc  (blessed obj)

    G1..G4 are mutually exclusive and exhaustive over all truthy CacheValues.

    ── Setter arg-count partitions ───────────────────────────────────────
    args : Seq(Any)
    ──────────────────────────────────────────────────────────────────────
    |args| = 0  ⟹  getter path
    |args| = 1  ⟹  scalar setter  (object called with scalar)
    |args| > 1  ⟹  array setter   (object called with \@args)

    Partitions are mutually exclusive by integer boundary.
    |args| = 1 is reached as logical necessity — no conditional test exists.

    ── CHI interface AND-conjunction ─────────────────────────────────────
    cache : BlessedObject
    ──────────────────────────────────────────────────────────────────────
    valid(cache) = can_get(cache) ∧ can_set(cache) ∧ can_purge(cache)
    ¬valid(cache) ⟹ croak  (for any missing method, independently)

=cut

use strict;
use warnings;

use Test::Most;
use Readonly;

BEGIN { use_ok('Class::Simple::Cached') }

Readonly::Scalar my $SENTINEL => Class::Simple::Cached::UNDEF_SENTINEL();

# ── Helper packages ───────────────────────────────────────────────────────────

{
	# Records each call so tests can count object invocations.
	package t::CallCounter;
	sub new    { bless { count => 0, val => undef }, shift }
	sub count  { $_[0]->{'count'} }
	sub getter {
		my $self = shift;
		$self->{'count'}++;
		return $self->{'val'};
	}
	sub setter {
		my ($self, @args) = @_;
		$self->{'count'}++;
		if(@args == 1) {
			$self->{'val'} = $args[0];
			return $args[0];
		}
		# multi-arg: store and return as arrayref (Class::Simple convention)
		$self->{'val'} = \@args;
		return \@args;
	}
	sub returns_zero  { $_[0]->{'count'}++; 0 }
	sub returns_empty { $_[0]->{'count'}++; return }   # empty list/undef depending on context
}

{
	# Blessed object with overloaded eq — used for getter-dispatch partition G4.
	package t::OverloadedEq;
	use overload 'eq' => sub { 1 }, '""' => sub { 'overloaded' }, fallback => 1;
	sub new { bless {}, shift }
}

{
	# Objects used to prove the CHI AND-conjunction: each is missing exactly
	# one of the three required interface methods.
	package t::NoGet;   sub new { bless {}, shift }  sub set {} sub purge {}
	package t::NoSet;   sub new { bless {}, shift }  sub get {} sub purge {}
	package t::NoPurge; sub new { bless {}, shift }  sub get {} sub set  {}
}

# ═══════════════════════════════════════════════════════════════════════════
# THEOREM 1 — Cache-hit branches are mutually exclusive and exhaustive
#
# Major Premise: ref() returns '', 'ARRAY', or a package name — three
#   disjoint value classes for any Perl value.
# Minor Premise: the cache stores whichever of those was returned by the
#   wrapped object (plain scalar, arrayref, or blessed object).
# Conclusion: exactly one branch fires per cache-hit, with no overlap.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'G1: plain-scalar cache hit returns the scalar' => sub {
	# Premise: ref('hello') eq '' (falsy) → first branch (!ref($rc)).
	# Conclusion: value returned directly; sentinel check never runs.
	my %cache;
	my $obj = Class::Simple::Cached->new(cache => \%cache);

	$obj->colour('hello');
	is($obj->colour(), 'hello', 'G1: plain scalar returned on cache hit');

	# White-box: confirm 'hello' is stored raw (not wrapped).
	is($cache{'Class::Simple::Cached:colour'}, 'hello',
		'G1: cache stores plain scalar, not an arrayref');

	done_testing();
};

subtest 'G3: arrayref cache hit returns a flat list' => sub {
	# Premise: ref(\@result) eq 'ARRAY' → second branch (elsif ref eq ARRAY).
	# Conclusion: the arrayref is dereferenced; all three elements return.
	my %cache;
	my $obj = Class::Simple::Cached->new(
		cache  => \%cache,
		object => t::CallCounter->new(),
	);

	# First call (cache miss): setter stores \@_ = ['a', 'b', 'c']
	my @first = $obj->setter('a', 'b', 'c');

	# Second call (cache hit): the stored arrayref must be dereferenced
	my @second = $obj->setter();
	is_deeply(\@second, ['a', 'b', 'c'],
		'G3: arrayref cache hit returns flat list via dereferencing');

	# White-box: cache holds an ARRAY ref
	is(ref($cache{'Class::Simple::Cached:setter'}), 'ARRAY',
		'G3: cache stores an arrayref for multi-element results');

	done_testing();
};

subtest 'G4: blessed-object cache hit returns the object (no sentinel comparison)' => sub {
	# Major Premise: blessed object's ref() returns its package name (truthy,
	#   not empty string, not 'ARRAY') → the elsif chain falls through to the
	#   final return — overloaded eq is NEVER invoked.
	# Conclusion: a blessed object with eq => sub{1} does not trigger
	#   false-positive sentinel detection.
	my %cache;
	my $inner = do {
		package t::ReturnsBlessed;
		sub new    { bless {}, shift }
		sub getter { return t::OverloadedEq->new() }
		t::ReturnsBlessed->new();
	};
	my $obj = Class::Simple::Cached->new(cache => \%cache, object => $inner);

	# Call 1: cache miss → stores the blessed object.
	my $v1 = $obj->getter();
	ok(ref($v1), 'G4: first call returns a reference (cache miss)');

	# Call 2: cache hit → must NOT return undef (sentinel check bypassed).
	my $v2 = $obj->getter();
	ok(ref($v2), 'G4: second call returns a reference (cache hit, no false sentinel)');
	ok(defined($v2), 'G4: overloaded-eq object never decoded as undef');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# THEOREM 2 — Setter arg-count partitions are non-overlapping integers
#
# Partition boundaries: {0}, {1}, {n | n > 1}.
# Each partition is reached by exactly one control-flow path in AUTOLOAD.
# The scalar-setter (|args|=1) is a logical necessity: no conditional guards
# it; it is reached because the two earlier guards (==0 and >1) have returned.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'S1: scalar setter (exactly 1 arg) passes scalar to wrapped object' => sub {
	# Premise: |args| = 1 → neither == 0 nor > 1 guards fire.
	# Premise: scalar setter calls $object->$param($_[0]), not $object->$param(\@_).
	# Conclusion: the inner object receives the plain scalar, not a one-element arrayref.
	my $inner = t::CallCounter->new();
	my $obj   = Class::Simple::Cached->new(cache => {}, object => $inner);

	my $ret = $obj->setter('xyz');
	is($ret, 'xyz',
		'S1: scalar setter returns the value, not CHI set() status');
	is($inner->count(), 1, 'S1: inner object called exactly once');

	# Call 2: getter must return the cached 'xyz', not re-invoke the object.
	my $cached = $obj->setter();
	is($cached, 'xyz', 'S1: subsequent getter returns cached scalar');
	is($inner->count(), 1, 'S1: inner object NOT called again on cache hit');

	done_testing();
};

subtest 'A1: array setter (>1 args) passes \@_ to wrapped object' => sub {
	# Premise: |args| > 1 → array setter path fires.
	# Premise: $object->$param(\@_) is called, so the wrapped object
	#   receives a single arrayref argument.
	# Conclusion: the return value is an arrayref; cache stores it; getter
	#   in list context returns the dereferenced list.
	my $inner = t::CallCounter->new();
	my %cache;
	my $obj   = Class::Simple::Cached->new(cache => \%cache, object => $inner);

	my @ret = $obj->setter('p', 'q', 'r');
	is_deeply(\@ret, ['p', 'q', 'r'],
		'A1: array setter return value is the stored list');
	is($inner->count(), 1, 'A1: inner object called once for the setter');

	# Cache key must include the class prefix (regression from pre-0.07).
	ok(!exists($cache{'setter'}),     'A1: bare key (without prefix) not written');
	ok( exists($cache{'Class::Simple::Cached:setter'}),
		'A1: prefixed cache key written by array setter');

	# Getter: cache hit must return the list without re-invoking the object.
	my @hit = $obj->setter();
	is_deeply(\@hit, ['p', 'q', 'r'], 'A1: getter returns cached list');
	is($inner->count(), 1, 'A1: inner object NOT called again on getter cache hit');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# THEOREM 3 — CHI interface validation is a conjunction (AND) of three
#             independent conditions; any single missing method suffices to
#             croak.
#
# De Morgan equivalent: croak iff ¬can_get ∨ ¬can_set ∨ ¬can_purge
# Each disjunct is tested independently to prove the AND is not short-cut
# by the order of evaluation.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'CHI-AND: missing get() alone causes croak' => sub {
	throws_ok {
		Class::Simple::Cached->new(cache => t::NoGet->new())
	} qr/Cache object must implement/,
		'CHI-AND: blessed cache missing only get() is rejected';
	done_testing();
};

subtest 'CHI-AND: missing set() alone causes croak' => sub {
	throws_ok {
		Class::Simple::Cached->new(cache => t::NoSet->new())
	} qr/Cache object must implement/,
		'CHI-AND: blessed cache missing only set() is rejected';
	done_testing();
};

subtest 'CHI-AND: missing purge() alone causes croak' => sub {
	throws_ok {
		Class::Simple::Cached->new(cache => t::NoPurge->new())
	} qr/Cache object must implement/,
		'CHI-AND: blessed cache missing only purge() is rejected';
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# THEOREM 4 — Falsy-but-defined scalar (0) is not cached
#
# Major Premise: the cache-hit guard is if($rc) (truthiness, not definedness).
# Minor Premise: 0 is falsy.
# Conclusion: a method returning 0 is treated as a cache miss every call.
#   The wrapped object IS re-invoked on every getter call.
#
# This is a documented limitation (see LIMITATIONS in the POD).
# ═══════════════════════════════════════════════════════════════════════════

subtest 'falsy-scalar boundary: 0 is not cached' => sub {
	my $inner = t::CallCounter->new();
	my $obj   = Class::Simple::Cached->new(cache => {}, object => $inner);

	# returns_zero() always returns 0 (falsy but defined).
	my $v1 = $obj->returns_zero();
	is($v1, 0, 'falsy-boundary: first call returns 0');
	is($inner->count(), 1, 'falsy-boundary: object called on first call');

	my $v2 = $obj->returns_zero();
	is($v2, 0, 'falsy-boundary: second call still returns 0');
	is($inner->count(), 2,
		'falsy-boundary: object called AGAIN because 0 is not cached');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# THEOREM 5 — Context asymmetry: empty-list context vs scalar-undef context
#
# Major Premise: "return unless scalar(@result)" prevents caching when the
#   wrapped object returns an empty list in list context.
# Major Premise: undef is cached as UNDEF_SENTINEL in scalar context.
# Minor Premise: the same object method can return an empty list in list
#   context and undef in scalar context.
# Conclusion:
#   - list context, empty result:   NOT cached; object called every call.
#   - scalar context, undef result: IS cached;  object called only once.
#
# This explains the historical FIXME comment in t/hash.t and t/chi.t.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'context-asymmetry: empty list context is not cached' => sub {
	my $inner = t::CallCounter->new();
	my %cache;
	my $obj   = Class::Simple::Cached->new(cache => \%cache, object => $inner);

	# Both calls in list context → both are cache misses → object called twice.
	my @r1 = $obj->returns_empty();
	my @r2 = $obj->returns_empty();
	is(scalar(@r1), 0, 'context-asymm: list context returns empty list');
	is(scalar(@r2), 0, 'context-asymm: second list-context call also returns empty');
	is($inner->count(), 2,
		'context-asymm: object called TWICE (empty list is never cached)');

	# No cache entry should exist — the guard prevented storage.
	ok(!exists($cache{'Class::Simple::Cached:returns_empty'}),
		'context-asymm: no cache entry written for empty-list result');

	done_testing();
};

subtest 'context-asymmetry: scalar-context undef IS cached as sentinel' => sub {
	my $inner = t::CallCounter->new();
	my %cache;
	my $obj   = Class::Simple::Cached->new(cache => \%cache, object => $inner);

	# First call in scalar context: cache miss → object called → stores sentinel.
	my $v1 = $obj->returns_empty();
	ok(!defined($v1), 'context-asymm: scalar context returns undef');
	is($inner->count(), 1, 'context-asymm: object called once (cache miss)');

	# Sentinel is stored.
	is($cache{'Class::Simple::Cached:returns_empty'}, $SENTINEL,
		'context-asymm: UNDEF_SENTINEL written for scalar-context undef');

	# Second call: cache hit → sentinel decoded → object NOT called again.
	my $v2 = $obj->returns_empty();
	ok(!defined($v2), 'context-asymm: second scalar call returns undef from cache');
	is($inner->count(), 1, 'context-asymm: object NOT called again (cache hit)');

	done_testing();
};

done_testing();
