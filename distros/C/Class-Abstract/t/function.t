#!/usr/bin/perl
# t/function.t -- white-box tests for every function in Class::Abstract.
#
# Unlike t/unit.t (black-box), these tests look inside each function:
#   - verify the internal helper _is_direct_abstract is called correctly
#   - mock _is_direct_abstract to force every conditional branch
#   - confirm $_ is never clobbered by any function
#   - use Test::Memory::Cycle on returned data structures

use strict;
use warnings;

use Readonly;
use Scalar::Util     qw(blessed);
use Test::Most;
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Returns;

use Class::Abstract;

# ---------------------------------------------------------------------------
# Configuration -- one place for all constants; no magic strings
# ---------------------------------------------------------------------------

my %config = (
	# Test-fixture package names
	pkg_abstract	=> 'FT::Abstract',
	pkg_concrete	=> 'FT::Concrete',
	pkg_transitive	=> 'FT::Transitive',
	pkg_plain	=> 'FT::Plain',
	pkg_no_isa	=> 'FT::NoISA',
	pkg_import_new	=> 'FT::ImportNew',
	pkg_import_dup	=> 'FT::ImportDup',
	pkg_import_early=> 'FT::ImportEarly',
	pkg_module	=> 'Class::Abstract',

	# Sentinel value for $_ clobber tests
	sentinel	=> 'sentinel_do_not_change',

	# Error patterns (matching module POD)
	err_abstract	=> qr/Cannot instantiate abstract class \S+ directly/,
	err_new_unblessed	=> qr/new\(\) invocant must be a class name or blessed object, got/,
	err_new_undef		=> qr/new\(\) requires a defined class name as invocant/,
	err_chk_unblessed	=> qr/check_abstract\(\) requires a class name or blessed object/,
	err_chk_undef		=> qr/check_abstract\(\) requires a defined class name/,
	err_isabs_undef		=> qr/is_abstract\(\) requires a class name or object invocant/,

	# Test::Returns schemas
	schema_string	=> { type => 'string' },
	schema_integer	=> { type => 'integer' },
);

# Readonly constants -- avoid bare literals
Readonly::Scalar my $CLASS_ABSTRACT	=> 'Class::Abstract';
Readonly::Scalar my $TRUE		=> 1;
Readonly::Scalar my $FALSE		=> 0;
Readonly::Scalar my $ZERO_CALLS		=> 0;
Readonly::Scalar my $ONE_CALL		=> 1;

# ---------------------------------------------------------------------------
# Fixture packages -- fixed inheritance chains for predictable test state
# ---------------------------------------------------------------------------

# FT::Abstract: has Class::Abstract directly in @ISA => is abstract
{
	package FT::Abstract;
	use parent -norequire, 'Class::Abstract';
}

# FT::Concrete: inherits from FT::Abstract only; NOT directly abstract
{
	package FT::Concrete;
	our @ISA = ('FT::Abstract');
	sub new {
		my ($class) = @_;
		return $class->SUPER::new();
	}
}

# FT::Transitive: inherits FT::Concrete; Class::Abstract is two hops away
{
	package FT::Transitive;
	our @ISA = ('FT::Concrete');
}

# FT::Plain: completely unrelated to Class::Abstract
{
	package FT::Plain;
	our @ISA = ('SomeOtherBase');
}

# FT::NoISA: no parent at all
{
	package FT::NoISA;
	our @ISA = ();
}

# ---------------------------------------------------------------------------
# Helper: disable both bypass paths so enforcement fires inside a harness
# ---------------------------------------------------------------------------

sub enforcement_on (&) {
	my ($code) = @_;
	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;
	return $code->();
}

diag 'Class::Abstract white-box (function-level) tests' if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION: _is_direct_abstract (private helper)
#
# This is the core predicate for all enforcement.  It inspects only the
# IMMEDIATE @ISA of a class -- never the full MRO.  Tested exhaustively
# here so every public function can rely on it.
# ===========================================================================

