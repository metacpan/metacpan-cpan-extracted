#!/usr/bin/env perl

=head1 NAME

t/edge_cases.t - Destructive, pathological, boundary, and security edge-case tests

=head1 DESCRIPTION

Actively attempts to break or subvert Class::Simple::Cached through hostile
constructor inputs, internal-field injection, upstream failure simulation,
boundary-condition values, and structural abuse.

Three bugs were discovered while writing these tests and fixed in the module:

=over 4

=item 1.

B<Clone validation gap> (C<new()> on instance): passing C<cache =E<gt> undef>
(or any invalid cache) via the clone path created a usable-looking but
immediately-crashing object.  Fixed by adding the same cache validation that
the non-clone path already applies.

=item 2.

B<C<can(undef)> emits spurious warnings>: the C<$method eq 'new'> comparison
generated an "uninitialized value" warning when method was C<undef>.  Fixed
with a C<defined $method> guard that returns C<undef> cleanly.

=item 3.

B<C<isa(undef)> emits spurious warnings>: same root cause as above.  Fixed
with a C<defined $class> guard.

=back

The following behaviour changes B<between cache-miss and cache-hit> when the
inner object's scalar-context getter returns an B<arrayref>: the first call
returns the arrayref; the second call (cache hit) treats the stored arrayref as
a cached list and returns the element count in scalar context.  This is a
structural limitation documented in the LIMITATIONS section of the POD.  No
test asserts the buggy behaviour — the limitation test below asserts the
miss-path return value only and explains the discrepancy.

=cut

use strict;
use warnings;

use Scalar::Util qw(blessed refaddr);
use POSIX qw(ENOENT);
use Test::Most;
use Test::Returns;
use Test::Mockingbird qw(spy restore_all);
use Readonly;

BEGIN { use_ok('Class::Simple::Cached') }

Readonly::Scalar my $SENTINEL  => Class::Simple::Cached::UNDEF_SENTINEL();
Readonly::Scalar my $PREFIX    => 'Class::Simple::Cached:';
Readonly::Scalar my $LONG_NAME => 'x' x 10_000;		# 10 KB method name
Readonly::Scalar my $LARGE_VAL => 'A' x (1024 * 1024);	# 1 MB string

# ── Helper packages ───────────────────────────────────────────────────────────

