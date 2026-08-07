#!/usr/bin/env perl

=head1 NAME

t/integration.t - End-to-end workflow tests for Class::Simple::Cached

=head1 DESCRIPTION

Black-box integration tests validating stateful workflows across multiple
public methods.  Each subtest narrates its strategy in a comment block so
the intent is clear without reading the implementation.

Test::Without::Module is used to prove CHI is an optional runtime dependency.
Test::Mockingbird spies verify that the module calls cache methods with the
correct arguments (e.g. set receives the 'never' expiry token).

=cut

use strict;
use warnings;

use Scalar::Util 'refaddr';
use Test::Most;
use Test::Returns;
use Test::Without::Module;
use Test::Mockingbird qw(spy restore_all);
use Readonly;

BEGIN { use_ok('Class::Simple::Cached') }

Readonly::Scalar my $SENTINEL => Class::Simple::Cached::UNDEF_SENTINEL();
Readonly::Scalar my $PREFIX   => 'Class::Simple::Cached:';
Readonly::Scalar my $NEVER    => 'never';	# CHI set() expiry token

# ── Helper packages ───────────────────────────────────────────────────────────

{
	# Minimal CHI-compatible object that actually stores values and records every
	# call so spies can verify argument correctness in later tests.
	package t::Int::CHI;
	sub new {
		bless { store => {}, log => [] }, shift;
	}
	sub get {
		my ($self, $key) = @_;
		push @{$self->{log}}, [ 'get', $key ];
		return $self->{store}{$key};
	}
	sub set {
		my ($self, $key, $val, $exp) = @_;
		push @{$self->{log}}, [ 'set', $key, $val, $exp ];
		$self->{store}{$key} = $val;
		return 1;
	}
	sub purge {
		my ($self) = @_;
		push @{$self->{log}}, ['purge'];
		%{$self->{store}} = ();
	}
	sub reset_log { $_[0]->{log} = [] }
	sub log       { @{$_[0]->{log}} }
}

{
	# A plain inner object with configurable return values used across many tests.
	# call_count() reflects how many times any getter was invoked on the real object.
	package t::Int::Inner;
	sub new {
		bless { store => {}, calls => 0 }, shift;
	}
	sub call_count { $_[0]->{calls} }
	our $AUTOLOAD;
	sub AUTOLOAD {
		my ($self, @args) = @_;
		my $m = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);
		$self->{calls}++;
		if(@args == 1) {
			$self->{store}{$m} = $args[0];
			return $args[0];
		}
		if(@args > 1) {
			$self->{store}{$m} = \@args;
			return \@args;
		}
		return $self->{store}{$m};
	}
	sub DESTROY {}
}

{
	# A separate inner class used to verify that subclasses produce different
	# cache-key prefixes (so two CSC subclasses sharing a hash ref do not collide).
	package t::Int::InnerB;
	sub new { bless { store => {} }, shift }
	our $AUTOLOAD;
	sub AUTOLOAD {
		my ($self, @args) = @_;
		my $m = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);
		$self->{store}{$m} = $args[0] if @args;
		return $self->{store}{$m};
	}
	sub DESTROY {}
}

{
	# CSC subclass A — its keys are prefixed with 't::Int::CachedA:'
	package t::Int::CachedA;
	our @ISA = ('Class::Simple::Cached');
}

{
	# CSC subclass B — its keys are prefixed with 't::Int::CachedB:'
	package t::Int::CachedB;
	our @ISA = ('Class::Simple::Cached');
}