# Purpose: undef input must return 0 (not croak, not return undef)
subtest '_is_direct_abstract -- returns 0 for undef input' => sub {
	plan tests => 2;

	# undef is handled by an early guard inside the function
	my $result;
	lives_ok { $result = Class::Abstract::_is_direct_abstract(undef) }
		'_is_direct_abstract(undef) does not croak';

	is $result, $FALSE, '_is_direct_abstract(undef) = 0';
};

# Purpose: Class::Abstract itself must always be abstract (special-cased)
subtest '_is_direct_abstract -- returns 1 for Class::Abstract itself' => sub {
	plan tests => 1;

	# The special-case avoids having Class::Abstract in its own @ISA
	is Class::Abstract::_is_direct_abstract($CLASS_ABSTRACT), $TRUE,
		'_is_direct_abstract("Class::Abstract") = 1 (special-cased)';
};

# Purpose: class with Class::Abstract directly in @ISA returns 1
subtest '_is_direct_abstract -- returns 1 for direct @ISA entry' => sub {
	plan tests => 1;

	# FT::Abstract was set up with 'Class::Abstract' in its immediate @ISA
	is Class::Abstract::_is_direct_abstract($config{pkg_abstract}), $TRUE,
		'_is_direct_abstract("FT::Abstract") = 1 (direct entry in @ISA)';
};

# Purpose: transitive inheritance must NOT be treated as directly abstract
subtest '_is_direct_abstract -- returns 0 for transitive inheritance' => sub {
	plan tests => 2;

	# FT::Transitive: Class::Abstract is two levels up, not in immediate @ISA
	is Class::Abstract::_is_direct_abstract($config{pkg_transitive}), $FALSE,
		'_is_direct_abstract("FT::Transitive") = 0 (only transitive)';

	# FT::Concrete: Class::Abstract is one level up via FT::Abstract
	is Class::Abstract::_is_direct_abstract($config{pkg_concrete}), $FALSE,
		'_is_direct_abstract("FT::Concrete") = 0 (Class::Abstract not direct)';
};

# Purpose: completely unrelated class must return 0
subtest '_is_direct_abstract -- returns 0 for unrelated class' => sub {
	plan tests => 2;

	# FT::Plain has SomeOtherBase; FT::NoISA has nothing
	is Class::Abstract::_is_direct_abstract($config{pkg_plain}), $FALSE,
		'_is_direct_abstract("FT::Plain") = 0 (unrelated parent)';

	is Class::Abstract::_is_direct_abstract($config{pkg_no_isa}), $FALSE,
		'_is_direct_abstract("FT::NoISA") = 0 (empty @ISA)';
};

# Purpose: function must not touch $_ (could break caller's loops)
subtest '_is_direct_abstract -- does not clobber $_' => sub {
	plan tests => 1;

	local $_ = $config{sentinel};

	# Exercise both the grep path (FT::Abstract) and the short-circuit path
	Class::Abstract::_is_direct_abstract($config{pkg_abstract});
	Class::Abstract::_is_direct_abstract($CLASS_ABSTRACT);
	Class::Abstract::_is_direct_abstract(undef);

	is $_, $config{sentinel}, '$_ unchanged after _is_direct_abstract calls';
};

# ===========================================================================
# SECTION: import()
#
# White-box focus:
#   - Which internal functions are called on each code path
#   - That the self-guard early-exits BEFORE calling _is_direct_abstract
#   - That the guard against duplicate @ISA entries uses _is_direct_abstract
#   - That set_return is called on every return path
# ===========================================================================

# Purpose: on the self-call path, _is_direct_abstract must NOT be called
subtest 'import() -- self-guard exits before calling _is_direct_abstract' => sub {
	plan tests => 2;

	# Install a spy to detect any call to _is_direct_abstract
	my $spy_ida = spy 'Class::Abstract::_is_direct_abstract';
	my $spy_sr  = spy 'Class::Abstract::set_return';

	# Calling import() from within Class::Abstract itself triggers the self-guard
	{ package Class::Abstract; Class::Abstract->import() }

	restore_all();

	# _is_direct_abstract must not have been called (early return fired first)
	my @ida_calls = $spy_ida->();
	is scalar @ida_calls, $ZERO_CALLS,
		'_is_direct_abstract not called when caller is Class::Abstract (self-guard)';

	# set_return must have been called exactly once (the early return)
	my @sr_calls = $spy_sr->();
	is scalar @sr_calls, $ONE_CALL,
		'set_return called exactly once on the self-guard early-return path';
};

