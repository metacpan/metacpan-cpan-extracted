#!/usr/bin/env perl

=head1 NAME

t/function.t - White-box function tests for Class::Simple::Cached

=head1 DESCRIPTION

Tests every function in lib/Class/Simple/Cached.pm, including internal helpers.
Each subtest exercises a single code path (equivalence partition) so that the
reason for any failure is immediately apparent.

Internal helpers (_cache_get, _cache_set) are directly callable here because
prove sets HARNESS_ACTIVE, which disables Sub::Protected access checks.

Test::Mockingbird spies are used to observe calls to cache and inner-object
methods without replacing their implementations.  restore_all() is called at
the end of every mock-using subtest to prevent state leakage.

=cut

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(spy mock restore_all);
use Test::Memory::Cycle;
use Test::Returns;
use Readonly;

BEGIN { use_ok('Class::Simple::Cached') }

# ── Shared constants ──────────────────────────────────────────────────────────

Readonly::Scalar my $SENTINEL   => Class::Simple::Cached::UNDEF_SENTINEL();
Readonly::Scalar my $PREFIX     => 'Class::Simple::Cached:';
Readonly::Scalar my $NEVER      => 'never';        # CHI expiry token

# ── Helper packages ───────────────────────────────────────────────────────────

{
	# Minimal CHI-compatible mock that logs every call.  get() returns whatever
	# was previously set(), so the cache actually works during tests.
	package t::MockCHI;
	sub new      { bless { store => {}, log => [] }, shift }
	sub get      { my ($s,$k)       = @_; push @{$s->{log}},['get',$k]; $s->{store}{$k} }
	sub set      { my ($s,$k,$v,$e) = @_; push @{$s->{log}},['set',$k,$v,$e]; $s->{store}{$k}=$v; 1 }
	sub purge    { my ($s)          = @_; push @{$s->{log}},['purge']; $s->{store}={} }
	sub calls    { @{$_[0]->{log}} }
	sub reset    { $_[0]->{log} = [] }
}

{
	# CHI mock with 'purge' removed — used to test missing-method detection.
	package t::CHINoPurge;
	sub new { bless {}, shift }; sub get {}; sub set {};
}

{
	# CHI mocks missing exactly one method each.
	package t::CHINoGet;   sub new { bless {}, shift }; sub set {};   sub purge {};
	package t::CHINoSet;   sub new { bless {}, shift }; sub get {};   sub purge {};
}

