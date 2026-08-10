#!/usr/bin/env perl

=head1 NAME

t/unit.t - Black-box unit tests for every public method of
Class::Simple::Readonly::Cached, driven strictly by the POD API.

=head1 DESCRIPTION

Each subtest targets one documented behaviour (return state, message, or
invariant) from the POD.  A ledger hash tracks every documented condition;
the final assertion confirms the ledger is empty -- proving no POD state
went untested.

Test::Mockingbird is used to:
  - spy on inner-object method calls to verify miss/hit dispatch counts
  - mock Carp::carp to capture warnings without polluting TAP output
  - spy on UnitTest::ChiLike::purge to verify DESTROY calls purge()

=cut

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Test::Mockingbird;
use Readonly;
use_ok('Class::Simple::Readonly::Cached');

# ===========================================================================
# Mock inner-object and cache-object packages used throughout the tests.
# Defined in their own namespaces before package main so they are available
# as mock targets for Test::Mockingbird::spy.
# ===========================================================================

package UnitTest::Inner;
use strict;
use warnings;
sub new           { bless {}, shift }
sub echo          { $_[1] }                              # reflects first arg
sub scalar_val    { 'scalar_result' }                    # fixed scalar
sub undef_val     { undef }                              # always undef
sub list_val      { ('item_one', 'item_two') }           # fixed list
sub context_aware { wantarray ? ('list_a', 'list_b') : 'scalar_only' }

# Blessed cache object with no API at all -- should trigger the API croak.
package UnitTest::BadCacheObj;
use strict;
use warnings;
sub new { bless {}, shift }

# Valid CHI-like cache: implements get / set / purge.
package UnitTest::ChiLike;
use strict;
use warnings;
sub new   { bless { _s => {} }, shift }
sub get   { $_[0]->{_s}{ $_[1] } }
sub set   { $_[0]->{_s}{ $_[1] } = $_[2]; return }
sub purge { my $self = shift; $self->{_s} = {}; return }

package main;

# ===========================================================================
# Constants
# ===========================================================================
Readonly::Scalar my $W => 'Class::Simple::Readonly::Cached';
Readonly::Scalar my $I => 'UnitTest::Inner';

# Exact message strings from the POD MESSAGES table.
Readonly::Scalar my $MSG_BAD_CACHE     => 'Cache must be ref to HASH or object';
Readonly::Scalar my $MSG_BAD_API       => 'Cache object must implement get(), set(), and purge()';
Readonly::Scalar my $MSG_SCALAR_OBJ    => '$object must be a reference, not a scalar';
Readonly::Scalar my $MSG_ALREADY_WRAP  => 'warning: $object is already a cached object';
Readonly::Scalar my $MSG_ALREADY_REGD  => '$object is already cached at';

# Internal sentinel documented in the POD AUTOLOAD section.
Readonly::Scalar my $SENTINEL => 'Class::Simple::Readonly::Cached>UNDEF<';

