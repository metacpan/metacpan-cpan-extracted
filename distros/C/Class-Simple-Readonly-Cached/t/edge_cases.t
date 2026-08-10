#!/usr/bin/env perl

=head1 NAME

t/edge_cases.t - Destructive, boundary-condition, and security subtests for
Class::Simple::Readonly::Cached.

=head1 DESCRIPTION

Actively tries to break or subvert the module using pathological inputs,
hostile inner objects, dying cache backends, key-collision exploits, and
global-variable poisoning.  Where a correct test exposed a bug, the fix is
applied to the module and a regression guard is included here.

BUG FIX (regression guard in section 4):
  AUTOLOAD did not localize C<$_>.  An inner object method that mutated C<$_>
  would corrupt the caller's C<$_> after the method returned.  Fixed by adding
  C<local $_;> at the top of AUTOLOAD.

=cut

BEGIN { $ENV{HARNESS_ACTIVE} ||= 1 }

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Test::Mockingbird;
use Readonly;
use Scalar::Util qw(blessed refaddr weaken);
use overload ();

use_ok('Class::Simple::Readonly::Cached');

# ===========================================================================
# Inline mock packages
# ===========================================================================

# Standard inner object used where behavior doesn't matter.
package EdgeTest::Inner;
use strict;
use warnings;
sub new   { bless { _n => {} }, shift }
sub ping  { my ($self) = @_; $self->{_n}{ping}++; 'pong' }
sub echo  { my ($self, $v) = @_; $self->{_n}{echo}++; $v }
sub ncalls { my ($self, $m) = @_; $self->{_n}{$m} // 0 }

# Inner object that modifies $_ as a side effect.
# Used to verify that AUTOLOAD now localizes $_ (regression guard).
package EdgeTest::MutatesUnderscore;
use strict;
use warnings;
sub new    { bless {}, shift }
sub mutate { $_ = 'CORRUPTED_BY_INNER'; return 'result_value' }
sub list   { $_ = 'CORRUPTED_LIST';  return ('item_a', 'item_b') }

# Inner object that throws various exception types.
package EdgeTest::ThrowsString;
use strict;
use warnings;
sub new  { bless {}, shift }
sub boom { die "STRING_EXCEPTION\n" }

package EdgeTest::ThrowsHash;
use strict;
use warnings;
sub new  { bless {}, shift }
sub boom { die { code => 500, reason => 'HASH_EXCEPTION' } }

package EdgeTest::ThrowsObject;
use strict;
use warnings;
sub new       { bless {}, shift }
sub boom      { die bless { msg => 'OBJECT_EXCEPTION' }, 'EdgeTest::Exception' }

# Inner object that returns falsy-but-defined scalar values.
package EdgeTest::FalsyReturner;
use strict;
use warnings;
sub new         { bless {}, shift }
sub zero        { 0 }
sub empty_str   { '' }
sub zero_str    { '0' }

# Inner object returning a blessed object in a list (fixate must be skipped).
package EdgeTest::BlessedListReturner;
use strict;
use warnings;
sub new          { bless {}, shift }
sub blessed_list { (bless({}, 'SomeObj'), 'plain') }

# Inner object with a self-referential circular structure.
package EdgeTest::CircularSelf;
use strict;
use warnings;
sub new  { my $o = bless {}, shift; $o->{self} = $o; $o }
sub ping { 'pong' }

# Partial and wholly-broken CHI-compatible cache backends.
package EdgeTest::HasGetOnly;
use strict; use warnings;
sub new { bless {}, shift }
sub get { undef }

package EdgeTest::HasGetSet;
use strict; use warnings;
sub new { bless {}, shift }
sub get { undef }
sub set { return }

package EdgeTest::DyingGet;
use strict; use warnings;
sub new   { bless {}, shift }
sub get   { die "UPSTREAM_TIMEOUT: get() failed\n" }
sub set   { return }
sub purge { return }

package EdgeTest::DyingSet;
use strict; use warnings;
sub new   { bless {}, shift }
sub get   { undef }
sub set   { die "ENOSPC: disk full\n" }
sub purge { return }

# Overloaded-stringify object: used as a method argument to probe cache
# key construction with non-plain-scalar values.
package EdgeTest::StringyArg;
use strict; use warnings;
use overload q("") => sub { "OVERLOADED::${$_[0]}" }, fallback => 1;
sub new { my $n = 99; bless \$n, shift }

# Inner whose method accepts an overloaded arg -- we need the inner NOT to
# re-stringify it (just return it) so the test stays focused on the key.
package EdgeTest::ArgMirror;
use strict; use warnings;
sub new   { bless {}, shift }
sub probe { my ($self, @a) = @_; scalar @a }   # returns arg count

package main;

Readonly::Scalar my $W        => 'Class::Simple::Readonly::Cached';
Readonly::Scalar my $SENTINEL => 'Class::Simple::Readonly::Cached>UNDEF<';
Readonly::Scalar my $LARGE_N  => 1_000;
Readonly::Scalar my $LONG_ARG => 'x' x 65_536;

# ===========================================================================
# SECTION 1: Constructor hostile inputs
#
# t/carp.t already covers undef-cache, scalar-ref-cache, arrayref-cache,
# scalar-object, and double-wrap.  These subtests cover the remaining
# partitions: coderef cache, GLOB-ref cache, partially-compliant CHI objects,
# and circular-reference inner objects.
# ===========================================================================

subtest 'new(): coderef as cache croaks with "Cache must be ref to HASH or object"' => sub {
	# A coderef is a ref but NOT a HASH ref and NOT a blessed object.
	# The validation guard must reject it.
	throws_ok {
		$W->new(cache => sub { 1 }, object => EdgeTest::Inner->new())
	} qr/Cache must be ref to HASH or object/,
		'coderef cache: croak with the expected message';
};

subtest 'new(): GLOB ref as cache croaks' => sub {
	throws_ok {
		$W->new(cache => \*STDOUT, object => EdgeTest::Inner->new())
	} qr/Cache must be ref to HASH or object/,
		'GLOB ref cache: croak with the expected message';
};

subtest 'new(): blessed object with only get() croaks (missing set and purge)' => sub {
	throws_ok {
		$W->new(cache => EdgeTest::HasGetOnly->new(), object => EdgeTest::Inner->new())
	} qr/Cache object must implement get\(\), set\(\), and purge\(\)/,
		'HasGetOnly: croak mentioning the full required API';
};

subtest 'new(): blessed object with only get() and set() croaks (missing purge)' => sub {
	throws_ok {
		$W->new(cache => EdgeTest::HasGetSet->new(), object => EdgeTest::Inner->new())
	} qr/Cache object must implement get\(\), set\(\), and purge\(\)/,
		'HasGetSet: croak mentioning the full required API';
};

subtest 'new(): circular-reference inner object is accepted (valid ref)' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = EdgeTest::CircularSelf->new();
	my $cached = $W->new(cache => {}, object => $inner);

	ok($cached, 'circular-ref inner object is a valid ref -- wrapper created');
	is($cached->ping(), 'pong', 'method call through wrapper reaches circular inner');
};

