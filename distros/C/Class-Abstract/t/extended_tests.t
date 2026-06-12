#!/usr/bin/perl
# t/extended_tests.t -- tests targeting execution paths not covered by the
# primary test suite, raising overall coverage and LCSAJ/TER3 scores.
#
# Coverage targets (from Devel::Cover analysis):
#   Line 233  bran/cond -- import() caller guard (empty/undef caller)
#   Line 348  cond l&&!r -- new('') defined-but-empty class name
#   Line 352  cond l&&!r -- new() production context: harness_bypass=1,
#                           HARNESS_ACTIVE unset, BYPASS=0
#   Line 420  cond l&&!r -- check_abstract('') defined-but-empty class name
#   Line 423  cond l&&!r -- check_abstract() same production context
#
# Additional paths for LCSAJ TER3 coverage:
#   - new(blessed_abstract_obj) with enforcement on  (ref -> extract -> abstract -> croak)
#   - check_abstract() returning undef for concrete class
#   - check_abstract() with blessed-object invocant
#   - can('new') on abstract class (documented croak-stub limitation)
#   - import() idempotency (already-abstract class)

use strict;
use warnings;

use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Returns;
use Test::Mockingbird;

use Class::Abstract;

# ---------------------------------------------------------------------------
# Configuration -- all constants and boundary values in one place
# ---------------------------------------------------------------------------

my %config = (
	# Package names (ET:: prefix avoids collision with other test suites)
	pkg_abstract => 'ET::Abstract',
	pkg_concrete => 'ET::Concrete',
	pkg_idem     => 'ET::Idempotent',
	pkg_module   => 'Class::Abstract',

	# Bypass sentinel values
	harness_bypass_on  => 1,
	harness_bypass_off => 0,
	harness_active_off => '',

	# Expected error patterns (match module POD exactly)
	err_abstract     => qr/Cannot instantiate abstract class \S+ directly/,
	err_new_undef    => qr/new\(\) requires a defined class name as invocant/,
	err_chk_undef    => qr/check_abstract\(\) requires a defined class name/,
	err_chk_unblessed => qr/check_abstract\(\) requires a class name or blessed object/,

	# Test::Returns schemas
	schema_string  => { type => 'string'  },
	schema_integer => { type => 'integer' },
	schema_undef   => { type => 'undef'   },
);

# Readonly constants
Readonly::Scalar my $CLASS_ABSTRACT => 'Class::Abstract';
Readonly::Scalar my $TRUE           => 1;
Readonly::Scalar my $FALSE          => 0;

# ---------------------------------------------------------------------------
# Fixture packages
# ---------------------------------------------------------------------------

# ET::Abstract: directly abstract via use parent
{
	package ET::Abstract;
	use parent -norequire, 'Class::Abstract';
}

# ET::Concrete: concrete subclass -- delegates to SUPER::new
{
	package ET::Concrete;
	our @ISA = ('ET::Abstract');
	sub new { my ($class) = @_; return $class->SUPER::new() }
}

# ET::Idempotent: used to verify import() does not add duplicates
{
	package ET::Idempotent;
	use parent -norequire, 'Class::Abstract';
}

diag 'Extended coverage tests' if $ENV{TEST_VERBOSE};

# ---------------------------------------------------------------------------
# Helper: disable all bypass paths (same pattern used in other test files)
# ---------------------------------------------------------------------------

sub enforcement_on (&) {
	my ($code) = @_;
	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;
	return $code->();
}

# ===========================================================================
# SECTION 1: import() caller guard -- empty/undef caller
#
# import() has a guard (line 233) that fires when caller() returns an empty
# string or undef.  This can happen in unusual compile contexts such as a
# BEGIN block inside a string eval at the top level.
#
# To exercise this path, we temporarily override CORE::GLOBAL::caller with a
# stub.  Because Class::Abstract uses bare 'caller' (not CORE::caller), the
# override intercepts it.
#
# NOTE: This path is UNREACHABLE in normal user code and is a defensive guard.
# ===========================================================================