{
	# An inner object that can respond to can() and isa() for delegation tests.
	package t::Int::Delegating;
	sub new      { bless {}, shift }
	sub greet    { 'hello' }
	sub can {
		my ($self, $m) = @_;
		return ($m eq 'greet') ? \&greet : undef;
	}
	sub isa {
		my ($self, $class) = @_;
		return ($class eq 't::Int::Delegating') ? 1 : 0;
	}
}

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 1 — Hash-ref backend complete lifecycle
#
# Strategy: exercise new → setter → repeated getter (cache hits) → DESTROY.
# After DESTROY we inspect the hash ref directly to confirm keys are gone.
# This proves the full round-trip without any CHI involvement.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:hash:lifecycle' => sub {
	# Strategy: construct with a hash ref, set a value, read it back twice
	# (second read must be a cache hit), then let DESTROY run and verify
	# the hash ref is emptied.
	my %store;
	my $inner = t::Int::Inner->new();
	my $obj   = Class::Simple::Cached->new(cache => \%store, object => $inner);

	# Setter stores value in both the inner object and the hash ref.
	$obj->colour('red');
	is($obj->colour(), 'red',
		'hash:lifecycle: getter returns value after setter');

	# The cache entry should be in the hash under the prefixed key.
	ok(exists $store{"${PREFIX}colour"},
		'hash:lifecycle: cache key exists in the hash ref');

	# Second getter — inner object must NOT be called again (cache hit).
	my $pre_count = $inner->call_count();
	$obj->colour();
	is($inner->call_count(), $pre_count,
		'hash:lifecycle: second getter does not invoke the inner object');

	diag sprintf('[hash:lifecycle] store keys: %s', join(', ', sort keys %store))
		if $ENV{TEST_VERBOSE};

	# DESTROY fires when $obj goes out of scope; use a block to force it.
	{ my $tmp = $obj; }    # keeps $obj alive; we destroy via explicit undef
	$obj = undef;

	is(scalar(keys %store), 0,
		'hash:lifecycle: DESTROY removes all cache entries from the hash ref');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 2 — Optional CHI dependency
#
# Strategy: block CHI with Test::Without::Module to prove that CSC itself
# never issues a `require CHI` — CHI is a purely caller-supplied runtime
# dependency.  The module is already loaded and continues to work with a
# hash-ref cache even when CHI cannot be required.
#
# After the subtest, CHI is unblocked so subsequent subtests can load it.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:optional-chi:hash-backend-works-without-chi' => sub {
	# Block CHI from loading to simulate an environment where it is not installed.
	Test::Without::Module->import('CHI');

	# Verify the block is effective for new require calls.
	eval { require CHI };
	ok($@, 'optional-chi: CHI cannot be required when blocked by Test::Without::Module');

	diag "[optional-chi] require CHI error: $@" if $ENV{TEST_VERBOSE} && $@;

	# CSC itself never calls require CHI — it only interacts with whatever object
	# the caller passes as cache =>.  A hash ref works with no CHI in the process.
	my $obj = Class::Simple::Cached->new(cache => {});
	$obj->field('present');
	is($obj->field(), 'present',
		'optional-chi: hash-ref backend operates correctly without CHI');

	# Likewise, a duck-typed CHI-compatible object works without the CHI module.
	my $fake_chi = t::Int::CHI->new();
	my $obj2 = Class::Simple::Cached->new(cache => $fake_chi, object => t::Int::Inner->new());
	$obj2->colour('blue');
	is($obj2->colour(), 'blue',
		'optional-chi: duck-typed CHI-compatible object works without CHI in process');

	Test::Without::Module->unimport('CHI');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 3 — CHI backend complete lifecycle with spy verification
#
# Strategy: construct with a t::Int::CHI mock, call a setter then a getter,
# and inspect the call log to prove:
#   (a) set() was called with the 'never' expiry token
#   (b) the second get() did NOT re-hit the inner object (cache hit)
# DESTROY on $obj should call purge() on the CHI mock.
# ─────────────────────────────────────────────────────────────────────────────