# Purpose: normal import() path calls _is_direct_abstract with the caller package
subtest 'import() -- calls _is_direct_abstract with the caller package name' => sub {
	plan tests => 2;

	# Fresh package that has not yet been seen by import()
	{ package FT::ImportNew; our @ISA = () }

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	{ package FT::ImportNew; Class::Abstract->import() }

	restore_all();

	# Spy must have captured at least one call
	my @calls = $spy->();
	ok scalar @calls >= $ONE_CALL,
		'_is_direct_abstract called inside import() for a new caller package';

	diag "import() called _is_direct_abstract with: '$calls[0][1]'" if $ENV{TEST_VERBOSE};

	# First argument of the first call must be the caller's package name
	is $calls[0][1], $config{pkg_import_new},
		'_is_direct_abstract passed the correct caller package name';
};

# Purpose: when _is_direct_abstract returns true, import() must not push to @ISA
subtest 'import() -- no @ISA push when _is_direct_abstract returns 1' => sub {
	plan tests => 2;

	# FT::ImportDup: already abstract; import() should be a no-op on @ISA
	{ package FT::ImportDup; our @ISA = ($CLASS_ABSTRACT) }

	# Count before calling import() again
	my $count_before = scalar grep { $_ eq $CLASS_ABSTRACT } @FT::ImportDup::ISA;

	# Mock _is_direct_abstract to explicitly return 1 (already abstract)
	mock 'Class::Abstract::_is_direct_abstract' => sub { $TRUE };

	{ package FT::ImportDup; Class::Abstract->import() }

	restore_all();

	# Count must be unchanged (the mock guard stopped the push)
	my $count_after = scalar grep { $_ eq $CLASS_ABSTRACT } @FT::ImportDup::ISA;
	is $count_after, $count_before,
		'@ISA not modified when _is_direct_abstract mock returns 1';

	is $count_after, $ONE_CALL,
		'Class::Abstract appears exactly once in @FT::ImportDup::ISA';
};

# Purpose: when _is_direct_abstract returns false, import() must push to @ISA
subtest 'import() -- pushes to @ISA when _is_direct_abstract returns 0' => sub {
	plan tests => 1;

	# FT::ImportEarly: empty ISA; mock forces _is_direct_abstract to return 0
	{ package FT::ImportEarly; our @ISA = () }

	# Mock always returns 0 (not yet abstract)
	mock 'Class::Abstract::_is_direct_abstract' => sub { $FALSE };

	{ package FT::ImportEarly; Class::Abstract->import() }

	restore_all();

	# Verify Class::Abstract was pushed
	ok grep { $_ eq $CLASS_ABSTRACT } @FT::ImportEarly::ISA,
		'Class::Abstract pushed to @ISA when _is_direct_abstract returns 0';
};

# Purpose: import() must not clobber $_ in the calling scope
subtest 'import() -- does not clobber $_' => sub {
	plan tests => 1;

	{ package FT::ISAClobber; our @ISA = () }

	local $_ = $config{sentinel};

	{ package FT::ISAClobber; Class::Abstract->import() }

	is $_, $config{sentinel}, '$_ unchanged after import()';
};

# ===========================================================================
# SECTION: new()
#
# White-box focus:
#   - When enforcement fires: _is_direct_abstract is called with correct arg
#   - When bypass active: _is_direct_abstract is NOT called at all
#   - Mocking _is_direct_abstract to 1/0 proves new() respects its result
#   - Returned object is free of memory cycles
# ===========================================================================

# Purpose: _is_direct_abstract is called with the resolved class name
subtest 'new() -- calls _is_direct_abstract with the class name when enforcement on' => sub {
	plan tests => 2;

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	# enforcement_on ensures enforcement actually fires
	enforcement_on { FT::Concrete->new() };

	restore_all();

	my @calls = $spy->();
	ok scalar @calls >= $ONE_CALL,
		'_is_direct_abstract called inside new() when enforcement is active';

	diag "new() called _is_direct_abstract with: '$calls[0][1]'" if $ENV{TEST_VERBOSE};

	# The argument must be the concrete class name, not FT::Abstract or Class::Abstract
	is $calls[0][1], $config{pkg_concrete},
		'_is_direct_abstract passed the concrete class name (not a base class)';
};

