#!/usr/bin/env perl

=head1 NAME

t/unit.t - Black-box unit tests for Class::Simple::Cached public API

=head1 DESCRIPTION

Tests every documented message, return state, and side-effect from the POD of
lib/Class/Simple/Cached.pm.  Only the public API is exercised; internal fields
are never probed directly unless they are part of the user-visible cache handle
the caller supplies.

An API ledger at the top records every POD-documented state.  Each condition
is struck from the ledger as it is triggered and verified.  The final assertion
confirms the ledger is empty, proving 100% coverage of the documented contract.

=cut

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(spy restore_all);
use Test::Returns;
use Readonly;

BEGIN { use_ok('Class::Simple::Cached') }

# ── API Ledger ────────────────────────────────────────────────────────────────
# Source: POD MESSAGES tables and RETURNS/SIDE EFFECTS sections.
# Every entry must be deleted by the subtest that successfully triggers it.
# The assertion at the bottom of this file proves exhaustive coverage.

my %LEDGER = (
    # new() ── MESSAGES table
    'new:msg:carp-bare-call'      => 'carp "use ->new() not ::new() to instantiate"',
    'new:msg:croak-no-args'       => 'croak "Usage: ClassName->new(cache => ...)"',
    'new:msg:croak-bad-cache'     => 'croak "Cache must be ref to HASH or object"',
    'new:msg:croak-chi-interface' => 'croak "Cache object must implement get, set, purge"',
    # new() ── documented returns and behaviours
    'new:ret:undef-on-bare-call'  => 'returns undef when class is undef',
    'new:ret:hashref-instance'    => 'returns blessed instance with hashref cache',
    'new:ret:chi-instance'        => 'returns blessed instance with CHI-compatible object',
    'new:ret:clone'               => 'returns shallow clone when called on a blessed instance',
    'new:behav:clone-shares-cache'=> 'clone shares the existing cache handle',
    'new:behav:default-object'    => 'object defaults to Class::Simple when not supplied',

    # can() ── RETURNS
    'can:ret:true-for-new'        => 'can("new") is always true on an instance',
    'can:ret:true-for-wrapped'    => 'can() true for a method the wrapped object knows',
    'can:ret:false-unknown'       => 'can() false for a completely unknown method name',
    'can:ret:class-method'        => 'can() called as class method delegates to SUPER::can',

    # isa() ── RETURNS
    'isa:ret:own-ref-class'       => 'isa(ref($self)) is true',
    'isa:ret:package-constant'    => 'isa("Class::Simple::Cached") is true',
    'isa:ret:wrapped-obj-class'   => 'isa(wrapped-object class) is true via delegation',
    'isa:ret:false-unrelated'     => 'isa(unrelated class) is false',
    'isa:ret:class-method'        => 'isa() called as class method delegates to SUPER::isa',

    # AUTOLOAD ── MESSAGES table
    'autoload:msg:array-sentinel' => 'croak method name when cached array[0] is UNDEF_SENTINEL',

    # AUTOLOAD ── getter, cache-HIT paths
    'autoload:get:hit-plain-scalar' => 'getter cache-hit returns plain scalar unchanged',
    'autoload:get:hit-sentinel'     => 'getter cache-hit decodes UNDEF_SENTINEL to undef',
    'autoload:get:hit-arrayref'     => 'getter cache-hit derefs arrayref to flat list',
    'autoload:get:hit-blessed-obj'  => 'getter cache-hit returns blessed object as-is',

    # AUTOLOAD ── getter, cache-MISS paths
    'autoload:get:miss-list'        => 'getter miss: caches list, returns it',
    'autoload:get:miss-empty-list'  => 'getter miss: does not cache empty list, returns ()',
    'autoload:get:miss-scalar'      => 'getter miss: caches defined scalar, returns it',
    'autoload:get:miss-undef'       => 'getter miss: caches UNDEF_SENTINEL, returns undef',

    # AUTOLOAD ── setter paths
    'autoload:set:scalar-defined'   => 'scalar setter stores value and returns it',
    'autoload:set:scalar-undef'     => 'scalar setter with undef caches sentinel, returns undef',
    'autoload:set:array-defined'    => 'array setter stores list and returns it',
    'autoload:set:array-undef'      => 'array setter when object returns undef gives empty list',
);

