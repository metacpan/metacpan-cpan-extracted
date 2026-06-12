#!/usr/bin/perl
# t/edge_cases.t -- destructive, boundary-condition, and security tests.
#
# Deliberately tries to break or subvert Class::Abstract by passing pathological
# inputs, mocking upstream dependencies with edge-case returns, manipulating
# @ISA at runtime, exploiting bypass mechanics, and verifying robustness under
# circular data structures.

use strict;
use warnings;

use Readonly;
use Scalar::Util     qw(blessed reftype weaken);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;

use Class::Abstract;

# ---------------------------------------------------------------------------
# Configuration -- every constant and boundary value in one place
# ---------------------------------------------------------------------------

my %config = (
	# Package names (EC:: prefix avoids collisions with other test files)
	pkg_abstract	=> 'EC::Abstract',
	pkg_concrete	=> 'EC::Concrete',
	pkg_dynamic	=> 'EC::Dynamic',
	pkg_circ_a	=> 'EC::CircA',
	pkg_circ_b	=> 'EC::CircB',
	pkg_module	=> 'Class::Abstract',

	# Boundary string values -- chosen to probe the defined() / length() guards
	str_zero	=> '0',          # falsy but length 1; must be treated as valid
	str_spaces	=> '   ',        # whitespace-only; length 3 but not a valid identifier
	str_long	=> 'A' x 5_000,  # very long identifier; no length limit in spec
	str_numeric	=> '123',        # numeric string; valid Perl package name

	# Truthy non-boolean bypass values (documented in the POD warnings section)
	bypass_str_false	=> 'false',  # counterintuitive but truthy
	bypass_str_zero_e	=> '0E0',    # numerically 0 but string-truthy
	bypass_float	=> 0.1,          # truthy number
	bypass_ref	=> [],             # reference; truthy

	# Expected error patterns matching the module POD exactly
	err_new_unblessed	=> qr/new\(\) invocant must be a class name or blessed object, got/,
	err_new_undef		=> qr/new\(\) requires a defined class name as invocant/,
	err_chk_unblessed	=> qr/check_abstract\(\) requires a class name or blessed object/,
	err_chk_undef		=> qr/check_abstract\(\) requires a defined class name/,
	err_isabs_undef		=> qr/is_abstract\(\) requires a class name or object invocant/,
	err_abstract		=> qr/Cannot instantiate abstract class \S+ directly/,

	# Test::Returns schemas
	schema_string	=> { type => 'string'  },
	schema_integer	=> { type => 'integer' },
);

# Readonly constants -- prevent accidental mutation
Readonly::Scalar my $CLASS_ABSTRACT	=> 'Class::Abstract';
Readonly::Scalar my $TRUE		=> 1;
Readonly::Scalar my $FALSE		=> 0;

# ---------------------------------------------------------------------------
# Fixture packages for edge-case scenarios
# ---------------------------------------------------------------------------

# EC::Abstract: directly abstract via use parent
{
	package EC::Abstract;
	use parent -norequire, 'Class::Abstract';
}

# EC::Concrete: concrete subclass of EC::Abstract
{
	package EC::Concrete;
	our @ISA = ('EC::Abstract');
	sub new {
		my ($class) = @_;
		return $class->SUPER::new();
	}
}