# Purpose: when $BYPASS is truthy, _is_direct_abstract must not be called
subtest 'new() -- _is_direct_abstract skipped when $BYPASS is truthy' => sub {
	plan tests => 1;

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	# $BYPASS short-circuits the entire enforcement block
	local $Class::Abstract::BYPASS                 = $TRUE;
	local $Class::Abstract::config{harness_bypass} = $FALSE;
	local $ENV{HARNESS_ACTIVE}                     = $FALSE;

	eval { FT::Abstract->new() };

	restore_all();

	my @calls = $spy->();
	is scalar @calls, $ZERO_CALLS,
		'_is_direct_abstract not called at all when $BYPASS is truthy';
};

# Purpose: when harness bypass fires, _is_direct_abstract must not be called
subtest 'new() -- _is_direct_abstract skipped under harness bypass' => sub {
	plan tests => 1;

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	# Both harness bypass conditions must be active; global bypass off
	local $Class::Abstract::BYPASS                 = $FALSE;
	local $Class::Abstract::config{harness_bypass} = $TRUE;
	local $ENV{HARNESS_ACTIVE}                     = $TRUE;

	eval { FT::Abstract->new() };

	restore_all();

	my @calls = $spy->();
	is scalar @calls, $ZERO_CALLS,
		'_is_direct_abstract not called when harness_bypass + HARNESS_ACTIVE active';
};

# Purpose: mocking _is_direct_abstract to 1 must cause croak for any class
subtest 'new() -- respects _is_direct_abstract return value (mock => 1 causes croak)' => sub {
	plan tests => 1;

	# Force _is_direct_abstract to claim every class is abstract
	mock 'Class::Abstract::_is_direct_abstract' => sub { $TRUE };

	enforcement_on {
		throws_ok { FT::Concrete->new() }
			qr/Cannot instantiate abstract class FT::Concrete directly/,
			'new() croaks for FT::Concrete when mock forces _is_direct_abstract to 1';
	};

	restore_all();
};

# Purpose: mocking _is_direct_abstract to 0 must suppress croak for abstract class
subtest 'new() -- respects _is_direct_abstract return value (mock => 0 suppresses croak)' => sub {
	plan tests => 1;

	# Force _is_direct_abstract to claim every class is concrete
	mock 'Class::Abstract::_is_direct_abstract' => sub { $FALSE };

	enforcement_on {
		lives_ok { FT::Abstract->new() }
			'new() lives for FT::Abstract when mock forces _is_direct_abstract to 0';
	};

	restore_all();
};

# Purpose: new() returns a blessed empty hashref with no memory cycles
subtest 'new() -- returned object has no memory cycles' => sub {
	plan tests => 1;

	my $obj = FT::Concrete->new();

	# bless {}, $class has no references that could cycle
	memory_cycle_ok $obj, 'new() returns a cycle-free blessed hashref';
};

# Purpose: defined-but-empty string hits the length guard before _is_direct_abstract
# This exercises the 'l&&!r' branch of the 'defined($class) && length($class)' condition.
subtest 'new() -- empty string class hits defined-but-empty guard, _is_direct_abstract not called' => sub {
	plan tests => 2;

	# Spy: _is_direct_abstract must NOT be called because the guard fires first
	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	throws_ok { Class::Abstract::new('') }
		qr/new\(\) requires a defined class name as invocant/,
		'new("") croaks at the defined/length guard';

	restore_all();

	my @calls = $spy->();
	is scalar(@calls), 0,
		'_is_direct_abstract never called: guard fires before the enforcement check';
};

# Purpose: new() must not clobber $_ in the calling scope
subtest 'new() -- does not clobber $_' => sub {
	plan tests => 1;

	local $_ = $config{sentinel};

	FT::Concrete->new();

	is $_, $config{sentinel}, '$_ unchanged after new()';
};