# ===========================================================================
# SECTION 2: Cache key edge cases
#
# Strategy: call the same method with inputs that the key-construction code
# might conflate, verify the cache hash to see which keys were created.
# ===========================================================================

subtest 'cache key: empty-string arg "" collides with zero-arg call (known limitation)' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = EdgeTest::Inner->new();
	my $c      = {};
	my $cached = $W->new(cache => $c, object => $inner);

	# grep { defined } filters nothing (empty string IS defined).
	# join('::', "") = "" -- appending "" to the base key leaves it unchanged.
	# So method("") and method() produce the exact same key.
	$cached->echo();     # no-arg miss
	$cached->echo('');   # empty-string "miss" -- but key is IDENTICAL to no-arg!

	my @keys = grep { /echo/ } keys %$c;
	is(scalar @keys, 1,
		'echo("") and echo() collapse to one cache entry (documented limitation)');

	is($inner->ncalls('echo'), 1,
		'inner called once: echo("") hit the entry cached by echo()');
};

subtest 'cache key: "0" arg produces a DISTINCT key from no-arg' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = EdgeTest::Inner->new();
	my $c      = {};
	my $cached = $W->new(cache => $c, object => $inner);

	$cached->echo();    # no-arg
	$cached->echo(0);   # arg is 0 (defined, non-empty after stringification)

	my @echo_keys = grep { /echo/ } keys %$c;
	is(scalar @echo_keys, 2,
		'echo() and echo(0) produce two distinct cache entries');

	my $no_arg_key = "${W}::echo::";
	my $zero_key   = "${W}::echo::0";
	ok(exists $c->{$no_arg_key}, 'zero-arg key exists');
	ok(exists $c->{$zero_key},   '"0" arg key exists');
};