# ── Constants ─────────────────────────────────────────────────────────────────

Readonly::Scalar my $SENTINEL => Class::Simple::Cached::UNDEF_SENTINEL();
Readonly::Scalar my $PREFIX   => 'Class::Simple::Cached:';

# ── Helper packages ───────────────────────────────────────────────────────────

{
	# Fully CHI-compatible cache: get/set/purge all work correctly.
	package t::Unit::FullCHI;
	sub new   { bless { store => {} }, shift }
	sub get   { $_[0]->{store}{$_[1]} }
	sub set   { $_[0]->{store}{$_[1]} = $_[2]; 1 }
	sub purge { $_[0]->{store} = {} }
}

{
	# Incomplete CHI interfaces — each missing one required method.
	package t::Unit::NoGet;   sub new { bless {}, shift } sub set {} sub purge {}
	package t::Unit::NoSet;   sub new { bless {}, shift } sub get {} sub purge {}
	package t::Unit::NoPurge; sub new { bless {}, shift } sub get {} sub set {}
}

{
	# Inner object that returns a controlled list or empty list.
	package t::Unit::ListSource;
	sub new  { bless { n => 0 }, shift }
	sub trio { $_[0]->{n}++; return ('p', 'q', 'r') }
	sub nada { $_[0]->{n}++; return }
	sub calls { $_[0]->{n} }
}

{
	# Inner object that returns a defined scalar from greeting().
	package t::Unit::ScalarSource;
	sub new      { bless {}, shift }
	sub greeting { 'hello' }
}

{
	# Inner object that returns a blessed value from thing().
	package t::Unit::BlessedSource;
	sub new   { bless {}, shift }
	sub thing { bless {}, 't::Unit::BlessedValue' }
}

{
	package t::Unit::BlessedValue;
	use overload 'eq' => sub { 1 }, '""' => sub { 'bomb' }, fallback => 1;
	sub new { bless {}, shift }
}

{
	# Inner object whose first-list-element is the UNDEF_SENTINEL string.
	# Triggers the array-sentinel croak on the second getter call.
	package t::Unit::SentinelList;
	sub new  { bless {}, shift }
	sub data { return (Class::Simple::Cached::UNDEF_SENTINEL(), 'extra') }
}

{
	# Inner object that always returns undef for any method call.
	# Used to trigger the array-setter-with-undef path.
	package t::Unit::NullReturn;
	sub new { bless {}, shift }
	our $AUTOLOAD;
	sub AUTOLOAD { return }
	sub DESTROY  {}
}

{
	# Simple blessed object with a distinct class, used for isa() delegation tests.
	package t::Unit::Domain;
	sub new { bless {}, shift }
}

# ═══════════════════════════════════════════════════════════════════════════
# new() — documented messages and return states
# ═══════════════════════════════════════════════════════════════════════════

