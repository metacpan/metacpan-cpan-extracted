#!/usr/bin/env perl

=head1 NAME

t/extended_tests.t - Tests targeting execution paths not covered by the
existing test suite, aimed at maximising LCSAJ/TER3 branch coverage.

=head1 DESCRIPTION

Each subtest is annotated with the specific conditional branch it exercises,
identified by source-file line and the logical premise that makes it fire.
Subtests are grouped by the method whose uncovered branch they target.

Uncovered branches targeted here (all in lib/Class/Simple/Readonly/Cached.pm):

  can()     line ~403  !ref($self->{object})  -- freed-inner fallback
  isa()     line ~457  class-level call        -- ref($self) = '' in final !!()
  isa()     line ~463  freed inner object      -- ref($self->{object}) = '' in !!()
  AUTOLOAD  line ~572  !ref($self->{object})   -- DESTROY skips registry delete
  new()     line ~249  delete @inner{...}      -- extra kwargs forwarded / filtered
  AUTOLOAD  list path  (undef) in list result  -- stored as [undef], not SENTINEL

=cut

BEGIN { $ENV{HARNESS_ACTIVE} ||= 1 }

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed refaddr);

use_ok('Class::Simple::Readonly::Cached');

# ===========================================================================
# Inline mock packages
# ===========================================================================

# Standard inner object for most tests.
package ExtTest::Inner;
use strict;
use warnings;
sub new         { bless { _n => {} }, shift }
sub ping        { my $s = shift; $s->{_n}{ping}++;        'pong'                      }
sub echo        { my ($s,$v) = @_; $s->{_n}{echo}++;      $v                          }
sub context_val { my $s = shift; $s->{_n}{context_val}++;
	wantarray ? ('list_a','list_b') : 'scalar_only'                     }
sub undef_list  { my $s = shift; $s->{_n}{undef_list}++;  (undef)                     }
sub ncalls      { my ($s,$m) = @_; $s->{_n}{$m} // 0 }

# Two-level class hierarchy for isa()/can() delegation.
package ExtTest::Base;
use strict; use warnings;
sub new         { bless {}, shift }
sub base_method { 'base' }

package ExtTest::Derived;
use strict; use warnings;
our @ISA = ('ExtTest::Base');
sub new            { bless {}, shift }
sub derived_method { 'derived' }

package main;

Readonly::Scalar my $W         => 'Class::Simple::Readonly::Cached';
Readonly::Scalar my $SENTINEL  => 'Class::Simple::Readonly::Cached>UNDEF<';

# ===========================================================================
# SECTION 1: can() -- !ref($self->{object}) branch (line ~403)
#
# Guard clause:
#   return $self->SUPER::can($method)
#       if !ref($self) || !ref($self->{object});
#
# The `!ref($self)` arm (class-level call) is covered in unit.t.
# The `!ref($self->{object})` arm (freed inner) is NOT covered anywhere.
# We simulate a freed inner by directly nulling the field.
# ===========================================================================

subtest 'can(): !ref($self->{object}) -- freed-inner falls back to SUPER::can' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = ExtTest::Inner->new();
	my $cached = $W->new(cache => {}, object => $inner);

	# Simulate global-destruction scenario: inner ref cleared.
	$cached->{object} = undef;

	# 'object' is a real named sub in this package; SUPER::can should find it.
	my $code = $cached->can('object');
	ok(defined($code) && ref($code) eq 'CODE',
		'can("object"): freed inner falls back to SUPER::can -- returns coderef for own method');

	# Unknown method has no coderef anywhere.
	my $undef = $cached->can('no_such_xyz');
	ok(!defined($undef),
		'can("no_such"): freed inner falls back to SUPER::can -- returns undef for unknown');
};