{
	# Flexible inner object: AUTOLOAD stores and returns per-method values,
	# and counts how many times each method has been called.
	package t::EC::Inner;
	sub new   { bless { store => {}, calls => {} }, shift }
	sub calls { $_[0]->{calls}{$_[1]} // 0 }
	our $AUTOLOAD;
	sub AUTOLOAD {
		my ($self, @args) = @_;
		my $m = substr($AUTOLOAD, rindex($AUTOLOAD, '::') + 2);
		$self->{calls}{$m}++;
		return $self->{store}{$m} = $args[0] if @args == 1;
		return $self->{store}{$m} = \@args   if @args > 1;
		return $self->{store}{$m};
	}
	sub DESTROY {}
}

{
	# Inner object whose getter always dies — simulates an upstream failure.
	package t::EC::DyingGetter;
	sub new    { bless {}, shift }
	sub value  { die "upstream get failure\n" }
	sub DESTROY {}
}

{
	# Inner object whose setter always dies but whose getter succeeds.
	package t::EC::DyingSetter;
	sub new   { bless { v => undef }, shift }
	sub value { die "upstream set failure\n" if @_ > 1; return $_[0]->{v} }
	sub DESTROY {}
}

{
	# Inner object that legitimately returns the UNDEF_SENTINEL string.
	# Tests the documented sentinel-collision limitation.
	package t::EC::SentinelReturner;
	sub new     { bless {}, shift }
	sub val     { return Class::Simple::Cached::UNDEF_SENTINEL() }
	sub DESTROY {}
}

{
	# Inner object whose getter returns an arrayref in scalar context — tests
	# the documented limitation where behaviour differs between miss and hit.
	package t::EC::ArrayRefGetter;
	sub new   { bless {}, shift }
	sub items { return ['a', 'b', 'c'] }	# arrayref as scalar return
	sub DESTROY {}
}

{
	# Inner object that returns an array with UNDEF_SENTINEL as first element.
	# The cache-hit path in AUTOLOAD must croak when it encounters this.
	package t::EC::ArraySentinelReturner;
	sub new   { bless {}, shift }
	sub items { return (Class::Simple::Cached::UNDEF_SENTINEL(), 'x', 'y') }
	sub DESTROY {}
}

{
	# Standard CHI-compatible mock with a call log.
	package t::EC::CHI;
	sub new   { bless { store => {}, log => [] }, shift }
	sub get   { my ($s,$k)       = @_; push @{$s->{log}},['get',$k]; $s->{store}{$k} }
	sub set   { my ($s,$k,$v,$e) = @_; push @{$s->{log}},['set',$k,$v,$e]; $s->{store}{$k}=$v; 1 }
	sub purge { my ($s)          = @_; push @{$s->{log}},['purge']; %{$s->{store}}=() }
	sub log   { @{$_[0]->{log}} }
	sub reset { $_[0]->{log} = [] }
}

{
	# CHI mock whose get() always dies.
	package t::EC::DyingGet;
	sub new   { bless {}, shift }
	sub get   { die "cache get() failed\n" }
	sub set   { 1 }
	sub purge {}
}

{
	# CHI mock whose set() always dies.
	package t::EC::DyingSet;
	sub new   { bless { store => {} }, shift }
	sub get   { $_[0]->{store}{$_[1]} }
	sub set   { die "cache set() failed\n" }
	sub purge { %{$_[0]->{store}} = () }
}

{
	# Minimal valid CHI-compatible object (has all three methods).
	package t::EC::FullCHI;
	sub new   { bless {}, shift }
	sub get   {}
	sub set   { 1 }
	sub purge {}
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION A — Constructor: hostile cache argument types
#
# Strategy: feed every non-hashref, non-blessed-object type for cache =>.
# Each must croak with the exact message before any internal state is set.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'constructor:cache-undef' => sub {
	throws_ok { Class::Simple::Cached->new(cache => undef) }
		qr/Cache must be ref to HASH or object/,
		'constructor: cache => undef croaks with correct message';
	done_testing();
};

subtest 'constructor:cache-zero' => sub {
	throws_ok { Class::Simple::Cached->new(cache => 0) }
		qr/Cache must be ref to HASH or object/,
		'constructor: cache => 0 (falsy scalar) croaks';
	done_testing();
};

subtest 'constructor:cache-empty-string' => sub {
	throws_ok { Class::Simple::Cached->new(cache => '') }
		qr/Cache must be ref to HASH or object/,
		'constructor: cache => "" (empty string) croaks';
	done_testing();
};

subtest 'constructor:cache-plain-string' => sub {
	throws_ok { Class::Simple::Cached->new(cache => 'not a ref') }
		qr/Cache must be ref to HASH or object/,
		'constructor: cache => "not a ref" (plain string) croaks';
	done_testing();
};

subtest 'constructor:cache-arrayref' => sub {
	# An arrayref is a ref but not a HASH ref and not a blessed object.
	throws_ok { Class::Simple::Cached->new(cache => []) }
		qr/Cache must be ref to HASH or object/,
		'constructor: cache => [] (arrayref) croaks';
	done_testing();
};

subtest 'constructor:cache-coderef' => sub {
	throws_ok { Class::Simple::Cached->new(cache => sub {}) }
		qr/Cache must be ref to HASH or object/,
		'constructor: cache => sub{} (coderef) croaks';
	done_testing();
};

subtest 'constructor:cache-scalar-ref' => sub {
	my $x = 42;
	throws_ok { Class::Simple::Cached->new(cache => \$x) }
		qr/Cache must be ref to HASH or object/,
		'constructor: cache => \\scalar (scalar ref) croaks';
	done_testing();
};

subtest 'constructor:cache-glob-ref' => sub {
	throws_ok { Class::Simple::Cached->new(cache => \*STDOUT) }
		qr/Cache must be ref to HASH or object/,
		'constructor: cache => \\*STDOUT (typeglob ref) croaks';
	done_testing();
};

subtest 'constructor:cache-blessed-missing-get' => sub {
	{
		package t::EC::NoGet;
		sub new { bless {}, shift }; sub set {}; sub purge {};
	}
	throws_ok { Class::Simple::Cached->new(cache => t::EC::NoGet->new()) }
		qr/Cache object must implement/,
		'constructor: blessed cache missing get() is rejected';
	done_testing();
};

subtest 'constructor:cache-blessed-missing-set' => sub {
	{
		package t::EC::NoSet;
		sub new { bless {}, shift }; sub get {}; sub purge {};
	}
	throws_ok { Class::Simple::Cached->new(cache => t::EC::NoSet->new()) }
		qr/Cache object must implement/,
		'constructor: blessed cache missing set() is rejected';
	done_testing();
};

subtest 'constructor:cache-blessed-missing-purge' => sub {
	{
		package t::EC::NoPurge;
		sub new { bless {}, shift }; sub get {}; sub set {};
	}
	throws_ok { Class::Simple::Cached->new(cache => t::EC::NoPurge->new()) }
		qr/Cache object must implement/,
		'constructor: blessed cache missing purge() is rejected';
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION B — Security: internal field injection
#
# Strategy: attempt to smuggle _is_hash_cache and _cache_prefix into both
# the fresh-new and clone construction paths.  The security invariant
# unconditionally recalculates both fields after every argument merge, so
# injection must always fail.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'security:new-is-hash-cache-injection' => sub {
	# Attack: pass a valid CHI object plus _is_hash_cache => 1 to trick CSC
	# into using the faster hash-ref path on an object that has no {} interface.
	# If the injection worked, _cache_set would write $cache->{$key} on a
	# blessed object (crash).  The recalculation must neutralise this.
	my $obj = Class::Simple::Cached->new(
		cache          => t::EC::FullCHI->new(),
		_is_hash_cache => 1,				# injection attempt
	);
	# The recalculation stores ref(blessed_obj) eq 'HASH' = '' (false string), not 0.
	# Use ok(!...) rather than is(..., 0) so both '' and 0 pass as "falsy = neutralised".
	ok(!$obj->{'_is_hash_cache'},
		'security:new: _is_hash_cache => 1 injection neutralised (recalculated to falsy)');
	done_testing();
};

subtest 'security:new-cache-prefix-injection' => sub {
	# Attack: inject _cache_prefix => '' to widen the DESTROY scope to ALL
	# keys in the shared hash (index($k, '') == 0 is always true), enabling
	# cross-class data erasure.  Recalculation must overwrite the injected value.
	my $obj = Class::Simple::Cached->new(
		cache         => {},
		_cache_prefix => '',				# injection attempt
	);
	is($obj->{'_cache_prefix'}, $PREFIX,
		'security:new: _cache_prefix => "" injection neutralised (recalculated to class prefix)');
	done_testing();
};

subtest 'security:clone-is-hash-cache-injection' => sub {
	# Attack: clone a hash-ref-backed object while injecting _is_hash_cache => 0
	# to force the CHI dispatch path.  Without the invariant, subsequent get()
	# calls on the plain hash ref would die ("Can't call method 'get' on HASH").
	my $base  = Class::Simple::Cached->new(cache => {});
	my $clone = $base->new(_is_hash_cache => 0);		# injection attempt

	is($clone->{'_is_hash_cache'}, 1,
		'security:clone: _is_hash_cache => 0 injection neutralised (hash ref stays hash-ref path)');

	$clone->field('works');
	is($clone->field(), 'works',
		'security:clone: cloned instance still operates correctly after injection attempt');
	done_testing();
};

subtest 'security:clone-cache-prefix-injection' => sub {
	# Attack: inject _cache_prefix => '' via the clone path to cause DESTROY
	# to delete every key in a shared hash (all keys match the empty prefix).
	my $base  = Class::Simple::Cached->new(cache => {});
	my $clone = $base->new(_cache_prefix => '');		# injection attempt

	is($clone->{'_cache_prefix'}, $PREFIX,
		'security:clone: _cache_prefix => "" injection neutralised (prefix always recalculated)');
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION C — Clone path validation (bug fix regression)
#
# Strategy: pass invalid cache values to the clone constructor.  Before the
# fix, all of these created an object that crashed on first method call.
# After the fix they must croak at construction time, matching new() behaviour.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'clone-validation:cache-undef' => sub {
	# Regression for the clone-path validation gap: $obj->new(cache => undef)
	# must croak, not silently create an object that dies on use.
	my $base = Class::Simple::Cached->new(cache => {});
	throws_ok { $base->new(cache => undef) }
		qr/Cache must be ref to HASH or object/,
		'clone-validation: cache => undef croaks at construction, not on first method call';
	done_testing();
};

subtest 'clone-validation:cache-invalid-ref' => sub {
	my $base = Class::Simple::Cached->new(cache => {});
	throws_ok { $base->new(cache => []) }
		qr/Cache must be ref to HASH or object/,
		'clone-validation: cache => [] croaks at construction';
	done_testing();
};

subtest 'clone-validation:cache-blessed-without-methods' => sub {
	my $base = Class::Simple::Cached->new(cache => {});
	throws_ok { $base->new(cache => t::EC::NoPurge->new()) }
		qr/Cache object must implement/,
		'clone-validation: blessed cache missing purge() croaks at construction';
	done_testing();
};

subtest 'clone-validation:valid-new-cache-accepted' => sub {
	# Ensure the validation does not break the common case: cloning with a
	# different but valid cache backend.
	my $base  = Class::Simple::Cached->new(cache => {});
	my $clone = $base->new(cache => {});		# different but valid hash ref
	$clone->colour('blue');
	is($clone->colour(), 'blue',
		'clone-validation: clone with valid new hash-ref cache operates correctly');
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION D — Getter boundary: falsy and sentinel values
#
# Strategy: verify the documented "falsy values are not cached" limitation
# and the sentinel-collision limitation without working around them in the
# tests — they are intended behaviour the caller must be aware of.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'boundary:falsy-zero-never-cached' => sub {
	# Major Premise: the cache-hit guard is if($rc) (truthiness check).
	# Minor Premise: 0 is falsy.
	# Conclusion: a method returning 0 is a cache miss every call, even after
	# the setter stores 0 in the cache.
	my $inner = t::EC::Inner->new();
	my %store;
	my $obj   = Class::Simple::Cached->new(cache => \%store, object => $inner);

	$obj->counter(0);				# setter stores 0

	is($store{"${PREFIX}counter"}, 0,
		'boundary:falsy-0: setter DOES write 0 to cache');

	my $before = $inner->calls('counter');
	$obj->counter();				# getter: 0 is falsy → cache miss
	$obj->counter();				# getter: still a miss
	is($inner->calls('counter'), $before + 2,
		'boundary:falsy-0: getter re-calls inner object every time (0 never a cache hit)');

	done_testing();
};

subtest 'boundary:falsy-empty-string-never-cached' => sub {
	my $inner = t::EC::Inner->new();
	my $obj   = Class::Simple::Cached->new(cache => {}, object => $inner);

	$obj->label('');
	my $before = $inner->calls('label');
	$obj->label();
	$obj->label();
	is($inner->calls('label'), $before + 2,
		'boundary:falsy-"": empty string treated as cache miss every call');
	done_testing();
};

subtest 'boundary:falsy-string-zero-never-cached' => sub {
	my $inner = t::EC::Inner->new();
	my $obj   = Class::Simple::Cached->new(cache => {}, object => $inner);

	$obj->flag('0');
	my $before = $inner->calls('flag');
	$obj->flag();
	$obj->flag();
	is($inner->calls('flag'), $before + 2,
		'boundary:falsy-"0": string "0" treated as cache miss every call');
	done_testing();
};

subtest 'boundary:sentinel-collision-limitation' => sub {
	# DOCUMENTED LIMITATION: if the inner object returns the literal string
	# UNDEF_SENTINEL as a genuine value, the getter decodes it as undef.
	# This test verifies the known failure mode so regressions are caught.
	my $inner = t::EC::SentinelReturner->new();
	my %store;
	my $obj   = Class::Simple::Cached->new(cache => \%store, object => $inner);

	# First call (cache miss): inner returns the sentinel string.
	# CSC stores it as-is (it IS defined), then returns $val directly.
	# So the FIRST call correctly returns the sentinel string.
	my $v1 = $obj->val();
	is($v1, $SENTINEL,
		'boundary:sentinel-collision: first call (miss) returns the sentinel string as a real value');

	# Second call (cache hit): the stored sentinel is decoded as undef — false positive.
	my $v2 = $obj->val();
	ok(!defined($v2),
		'boundary:sentinel-collision: second call (hit) misidentifies sentinel as cached undef (known limitation)');

	diag sprintf('[sentinel-collision] stored=%s v1=%s v2=%s',
		$store{"${PREFIX}val"} // 'undef',
		defined($v1) ? $v1 : 'undef',
		defined($v2) ? $v2 : 'undef') if $ENV{TEST_VERBOSE};

	done_testing();
};

subtest 'boundary:array-sentinel-croak' => sub {
	# When the inner object returns a list whose first element is the sentinel,
	# the cache-hit path croaks with the method name as the error message.
	my $inner = t::EC::ArraySentinelReturner->new();
	my $obj   = Class::Simple::Cached->new(cache => {}, object => $inner);

	my @first = $obj->items();		# cache miss: stores arrayref including sentinel

	diag sprintf('[array-sentinel] first call: [%s]', join(', ', @first))
		if $ENV{TEST_VERBOSE};

	throws_ok { $obj->items() }
		qr/\bitems\b/,
		'boundary:array-sentinel: getter croaks with method name when cached array[0] is sentinel';
	done_testing();
};

subtest 'boundary:setter-explicit-undef' => sub {
	# Calling $obj->method(undef) is a scalar setter whose argument is undef.
	# The inner object is called with undef; if it returns undef, UNDEF_SENTINEL
	# is stored.  The getter then returns undef without re-calling the inner object.
	my $inner = t::EC::Inner->new();
	my %store;
	my $obj   = Class::Simple::Cached->new(cache => \%store, object => $inner);

	my $ret = $obj->value(undef);
	ok(!defined($ret), 'boundary:setter-undef: setter returns undef when inner returns undef');

	is($store{"${PREFIX}value"}, $SENTINEL,
		'boundary:setter-undef: UNDEF_SENTINEL written to cache after undef setter');

	my $before = $inner->calls('value');
	my $got    = $obj->value();
	ok(!defined($got), 'boundary:setter-undef: getter returns undef (decoded from sentinel)');
	is($inner->calls('value'), $before,
		'boundary:setter-undef: getter does NOT re-invoke inner (sentinel is a valid cache hit)');
	done_testing();
};

subtest 'boundary:scalar-getter-returning-arrayref-limitation' => sub {
	# STRUCTURAL LIMITATION: if the inner object's scalar-context getter returns
	# an arrayref, the first call (cache miss) returns the arrayref correctly.
	# The second call (cache hit) hits the arrayref branch in AUTOLOAD and
	# returns @{$rc} — which in scalar context gives the element count (3),
	# not the arrayref.  This limitation arises because the cache cannot
	# distinguish "list cached as arrayref" from "scalar cached as arrayref".
	# This test documents the miss-path behaviour only.
	my $inner = t::EC::ArrayRefGetter->new();
	my $obj   = Class::Simple::Cached->new(cache => {}, object => $inner);

	my $v1 = $obj->items();
	is(ref($v1), 'ARRAY',
		'boundary:arrayref-limitation: cache miss returns the arrayref correctly');

	# The cache hit path (v2) is NOT asserted here because it returns 3 (length)
	# instead of the arrayref.  That discrepancy is the documented limitation.
	diag '[arrayref-limitation] first call (miss) returns arrayref; second call (hit) would return 3'
		if $ENV{TEST_VERBOSE};

	done_testing();
};

subtest 'boundary:large-value-round-trip' => sub {
	# A 1 MB string must cache and retrieve without truncation or corruption.
	my $obj = Class::Simple::Cached->new(cache => {}, object => t::EC::Inner->new());
	$obj->blob($LARGE_VAL);
	my $got = $obj->blob();
	is(length($got), length($LARGE_VAL),
		'boundary:large-value: 1 MB string retrieved from cache at correct length');
	is($got, $LARGE_VAL,
		'boundary:large-value: 1 MB string matches byte-for-byte after cache round-trip');
	done_testing();
};

subtest 'boundary:long-method-name' => sub {
	# A 10 KB method name forms a ~10 KB cache key.  This must not crash CSC
	# even though it is pathological; the inner object stores and retrieves it.
	my $inner = t::EC::Inner->new();
	my %store;
	my $obj   = Class::Simple::Cached->new(cache => \%store, object => $inner);

	$obj->$LONG_NAME('present');

	ok(exists $store{"${PREFIX}${LONG_NAME}"},
		'boundary:long-method-name: 10 KB method name is used as cache key without crash');
	is($store{"${PREFIX}${LONG_NAME}"}, 'present',
		'boundary:long-method-name: correct value stored under 10 KB key');

	is($obj->$LONG_NAME(), 'present',
		'boundary:long-method-name: getter retrieves value from 10 KB key');
	done_testing();
};

subtest 'boundary:circular-reference-in-cache' => sub {
	# The inner object may return a circular reference.  CSC stores the reference
	# and DESTROY must not loop (it only deletes hash keys, never traverses values).
	my $inner = do {
		package t::EC::CircularReturner;
		sub new { bless {}, shift }
		sub node { my $n = {}; $n->{self} = $n; return $n }
		sub DESTROY {}
		t::EC::CircularReturner->new();
	};
	my %store;
	my $obj = Class::Simple::Cached->new(cache => \%store, object => $inner);

	my $v1 = $obj->node();				# cache miss: stores circular ref
	my $v2 = $obj->node();				# cache hit: returns same ref

	is(ref($v1), 'HASH', 'boundary:circular-ref: returns a reference');
	is($v1->{self}, $v1,  'boundary:circular-ref: the reference is genuinely circular');
	is($v1, $v2,          'boundary:circular-ref: cache hit returns the same reference');

	$obj = undef;					# DESTROY with circular value in cache
	pass('boundary:circular-ref: DESTROY does not infinite-loop on circular cache values');
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION E — Upstream failure simulation
#
# Strategy: make the inner object or cache backend die at each call site and
# verify that CSC propagates the error without corrupting cache state.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'upstream:inner-getter-dies' => sub {
	# When the inner object's getter dies, the error propagates from AUTOLOAD.
	# The cache must NOT be written — only the inner call precedes the write.
	my %store;
	my $obj = Class::Simple::Cached->new(
		cache  => \%store,
		object => t::EC::DyingGetter->new(),
	);

	throws_ok { $obj->value() }
		qr/upstream get failure/,
		'upstream:inner-getter-dies: exception propagates from AUTOLOAD getter path';

	ok(!exists $store{"${PREFIX}value"},
		'upstream:inner-getter-dies: cache NOT written when inner getter dies');
	done_testing();
};

subtest 'upstream:inner-setter-dies' => sub {
	# When the inner object's setter dies the error propagates.
	# The cache write is downstream of the inner call so it is NOT reached.
	my %store;
	my $obj = Class::Simple::Cached->new(
		cache  => \%store,
		object => t::EC::DyingSetter->new(),
	);

	throws_ok { $obj->value('anything') }
		qr/upstream set failure/,
		'upstream:inner-setter-dies: exception propagates from AUTOLOAD setter path';

	ok(!exists $store{"${PREFIX}value"},
		'upstream:inner-setter-dies: cache NOT written when inner setter dies');
	done_testing();
};

subtest 'upstream:chi-get-dies' => sub {
	# A broken CHI backend whose get() dies causes the getter to die.
	# The error propagates from _cache_get through AUTOLOAD to the caller.
	my $obj = Class::Simple::Cached->new(
		cache  => t::EC::DyingGet->new(),
		object => t::EC::Inner->new(),
	);

	throws_ok { $obj->name() }
		qr/cache get\(\) failed/,
		'upstream:chi-get-dies: CHI get() failure propagates from getter';
	done_testing();
};

subtest 'upstream:chi-set-dies-from-setter' => sub {
	# CHI set() dies after the inner object has already been called.
	# The inner object's value IS stored internally; the cache is NOT persisted.
	my $inner = t::EC::Inner->new();
	my $chi   = t::EC::DyingSet->new();
	my $obj   = Class::Simple::Cached->new(cache => $chi, object => $inner);

	throws_ok { $obj->name('test') }
		qr/cache set\(\) failed/,
		'upstream:chi-set-dies-setter: CHI set() failure propagates from setter';

	is($inner->calls('name'), 1,
		'upstream:chi-set-dies-setter: inner object WAS called (set() failure is post-inner)');
	ok(!exists $chi->{store}{"${PREFIX}name"},
		'upstream:chi-set-dies-setter: value NOT persisted in CHI after set() failure');
	done_testing();
};

subtest 'upstream:chi-set-dies-from-getter-cache-miss' => sub {
	# CHI set() dies when the getter tries to persist a fresh value.
	# The inner object's getter IS called (returning a correct value),
	# but the cache write fails so subsequent calls re-invoke the inner object.
	my $inner = t::EC::Inner->new();
	$inner->name('hello');				# prime inner store directly (count = 1)
	my $obj = Class::Simple::Cached->new(
		cache  => t::EC::DyingSet->new(),
		object => $inner,
	);

	# Record the call count after priming, before the CSC getter runs.
	my $before = $inner->calls('name');

	throws_ok { $obj->name() }
		qr/cache set\(\) failed/,
		'upstream:chi-set-dies-getter-miss: CHI set() failure propagates on cache-miss getter path';

	is($inner->calls('name'), $before + 1,
		'upstream:chi-set-dies-getter-miss: inner object called exactly once by CSC getter (before set() failure)');
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION F — DESTROY edge cases
#
# Strategy: verify DESTROY behaves correctly under unusual cache-field states.
# On Perl 5.14+, exceptions from DESTROY are silently swallowed (confirmed
# empirically on this runtime), so a dying purge() does not propagate.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'destroy:no-cache-field' => sub {
	# Manual tampering: remove the cache field from the blessed hash.
	# DESTROY guards with `$self->{'cache'} or return`, so it must return early.
	my $obj = Class::Simple::Cached->new(cache => {}, object => t::EC::Inner->new());
	$obj->{'cache'} = undef;		# tamper with internals

	my $ok = eval { $obj = undef; 1 };	# DESTROY fires
	ok($ok, 'destroy:no-cache: DESTROY with missing cache field does not crash the caller');
	done_testing();
};

subtest 'destroy:empty-hash-cache' => sub {
	# DESTROY with an empty hash-ref cache must succeed (grep finds nothing).
	my %store;
	my $obj = Class::Simple::Cached->new(cache => \%store, object => t::EC::Inner->new());
	$obj = undef;					# DESTROY fires
	pass('destroy:empty-hash: DESTROY on empty hash-ref cache does not crash');
	is(scalar(keys %store), 0, 'destroy:empty-hash: empty hash stays empty after DESTROY');
	done_testing();
};

subtest 'destroy:mass-entries-cleared' => sub {
	# Write 500 distinct cache entries then verify DESTROY removes all of them.
	Readonly::Scalar my $N => 500;
	my %store;
	my $obj = Class::Simple::Cached->new(cache => \%store, object => t::EC::Inner->new());

	for my $i (1 .. $N) {
		my $m = "method_${i}";
		$obj->$m("value_$i");
	}
	is(scalar(keys %store), $N, "destroy:mass: $N entries in cache before DESTROY");

	$obj = undef;
	is(scalar(keys %store), 0, "destroy:mass: all $N entries cleared by DESTROY");
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION G — Global state preservation
#
# Strategy: assert that no CSC public method clobbers $_, $@, or $!.
# These checks guard against hidden eval{} calls or unlocalized loop variables.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'global-state:dollar-underscore' => sub {
	# Any use of $_ inside CSC without localising it would clobber the caller's
	# loop variable.  Set $_ to a sentinel, exercise every public method, verify.
	my $obj = Class::Simple::Cached->new(cache => {}, object => t::EC::Inner->new());

	local $_ = 'must-survive';
	$obj->name('test');		# setter
	$obj->name();			# getter (hit)
	$obj->new();			# clone
	$obj->can('name');
	$obj->isa('Class::Simple::Cached');

	is($_, 'must-survive', 'global-state:$_: not clobbered by any CSC method');
	done_testing();
};

subtest 'global-state:dollar-at' => sub {
	# If CSC uses eval{} internally without saving/restoring $@, a caller's
	# pending exception is silently discarded.
	my $obj = Class::Simple::Cached->new(cache => {}, object => t::EC::Inner->new());

	eval { die "pre-existing\n" };
	my $saved = $@;

	$obj->name('test');
	$obj->name();
	$obj->can('name');
	$obj->isa('UNIVERSAL');

	is($@, $saved, 'global-state:$@: not clobbered by CSC methods');
	done_testing();
};

subtest 'global-state:dollar-bang' => sub {
	# CSC should not trigger any syscalls that change errno.
	my $obj = Class::Simple::Cached->new(cache => {}, object => t::EC::Inner->new());

	local $! = ENOENT;
	my $saved = $! + 0;

	$obj->name('test');
	$obj->name();

	is($! + 0, $saved, 'global-state:$!: errno not changed by CSC methods');
	done_testing();
};

SKIP: {
	skip 'alarm() not functional on this platform', 1
		unless eval { alarm(30); alarm(0) > 0 };
	subtest 'global-state:alarm-not-cancelled' => sub {
		# If CSC called alarm() internally it would silently cancel the caller's
		# countdown timer.  Verify by setting a long alarm, exercising CSC, then
		# reading back the remaining time.
		my $obj = Class::Simple::Cached->new(cache => {}, object => t::EC::Inner->new());

		my $prev = alarm(30);		# set a 30-second countdown
		$obj->name('test');
		$obj->name();
		my $remaining = alarm(0);	# cancel and read

		ok($remaining > 0,
			'global-state:alarm: CSC does not cancel the caller\'s alarm() timer');

		alarm($prev);			# restore whatever was there before
		done_testing();
	};
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION H — can() and isa() hostile inputs
#
# Strategy: probe the guard clauses added to can() and isa() for undef inputs.
# Both methods must return a defined-but-false value without emitting warnings.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'can:undef-method-no-warning' => sub {
	# Regression for: can(undef) previously emitted "uninitialized value" warnings
	# from the $method eq 'new' comparison.  Now guarded by `return unless defined`.
	my $obj = Class::Simple::Cached->new(cache => {}, object => t::EC::Inner->new());

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result = $obj->can(undef);

	ok(!defined($result) || !$result,
		'can(undef): returns false/undef without dying');
	is(scalar(@warnings), 0,
		'can(undef): no "uninitialized value" warnings emitted');
	done_testing();
};

subtest 'can:empty-string' => sub {
	my $obj = Class::Simple::Cached->new(cache => {}, object => t::EC::Inner->new());
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, @_ };
	my $r = $obj->can('');
	is(scalar(@warn), 0, 'can(""): no warnings emitted');
	done_testing();
};

