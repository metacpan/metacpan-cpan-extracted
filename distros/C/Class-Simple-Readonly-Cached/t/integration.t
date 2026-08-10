#!/usr/bin/env perl

=head1 NAME

t/integration.t - Black-box end-to-end integration tests for
Class::Simple::Readonly::Cached.

=head1 DESCRIPTION

Validates stateful cross-method workflows, multi-instance isolation, clone
semantics, DESTROY lifecycle, backend-equivalence, and optional-dependency
independence.  All tests drive the public API only; internal fields are
inspected solely to confirm documented invariants.

=cut

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Test::Mockingbird;
use Readonly;
use Scalar::Util qw(refaddr);
use CHI;

use_ok('Class::Simple::Readonly::Cached');

# ===========================================================================
# Inline packages
# ===========================================================================

# Inner object that counts invocations per method so tests can verify the
# cache is serving hits without touching the inner object.
package IntTest::Inner;
use strict;
use warnings;
sub new       { bless { _n => {} }, shift }
sub ping      { my ($self)      = @_; $self->{_n}{ping}++; 'pong'   }
sub echo      { my ($self, $v)  = @_; $self->{_n}{echo}++; $v       }
sub list_val  { my ($self)      = @_; $self->{_n}{list_val}++; ('x','y','z') }
sub undef_val { my ($self)      = @_; $self->{_n}{undef_val}++; undef }
sub ncalls    { my ($self, $m)  = @_; $self->{_n}{$m} // 0 }

# Class hierarchy for isa()/can() delegation tests.
package IntTest::Base;
use strict;
use warnings;
sub new         { bless {}, shift }
sub base_method { 'from_base' }

package IntTest::Derived;
our @ISA = ('IntTest::Base');
use strict;
use warnings;
sub new             { bless {}, shift }
sub derived_method  { 'from_derived' }

# Duck-typed cache backend: fulfils the get/set/purge contract without
# depending on CHI.pm, proving the module speaks a protocol, not a dependency.
package IntTest::DuckCache;
use strict;
use warnings;
sub new         { bless { _s => {}, _purge_n => 0 }, shift }
sub get         { $_[0]->{_s}{ $_[1] } }
sub set         { $_[0]->{_s}{ $_[1] } = $_[2]; return }
sub purge       { $_[0]->{_s} = {}; $_[0]->{_purge_n}++; return }
sub purge_count { $_[0]->{_purge_n} }

package main;

Readonly::Scalar my $W => 'Class::Simple::Readonly::Cached';

# ===========================================================================
# 1. Two independent hash-backend instances must not share cache state.
#    Each wrapper gets its own {} and its own inner object.
# ===========================================================================

subtest 'multi-instance: separate hash caches are fully isolated' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my ($ia, $ib) = (IntTest::Inner->new, IntTest::Inner->new);
	my ($ca, $cb) = ({}, {});

	my $wa = $W->new(cache => $ca, object => $ia);
	my $wb = $W->new(cache => $cb, object => $ib);

	$wa->ping;   # miss on A
	$wb->ping;   # must be a miss on B, not a hit from A's cache

	is($ia->ncalls('ping'), 1, 'A: inner called once (miss)');
	is($ib->ncalls('ping'), 1, 'B: inner called independently (also a miss)');

	$wa->ping;   # hit
	$wb->ping;   # hit

	is($ia->ncalls('ping'), 1, 'A: inner NOT called again on hit');
	is($ib->ncalls('ping'), 1, 'B: inner NOT called again on hit');
	isnt(refaddr($ca), refaddr($cb), 'cache objects are distinct references');
};

# ===========================================================================
# 2. Shared duck-typed backend: cross-instance key collision
#    When two wrappers share the same backend, their cache keys collide
#    because the key prefix is the wrapper class name, not the inner object.
#    This is a documented limitation.
# ===========================================================================