subtest 'can(): class-level call for multiple wrapper-defined methods' => sub {
	# Explicitly exercises the !ref($self) arm for methods beyond 'object'.
	# (unit.t covers 'object'; here we cover 'state', 'can', 'isa'.)
	my $state_ref = $W->can('state');
	ok(defined($state_ref) && ref($state_ref) eq 'CODE',
		'class-level can("state") returns coderef');

	my $can_ref   = $W->can('can');
	ok(defined($can_ref) && ref($can_ref) eq 'CODE',
		'class-level can("can") returns coderef');

	my $isa_ref   = $W->can('isa');
	ok(defined($isa_ref) && ref($isa_ref) eq 'CODE',
		'class-level can("isa") returns coderef');
};

# ===========================================================================
# SECTION 2: isa() -- two previously uncovered paths
#
# Path A (line ~463): class-level call
#   $W->isa('SomeUnrelated')
#   ref($W) = ''   -->  !!('' && ...) = false
#
# Path B (line ~463): freed inner object
#   $cached->{object} = undef
#   ref(undef) = ''  -->  !!(truthy && '' && ...) = false
# ===========================================================================

subtest 'isa(): class-level call with unrelated class reaches !!() path and returns false' => sub {
	# When called on the class string, ref($self) = ''.
	# All four fast-path checks fail for 'SomeUnrelated_XYZ', so we reach the
	# final return !!(ref($self) && ...) where ref('Class::...') = '' → false.
	ok(!$W->isa('SomeUnrelated_XYZ'),
		'class-level isa("SomeUnrelated"): returns false via !!() short-circuit on ref($self)');

	# Class-level true paths: still work.
	ok($W->isa($W),               'class-level isa(wrapper class) returns true');
	ok($W->isa('Class::Simple'),  'class-level isa("Class::Simple") returns true');
	ok($W->isa('UNIVERSAL'),      'class-level isa("UNIVERSAL") returns true via SUPER::isa');
};

subtest 'isa(): freed inner object forces !!() to return false' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = ExtTest::Inner->new();
	my $cached = $W->new(cache => {}, object => $inner);

	# With a live inner object, isa('ExtTest::Inner') delegates and returns true.
	ok($cached->isa('ExtTest::Inner'),
		'sanity: isa(inner class) true before inner freed');

	# Null out the inner: ref($self->{object}) = '' --> !!(...&&''&&...) = false.
	$cached->{object} = undef;

	ok(!$cached->isa('ExtTest::Inner'),
		'isa(inner class): false when inner object ref has been freed');
	ok(!$cached->isa('SomeOtherClass'),
		'isa(unrelated class): also false when inner freed (double-check !!() branch)');

	# Wrapper-level checks are unaffected by the freed inner.
	ok($cached->isa($W),              'isa(wrapper class): still true after inner freed');
	ok($cached->isa('Class::Simple'), 'isa("Class::Simple"): still true after inner freed');
};

# ===========================================================================
# SECTION 3: AUTOLOAD DESTROY -- !ref($self->{object}) guard (line ~572)
#
#   delete $cached{$self->{object}} if ref($self->{object});
#
# When the inner object ref has already been freed, `ref(undef)` = '' (falsy),
# so the delete is skipped.  The test verifies DESTROY does not die and that
# the registry entry is NOT deleted (because the key is undef, not a ref).
# ===========================================================================

subtest 'DESTROY: skips registry delete when inner object ref has been freed' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = ExtTest::Inner->new();
	my $cached = $W->new(cache => {}, object => $inner);

	# The registry maps stringified $inner to the wrapper record.
	ok(exists $Class::Simple::Readonly::Cached::cached{$inner},
		'sanity: inner object is registered before we free it');

	# Free the inner reference on the wrapper side.
	$cached->{object} = undef;

	# DESTROY must survive without dying.
	lives_ok { $cached->DESTROY() }
		'DESTROY does not die when inner object ref has been freed';

	# The registry entry was NOT deleted (nothing to delete under undef key).
	# The original $inner key still exists because the delete was skipped.
	ok(exists $Class::Simple::Readonly::Cached::cached{$inner},
		'registry entry preserved (delete skipped because ref($self->{object}) was false)');
};