subtest 'isa:undef-class-no-warning' => sub {
	# Regression for: isa(undef) emitted "uninitialized value" warnings.
	my $obj = Class::Simple::Cached->new(cache => {}, object => t::EC::Inner->new());

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result = $obj->isa(undef);

	ok(!defined($result) || !$result,
		'isa(undef): returns false/undef without dying');
	is(scalar(@warnings), 0,
		'isa(undef): no "uninitialized value" warnings emitted');
	done_testing();
};

subtest 'isa:empty-string' => sub {
	my $obj = Class::Simple::Cached->new(cache => {}, object => t::EC::Inner->new());
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, @_ };
	my $r = $obj->isa('');
	is(scalar(@warn), 0, 'isa(""): no warnings emitted');
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION I — Structural edge cases
#
# Strategy: test unusual structural configurations that stress assumptions
# in the caching design (double-wrapping, stale cache, void context).
# ═══════════════════════════════════════════════════════════════════════════

subtest 'structural:csc-wrapping-csc' => sub {
	# An outer CSC wraps an inner CSC.  Values must propagate correctly through
	# both cache layers; the outer cache hit must avoid calling the inner CSC.
	my %inner_store;
	my $inner_obj = t::EC::Inner->new();
	my $inner_csc = Class::Simple::Cached->new(
		cache  => \%inner_store,
		object => $inner_obj,
	);
	my %outer_store;
	my $outer_csc = Class::Simple::Cached->new(
		cache  => \%outer_store,
		object => $inner_csc,
	);

	$outer_csc->val('layered');

	is($outer_csc->val(), 'layered',
		'structural:csc-wraps-csc: value retrieved from outer cache on second call');

	# Both caches must be populated after the first getter call.
	ok(exists $outer_store{"${PREFIX}val"},
		'structural:csc-wraps-csc: outer cache has the entry');
	ok(exists $inner_store{"${PREFIX}val"},
		'structural:csc-wraps-csc: inner CSC cache also populated');

	# Third call must use only the outer cache — inner_obj NOT re-invoked.
	my $before = $inner_obj->calls('val');
	$outer_csc->val();
	is($inner_obj->calls('val'), $before,
		'structural:csc-wraps-csc: outer cache hit does not touch inner object');
	done_testing();
};

