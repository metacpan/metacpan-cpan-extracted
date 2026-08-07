#!/usr/bin/env perl

=head1 NAME

t/cgi_security.t - Adversarial penetration tests for Class::Simple::Cached

=head1 DESCRIPTION

Although Class::Simple::Cached is a pure-Perl module and not a CGI script, it
accepts arbitrary external arguments and stores/retrieves untrusted data.  These
tests simulate the same classes of hostile input that a CGI security review
would apply: argument injection, internal-field poisoning, sentinel bypass,
resource-exhaustion, and namespace collision.

CGI-specific vectors (QUERY_STRING, PATH_INFO, command injection, path
traversal, XSS, CRLF header injection) are I<not applicable> to this module
because it has no HTTP layer, no file I/O, and no shell invocation.  Each
inapplicable vector is noted with a rationale.

=head3 API SPECIFICATION

    Input surface 1 — constructor
      cache  : HashRef | CHI-compatible blessed object  (required)
      object : blessed object                           (optional)

    Input surface 2 — method dispatch via AUTOLOAD
      method name : valid Perl identifier (\w+)  [Perl-controlled, never tainted]
      method args : any scalar or list

=head3 FORMAL SPECIFICATION

    Attack ────────────────────────────────────────────────────────────
    Δ(cache, _is_hash_cache, _cache_prefix)
    attacker_input? : Seq(Any)
    ──────────────────────────────────────────────────────────
    ∀ field? ∈ {_is_hash_cache, _cache_prefix}
      ¬ (attacker_input? ∋ field?)
      ∨ (field? overridden by secure recalculation post-merge)

    Sentinel ──────────────────────────────────────────────────────────
    v : CachedValue
    ────────────────────────────────────────────────
    (¬ ref(v)) ∧ (v = UNDEF_SENTINEL) ⟹ result! = undef
    ref(v) ⟹ (UNDEF_SENTINEL check SKIPPED; overloaded-eq never invoked)

=cut

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Readonly;

BEGIN { use_ok('Class::Simple::Cached') }

# ── Constants ────────────────────────────────────────────────────────────────

Readonly::Scalar my $SENTINEL    => Class::Simple::Cached::UNDEF_SENTINEL();
Readonly::Scalar my $LONG_NAME   => 'x' x 1024;
Readonly::Scalar my $PARENT_KEY  => 'Class::Simple::Cached:colour';
Readonly::Scalar my $CHILD_KEY   => 't::FakeSub:colour';

# ── Helper packages defined before test code ─────────────────────────────────

{
	# A cache object that is missing the required purge() method.
	# Exploit: pass a hobbled blessed object to bypass interface validation.
	package t::NoPurgeCache;
	sub new { bless {}, shift }
	sub get { }
	sub set { }
	# purge() intentionally absent
}

{
	# A cache object that is missing all required methods.
	package t::EmptyCache;
	sub new { bless {}, shift }
}

{
	# A class whose overloaded eq always returns true, simulating an object
	# designed to collide with UNDEF_SENTINEL comparisons.
	# Exploit: if !ref() guard is absent, this fools the sentinel check into
	# returning undef instead of the real cached object.
	package t::EqAlwaysTrue;
	use overload 'eq' => sub { 1 }, '""' => sub { 'fake' }, fallback => 1;
	sub new { bless {}, shift }
}

{
	# A wrapped object that returns an overloaded-eq object from a getter.
	package t::WrappedWithEqBomb;
	sub new    { bless {}, shift }
	sub getter { return t::EqAlwaysTrue->new() }
}

{
	# A wrapped object whose method returns the sentinel as the first element
	# of a list, triggering the array-sentinel croak path.
	package t::SentinelArrayReturn;
	sub new    { bless {}, shift }
	sub danger { return (Class::Simple::Cached::UNDEF_SENTINEL(), 'harmless') }
}