# Purpose: empty-string caller triggers the guard; @ISA is not modified
subtest 'import() caller guard -- empty-string caller returns early, no @ISA change' => sub {
	plan tests => 2;

	# Snapshot current size of @main::ISA before the call
	my $isa_count_before = scalar @main::ISA;

	diag "\@main::ISA before: (" . join(', ', @main::ISA) . ')' if $ENV{TEST_VERBOSE};

	# Override caller() to return "" (defined but length 0 -- fires the guard)
	{
		no warnings 'redefine';
		local *CORE::GLOBAL::caller = sub { return wantarray ? ('', '', 0) : '' };
		Class::Abstract->import();
	}

	# The guard must have fired: @main::ISA must not have grown
	is scalar(@main::ISA), $isa_count_before,
		'empty-string caller: @main::ISA unchanged (guard returned early)';

	# The return value must still be the class name string
	{
		no warnings 'redefine';
		local *CORE::GLOBAL::caller = sub { return wantarray ? ('', '', 0) : '' };
		my $ret = Class::Abstract->import();
		is $ret, $CLASS_ABSTRACT,
			'empty-string caller: import() returns "Class::Abstract" despite early exit';
	}
};

# Purpose: undef caller also triggers the guard (the !l condition)
subtest 'import() caller guard -- undef caller returns early, no @ISA change' => sub {
	plan tests => 1;

	my $isa_count_before = scalar @main::ISA;

	# Override caller() to return undef in scalar context
	{
		no warnings 'redefine';
		local *CORE::GLOBAL::caller = sub { return };   # undef in scalar context
		Class::Abstract->import();
	}

	# Guard must have fired: @main::ISA must not have grown
	is scalar(@main::ISA), $isa_count_before,
		'undef caller: @main::ISA unchanged (guard returned early)';
};

# ===========================================================================
# SECTION 2: new() and check_abstract() with defined-but-empty class name
#
# Both functions guard with 'unless defined($class) && length($class)'.
# The undefined case (failing defined()) is already tested; this section
# covers the case where $class IS defined but has length 0 (empty string),
# which is the 'l&&!r' branch of the and-condition.
# ===========================================================================

# Purpose: new("") must croak -- empty string is defined but has zero length
subtest 'new("") -- defined-but-empty class name croaks with documented error' => sub {
	plan tests => 2;

	diag 'Testing new("") -- defined but length 0' if $ENV{TEST_VERBOSE};

	# An empty string passes defined() but fails length()
	throws_ok { Class::Abstract::new('') }
		$config{err_new_undef},
		'new("") croaks: defined empty string fails the length guard';

	# Test::Returns: the call croaks, so there is no return value to check.
	# Verify the error message is exactly right by re-testing with explicit match.
	throws_ok { Class::Abstract::new('') }
		qr/new\(\) requires a defined class name as invocant/,
		'new("") error message matches documented text exactly';
};

# Purpose: check_abstract("") must croak -- same guard, same condition
subtest 'check_abstract("") -- defined-but-empty class name croaks' => sub {
	plan tests => 2;

	throws_ok { Class::Abstract::check_abstract('') }
		$config{err_chk_undef},
		'check_abstract("") croaks: defined empty string fails the length guard';

	throws_ok { Class::Abstract::check_abstract('') }
		qr/check_abstract\(\) requires a defined class name/,
		'check_abstract("") error message matches documented text exactly';
};

# ===========================================================================
# SECTION 3: Production scenario
#
# The 'l&&!r' condition for the bypass guard in new() and check_abstract() is:
#   $config{harness_bypass} is truthy (default=1)
#   $ENV{HARNESS_ACTIVE} is NOT set (empty string or undef)
#
# This is the real-world production scenario: code runs outside a test harness
# with all defaults.  Enforcement must fire because
#   $BYPASS=0 AND ($harness_bypass=1 AND $HARNESS_ACTIVE='') = 0 || 0 = false.
# ===========================================================================