subtest 'shared backend: cross-instance key collision (documented limitation)' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $shared = IntTest::DuckCache->new;
	my ($ia, $ib) = (IntTest::Inner->new, IntTest::Inner->new);

	my $wa = $W->new(cache => $shared, object => $ia);
	my $wb = $W->new(cache => $shared, object => $ib);

	$wa->ping;   # miss: stores 'pong' under "${W}::ping::"

	# B uses the same key prefix, so it hits A's cached entry.
	$wb->ping;
	is($ib->ncalls('ping'), 0,
		'shared backend: B served from A\'s cache entry (key-collision -- documented)');
};

# ===========================================================================
# 3. State tracking: miss and hit counts are correct and independent per key.
# ===========================================================================

subtest 'state(): miss and hit counts across sequential calls' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = IntTest::Inner->new;
	my $cached = $W->new(cache => {}, object => $inner);

	my $s = $cached->state;
	ok(!defined($s->{hits}),   'state.hits is undef before any call');
	ok(!defined($s->{misses}), 'state.misses is undef before any call');

	$cached->ping;
	$s = $cached->state;
	is($s->{misses}{"${W}::ping::"}, 1, '1 miss after first call');
	ok(!defined($s->{hits}{"${W}::ping::"}), 'no hits yet');

	$cached->ping;
	$s = $cached->state;
	is($s->{misses}{"${W}::ping::"}, 1, 'miss count unchanged after hit');
	is($s->{hits}{"${W}::ping::"},   1, '1 hit after second call');

	$cached->ping;
	is($cached->state->{hits}{"${W}::ping::"}, 2, 'hit counter increments');
};

# ===========================================================================
# 4. Multi-method state tracking: each cache key is tracked independently.
# ===========================================================================

subtest 'state(): multiple methods tracked per key, no cross-contamination' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = IntTest::Inner->new;
	my $cached = $W->new(cache => {}, object => $inner);

	$cached->ping;
	$cached->echo('hello');
	$cached->echo('world');
	$cached->ping;   # hit

	my $s = $cached->state;
	is($s->{misses}{"${W}::ping::"},      1, 'ping: 1 miss');
	is($s->{hits}{"${W}::ping::"},        1, 'ping: 1 hit');
	is($s->{misses}{"${W}::echo::hello"}, 1, 'echo(hello): 1 miss');
	is($s->{misses}{"${W}::echo::world"}, 1, 'echo(world): 1 miss');
	ok(!defined($s->{hits}{"${W}::echo::hello"}),
		'echo(hello): 0 hits (never called twice with same arg)');
};

# ===========================================================================
# 5. Argument-differentiated caching: same method, different args are separate
#    cache entries and do not serve results to each other.
# ===========================================================================

subtest 'argument permutations: distinct arg combos produce distinct cache entries' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = IntTest::Inner->new;
	my $cached = $W->new(cache => {}, object => $inner);

	is($cached->echo('a'), 'a', 'echo(a): first call');
	is($cached->echo('b'), 'b', 'echo(b): first call');
	is($cached->echo('a'), 'a', 'echo(a): second call served from cache');
	is($cached->echo('b'), 'b', 'echo(b): second call served from cache');

	# Inner must have been called exactly once per unique arg -- not four times.
	is($inner->ncalls('echo'), 2, 'inner called once per unique argument set');
};

# ===========================================================================
# 6. Context mismatch: scalar-first, then list.
#    A scalar result cannot serve a list-context caller (documented limitation).
#    Both forms are subsequently independently cached.
# ===========================================================================

subtest 'context mismatch: scalar cache cannot serve a list-context caller' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = IntTest::Inner->new;
	my $cached = $W->new(cache => {}, object => $inner);

	my $scalar = $cached->list_val;   # scalar context: miss
	is($inner->ncalls('list_val'), 1, 'inner called on scalar-context miss');

	my @list = $cached->list_val;     # list context: separate miss (scalar cached form unusable)
	is($inner->ncalls('list_val'), 2,
		'inner called again: scalar-cached result cannot serve list context (documented)');
	is_deeply(\@list, ['x','y','z'], 'list context returns correct values');

	# Both forms now cached: subsequent calls must not reach the inner object.
	my $scalar2 = $cached->list_val;
	is($inner->ncalls('list_val'), 2, 'scalar cache hit: inner NOT called');

	my @list2 = $cached->list_val;
	is($inner->ncalls('list_val'), 2, 'list cache hit: inner NOT called');
	is_deeply(\@list2, ['x','y','z'], 'list hit returns identical elements');
};