# ===========================================================================
# Ledger -- one entry per documented message / return state / invariant.
# Each is deleted when the corresponding test exercises it.
# The final check asserts the ledger is empty.
# ===========================================================================
my %ledger = (
	# new() -- MESSAGES table (croak)
	"new croak: $MSG_BAD_CACHE"  => 1,
	"new croak: $MSG_BAD_API"    => 1,

	# new() -- MESSAGES table (carp)
	"new carp: $MSG_SCALAR_OBJ"   => 1,
	"new carp: $MSG_ALREADY_WRAP" => 1,
	"new carp: $MSG_ALREADY_REGD" => 1,

	# new() -- return states from Returns / PSEUDOCODE
	'new: returns CSRC object'                    => 1,
	'new: returns undef on scalar object'         => 1,
	'new: returns existing wrapper (CSRC wrap)'   => 1,
	'new: returns existing wrapper (registry)'    => 1,
	'new: quiet suppresses warning'               => 1,
	'new: clone via object invocation'            => 1,
	'new: clone rebuilds accessors on new cache'  => 1,

	# object()
	'object: returns inner object'  => 1,

	# state()
	'state: returns hashref'                    => 1,
	'state: hits undef before first hit'        => 1,
	'state: misses undef before first miss'     => 1,
	'state: miss count incremented on miss'     => 1,
	'state: hit count incremented on hit'       => 1,

	# can()
	"can: returns coderef for 'new'"     => 1,
	'can: returns coderef for inner mth' => 1,
	'can: returns undef for unknown mth' => 1,
	'can: SUPER::can on class-level'     => 1,

	# isa()
	'isa: true for ref($self)'       => 1,
	'isa: true for __PACKAGE__'      => 1,
	'isa: true for Class::Simple'    => 1,
	'isa: true for inner class'      => 1,
	'isa: false for unrelated class' => 1,

	# AUTOLOAD
	'autoload: scalar miss'               => 1,
	'autoload: scalar hit'                => 1,
	'autoload: undef miss sentinel stored'=> 1,
	'autoload: undef hit from sentinel'   => 1,
	'autoload: list miss'                 => 1,
	'autoload: list hit list context'     => 1,
	'autoload: list hit scalar context'   => 1,
	'autoload: scalar-then-list is miss'  => 1,
	'autoload: CHI miss and hit'          => 1,

	# DESTROY
	'destroy: hash cache cleared'    => 1,
	'destroy: registry entry removed'=> 1,
	'destroy: CHI purge() called'    => 1,
);

# Mark a ledger entry as exercised.
sub _ok { delete $ledger{ $_[0] } // diag "ledger: unknown key '$_[0]'" }

# ===========================================================================
# new() -- croak paths
# ===========================================================================

subtest 'new(): scalar cache triggers croak' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	throws_ok {
		$W->new(cache => 'not_a_ref', object => $I->new())
	} qr/\Q$MSG_BAD_CACHE\E/,
		'scalar cache: correct croak message';
	_ok("new croak: $MSG_BAD_CACHE");
};

subtest 'new(): non-HASH ref (arrayref) cache triggers same croak' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	# Same partition as scalar -- different ref type, same guard, same message.
	throws_ok {
		$W->new(cache => [], object => $I->new())
	} qr/\Q$MSG_BAD_CACHE\E/,
		'arrayref cache: same croak message';
};

subtest 'new(): blessed cache without get/set/purge triggers API croak' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	throws_ok {
		$W->new(cache => UnitTest::BadCacheObj->new(), object => $I->new())
	} qr/\Q$MSG_BAD_API\E/,
		'bad-API cache: correct croak message';
	_ok("new croak: $MSG_BAD_API");
};

# ===========================================================================
# new() -- carp paths (mock Carp::carp to suppress TAP noise and capture msg)
# ===========================================================================

subtest 'new(): scalar object triggers carp and returns undef' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my @w;
	mock 'Carp::carp' => sub { push @w, $_[0] };

	my $result = $W->new(cache => {}, object => 'plain_string');
	restore_all();

	is($result, undef,
		'scalar object: returns undef');
	ok(scalar(@w) && $w[0] =~ /\Q$MSG_SCALAR_OBJ\E/,
		'scalar object: carp message matches POD');
	_ok("new carp: $MSG_SCALAR_OBJ");
	_ok('new: returns undef on scalar object');
};

subtest 'new(): wrapping an already-CSRC object triggers carp + returns existing' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my @w;
	mock 'Carp::carp' => sub { push @w, $_[0] };

	my $inner  = $I->new();
	my $first  = $W->new(cache => {}, object => $inner);
	# $first is a CSRC wrapper; wrapping it again triggers MSG_ALREADY_WRAP.
	my $second = $W->new(cache => {}, object => $first);
	restore_all();

	ok(scalar(@w) && $w[0] =~ /\Q$MSG_ALREADY_WRAP\E/,
		'already-CSRC: carp message matches POD');
	is($second, $first,
		'already-CSRC: returns the existing wrapper');
	_ok("new carp: $MSG_ALREADY_WRAP");
	_ok('new: returns existing wrapper (CSRC wrap)');
};

