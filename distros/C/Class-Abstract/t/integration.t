#!/usr/bin/perl
# t/integration.t -- end-to-end integration tests for Class::Abstract.
#
# Tests full workflows across multiple routines, multiple class hierarchies,
# and interactions with external modules (Scalar::Util, Return::Set, UNIVERSAL).
# No mocking of behaviour -- spies are used only to verify external calls.
# All fixture packages are prefixed IT:: to avoid collisions with other tests.

use strict;
use warnings;

use Readonly;
use Scalar::Util     qw(blessed refaddr);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;

use Class::Abstract;

# ---------------------------------------------------------------------------
# Configuration -- every constant and message string lives here
# ---------------------------------------------------------------------------

my %config = (
	# Package names: Vehicle hierarchy (tests the 'use Class::Abstract' import form)
	pkg_vehicle	=> 'IT::Vehicle',
	pkg_car		=> 'IT::Car',
	pkg_truck	=> 'IT::Truck',

	# Package names: Animal hierarchy (tests multi-level abstract)
	pkg_animal	=> 'IT::Animal',
	pkg_mammal	=> 'IT::Mammal',
	pkg_dog		=> 'IT::Dog',
	pkg_cat		=> 'IT::Cat',

	# Package names: Bird hierarchy (tests custom new() with check_abstract)
	pkg_bird	=> 'IT::Bird',
	pkg_sparrow	=> 'IT::Sparrow',
	pkg_eagle	=> 'IT::Eagle',

	# The module under test
	pkg_module	=> 'Class::Abstract',

	# Expected error patterns (from the module POD)
	err_abstract	=> qr/Cannot instantiate abstract class \S+ directly/,

	# Schema definitions for Test::Returns validation
	schema_string	=> { type => 'string'  },
	schema_integer	=> { type => 'integer' },
	schema_object	=> { type => 'object'  },

	# Number of concurrent instances to create in concurrency tests
	instance_count	=> 5,
);

# Readonly constants -- avoid bare literals in assertions
Readonly::Scalar my $CLASS_ABSTRACT	=> 'Class::Abstract';
Readonly::Scalar my $TRUE		=> 1;
Readonly::Scalar my $FALSE		=> 0;

# ---------------------------------------------------------------------------
# Fixture class hierarchies
# ---------------------------------------------------------------------------

# ---- IT::Vehicle hierarchy -- uses the 'use Class::Abstract' import form ----

# IT::Vehicle is abstract via the import form (equivalent to use parent)
{
	package IT::Vehicle;
	use Class::Abstract;    # import() adds Class::Abstract to @IT::Vehicle::ISA
}

# IT::Car is a concrete subclass of IT::Vehicle
{
	package IT::Car;
	our @ISA = ('IT::Vehicle');
	sub new {
		my ($class, %args) = @_;
		my $self = $class->SUPER::new();
		$self->{make}  = $args{make}  // 'Generic';
		$self->{model} = $args{model} // 'Unknown';
		return $self;
	}
	sub drive { 'vroom' }
}

# IT::Truck is another concrete subclass with a payload attribute
{
	package IT::Truck;
	our @ISA = ('IT::Vehicle');
	sub new {
		my ($class, %args) = @_;
		my $self = $class->SUPER::new();
		$self->{payload_kg} = $args{payload_kg} // 0;
		return $self;
	}
	sub haul { 'rumble' }
}

# ---- IT::Animal hierarchy -- two abstract levels (Animal and Mammal) ----

# IT::Animal is abstract via use parent
{
	package IT::Animal;
	use parent -norequire, 'Class::Abstract';
}

# IT::Mammal is ALSO abstract: explicitly opts in with both parents
{
	package IT::Mammal;
	use parent -norequire, 'Class::Abstract', 'IT::Animal';
}

