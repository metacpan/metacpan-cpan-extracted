#!/usr/bin/env perl

=head1 NAME

t/function.t - White-box tests for internal helpers and data-structure
invariants of Class::Simple::Readonly::Cached.

=head1 DESCRIPTION

Tests the private helpers (_can_fixate, _build_cache_accessors), verifies
the internal fields set by new() and AUTOLOAD, checks that closures do not
create circular references, and uses Test::Mockingbird spies to verify
correct delegation to Data::Reuse::fixate.

Sub::Private enforcement is disabled when $ENV{HARNESS_ACTIVE} is set (the
normal prove/make-test environment).  The BEGIN block below ensures the flag
is set when this file is run directly as well.

=cut

use strict;
use warnings;

# Ensure Sub::Private white-box access both under prove and direct execution.
BEGIN { $ENV{HARNESS_ACTIVE} ||= 1 }

use Test::Most;
use Test::Returns;
use Test::Mockingbird;
use Test::Memory::Cycle;
use Readonly;
use Class::Simple::Readonly::Cached;

# ===========================================================================
# Inline mock packages
# ===========================================================================

# Minimal inner object for exercising different return-type paths.
package FuncTest::Inner;
use strict;
use warnings;
sub new          { bless {}, shift }
sub noop         { 'noop_result' }
sub echo         { $_[1] }
sub list_method  { ('alpha', 'beta') }

# Inner object whose method returns a blessed object in a list (unsafe for
# fixate -- see RT#100461).  Used to verify _can_fixate gating.
package FuncTest::InnerBlessedList;
use strict;
use warnings;
sub new         { bless {}, shift }
sub mixed_list  { (bless({}, 'SomeBlessed'), 'plain') }

# CHI-like cache that records every call to set() so we can inspect the
# expiry argument passed by the _set closure.
package FuncTest::ChiLike;
use strict;
use warnings;
sub new   { bless { _s => {}, _calls => [] }, shift }
sub get   { $_[0]->{_s}{ $_[1] } }
sub set   {
	my ($self, $key, $val, $expiry) = @_;
	push @{ $self->{_calls} }, { key => $key, val => $val, expiry => $expiry };
	$self->{_s}{$key} = $val;
	return;
}
sub purge { my $self = shift; $self->{_s} = {}; $self->{_calls} = []; return }

package main;

Readonly::Scalar my $W        => 'Class::Simple::Readonly::Cached';
Readonly::Scalar my $I        => 'FuncTest::Inner';
Readonly::Scalar my $SENTINEL => 'Class::Simple::Readonly::Cached>UNDEF<';
Readonly::Scalar my $CHI_NEVER => 'never';

# Shorthand wrappers so call sites read cleanly.
sub _can_fixate              { Class::Simple::Readonly::Cached::_can_fixate(@_) }
sub _build_cache_accessors   { Class::Simple::Readonly::Cached::_build_cache_accessors(@_) }

# ===========================================================================
# _can_fixate -- exhaustive equivalence partitions
#
# Purpose: verify every input class that the function distinguishes.  The
# function gates Data::Reuse::fixate; a wrong answer either wastes a fixate
# call (safe, no crash) or -- for GLOBs and blessed refs -- would crash
# fixate (RT#100461, RT#163955).
# ===========================================================================

subtest '_can_fixate: empty list is safe (trivially, none iterates zero times)' => sub {
	ok(_can_fixate(), 'empty list returns true');
};

subtest '_can_fixate: plain scalars (strings, numbers, undef) are safe' => sub {
	ok(_can_fixate('string'),        'single string: safe');
	ok(_can_fixate(0, '', undef),    'false-y scalars including undef: safe');
	ok(_can_fixate(1, 2, 3, 'a'),   'multiple plain scalars: safe');
};

subtest '_can_fixate: unblessed container refs are safe' => sub {
	ok(_can_fixate([]),              'unblessed ARRAY ref: safe');
	ok(_can_fixate({}),              'unblessed HASH ref: safe');
	ok(_can_fixate(\1),              'unblessed SCALAR ref: safe');
	ok(_can_fixate([], {}, \1),      'mixed unblessed refs: safe');
};

