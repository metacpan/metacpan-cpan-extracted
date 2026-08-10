#!/usr/bin/env perl
# t/mutant_killers.t -- Kill the 4 MEDIUM and 3 LOW mutant survivors from
# xt/mutant_20260809_032457.t.
#
# Survivor map:
#   COND_INV_214_3     (MEDIUM) line 214: if(exists $params->{cache})  → unless
#   BOOL_NEGATE_243_4  (MEDIUM) line 243: return $params->{object}     → return !...
#   RETURN_UNDEF_243_4 (LOW)    line 243: return $params->{object}     → return undef
#   BOOL_NEGATE_397_2  (MEDIUM) line 397: return \&new if ...          → return !\&new
#   RETURN_UNDEF_397_2 (LOW)    line 397: return \&new if ...          → return undef
#   BOOL_NEGATE_500_2  (MEDIUM) line 500: return none { ... }          → return !none { ... }
#   RETURN_UNDEF_500_2 (LOW)    line 500: return none { ... }          → return undef

# BEGIN block sets HARNESS_ACTIVE before any CHECK blocks run, giving
# Sub::Private white-box access to _can_fixate and _build_cache_accessors.
BEGIN { $ENV{HARNESS_ACTIVE} ||= 1 }

use strict;
use warnings;
use Test::Most;
use Scalar::Util qw(blessed refaddr);
use Readonly;
use Test::Mockingbird;

use Class::Simple::Readonly::Cached;

Readonly::Scalar my $PKG => 'Class::Simple::Readonly::Cached';