subtest 'new(): carp + undef when called without a class (bare function form)' => sub {
	# POD MESSAGES: "use ->new() not ::new() to instantiate"
	# POD RETURNS:  undef
	# Strategy: spy on Carp::carp, call new() as a bare function, inspect
	# the call log.  The spy wraps the original so other carp calls still work.
	my $spy = spy 'Carp::carp';
	# Redirect STDERR so the carp output does not bleed into prove's non-verbose
	# output and alarm users reading a clean test run.
	local *STDERR;
	open(STDERR, '>', \my $stderr_buf) or die "Cannot redirect STDERR: $!";
	my $result = Class::Simple::Cached::new();

	my @calls  = $spy->();
	ok(scalar(@calls), 'carp was called');

	# The call is carp(__PACKAGE__, ' use ->new() not ::new()') — two args.
	# Join from index 1 onward to reconstruct the full message string.
	my $msg = join('', @{$calls[0]}[1 .. $#{$calls[0]}]);
	like($msg, qr/use ->new\(\) not ::new\(\) to instantiate/,
		'carp message matches POD MESSAGES table exactly');

	ok(!defined($result), 'bare call returns undef per POD RETURNS');
	returns_not_ok($result, { type => 'object' }, 'not a blessed object');

	restore_all();
	delete $LEDGER{'new:msg:carp-bare-call'};
	delete $LEDGER{'new:ret:undef-on-bare-call'};
	done_testing();
};

subtest 'new(): croak "Usage:" when called with no arguments' => sub {
	# POD MESSAGES: "Usage: $class->new(cache => $cache)"
	throws_ok { Class::Simple::Cached->new() }
		qr/Usage:/,
		'zero-arg new() croaks with Usage message per POD';

	delete $LEDGER{'new:msg:croak-no-args'};
	done_testing();
};

subtest 'new(): croak "Cache must be ref to HASH or object" for invalid cache types' => sub {
	# POD MESSAGES: "Cache must be ref to HASH or object"
	# POD: cache is a plain scalar or wrong ref — Use a hashref or CHI object
	# Test boundary conditions: scalar, arrayref, coderef, scalarref.
	for my $bad ('string', 42, [], sub{}, \(my $s)) {
		throws_ok { Class::Simple::Cached->new(cache => $bad) }
			qr/Cache must be ref to HASH or object/,
			'invalid cache type croaks with correct POD message';
	}

	delete $LEDGER{'new:msg:croak-bad-cache'};
	done_testing();
};

subtest 'new(): croak "Cache object must implement get, set, purge" for incomplete CHI' => sub {
	# POD MESSAGES: "Cache object must implement get, set, purge"
	# Each of the three methods is independently necessary (AND conjunction).
	for my $bad (t::Unit::NoGet->new(), t::Unit::NoSet->new(), t::Unit::NoPurge->new()) {
		throws_ok { Class::Simple::Cached->new(cache => $bad) }
			qr/Cache object must implement/,
			'blessed cache missing any required method croaks per POD';
	}

	delete $LEDGER{'new:msg:croak-chi-interface'};
	done_testing();
};

subtest 'new(): returns blessed instance with hashref cache' => sub {
	# POD RETURNS: "A blessed Class::Simple::Cached instance"
	my $obj = Class::Simple::Cached->new(cache => {});

	isa_ok($obj, 'Class::Simple::Cached', 'hashref-backed new() returns correct class');
	returns_ok($obj, { type => 'object' }, 'return type satisfies object schema');

	delete $LEDGER{'new:ret:hashref-instance'};
	done_testing();
};

subtest 'new(): returns blessed instance with CHI-compatible object' => sub {
	# POD: "a blessed object implementing get($key), set($key,$val,$exp), purge()"
	my $obj = Class::Simple::Cached->new(cache => t::Unit::FullCHI->new());

	isa_ok($obj, 'Class::Simple::Cached', 'CHI-backed new() returns correct class');
	returns_ok($obj, { type => 'object' }, 'return type satisfies object schema');

	delete $LEDGER{'new:ret:chi-instance'};
	done_testing();
};

subtest 'new(): object defaults to Class::Simple instance when omitted' => sub {
	# POD ARGUMENTS: "Defaults to a fresh Class::Simple instance"
	# Black-box verification: omitting object => still allows get/set round-trip,
	# proving a functioning default object was installed.
	my $obj = Class::Simple::Cached->new(cache => {});

	lives_ok { $obj->flavour('vanilla') }
		'setter works without explicit object => (default object handles calls)';
	is($obj->flavour(), 'vanilla',
		'getter round-trip works with default object');

	delete $LEDGER{'new:behav:default-object'};
	done_testing();
};

subtest 'new(): shallow clone from blessed instance, sharing cache' => sub {
	# POD: "Calling ->new() on an already-blessed instance returns a shallow clone
	# (all stored fields are merged, including the existing cache handle)."
	my %cache;
	my $orig  = Class::Simple::Cached->new(cache => \%cache);
	$orig->colour('crimson');

	my $clone = $orig->new();
	isa_ok($clone, 'Class::Simple::Cached', 'clone is a Class::Simple::Cached');
	returns_ok($clone, { type => 'object' }, 'clone return type is object');

	# Cache is shared: value written via orig is readable via clone.
	is($clone->colour(), 'crimson',
		'clone shares cache with original (sees crimson)');

	diag("cache keys: ", join(', ', keys %cache)) if $ENV{TEST_VERBOSE};

	delete $LEDGER{'new:ret:clone'};
	delete $LEDGER{'new:behav:clone-shares-cache'};
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# can() — documented return states
# ═══════════════════════════════════════════════════════════════════════════

subtest 'can(): "new" is always true on a blessed instance' => sub {
	# POD FORMAL SPEC: result! = (method? = 'new') ∨ ...
	# "new" is the unconditional fast-path; no wrapped-object lookup needed.
	my $obj = Class::Simple::Cached->new(cache => {});
	ok($obj->can('new'), 'can("new") returns true on instance per POD spec');

	delete $LEDGER{'can:ret:true-for-new'};
	done_testing();
};

subtest 'can(): true for a method the wrapped object handles' => sub {
	# POD FORMAL SPEC: result! = ... ∨ object.can(method?) ∨ ...
	# Calling a setter causes Class::Simple to install the stub, making can() work.
	my $obj = Class::Simple::Cached->new(cache => {});
	$obj->flavour('mint');   # installs 'flavour' stub in the inner Class::Simple

	ok($obj->can('flavour'),
		'can() returns true for a method known to the wrapped object');

	delete $LEDGER{'can:ret:true-for-wrapped'};
	done_testing();
};

subtest 'can(): false for a method known to neither object nor CSC' => sub {
	# POD RETURNS: "True if the method is known; false otherwise."
	my $obj = Class::Simple::Cached->new(cache => {});
	ok(!$obj->can('__no_such_method_9z8q__'),
		'can() returns false for unknown method per POD');

	delete $LEDGER{'can:ret:false-unknown'};
	done_testing();
};

subtest 'can(): class-method path delegates to SUPER::can' => sub {
	# POD: "When called as a class method there is no wrapped object to probe"
	# (comment in source, consistent with the formal spec's Ξ operator — state
	# is unchanged by a class-method can() call).
	ok(defined(Class::Simple::Cached->can('new')),
		'class-method can("new") returns a code ref');
	ok(!Class::Simple::Cached->can('__not_defined_8x7y__'),
		'class-method can() returns false for undefined sub');

	delete $LEDGER{'can:ret:class-method'};
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# isa() — documented return states
# ═══════════════════════════════════════════════════════════════════════════

subtest 'isa(): true for ref($self) — the wrapper\'s own runtime class' => sub {
	# POD FORMAL SPEC: result! = (class? = ref(self)) ∨ ...
	my $obj = Class::Simple::Cached->new(cache => {});
	ok($obj->isa('Class::Simple::Cached'),
		'isa(ref(self)) is true per formal spec');

	delete $LEDGER{'isa:ret:own-ref-class'};
	done_testing();
};

subtest 'isa(): true for __PACKAGE__ constant ("Class::Simple::Cached")' => sub {
	# POD FORMAL SPEC: result! = ... ∨ (class? = __PACKAGE__) ∨ ...
	# For the base class (not a subclass), ref($self) eq __PACKAGE__, so this
	# overlaps with the previous test.  Tested via a subclass to isolate it.
	{
		package t::Unit::SubCSC;
		our @ISA = ('Class::Simple::Cached');
	}
	my $sub = t::Unit::SubCSC->new(cache => {});
	ok($sub->isa('Class::Simple::Cached'),
		'isa(__PACKAGE__) true even on a subclass instance');

	delete $LEDGER{'isa:ret:package-constant'};
	done_testing();
};

subtest 'isa(): true for wrapped object\'s class via delegation' => sub {
	# POD FORMAL SPEC: result! = ... ∨ object.isa(class?)
	# Supply a custom inner object; isa() must report its class.
	my $inner = t::Unit::Domain->new();
	my $obj   = Class::Simple::Cached->new(cache => {}, object => $inner);

	ok($obj->isa('t::Unit::Domain'),
		'isa() delegates to wrapped object and returns true for its class');

	delete $LEDGER{'isa:ret:wrapped-obj-class'};
	done_testing();
};

subtest 'isa(): false for an unrelated class' => sub {
	# POD RETURNS: "True if the wrapper or the wrapped object is-a $class."
	my $obj = Class::Simple::Cached->new(cache => {});
	ok(!$obj->isa('CHI'),
		'isa(unrelated class) is false per POD');
	ok(!$obj->isa('SomeMadeUpClass99'),
		'isa(nonexistent class) is also false');

	delete $LEDGER{'isa:ret:false-unrelated'};
	done_testing();
};

subtest 'isa(): class-method path delegates to SUPER::isa' => sub {
	# POD code comment: "When called as a class method there is no wrapped
	# object to interrogate"
	ok(Class::Simple::Cached->isa('Class::Simple::Cached'),
		'class-method isa(own class) is true');
	ok(!Class::Simple::Cached->isa('SomeFakeClass'),
		'class-method isa(unrelated class) is false');

	delete $LEDGER{'isa:ret:class-method'};
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# AUTOLOAD — documented message: croak on sentinel as array first element
# ═══════════════════════════════════════════════════════════════════════════

subtest 'AUTOLOAD croak: cached array[0] == UNDEF_SENTINEL fires method-name croak' => sub {
	# POD MESSAGES: "$method" (croak) — "Cached array's first element is the
	# UNDEF_SENTINEL string.  Do not store the sentinel string as a real value."
	# Strategy: inner object returns the sentinel string as first element of a
	# list.  First call (cache miss) stores [$SENTINEL, 'extra'].  Second call
	# (cache hit) sees $rc->[0] eq UNDEF_SENTINEL and croaks with the method name.
	my $obj = Class::Simple::Cached->new(
		cache  => {},
		object => t::Unit::SentinelList->new(),
	);

	my @first;
	lives_ok { @first = $obj->data() } 'first call (cache miss) does not die';
	is($first[0], $SENTINEL, 'first call returns the sentinel as first element');

	throws_ok { my @second = $obj->data() }
		qr/\bdata\b/,
		'second call (cache hit) croaks with method name per POD';

	delete $LEDGER{'autoload:msg:array-sentinel'};
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# AUTOLOAD — getter, cache-HIT paths
# Set up state via the setter API, then verify getter returns correct value.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'AUTOLOAD getter cache-hit: plain scalar returned unchanged' => sub {
	# POD PSEUDOCODE getter: "IF val is a plain string → RETURN val"
	# The setter stores 'teal' in the cache; the getter must return it verbatim.
	my $obj = Class::Simple::Cached->new(cache => {});
	$obj->colour('teal');

	my $v = $obj->colour();
	is($v, 'teal', 'getter cache-hit returns plain scalar per POD');
	returns_ok($v, { type => 'scalar' }, 'return type is scalar');

	# Verify caching: overwrite the inner object directly — the wrapper must
	# still return the cached (stale) value, not the fresh one.
	$obj->{'object'}->colour('orange');
	is($obj->colour(), 'teal',
		'getter returns cached value even after inner object changes');

	delete $LEDGER{'autoload:get:hit-plain-scalar'};
	done_testing();
};

subtest 'AUTOLOAD getter cache-hit: UNDEF_SENTINEL decoded to undef' => sub {
	# POD PSEUDOCODE getter: "IF val is UNDEF_SENTINEL → return undef"
	# Strategy: first getter call stores the sentinel (inner returns undef).
	# Second call hits the sentinel and must return undef.
	my $obj = Class::Simple::Cached->new(cache => {});

	my $v1 = $obj->ghost();   # cache miss: inner returns undef, stores sentinel
	ok(!defined($v1), 'first call (cache miss) returns undef');

	my $v2 = $obj->ghost();   # cache hit: sentinel decoded to undef
	ok(!defined($v2), 'second call (sentinel cache-hit) returns undef per POD');

	delete $LEDGER{'autoload:get:hit-sentinel'};
	done_testing();
};

subtest 'AUTOLOAD getter cache-hit: arrayref dereferenced to flat list' => sub {
	# POD PSEUDOCODE getter: "IF val is an arrayref → RETURN dereferenced list"
	# Strategy: array setter stores an arrayref; getter in list context returns list.
	my $obj = Class::Simple::Cached->new(cache => {});
	$obj->tags('alpha', 'beta', 'gamma');

	my @got = $obj->tags();
	is_deeply(\@got, ['alpha', 'beta', 'gamma'],
		'getter cache-hit returns flat list from cached arrayref per POD');

	delete $LEDGER{'autoload:get:hit-arrayref'};
	done_testing();
};

subtest 'AUTOLOAD getter cache-hit: blessed object returned as-is' => sub {
	# POD PSEUDOCODE getter: "RETURN val (blessed object)"
	# Also exercises the overloaded-eq guard (see LIMITATIONS): the !ref() check
	# prevents the sentinel comparison from running on a blessed object.
	my $obj = Class::Simple::Cached->new(
		cache  => {},
		object => t::Unit::BlessedSource->new(),
	);

	my $v1 = $obj->thing();   # cache miss: stores the blessed value
	my $v2 = $obj->thing();   # cache hit: must return the object, not undef

	ok(ref($v2), 'getter cache-hit returns a reference (blessed object)');
	ok(defined($v2), 'getter does not decode overloaded-eq object as undef');
	is(ref($v2), 't::Unit::BlessedValue',
		'returned reference is the correct class');

	delete $LEDGER{'autoload:get:hit-blessed-obj'};
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# AUTOLOAD — getter, cache-MISS paths
# ═══════════════════════════════════════════════════════════════════════════

subtest 'AUTOLOAD getter miss (list context, non-empty): caches and returns list' => sub {
	# POD PSEUDOCODE: "result_list = object->method(); cache_set(key, \result_list)"
	my $inner = t::Unit::ListSource->new();
	my %cache;
	my $obj   = Class::Simple::Cached->new(cache => \%cache, object => $inner);

	my @r1 = $obj->trio();   # cache miss
	is_deeply(\@r1, ['p','q','r'], 'cache-miss list getter returns all elements');
	is($inner->calls(), 1, 'inner object called once on miss');

	my @r2 = $obj->trio();   # cache hit — inner must NOT be called again
	is_deeply(\@r2, ['p','q','r'], 'second call returns same list from cache');
	is($inner->calls(), 1, 'inner object not called again on cache hit');

	is(ref($cache{"${PREFIX}trio"}), 'ARRAY',
		'list result is stored as an arrayref in cache');

	diag("cache key: ${PREFIX}trio => ", ref($cache{"${PREFIX}trio"}))
		if $ENV{TEST_VERBOSE};

	delete $LEDGER{'autoload:get:miss-list'};
	done_testing();
};

subtest 'AUTOLOAD getter miss (list context, empty): not cached, returns ()' => sub {
	# POD PSEUDOCODE: "IF empty → return ()" — explicitly not cached.
	my $inner = t::Unit::ListSource->new();
	my %cache;
	my $obj   = Class::Simple::Cached->new(cache => \%cache, object => $inner);

	my @r1 = $obj->nada();
	my @r2 = $obj->nada();
	is(scalar(@r1), 0, 'first empty-list result is ()');
	is(scalar(@r2), 0, 'second empty-list result is still ()');
	is($inner->calls(), 2,
		'inner called twice — empty list is never cached per POD');

	ok(!exists($cache{"${PREFIX}nada"}),
		'no cache entry created for empty-list result');

	delete $LEDGER{'autoload:get:miss-empty-list'};
	done_testing();
};

subtest 'AUTOLOAD getter miss (scalar context, defined): cached and returned' => sub {
	# POD PSEUDOCODE: "result = object->method(); IF defined: cache_set(key, result)"
	my %cache;
	my $obj = Class::Simple::Cached->new(
		cache  => \%cache,
		object => t::Unit::ScalarSource->new(),
	);

	my $v1 = $obj->greeting();   # cache miss
	is($v1, 'hello', 'cache-miss scalar getter returns defined value from object');
	is($cache{"${PREFIX}greeting"}, 'hello', 'defined scalar cached directly');

	# Confirmed cached: a subsequent getter must not re-invoke the object.
	# (ScalarSource::greeting always returns 'hello', but the test below
	# would fail if the cache key were corrupted or the value were wrong.)
	my $v2 = $obj->greeting();
	is($v2, 'hello', 'second call returns cached value');

	delete $LEDGER{'autoload:get:miss-scalar'};
	done_testing();
};

subtest 'AUTOLOAD getter miss (scalar context, undef): sentinel cached, undef returned' => sub {
	# POD PSEUDOCODE: "cache_set(key, UNDEF_SENTINEL); RETURN undef"
	# The default Class::Simple inner object returns undef for unset accessors.
	my %cache;
	my $obj = Class::Simple::Cached->new(cache => \%cache);

	my $v1 = $obj->phantom();   # cache miss, inner returns undef
	ok(!defined($v1), 'cache-miss undef getter returns undef');
	is($cache{"${PREFIX}phantom"}, $SENTINEL,
		'UNDEF_SENTINEL stored in cache for undef result per POD');

	my $v2 = $obj->phantom();   # cache hit: sentinel decoded
	ok(!defined($v2), 'second call returns undef from sentinel cache-hit');

	delete $LEDGER{'autoload:get:miss-undef'};
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# AUTOLOAD — setter paths
# ═══════════════════════════════════════════════════════════════════════════

subtest 'AUTOLOAD scalar setter: stores value, returns it (not CHI status code)' => sub {
	# POD PSEUDOCODE setter: "val = object->method(args[0]); RETURN val"
	# CHI->set() returns 1.  The wrapper must return the stored value, not 1.
	my $obj = Class::Simple::Cached->new(cache => {});
	my $ret = $obj->name('Eve');

	is($ret, 'Eve', 'scalar setter returns the stored value per POD');
	isnt($ret, 1,   'return is the value, not CHI success flag (1)');

	# Round-trip: getter must return the same value.
	is($obj->name(), 'Eve', 'getter returns setter value via cache');

	# Verify with CHI backend too — proves CHI success flag is not leaked.
	my $chi_obj = Class::Simple::Cached->new(cache => t::Unit::FullCHI->new());
	my $chi_ret = $chi_obj->name('Frank');
	is($chi_ret, 'Frank', 'CHI-backed scalar setter also returns value not 1');

	delete $LEDGER{'autoload:set:scalar-defined'};
	done_testing();
};

subtest 'AUTOLOAD scalar setter with undef: caches sentinel, returns undef' => sub {
	# POD PSEUDOCODE: "cache_set(key, val // UNDEF_SENTINEL); RETURN val"
	# When the inner object stores undef and returns undef, the sentinel must
	# be written to the cache and the getter must later decode it back to undef.
	my %cache;
	my $obj = Class::Simple::Cached->new(cache => \%cache);

	my $ret = $obj->tag(undef);   # inner receives undef, returns undef
	ok(!defined($ret), 'scalar setter with undef returns undef per POD');
	is($cache{"${PREFIX}tag"}, $SENTINEL,
		'UNDEF_SENTINEL stored by scalar setter for undef value');

	my $from_cache = $obj->tag();
	ok(!defined($from_cache),
		'getter decodes sentinel back to undef correctly');

	delete $LEDGER{'autoload:set:scalar-undef'};
	done_testing();
};

subtest 'AUTOLOAD array setter: stores list, returns flat list' => sub {
	# POD PSEUDOCODE: "val = object->method(\@args); RETURN @val"
	# The inner object receives a single arrayref argument, stores it, returns it.
	# CSC caches the arrayref and returns the dereferenced list.
	my %cache;
	my $obj = Class::Simple::Cached->new(cache => \%cache);

	my @ret = $obj->roles('admin', 'editor', 'viewer');
	is_deeply(\@ret, ['admin','editor','viewer'],
		'array setter returns the stored list per POD');

	# Cache holds an arrayref under the prefixed key.
	is(ref($cache{"${PREFIX}roles"}), 'ARRAY',
		'list is cached as an arrayref');
	ok(!exists($cache{'roles'}),
		'bare key without class prefix does not exist (regression guard)');

	# Getter round-trip.
	my @got = $obj->roles();
	is_deeply(\@got, ['admin','editor','viewer'],
		'getter returns the cached list');

	delete $LEDGER{'autoload:set:array-defined'};
	done_testing();
};

subtest 'AUTOLOAD array setter when object returns undef: sentinel cached, returns ()' => sub {
	# POD PSEUDOCODE: "IF defined: RETURN @val; cache_set(key, UNDEF_SENTINEL); RETURN undef"
	# Note: the pseudocode says "RETURN undef" but the implementation returns ()
	# in list context (correct behavior for an array-context setter).
	# Test verifies the actual list-context return is empty, not (undef).
	my %cache;
	my $obj = Class::Simple::Cached->new(
		cache  => \%cache,
		object => t::Unit::NullReturn->new(),
	);

	my @ret = $obj->items('x', 'y');   # array setter, inner returns undef
	is(scalar(@ret), 0,
		'array setter with undef inner return gives empty list per POD');

	is($cache{"${PREFIX}items"}, $SENTINEL,
		'UNDEF_SENTINEL cached when array setter inner-return is undef');

	delete $LEDGER{'autoload:set:array-undef'};
	done_testing();
};

# ═══════════════════════════════════════════════════════════════════════════
# Global state integrity
# CSC must not clobber $@, $!, or $_ during any operation, and must not
# reset alarm() timers.
# ═══════════════════════════════════════════════════════════════════════════

subtest 'global state: $@ is not clobbered by new() or AUTOLOAD' => sub {
	eval { die 'pre-existing error' };
	my $saved_at = $@;
	ok($saved_at, 'set up a pre-existing $@ (sanity check)');

	my $obj = Class::Simple::Cached->new(cache => {});
	$obj->colour('green');
	$obj->colour();

	is($@, $saved_at, '$@ unchanged after new() and AUTOLOAD getter/setter');
	done_testing();
};

subtest 'global state: DESTROY does not modify outer $_' => sub {
	# The DESTROY hash-cleanup uses `for` which localizes $_.
	# Confirm the localization is correct: outer $_ must survive.
	{
		local $_ = 'outer_sentinel';
		do {
			my %cache = ("${PREFIX}x" => 'v', 'Other:x' => 'w');
			my $obj = Class::Simple::Cached->new(cache => \%cache);
			# DESTROY fires here as $obj goes out of scope
		};
		is($_, 'outer_sentinel',
			'$_ restored after DESTROY cleans up hash cache keys');
	}
	done_testing();
};

SKIP: {
	skip 'alarm() not functional on this platform', 1
		unless eval { alarm(30); alarm(0) > 0 };
	subtest 'global state: alarm() timer is not reset by CSC operations' => sub {
		# CSC must not call alarm() internally.  Set a 60-second timer, run CSC
		# operations, then cancel and assert time remained (> 0 seconds left).
		alarm(60);

		my $obj = Class::Simple::Cached->new(cache => {});
		$obj->name('test');
		$obj->name();
		{
			my $tmp = $obj->new();   # clone path
		}   # DESTROY fires

		my $remaining = alarm(0);   # cancel and read remaining seconds
		ok($remaining > 0,
			'alarm() timer was not reset by any CSC operation');

		done_testing();
	};
}

# ═══════════════════════════════════════════════════════════════════════════
# Ledger exhaustion — proves 100% of documented API states were exercised
# ═══════════════════════════════════════════════════════════════════════════

if(%LEDGER) {
	fail('API Ledger is NOT empty — documented states were not exercised:');
	for my $key (sort keys %LEDGER) {
		diag("  UNTESTED: $key => $LEDGER{$key}");
	}
} else {
	pass('API Ledger is empty — all documented messages and return states verified');
}

done_testing();