subtest 'cache key: "0E0" and "0 but true" are preserved as distinct keys' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $c      = {};
	my $cached = $W->new(cache => $c, object => EdgeTest::Inner->new());

	$cached->echo('0E0');
	$cached->echo('0 but true');

	ok(exists $c->{"${W}::echo::0E0"},      '"0E0" key stored');
	ok(exists $c->{"${W}::echo::0 but true"}, '"0 but true" key stored');
	isnt($c->{"${W}::echo::0E0"}, $c->{"${W}::echo::0 but true"},
		'two distinct entries');
};

subtest 'cache key: very long argument (64 KiB) accepted without corruption' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = EdgeTest::Inner->new();
	my $cached = $W->new(cache => {}, object => $inner);

	my $r1 = $cached->echo($LONG_ARG);
	is($r1, $LONG_ARG, '64 KiB arg: first call returns value unchanged');

	my $r2 = $cached->echo($LONG_ARG);
	is($r2, $LONG_ARG, '64 KiB arg: second call returns cached value unchanged');
	is($inner->ncalls('echo'), 1, 'inner called once (cache hit on second call)');
};

subtest 'cache key: overloaded-stringify object as arg uses its string form' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $c      = {};
	my $arg    = EdgeTest::StringyArg->new();
	my $cached = $W->new(cache => $c, object => EdgeTest::ArgMirror->new());

	$cached->probe($arg);

	# The arg is stringified by join() inside the key construction.
	# The overloaded "" operator returns "OVERLOADED::99".
	my @keys = grep { /probe.*OVERLOADED/ } keys %$c;
	is(scalar @keys, 1, 'overloaded-stringify arg is stringified in the cache key');
	like($keys[0], qr/OVERLOADED::99/, 'key contains the overloaded string form');
};

# ===========================================================================
# SECTION 3: Exception propagation through AUTOLOAD
#
# AUTOLOAD must not swallow or transform exceptions thrown by the inner object.
# A caller that wraps a call in eval{} must receive the original exception
# structure, whether it is a string, a hash-ref, or a blessed object.
# ===========================================================================

subtest 'exception: string die from inner object propagates unchanged' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::ThrowsString->new());

	my $caught = '';
	eval { $cached->boom(); 1 } or do { $caught = $@ };

	like($caught, qr/STRING_EXCEPTION/, 'string exception text preserved');
};

subtest 'exception: hash-ref die from inner object propagates as a hash-ref' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::ThrowsHash->new());

	my $caught;
	eval { $cached->boom(); 1 } or do { $caught = $@ };

	ok(ref($caught) eq 'HASH',        'exception is still a HASH ref');
	is($caught->{code},   500,         'exception code preserved');
	is($caught->{reason}, 'HASH_EXCEPTION', 'exception reason preserved');
};

subtest 'exception: blessed exception object propagates with class intact' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::ThrowsObject->new());

	my $caught;
	eval { $cached->boom(); 1 } or do { $caught = $@ };

	ok(blessed($caught) && $caught->isa('EdgeTest::Exception'),
		'blessed exception class is preserved');
	is($caught->{msg}, 'OBJECT_EXCEPTION', 'blessed exception payload preserved');
};