# Purpose: enforcement fires in production context (no harness, no bypass)
subtest 'production scenario -- enforcement fires with defaults outside harness' => sub {
	plan tests => 4;

	diag 'Testing production context: BYPASS=0, harness_bypass=1, HARNESS_ACTIVE=""'
		if $ENV{TEST_VERBOSE};

	# new(): BYPASS=0, harness_bypass=1 (default), HARNESS_ACTIVE="" (not in harness)
	{
		local $Class::Abstract::BYPASS                 = 0;
		local $Class::Abstract::config{harness_bypass} = $config{harness_bypass_on};
		local $ENV{HARNESS_ACTIVE}                     = $config{harness_active_off};

		throws_ok { ET::Abstract->new() }
			$config{err_abstract},
			'new() croaks in production: BYPASS=0, harness_bypass=1, HARNESS_ACTIVE=""';
	}

	# new(): verify concrete class still works in the same context
	{
		local $Class::Abstract::BYPASS                 = 0;
		local $Class::Abstract::config{harness_bypass} = $config{harness_bypass_on};
		local $ENV{HARNESS_ACTIVE}                     = $config{harness_active_off};

		my $obj;
		lives_ok { $obj = ET::Concrete->new() }
			'new(concrete) lives in production context (only abstract class is blocked)';
		ok blessed($obj), 'concrete object is blessed in production context';
	}

	# check_abstract(): same production context
	{
		local $Class::Abstract::BYPASS                 = 0;
		local $Class::Abstract::config{harness_bypass} = $config{harness_bypass_on};
		local $ENV{HARNESS_ACTIVE}                     = $config{harness_active_off};

		throws_ok { Class::Abstract::check_abstract($config{pkg_abstract}) }
			$config{err_abstract},
			'check_abstract() croaks in production: same default context';
	}
};

# ===========================================================================
# SECTION 4: new() with blessed abstract-class instance as invocant
#
# When a blessed object of an abstract class is passed as invocant, new()
# extracts the class name via blessed() then checks if that class is abstract.
# With enforcement on, the croak must fire because the extracted class IS abstract.
#
# This tests the LCSAJ path:
#   if(ref): T -> unless(blessed): F -> class=ref(obj) -> bypass: off -> abstract: T -> CROAK
# ===========================================================================