subtest 'DESTROY: does not clear _hits/_misses statistics' => sub {
	# DESTROY clears the cache backend but intentionally leaves the stat
	# counters intact so callers can read them post-lifecycle if needed.
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = ExtTest::Inner->new();
	my $cached = $W->new(cache => {}, object => $inner);
	my $key    = "${W}::ping::";

	$cached->ping();   # miss
	$cached->ping();   # hit

	$cached->DESTROY();

	my $s = $cached->state();
	is($s->{misses}{$key}, 1, 'miss count intact after DESTROY');
	is($s->{hits}{$key},   1, 'hit count intact after DESTROY');
};

# ===========================================================================
# SECTION 4: new() -- %inner filtering (lines ~249-251)
#
#   my %inner = %{$params};
#   delete @inner{qw(cache quiet)};
#   $params->{object} = Class::Simple->new(%inner);
#
# Tests verify:
#   (a) Extra user kwargs are forwarded to the auto-created Class::Simple inner.
#   (b) The 'cache' key does NOT appear as an attribute on the inner object.
#   (c) The 'quiet' key does NOT appear as an attribute on the inner object.
# ===========================================================================

subtest 'new(): extra kwargs forwarded to auto-created Class::Simple inner object' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	# 'color' is not a wrapper key; it should be forwarded to Class::Simple->new().
	my $cached = $W->new(cache => {}, color => 'red');
	ok($cached, 'wrapper created with extra kwarg');
	isa_ok($cached->object(), 'Class::Simple', 'auto-created inner is a Class::Simple');

	# Class::Simple stores and returns arbitrary attributes.
	is($cached->object->color(), 'red',
		'"color" kwarg was forwarded to the inner Class::Simple object');
};

subtest 'new(): "cache" and "quiet" keys NOT leaked to inner Class::Simple object' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	# Pass all three key types: a wrapper key (cache), a wrapper flag (quiet),
	# and a user key (label).  Only 'label' should reach the inner object.
	my $cached = $W->new(cache => {}, quiet => 1, label => 'test');
	ok($cached, 'wrapper created with mixed kwargs');

	# User key reached the inner object.
	is($cached->object->label(), 'test',
		'"label" kwarg was forwarded to Class::Simple inner');

	# Wrapper keys must NOT appear as attributes.
	# Class::Simple stores constructor args via an internal accessor mechanism
	# (not a plain hashref).  Use the generated accessor to probe for leakage.
	ok(!defined($cached->object->cache()),
		'"cache" was NOT leaked into Class::Simple inner object');
	ok(!defined($cached->object->quiet()),
		'"quiet" was NOT leaked into Class::Simple inner object');
};

# ===========================================================================
# SECTION 5: AUTOLOAD list-context -- list result containing undef (hash backend)
#
# chi.t covers this scenario with the CHI backend (method 'notdefined').
# The hash backend has not been explicitly tested for this path.
#
# Critical distinction:
#   - empty list  --> stored as UNDEF_SENTINEL (string)
#   - (undef)     --> stored as [undef] (ARRAY ref with one undef element)
#
# This verifies the `if(!@result)` guard is NOT entered for a 1-element-undef
# list, so the non-empty path stores an ARRAY ref and subsequent hits restore
# the full list including the undef element.
# ===========================================================================

subtest 'list context: method returning (undef) stored as [undef], not as UNDEF_SENTINEL' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $c      = {};
	my $inner  = ExtTest::Inner->new();
	my $cached = $W->new(cache => $c, object => $inner);
	my $key    = "${W}::undef_list::";

	# --- Miss ---
	my @result = $cached->undef_list();

	is(scalar @result, 1,
		'undef_list() in list context: returns a 1-element list');
	ok(!defined($result[0]),
		'the single element is undef');
	is(ref($c->{$key}), 'ARRAY',
		'(undef) list stored as ARRAY ref, NOT the UNDEF_SENTINEL string');
	isnt($c->{$key}, $SENTINEL,
		'stored value is NOT the UNDEF_SENTINEL');

	my $s = $cached->state();
	is($s->{misses}{$key}, 1, '1 miss after first call');

	# --- Hit ---
	my @hit = $cached->undef_list();

	is(scalar @hit, 1,   'hit: still a 1-element list');
	ok(!defined($hit[0]), 'hit: element is still undef');

	is($inner->ncalls('undef_list'), 1,
		'inner called only once: second call served from cache (hit)');
	is($cached->state()->{hits}{$key}, 1, '1 hit after second call');
};