# ===========================================================================
# 7. Undef return: UNDEF_SENTINEL prevents repeated inner invocations.
# ===========================================================================

subtest 'undef return: sentinel distinguishes "cached undef" from cache miss' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = IntTest::Inner->new;
	my $cached = $W->new(cache => {}, object => $inner);

	my $r1 = $cached->undef_val;
	is($inner->ncalls('undef_val'), 1, 'inner called on first call (miss)');
	ok(!defined($r1), 'first call returns undef');

	my $r2 = $cached->undef_val;
	is($inner->ncalls('undef_val'), 1,
		'inner NOT called on second call (hit via UNDEF_SENTINEL)');
	ok(!defined($r2), 'second call also returns undef');
};

# ===========================================================================
# 8. Stale data: mutation of the inner object after caching is not visible
#    through the wrapper (documented limitation).  object() bypasses the cache.
# ===========================================================================

subtest 'stale cache: mutation hidden until cache entry is invalidated' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner = Class::Simple->new;
	$inner->value('original');
	my $cached = $W->new(cache => {}, object => $inner);

	is($cached->value, 'original', 'first call: live value');

	$inner->value('mutated');
	is($cached->value, 'original',
		'stale cache shields mutated value (documented limitation)');

	# object() provides direct access to bypass the cache.
	is($cached->object->value, 'mutated',
		'object() returns live value from inner object');
};

# ===========================================================================
# 9. DESTROY: clears this instance's cache entries and deregisters from
#    %cached, enabling a clean re-wrap of the same inner object.
# ===========================================================================

subtest 'DESTROY: cache cleared and registry deregistered on scope exit' => sub {
	my $inner  = IntTest::Inner->new;
	my $cache  = {};
	my $key    = "${W}::ping::";

	{
		# local %cached is INSIDE the inner block so the registry entry is freed
		# synchronously when the block exits, dropping $w's refcount to zero and
		# triggering DESTROY before the assertions below run.
		local %Class::Simple::Readonly::Cached::cached;
		my $w = $W->new(cache => $cache, object => $inner);
		$w->ping;
		ok(exists $cache->{$key}, 'sanity: cache populated before scope exit');
	} # local %cached freed -> $w refcount 0 -> DESTROY fires here

	ok(!exists $cache->{$key},
		'DESTROY cleared the instance\'s cache entry');
	ok(!exists $Class::Simple::Readonly::Cached::cached{$inner},
		'DESTROY removed inner object from the double-wrap registry');

	# The inner object is now free to be re-wrapped without any warning.
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, @_ };
	{
		local %Class::Simple::Readonly::Cached::cached;
		my $w2 = $W->new(cache => $cache, object => $inner);
		is(scalar @warns, 0, 're-wrap after DESTROY: no double-wrap warning');
		ok($w2, 're-wrap after DESTROY: new wrapper created successfully');
	}
};

# ===========================================================================
# 10. DESTROY with shared hash cache: all entries sharing the class-name
#     prefix are deleted (the key prefix is the wrapper class, not the inner
#     object -- documented consequence of shared cache use).
# ===========================================================================

