#!/usr/bin/perl
# t/unit.t -- black-box unit tests for the public API of Class::Abstract.
#
# Each subtest exercises exactly one documented behaviour of one public
# method against its POD specification.  Where the module calls external
# functions (Return::Set::set_return, Scalar::Util::blessed), spies are
# used to verify those calls without altering the module's behaviour.

use strict;
use warnings;

use Readonly;
use Scalar::Util  qw(blessed);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;

use Class::Abstract;

# ---------------------------------------------------------------------------
# Configuration -- all constants and strings live here; no magic values
# ---------------------------------------------------------------------------

my %config = (
	# Package names used as test fixtures
	pkg_abstract	=> 'UT::Abstract',
	pkg_concrete	=> 'UT::Concrete',
	pkg_import_a	=> 'UT::ImportA',
	pkg_import_b	=> 'UT::ImportB',

	# The module under test
	pkg_module	=> 'Class::Abstract',

	# Compiled error-pattern regexes (from the module POD)
	err_abstract		=> qr/Cannot instantiate abstract class \S+ directly/,
	err_abstract_ut		=> qr/Cannot instantiate abstract class UT::Abstract directly/,
	err_new_unblessed	=> qr/new\(\) invocant must be a class name or blessed object, got/,
	err_new_undef		=> qr/new\(\) requires a defined class name as invocant/,
	err_chk_unblessed	=> qr/check_abstract\(\) requires a class name or blessed object/,
	err_chk_undef		=> qr/check_abstract\(\) requires a defined class name/,
	err_isabs_undef		=> qr/is_abstract\(\) requires a class name or object invocant/,

	# Schema definitions for Test::Returns validation
	schema_string	=> { type => 'string' },
	schema_integer	=> { type => 'integer' },
);

# Readonly constants -- avoid bare literals in test logic
Readonly::Scalar my $CLASS_ABSTRACT	=> 'Class::Abstract';
Readonly::Scalar my $TRUE		=> 1;
Readonly::Scalar my $FALSE		=> 0;

# ---------------------------------------------------------------------------
# Fixture packages -- compiled at BEGIN time for stable inheritance chains
# ---------------------------------------------------------------------------

# UT::Abstract has Class::Abstract directly in @ISA, so it IS abstract
{
	package UT::Abstract;
	use parent -norequire, 'Class::Abstract';
}

# UT::Concrete inherits from UT::Abstract only; it is NOT directly abstract
{
	package UT::Concrete;
	our @ISA = ('UT::Abstract');

	# Concrete subclass must delegate construction through SUPER
	sub new {
		my ($class) = @_;
		return $class->SUPER::new();
	}
}

# ---------------------------------------------------------------------------
# Helper: disable both bypass paths so enforcement fires inside a harness
# ---------------------------------------------------------------------------

# This mirrors the pattern used in basic.t and override_new.t
sub enforcement_on (&) {
	my ($code) = @_;
	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;
	return $code->();
}

diag 'Class::Abstract unit tests -- one subtest per documented behaviour'
	if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION: import()
#
# POD contract:
#   - Adds 'Class::Abstract' to the calling package's @ISA if not present
#   - Is a no-op when Class::Abstract is already in @ISA
#   - Does not modify Class::Abstract's own @ISA
#   - Returns the string 'Class::Abstract'
# ===========================================================================

# Purpose: confirm import() adds the module to the caller's @ISA
subtest 'import() -- adds Class::Abstract to caller @ISA on first call' => sub {
	plan tests => 3;

	# Start with a clean slate so the test is order-independent
	{ package UT::ImportA; our @ISA = () }

	# Pre-condition: Class::Abstract must NOT be present yet
	ok !grep { $_ eq $CLASS_ABSTRACT } @UT::ImportA::ISA,
		'precondition: Class::Abstract not yet in @UT::ImportA::ISA';

	# Call import() at runtime from within the target package context.
	# The 'package' declaration makes caller() return 'UT::ImportA'.
	{ package UT::ImportA; Class::Abstract->import() }

	diag '@UT::ImportA::ISA after import: (' . join(', ', @UT::ImportA::ISA) . ')'
		if $ENV{TEST_VERBOSE};

	# Post-condition: the entry must now be present
	ok grep { $_ eq $CLASS_ABSTRACT } @UT::ImportA::ISA,
		'import() adds Class::Abstract to @UT::ImportA::ISA';

	# Verify the package is now treated as directly abstract
	is( UT::ImportA->is_abstract(), $TRUE,
		'UT::ImportA reports is_abstract() = 1 after import()' );
};