subtest 'exception: nothing is cached after an inner object exception' => sub {
	# If the inner call throws, the key must NOT be stored in the cache.
	# A subsequent call must re-invoke the inner object (another miss), not
	# silently return undef or a corrupt cached value.
	local %Class::Simple::Readonly::Cached::cached;

	my $c      = {};
	my $cached = $W->new(cache => $c, object => EdgeTest::ThrowsString->new());

	eval { $cached->boom() };   # first call -- inner dies

	my @cached_keys = grep { /boom/ } keys %$c;
	is(scalar @cached_keys, 0, 'no cache entry created when inner object throws');
};

# ===========================================================================
# SECTION 4: Global variable preservation ($_ regression guard)
#
# AUTOLOAD must localize $_ so that side effects inside the inner object's
# method do not corrupt the caller's $_.
#
# Bug: AUTOLOAD did not contain "local $_".  An inner method that set $_ to
# any value would leak that assignment back to the caller's scope.
# Fix: added "local $_;" at the top of AUTOLOAD (see lib/...Cached.pm).
# ===========================================================================

subtest 'REGRESSION: $_ is preserved after scalar-context method call' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::MutatesUnderscore->new());

	local $_ = 'caller_value';
	my $result = $cached->mutate();   # inner method sets $_ = 'CORRUPTED_BY_INNER'

	is($result, 'result_value', 'result returned correctly');
	is($_, 'caller_value',
		'REGRESSION: $_ not corrupted after inner method mutates it (local $_ in AUTOLOAD)');
};

subtest 'REGRESSION: $_ is preserved after list-context method call' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::MutatesUnderscore->new());

	local $_ = 'caller_list_value';
	my @result = $cached->list();   # inner method sets $_ = 'CORRUPTED_LIST'

	is_deeply(\@result, ['item_a', 'item_b'], 'list result correct');
	is($_, 'caller_list_value',
		'REGRESSION: $_ not corrupted after inner list-context method mutates it');
};

subtest 'REGRESSION: $_ is preserved even when result is served from cache (hit)' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = EdgeTest::MutatesUnderscore->new();
	my $cached = $W->new(cache => {}, object => $inner);

	$cached->mutate();   # prime the cache (miss)

	local $_ = 'before_hit';
	$cached->mutate();   # cache hit -- no inner call, but $_ should still be safe

	is($_, 'before_hit', '$_ unchanged on cache hit (local $_ covers the hit path too)');
};

# ===========================================================================
# SECTION 5: Falsy-but-defined return values
#
# The module uses `if(!defined($result))` to detect undef.  It must NOT treat
# 0, "0", or "" as undef -- those are valid return values that must be cached
# and returned correctly.
# ===========================================================================

subtest 'falsy returns: 0 is cached and returned correctly' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = EdgeTest::FalsyReturner->new();
	my $cached = $W->new(cache => {}, object => $inner);

	my $r1 = $cached->zero();
	is($r1, 0, 'first call: 0 returned');
	is(defined($r1) && $r1 == 0, 1, 'returned value is defined 0, not undef');

	my $r2 = $cached->zero();
	is($r2, 0, 'second call (cache hit): 0 returned');

	my $s = $cached->state;
	is($s->{misses}{"${W}::zero::"}, 1, '1 miss');
	is($s->{hits}{"${W}::zero::"},   1, '1 hit');
};

subtest 'falsy returns: "" (empty string) is cached and returned correctly' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::FalsyReturner->new());

	my $r1 = $cached->empty_str();
	is($r1, '',        'first call: "" returned');
	ok(defined($r1),   'empty string is defined');

	my $r2 = $cached->empty_str();
	is($r2, '',        'second call (cache hit): "" returned');

	my $s = $cached->state;
	is($s->{misses}{"${W}::empty_str::"}, 1, '1 miss');
	is($s->{hits}{"${W}::empty_str::"},   1, '1 hit');
};

subtest 'falsy returns: "0" (string zero) is cached correctly' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::FalsyReturner->new());

	my $r1 = $cached->zero_str();
	is($r1, '0', 'first call: "0" returned');

	my $r2 = $cached->zero_str();
	is($r2, '0', 'second call: "0" returned from cache');

	my $s = $cached->state;
	is($s->{hits}{"${W}::zero_str::"}, 1, '1 hit');
};