subtest '_can_fixate: blessed objects are NOT safe (RT#100461)' => sub {
	# Data::Reuse::fixate cannot handle blessed refs; calling it on them
	# triggers a fatal error.  _can_fixate must return false for any blessed ref.
	ok(!_can_fixate(bless({}, 'Any')),
		'blessed HASH ref: not safe');
	ok(!_can_fixate(bless([], 'Any')),
		'blessed ARRAY ref: not safe');
	ok(!_can_fixate('safe', bless({}, 'Any')),
		'mixed list containing a blessed ref: not safe');
};

subtest '_can_fixate: GLOBs are NOT safe (RT#163955)' => sub {
	ok(!_can_fixate(\*STDOUT),
		'GLOB ref: not safe');
	ok(!_can_fixate('safe', \*STDERR),
		'mixed list containing a GLOB: not safe');
};

subtest '_can_fixate: does not clobber $_ (List::Util::none localizes it)' => sub {
	# Verify that the iterator's implicit use of $_ inside the none{} block
	# does not leak out to the caller.
	local $_ = 'do_not_touch';
	_can_fixate('a', 'b', bless({}, 'X'));   # mix of safe and unsafe values
	is($_, 'do_not_touch', '$_ is unchanged after _can_fixate returns');
};

# ===========================================================================
# _build_cache_accessors -- hash backend
#
# Purpose: verify the closures are installed with correct types, that they
# perform actual reads and writes against the cache (not $self), and that
# they correctly set _cache_is_hash.
# ===========================================================================

subtest '_build_cache_accessors (hash): sets _cache_is_hash=1, _get, _set' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cache = {};
	my $self  = bless { cache => $cache, _class => $W }, $W;

	_build_cache_accessors($self);

	is($self->{_cache_is_hash}, 1, '_cache_is_hash set to 1 for hash backend');
	returns_is($self->{_get}, { type => 'coderef' }, '_get is a coderef');
	returns_is($self->{_set}, { type => 'coderef' }, '_set is a coderef');
};

subtest '_build_cache_accessors (hash): _get and _set operate on the cache hash' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cache = {};
	my $self  = bless { cache => $cache, _class => $W }, $W;
	_build_cache_accessors($self);

	$self->{_set}->('the_key', 'the_val');

	is($cache->{the_key}, 'the_val',
		'_set writes to the captured cache hash');
	is($self->{_get}->('the_key'), 'the_val',
		'_get reads back from the same hash');
	is($self->{_get}->('absent'), undef,
		'_get returns undef for a key that was never set');
};

subtest '_build_cache_accessors (hash): closure captures cache ref, not $self' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cache = {};
	my $self  = bless { cache => $cache, _class => $W }, $W;
	_build_cache_accessors($self);

	# memory_cycle_ok verifies no $self -> closure -> $self cycle.
	# If _get/$set closed over $self instead of $c, Devel::Cycle would flag it.
	memory_cycle_ok($self,
		'hash backend: closures do not create a circular reference back to $self');
};

# ===========================================================================
# _build_cache_accessors -- CHI backend
# ===========================================================================

subtest '_build_cache_accessors (CHI): sets _cache_is_hash=0, _get, _set' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $chi  = FuncTest::ChiLike->new();
	my $self = bless { cache => $chi, _class => $W }, $W;
	_build_cache_accessors($self);

	is($self->{_cache_is_hash}, 0, '_cache_is_hash set to 0 for CHI backend');
	returns_is($self->{_get}, { type => 'coderef' }, '_get is a coderef');
	returns_is($self->{_set}, { type => 'coderef' }, '_set is a coderef');
};

subtest '_build_cache_accessors (CHI): _get/_set delegate to the cache object' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $chi  = FuncTest::ChiLike->new();
	my $self = bless { cache => $chi, _class => $W }, $W;
	_build_cache_accessors($self);

	$self->{_set}->('chi_k', 'chi_v');
	is($self->{_get}->('chi_k'), 'chi_v',
		'_get returns what _set stored via the CHI object');
};