subtest 'new(): double-wrapping same inner object triggers carp + returns existing' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my @w;
	mock 'Carp::carp' => sub { push @w, $_[0] };

	my $inner  = $I->new();
	my $first  = $W->new(cache => {}, object => $inner);
	# Wrap the same $inner again (not the CSRC wrapper) -- triggers MSG_ALREADY_REGD.
	my $second = $W->new(cache => {}, object => $inner);
	restore_all();

	ok(scalar(@w) && $w[0] =~ /\Q$MSG_ALREADY_REGD\E/,
		'double-wrap same inner: carp message matches POD');
	is($second, $first,
		'double-wrap same inner: returns the existing wrapper');
	_ok("new carp: $MSG_ALREADY_REGD");
	_ok('new: returns existing wrapper (registry)');
};

subtest 'new(): quiet => 1 suppresses the double-wrap carp' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my @w;
	mock 'Carp::carp' => sub { push @w, $_[0] };

	my $inner  = $I->new();
	my $first  = $W->new(cache => {}, object => $inner);
	my $second = $W->new(cache => {}, object => $inner, quiet => 1);
	restore_all();

	is(scalar(@w), 0, 'quiet => 1: no carp emitted');
	is($second, $first, 'quiet => 1: existing wrapper still returned');
	_ok('new: quiet suppresses warning');
};

# ===========================================================================
# new() -- success and clone paths
# ===========================================================================

subtest 'new(): success with hash-ref cache returns a CSRC object' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $inner  = $I->new();
	my $cached = $W->new(cache => {}, object => $inner);

	isa_ok($cached, $W, 'constructed object');
	returns_is($cached, { type => 'object' }, 'return type is a blessed object');
	_ok('new: returns CSRC object');
};

subtest 'new(): object-invocation returns a clone sharing the inner object' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $inner    = $I->new();
	my $original = $W->new(cache => {}, object => $inner);
	my $clone    = $original->new();

	isa_ok($clone, $W, 'clone');
	is($clone->object(), $inner, 'clone shares the same inner object');
	_ok('new: clone via object invocation');
};

subtest 'new(): clone with new cache rebuilds _get/_set for the new backend' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $inner    = $I->new();
	my $cache1   = {};
	my $cache2   = {};
	my $original = $W->new(cache => $cache1, object => $inner);
	$original->scalar_val();    # populate cache1

	my $clone = $original->new(cache => $cache2);
	$clone->scalar_val();       # should write to cache2 via rebuilt closures

	ok( exists $cache2->{ $W . '::scalar_val::' },
		'clone writes to the new cache after accessor rebuild');
	ok(scalar(keys %{$cache1}) == 1 && !exists $cache1->{ $W . '::scalar_val::scalar_val' },
		'cache1 is not written to by the clone');
	_ok('new: clone rebuilds accessors on new cache');
};

# ===========================================================================
# object()
# ===========================================================================

subtest 'object(): returns the inner object reference' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $inner  = $I->new();
	my $cached = $W->new(cache => {}, object => $inner);

	my $got = $cached->object();
	is($got, $inner, 'object() returns the exact inner reference');
	returns_is($got, { type => 'object' }, 'return type is a blessed object');
	_ok('object: returns inner object');
};

# ===========================================================================
# state()
# ===========================================================================

subtest 'state(): returns a hashref with hits and misses keys' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cached = $W->new(cache => {}, object => $I->new());
	my $s = $cached->state();

	returns_is($s, { type => 'hashref' }, 'state() returns hashref');
	ok(exists $s->{hits},   'hashref contains "hits" key');
	ok(exists $s->{misses}, 'hashref contains "misses" key');
	_ok('state: returns hashref');
};

subtest 'state(): hits and misses are undef before any dispatch' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cached = $W->new(cache => {}, object => $I->new());
	my $s = $cached->state();

	is($s->{hits},   undef, 'hits is undef before any hit');
	is($s->{misses}, undef, 'misses is undef before any miss');
	_ok('state: hits undef before first hit');
	_ok('state: misses undef before first miss');
};