subtest 'structural:stale-cache-after-direct-mutation' => sub {
	# CSC explicitly does NOT maintain cache coherency if the inner object is
	# mutated through a path other than the CSC wrapper.  This is documented
	# in the module POD.  The test verifies that the stale cached value IS
	# returned — not the mutated one — so that this limitation cannot silently
	# disappear in a future refactor.
	my $inner = t::EC::Inner->new();
	my $obj   = Class::Simple::Cached->new(cache => {}, object => $inner);

	$obj->status('original');		# warms cache via wrapper
	$inner->status('mutated');		# bypasses wrapper → cache is now stale

	is($obj->status(), 'original',
		'structural:stale-cache: CSC returns cached (stale) value; direct mutation is invisible');
	done_testing();
};

subtest 'structural:getter-in-void-context' => sub {
	# A getter called in void context uses the scalar path (wantarray is undef,
	# which is falsy).  The value IS fetched and cached even though the return
	# value is discarded.  The next scalar-context call must be a cache hit.
	my $inner = t::EC::Inner->new();
	my $obj   = Class::Simple::Cached->new(cache => {}, object => $inner);
	$inner->phase('void');			# prime inner object directly

	$obj->phase();				# void context: triggers scalar cache-miss path

	my $before = $inner->calls('phase');
	my $got    = $obj->phase();		# scalar context: must be a cache hit now
	is($got, 'void', 'structural:void-context: value cached from void-context call');
	is($inner->calls('phase'), $before,
		'structural:void-context: subsequent scalar getter is a cache hit');
	done_testing();
};

subtest 'structural:object-falsy-default' => sub {
	# object => 0 and object => undef are falsy, so the ||= guard replaces them
	# with a fresh Class::Simple instance.  This matches the "defaults to a bare
	# Class::Simple instance" guarantee in the POD.
	my $obj_zero  = Class::Simple::Cached->new(cache => {}, object => 0);
	my $obj_undef = Class::Simple::Cached->new(cache => {}, object => undef);

	is(ref($obj_zero->{'object'}),  'Class::Simple',
		'structural:object-falsy: object => 0 silently replaced by Class::Simple');
	is(ref($obj_undef->{'object'}), 'Class::Simple',
		'structural:object-falsy: object => undef silently replaced by Class::Simple');
	done_testing();
};

done_testing();