subtest '_build_cache_accessors (CHI): _set passes "never" as the expiry argument' => sub {
	# The $CHI_NEVER Readonly constant ('never') must be the third argument to
	# $cache->set().  Inspect the recorded call on FuncTest::ChiLike.
	local %Class::Simple::Readonly::Cached::cached;
	my $chi  = FuncTest::ChiLike->new();
	my $self = bless { cache => $chi, _class => $W }, $W;
	_build_cache_accessors($self);

	$self->{_set}->('k', 'v');

	my $recorded = $chi->{_calls}[0];
	is($recorded->{key},    'k',        'CHI set: correct key forwarded');
	is($recorded->{val},    'v',        'CHI set: correct value forwarded');
	is($recorded->{expiry}, $CHI_NEVER, 'CHI set: expiry is "never" ($CHI_NEVER constant)');
};

subtest '_build_cache_accessors (CHI): closure does not create a cycle' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $chi  = FuncTest::ChiLike->new();
	my $self = bless { cache => $chi, _class => $W }, $W;
	_build_cache_accessors($self);

	memory_cycle_ok($self,
		'CHI backend: closures do not create a circular reference back to $self');
};

# ===========================================================================
# Internal invariants after new()
# White-box: inspect the blessed hashref fields that the public API never
# exposes but that every AUTOLOAD dispatch depends on.
# ===========================================================================

subtest 'new(): _class field is pre-computed from ref($self)' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cached = $W->new(cache => {}, object => $I->new());

	is($cached->{_class}, $W,
		'_class equals the class name string');
	is($cached->{_class}, ref($cached),
		'_class equals ref($self) -- no per-dispatch ref() call needed');
};

subtest 'new(): _cache_is_hash reflects backend type' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $hash_w = $W->new(cache => {}, object => $I->new());
	is($hash_w->{_cache_is_hash}, 1, 'hash backend: _cache_is_hash = 1');

	local %Class::Simple::Readonly::Cached::cached;
	my $chi_w  = $W->new(cache => FuncTest::ChiLike->new(), object => $I->new());
	is($chi_w->{_cache_is_hash}, 0, 'CHI backend: _cache_is_hash = 0');
};

subtest 'new(): %cached registry entry has object, file, and line fields' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $inner  = $I->new();
	my $cached = $W->new(cache => {}, object => $inner);

	my $entry = $Class::Simple::Readonly::Cached::cached{$inner};
	ok(defined $entry,
		'inner object reference is a key in %cached');
	is($entry->{object}, $cached,
		'entry->{object} is the wrapper');
	ok(defined $entry->{file},
		'entry->{file} is set');
	like($entry->{line}, qr/^\d+$/,
		'entry->{line} is a positive integer');
};

# ===========================================================================
# Memory cycles -- the complete wrapper object graph
# ===========================================================================

subtest 'memory_cycle_ok: hash-backend wrapper has no circular references' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cached = $W->new(cache => {}, object => $I->new());
	memory_cycle_ok($cached, 'hash-backend wrapper: no cycles');
};

subtest 'memory_cycle_ok: CHI-backend wrapper has no circular references' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cached = $W->new(cache => FuncTest::ChiLike->new(), object => $I->new());
	memory_cycle_ok($cached, 'CHI-backend wrapper: no cycles');
};

# ===========================================================================
# Cache key format (white-box)
# The key is:  _class . '::' . method . '::' [. join('::', @defined_args)]
# Inspecting the cache hash directly confirms the exact byte sequence.
# ===========================================================================

subtest 'cache key: zero args => "ClassName::method::"' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $c = {};
	my $w = $W->new(cache => $c, object => $I->new());

	$w->noop();

	ok(exists $c->{ $W . '::noop::' },
		'zero-arg key has the trailing :: separator with nothing after it');
};

subtest 'cache key: one defined arg => "ClassName::method::arg"' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $c = {};
	my $w = $W->new(cache => $c, object => $I->new());

	$w->echo('hello');

	ok(exists $c->{ $W . '::echo::hello' },
		'one-arg key: class :: method :: arg');
};

subtest 'cache key: multiple args joined with ::' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $c = {};
	my $w = $W->new(cache => $c, object => $I->new());

	$w->echo('a', 'b', 'c');

	ok(exists $c->{ $W . '::echo::a::b::c' },
		'multi-arg key: all args joined with ::');
};

subtest 'cache key: undef args are stripped from the key' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $c = {};
	my $w = $W->new(cache => $c, object => $I->new());

	$w->echo(undef, 'x', undef, 'y');   # two undef, two defined

	ok(exists $c->{ $W . '::echo::x::y' },
		'undef args are filtered; key contains only defined values');
	ok(!exists $c->{ $W . '::echo::x::y::' },
		'no trailing :: after final defined arg');
};