# ===========================================================================
# SECTION: check_abstract()
#
# White-box focus:
#   - _is_direct_abstract called when enforcement active
#   - _is_direct_abstract NOT called when bypass active (either path)
#   - Blessed object invocant: ref() applied before _is_direct_abstract call
# ===========================================================================

# Purpose: _is_direct_abstract called with the correct class during enforcement
subtest 'check_abstract() -- calls _is_direct_abstract with correct class' => sub {
	plan tests => 2;

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	# check_abstract() must call _is_direct_abstract to decide whether to croak
	enforcement_on { Class::Abstract::check_abstract($config{pkg_concrete}) };

	restore_all();

	my @calls = $spy->();
	ok scalar @calls >= $ONE_CALL,
		'_is_direct_abstract called from check_abstract() during enforcement';

	is $calls[0][1], $config{pkg_concrete},
		'_is_direct_abstract passed the correct class name';
};

# Purpose: when $BYPASS is truthy, _is_direct_abstract must not be called
subtest 'check_abstract() -- _is_direct_abstract skipped when $BYPASS truthy' => sub {
	plan tests => 1;

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	local $Class::Abstract::BYPASS                 = $TRUE;
	local $Class::Abstract::config{harness_bypass} = $FALSE;
	local $ENV{HARNESS_ACTIVE}                     = $FALSE;

	eval { Class::Abstract::check_abstract($config{pkg_abstract}) };

	restore_all();

	my @calls = $spy->();
	is scalar @calls, $ZERO_CALLS,
		'_is_direct_abstract not called when $BYPASS is truthy';
};

# Purpose: harness bypass also skips the _is_direct_abstract call
subtest 'check_abstract() -- _is_direct_abstract skipped under harness bypass' => sub {
	plan tests => 1;

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	local $Class::Abstract::BYPASS                 = $FALSE;
	local $Class::Abstract::config{harness_bypass} = $TRUE;
	local $ENV{HARNESS_ACTIVE}                     = $TRUE;

	eval { Class::Abstract::check_abstract($config{pkg_abstract}) };

	restore_all();

	my @calls = $spy->();
	is scalar @calls, $ZERO_CALLS,
		'_is_direct_abstract not called under harness_bypass + HARNESS_ACTIVE';
};

# Purpose: blessed-object arg: check_abstract uses ref() to extract the class
subtest 'check_abstract() -- extracts class from blessed object via ref()' => sub {
	plan tests => 2;

	my $obj = FT::Concrete->new();
	ok blessed($obj), 'precondition: $obj is a blessed FT::Concrete instance';

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	# Pass the blessed object; check_abstract must call _is_direct_abstract
	# with 'FT::Concrete' (from ref($obj)), not with the object reference itself
	enforcement_on { Class::Abstract::check_abstract($obj) };

	restore_all();

	my @calls = $spy->();
	is $calls[0][1], $config{pkg_concrete},
		'_is_direct_abstract called with ref($obj) = "FT::Concrete", not the ref itself';
};

# Purpose: check_abstract() must not clobber $_ in the calling scope
subtest 'check_abstract() -- does not clobber $_' => sub {
	plan tests => 1;

	local $_ = $config{sentinel};

	enforcement_on { Class::Abstract::check_abstract($config{pkg_concrete}) };

	is $_, $config{sentinel}, '$_ unchanged after check_abstract()';
};

# Purpose: empty string hits the length guard before _is_direct_abstract is called
subtest 'check_abstract() -- empty string fires length guard; _is_direct_abstract not called' => sub {
	plan tests => 2;

	# Spy: _is_direct_abstract must NOT be called when the length guard fires first
	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	throws_ok { Class::Abstract::check_abstract('') }
		qr/check_abstract\(\) requires a defined class name/,
		'check_abstract("") croaks at the defined/length guard';

	restore_all();

	my @calls = $spy->();
	is scalar(@calls), 0,
		'_is_direct_abstract never called: length guard fires before enforcement check';
};

# ===========================================================================
# SECTION: is_abstract()
#
# White-box focus:
#   - Two-arg form passes invocant class to _is_direct_abstract
#   - Two-arg form with blessed object passes ref(obj) to _is_direct_abstract
#   - Three-arg form passes class_arg (not the invocant) to _is_direct_abstract
# ===========================================================================