# Purpose: blessed instance of abstract class passed to new() -- croak after class extraction
subtest 'new() -- blessed abstract-class instance causes enforcement after class extraction' => sub {
	plan tests => 3;

	# Create a blessed abstract instance (bypass must be on to create it)
	my $abstract_obj;
	{
		local $Class::Abstract::BYPASS = 1;
		$abstract_obj = ET::Abstract->new();
	}

	diag 'abstract obj class: ' . (blessed($abstract_obj) // 'undef') if $ENV{TEST_VERBOSE};

	# Precondition: the object exists and is blessed into the abstract class
	ok blessed($abstract_obj), 'precondition: abstract object created with bypass';
	is ref($abstract_obj), $config{pkg_abstract},
		'precondition: object is blessed into ET::Abstract';

	# With enforcement on, new($abstract_obj) must croak:
	# ref branch -> class = 'ET::Abstract' -> abstract check -> croak
	enforcement_on {
		throws_ok { Class::Abstract::new($abstract_obj) }
			qr/Cannot instantiate abstract class ET::Abstract directly/,
			'new(blessed abstract obj): croak after class extraction from blessed ref';
	};
};

# ===========================================================================
# SECTION 5: check_abstract() with concrete class and blessed object invocant
#
# check_abstract() must silently return undef when the class is concrete.
# Also tests the path where a blessed concrete OBJECT is passed as invocant
# (ref branch: truthy -> blessed: truthy -> class extracted from ref).
# ===========================================================================

# Purpose: check_abstract() returns undef for a concrete class (no croak)
subtest 'check_abstract() -- returns undef for concrete class (no enforcement)' => sub {
	plan tests => 2;

	# check_abstract() on a concrete class must not croak and must return undef
	enforcement_on {
		my $ret;
		lives_ok { $ret = Class::Abstract::check_abstract($config{pkg_concrete}) }
			'check_abstract(concrete) does not croak';
		is $ret, undef,
			'check_abstract(concrete) returns undef on success (per POD)';
	};
};

# Purpose: check_abstract() accepts a blessed concrete object as invocant
subtest 'check_abstract() -- blessed concrete object invocant: class extracted, no croak' => sub {
	plan tests => 3;

	# Create a concrete object to use as invocant
	my $obj = ET::Concrete->new();

	diag 'concrete obj: ref=' . ref($obj) if $ENV{TEST_VERBOSE};

	ok blessed($obj), 'precondition: ET::Concrete object is blessed';

	# check_abstract($obj) must extract class from blessed($obj) and not croak
	# because ET::Concrete is not abstract
	enforcement_on {
		my $ret;
		lives_ok { $ret = Class::Abstract::check_abstract($obj) }
			'check_abstract(blessed concrete obj): does not croak';
		is $ret, undef,
			'check_abstract(blessed concrete obj): returns undef (concrete class)';
	};
};

# ===========================================================================
# SECTION 6: import() idempotency
#
# Calling import() on a class that already has Class::Abstract in @ISA must
# not add a second entry.  The guard 'unless _is_direct_abstract($caller)'
# prevents double-registration.
# ===========================================================================

# Purpose: import() does not add duplicate entries to @ISA
subtest 'import() -- idempotent: Class::Abstract not duplicated in @ISA' => sub {
	plan tests => 3;

	diag "\@ET::Idempotent::ISA before: (" . join(', ', @ET::Idempotent::ISA) . ')'
		if $ENV{TEST_VERBOSE};

	# ET::Idempotent already has Class::Abstract in @ISA via 'use parent'
	my $count_before = scalar @ET::Idempotent::ISA;
	ok $count_before >= 1,
		'precondition: ET::Idempotent already has Class::Abstract in @ISA';

	# Call import() again -- must not add a second copy
	{ package ET::Idempotent; Class::Abstract->import() }

	my $count_after = scalar @ET::Idempotent::ISA;

	is $count_after, $count_before,
		'second import() call does not grow @ISA (no duplicate)';

	# Confirm exactly one occurrence of Class::Abstract
	my $occurrences = scalar grep { $_ eq $CLASS_ABSTRACT } @ET::Idempotent::ISA;
	is $occurrences, 1,
		'Class::Abstract appears exactly once in @ET::Idempotent::ISA';
};

# ===========================================================================
# SECTION 7: import() return value schema
#
# import() must always return the string 'Class::Abstract' regardless of
# whether it pushed to @ISA or returned early (self-guard or caller guard).
# Verify with Test::Returns schema.
# ===========================================================================

# Purpose: import() return value always satisfies the {type=>'string'} schema
subtest 'import() -- return value satisfies string schema in all paths' => sub {
	plan tests => 3;

	# Normal import (adds Class::Abstract to caller's @ISA)
	my $ret_normal;
	{ package ET::SchemaTest1; our @ISA = (); $ret_normal = Class::Abstract->import() }
	returns_ok $ret_normal, $config{schema_string},
		'import() normal path: return value satisfies string schema';

	# Self-guard (import() called on Class::Abstract itself)
	my $ret_self = Class::Abstract->import();
	returns_ok $ret_self, $config{schema_string},
		'import() self-guard path: return value satisfies string schema';

	# Already-abstract (idempotent path: _is_direct_abstract already true)
	my $ret_idem;
	{ package ET::SchemaTest2; use parent -norequire, 'Class::Abstract'; $ret_idem = Class::Abstract->import() }
	returns_ok $ret_idem, $config{schema_string},
		'import() idempotent path: return value satisfies string schema';
};

# ===========================================================================
# SECTION 8: can('new') on abstract class -- documented limitation
#
# POD documents that can('new') returns a truthy CODE ref even for abstract
# classes.  This is expected behaviour: new() exists, it just croaks.
# ===========================================================================

# Purpose: can('new') returns a CODE ref for abstract class (croak-stub limitation)
subtest 'can("new") on abstract class returns CODE ref (documented limitation)' => sub {
	plan tests => 3;

	# Abstract class: can('new') must return truthy even though new() will croak
	my $code = ET::Abstract->can('new');
	ok $code, 'ET::Abstract->can("new") returns a truthy value';

	is ref($code), 'CODE',
		'ET::Abstract->can("new") returns a CODE reference';

	# Calling it with enforcement on must croak
	enforcement_on {
		throws_ok { $code->('ET::Abstract') }
			$config{err_abstract},
			'the CODE ref from can("new") still enforces the abstract contract';
	};
};

# ===========================================================================
# SECTION 9: BYPASS short-circuit verification
#
# When $BYPASS is truthy, the OR short-circuits and harness_bypass is not
# evaluated at all.  This means $BYPASS=1 bypasses enforcement even if
# harness_bypass=0 and HARNESS_ACTIVE=0.  Confirm this for both new() and
# check_abstract().
# ===========================================================================

# Purpose: $BYPASS short-circuits the whole bypass expression
subtest '$BYPASS short-circuit: bypasses even when harness_bypass=0 and HARNESS_ACTIVE=0' => sub {
	plan tests => 2;

	# Both of these would normally fire enforcement; $BYPASS overrides both
	{
		local $Class::Abstract::BYPASS                 = 1;
		local $Class::Abstract::config{harness_bypass} = 0;
		local $ENV{HARNESS_ACTIVE}                     = 0;

		lives_ok { ET::Abstract->new() }
			'$BYPASS=1 short-circuits: new() bypassed despite harness_bypass=0 and HARNESS_ACTIVE=0';
	}

	{
		local $Class::Abstract::BYPASS                 = 1;
		local $Class::Abstract::config{harness_bypass} = 0;
		local $ENV{HARNESS_ACTIVE}                     = 0;

		lives_ok { Class::Abstract::check_abstract($config{pkg_abstract}) }
			'$BYPASS=1 short-circuits: check_abstract() bypassed despite harness_bypass=0';
	}
};

# ===========================================================================
# SECTION 10: _is_direct_abstract() with Class::Abstract as both subject
# and query -- the self-referential case
#
# _is_direct_abstract('Class::Abstract') returns 1 via the
# '$class eq $SELF' fast path.  Verify this is accessible via the public
# is_abstract() interface.
# ===========================================================================

# Purpose: Class::Abstract reports itself as abstract via is_abstract()
subtest 'Class::Abstract->is_abstract() -- module itself is abstract' => sub {
	plan tests => 3;

	# Direct invocation on the module
	my $result = Class::Abstract->is_abstract();
	is $result, $TRUE,
		'Class::Abstract->is_abstract() = 1 (module itself is abstract)';

	# Three-arg form
	my $via_arg = Class::Abstract->is_abstract($config{pkg_module});
	is $via_arg, $TRUE,
		'Class::Abstract->is_abstract("Class::Abstract") = 1';

	# Return schema
	returns_ok $result, $config{schema_integer},
		'Class::Abstract->is_abstract() satisfies integer return schema';
};

# ===========================================================================
# SECTION 11: check_abstract() return value schema
#
# check_abstract() returns undef on success (concrete class, or bypass).
# Verify with Test::Returns.
# ===========================================================================

# Purpose: check_abstract() return value schema matches documentation
subtest 'check_abstract() -- return value is undef on success (schema check)' => sub {
	plan tests => 2;

	# Concrete class: returns undef
	enforcement_on {
		my $ret = Class::Abstract::check_abstract($config{pkg_concrete});
		is $ret, undef,
			'check_abstract(concrete): returns undef per POD';
	};

	# Bypassed abstract class: also returns undef
	{
		local $Class::Abstract::BYPASS = 1;
		my $ret = Class::Abstract::check_abstract($config{pkg_abstract});
		is $ret, undef,
			'check_abstract(abstract, BYPASS=1): returns undef (bypass active)';
	}
};

# ===========================================================================
# SECTION 12: new() return value schema
#
# new() returns a blessed empty hashref.  Verify with Test::Returns and check
# the object structure is correct.
# ===========================================================================

# Purpose: new() return value satisfies expected object schema
subtest 'new() -- return value is a blessed empty hashref' => sub {
	plan tests => 3;

	my $obj = ET::Concrete->new();

	ok blessed($obj), 'new() returns a blessed reference';

	is ref($obj), $config{pkg_concrete},
		'new() blesses into the concrete class';

	is_deeply $obj, {},
		'new() returns an empty hashref (no keys pre-populated)';
};

done_testing;