subtest 'cache key: undef-only args collapse to the zero-arg key' => sub {
	# Documented limitation: foo(undef) and foo() share a cache entry.
	local %Class::Simple::Readonly::Cached::cached;
	my $c = {};
	my $w = $W->new(cache => $c, object => $I->new());

	$w->echo(undef);

	ok(exists $c->{ $W . '::echo::' },
		'undef-only arg list produces the same key as a zero-arg call');
};

# ===========================================================================
# DESTROY edge cases
# ===========================================================================

subtest 'DESTROY: only deletes keys matching this instance\'s class prefix' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $c = {};
	my $w = $W->new(cache => $c, object => $I->new());
	$w->noop();   # plants key "...$W::noop::"

	# Simulate a key owned by a completely different class.
	$c->{'AnotherPkg::noop::'} = 'untouched';

	$w->DESTROY();

	ok(!exists $c->{ $W . '::noop::' },
		'DESTROY removes the instance\'s own key');
	is($c->{'AnotherPkg::noop::'}, 'untouched',
		'DESTROY does not touch keys belonging to other classes');
};

subtest 'DESTROY: survives when {cache} has been set to undef' => sub {
	# If application code nils out the cache field, the DESTROY guard
	# `if($cache)` must skip the clearing block rather than dying.
	local %Class::Simple::Readonly::Cached::cached;
	my $inner  = $I->new();
	my $cached = $W->new(cache => {}, object => $inner);

	$cached->{cache} = undef;   # white-box: null the cache field

	lives_ok { $cached->DESTROY() }
		'DESTROY does not die when {cache} is undef';
};

# ===========================================================================
# state() returns live references to _hits/_misses, not deep copies
# White-box: mutating the returned hash should be visible through the object.
# ===========================================================================

subtest 'state(): hits/misses are live refs -- mutation is reflected in the object' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cached = $W->new(cache => {}, object => $I->new());
	my $key    = $W . '::noop::';

	$cached->noop();   # one miss

	my $s = $cached->state();

	# Mutate via the returned reference: if $s->{misses} IS $self->{_misses}
	# (same ref), this mutation is visible through a fresh state() call.
	$s->{misses}{$key} = 999;

	is($cached->state()->{misses}{$key}, 999,
		'mutation through state() return value is visible via the object (live ref)');
};

# ===========================================================================
# List caching internals
# The list is stored as an ARRAY ref, never as a flat list.
# ===========================================================================

subtest 'AUTOLOAD: list result stored as ARRAY ref in the cache hash' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $c      = {};
	my $cached = $W->new(cache => $c, object => $I->new());
	my $key    = $W . '::list_method::';

	my @got = $cached->list_method();   # list context

	is(ref($c->{$key}), 'ARRAY',
		'list result stored as ARRAY ref (not a flat list)');
	is_deeply($c->{$key}, ['alpha', 'beta'],
		'stored array contains the correct elements in the correct order');
};

# ===========================================================================
# Data::Reuse::fixate integration
# AUTOLOAD calls fixate only for fixatable list results.  A spy on
# Data::Reuse::fixate confirms it is or is not called in each case.
# ===========================================================================

subtest 'AUTOLOAD: fixate() called for plain-scalar list result' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	clear_call_log();

	my $spy    = spy 'Data::Reuse::fixate';
	my $cached = $W->new(cache => {}, object => $I->new());
	my @result = $cached->list_method();   # returns ('alpha', 'beta') -- safe

	my $calls_after = scalar( $spy->() );
	restore_all();

	is($calls_after, 1,
		'fixate() called once for a fixatable (plain-scalar) list result');
};

subtest 'AUTOLOAD: fixate() NOT called when list contains a blessed object' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	clear_call_log();

	my $spy    = spy 'Data::Reuse::fixate';
	my $inner  = FuncTest::InnerBlessedList->new();
	my $cached = $W->new(cache => {}, object => $inner);
	my @result = $cached->mixed_list();    # returns (bless({},'SomeBlessed'), 'plain')

	my $calls_after = scalar( $spy->() );
	restore_all();

	is($calls_after, 0,
		'fixate() NOT called when _can_fixate returns false (blessed object in list)');
};

done_testing();