# ===========================================================================
# SECTION 6: Hostile cache backends (dying get/set via mock or inline class)
#
# The module must propagate exceptions from backend operations to the caller
# rather than silently swallowing them.
# ===========================================================================

subtest 'CHI backend: get() die propagates to caller' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = EdgeTest::Inner->new();
	my $cached = $W->new(cache => EdgeTest::DyingGet->new(), object => $inner);

	my $caught = '';
	eval { $cached->ping() } or $caught = $@;

	like($caught, qr/UPSTREAM_TIMEOUT.*get\(\) failed/,
		'get() exception propagates to the caller unchanged');
};

subtest 'CHI backend: set() die propagates to caller' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = EdgeTest::Inner->new();
	my $cached = $W->new(cache => EdgeTest::DyingSet->new(), object => $inner);

	my $caught = '';
	eval { $cached->ping() } or $caught = $@;

	like($caught, qr/ENOSPC.*disk full/,
		'set() exception propagates to the caller unchanged');
};

subtest 'CHI backend: Test::Mockingbird spy confirms set() called once per miss' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	clear_call_log();

	# Use an inline minimal cache with a spied set() to count calls precisely.
	package EdgeTest::SpyableCache;
	use strict; use warnings;
	sub new   { bless { _s => {} }, shift }
	sub get   { $_[0]->{_s}{ $_[1] } }
	sub set   { $_[0]->{_s}{ $_[1] } = $_[2]; return }
	sub purge { $_[0]->{_s} = {}; return }

	package main;
	my $spy    = spy 'EdgeTest::SpyableCache::set';
	my $inner  = EdgeTest::Inner->new();
	my $chi    = EdgeTest::SpyableCache->new();
	my $cached = $W->new(cache => $chi, object => $inner);

	$cached->ping();   # miss
	$cached->ping();   # hit
	$cached->ping();   # hit

	my @calls   = $spy->();
	restore_all();

	is(scalar @calls, 1, 'set() called exactly once across 1 miss + 2 hits');
	# The first argument after $self is the cache key.
	like($calls[0][2], qr/::ping::$/, 'set() was called with the ping cache key');
};

# ===========================================================================
# SECTION 7: can() and isa() with hostile arguments
#
# Both methods must not die (though they may warn) when passed undef or
# other degenerate values.  Warnings are suppressed here so the test
# focuses on the no-die guarantee.
# ===========================================================================

subtest 'can(undef): survives without dying (may warn)' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::Inner->new());
	my $result;

	# Suppress the "uninitialized value" warnings we know are emitted.
	local $SIG{__WARN__} = sub { };
	lives_ok { $result = $cached->can(undef) }
		'can(undef) does not die';
	ok(!$result, 'can(undef) returns a false value (undef method does not exist)');
};

subtest 'isa(undef): survives without dying (may warn)' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::Inner->new());
	my $result;

	local $SIG{__WARN__} = sub { };
	lives_ok { $result = $cached->isa(undef) }
		'isa(undef) does not die';
};

subtest 'isa("UNIVERSAL"): returns true for any object' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::Inner->new());
	ok($cached->isa('UNIVERSAL'), 'isa("UNIVERSAL") is true (every object is-a UNIVERSAL)');
};

subtest 'isa(empty string): survives without dying' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => EdgeTest::Inner->new());

	local $SIG{__WARN__} = sub { };
	lives_ok { $cached->isa('') } 'isa("") does not die';
};

# ===========================================================================
# SECTION 8: Void context method dispatch
#
# wantarray() returns undef in void context.  AUTOLOAD uses $wantlist to
# decide between the list and scalar paths.  A falsy $wantlist follows the
# scalar path, which is correct.  Verify no crash and correct cache behavior.
# ===========================================================================