{
	# A trivial subclass used to verify key namespace isolation.
	package t::FakeSub;
	our @ISA = ('Class::Simple::Cached');
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 1 — Constructor argument validation
# Attack vector: hostile/malformed values passed as cache =>
# ═══════════════════════════════════════════════════════════════════════════

subtest 'constructor rejects all invalid cache types' => sub {
	# Every croak message must match the documented error strings so that
	# callers can distinguish argument errors from runtime failures.

	throws_ok { Class::Simple::Cached->new() }
		qr/Usage:/,
		'no-args call croaks with Usage message';

	throws_ok { Class::Simple::Cached->new(cache => undef) }
		qr/Cache must be ref to HASH or object/,
		'undef cache rejected';

	throws_ok { Class::Simple::Cached->new(cache => 'string') }
		qr/Cache must be ref to HASH or object/,
		'plain string cache rejected';

	throws_ok { Class::Simple::Cached->new(cache => 42) }
		qr/Cache must be ref to HASH or object/,
		'number cache rejected';

	throws_ok { Class::Simple::Cached->new(cache => []) }
		qr/Cache must be ref to HASH or object/,
		'arrayref cache rejected';

	throws_ok { Class::Simple::Cached->new(cache => \my $s) }
		qr/Cache must be ref to HASH or object/,
		'scalarref cache rejected';

	throws_ok { Class::Simple::Cached->new(cache => sub {}) }
		qr/Cache must be ref to HASH or object/,
		'coderef cache rejected';

	throws_ok { Class::Simple::Cached->new(cache => t::NoPurgeCache->new()) }
		qr/Cache object must implement/,
		'blessed cache missing purge() rejected';

	throws_ok { Class::Simple::Cached->new(cache => t::EmptyCache->new()) }
		qr/Cache object must implement/,
		'blessed cache missing all methods rejected';

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 2 — Internal field injection via clone path
#
# Attack surface: $obj->new(_is_hash_cache => 0, _cache_prefix => 'evil:')
#
# Exploit mechanism:
#   Params::Get returns ALL key-value args including CSC-internal field names.
#   The clone path did: my %merged = (%{$class}, %{$params}).
#   Without unconditional recalculation, an attacker-supplied
#   _is_hash_cache => 0 overwrites the precomputed flag.  _cache_get then
#   calls $cache->get($key) on a plain HASH ref (which has no get() method),
#   causing a fatal "Can't locate object method" exception on the next getter.
#   Similarly, _cache_prefix => 'evil:' would make DESTROY delete keys from
#   a sibling instance's namespace.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'clone path: injected internal fields are overridden post-merge' => sub {
	my %cache;
	my $orig = Class::Simple::Cached->new(cache => \%cache);
	$orig->colour('red');

	# Attempt to inject internal fields through the clone constructor.
	my $clone;
	lives_ok {
		$clone = $orig->new(_is_hash_cache => 0, _cache_prefix => 'evil:');
	} 'clone construction with injected internal fields does not die';

	# The injected _is_hash_cache => 0 must have been overridden by
	# the post-merge recalculation (the actual cache is still a hashref).
	ok($clone->{'_is_hash_cache'},
		'_is_hash_cache recalculated to 1 despite injection of 0');

	# The injected _cache_prefix must be ignored.
	is($clone->{'_cache_prefix'}, 'Class::Simple::Cached:',
		'_cache_prefix recalculated to correct value despite injection');

	# A getter must work without dying (would die if _is_hash_cache were 0).
	my $val;
	lives_ok { $val = $clone->colour() } 'getter does not die after injected clone';
	is($val, 'red', 'getter returns correct cached value from injected clone');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 3 — UNDEF_SENTINEL bypass via overloaded eq
#
# Attack mechanism:
#   The getter probe was: return if $rc eq UNDEF_SENTINEL
#   A blessed object with overloaded eq => sub { 1 } would cause every
#   cache retrieval to return undef regardless of the real value.
# Fix: !ref($rc) guard ensures the eq comparison only runs on plain strings.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'overloaded-eq object is not mistaken for UNDEF_SENTINEL' => sub {
	my %cache;
	my $obj = Class::Simple::Cached->new(
		cache  => \%cache,
		object => t::WrappedWithEqBomb->new(),
	);

	# First call: cache miss, delegates to wrapped object, stores blessed value.
	my $result = $obj->getter();
	ok(defined($result),
		'getter does not return undef for overloaded-eq object');
	ok(ref($result),
		'returned value is a reference (not coerced to undef by false sentinel match)');

	# Second call: cache hit — must return the blessed object, not undef.
	my $cached = $obj->getter();
	ok(defined($cached),
		'second getter call (cache hit) still does not return undef');
	ok(ref($cached),
		'cached overloaded-eq object returned as-is on second call');

	returns_ok($result, { type => 'object' },
		'Test::Returns: getter return satisfies object schema');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 4 — UNDEF_SENTINEL in array first-element triggers croak
#
# Attack mechanism:
#   If the wrapped object returns a list whose first element IS the sentinel
#   string, CSC would cache [UNDEF_SENTINEL, ...].  On retrieval the
#   !ref() + eq guard detects the collision and croaks.  This prevents silent
#   data corruption where an attacker-controlled return value bypasses the
#   undef-detection protocol.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'sentinel as array first-element triggers croak on cache retrieval' => sub {
	my %cache;
	my $obj = Class::Simple::Cached->new(
		cache  => \%cache,
		object => t::SentinelArrayReturn->new(),
	);

	# First call: cache miss — result stored as [$SENTINEL, 'harmless'].
	my @first;
	lives_ok { @first = $obj->danger() } 'first call (cache miss) does not die';
	is($first[0], $SENTINEL, 'first element of returned list is the sentinel string');

	# Second call: cache hit — croak expected because first element collides.
	throws_ok { my @second = $obj->danger() }
		qr/danger/,
		'sentinel as array first element croaks on cache retrieval';

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 5 — Resource exhaustion: very long method name
#
# CGI analogy: oversized QUERY_STRING parameter names.
# A 1 kB method name is a valid Perl identifier (\w+) so AUTOLOAD
# dispatches it.  The test verifies neither a stack overflow nor a memory
# panic occurs, and that the resulting cache key is correctly prefixed.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'very long method name handled without crash' => sub {
	my %cache;
	my $obj = Class::Simple::Cached->new(cache => \%cache);

	lives_ok { $obj->$LONG_NAME('value') } '1 kB method name setter does not crash';
	lives_ok { $obj->$LONG_NAME() }        '1 kB method name getter does not crash';

	my $expected_key = "Class::Simple::Cached:$LONG_NAME";
	ok(exists $cache{$expected_key},
		'long method name generates correctly prefixed cache key');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 6 — Cache namespace isolation (subclass key collision)
#
# CGI analogy: two tenants sharing a session store must not read each other's
# data.  Two CSC instances of different classes sharing the same hash-ref
# cache must use disjoint key namespaces.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'subclass keys do not collide with parent class keys' => sub {
	my %shared;
	my $parent = Class::Simple::Cached->new(cache => \%shared);
	my $child  = t::FakeSub->new(cache => \%shared);

	$parent->colour('red');
	$child->colour('blue');

	is($parent->colour(), 'red',  'parent value not overwritten by child setter');
	is($child->colour(),  'blue', 'child value not overwritten by parent setter');

	ok( exists $shared{$PARENT_KEY}, 'parent cache key is present');
	ok( exists $shared{$CHILD_KEY},  'child cache key is present');
	isnt($shared{$PARENT_KEY}, $shared{$CHILD_KEY},
		'parent and child store distinct values under distinct keys');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 7 — Undef setter stores sentinel; internal flags remain intact
#
# If a setter receives undef, the module stores UNDEF_SENTINEL so that
# a subsequent getter cache-hit returns undef rather than re-invoking the
# object.  Internal fields (_is_hash_cache, _cache_prefix) must not be
# modified as a side-effect.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'undef setter writes sentinel and does not corrupt internal fields' => sub {
	my %cache;
	my $obj = Class::Simple::Cached->new(cache => \%cache);

	lives_ok { $obj->field(undef) } 'setter with undef arg does not die';

	my $cache_key = 'Class::Simple::Cached:field';
	ok(exists $cache{$cache_key},
		'undef setter created a cache entry');
	is($cache{$cache_key}, $SENTINEL,
		'undef setter stored UNDEF_SENTINEL (not undef) in cache');

	# Sentinel must be transparently decoded by the getter
	my $retrieved = $obj->field();
	ok(!defined($retrieved), 'getter returns undef for sentinel-stored value');

	ok($obj->{'_is_hash_cache'}, '_is_hash_cache intact after undef setter');
	is($obj->{'_cache_prefix'}, 'Class::Simple::Cached:',
		'_cache_prefix intact after undef setter');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 8 — constructor returns value validated with Test::Returns
# ═══════════════════════════════════════════════════════════════════════════

subtest 'constructor return type satisfies object schema' => sub {
	my $obj = Class::Simple::Cached->new(cache => {});
	returns_ok($obj, { type => 'object' },
		'new() return value satisfies object schema');
	isa_ok($obj, 'Class::Simple::Cached', 'new() return is correct class');

	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# SECTION 9 — N/A vectors (documented, not tested)
# ═══════════════════════════════════════════════════════════════════════════

# COMMAND INJECTION  — N/A: no system(), exec(), backticks, or open(CMD, ...)
# PATH TRAVERSAL     — N/A: no file I/O in the module
# XSS                — N/A: no HTML output
# CRLF HEADER INJ.   — N/A: not a CGI script; no HTTP response headers
# QUERY_STRING/POST  — N/A: no CGI parameter parsing
# TAINT MODE         — Covered by t/hash.t, t/carp.t, t/chi.t (all use -T);
#                      $AUTOLOAD is Perl-internal and never tainted.

done_testing();