subtest 'state(): miss and hit counts are keyed by cache key and increment correctly' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cached = $W->new(cache => {}, object => $I->new());
	my $key    = $W . '::scalar_val::';

	$cached->scalar_val();    # miss 1
	$cached->scalar_val();    # hit 1
	$cached->scalar_val();    # hit 2

	my $s = $cached->state();
	diag("state: " . Data::Dumper::Dumper($s)) if $ENV{TEST_VERBOSE};

	is($s->{misses}{$key}, 1, 'miss count == 1 after one miss');
	is($s->{hits}{$key},   2, 'hit count == 2 after two hits');
	_ok('state: miss count incremented on miss');
	_ok('state: hit count incremented on hit');
};

# ===========================================================================
# can()
# ===========================================================================

subtest "can('new'): returns \\&new coderef (not boolean 1)" => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cached = $W->new(cache => {}, object => $I->new());
	my $code   = $cached->can('new');

	returns_is($code, { type => 'coderef' }, "can('new') return type is coderef");
	is($code, \&Class::Simple::Readonly::Cached::new,
		"can('new') is the exact \\&new reference (documented in LIMITATIONS)");
	_ok("can: returns coderef for 'new'");
};

subtest "can(): returns coderef for a method the inner object provides" => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cached = $W->new(cache => {}, object => $I->new());
	my $code   = $cached->can('scalar_val');

	returns_is($code, { type => 'coderef' }, "can('scalar_val') return type is coderef");
	_ok('can: returns coderef for inner mth');
};

subtest "can(): returns undef for an unknown method" => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $cached = $W->new(cache => {}, object => $I->new());

	is($cached->can('no_such_method_xyz'), undef,
		"can('no_such_method_xyz') returns undef");
	_ok('can: returns undef for unknown mth');
};

subtest "can(): class-level call delegates to SUPER::can" => sub {
	# !ref($self) path: the guard returns SUPER::can directly.
	my $code = $W->can('object');
	returns_is($code, { type => 'coderef' }, 'class-level can("object") returns coderef');
	_ok('can: SUPER::can on class-level');
};

# ===========================================================================
# isa()
# ===========================================================================

subtest 'isa(): all documented true and false cases' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	my $inner  = $I->new();
	my $cached = $W->new(cache => {}, object => $inner);

	ok($cached->isa(ref($cached)),
		'isa(ref($self)): O(1) fast path');
	_ok('isa: true for ref($self)');

	ok($cached->isa('Class::Simple::Readonly::Cached'),
		'isa(__PACKAGE__): true');
	_ok('isa: true for __PACKAGE__');

	ok($cached->isa('Class::Simple'),
		'isa("Class::Simple"): true -- special-cased because @ISA is empty');
	_ok('isa: true for Class::Simple');

	ok($cached->isa($I),
		"isa($I): delegates to inner object -- true");
	_ok('isa: true for inner class');

	ok(!$cached->isa('NoSuchClassXYZZY'),
		'isa("NoSuchClassXYZZY"): false');
	_ok('isa: false for unrelated class');
};

# ===========================================================================
# AUTOLOAD -- scalar miss / hit  (hash backend)
# Spy on the inner method to verify it is called exactly once on miss
# and zero times on hit.
# ===========================================================================