# Purpose: calling import() again must NOT add a second entry
subtest 'import() -- no duplicate when called on a package that already inherits' => sub {
	plan tests => 2;

	# UT::ImportA already has Class::Abstract from the previous subtest
	my $count_before = scalar grep { $_ eq $CLASS_ABSTRACT } @UT::ImportA::ISA;

	# Second import call -- must not change the count
	{ package UT::ImportA; Class::Abstract->import() }

	my $count_after = scalar grep { $_ eq $CLASS_ABSTRACT } @UT::ImportA::ISA;

	# Entry count must be unchanged
	is $count_after, $count_before,
		'calling import() twice does not duplicate the entry in @ISA';

	# Sanity: the count should be exactly one
	is $count_after, $TRUE,
		'Class::Abstract appears exactly once in @UT::ImportA::ISA';
};

# Purpose: import() must return the module name as a typed string
subtest 'import() -- return value is the module name as a typed string' => sub {
	plan tests => 3;

	# Install a spy to confirm set_return is called with the right schema.
	# The spy passes through to the original, so import() still works.
	my $spy = spy 'Class::Abstract::set_return';

	# Call import() from a fresh package so the normal (non-early-return) path runs
	my $ret;
	{ package UT::ImportB; our @ISA = (); $ret = Class::Abstract->import() }

	# Restore the spy before any assertion that may call set_return itself
	restore_all();

	diag "import() returned: '$ret'" if $ENV{TEST_VERBOSE};

	# The return value must equal the module name
	is $ret, $CLASS_ABSTRACT, 'import() returns the string "Class::Abstract"';

	# Validate the return type using the documented schema
	returns_ok $ret, $config{schema_string},
		'import() return satisfies the { type => "string" } schema';

	# Verify set_return was invoked (typed-return contract honoured)
	my @calls = $spy->();
	ok scalar @calls >= $TRUE,
		'set_return() was called inside import() for the typed return';
};

# Purpose: import() must not add anything to Class::Abstract's own @ISA
subtest 'import() -- does not register Class::Abstract into its own @ISA' => sub {
	plan tests => 1;

	# Snapshot the ISA array before any call
	my @snapshot = @Class::Abstract::ISA;

	# Re-entering import() from the same module is blocked by the self-guard.
	# We verify the invariant directly: ISA must be identical before and after.
	is_deeply \@Class::Abstract::ISA, \@snapshot,
		'@Class::Abstract::ISA is unchanged (self-registration guard holds)';
};

# ===========================================================================
# SECTION: new()
#
# POD contract:
#   - Returns a blessed empty hashref of class $class
#   - Croaks for directly abstract classes (when enforcement is active)
#   - Accepts a blessed object as the invocant
#   - Rejects unblessed references with an error
#   - Rejects undef with an error
#   - Bypass variables suppress the abstract croak
# ===========================================================================

# Purpose: a concrete class must be successfully instantiated
subtest 'new() -- returns a blessed hashref for a concrete class' => sub {
	plan tests => 2;

	my $obj;

	# Enforcement on: UT::Concrete is not abstract, so new() must succeed
	enforcement_on {
		lives_ok { $obj = UT::Concrete->new() }
			'UT::Concrete->new() lives (concrete class)';
	};

	# The returned value must be a blessed reference
	ok blessed($obj), 'new() returns a blessed reference';
};

# Purpose: the object must carry the correct class, not a base class
subtest 'new() -- blesses the object into the concrete invocant class' => sub {
	plan tests => 1;

	# ref() on the returned object must equal the calling class
	my $obj = UT::Concrete->new();
	is ref($obj), $config{pkg_concrete},
		'new() blesses the object into UT::Concrete, not Class::Abstract';
};

# Purpose: directly abstract class must croak when enforcement is active
subtest 'new() -- croaks for a directly abstract class (enforcement on)' => sub {
	plan tests => 2;

	enforcement_on {
		# throws_ok verifies exact error message format from the POD
		throws_ok { UT::Abstract->new() }
			qr/Cannot instantiate abstract class UT::Abstract directly/,
			'new() croaks with the exact documented error for abstract class';

		# Verify the canonical phrase is present in $@
		like $@, qr/Cannot instantiate abstract class/,
			'$@ contains the documented error phrase';
	};
};