subtest 'DESTROY with shared hash cache: class-prefix keys all cleared' => sub {
	my ($ia, $ib) = (IntTest::Inner->new, IntTest::Inner->new);
	my $shared = {};

	# $wb lives for the whole subtest in its own local registry.
	local %Class::Simple::Readonly::Cached::cached;
	my $wb = $W->new(cache => $shared, object => $ib);
	$wb->ping;   # "${W}::ping::" in $shared

	{
		# $wa uses its own local registry so DESTROY fires synchronously at }.
		local %Class::Simple::Readonly::Cached::cached;
		my $wa = $W->new(cache => $shared, object => $ia);
		$wa->echo('x');   # "${W}::echo::x" in $shared
	} # $wa DESTROY fires here: deletes ALL keys matching "${W}::" prefix

	# Because the key prefix is the wrapper class (not the inner object),
	# $wa's DESTROY clears $wb's entry too -- expected behaviour.
	ok(!exists $shared->{"${W}::ping::"},   'sibling entry also cleared (same class prefix)');
	ok(!exists $shared->{"${W}::echo::x"},  'own entry cleared');
};

# ===========================================================================
# 11. Clone (no args): shares inner object and cache with the original.
#     A hit populated by the original is served by the clone.
# ===========================================================================

subtest 'clone: shares inner object and cache; hit crosses instance boundary' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = IntTest::Inner->new;
	my $cache  = {};
	my $orig   = $W->new(cache => $cache, object => $inner);

	$orig->ping;   # miss: result stored in $cache

	my $clone = $orig->new;   # object-invocation clone

	is(refaddr($clone->{object}), refaddr($orig->{object}),
		'clone shares the same inner object reference');
	is(refaddr($clone->{cache}), refaddr($orig->{cache}),
		'clone shares the same cache reference');

	is($clone->ping, 'pong',
		'clone serves cached result via shared cache (no inner object call)');
	is($inner->ncalls('ping'), 1, 'inner called only once across both instances');
};

# ===========================================================================
# 12. Clone with overridden cache: fresh backend, shared inner object.
#     The clone's _get/_set closures must point at the new cache.
# ===========================================================================

subtest 'clone with new cache: independent backend, shared inner object' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner     = IntTest::Inner->new;
	my $orig      = $W->new(cache => {}, object => $inner);
	$orig->ping;   # populate orig cache

	my $fresh = {};
	my $clone = $orig->new(cache => $fresh);

	is(refaddr($clone->{object}), refaddr($orig->{object}),
		'clone shares inner object even with a new cache');
	isnt(refaddr($clone->{cache}), refaddr($orig->{cache}),
		'clone has a distinct cache object');

	# Fresh cache is empty: the clone must invoke the inner object.
	$clone->ping;
	is($inner->ncalls('ping'), 2,
		'inner called again via clone (fresh cache is empty -- miss)');
	ok(exists $fresh->{"${W}::ping::"},
		'clone populated the new cache, not the original\'s');
};

# ===========================================================================
# 13. object() method: provides direct access to the inner object for
#     mutation, inspection, or bypass.
# ===========================================================================

subtest 'object(): returns inner ref; direct mutation bypasses wrapper cache' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner = Class::Simple->new;
	$inner->name('Alice');
	my $cached = $W->new(cache => {}, object => $inner);

	$cached->name;   # cache 'Alice'

	# Mutate via object() and verify the wrapper returns stale data while
	# the live inner object has the new value.
	$cached->object->name('Bob');
	is($cached->name,          'Alice', 'wrapper returns stale cached value');
	is($cached->object->name,  'Bob',   'object() returns live value');
	is(refaddr($cached->object), refaddr($inner),
		'object() returns the same ref that was passed to new()');
};

# ===========================================================================
# 14. can() delegates to the inner object's class hierarchy.
# ===========================================================================

subtest 'can(): delegates to inner object and wrapper; returns coderef or undef' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $derived = IntTest::Derived->new;
	my $cached  = $W->new(cache => {}, object => $derived);

	ok($cached->can('derived_method'), 'can: finds method on derived class');
	ok($cached->can('base_method'),    'can: finds inherited method on base class');
	ok($cached->can('new'),            'can(new): returns wrapper\'s own \&new');
	ok(!$cached->can('no_such'),       'can: returns undef for nonexistent method');

	# can('new') must return a coderef, not boolean 1 (see LIMITATIONS in POD).
	isa_ok($cached->can('new'), 'CODE', 'can(new) return value');
};