subtest 'AUTOLOAD: scalar cache miss then hit (hash backend)' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	clear_call_log();

	my $inner  = $I->new();
	my $cache  = {};
	my $cached = $W->new(cache => $cache, object => $inner);

	# Install spy AFTER wrapper creation so the closure in _build_cache_accessors
	# captures the original (pre-spy) sub reference -- but dispatch via
	# $object->$method() still goes through UnitTest::Inner::scalar_val, which
	# Test::Mockingbird replaces in the stash, so the spy IS intercepted.
	my $spy = spy 'UnitTest::Inner::scalar_val';

	# --- Miss ---
	my $miss_val = $cached->scalar_val();
	is($miss_val, 'scalar_result', 'miss: correct value returned');

	# $spy->() returns a per-spy array; it accumulates across calls and is
	# never reset by clear_call_log().  Check total count after miss = 1.
	my $count_after_miss = scalar( $spy->() );
	is($count_after_miss, 1, 'miss: inner method called exactly once');

	my $key = $W . '::scalar_val::';
	is($cache->{$key}, 'scalar_result', 'miss: value stored in cache under expected key');
	_ok('autoload: scalar miss');

	# --- Hit ---
	# Snapshot the spy count, make the hit call, assert count is unchanged.
	my $count_before_hit = scalar( $spy->() );
	my $hit_val = $cached->scalar_val();
	is($hit_val, 'scalar_result', 'hit: same value returned');

	my $count_after_hit = scalar( $spy->() );
	is($count_after_hit, $count_before_hit,
		'hit: inner method NOT called again (spy count unchanged)');
	_ok('autoload: scalar hit');

	restore_all();
};

# ===========================================================================
# AUTOLOAD -- undef return / sentinel mechanism
# ===========================================================================

subtest 'AUTOLOAD: undef result stored as sentinel; hit returns undef' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cache  = {};
	my $cached = $W->new(cache => {}, object => $I->new());

	# Wrap around the shared hash for this sub-test's inspection.
	# Use a fresh wrapper backed by $cache so we can read raw stored values.
	local %Class::Simple::Readonly::Cached::cached;
	my $c2     = {};
	my $inner2 = $I->new();
	my $wrap2  = $W->new(cache => $c2, object => $inner2);

	my $key = $W . '::undef_val::';

	# --- Miss ---
	my $miss = $wrap2->undef_val();
	is($miss, undef, 'miss: undef returned on first call');
	is($c2->{$key}, $SENTINEL,
		'miss: sentinel stored so future hits are unambiguous');
	_ok('autoload: undef miss sentinel stored');

	# --- Hit ---
	my $hit = $wrap2->undef_val();
	is($hit, undef, 'hit: undef returned from cached sentinel');
	is($wrap2->state()->{hits}{$key}, 1, 'hit count incremented for undef result');
	_ok('autoload: undef hit from sentinel');
};

# ===========================================================================
# AUTOLOAD -- list miss / hit
# ===========================================================================

subtest 'AUTOLOAD: list result cached as ARRAY ref; hit serves list or last element' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $c      = {};
	my $inner  = $I->new();
	my $cached = $W->new(cache => $c, object => $inner);
	my $key    = $W . '::list_val::';

	# --- Miss (list context) ---
	my @miss = $cached->list_val();
	is_deeply(\@miss, ['item_one', 'item_two'],
		'list miss: correct list returned');
	is(ref($c->{$key}), 'ARRAY',
		'list miss: stored as ARRAY ref in cache');
	_ok('autoload: list miss');

	# --- Hit (list context) ---
	my @hit = $cached->list_val();
	is_deeply(\@hit, ['item_one', 'item_two'],
		'list hit (list context): full list returned');
	_ok('autoload: list hit list context');

	# --- Hit (scalar context) -- last element of the cached array ---
	my $scalar_hit = $cached->list_val();
	is($scalar_hit, 'item_two',
		'list hit (scalar context): last element returned');
	_ok('autoload: list hit scalar context');
};

# ===========================================================================
# AUTOLOAD -- scalar-then-list is a miss (documented in LIMITATIONS)
# ===========================================================================