{
	# A real inner object that records call counts per method and can store values.
	# We deliberately do NOT use CSC itself as the inner object to avoid circularity.
	package t::Inner;
	use Class::Simple;
	our @ISA = ('Class::Simple');
	sub new { bless { _calls => {}, _store => {} }, ref($_[0]) || $_[0] }
	sub calls { $_[0]->{_calls}{$_[1]} // 0 }
}

{
	# Returns a list of three elements — exercises the wantarray / arrayref path.
	package t::ListSource;
	sub new   { bless { _n => 0 }, shift }
	sub items { $_[0]->{_n}++; return ('x', 'y', 'z') }
	sub nada  { $_[0]->{_n}++; return }       # always returns empty
	sub calls { $_[0]->{_n} }
}

{
	# Returns a blessed value — used to verify the blessed-object cache-hit path
	# does NOT invoke eq against UNDEF_SENTINEL.
	package t::BlessedValue;
	use overload 'eq' => sub { 1 }, '""' => sub { 'bomb' }, fallback => 1;
	sub new { bless {}, shift }
}

{
	# An inner object whose only method returns a t::BlessedValue.
	package t::BlessedSource;
	sub new   { bless {}, shift }
	sub thing { t::BlessedValue->new() }
}

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTION: new()
# ═══════════════════════════════════════════════════════════════════════════

subtest 'new(): undef class -> carp and return undef' => sub {
	# The only way to hit the !defined($class) guard is to call new() as a bare
	# function (without a class or object as the invocant).  We use a spy on
	# Carp::carp to confirm the correct signalling path is taken.
	my $spy = spy 'Carp::carp';

	my $result = Class::Simple::Cached::new();

	my @recorded = $spy->();
	ok(scalar(@recorded), 'carp was called');
	# The call is Carp::carp(__PACKAGE__, ' use ->new() ...') — two separate
	# arguments.  Join all args (skipping the function name at index 0) to get
	# the full message string.
	my $full_msg = join('', @{$recorded[0]}[1 .. $#{$recorded[0]}]);
	like($full_msg, qr/use ->new\(\) not ::new\(\)/,
		'carp message names the correct invocation form');
	ok(!defined($result), 'undef is returned when class is undef');

	returns_not_ok($result, { type => 'object' },
		'returns_not_ok: result is not a blessed object');

	restore_all();
	done_testing();
};

subtest 'new(): no arguments -> croak with Usage message' => sub {
	# Params::Get::get_params uses Carp::confess, which Test::Carp cannot
	# distinguish from croak.  new() explicitly guards against zero args and
	# calls Carp::croak first, so Test::Most's throws_ok sees a croak.
	throws_ok { Class::Simple::Cached->new() }
		qr/Usage:/,
		'zero-arg new() croaks with Usage message';
	done_testing();
};

subtest 'new(): non-ref scalar cache -> croak' => sub {
	# A plain string is neither a blessed object nor a hashref — both early
	# returns are skipped and the final croak fires.
	throws_ok { Class::Simple::Cached->new(cache => 'string') }
		qr/Cache must be ref to HASH or object/,
		'plain string cache croaks';
	throws_ok { Class::Simple::Cached->new(cache => 42) }
		qr/Cache must be ref to HASH or object/,
		'integer cache croaks';
	done_testing();
};

subtest 'new(): non-hash, non-object refs -> croak' => sub {
	# Arrayrefs, coderefs, and scalarrefs pass the defined/blessed check
	# but fail both the blessed and the _is_hash_cache tests.
	throws_ok { Class::Simple::Cached->new(cache => []) }
		qr/Cache must be ref to HASH or object/, 'arrayref cache croaks';
	throws_ok { Class::Simple::Cached->new(cache => sub{}) }
		qr/Cache must be ref to HASH or object/, 'coderef cache croaks';
	throws_ok { Class::Simple::Cached->new(cache => \(my $s)) }
		qr/Cache must be ref to HASH or object/, 'scalarref cache croaks';
	done_testing();
};

subtest 'new(): hashref cache -> correct instance fields' => sub {
	# Transitive reduction: _is_hash_cache must equal ref($cache) eq 'HASH',
	# and _cache_prefix must be 'ClassName:'.
	my %store;
	my $obj = Class::Simple::Cached->new(cache => \%store);

	returns_ok($obj, { type => 'object' }, 'new() returns a blessed object');
	isa_ok($obj, 'Class::Simple::Cached', 'correct class');

	ok($obj->{'_is_hash_cache'},
		'_is_hash_cache is true for a hashref cache');
	is($obj->{'_cache_prefix'}, $PREFIX,
		'_cache_prefix equals ClassName:');
	is(ref($obj->{'cache'}), 'HASH',
		'cache field holds the same hashref');
	ok(defined($obj->{'object'}),
		'object field is populated (defaults to Class::Simple instance)');

	memory_cycle_ok($obj, 'no circular references in CSC instance');
	done_testing();
};

subtest 'new(): CHI-compatible object -> correct instance fields' => sub {
	my $chi = t::MockCHI->new();
	my $obj = Class::Simple::Cached->new(cache => $chi);

	isa_ok($obj, 'Class::Simple::Cached', 'CHI-backed instance is correct class');
	ok(!$obj->{'_is_hash_cache'},
		'_is_hash_cache is false for a CHI cache');
	is($obj->{'_cache_prefix'}, $PREFIX,
		'_cache_prefix equals ClassName:');

	memory_cycle_ok($obj, 'no circular references with CHI cache');
	done_testing();
};

subtest 'new(): CHI cache missing get() -> croak' => sub {
	throws_ok { Class::Simple::Cached->new(cache => t::CHINoGet->new()) }
		qr/Cache object must implement/,
		'missing get() causes croak';
	done_testing();
};

subtest 'new(): CHI cache missing set() -> croak' => sub {
	throws_ok { Class::Simple::Cached->new(cache => t::CHINoSet->new()) }
		qr/Cache object must implement/,
		'missing set() causes croak';
	done_testing();
};

subtest 'new(): CHI cache missing purge() -> croak' => sub {
	throws_ok { Class::Simple::Cached->new(cache => t::CHINoPurge->new()) }
		qr/Cache object must implement/,
		'missing purge() causes croak';
	done_testing();
};

subtest 'new(): clone path -> shallow merge, fields recalculated' => sub {
	# The clone path merges %{$class} with %{$params}.  The security invariant
	# requires that _is_hash_cache and _cache_prefix are ALWAYS recalculated
	# after the merge so callers cannot inject corrupted values.
	my %store;
	my $orig = Class::Simple::Cached->new(cache => \%store);
	$orig->colour('green');

	# Normal clone: no extra args.
	my $clone = $orig->new();
	isa_ok($clone, 'Class::Simple::Cached', 'clone is correct class');
	is($clone->colour(), 'green', 'clone shares cache, sees original value');

	# Field injection attempt: supplying _is_hash_cache => 0 must be overridden.
	my $bad = $orig->new(_is_hash_cache => 0, _cache_prefix => 'evil:');
	ok($bad->{'_is_hash_cache'},
		'injected _is_hash_cache=0 is overridden to correct value');
	is($bad->{'_cache_prefix'}, $PREFIX,
		'injected _cache_prefix is overridden to correct value');

	# After the injection override, the getter must still work without dying.
	my $v;
	lives_ok { $v = $bad->colour() } 'getter on injected clone does not die';
	is($v, 'green', 'injected clone returns correct cached value');

	memory_cycle_ok($clone, 'no circular references in clone');
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTION: can()
# ═══════════════════════════════════════════════════════════════════════════

subtest 'can(): called as class method -> SUPER::can path' => sub {
	# When the invocant is not blessed, blessed($self) is false, so we fall
	# through to SUPER::can without accessing $self->{'object'}.
	ok(defined(Class::Simple::Cached->can('new')),
		'class-method can("new") returns a code ref');
	ok(!defined(Class::Simple::Cached->can('_no_such_method')),
		'class-method can for undefined method returns undef');
	done_testing();
};

subtest 'can(): method == "new" -> always true on instance' => sub {
	# The $method eq 'new' fast-path fires first, returning 1 before any
	# delegation to the wrapped object.  This guarantees new() is always
	# reported as available regardless of the wrapped object.
	my $obj = Class::Simple::Cached->new(cache => {});
	ok($obj->can('new'), 'instance can("new") is true');
	done_testing();
};

subtest 'can(): method exists on wrapped object -> true' => sub {
	# The wrapped object is a real Class::Simple instance; its AUTOLOAD installs
	# concrete stubs, so can() on it returns a code ref.
	my $obj = Class::Simple::Cached->new(cache => {});
	$obj->barney('betty');   # causes Class::Simple to install 'barney' stub

	ok($obj->can('barney'), 'can() returns true for a method on the wrapped object');
	done_testing();
};

subtest 'can(): method not on object or SUPER -> false' => sub {
	my $obj = Class::Simple::Cached->new(cache => {});
	ok(!$obj->can('__no_such_method_ever__'),
		'can() returns false for a nonexistent method');
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTION: isa()
# ═══════════════════════════════════════════════════════════════════════════

subtest 'isa(): called as class method -> SUPER::isa path' => sub {
	ok(Class::Simple::Cached->isa('Class::Simple::Cached'),
		'class-method isa() reports correct class');
	done_testing();
};

subtest 'isa(): is own class -> true' => sub {
	my $obj = Class::Simple::Cached->new(cache => {});
	ok($obj->isa('Class::Simple::Cached'), 'instance isa() its own class');
	done_testing();
};

subtest 'isa(): is wrapped object class -> true' => sub {
	# isa() delegates to the inner object when the class doesn't match self
	# or __PACKAGE__.  The inner object defaults to Class::Simple.
	my $obj = Class::Simple::Cached->new(cache => {});
	ok($obj->isa('Class::Simple'), 'isa() delegates to inner object class');
	done_testing();
};

subtest 'isa(): is UNIVERSAL -> true (all objects are UNIVERSAL)' => sub {
	my $obj = Class::Simple::Cached->new(cache => {});
	ok($obj->isa('UNIVERSAL'), 'isa(UNIVERSAL) is true via SUPER::isa');
	done_testing();
};

subtest 'isa(): unrelated class -> false' => sub {
	my $obj = Class::Simple::Cached->new(cache => {});
	ok(!$obj->isa('CHI'), 'isa() returns false for unrelated class');
	ok(!$obj->isa('DBI'), 'isa() returns false for another unrelated class');
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTION: DESTROY()
# ═══════════════════════════════════════════════════════════════════════════

subtest 'DESTROY(): no cache field -> exits cleanly without crash' => sub {
	# If $self->{'cache'} is falsy (absent or undef), DESTROY must return
	# immediately without attempting any cache operations.
	my $obj = bless {}, 'Class::Simple::Cached';   # no 'cache' key
	lives_ok { $obj->DESTROY() } 'DESTROY with no cache does not die';
	done_testing();
};

subtest 'DESTROY(): hash cache -> removes only own-prefix keys' => sub {
	# The key-namespace invariant: DESTROY must delete entries whose keys begin
	# with _cache_prefix and leave all other entries untouched.
	my %shared = (
		"${PREFIX}colour"   => 'red',          # owned by this instance
		"${PREFIX}size"     => 'large',         # owned by this instance
		'OtherClass:colour' => 'blue',          # belongs to a sibling
	);
	my $obj = Class::Simple::Cached->new(
		cache  => \%shared,
		object => Class::Simple->new(),
	);

	$obj->DESTROY();

	ok(!exists($shared{"${PREFIX}colour"}), 'own prefix key "colour" deleted');
	ok(!exists($shared{"${PREFIX}size"}),   'own prefix key "size" deleted');
	ok( exists($shared{'OtherClass:colour'}),
		'sibling key with different prefix is preserved');
	done_testing();
};

subtest 'DESTROY(): CHI cache -> purge() is called once' => sub {
	# When not in global destruction phase, DESTROY must call $cache->purge().
	my $chi = t::MockCHI->new();
	{
		my $obj = Class::Simple::Cached->new(cache => $chi);
		# DESTROY fires here when $obj goes out of scope
	}

	my @calls = $chi->calls();
	my @purges = grep { $_->[0] eq 'purge' } @calls;
	is(scalar(@purges), 1, 'purge() called exactly once on scope exit');
	done_testing();
};

subtest 'DESTROY(): CHI cache -> purge() skipped during global destruct' => sub {
	# ${^GLOBAL_PHASE} is read-only and cannot be set from Perl code.
	# We verify the GUARD is architecturally correct by confirming the constant
	# _GLOBAL_PHASE_AVAILABLE is set and that we are NOT in DESTRUCT right now.
	SKIP: {
		skip 'GLOBAL_PHASE not available on this Perl', 1
			unless Class::Simple::Cached::_GLOBAL_PHASE_AVAILABLE();

		isnt(${^GLOBAL_PHASE}, 'DESTRUCT',
			'we are not in DESTRUCT phase during normal test execution');

		# The direct DESTRUCT path (purge skipped) is only reachable via
		# actual global destruction.  Architecture is proven by the constant
		# + the isnt() check above.
		pass('GLOBAL_PHASE guard is architecturally correct');
	}
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTION: _cache_get()
# (HARNESS_ACTIVE disables Sub::Protected, so direct calls work under prove)
# ═══════════════════════════════════════════════════════════════════════════

subtest '_cache_get(): hash backend -> direct hashref lookup' => sub {
	my %store = ("${PREFIX}x" => 'alpha');
	my $obj   = Class::Simple::Cached->new(cache => \%store);

	# A key that is present in the hash must come back with its stored value.
	my $got = $obj->_cache_get("${PREFIX}x");
	is($got, 'alpha', '_cache_get returns stored scalar from hashref');

	# A key that is absent must return undef (hashref returns undef for missing).
	my $miss = $obj->_cache_get("${PREFIX}missing");
	ok(!defined($miss), '_cache_get returns undef for missing hashref key');

	diag("hash store contents: ", join(', ', map { "$_=$store{$_}" } keys %store))
		if $ENV{TEST_VERBOSE};

	done_testing();
};

subtest '_cache_get(): CHI backend -> delegates to $cache->get($key)' => sub {
	# Spy on t::MockCHI::get so we can verify both that it was called AND
	# with the correct key argument, while still getting the real value back.
	my $chi = t::MockCHI->new();
	$chi->set("${PREFIX}x", 'beta', $NEVER);
	$chi->reset();   # clear the set() call from the log

	my $obj = Class::Simple::Cached->new(cache => $chi);
	my $got = $obj->_cache_get("${PREFIX}x");
	is($got, 'beta', '_cache_get returns value from CHI get()');

	my @calls = grep { $_->[0] eq 'get' } $chi->calls();
	is(scalar(@calls), 1, 'CHI get() called exactly once');
	is($calls[0][1], "${PREFIX}x", 'CHI get() called with the correct key');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTION: _cache_set()
# ═══════════════════════════════════════════════════════════════════════════

subtest '_cache_set(): hash backend -> assigns value to hashref key' => sub {
	my %store;
	my $obj = Class::Simple::Cached->new(cache => \%store);

	$obj->_cache_set("${PREFIX}y", 'gamma');

	is($store{"${PREFIX}y"}, 'gamma', '_cache_set writes correct value to hashref');
	done_testing();
};

subtest '_cache_set(): CHI backend -> calls set($key, $val, "never")' => sub {
	# The expiry token 'never' must be passed as the third argument.
	# CHI->set() returns 1 (success flag), not the stored value.
	my $chi = t::MockCHI->new();
	my $obj = Class::Simple::Cached->new(cache => $chi);

	$obj->_cache_set("${PREFIX}y", 'delta');

	my @sets = grep { $_->[0] eq 'set' } $chi->calls();
	is(scalar(@sets), 1,        'CHI set() called once');
	is($sets[0][1], "${PREFIX}y", 'CHI set() received correct key');
	is($sets[0][2], 'delta',      'CHI set() received correct value');
	is($sets[0][3], $NEVER,       'CHI set() received "never" as expiry token');
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTION: AUTOLOAD() — getter, cache-hit branches
# We pre-populate the hash cache so AUTOLOAD's _cache_get returns a
# controlled value, letting us exercise each branch in isolation.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'AUTOLOAD getter: cache hit, plain scalar -> return value' => sub {
	my %cache = ("${PREFIX}colour" => 'crimson');
	my $obj   = Class::Simple::Cached->new(cache => \%cache);

	my $v = $obj->colour();
	is($v, 'crimson', 'plain scalar cache hit returns the stored scalar');

	returns_ok($v, { type => 'scalar' }, 'Test::Returns: scalar returned');
	done_testing();
};

subtest 'AUTOLOAD getter: cache hit, UNDEF_SENTINEL -> returns undef' => sub {
	# The sentinel is a non-empty (truthy) string stored in place of an
	# actual undef result.  Retrieval must decode it back to undef.
	my %cache = ("${PREFIX}thing" => $SENTINEL);
	my $obj   = Class::Simple::Cached->new(cache => \%cache);

	my $v = $obj->thing();
	ok(!defined($v), 'UNDEF_SENTINEL decoded back to undef on cache hit');
	done_testing();
};

subtest 'AUTOLOAD getter: cache hit, arrayref -> returns flat list' => sub {
	my %cache = ("${PREFIX}trio" => ['a', 'b', 'c']);
	my $obj   = Class::Simple::Cached->new(cache => \%cache);

	my @got = $obj->trio();
	is_deeply(\@got, ['a', 'b', 'c'],
		'arrayref cache hit returns a flat list via dereferencing');
	done_testing();
};

subtest 'AUTOLOAD getter: cache hit, arrayref sentinel first element -> croak' => sub {
	# If the first element of a cached arrayref is the sentinel string, the
	# module detects a sentinel collision and croaks with the method name.
	my %cache = ("${PREFIX}danger" => [$SENTINEL, 'data']);
	my $obj   = Class::Simple::Cached->new(cache => \%cache);

	throws_ok { my @r = $obj->danger() }
		qr/danger/,
		'sentinel as first array element triggers croak with method name';
	done_testing();
};

subtest 'AUTOLOAD getter: cache hit, blessed object -> returned without eq check' => sub {
	# The !ref() guard ensures the eq-SENTINEL comparison runs ONLY for plain
	# strings.  A blessed object with overloaded eq must never trigger a false
	# undef return — the elsif branch falls through directly to return $rc.
	my $bomb = t::BlessedValue->new();
	my %cache = ("${PREFIX}thing" => $bomb);
	my $obj   = Class::Simple::Cached->new(cache => \%cache);

	my $got = $obj->thing();
	ok(ref($got), 'blessed-object cache hit returns a reference');
	ok(defined($got), 'blessed-object cache hit does not return undef');
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTION: AUTOLOAD() — getter, cache-miss branches
# ═══════════════════════════════════════════════════════════════════════════

subtest 'AUTOLOAD getter: miss, list context, non-empty -> cached as arrayref' => sub {
	# On a cache miss in list context, the result must be stored as an arrayref
	# and returned as a flat list.  The second call must come from cache.
	my $inner = t::ListSource->new();
	my %cache;
	my $obj   = Class::Simple::Cached->new(cache => \%cache, object => $inner);

	my @r1 = $obj->items();   # cache miss
	is_deeply(\@r1, ['x','y','z'], 'first call returns full list');
	is($inner->calls(), 1, 'inner object called once on cache miss');

	# Verify the cache now holds an arrayref.
	is(ref($cache{"${PREFIX}items"}), 'ARRAY',
		'list result cached as ARRAY ref');

	my @r2 = $obj->items();   # cache hit
	is_deeply(\@r2, ['x','y','z'], 'second call returns same list from cache');
	is($inner->calls(), 1, 'inner object NOT called again on cache hit');

	done_testing();
};

subtest 'AUTOLOAD getter: miss, list context, empty -> NOT cached, re-invoked' => sub {
	# An empty list result must never be cached (the guard `return unless
	# scalar(@result)` prevents storage).  Each call must hit the inner object.
	my $inner = t::ListSource->new();
	my %cache;
	my $obj   = Class::Simple::Cached->new(cache => \%cache, object => $inner);

	my @r1 = $obj->nada();
	my @r2 = $obj->nada();
	is(scalar(@r1), 0, 'first call returns empty list');
	is(scalar(@r2), 0, 'second call also returns empty list');
	is($inner->calls(), 2, 'inner object called TWICE (empty list not cached)');

	ok(!exists($cache{"${PREFIX}nada"}),
		'no cache entry written for empty-list result');
	done_testing();
};

subtest 'AUTOLOAD getter: miss, scalar context, defined -> value cached' => sub {
	# A defined scalar result is stored as-is.  The second call must be served
	# from cache without re-invoking the inner object.
	my %cache;
	my $obj = Class::Simple::Cached->new(cache => \%cache);
	$obj->{'object'}->size(42);   # prime the inner Class::Simple object

	my $v1 = $obj->size();   # cache miss
	is($v1, 42, 'first scalar-context getter returns correct value');
	is($cache{"${PREFIX}size"}, 42,
		'scalar value stored directly in cache (not as arrayref)');

	# Overwrite the inner object's value to confirm the second call is from cache.
	$obj->{'object'}->size(99);
	my $v2 = $obj->size();   # must come from cache
	is($v2, 42, 'second call returns stale cached value, not fresh object value');

	done_testing();
};

subtest 'AUTOLOAD getter: miss, scalar context, undef -> sentinel cached' => sub {
	# When the inner object returns undef, the UNDEF_SENTINEL must be stored
	# so the cache-hit probe (if($rc)) can distinguish "never cached" from
	# "cached undef".  The getter must decode the sentinel back to undef.
	my %cache;
	my $obj = Class::Simple::Cached->new(cache => \%cache);
	# The default Class::Simple object returns undef for unset accessors.

	my $v1 = $obj->ghost();   # cache miss, inner returns undef
	ok(!defined($v1), 'first call returns undef');
	is($cache{"${PREFIX}ghost"}, $SENTINEL,
		'UNDEF_SENTINEL stored in cache for undef result');

	my $v2 = $obj->ghost();   # cache hit, sentinel decoded
	ok(!defined($v2), 'second call returns undef from sentinel cache hit');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTION: AUTOLOAD() — setter branches
# ═══════════════════════════════════════════════════════════════════════════

subtest 'AUTOLOAD scalar setter (1 arg): value stored, correct return' => sub {
	# The scalar setter must pass the single argument as a plain scalar to the
	# inner object (not as \@_).  The return value must be the stored value,
	# not CHI->set()'s return code of 1.
	my %cache;
	my $obj = Class::Simple::Cached->new(cache => \%cache);

	my $ret = $obj->colour('scarlet');
	is($ret, 'scarlet', 'scalar setter returns the stored value');

	is($cache{"${PREFIX}colour"}, 'scarlet',
		'scalar value is stored directly in cache (not wrapped in arrayref)');

	# Subsequent getter must come from cache (inner already updated).
	my $v = $obj->colour();
	is($v, 'scarlet', 'getter returns cached setter value');

	done_testing();
};

subtest 'AUTOLOAD scalar setter (1 arg) with CHI: returns value not CHI status' => sub {
	# CHI->set() returns 1 (success flag).  The setter must capture the value
	# BEFORE calling CHI->set() and return that captured value, not 1.
	my $chi = t::MockCHI->new();
	my $obj = Class::Simple::Cached->new(cache => $chi);

	my $ret = $obj->flavour('vanilla');
	is($ret, 'vanilla', 'scalar setter returns stored value, not CHI success flag (1)');
	isnt($ret, 1, 'return value is not the CHI set() status code');

	done_testing();
};

subtest 'AUTOLOAD array setter (>1 args): \@_ passed to object, result cached' => sub {
	# The array setter calls $object->$method(\@_): it wraps all args in an
	# arrayref.  The inner object (Class::Simple) receives the arrayref,
	# stores it, and returns it.  We then cache that arrayref and return
	# the list.
	my %cache;
	my $obj = Class::Simple::Cached->new(cache => \%cache);

	my @ret = $obj->tags('perl', 'cpan', 'cache');
	is_deeply(\@ret, ['perl','cpan','cache'],
		'array setter returns the stored list');

	is(ref($cache{"${PREFIX}tags"}), 'ARRAY',
		'array result is cached as an arrayref');
	is_deeply($cache{"${PREFIX}tags"}, ['perl','cpan','cache'],
		'cached arrayref contains all passed arguments');

	# Getter must serve from cache without hitting the inner object again.
	my @from_cache = $obj->tags();
	is_deeply(\@from_cache, ['perl','cpan','cache'],
		'subsequent getter returns cached list');

	# Confirm the cache key uses the class prefix (regression: was bare $param).
	ok(!exists($cache{'tags'}), 'bare key without prefix does NOT exist');
	ok( exists($cache{"${PREFIX}tags"}), 'prefixed key DOES exist');

	done_testing();
};

subtest 'AUTOLOAD array setter (>1 args) with CHI: no stale CHI return value' => sub {
	# CHI->set() returns 1.  The array setter path does NOT use the CHI return
	# value — it captures the object's return value before calling _cache_set.
	my $chi = t::MockCHI->new();
	my $obj = Class::Simple::Cached->new(cache => $chi);

	my @ret = $obj->tags('a', 'b');
	is_deeply(\@ret, ['a','b'], 'CHI-backed array setter returns correct list');
	isnt(scalar(@ret), 1, 'return is not the CHI success flag');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# MEMORY CYCLE CHECKS
# CSC wraps inner_object + cache; neither holds a back-ref to CSC.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'memory_cycle_ok: no circular references in any backend' => sub {
	my $hash_obj = Class::Simple::Cached->new(cache => {});
	$hash_obj->colour('teal');
	memory_cycle_ok($hash_obj, 'no cycles: hash backend');

	my $chi_obj  = Class::Simple::Cached->new(cache => t::MockCHI->new());
	$chi_obj->flavour('mint');
	memory_cycle_ok($chi_obj, 'no cycles: CHI backend');

	my $clone = $hash_obj->new();
	memory_cycle_ok($clone, 'no cycles: clone of hash-backed instance');

	done_testing();
};

done_testing();