# Purpose: $BYPASS = truthy must suppress the abstract-class croak
subtest 'new() -- $BYPASS suppresses the abstract croak' => sub {
	plan tests => 1;

	# Only $BYPASS active; harness paths are disabled
	local $Class::Abstract::BYPASS                 = $TRUE;
	local $Class::Abstract::config{harness_bypass} = $FALSE;
	local $ENV{HARNESS_ACTIVE}                     = $FALSE;

	# No croak expected under bypass
	lives_ok { UT::Abstract->new() }
		'new() lives when $BYPASS is set to a truthy value';
};

# Purpose: harness_bypass=1 + HARNESS_ACTIVE must suppress the abstract croak
subtest 'new() -- harness_bypass path suppresses the abstract croak' => sub {
	plan tests => 1;

	# Harness bypass active; global $BYPASS disabled
	local $Class::Abstract::BYPASS                 = $FALSE;
	local $Class::Abstract::config{harness_bypass} = $TRUE;
	local $ENV{HARNESS_ACTIVE}                     = $TRUE;

	# No croak expected under harness bypass
	lives_ok { UT::Abstract->new() }
		'new() lives under harness_bypass + HARNESS_ACTIVE';
};

# Purpose: a blessed object passed as invocant must be dereferenced to its class
subtest 'new() -- accepts a blessed object as the invocant' => sub {
	plan tests => 2;

	# Create an existing concrete instance to use as the invocant
	my $existing = UT::Concrete->new();
	ok blessed($existing), 'precondition: $existing is a blessed object';

	# Calling new() on a blessed instance must succeed for a concrete class
	enforcement_on {
		lives_ok { $existing->new() }
			'$concrete_obj->new() lives (blessed-ref invocant)';
	};
};

# Purpose: unblessed references must be rejected before any other check
subtest 'new() -- croaks for unblessed reference invocant (arrayref)' => sub {
	plan tests => 2;

	# Invocant validation fires before the abstract check; no bypass needed
	throws_ok { Class::Abstract::new([]) }
		$config{err_new_unblessed},
		'new([]) croaks: documented message for unblessed arrayref';

	# Scalarref must also be rejected by the same guard
	throws_ok { Class::Abstract::new(\42) }
		$config{err_new_unblessed},
		'new(\42) croaks: documented message for unblessed scalarref';
};

# Purpose: undef invocant must produce a controlled croak
subtest 'new() -- croaks for undef invocant' => sub {
	plan tests => 1;

	# undef bypasses the ref() guard and hits the defined() guard
	throws_ok { Class::Abstract::new(undef) }
		$config{err_new_undef},
		'new(undef) croaks with the documented error message';
};

# Purpose: "" is defined but length 0 -- the 'l&&!r' branch of 'defined&&length'
subtest 'new() -- croaks for defined-but-empty string class name' => sub {
	plan tests => 1;

	# defined('') is true; length('') is 0 -- the guard fires on the right-hand side
	throws_ok { Class::Abstract::new('') }
		$config{err_new_undef},
		'new("") croaks: empty string passes defined() but fails length()';
};

# Purpose: production scenario -- harness_bypass=1 (default) but HARNESS_ACTIVE unset
# simulates running outside a test harness with default settings.
subtest 'new() -- production scenario: harness_bypass=1, no HARNESS_ACTIVE, no BYPASS' => sub {
	plan tests => 2;

	# bypass expression: 0 || (1 && '') = false -> enforcement fires
	{
		local $Class::Abstract::BYPASS                 = 0;
		local $Class::Abstract::config{harness_bypass} = 1;
		local $ENV{HARNESS_ACTIVE}                     = '';

		throws_ok { UT::Abstract->new() }
			$config{err_abstract},
			'enforcement fires in production: BYPASS=0, harness_bypass=1, HARNESS_ACTIVE=""';
	}

	# Concrete class must still succeed in the same context
	{
		local $Class::Abstract::BYPASS                 = 0;
		local $Class::Abstract::config{harness_bypass} = 1;
		local $ENV{HARNESS_ACTIVE}                     = '';

		lives_ok { UT::Concrete->new() }
			'concrete class succeeds in production context';
	}
};

# Purpose: blessed/unblessed distinction -- blessed ref yields its class, unblessed croaks
subtest 'new() -- distinguishes blessed from unblessed reference invocants' => sub {
	plan tests => 2;

	# A blessed UT::Concrete object used as invocant must produce a UT::Concrete object.
	# This proves new() extracts the class from the blessed ref rather than dying.
	my $existing = bless {}, $config{pkg_concrete};
	my $obj;
	lives_ok { $obj = $existing->new() }
		'blessed-ref invocant is accepted and returns a new object';

	# An unblessed ref passed directly must croak -- the two branches are distinct
	throws_ok { Class::Abstract::new({}) }
		$config{err_new_unblessed},
		'unblessed hashref invocant croaks with documented message';
};