subtest 'list context: single-element ARRAY hit in scalar context returns that element' => sub {
	# When [undef] is served in scalar context, $cached_val->[-1] = undef.
	# We must prime the cache with a LIST-context call so [undef] (ARRAY ref)
	# is stored, not the UNDEF_SENTINEL (which would be stored by a scalar/void
	# context priming call and would follow a different hit branch entirely).
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => ExtTest::Inner->new());

	my @first = $cached->undef_list();   # LIST-context miss → stores [undef] ARRAY ref
	is(scalar @first, 1, 'sanity: list miss returns 1-element list');

	# Scalar-context hit: ARRAY ref is found; returns $cached_val->[-1] = undef.
	my $scalar_hit = $cached->undef_list();
	ok(!defined($scalar_hit),
		'scalar-context hit on [undef] ARRAY cache returns undef ($cached_val->[-1])');

	my $s = $cached->state();
	is($s->{hits}{"${W}::undef_list::"}, 1,
		'1 hit after scalar-context read of the list-cached [undef]');
};

# ===========================================================================
# SECTION 6: State tracking -- scalar-then-list fallthrough miss count
#
# When a method is first called in scalar context (miss, scalar stored) and
# then in list context (fallthrough -- scalar cannot serve list, treated as
# second miss), the miss counter must reach 2.
#
# Existing tests verify the correct return values; none assert the count = 2.
# ===========================================================================

subtest 'state(): miss count = 2 after scalar-context miss then list-context fallthrough' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = ExtTest::Inner->new();
	my $cached = $W->new(cache => {}, object => $inner);
	my $key    = "${W}::context_val::";

	# --- First call: scalar context ---
	my $scalar = $cached->context_val();
	is($scalar, 'scalar_only', 'first call (scalar): correct scalar returned');
	is($cached->state()->{misses}{$key}, 1,
		'miss count = 1 after first (scalar) call');

	# --- Second call: list context ---
	# The scalar cached entry cannot serve a list-context caller.
	# AUTOLOAD falls through to re-invoke the inner object -- a second miss.
	my @list = $cached->context_val();
	is_deeply(\@list, ['list_a','list_b'],
		'second call (list context): correct list returned via re-invocation');
	is($cached->state()->{misses}{$key}, 2,
		'miss count = 2 after list-context fallthrough (both scalar and list are misses)');

	# Inner was called exactly twice.
	is($inner->ncalls('context_val'), 2,
		'inner invoked twice: once for scalar miss, once for list-context fallthrough');

	# --- Third call: scalar context (hit on the NOW-OVERWRITTEN array form) ---
	# The list-context fallthrough stored ['list_a','list_b'] under the SAME key,
	# OVERWRITING the earlier 'scalar_only' scalar entry.  A scalar-context hit on
	# an ARRAY ref returns $cached_val->[-1] = 'list_b', NOT 'scalar_only'.
	# This is the documented ARRAY-hit-in-scalar-context behaviour.
	my $scalar2 = $cached->context_val();
	is($scalar2, 'list_b',
		'third call (scalar context): returns last element of ARRAY (scalar form overwritten)');
	is($cached->state()->{hits}{$key}, 1,
		'hit count = 1 after third call');
	is($inner->ncalls('context_val'), 2,
		'inner NOT called again: ARRAY cache entry served the scalar-context request');

	# --- Fourth call: list context (hit on ARRAY form) ---
	my @list2 = $cached->context_val();
	is_deeply(\@list2, ['list_a','list_b'], 'fourth call (list context): ARRAY cache hit');
	is($cached->state()->{hits}{$key}, 2,
		'hit count = 2 after fourth call');
};