# ---------------------------------------------------------------------------
# Minimal inner object used across all subtests.
# list_items() returns a plain-scalar list — safe for Data::Reuse::fixate.
# ---------------------------------------------------------------------------
{
	package MK::Inner;
	sub new        { bless { _n => {} }, shift }
	sub greet      { my ($self) = @_; $self->{_n}{greet}++;      'hello' }
	sub list_items { my ($self) = @_; $self->{_n}{list_items}++; ('alpha', 'beta') }
	sub ncalls     { $_[0]->{_n}{ $_[1] } // 0 }
}

# ===========================================================================
# MUTANT: COND_INV_214_3 (MEDIUM) — line 214 in new()
#
#   Source:   if(exists $params->{cache}) { _build_cache_accessors($clone) }
#   Mutation: unless(exists $params->{cache}) { ... }
#
# Kill strategy (TRUE branch — cache IS provided to clone):
#   Correct: _build_cache_accessors IS called → new _get/_set closures target $cache2.
#   Mutant:  condition inverted → _build_cache_accessors is SKIPPED → closures still
#            target $cache1.  A call through $clone therefore writes to $cache1, leaving
#            $cache2 empty.  The final ok() fails under the mutation.
# ===========================================================================
subtest 'COND_INV_214_3 – clone with cache override writes to the new cache' => sub {
	plan tests => 3;

	local %Class::Simple::Readonly::Cached::cached;

	my $cache1 = {};
	my $cache2 = {};
	my $inner  = MK::Inner->new;

	my $orig  = $PKG->new(object => $inner, cache => $cache1);
	my $clone = $orig->new(cache => $cache2);

	isnt(refaddr($clone), refaddr($orig), 'clone is a distinct object');

	my $val = $clone->greet;
	is($val, 'hello', 'clone returns the correct value');

	# Under the mutation (unless), _build_cache_accessors is skipped when cache
	# IS given, so _set still targets $cache1 and $cache2 remains empty.
	diag('cache2 key count: ' . scalar(keys %$cache2)) if $ENV{TEST_VERBOSE};
	ok(scalar(keys %$cache2) > 0,
		'new cache ($cache2) received the cached entry — not the original cache');
};

# ===========================================================================
# MUTANTS: BOOL_NEGATE_243_4 (MEDIUM) + RETURN_UNDEF_243_4 (LOW) — line 243
#
#   Source:   return $params->{object};   (inside ref(...) eq __PACKAGE__ block)
#   Mutation A: return !$params->{object}  → '' (unblessed empty string)
#   Mutation B: return undef
#
# Kill strategy: pass an existing CSRC wrapper as the 'object' param.
# new() detects ref($params->{object}) eq __PACKAGE__ and must return the
# ORIGINAL wrapper unchanged.
#   Mutation A: !blessed_ref = '' — not blessed, not == $first → both assertions fail.
#   Mutation B: undef — not defined, not blessed, not == $first → all three fail.
# ===========================================================================
subtest 'BOOL_NEGATE_243_4 + RETURN_UNDEF_243_4 – double-wrap returns original wrapper' => sub {
	plan tests => 3;

	local %Class::Simple::Readonly::Cached::cached;

	my $inner = MK::Inner->new;
	my $first = $PKG->new(object => $inner, cache => {});

	# Passing a CSRC wrapper as the object triggers the ref-eq-__PACKAGE__ guard
	# at line 239, which always carps; suppress with a local signal handler.
	my $result;
	local $SIG{__WARN__} = sub { };
	$result = $PKG->new(object => $first, cache => {});

	ok(defined($result),
		'double-wrap: result is defined (kills RETURN_UNDEF_243_4)');
	ok(blessed($result),
		'double-wrap: result is a blessed ref (kills BOOL_NEGATE_243_4, which returns "")');
	is(refaddr($result), refaddr($first),
		'double-wrap: result is the same object as the first wrapper');
};

# ===========================================================================
# MUTANTS: BOOL_NEGATE_397_2 (MEDIUM) + RETURN_UNDEF_397_2 (LOW) — line 397
#
#   Source:   return \&new if $method eq 'new';
#   Mutation A: return !\&new if $method eq 'new'  → '' (false)
#   Mutation B: return undef  if $method eq 'new'
#
# Kill strategy: call can('new') on a live wrapper.
# Correct: returns a CODE ref pointing to \&Class::Simple::Readonly::Cached::new.
# Mutation A: !\&new = '' — ref('') = '' ≠ 'CODE'; '' ≠ \&new.
# Mutation B: undef    — ref(undef) = ''; undef ne \&new.
# All three assertions below fail under either mutation.
# ===========================================================================
subtest 'BOOL_NEGATE_397_2 + RETURN_UNDEF_397_2 – can("new") returns correct coderef' => sub {
	plan tests => 3;

	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = MK::Inner->new;
	my $cached = $PKG->new(object => $inner, cache => {});

	my $code = $cached->can('new');

	diag('can("new") ref: ' . (defined $code ? ref($code) || 'SCALAR' : 'undef'))
		if $ENV{TEST_VERBOSE};

	ok(defined($code),
		'can("new") is defined (kills RETURN_UNDEF_397_2)');
	is(ref($code), 'CODE',
		'can("new") returns a CODE ref (kills BOOL_NEGATE_397_2, which returns "")');
	is($code, \&Class::Simple::Readonly::Cached::new,
		'can("new") is exactly \&Class::Simple::Readonly::Cached::new');
};

# ===========================================================================
# MUTANTS: BOOL_NEGATE_500_2 (MEDIUM) + RETURN_UNDEF_500_2 (LOW) — line 500
#
#   Source:   return none { ref($_) && ref($_) !~ /\A(?:ARRAY|HASH|SCALAR)\z/x } @_;
#   Mutation A: return !none { ... } @_  — completely inverts the safety check
#   Mutation B: return undef
#
# Kill strategy A (unit — safe list):
#   _can_fixate('a', 42)  → correct: 1 (truthy)
#                         → Mutation A: !1 = '' (falsy)  → ok() fails
#                         → Mutation B: undef  (falsy)   → ok() fails
#
# Kill strategy B (unit — unsafe list):
#   _can_fixate(bless{}) → correct: '' (falsy)
#                        → Mutation A: !'' = 1 (truthy)  → ok(!result) fails
#
# Kill strategy C (integration):
#   Spy on Data::Reuse::fixate during a safe-list miss.  Correct: fixate IS
#   called because _can_fixate returns 1.  Under Mutation A, _can_fixate
#   returns '' → the `if` guard is false → fixate is NOT called → spy count = 0.
# ===========================================================================
subtest 'BOOL_NEGATE_500_2 + RETURN_UNDEF_500_2 – _can_fixate: safe list is truthy' => sub {
	plan tests => 3;

	# Plain scalars are always safe to fixate.
	ok($PKG->_can_fixate('apple', 'banana', 42),
		'_can_fixate: plain-scalar list returns truthy (kills BOOL_NEGATE and RETURN_UNDEF)');

	# Unblessed refs (ARRAY, HASH, SCALAR) are also safe per the regex.
	ok($PKG->_can_fixate([], {}, \42),
		'_can_fixate: unblessed ARRAY/HASH/SCALAR refs return truthy');

	# Vacuously true: none{} over an empty list is 1.
	ok($PKG->_can_fixate(),
		'_can_fixate: empty list returns truthy (vacuous safety)');
};

subtest 'BOOL_NEGATE_500_2 – _can_fixate: unsafe list is falsy' => sub {
	plan tests => 2;

	# Blessed object — fixate would crash (RT#100461): must return false.
	# Under Mutation A: !none{...on unsafe} = !0 = 1 → ok(!result) fails.
	my $blessed = bless {}, 'SomeClass';
	ok(!$PKG->_can_fixate('ok', $blessed),
		'_can_fixate: list with blessed ref returns falsy (RT#100461)');

	# GLOB — also not safe for fixate (RT#163955).
	local *MY_GLOB;
	ok(!$PKG->_can_fixate('ok', \*MY_GLOB),
		'_can_fixate: list with GLOB returns falsy (RT#163955)');
};

subtest 'BOOL_NEGATE_500_2 integration – fixate IS called on safe-list miss' => sub {
	plan tests => 2;

	local %Class::Simple::Readonly::Cached::cached;

	clear_call_log();
	my $spy    = spy 'Data::Reuse::fixate';
	my $inner  = MK::Inner->new;
	my $cached = $PKG->new(object => $inner, cache => {});

	# list_items returns ('alpha', 'beta') — a plain-scalar list, safe for fixate.
	# AUTOLOAD calls: Data::Reuse::fixate(@result) if _can_fixate(@result);
	# Under BOOL_NEGATE_500_2: _can_fixate returns !1 = '' → fixate NOT called.
	my @result = $cached->list_items;
	my $calls  = scalar($spy->());
	restore_all();

	diag("Data::Reuse::fixate call count on safe-list miss: $calls")
		if $ENV{TEST_VERBOSE};

	is_deeply(\@result, ['alpha', 'beta'],
		'list method returns correct values through the cache');
	ok($calls > 0,
		'Data::Reuse::fixate was called on a safe-list miss (kills BOOL_NEGATE_500_2)');
};

done_testing();