SKIP: {
	eval { require CHI };
	skip 'CHI not available', 1 if $@;

subtest 'workflow:chi:lifecycle+spy' => sub {
	my $chi   = t::Int::CHI->new();
	my $inner = t::Int::Inner->new();
	my $obj   = Class::Simple::Cached->new(cache => $chi, object => $inner);

	# Setter: should call object->size('large') then chi->set(key, val, 'never').
	$obj->size('large');
	my @calls_after_set = $chi->log();

	my ($set_call) = grep { $_->[0] eq 'set' } @calls_after_set;
	ok(defined $set_call, 'chi:lifecycle: set() was called on the CHI cache');
	is($set_call->[1], "${PREFIX}size",
		'chi:lifecycle: set() key is class-prefixed method name');
	is($set_call->[2], 'large',
		'chi:lifecycle: set() value matches what the inner object returned');
	is($set_call->[3], $NEVER,
		'chi:lifecycle: set() expiry argument is "never"');

	diag sprintf('[chi:lifecycle] set call: [%s]', join(', ', map { $_ // 'undef' } @{$set_call}))
		if $ENV{TEST_VERBOSE};

	# Getter: CSC should call chi->get(key) once; if it returns a truthy value,
	# the inner object must NOT be called again.
	$chi->reset_log();
	my $pre_inner = $inner->call_count();
	my $val = $obj->size();
	is($val, 'large',
		'chi:lifecycle: getter returns cached value');
	is($inner->call_count(), $pre_inner,
		'chi:lifecycle: inner object not called again on cache hit');

	my @get_calls = grep { $_->[0] eq 'get' } $chi->log();
	is(scalar @get_calls, 1,
		'chi:lifecycle: exactly one get() call on the CHI cache for the getter');
	is($get_calls[0][1], "${PREFIX}size",
		'chi:lifecycle: get() receives the correct prefixed key');

	# DESTROY: let $obj go out of scope and verify purge() fires.
	$chi->reset_log();
	$obj = undef;

	my @purge_calls = grep { $_->[0] eq 'purge' } $chi->log();
	is(scalar @purge_calls, 1,
		'chi:lifecycle: DESTROY calls purge() exactly once on the CHI cache');

	done_testing();
};

} # end SKIP

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 4 — Multi-instance isolation with separate caches
#
# Strategy: create two CSC instances with INDEPENDENT caches.  Setting a
# value in one must not appear in the other's cache, and DESTROY of one
# must not touch the other's data.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:multi-instance:isolation' => sub {
	my (%store_a, %store_b);
	my $inner_a = t::Int::Inner->new();
	my $inner_b = t::Int::Inner->new();
	my $obj_a   = Class::Simple::Cached->new(cache => \%store_a, object => $inner_a);
	my $obj_b   = Class::Simple::Cached->new(cache => \%store_b, object => $inner_b);

	$obj_a->colour('red');
	$obj_b->colour('blue');

	is($obj_a->colour(), 'red',  'multi-instance: obj_a returns its own value');
	is($obj_b->colour(), 'blue', 'multi-instance: obj_b returns its own value');

	# Both use the same key name (same class prefix) but in separate hash refs.
	# Verify each hash holds only its own instance's value.
	is($store_a{"${PREFIX}colour"}, 'red',
		'multi-instance: store_a holds obj_a value');
	is($store_b{"${PREFIX}colour"}, 'blue',
		'multi-instance: store_b holds obj_b value (not obj_a value)');

	# Destroy obj_a; obj_b must be unaffected.
	$obj_a = undef;

	is(scalar(keys %store_a), 0,
		'multi-instance: DESTROY of obj_a clears only store_a');
	ok(exists $store_b{"${PREFIX}colour"},
		'multi-instance: DESTROY of obj_a does not touch store_b');
	is($obj_b->colour(), 'blue',
		'multi-instance: obj_b getter still works after obj_a is destroyed');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 5 — Shared hash-ref cache, different classes: namespace isolation
#
# Strategy: two CSC subclasses (t::Int::CachedA and t::Int::CachedB) share
# the SAME hash ref.  Because they have different class names, their keys
# are prefixed with different strings and they cannot collide.
# DESTROY of instance A only removes A-prefixed keys, leaving B's intact.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:shared-hash:different-class-namespacing' => sub {
	my %shared;
	my $inner_a = t::Int::Inner->new();
	my $inner_b = t::Int::InnerB->new();
	my $obj_a   = t::Int::CachedA->new(cache => \%shared, object => $inner_a);
	my $obj_b   = t::Int::CachedB->new(cache => \%shared, object => $inner_b);

	$obj_a->colour('green');
	$obj_b->colour('yellow');

	# Both entries should coexist in the shared hash under different prefixes.
	my $key_a = 't::Int::CachedA:colour';
	my $key_b = 't::Int::CachedB:colour';

	ok(exists $shared{$key_a}, 'shared-hash:ns: key_a exists in shared cache');
	ok(exists $shared{$key_b}, 'shared-hash:ns: key_b exists in shared cache');
	isnt($shared{$key_a}, $shared{$key_b},
		'shared-hash:ns: the two class entries hold distinct values');

	diag sprintf('[shared-hash:ns] keys: %s', join(', ', sort keys %shared))
		if $ENV{TEST_VERBOSE};

	# Destroy obj_a — only key_a should be removed.
	$obj_a = undef;
	ok(!exists $shared{$key_a}, 'shared-hash:ns: obj_a key removed after DESTROY');
	ok( exists $shared{$key_b}, 'shared-hash:ns: obj_b key untouched after obj_a DESTROY');
	is($obj_b->colour(), 'yellow',
		'shared-hash:ns: obj_b getter still returns its value after obj_a DESTROY');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 6 — Shared hash-ref cache, SAME class: sibling cache cleared by DESTROY
#
# Strategy: two instances of Class::Simple::Cached itself share one hash ref.
# Because both instances share the SAME class-prefix, DESTROY of either one
# deletes ALL keys with that prefix — including the sibling's entries.
#
# This is an expected consequence of the prefix-based purge (documented in
# the DESTROY comment in the source).  A shared cache between same-class
# instances should be avoided unless both have the same lifecycle.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:shared-hash:same-class-destroy-clears-sibling' => sub {
	my %shared;
	my $obj_a = Class::Simple::Cached->new(cache => \%shared, object => t::Int::Inner->new());
	my $obj_b = Class::Simple::Cached->new(cache => \%shared, object => t::Int::Inner->new());

	$obj_a->temperature('hot');
	$obj_b->pressure('high');

	# Both keys are in the shared hash with the same prefix.
	my $key_temp  = "${PREFIX}temperature";
	my $key_press = "${PREFIX}pressure";

	ok(exists $shared{$key_temp},  'shared-hash:same: temperature key in shared hash');
	ok(exists $shared{$key_press}, 'shared-hash:same: pressure key in shared hash');

	# Destroy obj_a — it removes ALL keys with the class prefix, including
	# obj_b's 'pressure' entry.
	$obj_a = undef;

	ok(!exists $shared{$key_temp},
		'shared-hash:same: obj_a temperature key removed by DESTROY');
	ok(!exists $shared{$key_press},
		'shared-hash:same: obj_b pressure key also cleared (same-prefix DESTROY)');

	# obj_b's next getter is a cache miss — falls through to inner object.
	my $inner_b_calls_before = $obj_b->{'object'}->call_count();
	my $val = $obj_b->pressure();
	is($val, 'high', 'shared-hash:same: obj_b getter re-fetches after sibling DESTROY');
	is($obj_b->{'object'}->call_count(), $inner_b_calls_before + 1,
		'shared-hash:same: inner object re-invoked after cache was cleared');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 7 — CHI backend LIMITATION: purge is global
#
# Strategy (from the POD LIMITATIONS section):
#   "purge() on a CHI-style cache is global: destroying one instance will
#   purge all entries from a shared CHI cache, including those of the other."
#
# Two subclass instances share one t::Int::CHI object.  Destroying the first
# instance calls purge() which clears everything, so the second instance
# loses its cache entries too.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:chi-shared:global-purge-limitation' => sub {
	my $chi   = t::Int::CHI->new();
	my $obj_a = t::Int::CachedA->new(cache => $chi, object => t::Int::Inner->new());
	my $obj_b = t::Int::CachedB->new(cache => $chi, object => t::Int::Inner->new());

	$obj_a->colour('magenta');
	$obj_b->colour('cyan');

	# Verify both values are in the CHI store.
	is($chi->{store}{'t::Int::CachedA:colour'}, 'magenta',
		'chi-shared: obj_a value in CHI store before DESTROY');
	is($chi->{store}{'t::Int::CachedB:colour'}, 'cyan',
		'chi-shared: obj_b value in CHI store before DESTROY');

	diag sprintf('[chi-shared] chi store keys: %s',
		join(', ', sort keys %{$chi->{store}})) if $ENV{TEST_VERBOSE};

	# Destroy obj_a — purge() is called and wipes the ENTIRE CHI store.
	$chi->reset_log();
	$obj_a = undef;

	my @purge_calls = grep { $_->[0] eq 'purge' } $chi->log();
	is(scalar @purge_calls, 1, 'chi-shared: purge() called once on DESTROY of obj_a');

	# POD LIMITATION verified: obj_b's entry is also gone.
	ok(!exists $chi->{store}{'t::Int::CachedB:colour'},
		'chi-shared: LIMITATION — obj_b entry purged by obj_a DESTROY (global purge)');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 8 — Clone workflow
#
# Strategy: call ->new() on an existing instance to produce a shallow clone.
# The clone must share the same cache handle as the original, so values set
# by either party are visible to the other.  The clone uses the same class
# prefix, so its DESTROY will clear the same set of keys.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:clone' => sub {
	my %store;
	my $original = Class::Simple::Cached->new(cache => \%store, object => t::Int::Inner->new());

	$original->shape('circle');

	my $clone = $original->new();	# shallow clone; same cache handle

	# Clone must see the value set by original (shared cache).
	is($clone->shape(), 'circle',
		'clone: clone sees value set by original (shared cache)');

	# Clone sets a different value; original must see it too.
	$clone->shape('square');
	is($original->shape(), 'square',
		'clone: original sees value updated by clone');

	# Both should share the same internal cache reference.
	is(refaddr($clone->{'cache'}), refaddr($original->{'cache'}),
		'clone: clone and original share the same cache reference');

	# The clone recalculates _cache_prefix from ref($self) (the original's class).
	is($clone->{'_cache_prefix'}, $original->{'_cache_prefix'},
		'clone: _cache_prefix is identical in original and clone');

	# Destroy the clone — as it has the same prefix, ALL prefixed keys are removed.
	$clone = undef;
	is(scalar(keys %store), 0,
		'clone: DESTROY of clone removes all same-prefix keys (including original data)');

	# After clone DESTROY, original's next getter is a cache miss.
	my $inner_calls_before = $original->{'object'}->call_count();
	my $val = $original->shape();
	is($val, 'square',
		'clone: original getter re-fetches from inner object after clone DESTROY');
	is($original->{'object'}->call_count(), $inner_calls_before + 1,
		'clone: inner object re-invoked on cache miss after clone DESTROY');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 9 — Subclass key isolation
#
# Strategy: t::Int::CachedA and CSC itself both wrap inner objects, each using
# different cache-key prefixes.  Verify the prefix is derived from the concrete
# class name so that two subclasses never share keys even if the method name is
# identical.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:subclass:key-isolation' => sub {
	my %store;
	my $sub_obj = t::Int::CachedA->new(cache => \%store, object => t::Int::Inner->new());
	my $base_obj = Class::Simple::Cached->new(cache => \%store, object => t::Int::Inner->new());

	$sub_obj->name('subclass');
	$base_obj->name('base');

	my $sub_key  = 't::Int::CachedA:name';
	my $base_key = "${PREFIX}name";

	is($store{$sub_key},  'subclass',
		'subclass:key-isolation: subclass key holds subclass value');
	is($store{$base_key}, 'base',
		'subclass:key-isolation: base class key holds base value');

	is($sub_obj->name(),  'subclass',
		'subclass:key-isolation: subclass getter returns own value (no collision)');
	is($base_obj->name(), 'base',
		'subclass:key-isolation: base getter returns own value (no collision)');

	diag sprintf('[subclass:key-isolation] store: %s',
		join(', ', map { "$_=$store{$_}" } sort keys %store)) if $ENV{TEST_VERBOSE};

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 10 — Wrapped custom object: can() and isa() delegation
#
# Strategy: wrap a t::Int::Delegating object that provides custom can() and
# isa() implementations.  Verify that CSC's can() and isa() delegate to the
# inner object when the wrapper itself does not directly handle the query.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:delegation:can-and-isa' => sub {
	my $inner = t::Int::Delegating->new();
	my $obj   = Class::Simple::Cached->new(cache => {}, object => $inner);

	# can() must return true for a method the inner object advertises.
	ok($obj->can('greet'),
		'delegation:can: CSC can() delegates to inner object for "greet"');

	# can() must return something falsy for a method neither CSC nor inner knows.
	ok(!$obj->can('no_such_method'),
		'delegation:can: CSC can() returns false for unknown method');

	# can('new') must always be true — CSC always provides new().
	ok($obj->can('new'),
		'delegation:can: CSC can("new") is always true');

	# isa() must delegate to the inner object for its own class.
	ok($obj->isa('t::Int::Delegating'),
		'delegation:isa: CSC isa() delegates to inner for inner object class');

	# isa('Class::Simple::Cached') must be true — wrapper is always CSC.
	ok($obj->isa('Class::Simple::Cached'),
		'delegation:isa: CSC isa() returns true for its own package');

	# isa() for a class neither party knows.
	ok(!$obj->isa('No::Such::Class'),
		'delegation:isa: CSC isa() returns false for unknown class');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 11 — Concurrent instances: no cross-instance state pollution
#
# Strategy: create several independent CSC instances simultaneously (they coexist
# in the same process, same test scope).  Mutate state in one and verify that
# all others are unaffected.  This exercises the assumption that the cache
# prefix is per-class (not per-instance), and that hash-ref caches are
# genuinely independent when they are distinct references.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:concurrent:no-cross-pollution' => sub {
	Readonly::Scalar my $N => 5;

	# Five independent instances, each with its own separate hash-ref cache.
	my @objs   = map { Class::Simple::Cached->new(cache => {}, object => t::Int::Inner->new()) } 1..$N;

	# Set a distinct value in each instance.
	for my $i (0 .. $N-1) {
		$objs[$i]->value("instance_$i");
	}

	# Every instance must return its own value, not a neighbour's.
	for my $i (0 .. $N-1) {
		is($objs[$i]->value(), "instance_$i",
			"concurrent: instance $i returns its own value");
	}

	# Destroy all but instance 2; verify instance 2 is unaffected.
	for my $i (0, 1, 3, 4) {
		$objs[$i] = undef;
	}
	is($objs[2]->value(), 'instance_2',
		'concurrent: instance 2 unaffected after other instances destroyed');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 12 — Undef caching via sentinel: scalar-context cache round-trip
#
# Strategy: an inner object returns undef.  CSC must store the UNDEF_SENTINEL
# and return undef on subsequent calls WITHOUT re-invoking the inner object.
# This validates the sentinel mechanism end-to-end across the full call chain.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:sentinel:undef-caching' => sub {
	my $inner = t::Int::Inner->new();
	my %store;
	my $obj   = Class::Simple::Cached->new(cache => \%store, object => $inner);

	# First call: cache miss, inner returns undef, sentinel stored.
	my $v1 = $obj->missing();
	ok(!defined($v1), 'sentinel: first getter returns undef');
	is($store{"${PREFIX}missing"}, $SENTINEL,
		'sentinel: UNDEF_SENTINEL written to cache for undef return');

	my $calls_after_first = $inner->call_count();

	# Second call: cache hit, sentinel decoded back to undef.
	my $v2 = $obj->missing();
	ok(!defined($v2), 'sentinel: second getter returns undef (from cache)');
	is($inner->call_count(), $calls_after_first,
		'sentinel: inner object NOT called again on sentinel cache hit');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 13 — Array round-trip across both backends
#
# Strategy: call a setter with multiple arguments (array setter path), then
# retrieve the list via a getter.  Run against both hash-ref and CHI-compatible
# backends to prove backend parity for the array code path.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:array:hash-backend' => sub {
	my $inner = t::Int::Inner->new();
	my %store;
	my $obj   = Class::Simple::Cached->new(cache => \%store, object => $inner);

	my @set_ret = $obj->tags('perl', 'cpan', 'cache');
	is_deeply(\@set_ret, ['perl', 'cpan', 'cache'],
		'array:hash: setter returns the stored list');

	is(ref($store{"${PREFIX}tags"}), 'ARRAY',
		'array:hash: cache entry is an arrayref');

	# Getter returns the dereferenced list without re-calling the inner object.
	my $calls_before = $inner->call_count();
	my @got = $obj->tags();
	is_deeply(\@got, ['perl', 'cpan', 'cache'],
		'array:hash: getter returns the cached list');
	is($inner->call_count(), $calls_before,
		'array:hash: inner object not called again on array cache hit');

	done_testing();
};

subtest 'workflow:array:chi-backend' => sub {
	my $chi   = t::Int::CHI->new();
	my $inner = t::Int::Inner->new();
	my $obj   = Class::Simple::Cached->new(cache => $chi, object => $inner);

	my @set_ret = $obj->tags('x', 'y', 'z');
	is_deeply(\@set_ret, ['x', 'y', 'z'],
		'array:chi: setter returns the stored list');

	my ($set_call) = grep { $_->[0] eq 'set' } $chi->log();
	is(ref($set_call->[2]), 'ARRAY',
		'array:chi: CHI set() received an arrayref (not a flat list)');
	is($set_call->[3], $NEVER,
		'array:chi: CHI set() received "never" expiry token');

	my $calls_before = $inner->call_count();
	my @got = $obj->tags();
	is_deeply(\@got, ['x', 'y', 'z'],
		'array:chi: getter returns the cached list');
	is($inner->call_count(), $calls_before,
		'array:chi: inner object not called again on array cache hit');

	done_testing();
};

# ─────────────────────────────────────────────────────────────────────────────
# Workflow 14 — Backend parity: hash-ref and CHI-compatible produce
#               identical caller-visible outcomes for all setter/getter paths.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'workflow:backend-parity:scalar-getter-setter' => sub {
	# Run the same setter→getter round-trip against both backends and
	# assert they produce identical caller-visible outcomes.
	for my $label_backend (
		['hash', sub { my %h; return \%h }],
		['chi',  sub { t::Int::CHI->new()        }],
	) {
		my ($label, $mk_cache) = @{$label_backend};
		my $cache = $mk_cache->();
		my $inner = t::Int::Inner->new();
		my $obj   = Class::Simple::Cached->new(cache => $cache, object => $inner);

		$obj->speed('fast');
		my $v1 = $obj->speed();
		is($v1, 'fast',
			"parity:$label: getter returns value after setter");

		# Verify the inner object is not re-called on the second get.
		my $c = $inner->call_count();
		$obj->speed();
		is($inner->call_count(), $c,
			"parity:$label: inner object not re-invoked on second getter");
	}

	done_testing();
};

done_testing();