# ===========================================================================
# SECTION 7: Post-DESTROY wrapper usability
#
# After an explicit DESTROY(), the cache is cleared but the wrapper's
# {object} is still intact.  A subsequent method call must re-invoke the
# inner object (fresh miss) rather than returning stale data or crashing.
# ===========================================================================

subtest 'post-DESTROY: wrapper re-usable as a fresh cache after explicit DESTROY' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner  = ExtTest::Inner->new();
	my $c      = {};
	my $cached = $W->new(cache => $c, object => $inner);
	my $key    = "${W}::ping::";

	$cached->ping();   # miss 1
	$cached->ping();   # hit 1
	is($inner->ncalls('ping'), 1, 'inner called once before DESTROY');

	$cached->DESTROY();
	ok(!exists $c->{$key}, 'DESTROY: cache entry cleared');

	# Re-register so we can wrap the inner again without a double-wrap warning.
	$cached = $W->new(cache => $c, object => $inner);

	$cached->ping();   # miss 2 (fresh wrapper)
	is($inner->ncalls('ping'), 2,
		'inner called again after DESTROY: cache was cleared, so re-invoked');
	is($cached->state()->{misses}{$key}, 1, 'new wrapper shows 1 miss');
	ok(!exists $cached->state()->{hits}{$key} || !defined($cached->state()->{hits}{$key}),
		'new wrapper shows 0 hits');
};

# ===========================================================================
# SECTION 8: can() and isa() delegation through a class hierarchy
#
# These cover the happy-path delegation to the inner object for inherited
# methods, confirming that the !ref() guards are the ONLY deviation from
# normal delegation.  Explicitly covers ExtTest::Derived (which inherits
# ExtTest::Base) so the delegation chain is longer than one hop.
# ===========================================================================

subtest 'can(): delegates through multi-level class hierarchy' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $derived = ExtTest::Derived->new();
	my $cached  = $W->new(cache => {}, object => $derived);

	my $code_derived = $cached->can('derived_method');
	ok(defined($code_derived) && ref($code_derived) eq 'CODE',
		'can("derived_method"): finds method directly on inner class');

	my $code_base = $cached->can('base_method');
	ok(defined($code_base) && ref($code_base) eq 'CODE',
		'can("base_method"): finds inherited method one level up');

	ok(!$cached->can('completely_unknown_xyz'),
		'can("completely_unknown"): returns false for nonexistent method');
};

subtest 'isa(): delegates through multi-level class hierarchy' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $derived = ExtTest::Derived->new();
	my $cached  = $W->new(cache => {}, object => $derived);

	ok($cached->isa('ExtTest::Derived'), 'isa(inner class): true');
	ok($cached->isa('ExtTest::Base'),    'isa(inner base class): true -- inherited');
	ok(!$cached->isa('ExtTest::UnrelatedXYZ'),
		'isa(unrelated class): false -- not in hierarchy');
};

# ===========================================================================
# SECTION 9: isa() -- SUPER::isa path explicitly traced
#
# The fourth fast-path check:  `$self->SUPER::isa($class)`.
# This fires for 'UNIVERSAL', which every object inherits from.
# The path is distinct from the wrapper-class checks above it; tracing it
# explicitly here ensures the SUPER::isa branch is independently verified.
# ===========================================================================

subtest 'isa(): SUPER::isa("UNIVERSAL") returns true (all objects are-a UNIVERSAL)' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $cached = $W->new(cache => {}, object => ExtTest::Inner->new());

	# 'UNIVERSAL' is not eq ref($self), not eq __PACKAGE__, not eq 'Class::Simple'.
	# It IS found by SUPER::isa (UNIVERSAL::isa reports every object as UNIVERSAL).
	ok($cached->isa('UNIVERSAL'),
		'isa("UNIVERSAL"): true via SUPER::isa (Perl internal hierarchy)');
};