# ===========================================================================
# 15. isa() delegates through the decorator and the inner object hierarchy.
# ===========================================================================

subtest 'isa(): delegates to inner hierarchy; wrapper class always true' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $derived = IntTest::Derived->new;
	my $cached  = $W->new(cache => {}, object => $derived);

	ok($cached->isa($W),               'isa: wrapper class itself');
	ok($cached->isa('Class::Simple'),  'isa: Class::Simple (required by design)');
	ok($cached->isa('IntTest::Derived'), 'isa: inner object\'s own class');
	ok($cached->isa('IntTest::Base'),    'isa: inner object\'s base class (inherited)');
	ok(!$cached->isa('SomeUnrelated'),   'isa: false for unrelated class');
};

# ===========================================================================
# 16. Double-wrap: quiet => 1 suppresses the warning and returns the existing
#     wrapper (not a new wrapper around the already-wrapped object).
# ===========================================================================

subtest 'double-wrap with quiet: no warning; existing wrapper returned' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner = IntTest::Inner->new;
	my $first = $W->new(cache => {}, object => $inner);

	my @warns;
	local $SIG{__WARN__} = sub { push @warns, @_ };

	my $second = $W->new(cache => {}, object => $inner, quiet => 1);

	is(scalar @warns, 0, 'quiet => 1: no warning emitted');
	is(refaddr($second), refaddr($first),
		'quiet => 1: existing wrapper returned, not a new object');
};

# ===========================================================================
# 17. Double-wrap without quiet: warning includes source location of first wrap.
# ===========================================================================

subtest 'double-wrap without quiet: warning includes file and line of first wrap' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner = IntTest::Inner->new;
	my $first = $W->new(cache => {}, object => $inner);

	my @warns;
	local $SIG{__WARN__} = sub { push @warns, @_ };

	my $second = $W->new(cache => {}, object => $inner);

	is(scalar @warns, 1,            'exactly one warning on double-wrap');
	like($warns[0], qr/already cached/, 'warning text: "already cached"');
	like($warns[0], qr/\d+/,           'warning includes a line number');
	is(refaddr($second), refaddr($first), 'returns existing wrapper');
};

# ===========================================================================
# 18. Duck-typed CHI backend: any object implementing get/set/purge works.
#     This proves the module speaks a protocol, not a hard CHI.pm dependency.
# ===========================================================================

subtest 'duck-typed backend: any get/set/purge object is a valid CHI backend' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $duck   = IntTest::DuckCache->new;
	my $inner  = IntTest::Inner->new;
	my $cached = $W->new(cache => $duck, object => $inner);

	ok($cached, 'wrapper constructed with duck-typed cache');

	is($cached->ping, 'pong', 'miss: delegated to inner');
	is($cached->ping, 'pong', 'hit: served from duck cache');
	is($inner->ncalls('ping'), 1, 'inner called once only');

	my $s = $cached->state;
	is($s->{misses}{"${W}::ping::"}, 1, '1 miss tracked');
	is($s->{hits}{"${W}::ping::"},   1, '1 hit tracked');
};

# ===========================================================================
# 19. CHI backend DESTROY: purge() called exactly once.
# ===========================================================================

subtest 'CHI DESTROY: purge() called exactly once on wrapper teardown' => sub {
	my $duck  = IntTest::DuckCache->new;
	my $inner = IntTest::Inner->new;

	{
		# local %cached inside the inner block: frees the registry entry at },
		# dropping $w's refcount to 0 and triggering DESTROY synchronously.
		local %Class::Simple::Readonly::Cached::cached;
		my $w = $W->new(cache => $duck, object => $inner);
		$w->ping;   # populate the backend
	} # local %cached freed -> $w refcount 0 -> DESTROY -> purge() called

	is($duck->purge_count, 1, 'purge() called exactly once during CHI-backend DESTROY');
};

# ===========================================================================
# 20. No inner object: a Class::Simple instance is created automatically.
# ===========================================================================