subtest 'void context: method call in void context does not crash' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = EdgeTest::Inner->new();
	my $cached = $W->new(cache => {}, object => $inner);

	lives_ok { $cached->ping() } 'void-context call does not die';
	lives_ok { $cached->ping() } 'second void-context call (hit) does not die';

	my $s = $cached->state;
	is($s->{misses}{"${W}::ping::"}, 1, '1 miss in void context');
	is($s->{hits}{"${W}::ping::"},   1, '1 hit in void context');
};

# ===========================================================================
# SECTION 9: UNDEF_SENTINEL spoofing (security / key-collision boundary)
#
# If an inner object returns exactly the sentinel string, the hit path
# confuses it with a cached-undef entry and silently returns undef.
# Documented as a known bug (tracked as TODO in t/cgi_security.t).
# Tested here as a regression boundary: the symptom must not silently
# worsen into a crash.
# ===========================================================================

subtest 'UNDEF_SENTINEL spoofing: no crash even when the bug triggers' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	# Inner object that returns the exact sentinel string.
	package EdgeTest::SentinelReturner;
	use strict; use warnings;
	sub new   { bless {}, shift }
	sub probe { 'Class::Simple::Readonly::Cached>UNDEF<' }

	package main;

	my $cached = $W->new(cache => {}, object => EdgeTest::SentinelReturner->new());

	my $first = $cached->probe();

	TODO: {
		local $TODO = 'KNOWN BUG: hit path confuses sentinel string with cached-undef -- fix by wrapping stored values in an opaque blessed struct';
		is($first, 'Class::Simple::Readonly::Cached>UNDEF<',
			'first call (miss): sentinel string returned correctly');

		my $second = $cached->probe();
		is($second, 'Class::Simple::Readonly::Cached>UNDEF<',
			'second call (hit): sentinel string should survive hit path unchanged');
	}

	# Regardless of the bug: the module must not die or crash.
	lives_ok { $cached->probe() } 'UNDEF_SENTINEL spoofing does not crash the program';
};

# ===========================================================================
# SECTION 10: Cache flooding stress test
#
# Populate the cache with many distinct entries.  Verify that no entries
# are silently lost or corrupted, and that the state() counters are correct.
# ===========================================================================

subtest "cache flooding: $LARGE_N distinct keys without corruption" => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = EdgeTest::Inner->new();
	my $cached = $W->new(cache => {}, object => $inner);

	# Populate $LARGE_N distinct cache entries.
	for my $i (0 .. $LARGE_N - 1) {
		$cached->echo("key_$i");
	}

	# Re-hit every entry to verify the cache serves them all correctly.
	my $corrupted = 0;
	for my $i (0 .. $LARGE_N - 1) {
		my $got = $cached->echo("key_$i");
		$corrupted++ unless defined $got && $got eq "key_$i";
	}

	is($corrupted, 0, "all $LARGE_N cache entries served correctly on hit");

	my $s = $cached->state;
	my $total_hits = do { my $n = 0; $n += $_ for values %{ $s->{hits} // {} }; $n };
	is($total_hits, $LARGE_N, "$LARGE_N cache hits counted");
};

# ===========================================================================
# SECTION 11: fixate() is skipped when list contains a blessed object
#
# _can_fixate() guards Data::Reuse::fixate against blessed objects (RT#100461).
# Verify end-to-end that calling a method that returns a list containing a
# blessed object does NOT crash and still caches the result correctly.
# ===========================================================================

subtest 'list with blessed object: fixate skipped, result cached correctly' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	clear_call_log();

	my $spy    = spy 'Data::Reuse::fixate';
	my $inner  = EdgeTest::BlessedListReturner->new();
	my $cached = $W->new(cache => {}, object => $inner);

	my @first  = $cached->blessed_list();
	my $fixate_calls = scalar($spy->());
	restore_all();

	is($fixate_calls, 0,
		'fixate() NOT called when list contains a blessed object (RT#100461 guard)');
	is(scalar @first, 2, 'list returned with correct element count');
	ok(blessed($first[0]) && $first[0]->isa('SomeObj'),
		'blessed object element preserved in result');
	is($first[1], 'plain', 'plain string element preserved');
};

done_testing;