# Purpose: two-arg class-name form passes the invocant to _is_direct_abstract
subtest 'is_abstract() -- two-arg form passes invocant class to _is_direct_abstract' => sub {
	plan tests => 2;

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	FT::Abstract->is_abstract();

	restore_all();

	my @calls = $spy->();
	ok scalar @calls >= $ONE_CALL,
		'_is_direct_abstract called from is_abstract()';

	diag "is_abstract() passed: '$calls[0][1]'" if $ENV{TEST_VERBOSE};

	# The argument must be the abstract class name, not Class::Abstract
	is $calls[0][1], $config{pkg_abstract},
		'_is_direct_abstract passed the invocant class "FT::Abstract"';
};

# Purpose: two-arg form with blessed object passes ref(obj), not the raw ref
subtest 'is_abstract() -- blessed instance form passes ref($obj) to _is_direct_abstract' => sub {
	plan tests => 2;

	my $obj = FT::Concrete->new();
	ok blessed($obj), 'precondition: $obj is a blessed FT::Concrete instance';

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	$obj->is_abstract();

	restore_all();

	my @calls = $spy->();

	# Must have passed 'FT::Concrete', the class of $obj (from ref($obj))
	is $calls[0][1], $config{pkg_concrete},
		'_is_direct_abstract passed ref($obj) = "FT::Concrete" (not the ref itself)';
};

# Purpose: three-arg form uses class_arg, ignoring the invocant
subtest 'is_abstract() -- three-arg form passes class_arg, not invocant' => sub {
	plan tests => 2;

	my $spy = spy 'Class::Abstract::_is_direct_abstract';

	# Invocant is Class::Abstract, but we pass FT::Abstract as the arg
	Class::Abstract->is_abstract($config{pkg_abstract});

	restore_all();

	my @calls = $spy->();
	ok scalar @calls >= $ONE_CALL,
		'_is_direct_abstract called from three-arg is_abstract()';

	# Must pass FT::Abstract (the class_arg), not Class::Abstract (the invocant)
	is $calls[0][1], $config{pkg_abstract},
		'_is_direct_abstract passed "FT::Abstract" (class_arg), not the invocant';
};

# Purpose: is_abstract() propagates _is_direct_abstract result without wrapping
subtest 'is_abstract() -- propagates _is_direct_abstract return value unchanged' => sub {
	plan tests => 2;

	# Mock returning 1 for any class -- is_abstract() must pass this through
	mock 'Class::Abstract::_is_direct_abstract' => sub { $TRUE };
	my $result_true = FT::Concrete->is_abstract();
	restore_all();

	# Mock returning 0 -- is_abstract() must also pass 0 through
	mock 'Class::Abstract::_is_direct_abstract' => sub { $FALSE };
	my $result_false = FT::Abstract->is_abstract();
	restore_all();

	is $result_true,  $TRUE,  'is_abstract() returns 1 when _is_direct_abstract returns 1';
	is $result_false, $FALSE, 'is_abstract() returns 0 when _is_direct_abstract returns 0';
};

# Purpose: is_abstract() must not clobber $_ in the calling scope
subtest 'is_abstract() -- does not clobber $_' => sub {
	plan tests => 1;

	local $_ = $config{sentinel};

	FT::Abstract->is_abstract();
	FT::Concrete->is_abstract();
	Class::Abstract->is_abstract($config{pkg_abstract});

	is $_, $config{sentinel}, '$_ unchanged after is_abstract() calls';
};

# ===========================================================================
# SECTION: Global module state
#
# Verify that the module's own data structures ($BYPASS, %config) carry no
# circular references that would prevent garbage collection.
# ===========================================================================

# Purpose: module-level public data structures must be cycle-free
subtest 'module state -- $BYPASS and %config contain no memory cycles' => sub {
	plan tests => 2;

	# $BYPASS is a simple scalar; wrap in a ref to let memory_cycle_ok examine it
	memory_cycle_ok \$Class::Abstract::BYPASS,
		'$Class::Abstract::BYPASS has no memory cycles';

	memory_cycle_ok \%Class::Abstract::config,
		'%Class::Abstract::config has no memory cycles';
};

done_testing;