# EC::Dynamic: starts empty; @ISA is manipulated at test runtime
{
	package EC::Dynamic;
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

diag 'Class::Abstract edge-case tests' if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 1: Exotic unblessed reference types as invocant to new()
#
# POD: new() rejects unblessed references with a specific error that names
# the ref type.  Test every distinct ref type that ref() can return.
# ===========================================================================

# Purpose: each unblessed ref type must croak with the correct documented type name
subtest 'new() -- exotic unblessed ref invocants all croak with correct type name' => sub {
	plan tests => 5;

	# Arrayref -- ref() returns 'ARRAY'
	throws_ok { Class::Abstract::new([]) }
		qr/new\(\) invocant must be a class name or blessed object, got ARRAY/,
		'new([]) croaks: got ARRAY';

	# Hashref -- ref() returns 'HASH'
	throws_ok { Class::Abstract::new({}) }
		qr/new\(\) invocant must be a class name or blessed object, got HASH/,
		'new({}) croaks: got HASH';

	# Coderef -- ref() returns 'CODE'
	throws_ok { Class::Abstract::new(sub {}) }
		qr/new\(\) invocant must be a class name or blessed object, got CODE/,
		'new(sub{}) croaks: got CODE';

	# Typeglob -- ref(\*STDOUT) returns 'GLOB'
	throws_ok { Class::Abstract::new(\*STDOUT) }
		qr/new\(\) invocant must be a class name or blessed object, got GLOB/,
		'new(\*STDOUT) croaks: got GLOB';

	# Scalar ref -- ref() returns 'SCALAR'
	throws_ok { Class::Abstract::new(\42) }
		qr/new\(\) invocant must be a class name or blessed object, got SCALAR/,
		'new(\42) croaks: got SCALAR';
};

# ===========================================================================
# SECTION 2: Blessed Regexp ref as invocant (surprising but valid)
#
# In Perl, qr// creates an object blessed into class 'Regexp'.  Because
# blessed() returns 'Regexp' (truthy), new() treats it as a legitimate
# invocant and extracts 'Regexp' as the class name.
# ===========================================================================

# Purpose: document that blessed regex refs pass invocant validation
subtest 'new() -- blessed Regexp ref is accepted as invocant (Regexp is blessed)' => sub {
	plan tests => 3;

	# Confirm the test precondition: qr// IS blessed in this Perl
	ok defined(blessed(qr//)), 'precondition: qr// is blessed (class = Regexp)';

	diag 'qr// blessed class: ' . (blessed(qr//) // 'undef') if $ENV{TEST_VERBOSE};

	# Because blessed() returns 'Regexp', new() accepts it and creates
	# a hashref blessed into class 'Regexp' (ref of the invocant)
	my $obj;
	lives_ok { $obj = Class::Abstract::new(qr/foo/) }
		'new(qr/foo/) lives: blessed Regexp invocant is accepted';

	# The resulting class is 'Regexp' (from ref(qr/foo/))
	is ref($obj), 'Regexp',
		'new(qr/foo/) blesses into "Regexp" (the class of the qr// invocant)';
};

# ===========================================================================
# SECTION 3: Exotic ref types as invocant to check_abstract()
#
# check_abstract() uses the same validation path as new(), so it must
# reject the same range of unblessed reference types.
# ===========================================================================

# Purpose: check_abstract() rejects unblessed refs with the correct error
subtest 'check_abstract() -- exotic unblessed ref invocants croak correctly' => sub {
	plan tests => 3;

	# Arrayref
	throws_ok { Class::Abstract::check_abstract([]) }
		$config{err_chk_unblessed},
		'check_abstract([]) croaks with documented message';

	# Hashref (not blessed)
	throws_ok { Class::Abstract::check_abstract({}) }
		$config{err_chk_unblessed},
		'check_abstract({}) croaks with documented message';

	# Coderef
	throws_ok { Class::Abstract::check_abstract(sub {}) }
		$config{err_chk_unblessed},
		'check_abstract(sub{}) croaks with documented message';
};

# Purpose: "" is defined but length 0 -- check_abstract() must croak (l&&!r condition)
subtest 'check_abstract() -- "" is rejected: defined-but-empty string fails the length guard' => sub {
	plan tests => 1;

	# "" passes defined() but fails length() -- the same 'l&&!r' branch as in new()
	throws_ok { Class::Abstract::check_abstract('') }
		qr/check_abstract\(\) requires a defined class name/,
		'check_abstract("") croaks: empty string is defined but length 0';
};

# ===========================================================================
# SECTION 4: Boundary string inputs to new()
#
# The only string-level guards are defined() and length().  Values like "0",
# very long identifiers, and numeric strings all pass these guards even though
# they may not be valid Perl package names.  The module accepts them silently.
# ===========================================================================

# Purpose: "" is defined but has length 0 -- must croak (fails the length guard)
subtest 'new() -- "" is rejected: defined-but-empty string fails the length guard' => sub {
	plan tests => 1;

	# "" passes defined() but fails length() -- the 'l&&!r' condition branch
	throws_ok { Class::Abstract::new('') }
		qr/new\(\) requires a defined class name as invocant/,
		'new("") croaks: empty string is defined but length 0';
};

# Purpose: "0" is falsy but has length 1 -- must be accepted as a class name
subtest 'new() -- "0" is accepted as a class name (falsy but length 1)' => sub {
	plan tests => 3;

	# "0" passes defined("0") && length("0"); _is_direct_abstract("0") = 0
	my $obj;
	lives_ok { $obj = Class::Abstract::new($config{str_zero}) }
		'new("0") lives (falsy string with length 1)';

	# blessed($obj) returns "0" which is falsy -- use defined() to check blessedness
	ok defined(blessed($obj)),
		'new("0") returns a blessed reference (blessed() returns "0" which is defined)';

	is ref($obj), $config{str_zero},
		'object is blessed into class "0"';
};

# Purpose: very long class names must not cause a length-related failure
subtest 'new() -- very long class name (5000 chars) is accepted' => sub {
	plan tests => 2;

	diag 'long class name length: ' . length($config{str_long}) if $ENV{TEST_VERBOSE};

	# No length limit is documented; the module must handle arbitrarily long names
	my $obj;
	lives_ok { $obj = Class::Abstract::new($config{str_long}) }
		'new(5000-char name) lives (no length limit enforced)';

	ok blessed($obj),
		'new(5000-char name) returns a blessed reference';
};

# Purpose: new() must silently discard any additional arguments beyond $class
subtest 'new() -- extra arguments (including destructive types) are silently discarded' => sub {
	plan tests => 4;

	# POD states: any additional arguments beyond $class are silently discarded
	my $obj;
	lives_ok { $obj = EC::Concrete->new('extra', undef, [], {}, qr//) }
		'new($class, extra, undef, [], {}, qr//) lives (all extra args discarded)';

	ok blessed($obj), 'returned object is blessed even with extra args';

	# The object must be a plain empty hashref (extra args are not stored)
	is_deeply $obj, {}, 'returned object is an empty hashref (extra args not stored)';

	# A single extra undef must also be silently discarded (not treated as $class)
	my $obj2;
	lives_ok { $obj2 = EC::Concrete->new(undef) }
		'new($class, undef) lives (trailing undef discarded)';
};

# ===========================================================================
# SECTION 5: is_abstract() boundary inputs
#
# "0" must be treated as a valid class name (length 1).  Undef and empty
# string must croak with the documented error message.
# ===========================================================================

# Purpose: "0" as an argument to is_abstract() must be handled as a class name
subtest 'is_abstract() -- "0" is a valid class name (falsy but defined and non-empty)' => sub {
	plan tests => 2;

	# "0" is length 1 and defined: must not croak; class "0" is not abstract
	my $result = Class::Abstract->is_abstract($config{str_zero});

	is $result, $FALSE,
		'is_abstract("0") = 0 (class "0" has no Class::Abstract in @ISA)';

	returns_ok $result, $config{schema_integer},
		'is_abstract("0") satisfies integer return schema';
};

# Purpose: undef and empty string must croak (fail the length guard)
subtest 'is_abstract() -- undef and empty string croak with documented error' => sub {
	plan tests => 2;

	# undef fails defined() check
	throws_ok { Class::Abstract::is_abstract(undef) }
		$config{err_isabs_undef},
		'is_abstract(undef) croaks with documented message';

	# empty string passes defined() but fails length() check
	throws_ok { Class::Abstract::is_abstract('') }
		$config{err_isabs_undef},
		'is_abstract("") croaks with documented message';
};

# ===========================================================================
# SECTION 6: $BYPASS truthy non-boolean values -- the documented trap
#
# The POD explicitly warns: ANY truthy value (including the string "false",
# the string "0E0", or a reference) enables bypass.  This is counterintuitive
# and a potential source of accidental security bypasses.
# ===========================================================================

# Purpose: each of these surprising truthy values must bypass enforcement
subtest 'BYPASS -- truthy non-boolean values bypass enforcement (POD warning)' => sub {
	plan tests => 4;

	# The string "false" is truthy (length 5, not "0")
	{
		local $Class::Abstract::BYPASS                 = $config{bypass_str_false};
		local $Class::Abstract::config{harness_bypass} = $FALSE;
		local $ENV{HARNESS_ACTIVE}                     = $FALSE;
		lives_ok { EC::Abstract->new() }
			'$BYPASS = "false" bypasses enforcement (truthy string)';
	}

	# "0E0" is numerically 0 but string-truthy
	{
		local $Class::Abstract::BYPASS                 = $config{bypass_str_zero_e};
		local $Class::Abstract::config{harness_bypass} = $FALSE;
		local $ENV{HARNESS_ACTIVE}                     = $FALSE;
		lives_ok { EC::Abstract->new() }
			'$BYPASS = "0E0" bypasses enforcement (truthy despite numeric value 0)';
	}

	# A non-zero float is truthy
	{
		local $Class::Abstract::BYPASS                 = $config{bypass_float};
		local $Class::Abstract::config{harness_bypass} = $FALSE;
		local $ENV{HARNESS_ACTIVE}                     = $FALSE;
		lives_ok { EC::Abstract->new() }
			'$BYPASS = 0.1 bypasses enforcement (truthy float)';
	}

	# A reference is truthy
	{
		local $Class::Abstract::BYPASS                 = $config{bypass_ref};
		local $Class::Abstract::config{harness_bypass} = $FALSE;
		local $ENV{HARNESS_ACTIVE}                     = $FALSE;
		lives_ok { EC::Abstract->new() }
			'$BYPASS = [] bypasses enforcement (truthy reference)';
	}
};

# Purpose: falsy values must NOT bypass -- enforcement fires
subtest 'BYPASS -- falsy values do NOT bypass enforcement' => sub {
	plan tests => 3;

	# Integer 0 is falsy
	enforcement_on {
		local $Class::Abstract::BYPASS = $FALSE;
		throws_ok { EC::Abstract->new() }
			$config{err_abstract},
			'$BYPASS = 0 does not bypass enforcement';
	};

	# Empty string is falsy
	enforcement_on {
		local $Class::Abstract::BYPASS = '';
		throws_ok { EC::Abstract->new() }
			$config{err_abstract},
			'$BYPASS = "" does not bypass enforcement';
	};

	# undef is falsy
	enforcement_on {
		local $Class::Abstract::BYPASS = undef;
		throws_ok { EC::Abstract->new() }
			$config{err_abstract},
			'$BYPASS = undef does not bypass enforcement';
	};
};

# ===========================================================================
# SECTION 7: @ISA runtime manipulation -- security implications
#
# Perl's @ISA is mutable at runtime.  This section documents that removing
# Class::Abstract from @ISA defeats enforcement, and adding it makes a
# previously-concrete class suddenly abstract.
# ===========================================================================

# Purpose: removing Class::Abstract from @ISA at runtime defeats enforcement
subtest '@ISA mutation -- removing Class::Abstract makes abstract class concrete' => sub {
	plan tests => 2;

	# EC::Abstract currently has Class::Abstract in @ISA
	is( EC::Abstract->is_abstract(), $TRUE,
		'precondition: EC::Abstract->is_abstract() = 1' );

	# Temporarily remove Class::Abstract from @ISA.
	# NOTE: removing it also removes the inherited new() method.
	# We call Class::Abstract::new() as a plain function to test enforcement directly.
	{
		local @EC::Abstract::ISA = grep { $_ ne $CLASS_ABSTRACT } @EC::Abstract::ISA;

		diag '@EC::Abstract::ISA after removal: (' . join(', ', @EC::Abstract::ISA) . ')'
			if $ENV{TEST_VERBOSE};

		# Enforcement is now defeated: _is_direct_abstract returns 0 for empty @ISA
		enforcement_on {
			lives_ok { Class::Abstract::new($config{pkg_abstract}) }
				'SECURITY: removing Class::Abstract from @ISA defeats enforcement';
		};
	}
};

# Purpose: adding Class::Abstract to @ISA at runtime makes a concrete class abstract
subtest '@ISA mutation -- adding Class::Abstract makes concrete class abstract' => sub {
	plan tests => 2;

	# EC::Dynamic has no parents so it has no is_abstract() method.
	# Use the three-arg form from Class::Abstract to query it externally.
	is( Class::Abstract->is_abstract($config{pkg_dynamic}), $FALSE,
		'precondition: EC::Dynamic is not abstract (empty @ISA)' );

	# Add Class::Abstract to @ISA at runtime -- EC::Dynamic now inherits new()
	{
		local @EC::Dynamic::ISA = ($CLASS_ABSTRACT);

		diag '@EC::Dynamic::ISA set to (Class::Abstract)' if $ENV{TEST_VERBOSE};

		# EC::Dynamic is now directly abstract -- new() must croak
		enforcement_on {
			throws_ok { EC::Dynamic->new() }
				$config{err_abstract},
				'Adding Class::Abstract to @ISA at runtime makes class abstract';
		};
	}
};

# ===========================================================================
# SECTION 8: Circular @ISA -- Perl itself prevents it in 5.26+
#
# Perl detects circular inheritance and dies at the point of @ISA assignment.
# _is_direct_abstract therefore cannot encounter genuine circular @ISA via
# the normal API.  The test verifies Perl's protection fires before the module
# code even runs.
# ===========================================================================

# Purpose: document that Perl prevents circular @ISA before _is_direct_abstract runs
subtest 'circular @ISA -- Perl detects and prevents circular inheritance' => sub {
	plan tests => 2;

	# Perl 5.26+ raises "Recursive inheritance detected" when a circular
	# @ISA chain is created.  The second assignment below creates the cycle.
	throws_ok {
		local @EC::CircA::ISA = ($config{pkg_circ_b});
		local @EC::CircB::ISA = ($config{pkg_circ_a});  # Perl dies here
	}
		qr/Recursive inheritance detected/,
		'Perl prevents circular @ISA (dies with "Recursive inheritance detected")';

	# A non-circular chain must terminate normally in _is_direct_abstract
	{
		local @EC::CircA::ISA = ($config{pkg_dynamic});   # one-way, no cycle
		lives_ok { Class::Abstract::_is_direct_abstract($config{pkg_circ_a}) }
			'_is_direct_abstract terminates on a non-circular chain';
	}
};

# ===========================================================================
# SECTION 9: _is_direct_abstract with empty string -- @main::ISA probe
#
# An empty string class name bypasses the public API guards (is_abstract,
# new, check_abstract all check length > 0) and cannot reach
# _is_direct_abstract via the public interface.  Direct calls expose an
# implementation detail: @{"::ISA"} is @main::ISA in Perl's symbol table.
# ===========================================================================

# Purpose: document that _is_direct_abstract("") reads @main::ISA, not some other package
subtest '_is_direct_abstract("") reads @main::ISA (internal edge case)' => sub {
	plan tests => 2;

	# When @main::ISA contains Class::Abstract, _is_direct_abstract("") returns 1
	{
		local @main::ISA = ($CLASS_ABSTRACT);

		diag '@main::ISA temporarily set to contain Class::Abstract' if $ENV{TEST_VERBOSE};

		is Class::Abstract::_is_direct_abstract(''), $TRUE,
			'_is_direct_abstract("") = 1 when @main::ISA contains Class::Abstract';
	}

	# When @main::ISA does not contain Class::Abstract, returns 0
	{
		local @main::ISA = ('SomeOtherBase');
		is Class::Abstract::_is_direct_abstract(''), $FALSE,
			'_is_direct_abstract("") = 0 when @main::ISA does not contain Class::Abstract';
	}
};

# ===========================================================================
# SECTION 10: Scalar::Util::blessed() invocant guard boundary tests
#
# new() uses blessed() to detect whether the invocant is an object and to
# extract its class.  Note: blessed() carries a ($) prototype; whether that
# prototype prevents Test::Mockingbird from intercepting it is Perl-version-
# and Test::Mockingbird-version-dependent.  All tests here are purely
# behavioural and require no mocking of blessed() itself.
# ===========================================================================

# Purpose: verify the prototype annotation and the unblessed/blessed boundary
subtest 'blessed() invocant guard -- prototype check and unblessed/blessed boundary' => sub {
	plan tests => 3;

	# Confirm the ($) prototype annotation; its effect on mock intercept varies by version
	my $proto = prototype(\&Scalar::Util::blessed);
	is $proto, '$',
		'Scalar::Util::blessed has ($) prototype annotation';

	# Unblessed ref: blessed() returns undef (falsy) -> croak with ref type
	throws_ok { Class::Abstract::new({}) }
		$config{err_new_unblessed},
		'unblessed hashref: blessed()=undef; new() croaks with documented message';

	# Blessed ref: blessed() returns class name (truthy) -> invocant accepted
	my $blessed_ref = bless {}, $config{pkg_concrete};
	lives_ok { Class::Abstract::new($blessed_ref) }
		'blessed ref: blessed()=class_name; new() accepts the invocant';
};

# Purpose: prove that a blessed-ref invocant extracts the class from blessed()
# and creates a fresh, distinct object of that class.
subtest 'new() with blessed ref invocant -- creates new object of the blessed class' => sub {
	plan tests => 3;

	# When a blessed object is passed as invocant, new() extracts the class from
	# blessed($invocant) and returns a new object blessed into that class.
	my $existing = bless {}, $config{pkg_concrete};
	my $new_obj;
	lives_ok { $new_obj = Class::Abstract::new($existing) }
		'blessed ref invocant: new() does not croak';

	# The result is blessed into the same class as the invocant
	is ref($new_obj), $config{pkg_concrete},
		'new object is blessed into the same class as the invocant';

	# The result is a distinct reference -- new() always allocates a fresh hashref
	isnt $new_obj, $existing,
		'new object is a different reference than the invocant';
};

# ===========================================================================
# SECTION 11: Mock _is_direct_abstract returning unusual values
#
# The enforcement check is 'if _is_direct_abstract($class)' -- a boolean test.
# "0E0" is numerically 0 but STRING-truthy, so it triggers enforcement even
# for concrete classes.  undef and "" are falsy and suppress enforcement
# even for abstract classes.
# ===========================================================================

# Purpose: mock returning "0E0" (truthy) fires enforcement for a concrete class
subtest 'mock _is_direct_abstract returning "0E0" -- triggers croak for concrete class' => sub {
	plan tests => 1;

	# "0E0" is string-truthy: 'if "0E0"' is true, so enforcement fires
	mock 'Class::Abstract::_is_direct_abstract' => sub { '0E0' };

	enforcement_on {
		throws_ok { EC::Concrete->new() }
			qr/Cannot instantiate abstract class EC::Concrete directly/,
			'mock _is_direct_abstract="0E0": concrete class croaks (truthy return fires enforcement)';
	};

	restore_all();
};

# Purpose: mock returning undef (falsy) suppresses enforcement for an abstract class
subtest 'mock _is_direct_abstract returning undef -- suppresses croak for abstract class' => sub {
	plan tests => 1;

	# undef is falsy: 'if undef' is false, so enforcement is suppressed
	mock 'Class::Abstract::_is_direct_abstract' => sub { undef };

	enforcement_on {
		lives_ok { EC::Abstract->new() }
			'mock _is_direct_abstract=undef: abstract class lives (falsy suppresses enforcement)';
	};

	restore_all();
};

# ===========================================================================
# SECTION 12: Mock set_return returning edge-case values from import()
#
# import() delegates its return value entirely to set_return().  If set_return
# returns an edge-case value, import() propagates it unchanged.
# ===========================================================================

# Purpose: import() propagates whatever set_return returns including edge cases
subtest 'mock set_return returning edge values -- import() propagates them' => sub {
	plan tests => 3;

	# set_return returning undef: import() returns undef
	{
		mock 'Class::Abstract::set_return' => sub { undef };
		my $ret;
		{ package EC::SRMock1; our @ISA = (); $ret = Class::Abstract->import() }
		restore_all();
		ok !defined($ret), 'mock set_return=undef: import() returns undef';
	}

	# set_return returning 0: import() returns 0
	{
		mock 'Class::Abstract::set_return' => sub { 0 };
		my $ret;
		{ package EC::SRMock2; our @ISA = (); $ret = Class::Abstract->import() }
		restore_all();
		is $ret, 0, 'mock set_return=0: import() returns 0';
	}

	# set_return returning "": import() returns ""
	{
		mock 'Class::Abstract::set_return' => sub { '' };
		my $ret;
		{ package EC::SRMock3; our @ISA = (); $ret = Class::Abstract->import() }
		restore_all();
		is $ret, '', 'mock set_return="": import() returns ""';
	}
};

# ===========================================================================
# SECTION 13: Mocking croak to not die -- enforcement defeated silently
#
# SECURITY NOTE: Class::Abstract's enforcement relies entirely on Carp::croak
# dying.  If croak is replaced with a no-op (or returns rather than dying),
# enforcement is completely defeated: abstract classes become instantiable.
# This is a fundamental limitation of the design -- there is no secondary guard.
# ===========================================================================

# Purpose: document that enforcement has no fallback if croak is neutralized
subtest 'mock croak as no-op -- enforcement is defeated (design limitation)' => sub {
	plan tests => 2;

	# Replace croak with a silent no-op that returns without dying
	mock 'Class::Abstract::croak' => sub { return };

	enforcement_on {
		# EC::Abstract->new() would normally croak, but the mock prevents it
		my $obj = EC::Abstract->new();

		restore_all();

		# With croak neutralized, execution continues to 'return bless {}, $class'
		ok blessed($obj),
			'SECURITY: neutralized croak lets abstract class be instantiated';

		is ref($obj), $config{pkg_abstract},
			'SECURITY: resulting object is blessed into the abstract class';
	};
};

# ===========================================================================
# SECTION 14: Context sensitivity for is_abstract()
#
# is_abstract() returns a scalar integer.  In list context it must still
# deliver a single meaningful value.  In boolean context the result must
# be truthy for abstract classes and falsy for concrete ones.
# ===========================================================================

# Purpose: is_abstract() behaves consistently across calling contexts
subtest 'is_abstract() -- consistent in list, scalar, and boolean contexts' => sub {
	plan tests => 5;

	# List context: must return a list of exactly one element
	my @list = EC::Abstract->is_abstract();
	is scalar @list, 1,
		'is_abstract() in list context returns a 1-element list';

	is $list[0], $TRUE,
		'is_abstract() list context: first element is 1 for abstract class';

	# Scalar context: must return the integer 1 for abstract class
	my $scalar = EC::Abstract->is_abstract();
	is $scalar, $TRUE,
		'is_abstract() in scalar context returns 1 for abstract class';

	# Boolean context: abstract must be truthy, concrete must be falsy.
	# Explicit parens prevent 'ok CLASS->method' being parsed as 'CLASS->ok(...)'.
	ok( EC::Abstract->is_abstract(),
		'EC::Abstract->is_abstract() is truthy in boolean context' );

	ok( !EC::Concrete->is_abstract(),
		'EC::Concrete->is_abstract() is falsy in boolean context' );
};

# ===========================================================================
# SECTION 15: Weakened reference as invocant
#
# Scalar::Util::weaken() removes the strong reference count.  Once all
# strong references are gone the object is destroyed and the weak ref becomes
# undef.  A live (still-referenced) weakened blessed ref must pass new().
# A dead (garbage-collected) weakened ref becomes undef and must croak.
# ===========================================================================

# Purpose: live weakened blessed ref works; dead weakened ref croaks
subtest 'weakened references as invocants' => sub {
	plan tests => 3;

	# Live weak ref: a strong ref also exists, so the object survives
	my $strong = EC::Concrete->new();
	my $weak   = $strong;
	weaken($weak);

	diag 'weak ref: ' . (defined($weak) ? ref($weak) : 'undef') if $ENV{TEST_VERBOSE};

	# $weak is still alive because $strong holds a strong reference
	ok defined($weak) && blessed($weak),
		'precondition: weakened ref is still alive (strong ref holds it)';

	# A live weakened blessed ref must be accepted by new()
	lives_ok { $strong->new() }
		'live weakened blessed ref: new() succeeds via strong ref';

	# Dead weak ref: no strong references, object is garbage-collected immediately
	my $dead_weak = do { my $obj = EC::Concrete->new(); weaken($obj); $obj };

	# The dead weak ref is undef; ref(undef) = "", so it hits the undef guard
	throws_ok { Class::Abstract::new($dead_weak) }
		$config{err_new_undef},
		'dead weakened ref (undef) causes new() to croak with defined-class-name error';
};

# ===========================================================================
# SECTION 16: $_ is never clobbered by any public method
#
# Any grep or map over @ISA inside _is_direct_abstract could overwrite $_.
# Verify $_ is unchanged across all four public methods under varied inputs.
# ===========================================================================

# Purpose: no public method may mutate $_ in the calling scope
subtest '$_ not clobbered by any public method under varied inputs' => sub {
	plan tests => 4;

	# Use a value containing characters that would cause obvious corruption
	Readonly::Scalar my $SENTINEL => 'SENTINEL_DO_NOT_MUTATE';

	# import() must leave $_ alone
	{
		local $_ = $SENTINEL;
		{ package EC::DontClobberImport; our @ISA = (); Class::Abstract->import() }
		is $_, $SENTINEL, '$_ unchanged after import()';
	}

	# new() must leave $_ alone
	{
		local $_ = $SENTINEL;
		EC::Concrete->new();
		is $_, $SENTINEL, '$_ unchanged after new()';
	}

	# check_abstract() must leave $_ alone
	{
		local $_ = $SENTINEL;
		enforcement_on { Class::Abstract::check_abstract($config{pkg_concrete}) };
		is $_, $SENTINEL, '$_ unchanged after check_abstract()';
	}

	# is_abstract() must leave $_ alone (grep on @ISA is the risk)
	{
		local $_ = $SENTINEL;
		EC::Abstract->is_abstract();
		EC::Concrete->is_abstract();
		Class::Abstract->is_abstract($config{pkg_abstract});
		is $_, $SENTINEL, '$_ unchanged after multiple is_abstract() calls';
	}
};

done_testing;