subtest 'AUTOLOAD: scalar-stored entry is treated as miss in list context' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $c      = {};
	my $inner  = $I->new();
	my $cached = $W->new(cache => $c, object => $inner);
	my $key    = $W . '::context_aware::';

	# First call: scalar context -- stores 'scalar_only' as a plain scalar.
	my $scalar = $cached->context_aware();
	is($scalar, 'scalar_only', 'first call (scalar ctx): correct scalar returned');
	ok(!ref($c->{$key}), 'scalar stored (not ARRAY ref) after scalar call');

	# Second call: list context -- scalar cannot be adapted; re-invokes inner.
	my @list = $cached->context_aware();
	is_deeply(\@list, ['list_a', 'list_b'],
		'second call (list ctx): inner re-invoked; correct list returned');

	# Both forms are now independently cached.
	is(ref($c->{$key}), 'ARRAY',
		'list form now also cached as ARRAY ref alongside the scalar entry');
	_ok('autoload: scalar-then-list is miss');
};

# ===========================================================================
# AUTOLOAD -- CHI backend
# ===========================================================================

subtest 'AUTOLOAD: CHI backend miss and hit behave identically to hash backend' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $chi    = UnitTest::ChiLike->new();
	my $inner  = $I->new();
	my $cached = $W->new(cache => $chi, object => $inner);
	my $key    = $W . '::scalar_val::';

	my $miss = $cached->scalar_val();
	is($miss, 'scalar_result', 'CHI miss: correct value returned');
	is($cached->state()->{misses}{$key}, 1, 'CHI miss count is 1');

	my $hit = $cached->scalar_val();
	is($hit, 'scalar_result', 'CHI hit: cached value returned');
	is($cached->state()->{hits}{$key}, 1, 'CHI hit count is 1');
	_ok('autoload: CHI miss and hit');
};

# ===========================================================================
# DESTROY -- hash backend: cache entries cleared for this class
# ===========================================================================

subtest 'DESTROY: clears all hash-cache entries belonging to this instance' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $c      = {};
	my $inner  = $I->new();
	my $cached = $W->new(cache => $c, object => $inner);

	$cached->scalar_val();         # key: ...::scalar_val::
	$cached->echo('arg');          # key: ...::echo::arg

	my $k1 = $W . '::scalar_val::';
	my $k2 = $W . '::echo::arg';

	ok(exists $c->{$k1}, 'entry 1 exists before DESTROY');
	ok(exists $c->{$k2}, 'entry 2 exists before DESTROY');

	$cached->DESTROY();

	ok(!exists $c->{$k1}, 'entry 1 cleared after DESTROY');
	ok(!exists $c->{$k2}, 'entry 2 cleared after DESTROY');
	_ok('destroy: hash cache cleared');
};

# ===========================================================================
# DESTROY -- removes wrapper from %cached registry
# ===========================================================================

subtest 'DESTROY: removes wrapper from the double-wrap registry' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = $I->new();
	my $cached = $W->new(cache => {}, object => $inner);

	ok(exists $Class::Simple::Readonly::Cached::cached{$inner},
		'inner object is registered in %cached before DESTROY');

	$cached->DESTROY();

	ok(!exists $Class::Simple::Readonly::Cached::cached{$inner},
		'inner object removed from %cached after DESTROY');
	_ok('destroy: registry entry removed');
};

# ===========================================================================
# DESTROY -- CHI backend: purge() called
# ===========================================================================

subtest 'DESTROY: calls purge() on a CHI-compatible cache' => sub {
	local %Class::Simple::Readonly::Cached::cached;
	clear_call_log();

	my $chi    = UnitTest::ChiLike->new();
	my $inner  = $I->new();
	my $cached = $W->new(cache => $chi, object => $inner);
	$cached->scalar_val();    # populate one entry

	my $purge_spy = spy 'UnitTest::ChiLike::purge';
	$cached->DESTROY();

	my @calls = $purge_spy->();
	is(scalar @calls, 1, 'purge() called exactly once during CHI DESTROY');
	restore_all();
	_ok('destroy: CHI purge() called');
};

# ===========================================================================
# Ledger completion check
# All documented conditions must have been exercised by the tests above.
# ===========================================================================

if(my @remaining = sort keys %ledger) {
	fail("untested POD condition: '$_'") for @remaining;
} else {
	pass('ledger complete: every documented message and return state was exercised');
}

done_testing();