# ===========================================================================
# SECTION 10: new() clone -- various argument forms
#
# The clone path calls:
#   my $params = Params::Get::get_params(undef, \@_) // {};
#
# Verify the // {} fallback (empty args) and that a non-cache param on
# the clone does NOT trigger _build_cache_accessors.
# ===========================================================================

subtest 'new() clone: no-arg call uses // {} fallback and shares cache' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner    = ExtTest::Inner->new();
	my $cache    = {};
	my $original = $W->new(cache => $cache, object => $inner);
	$original->ping();   # populate cache

	# $original->new() with no args -- Params::Get returns undef, // {} kicks in.
	my $clone = $original->new();
	isa_ok($clone, $W, 'clone from no-arg new()');
	is(refaddr($clone->{cache}), refaddr($cache),
		'no-arg clone shares the same cache reference');

	# Cache hit across the clone boundary.
	my $result = $clone->ping();
	is($result, 'pong', 'no-arg clone serves cache hit from original\'s miss');
	is($inner->ncalls('ping'), 1,
		'inner NOT re-invoked: clone used shared cache');
};

subtest 'new() clone: non-cache param does NOT trigger _build_cache_accessors' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	my $inner    = ExtTest::Inner->new();
	my $original = $W->new(cache => {}, object => $inner);

	# Passing a non-cache kwarg (quiet => 0).  Since 'cache' is not in the clone
	# params, _build_cache_accessors should NOT be called, and the clone's
	# _get/_set should remain identical coderefs.
	my $get_before = $original->{_get};
	my $clone = $original->new(quiet => 0);

	is(refaddr($clone->{_get}), refaddr($get_before),
		'non-cache clone param does not rebuild _get/_set (same coderef reference)');
};

# ===========================================================================
# SECTION 11: AUTOLOAD list-context empty result (UNDEF_SENTINEL) -- hash backend
#
# hash.t covers this path, but the verification there is behavioural
# (returns undef in scalar context).  Here we explicitly assert the sentinel
# string is stored so the three stored-value forms are each independently proven:
#   (a) ARRAY ref   -- for non-empty list
#   (b) SENTINEL    -- for empty / undef scalar
#   (c) plain scalar -- for defined scalar
# ===========================================================================

subtest 'AUTOLOAD list miss: empty list stored as UNDEF_SENTINEL in hash backend' => sub {
	local %Class::Simple::Readonly::Cached::cached;

	# Use a Class::Simple inner whose method returns an empty list.
	my $inner = Class::Simple->new();
	my $c     = {};
	my $cached = $W->new(cache => $c, object => $inner);

	# Use AUTOLOAD on Class::Simple to get an undef/empty-list method.
	# Class::Simple returns undef for unset attributes, which in list context
	# is (undef), a 1-element list -- NOT empty.
	# Instead create a wrapper around a bare sub that returns ().
	package ExtTest::EmptyList;
	use strict; use warnings;
	sub new    { bless {}, shift }
	sub empty  { () }

	package main;

	local %Class::Simple::Readonly::Cached::cached;
	my $c2      = {};
	my $inner2  = ExtTest::EmptyList->new();
	my $cached2 = $W->new(cache => $c2, object => $inner2);
	my $key     = "${W}::empty::";

	my @r = $cached2->empty();
	is(scalar @r, 0, 'empty() returns empty list on miss');
	is($c2->{$key}, $SENTINEL,
		'empty list stored as UNDEF_SENTINEL in hash cache (not as ARRAY ref)');

	# Verify hit returns empty list.
	my @r2 = $cached2->empty();
	is(scalar @r2, 0, 'empty() returns empty list on hit');
	is($cached2->state()->{hits}{$key}, 1,
		'hit counter incremented for empty-list cache hit');
};

done_testing;