subtest 'no object param: Class::Simple inner object created automatically' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {});
	ok($cached, 'wrapper created without explicit object');
	isa_ok($cached->object, 'Class::Simple', 'auto-created inner object');

	# Set a value through the auto-created inner and read it back via wrapper.
	$cached->object->city('Paris');
	is($cached->city, 'Paris', 'auto-inner method accessible through wrapper');
	is($cached->city, 'Paris', 'second call served from cache');
};

# ===========================================================================
# 21. Data::Reuse::fixate called during list cache miss, not on cache hit.
#     Integration between AUTOLOAD and Data::Reuse.
# ===========================================================================

subtest 'Data::Reuse::fixate called on list miss, not on list hit' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	clear_call_log();

	my $spy    = spy 'Data::Reuse::fixate';
	my $inner  = IntTest::Inner->new;
	my $cached = $W->new(cache => {}, object => $inner);

	my @first = $cached->list_val;    # list context miss -- fixate should be called
	my $calls_after_miss = scalar($spy->());
	restore_all();

	is($calls_after_miss, 1,
		'fixate called exactly once during list-context cache miss');
	is_deeply(\@first, ['x','y','z'], 'miss result is correct');

	# On a subsequent hit, fixate must NOT be called again.
	clear_call_log();
	my $spy2    = spy 'Data::Reuse::fixate';
	my @second  = $cached->list_val;   # list context hit
	my $calls_after_hit = scalar($spy2->());
	restore_all();

	is($calls_after_hit, 0, 'fixate NOT called on list cache hit');
	is_deeply(\@second, ['x','y','z'], 'hit result is identical');
};

# ===========================================================================
# 22. CHI-free environment: hash backend has no hidden CHI dependency.
#     We temporarily insert a blocker into @INC that dies if CHI is required,
#     then verify the hash-backend path completes without triggering it.
# ===========================================================================

subtest 'CHI independence: hash backend never requires CHI at runtime' => sub {
	local %INC  = %INC;
	local @INC  = @INC;

	# Front-load a guard that would fail if any code path attempted to require
	# CHI after this point.  The hash-backend path must never do that.
	unshift @INC, sub {
		die "CHI must not be required by the hash-backend path\n"
			if $_[1] =~ m{\ACHI[./]};
		return;
	};
	delete $INC{'CHI.pm'};

	local %Class::Simple::Readonly::Cached::cached;
	my $inner  = IntTest::Inner->new;
	my $cached = $W->new(cache => {}, object => $inner);

	ok($cached, 'wrapper constructable with hash backend when CHI is absent');
	is($cached->ping, 'pong', 'scalar method works without CHI in %INC');

	my @list = $cached->list_val;
	is_deeply(\@list, ['x','y','z'], 'list method works without CHI in %INC');

	is($inner->ncalls('ping'), 1, 'miss: inner called once');
	is($cached->ping, 'pong',      'hit: served from cache; CHI still not involved');
	is($inner->ncalls('ping'), 1, 'inner NOT called on cache hit');
};

# ===========================================================================
# 23. Real CHI Memory backend: full miss-hit lifecycle.
#     Confirms the module's CHI path works end-to-end with an actual CHI driver.
# ===========================================================================

subtest 'CHI Memory backend: miss-hit lifecycle with real CHI driver' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $chi    = CHI->new(driver => 'Memory', datastore => {});
	my $inner  = IntTest::Inner->new;
	my $cached = $W->new(cache => $chi, object => $inner);

	is($cached->ping, 'pong', 'CHI: first call is a miss');
	is($inner->ncalls('ping'), 1, 'CHI: inner called on miss');

	is($cached->ping, 'pong', 'CHI: second call is a hit');
	is($inner->ncalls('ping'), 1, 'CHI: inner NOT called on hit');

	my $s = $cached->state;
	is($s->{misses}{"${W}::ping::"}, 1, 'CHI: 1 miss recorded');
	is($s->{hits}{"${W}::ping::"},   1, 'CHI: 1 hit recorded');
};

done_testing;