# IT::Dog is a concrete subclass -- populates attributes after SUPER::new
{
	package IT::Dog;
	our @ISA = ('IT::Mammal');
	sub new {
		my ($class, %args) = @_;
		my $self = $class->SUPER::new();
		$self->{name}  = $args{name}  // 'unnamed';
		$self->{breed} = $args{breed} // 'unknown';
		return $self;
	}
	sub speak { 'Woof' }
}

# IT::Cat is another concrete mammal
{
	package IT::Cat;
	our @ISA = ('IT::Mammal');
	sub new {
		my ($class, %args) = @_;
		my $self = $class->SUPER::new();
		$self->{name} = $args{name} // 'unnamed';
		return $self;
	}
	sub speak { 'Meow' }
}

# ---- IT::Bird hierarchy -- abstract class defines its own new() ----
# This exercises the check_abstract() workflow end-to-end.

# IT::Bird is abstract but defines its own new() that does NOT call SUPER::new.
# It must use check_abstract() instead to preserve enforcement.
{
	package IT::Bird;
	use parent -norequire, 'Class::Abstract';

	sub new {
		my ($class, %args) = @_;
		# check_abstract enforces the abstract contract for this custom constructor
		Class::Abstract::check_abstract($class);
		return bless { call_sound => $args{call} // 'tweet' }, $class;
	}
}

# IT::Sparrow is a concrete bird subclass
{
	package IT::Sparrow;
	our @ISA = ('IT::Bird');
	sub call { 'chirp' }
}

# IT::Eagle is a concrete bird subclass with a different call
{
	package IT::Eagle;
	our @ISA = ('IT::Bird');
	sub call { 'screech' }
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

diag 'Class::Abstract integration tests' if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 1: Module loading and public API surface
#
# Verify the module loads, the version is defined, and all public symbols
# are accessible before running any behavioural tests.
# ===========================================================================

# Purpose: confirm the module loads without compile errors or warnings
subtest 'module loading -- use_ok and public API surface' => sub {
	plan tests => 7;

	# use_ok confirms the module is on @INC and compiles cleanly
	use_ok($CLASS_ABSTRACT);

	# $VERSION must be defined and formatted as a decimal
	ok defined($Class::Abstract::VERSION), '$VERSION is defined';
	like $Class::Abstract::VERSION, qr/\A\d+\.\d+/, '$VERSION looks like a version string';

	# All four public methods must be callable
	ok( Class::Abstract->can('import'),        'Class::Abstract->can("import")'        );
	ok( Class::Abstract->can('new'),           'Class::Abstract->can("new")'           );
	ok( Class::Abstract->can('check_abstract'),'Class::Abstract->can("check_abstract")');
	ok( Class::Abstract->can('is_abstract'),   'Class::Abstract->can("is_abstract")'   );
};

# ===========================================================================
# SECTION 2: Vehicle hierarchy -- end-to-end import-form workflow
#
# The 'use Class::Abstract' import form must produce identical results to
# the 'use parent' inheritance form.  This tests the full constructor chain
# from a concrete subclass through the abstract base.
# ===========================================================================

# Purpose: abstract Vehicle must croak; concrete Car and Truck must succeed
subtest 'Vehicle hierarchy -- import form enforces abstract contract' => sub {
	plan tests => 4;

	enforcement_on {
		# Direct instantiation of the abstract class must croak
		throws_ok { IT::Vehicle->new() }
			$config{err_abstract},
			'IT::Vehicle->new() croaks (abstract via import form)';

		# Concrete subclasses must succeed
		lives_ok { IT::Car->new() }
			'IT::Car->new() lives (concrete subclass)';

		lives_ok { IT::Truck->new() }
			'IT::Truck->new() lives (concrete subclass)';
	};

	# Class::Abstract must be in IT::Vehicle's @ISA (the import effect)
	ok grep { $_ eq $CLASS_ABSTRACT } @IT::Vehicle::ISA,
		'import form added Class::Abstract to @IT::Vehicle::ISA';
};

# Purpose: Car and Truck objects carry the correct blessed class and attributes
subtest 'Vehicle hierarchy -- objects are correctly blessed and populated' => sub {
	plan tests => 6;

	# new_ok verifies the call succeeds and the result is a blessed ref
	my $car   = new_ok('IT::Car',   [ make => 'Toyota', model => 'Yaris' ]);
	my $truck = new_ok('IT::Truck', [ payload_kg => 5000 ]);

	# Object classes must match the concrete subclass, not the abstract base
	is ref($car),   $config{pkg_car},   'car is blessed into IT::Car';
	is ref($truck), $config{pkg_truck}, 'truck is blessed into IT::Truck';

	diag "car->make = $car->{make}, truck->payload = $truck->{payload_kg}"
		if $ENV{TEST_VERBOSE};

	# Attributes must be populated by each subclass's own new()
	is $car->{make},        'Toyota', 'car make attribute set correctly';
	is $truck->{payload_kg}, 5000,   'truck payload_kg attribute set correctly';
};

# ===========================================================================
# SECTION 3: Animal / Mammal hierarchy -- multi-level abstract classes
#
# Both Animal and Mammal are abstract.  Only Dog and Cat can be instantiated.
# This tests that each level of the hierarchy opts in independently and that
# the is_abstract() predicate correctly distinguishes direct-abstract vs not.
# ===========================================================================

# Purpose: Animal and Mammal both croak; Dog and Cat both succeed
subtest 'Animal/Mammal hierarchy -- both abstract levels enforced' => sub {
	plan tests => 4;

	enforcement_on {
		# Both abstract levels must croak
		throws_ok { IT::Animal->new() }
			qr/Cannot instantiate abstract class IT::Animal directly/,
			'IT::Animal->new() croaks (first abstract level)';

		throws_ok { IT::Mammal->new() }
			qr/Cannot instantiate abstract class IT::Mammal directly/,
			'IT::Mammal->new() croaks (second abstract level)';

		# Concrete subclasses two and three levels below abstract must succeed
		lives_ok { IT::Dog->new(name => 'Rex') }
			'IT::Dog->new() lives (concrete, two levels below abstract)';

		lives_ok { IT::Cat->new(name => 'Whiskers') }
			'IT::Cat->new() lives (concrete, two levels below abstract)';
	};
};

# Purpose: is_abstract() must return the correct value at every level
subtest 'Animal/Mammal hierarchy -- is_abstract() across all levels' => sub {
	plan tests => 5;

	# Class::Abstract itself must be abstract
	is( Class::Abstract->is_abstract(), $TRUE,
		'Class::Abstract->is_abstract() = 1' );

	# Each directly abstract level must report 1
	is( IT::Animal->is_abstract(), $TRUE,
		'IT::Animal->is_abstract() = 1 (direct)' );

	is( IT::Mammal->is_abstract(), $TRUE,
		'IT::Mammal->is_abstract() = 1 (direct, even though Animal is also abstract)' );

	# Concrete classes must report 0 regardless of how many abstract levels above
	is( IT::Dog->is_abstract(), $FALSE,
		'IT::Dog->is_abstract() = 0 (concrete, not in direct @ISA)' );

	is( IT::Cat->is_abstract(), $FALSE,
		'IT::Cat->is_abstract() = 0 (concrete)' );
};

# Purpose: Dog attributes must be populated correctly via SUPER::new chain
subtest 'Animal/Mammal hierarchy -- SUPER::new chain populates attributes' => sub {
	plan tests => 4;

	# Dog->new delegates to Mammal->SUPER->Animal->SUPER->Class::Abstract::new
	my $dog = IT::Dog->new(name => 'Buddy', breed => 'Labrador');

	# The object must be a blessed IT::Dog hashref
	ok blessed($dog), 'IT::Dog->new() returned a blessed reference';
	is ref($dog), $config{pkg_dog}, 'object is blessed into IT::Dog';

	# Attributes must survive the full SUPER chain
	is $dog->{name},  'Buddy',    'name attribute populated after full SUPER chain';
	is $dog->{breed}, 'Labrador', 'breed attribute populated after full SUPER chain';
};

# ===========================================================================
# SECTION 4: Bird hierarchy -- custom new() with check_abstract()
#
# IT::Bird defines its own new() that does NOT delegate to SUPER::new.
# The check_abstract() call at the top of Bird::new is the only guard.
# ===========================================================================

# Purpose: Bird->new must croak even though the croak is in Bird::new, not Class::Abstract::new
subtest 'Bird hierarchy -- check_abstract() enforces abstract contract in custom new()' => sub {
	plan tests => 4;

	enforcement_on {
		# check_abstract must croak for the abstract class
		throws_ok { IT::Bird->new() }
			qr/Cannot instantiate abstract class IT::Bird directly/,
			'IT::Bird->new() croaks via check_abstract() in custom new()';

		# Concrete subclasses must reach the bless line
		my $sparrow;
		lives_ok { $sparrow = IT::Sparrow->new(call => 'chirp') }
			'IT::Sparrow->new() lives (concrete bird)';

		# Object must be blessed into the concrete subclass, not IT::Bird
		is ref($sparrow), $config{pkg_sparrow},
			'sparrow is blessed into IT::Sparrow';

		# Custom attribute from Bird::new must be present
		is $sparrow->{call_sound}, 'chirp',
			'call_sound attribute set by IT::Bird::new after check_abstract passes';
	};
};

# ===========================================================================
# SECTION 5: Multiple concurrent instances
#
# Each call to new() must produce a completely independent object.  Multiple
# instances of the same class must not share any mutable state.
# ===========================================================================

# Purpose: create many instances simultaneously; all must be distinct and blessed
subtest 'concurrency -- multiple instances are independent blessed objects' => sub {
	# Plan: N blessed checks for dogs + 1 distinct check + N for cars + 1 + 1 cross
	plan tests => 3 + 2 * $config{instance_count};

	# Create several Dog and Car instances simultaneously
	my @dogs = map { IT::Dog->new(name => "Dog$_") } 1 .. $config{instance_count};
	my @cars  = map { IT::Car->new(make => "Make$_") } 1 .. $config{instance_count};

	# Every Dog instance must be a blessed reference
	for my $i (0 .. $config{instance_count} - 1) {
		ok blessed($dogs[$i]), "dog[$i] is a blessed reference";
	}

	# First and last Dog must be distinct objects (no aliasing across the array)
	isnt refaddr($dogs[0]), refaddr($dogs[-1]),
		'first and last Dog instances are distinct objects';

	# Every Car instance must also be a blessed reference
	for my $i (0 .. $config{instance_count} - 1) {
		ok blessed($cars[$i]), "car[$i] is a blessed reference";
	}

	# First and last Car must be distinct objects
	isnt refaddr($cars[0]), refaddr($cars[-1]),
		'first and last Car instances are distinct objects';

	# A Dog and a Car must never share the same address
	isnt refaddr($dogs[0]), refaddr($cars[0]),
		'a Dog instance and a Car instance are different objects';
};

# Purpose: mutating one instance must not affect other instances of the same class
subtest 'concurrency -- instance state is isolated between objects' => sub {
	plan tests => 4;

	# Create two Dog instances with different names
	my $dog1 = IT::Dog->new(name => 'Rex');
	my $dog2 = IT::Dog->new(name => 'Fido');

	diag "dog1 name: $dog1->{name}, dog2 name: $dog2->{name}"
		if $ENV{TEST_VERBOSE};

	# Initial state must differ between instances
	isnt $dog1->{name}, $dog2->{name},
		'two Dog instances start with different name attributes';

	# Mutate dog1 and verify dog2 is unaffected
	$dog1->{name} = 'Max';
	is $dog1->{name}, 'Max',  'dog1 name updated to Max';
	is $dog2->{name}, 'Fido', 'dog2 name unchanged after mutating dog1';

	# Objects from different hierarchies in the same scope must coexist
	my $car = IT::Car->new(make => 'Ford');
	ok blessed($car), 'Car instance coexists with Dog instances in same scope';
};

# ===========================================================================
# SECTION 6: UNIVERSAL::isa integration
#
# isa() returns true for all ancestors including Class::Abstract (transitive),
# but is_abstract() returns true only for classes with Class::Abstract
# directly in @ISA.  The two methods measure different things.
# ===========================================================================

# Purpose: isa() and is_abstract() give different answers for concrete classes
subtest 'UNIVERSAL::isa vs is_abstract() -- different answers for concrete classes' => sub {
	plan tests => 8;

	# All classes in the Animal hierarchy share Class::Abstract as an ancestor.
	# Parentheses required: without them Perl parses 'ok CLASS->isa(...)' as
	# 'CLASS->ok(...)' (indirect-object syntax).
	ok( IT::Animal->isa($CLASS_ABSTRACT),
		'IT::Animal->isa("Class::Abstract") = 1 (direct ancestor)' );

	ok( IT::Mammal->isa($CLASS_ABSTRACT),
		'IT::Mammal->isa("Class::Abstract") = 1 (direct ancestor)' );

	ok( IT::Dog->isa($CLASS_ABSTRACT),
		'IT::Dog->isa("Class::Abstract") = 1 (transitive ancestor -- Dog inherits Mammal->Animal->Class::Abstract)' );

	# But is_abstract() distinguishes abstract from merely related
	is( IT::Dog->is_abstract(), $FALSE,
		'IT::Dog->is_abstract() = 0 (Class::Abstract not in @IT::Dog::ISA directly)' );

	# A blessed Dog instance behaves the same way
	my $dog = IT::Dog->new();
	ok( $dog->isa($CLASS_ABSTRACT),
		'$dog->isa("Class::Abstract") = 1 (transitive via MRO)' );

	is $dog->is_abstract(), $FALSE,
		'$dog->is_abstract() = 0 (instance of a concrete class)';

	# The three-arg form verifies a named class from any invocant
	is( Class::Abstract->is_abstract($config{pkg_dog}), $FALSE,
		'Class::Abstract->is_abstract("IT::Dog") = 0 (three-arg form)' );

	is( Class::Abstract->is_abstract($config{pkg_mammal}), $TRUE,
		'Class::Abstract->is_abstract("IT::Mammal") = 1 (three-arg form)' );
};

# ===========================================================================
# SECTION 7: Bypass integration -- full workflow with bypass enabled
#
# The bypass mechanism must suppress enforcement for all three entry points:
# new(), check_abstract(), and (implicitly) any SUPER::new chain.
# ===========================================================================

# Purpose: $BYPASS enables instantiation of otherwise-abstract classes
subtest 'bypass integration -- $BYPASS suppresses enforcement for all abstract classes' => sub {
	plan tests => 3;

	local $Class::Abstract::BYPASS                 = $TRUE;
	local $Class::Abstract::config{harness_bypass} = $FALSE;
	local $ENV{HARNESS_ACTIVE}                     = $FALSE;

	# With $BYPASS set, all abstract classes must be instantiable
	lives_ok { IT::Animal->new()  } '$BYPASS: IT::Animal->new() lives';
	lives_ok { IT::Mammal->new()  } '$BYPASS: IT::Mammal->new() lives';

	# Bird uses check_abstract() in its own new() -- bypass must suppress that too
	lives_ok { IT::Bird->new()    } '$BYPASS: IT::Bird->new() lives (via check_abstract)';
};

# Purpose: harness bypass (the default test-suite mode) suppresses enforcement
subtest 'bypass integration -- harness_bypass suppresses enforcement under HARNESS_ACTIVE' => sub {
	plan tests => 2;

	local $Class::Abstract::BYPASS                 = $FALSE;
	local $Class::Abstract::config{harness_bypass} = $TRUE;
	local $ENV{HARNESS_ACTIVE}                     = $TRUE;

	# Under normal test-harness conditions abstract classes must not croak
	lives_ok { IT::Vehicle->new() } 'harness bypass: IT::Vehicle->new() lives';
	lives_ok { IT::Animal->new()  } 'harness bypass: IT::Animal->new() lives';
};

# ===========================================================================
# SECTION 8: Return::Set integration -- import() typed return
#
# import() uses set_return() to return a typed string value.  A spy confirms
# the call happens with the correct arguments: (class_name, {type=>'string'}).
# ===========================================================================

# Purpose: import() calls set_return with the expected typed-return schema
subtest 'Return::Set integration -- import() delivers typed return via set_return()' => sub {
	plan tests => 4;

	# Spy on the imported set_return function (passes through to original)
	my $spy = spy 'Class::Abstract::set_return';

	# Fresh package so import() takes the normal (non-early-return) path
	{ package IT::ImportSpyTarget; our @ISA = (); Class::Abstract->import() }

	restore_all();

	# Gather the captured calls
	my @calls = $spy->();

	diag 'set_return call count: ' . scalar(@calls) if $ENV{TEST_VERBOSE};

	# set_return must have been called at least once
	ok scalar @calls >= $TRUE,
		'set_return() called inside import()';

	# First argument must be the class name 'Class::Abstract'
	is $calls[0][1], $CLASS_ABSTRACT,
		'set_return first arg = "Class::Abstract"';

	# Second argument must be the string-type schema
	is_deeply $calls[0][2], $config{schema_string},
		'set_return second arg = { type => "string" }';

	# Return value of import() must satisfy the typed-string schema itself
	my $ret;
	{ package IT::ImportRet; our @ISA = (); $ret = Class::Abstract->import() }

	returns_ok $ret, $config{schema_string},
		'import() return value satisfies { type => "string" } schema';
};

# ===========================================================================
# SECTION 9: Cross-hierarchy and stateful interaction
#
# Mix objects from different hierarchies, verify is_abstract() and blessed()
# behave consistently, and that object identity is preserved correctly.
# ===========================================================================

# Purpose: objects from different hierarchies must coexist without interference
subtest 'cross-hierarchy -- Dog, Car, and Sparrow instances in the same scope' => sub {
	plan tests => 6;

	# Instantiate one object from each hierarchy
	my $dog     = IT::Dog->new(name => 'Buster');
	my $car     = IT::Car->new(make => 'Honda', model => 'Civic');

	# Enforcement on to test Bird hierarchy's check_abstract path
	my $sparrow;
	enforcement_on {
		lives_ok { $sparrow = IT::Sparrow->new(call => 'tweet') }
			'IT::Sparrow->new() lives (Bird hierarchy)';
	};

	# All three objects must be blessed
	ok blessed($dog),     'dog object is blessed';
	ok blessed($car),     'car object is blessed';
	ok blessed($sparrow), 'sparrow object is blessed';

	# is_abstract() on instances of each hierarchy must all return 0
	is $dog->is_abstract(),     $FALSE, '$dog->is_abstract() = 0';
	is $sparrow->is_abstract(), $FALSE, '$sparrow->is_abstract() = 0';
};

# Purpose: three-arg is_abstract() form correctly queries any named class
subtest 'cross-hierarchy -- three-arg is_abstract() queries any named class' => sub {
	plan tests => 6;

	# Query classes from all three hierarchies via the three-arg form
	is( Class::Abstract->is_abstract($config{pkg_vehicle}), $TRUE,
		'IT::Vehicle is_abstract = 1 (import form)' );

	is( Class::Abstract->is_abstract($config{pkg_car}), $FALSE,
		'IT::Car is_abstract = 0' );

	is( Class::Abstract->is_abstract($config{pkg_animal}), $TRUE,
		'IT::Animal is_abstract = 1' );

	is( Class::Abstract->is_abstract($config{pkg_dog}), $FALSE,
		'IT::Dog is_abstract = 0' );

	is( Class::Abstract->is_abstract($config{pkg_bird}), $TRUE,
		'IT::Bird is_abstract = 1 (custom new)' );

	is( Class::Abstract->is_abstract($config{pkg_sparrow}), $FALSE,
		'IT::Sparrow is_abstract = 0' );
};

# ===========================================================================
# SECTION 10: Scalar::Util::blessed integration
#
# Every object created by new() across all hierarchies must pass blessed().
# Checks that blessed() integrates correctly with all construction patterns.
# ===========================================================================

# Purpose: all successfully constructed objects must satisfy blessed() check
subtest 'Scalar::Util integration -- every new() result satisfies blessed()' => sub {
	plan tests => 5;

	# One object from each concrete class in all three hierarchies
	my $car      = IT::Car->new();
	my $truck    = IT::Truck->new();
	my $dog      = IT::Dog->new();
	my $cat      = IT::Cat->new();

	my $sparrow;
	enforcement_on { lives_ok { $sparrow = IT::Sparrow->new() } 'sparrow created' };

	# Every object must be blessed (confirmed via Scalar::Util::blessed)
	ok blessed($car),     'IT::Car object satisfies blessed()';
	ok blessed($truck),   'IT::Truck object satisfies blessed()';
	ok blessed($dog),     'IT::Dog object satisfies blessed()';
	ok blessed($cat),     'IT::Cat object satisfies blessed()';
};

# ===========================================================================
# INTEGRATION: blessed abstract-class object used as new() invocant
#
# When an existing object of an abstract class is used as invocant to new(),
# new() extracts the class via blessed() and then checks if that class is
# abstract.  With enforcement on, the croak fires because the extracted
# class IS the abstract class.
# ===========================================================================

subtest 'end-to-end: blessed abstract instance as new() invocant causes croak' => sub {
	plan tests => 3;

	# Create an abstract instance using bypass (to get past enforcement)
	my $abstract_obj;
	{
		local $Class::Abstract::BYPASS = 1;
		$abstract_obj = IT::Vehicle->new();
	}

	ok blessed($abstract_obj), 'precondition: abstract instance created under bypass';
	is ref($abstract_obj), 'IT::Vehicle',
		'precondition: instance is blessed into IT::Vehicle (abstract)';

	# With enforcement on, passing this object to new() must croak
	enforcement_on {
		throws_ok { Class::Abstract::new($abstract_obj) }
			qr/Cannot instantiate abstract class IT::Vehicle directly/,
			'new(blessed abstract obj) croaks after extracting abstract class from blessed ref';
	};
};

# ===========================================================================
# INTEGRATION: production context across full hierarchy
#
# Simulates running outside a harness (HARNESS_ACTIVE unset, harness_bypass=1)
# with no BYPASS.  This is the default deployment scenario.
# ===========================================================================

subtest 'end-to-end: enforcement in production context (no harness, default settings)' => sub {
	plan tests => 3;

	# Production: BYPASS=0, harness_bypass=1 (default), HARNESS_ACTIVE='' (no harness)
	{
		local $Class::Abstract::BYPASS                 = 0;
		local $Class::Abstract::config{harness_bypass} = 1;
		local $ENV{HARNESS_ACTIVE}                     = '';

		# Abstract class must be blocked
		throws_ok { IT::Vehicle->new() }
			qr/Cannot instantiate abstract class IT::Vehicle directly/,
			'abstract IT::Vehicle blocked in production context';

		# Concrete subclass must succeed
		lives_ok { IT::Car->new() }
			'concrete IT::Car succeeds in production context';
	}

	# Multi-level: IT::Animal (abstract), IT::Mammal (also abstract), IT::Dog (concrete)
	{
		local $Class::Abstract::BYPASS                 = 0;
		local $Class::Abstract::config{harness_bypass} = 1;
		local $ENV{HARNESS_ACTIVE}                     = '';

		lives_ok { IT::Dog->new() }
			'IT::Dog (two levels from abstract) succeeds in production context';
	}
};

done_testing;