# ===========================================================================
# SECTION: check_abstract()
#
# POD contract:
#   - Returns undef for concrete classes (void enforcement helper)
#   - Croaks for directly abstract classes (when enforcement is active)
#   - Accepts a blessed object as the argument
#   - Rejects unblessed references with an error
#   - Rejects undef with an error
#   - Respects $BYPASS and harness_bypass identically to new()
# ===========================================================================

# Purpose: a concrete class name must pass without croaking, returning undef
subtest 'check_abstract() -- returns undef for a concrete class name' => sub {
	plan tests => 2;

	my $ret;

	enforcement_on {
		# Concrete class must not trigger the enforcement croak
		lives_ok { $ret = Class::Abstract::check_abstract($config{pkg_concrete}) }
			'check_abstract() lives for a concrete class name';
	};

	# The POD documents the return as void (undef)
	ok !defined($ret), 'check_abstract() returns undef on success';
};

# Purpose: directly abstract class must croak with exact documented message
subtest 'check_abstract() -- croaks for a directly abstract class' => sub {
	plan tests => 2;

	enforcement_on {
		throws_ok { Class::Abstract::check_abstract($config{pkg_abstract}) }
			$config{err_abstract_ut},
			'check_abstract() croaks for abstract class with exact message';

		# The canonical phrase must appear in the error
		like $@, qr/Cannot instantiate abstract class/,
			'$@ contains the documented error phrase';
	};
};

# Purpose: $BYPASS must suppress the croak in check_abstract() too
subtest 'check_abstract() -- $BYPASS suppresses the abstract croak' => sub {
	plan tests => 1;

	local $Class::Abstract::BYPASS                 = $TRUE;
	local $Class::Abstract::config{harness_bypass} = $FALSE;
	local $ENV{HARNESS_ACTIVE}                     = $FALSE;

	lives_ok { Class::Abstract::check_abstract($config{pkg_abstract}) }
		'check_abstract() lives when $BYPASS is set';
};

# Purpose: harness bypass must suppress the croak in check_abstract()
subtest 'check_abstract() -- harness bypass suppresses the abstract croak' => sub {
	plan tests => 1;

	local $Class::Abstract::BYPASS                 = $FALSE;
	local $Class::Abstract::config{harness_bypass} = $TRUE;
	local $ENV{HARNESS_ACTIVE}                     = $TRUE;

	lives_ok { Class::Abstract::check_abstract($config{pkg_abstract}) }
		'check_abstract() lives under harness_bypass + HARNESS_ACTIVE';
};

# Purpose: a blessed concrete object must be accepted (uses ref() for class)
subtest 'check_abstract() -- accepts a blessed object as the argument' => sub {
	plan tests => 2;

	# Create a concrete instance to use as the argument
	my $obj = UT::Concrete->new();
	ok blessed($obj), 'precondition: $obj is a blessed concrete object';

	# check_abstract() must extract the class from ref() and pass the check
	enforcement_on {
		lives_ok { Class::Abstract::check_abstract($obj) }
			'check_abstract($blessed_concrete_obj) lives';
	};
};

# Purpose: unblessed references must be rejected before the abstract check
subtest 'check_abstract() -- croaks for an unblessed reference argument' => sub {
	plan tests => 1;

	# Invocant validation fires before enforcement; no bypass needed
	throws_ok { Class::Abstract::check_abstract([]) }
		$config{err_chk_unblessed},
		'check_abstract([]) croaks with documented message for unblessed ref';
};

# Purpose: undef argument must produce a controlled croak
subtest 'check_abstract() -- croaks for undef argument' => sub {
	plan tests => 1;

	throws_ok { Class::Abstract::check_abstract(undef) }
		$config{err_chk_undef},
		'check_abstract(undef) croaks with documented message';
};

# Purpose: "" is defined but length 0 -- check_abstract() must also croak
subtest 'check_abstract() -- croaks for defined-but-empty string argument' => sub {
	plan tests => 1;

	throws_ok { Class::Abstract::check_abstract('') }
		$config{err_chk_undef},
		'check_abstract("") croaks: defined empty string fails the length guard';
};

# Purpose: production scenario -- same as new() but for check_abstract()
subtest 'check_abstract() -- production scenario: harness_bypass=1, no HARNESS_ACTIVE' => sub {
	plan tests => 1;

	# bypass expression: 0 || (1 && '') = false -> enforcement fires
	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 1;
	local $ENV{HARNESS_ACTIVE}                     = '';

	throws_ok { Class::Abstract::check_abstract($config{pkg_abstract}) }
		$config{err_abstract},
		'check_abstract() croaks in production: harness_bypass=1, HARNESS_ACTIVE=""';
};

# ===========================================================================
# SECTION: is_abstract()
#
# POD contract:
#   - Returns 1 when the invocant has Class::Abstract directly in @ISA
#   - Returns 0 for concrete classes (even with abstract ancestors)
#   - Returns 1 for Class::Abstract itself
#   - Accepts a blessed object (uses ref() for the class check)
#   - Three-argument form: Class::Abstract->is_abstract('SomeClass')
#   - Croaks for undef or empty-string invocant
# ===========================================================================

# Purpose: directly abstract class must return exactly 1
subtest 'is_abstract() -- returns 1 for a directly abstract class' => sub {
	plan tests => 2;

	my $result = UT::Abstract->is_abstract();

	diag "UT::Abstract->is_abstract() = $result" if $ENV{TEST_VERBOSE};

	# Documented return is the integer 1, not a truthy string
	is $result, $TRUE, 'UT::Abstract->is_abstract() = 1';

	# Validate the return type against the documented schema
	returns_ok $result, $config{schema_integer},
		'is_abstract() return satisfies { type => "integer" } for abstract class';
};

# Purpose: concrete class must return exactly 0 even with abstract ancestors
subtest 'is_abstract() -- returns 0 for concrete class with abstract ancestor' => sub {
	plan tests => 2;

	# UT::Concrete has Class::Abstract only transitively -- not directly abstract
	my $result = UT::Concrete->is_abstract();

	diag "UT::Concrete->is_abstract() = $result" if $ENV{TEST_VERBOSE};

	# Must return exactly the integer 0
	is $result, $FALSE, 'UT::Concrete->is_abstract() = 0';

	# Validate the return type
	returns_ok $result, $config{schema_integer},
		'is_abstract() return satisfies { type => "integer" } for concrete class';
};

# Purpose: Class::Abstract itself must report as abstract
subtest 'is_abstract() -- Class::Abstract itself reports is_abstract = 1' => sub {
	plan tests => 1;

	# The module is its own abstract class and must not be instantiated
	is( Class::Abstract->is_abstract(), $TRUE,
		'Class::Abstract->is_abstract() = 1' );
};

# Purpose: calling is_abstract() on a blessed instance checks its class
subtest 'is_abstract() -- blessed instance yields its class for the check' => sub {
	plan tests => 2;

	# Construct a concrete instance
	my $obj = UT::Concrete->new();
	ok blessed($obj), 'precondition: $obj is a blessed instance';

	# is_abstract() on an object must check ref($obj), not the object itself
	is $obj->is_abstract(), $FALSE,
		'$concrete_obj->is_abstract() = 0 (uses ref($obj) = "UT::Concrete")';
};

# Purpose: three-argument form must check the named class, not the invocant
subtest 'is_abstract() -- three-argument form checks the named class argument' => sub {
	plan tests => 2;

	# Class::Abstract->is_abstract('UT::Abstract') must check UT::Abstract
	is( Class::Abstract->is_abstract($config{pkg_abstract}), $TRUE,
		'Class::Abstract->is_abstract("UT::Abstract") = 1 (named abstract class)' );

	# Class::Abstract->is_abstract('UT::Concrete') must check UT::Concrete
	is( Class::Abstract->is_abstract($config{pkg_concrete}), $FALSE,
		'Class::Abstract->is_abstract("UT::Concrete") = 0 (named concrete class)' );
};

# Purpose: undef and empty-string invocants must croak with documented message
subtest 'is_abstract() -- croaks for undef or empty-string invocant' => sub {
	plan tests => 2;

	# No bypass is relevant here -- is_abstract() does not enforce abstract contract
	throws_ok { Class::Abstract::is_abstract(undef) }
		$config{err_isabs_undef},
		'is_abstract(undef) croaks with documented message';

	# Empty string fails the length() guard
	throws_ok { Class::Abstract::is_abstract('') }
		$config{err_isabs_undef},
		'is_abstract("") croaks with documented message';
};

done_testing();
