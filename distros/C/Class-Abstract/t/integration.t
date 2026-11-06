#!/usr/bin/perl
# t/integration.t -- black-box, end-to-end tests for Class::Abstract.
#
# These tests drive whole workflows the way a user would: several class
# hierarchies built in different documented ways, objects made and used
# side by side, the bypass switched on and off, and the module combined
# with its companion modules (Sub::Abstract, Sub::Private, Sub::Protected).
#
# They also put the module under environmental stress:
#   - companion modules present and absent, in every combination
#     (Test::Without::Module, in separate perl processes)
#   - required modules missing (must fail at load time, clearly)
#   - a filesystem with permissions taken away (Test::Permissions)
#   - its one runtime dependency (Return::Set::set_return) made slow,
#     failing, hanging, or returning junk
#
# Mocking is kept to the sabotage section.  Elsewhere, spies only watch
# the module's calls to Return::Set and Carp.

use strict;
use warnings;

use Cwd          qw(getcwd);
use File::Spec;
use File::Temp   qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed refaddr);
use Time::HiRes  qw(time sleep);
use Test::Most;
use Test::Mockingbird;
use Test::Permissions qw(:revoke :guard :report);
use Test::Returns;

# Empty import list: a bare "use Class::Abstract;" here would make package
# main abstract (POD: COMMON PITFALLS).
use Class::Abstract ();

# ---------------------------------------------------------------------------
# Configuration -- every constant and message string lives here
# ---------------------------------------------------------------------------

my %config = (
	# Package names: Vehicle hierarchy (the 'use Class::Abstract' import form)
	pkg_vehicle	=> 'IT::Vehicle',
	pkg_car		=> 'IT::Car',
	pkg_truck	=> 'IT::Truck',

	# Package names: Animal hierarchy (two abstract levels)
	pkg_animal	=> 'IT::Animal',
	pkg_mammal	=> 'IT::Mammal',
	pkg_dog		=> 'IT::Dog',
	pkg_cat		=> 'IT::Cat',

	# Package names: Bird hierarchy (abstract class with its own new())
	pkg_bird	=> 'IT::Bird',
	pkg_sparrow	=> 'IT::Sparrow',
	pkg_eagle	=> 'IT::Eagle',

	# The module under test, its runtime dependencies, and its companions
	pkg_module	=> 'Class::Abstract',
	required_deps	=> [ 'Readonly', 'Return::Set' ],
	companions	=> [ 'Sub::Abstract', 'Sub::Private', 'Sub::Protected' ],

	# The external routines the module calls
	fn_set_return	=> 'Class::Abstract::set_return',
	fn_croak	=> 'Class::Abstract::croak',

	# Expected error patterns (from the module POD)
	err_abstract	=> qr/Cannot instantiate abstract class \S+ directly/,
	msg_abstract	=> 'Cannot instantiate abstract class %s directly',

	# Schemas from the POD's API SPECIFICATION sections
	schema_string	=> { type => 'string'  },
	schema_integer	=> { type => 'integer', min => 0, max => 1 },
	schema_object	=> { type => 'object'  },

	# Concurrency: objects per class in the interleaved test
	instance_count	=> 5,
	interleave_count=> 50,

	# Sabotage timings, in seconds
	latency		=> 0.2,    # injected delay
	fast_fail	=> 1,      # a failure must surface faster than this
	hang		=> 30,     # a "hung" upstream sleeps this long ...
	watchdog	=> 1,      # ... and the caller's alarm stops it after this
	test_guard	=> 10,     # hard limit so a broken test cannot hang the suite
	sabotage_error	=> "upstream timeout\n",
	watchdog_error	=> "watchdog fired\n",
);

# Malformed values a broken upstream might hand back instead of the
# validated return value
Readonly::Array my @MALFORMED => (
	undef,
	{},
	[],
	'{"broken": ',
	"\0garbage\x7f",
	sub { 'not a string' },
);

Readonly::Scalar my $CLASS_ABSTRACT	=> 'Class::Abstract';
Readonly::Scalar my $TRUE		=> 1;
Readonly::Scalar my $FALSE		=> 0;
Readonly::Scalar my $EXIT_OK		=> 0;

# ---------------------------------------------------------------------------
# Fixture class hierarchies
# ---------------------------------------------------------------------------

# ---- IT::Vehicle hierarchy -- uses the 'use Class::Abstract' import form ----

{
	package IT::Vehicle;
	use Class::Abstract;    # import() adds Class::Abstract to @IT::Vehicle::ISA
}

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

{
	package IT::Animal;
	use parent -norequire, 'Class::Abstract';
}

# IT::Mammal is ALSO abstract: it opts in itself (POD: "Only the class that
# asks is abstract")
{
	package IT::Mammal;
	use parent -norequire, 'Class::Abstract', 'IT::Animal';
}

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

# IT::Bird does not call SUPER::new, so it must call check_abstract()
{
	package IT::Bird;
	use parent -norequire, 'Class::Abstract';

	sub new {
		my ($class, %args) = @_;
		Class::Abstract::check_abstract($class);
		return bless { call_sound => $args{call} // 'tweet' }, $class;
	}
}

{
	package IT::Sparrow;
	our @ISA = ('IT::Bird');
	sub call { 'chirp' }
}

{
	package IT::Eagle;
	our @ISA = ('IT::Bird');
	sub call { 'screech' }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Disable both bypass paths so enforcement fires inside a harness
sub enforcement_on (&) {    ## no critic (ProhibitSubroutinePrototypes) -- block syntax
	my ($code) = @_;
	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;
	return $code->();
}

# Run a block with a hard time limit, so a test that hangs fails instead of
# stalling the whole suite.  Returns the elapsed time in seconds.
sub within_time_limit (&) {    ## no critic (ProhibitSubroutinePrototypes) -- block syntax
	my ($code) = @_;
	local $SIG{ALRM} = sub { die "test exceeded its time limit\n" };
	my $start = time;
	alarm($config{test_guard});
	my $ok = eval { $code->(); 1 };
	my $error = $@;
	alarm(0);
	die $error unless $ok;
	return time - $start;
}

# --- Child processes ------------------------------------------------------
#
# Test::Without::Module only affects modules that are not loaded yet, and
# the companion modules work at compile time, so each environment needs a
# fresh perl.  run_child() writes a script, runs it with this process's
# @INC (as absolute paths, so the child's working directory does not
# matter), and parses its "key=value" output lines.

my $WORKDIR   = tempdir(CLEANUP => 1);
my @CHILD_INC = map { File::Spec->rel2abs($_) } grep { !ref } @INC;
my $child_seq = 0;

sub run_child {
	my (%opt) = @_;
	my @hidden = @{ $opt{hidden} || [] };

	my $script = File::Spec->catfile($WORKDIR, 'child' . $child_seq++ . '.pl');
	open(my $out, '>', $script) or die "Cannot write $script: $!";
	print {$out} "BEGIN { open(STDERR, '>&', \\*STDOUT) or die }\n";    # one stream
	print {$out} "use Test::Without::Module qw(@hidden);\n" if @hidden;
	print {$out} $opt{body};
	close $out;

	# The child plays a real program, not a test: the companion modules
	# still default to switching their checks off under HARNESS_ACTIVE.
	my %env = (HARNESS_ACTIVE => '', %{ $opt{env} || {} });
	local @ENV{ keys %env } = values %env;
	open(my $fh, '-|', $^X, (map { "-I$_" } @CHILD_INC), $script)
		or die "Cannot run $^X: $!";
	my $output = do { local $/; <$fh> };
	close $fh;
	my $status = $? >> 8;

	my %result = map { /^(\w+)=(.*)$/ ? ($1 => $2) : () } split /\n/, $output;

	diag "child (hidden: @hidden) exit $status:\n$output" if $ENV{TEST_VERBOSE};

	return { status => $status, output => $output, result => \%result };
}

# The companion workflow run in a child.  Each companion is loaded only if
# it is available, and applied to the same small hierarchy, so the core
# Class::Abstract results can be compared across every combination.
Readonly::Scalar my $COMPANION_BODY => <<'END_CHILD';
use strict;
use warnings;
use Class::Abstract ();

my %have;
BEGIN {
	foreach my $m (qw(Sub::Abstract Sub::Private Sub::Protected)) {
		$have{$m} = eval "require $m; 1" ? 1 : 0;
	}
}

package CO::Animal;
BEGIN { our @ISA = ('Class::Abstract') }
BEGIN { Sub::Abstract->import('speak') if $have{'Sub::Abstract'} }
BEGIN { Sub::Private->import({ mode => 'enforce' }, '_hidden') if $have{'Sub::Private'} }
BEGIN { Sub::Protected->import('_family') if $have{'Sub::Protected'} }
sub _hidden    { 'hidden' }
sub _family    { 'family' }
sub use_hidden { $_[0]->_hidden }

package CO::Dog;
our @ISA = ('CO::Animal');
sub speak      { 'Woof' }
sub use_family { $_[0]->_family }

package CO::Cat;
our @ISA = ('CO::Animal');

package main;
$Class::Abstract::config{harness_bypass} = 0;
$Class::Abstract::BYPASS = 0;

my %r;
$r{loaded}       = join ',', grep { $have{$_} } sort keys %have;
$r{abstract_new} = eval { CO::Animal->new; 1 } ? 'built'
	: ($@ =~ /^Cannot instantiate abstract class CO::Animal directly at /) ? 'croak' : 'other';
my $dog          = CO::Dog->new;
$r{concrete_new} = ref $dog;
$r{is_abstract}  = CO::Animal->is_abstract . CO::Dog->is_abstract;
$r{speak}        = $dog->speak;
$r{missing}      = eval { CO::Cat->new->speak; 1 } ? 'ran'
	: ($@ =~ /abstract method/) ? 'croak'
	: ($@ =~ /Can't locate object method/) ? 'nomethod' : 'other';
$r{private_in}   = $dog->use_hidden;
$r{private_out}  = eval { $dog->_hidden; 1 } ? 'ran' : 'croak';
$r{protected_in} = $dog->use_family;
$r{protected_out}= eval { $dog->_family; 1 } ? 'ran' : 'croak';
print "$_=$r{$_}\n" foreach sort keys %r;
END_CHILD

# A copy of a package's @ISA, looked up by name at run time
sub isa_of {
	my ($pkg) = @_;
	no strict 'refs';    ## no critic (ProhibitNoStrict) -- symbolic lookup is the point
	return [ @{"${pkg}::ISA"} ];
}

# True if a module can be found in @INC, without loading it (loading a
# companion here would run its import-time code in this process)
sub module_installed {
	my ($module) = @_;
	(my $file = "$module.pm") =~ s{::}{/}g;
	return grep({ -f File::Spec->catfile($_, $file) } @CHILD_INC) ? 1 : 0;
}

# All subsets of a list (the empty set included)
sub all_subsets {
	my @items = @_;
	my @subsets;
	foreach my $mask (0 .. (1 << @items) - 1) {
		push @subsets, [ map { $items[$_] } grep { $mask & (1 << $_) } 0 .. $#items ];
	}
	return @subsets;
}

diag 'Class::Abstract integration tests' if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION 1: Module loading and public API surface
# ===========================================================================

# Purpose: the module loads and exposes its documented API.
# require_ok, not use_ok: use_ok would call import() in package main and
# make main abstract, which is the pitfall the POD warns about.
subtest 'module loading -- require_ok and public API surface' => sub {
	plan tests => 7;

	require_ok($CLASS_ABSTRACT);
	ok( defined($Class::Abstract::VERSION), '$VERSION is defined' );
	like( $Class::Abstract::VERSION, qr/\A\d+\.\d+/, '$VERSION looks like a version string' );

	ok( Class::Abstract->can('import'),         'Class::Abstract->can("import")' );
	ok( Class::Abstract->can('new'),            'Class::Abstract->can("new")' );
	ok( Class::Abstract->can('check_abstract'), 'Class::Abstract->can("check_abstract")' );
	ok( Class::Abstract->can('is_abstract'),    'Class::Abstract->can("is_abstract")' );
};

# ===========================================================================
# SECTION 2: Vehicle hierarchy -- end-to-end import-form workflow
# ===========================================================================

# Purpose: 'use Class::Abstract' makes Vehicle abstract; its children work
subtest 'Vehicle hierarchy -- import form enforces abstract contract' => sub {
	plan tests => 4;

	enforcement_on {
		throws_ok { IT::Vehicle->new() } $config{err_abstract}, 'IT::Vehicle->new() croaks';
		lives_ok  { IT::Car->new() }   'IT::Car->new() lives';
		lives_ok  { IT::Truck->new() } 'IT::Truck->new() lives';
	};
	ok( grep({ $_ eq $CLASS_ABSTRACT } @IT::Vehicle::ISA), 'import form added Class::Abstract to @IT::Vehicle::ISA' );
};

# Purpose: objects carry the right class and their own data
subtest 'Vehicle hierarchy -- objects are correctly blessed and populated' => sub {
	plan tests => 6;

	my $car   = new_ok($config{pkg_car},   [ make => 'Toyota', model => 'Yaris' ]);
	my $truck = new_ok($config{pkg_truck}, [ payload_kg => 5000 ]);

	diag "car->make = $car->{make}, truck->payload = $truck->{payload_kg}" if $ENV{TEST_VERBOSE};

	is( ref($car),   $config{pkg_car},   'car is blessed into IT::Car' );
	is( ref($truck), $config{pkg_truck}, 'truck is blessed into IT::Truck' );
	is( $car->{make},         'Toyota', 'car make attribute set' );
	is( $truck->{payload_kg}, 5000,     'truck payload_kg attribute set' );
};

# ===========================================================================
# SECTION 3: Animal / Mammal hierarchy -- multi-level abstract classes
# ===========================================================================

# Purpose: both abstract levels croak; concrete leaves build
subtest 'Animal/Mammal hierarchy -- both abstract levels enforced' => sub {
	plan tests => 4;

	enforcement_on {
		throws_ok { IT::Animal->new() } qr/Cannot instantiate abstract class IT::Animal directly/, 'IT::Animal croaks';
		throws_ok { IT::Mammal->new() } qr/Cannot instantiate abstract class IT::Mammal directly/, 'IT::Mammal croaks';
		lives_ok  { IT::Dog->new(name => 'Rex') }      'IT::Dog lives';
		lives_ok  { IT::Cat->new(name => 'Whiskers') } 'IT::Cat lives';
	};
};

# Purpose: is_abstract() is right at every level
subtest 'Animal/Mammal hierarchy -- is_abstract() across all levels' => sub {
	plan tests => 6;

	is( Class::Abstract->is_abstract(), $TRUE,  'Class::Abstract = 1' );
	is( IT::Animal->is_abstract(),      $TRUE,  'IT::Animal = 1' );
	is( IT::Mammal->is_abstract(),      $TRUE,  'IT::Mammal = 1 (opts in itself)' );
	is( IT::Dog->is_abstract(),         $FALSE, 'IT::Dog = 0' );
	is( IT::Cat->is_abstract(),         $FALSE, 'IT::Cat = 0' );
	returns_ok( IT::Cat->is_abstract(), $config{schema_integer}, 'result is an integer 0 or 1' );
};

# Purpose: attributes survive the whole SUPER::new chain
subtest 'Animal/Mammal hierarchy -- SUPER::new chain populates attributes' => sub {
	plan tests => 4;

	my $dog = new_ok($config{pkg_dog}, [ name => 'Buddy', breed => 'Labrador' ]);
	returns_ok( $dog, $config{schema_object}, 'new() returns an object' );
	is( $dog->{name},  'Buddy',    'name populated after the SUPER chain' );
	is( $dog->{breed}, 'Labrador', 'breed populated after the SUPER chain' );
};

# ===========================================================================
# SECTION 4: Bird hierarchy -- custom new() with check_abstract()
# ===========================================================================

# Purpose: check_abstract() is the only guard in Bird::new, and it works
subtest 'Bird hierarchy -- check_abstract() guards a custom new()' => sub {
	plan tests => 4;

	enforcement_on {
		throws_ok { IT::Bird->new() } qr/Cannot instantiate abstract class IT::Bird directly/,
			'IT::Bird->new() croaks via check_abstract()';
		my $sparrow;
		lives_ok { $sparrow = IT::Sparrow->new(call => 'chirp') } 'IT::Sparrow->new() lives';
		is( ref($sparrow), $config{pkg_sparrow}, 'sparrow is blessed into IT::Sparrow' );
		is( $sparrow->{call_sound}, 'chirp', 'Bird::new set its attribute after the check' );
	};
};

# ===========================================================================
# SECTION 5: Concurrency -- many independent objects at once
#
# Each new() call must give a completely separate object.  Objects of the
# same class, of different classes and of different hierarchies must not
# share state, and changing the bypass for one batch must not affect the
# others.
# ===========================================================================

# Purpose: several objects of two classes, all distinct
subtest 'concurrency -- multiple instances are independent blessed objects' => sub {
	plan tests => 3 + 2 * $config{instance_count};

	my @dogs = map { IT::Dog->new(name => "Dog$_") } 1 .. $config{instance_count};
	my @cars = map { IT::Car->new(make => "Make$_") } 1 .. $config{instance_count};

	ok( blessed($dogs[$_]), "dog[$_] is a blessed reference" ) for 0 .. $#dogs;
	isnt( refaddr($dogs[0]), refaddr($dogs[-1]), 'first and last Dog are distinct' );
	ok( blessed($cars[$_]), "car[$_] is a blessed reference" ) for 0 .. $#cars;
	isnt( refaddr($cars[0]), refaddr($cars[-1]), 'first and last Car are distinct' );
	isnt( refaddr($dogs[0]), refaddr($cars[0]),  'a Dog and a Car are different objects' );
};

# Purpose: changing one object never changes another
subtest 'concurrency -- instance state is isolated between objects' => sub {
	plan tests => 4;

	my $dog1 = IT::Dog->new(name => 'Rex');
	my $dog2 = IT::Dog->new(name => 'Fido');

	diag "dog1: $dog1->{name}, dog2: $dog2->{name}" if $ENV{TEST_VERBOSE};

	isnt( $dog1->{name}, $dog2->{name}, 'two Dogs start with different names' );
	$dog1->{name} = 'Max';
	is( $dog1->{name}, 'Max',  'dog1 updated' );
	is( $dog2->{name}, 'Fido', 'dog2 unchanged' );
	ok( blessed(IT::Car->new(make => 'Ford')), 'a Car coexists with the Dogs' );
};

# Purpose: objects from three hierarchies, created in an interleaved order,
# are all distinct, correctly classed and carry only their own data.
subtest 'concurrency -- interleaved creation across three hierarchies' => sub {
	plan tests => 4;

	my @objects;
	enforcement_on {
		foreach my $i (1 .. $config{interleave_count}) {
			push @objects,
				IT::Dog->new(name => "dog$i"),
				IT::Car->new(make => "car$i"),
				IT::Sparrow->new(call => "call$i");
		}
	};

	my %addresses = map { refaddr($_) => 1 } @objects;
	is( scalar keys %addresses, scalar @objects, 'every object has its own address' );

	my @wrong_class = grep {
		my $i = int($_ / 3) + 1;
		my $o = $objects[$_];
		!(($_ % 3 == 0 && ref($o) eq $config{pkg_dog}     && $o->{name}       eq "dog$i")
		|| ($_ % 3 == 1 && ref($o) eq $config{pkg_car}     && $o->{make}       eq "car$i")
		|| ($_ % 3 == 2 && ref($o) eq $config{pkg_sparrow} && $o->{call_sound} eq "call$i"));
	} 0 .. $#objects;
	is( scalar @wrong_class, 0, 'every object has the right class and only its own data' );

	my @abstract = grep { $_->is_abstract } @objects;
	is( scalar @abstract, 0, 'none of them reports itself abstract' );

	$objects[0]{name} = 'changed';
	is( $objects[3]{name}, 'dog2', 'changing one Dog leaves the next Dog alone' );
};

# Purpose: a bypass used for one batch of objects does not leak into the
# next batch or change the objects already made
subtest 'concurrency -- a scoped bypass affects only its own block' => sub {
	plan tests => 5;

	enforcement_on {
		my $before = IT::Dog->new(name => 'before');
		my $abstract_obj = do {
			local $Class::Abstract::BYPASS = 1;
			IT::Animal->new();
		};
		my $after = IT::Dog->new(name => 'after');

		is( ref($abstract_obj), $config{pkg_animal}, 'abstract object made inside the bypass block' );
		throws_ok { IT::Animal->new() } $config{err_abstract}, 'outside the block the check is back on';
		is( $before->is_abstract, $FALSE, 'the earlier object is unaffected' );
		is( $after->{name}, 'after', 'the later object is normal' );
		is( IT::Animal->is_abstract, $TRUE, 'the class is still abstract' );
	};
};

# ===========================================================================
# SECTION 6: UNIVERSAL::isa integration
# ===========================================================================

# Purpose: isa() and is_abstract() answer different questions
# (POD: COMMON PITFALLS, "isa() is not the same as is_abstract()")
subtest 'UNIVERSAL::isa vs is_abstract() -- different answers for concrete classes' => sub {
	plan tests => 8;

	ok( IT::Animal->isa($CLASS_ABSTRACT), 'IT::Animal isa Class::Abstract' );
	ok( IT::Mammal->isa($CLASS_ABSTRACT), 'IT::Mammal isa Class::Abstract' );
	ok( IT::Dog->isa($CLASS_ABSTRACT),    'IT::Dog isa Class::Abstract (grandparent)' );
	is( IT::Dog->is_abstract(), $FALSE,   'but IT::Dog is not abstract' );

	my $dog = IT::Dog->new();
	ok( $dog->isa($CLASS_ABSTRACT), '$dog isa Class::Abstract' );
	is( $dog->is_abstract(), $FALSE, '$dog->is_abstract() = 0' );

	is( Class::Abstract->is_abstract($config{pkg_dog}),    $FALSE, 'explicit target IT::Dog = 0' );
	is( Class::Abstract->is_abstract($config{pkg_mammal}), $TRUE,  'explicit target IT::Mammal = 1' );
};

# ===========================================================================
# SECTION 7: Bypass integration
# ===========================================================================

# Purpose: $BYPASS reaches every entry point, including check_abstract()
subtest 'bypass integration -- $BYPASS suppresses enforcement everywhere' => sub {
	plan tests => 3;

	local $Class::Abstract::BYPASS                 = $TRUE;
	local $Class::Abstract::config{harness_bypass} = $FALSE;
	local $ENV{HARNESS_ACTIVE}                     = $FALSE;

	lives_ok { IT::Animal->new() } '$BYPASS: IT::Animal->new() lives';
	lives_ok { IT::Mammal->new() } '$BYPASS: IT::Mammal->new() lives';
	lives_ok { IT::Bird->new() }   '$BYPASS: IT::Bird->new() lives (via check_abstract)';
};

# Purpose: harness_bypass works only together with HARNESS_ACTIVE, and by
# default (since 0.03) the check is on inside a harness
subtest 'bypass integration -- harness_bypass and the 0.03 default' => sub {
	plan tests => 3;

	local $Class::Abstract::BYPASS = $FALSE;
	{
		local $Class::Abstract::config{harness_bypass} = $TRUE;
		local $ENV{HARNESS_ACTIVE}                     = $TRUE;
		lives_ok { IT::Vehicle->new() } 'harness_bypass + HARNESS_ACTIVE: IT::Vehicle->new() lives';
		lives_ok { IT::Animal->new() }  'harness_bypass + HARNESS_ACTIVE: IT::Animal->new() lives';
	}
	{
		local $ENV{HARNESS_ACTIVE} = $TRUE;
		throws_ok { IT::Vehicle->new() } $config{err_abstract}, 'default settings: the check is on in a harness';
	}
};

# Purpose: outside a harness, with harness_bypass on, the check still runs
subtest 'end-to-end: enforcement outside a harness' => sub {
	plan tests => 3;

	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 1;
	local $ENV{HARNESS_ACTIVE}                     = '';

	throws_ok { IT::Vehicle->new() } qr/Cannot instantiate abstract class IT::Vehicle directly/, 'IT::Vehicle blocked';
	lives_ok  { IT::Car->new() } 'IT::Car allowed';
	lives_ok  { IT::Dog->new() } 'IT::Dog (two levels below abstract) allowed';
};

# Purpose: an object made during a bypass cannot be used to make another
# once the check is back (POD: COMMON PITFALLS)
subtest 'end-to-end: object of an abstract class as new() invocant croaks' => sub {
	plan tests => 2;

	my $abstract_obj = do { local $Class::Abstract::BYPASS = 1; IT::Vehicle->new() };
	is( ref($abstract_obj), $config{pkg_vehicle}, 'precondition: abstract object made under bypass' );
	enforcement_on {
		throws_ok { $abstract_obj->new() } qr/Cannot instantiate abstract class IT::Vehicle directly/,
			'$abstract_obj->new croaks';
	};
};

# ===========================================================================
# SECTION 8: Calls to external routines (spies, no behaviour change)
# ===========================================================================

# Purpose: import() hands its result to Return::Set with the documented schema
subtest 'Return::Set integration -- import() delivers a typed return via set_return()' => sub {
	plan tests => 4;

	my $spy = spy $config{fn_set_return};
	my $ret;
	{ package IT::ImportSpyTarget; our @ISA = (); $ret = Class::Abstract->import() }
	restore_all();

	my @calls = $spy->();

	diag 'set_return calls: ' . scalar(@calls) if $ENV{TEST_VERBOSE};

	is( scalar @calls, 1, 'set_return() called once' );
	is( $calls[0][1], $CLASS_ABSTRACT, 'value passed = "Class::Abstract"' );
	is_deeply( $calls[0][2], $config{schema_string}, 'schema passed = { type => "string" }' );
	returns_ok( $ret, $config{schema_string}, 'import() returns a string' );
};

# Purpose: a class that says "use Class::Abstract" twice (for example from
# two source files that both build up the same package) is registered
# once, and still behaves as one abstract class
subtest 'import() workflow -- repeated import registers the class once' => sub {
	plan tests => 4;

	my @returns;
	## no critic (ProhibitStringyEval) -- "use" must compile at run time
	eval q{
		package IT::TwiceImported;
		use Class::Abstract;
		BEGIN { push @returns, Class::Abstract->import() }
		1;
	} or die $@;
	## use critic

	is_deeply( \@IT::TwiceImported::ISA, [$CLASS_ABSTRACT], '@ISA holds Class::Abstract exactly once' );
	is( $returns[0], $CLASS_ABSTRACT, 'second import() still returns the class name' );
	is( IT::TwiceImported->is_abstract, $TRUE, 'class is abstract' );
	enforcement_on {
		throws_ok { IT::TwiceImported->new } $config{err_abstract}, 'and enforced';
	};
};

# Purpose: loading a class at run time (a plugin loader, say) inside an
# error handler must not wipe the error being handled.  Return::Set
# clears $@, so import() has to put it back.
subtest 'import() workflow -- $@ survives a run-time class load' => sub {
	plan tests => 2;

	my $handled = "error being handled\n";
	eval { die $handled };
	{ package IT::LateLoadedDirect; our @ISA = (); Class::Abstract->import() }
	is( $@, $handled, '$@ unchanged after import()' );
	is( IT::LateLoadedDirect->is_abstract, $TRUE, 'and the class was registered' );
};

# Purpose: errors go through Carp::croak with exactly the documented text,
# whichever hierarchy and entry point raised them
subtest 'Carp integration -- errors are raised through croak() with the documented text' => sub {
	plan tests => 3;

	my $spy = spy $config{fn_croak};
	enforcement_on {
		eval { IT::Vehicle->new() };
		eval { IT::Mammal->new() };
		eval { IT::Bird->new() };
	};
	restore_all();

	my @messages = map { $_->[1] } $spy->();
	is_deeply( \@messages,
		[ map { sprintf($config{msg_abstract}, $_) } $config{pkg_vehicle}, $config{pkg_mammal}, $config{pkg_bird} ],
		'one croak per failure, each with the exact documented message' );

	# Without the spy, the message points at this file (the caller)
	enforcement_on {
		throws_ok { IT::Vehicle->new() } qr/ at \Q$0\E line \d+\.\n\z/, 'error location is the caller';
	};
	unlike( $@, qr{Class/Abstract\.pm}, 'error does not point inside the module' );
};

# ===========================================================================
# SECTION 9: Cross-hierarchy interaction
# ===========================================================================

# Purpose: objects from all three hierarchies coexist in one scope
subtest 'cross-hierarchy -- Dog, Car, and Sparrow in the same scope' => sub {
	plan tests => 6;

	my $dog = IT::Dog->new(name => 'Buster');
	my $car = IT::Car->new(make => 'Honda', model => 'Civic');
	my $sparrow;
	enforcement_on {
		lives_ok { $sparrow = IT::Sparrow->new(call => 'tweet') } 'IT::Sparrow->new() lives';
	};

	ok( blessed($dog),     'dog is blessed' );
	ok( blessed($car),     'car is blessed' );
	ok( blessed($sparrow), 'sparrow is blessed' );
	is( $dog->is_abstract(),     $FALSE, '$dog->is_abstract() = 0' );
	is( $sparrow->is_abstract(), $FALSE, '$sparrow->is_abstract() = 0' );
};

# Purpose: Class::Abstract->is_abstract('Name') answers for any hierarchy
subtest 'cross-hierarchy -- explicit-target is_abstract() for every class' => sub {
	my %expect = (
		$config{pkg_vehicle} => $TRUE,  $config{pkg_car}     => $FALSE,
		$config{pkg_animal}  => $TRUE,  $config{pkg_dog}     => $FALSE,
		$config{pkg_bird}    => $TRUE,  $config{pkg_sparrow} => $FALSE,
	);
	plan tests => scalar keys %expect;

	foreach my $class (sort keys %expect) {
		is( Class::Abstract->is_abstract($class), $expect{$class}, "$class = $expect{$class}" );
	}
};

# ===========================================================================
# SECTION 10: Companion modules, present and absent in every combination
#
# Class::Abstract has no optional dependencies of its own, but the POD
# recommends using it with Sub::Abstract, Sub::Private and Sub::Protected.
# For every combination of those being installed or not (2^3 = 8), the
# core Class::Abstract behaviour must be identical, each companion's own
# behaviour must appear exactly when it is installed, and nothing may die.
# ===========================================================================

subtest 'companions -- every combination of present and absent' => sub {
	my @companions = @{ $config{companions} };

	# Companions are not prerequisites, so expect only those installed here
	my %installed = map { $_ => module_installed($_) } @companions;
	diag 'installed companions: ' . join(', ', grep { $installed{$_} } @companions) if $ENV{TEST_VERBOSE};
	my @subsets    = all_subsets(@companions);
	plan tests => scalar @subsets;

	foreach my $hidden (@subsets) {
		my %is_hidden = map { $_ => 1 } @{$hidden};
		my %present   = map { $_ => ($installed{$_} && !$is_hidden{$_}) } @companions;
		my @present   = grep { $present{$_} } @companions;
		my $label     = @{$hidden} ? 'without ' . join(', ', @{$hidden}) : 'with all companions';

		subtest $label => sub {
			plan tests => 11;

			my $run = run_child(hidden => $hidden, body => $COMPANION_BODY);
			my $r   = $run->{result};

			is( $run->{status}, $EXIT_OK, 'child exits cleanly' );
			is( $r->{loaded}, join(',', sort @present), 'exactly the expected companions loaded' );

			# Core Class::Abstract behaviour never changes
			is( $r->{abstract_new}, 'croak',   'abstract class croaks with the documented message' );
			is( $r->{concrete_new}, 'CO::Dog', 'concrete class builds' );
			is( $r->{is_abstract},  '10',      'is_abstract: Animal 1, Dog 0' );
			is( $r->{speak},        'Woof',    'implemented method works' );
			is( $r->{private_in},   'hidden',  'private method callable from its own class' );
			is( $r->{protected_in}, 'family',  'protected method callable from a subclass' );

			# Each companion's own guarantee appears exactly when it is loaded
			is( $r->{missing},
				$present{'Sub::Abstract'} ? 'croak' : 'nomethod',
				'missing method: Sub::Abstract croak only when loaded' );
			is( $r->{private_out},
				$present{'Sub::Private'} ? 'croak' : 'ran',
				'outside call to private method: blocked only when Sub::Private loaded' );
			is( $r->{protected_out},
				$present{'Sub::Protected'} ? 'croak' : 'ran',
				'outside call to protected method: blocked only when Sub::Protected loaded' );
		};
	}
};

# ===========================================================================
# SECTION 11: Required dependencies missing
#
# Readonly and Return::Set are required (POD: DEPENDENCIES).  Without
# either one, loading must fail at once, at "use" time, naming the missing
# module -- not succeed and break later at some unrelated call.
# ===========================================================================

subtest 'required dependencies -- missing module fails at load time, clearly' => sub {
	my @deps = @{ $config{required_deps} };
	plan tests => 3 * scalar @deps;

	foreach my $dep (@deps) {
		(my $file = "$dep.pm") =~ s{::}{/}g;
		my $run = run_child(
			hidden => [$dep],
			body   => "use Class::Abstract ();\nprint qq{loaded=1\\n};\n",
		);
		isnt( $run->{status}, $EXIT_OK, "without $dep: the program stops" );
		like( $run->{output}, qr/Can't locate \Q$file\E/, "without $dep: the error names $file" );
		ok( !exists $run->{result}{loaded}, "without $dep: no code after 'use' ran" );
	}
};

# ===========================================================================
# SECTION 12: Filesystem permissions taken away
#
# The module reads and writes no files, so a locked-down filesystem must
# not affect it.  Each case runs the full companion workflow in a child
# whose working directory, temporary directory or home directory has had
# a permission removed.  Test::Permissions restores the mode afterwards;
# cases are skipped where the OS (or running as root) cannot revoke.
# ===========================================================================

# Expected core results of the companion workflow with everything present
sub workflow_intact {
	my ($run, $label) = @_;
	my $r = $run->{result};
	is( $run->{status}, $EXIT_OK, "$label: child exits cleanly" );
	is( join('|', @{$r}{qw(abstract_new concrete_new is_abstract)}), 'croak|CO::Dog|10',
		"$label: enforcement and construction unaffected" );
	return;
}

subtest 'permissions -- no write access to cwd or TMPDIR' => sub {
	plan tests => 2;

	my $dir = tempdir(DIR => $WORKDIR);
	diag permissions_report($dir) if $ENV{TEST_VERBOSE};

	SKIP: {
		skip why_not('create', $dir), 2 unless can_revoke_create($dir);

		my $home = getcwd();
		chdir $dir or die "Cannot chdir to $dir: $!";
		my $run;
		my $ok = eval {
			with_revoked(create => $dir, sub {
				$run = run_child(body => $COMPANION_BODY, env => { TMPDIR => $dir, TMP => $dir, TEMP => $dir });
			});
			1;
		};
		chdir $home or die "Cannot chdir back to $home: $!";
		die $@ unless $ok;

		workflow_intact($run, 'read-only cwd and TMPDIR');
	}
};

subtest 'permissions -- no search access to cwd or HOME' => sub {
	plan tests => 2;

	my $dir = tempdir(DIR => $WORKDIR);

	SKIP: {
		skip why_not('search', $dir), 2 unless can_revoke_search($dir);

		my $home = getcwd();
		chdir $dir or die "Cannot chdir to $dir: $!";
		my $run;
		my $ok = eval {
			with_revoked(search => $dir, sub {
				$run = run_child(body => $COMPANION_BODY, env => { HOME => $dir });
			});
			1;
		};
		chdir $home or die "Cannot chdir back to $home: $!";
		die $@ unless $ok;

		workflow_intact($run, 'unsearchable cwd and HOME');
	}
};

# ===========================================================================
# SECTION 13: Subsystem sabotage -- Return::Set misbehaving
#
# set_return() is the only outside code the module calls at run time
# (from import()).  Each case makes it slow, fail, hang or return junk,
# then checks three things:
#   - the failure reaches the caller quickly and plainly
#   - the class being registered is left in a consistent state
#   - nothing else is affected: new(), check_abstract() and is_abstract()
#     on other hierarchies work as before, and import() works again once
#     the upstream recovers (no cascading failure)
# ===========================================================================

# Shared "nothing else broke" checks; $pkg is the class import() was
# registering when the sabotage happened
sub no_cascade {
	my ($pkg, $label) = @_;
	is_deeply( isa_of($pkg), [$CLASS_ABSTRACT], "$label: $pkg registered exactly once" );
	enforcement_on {
		throws_ok { Class::Abstract::new($pkg) } $config{err_abstract}, "$label: $pkg is enforced as abstract";
		lives_ok  { IT::Dog->new() } "$label: other hierarchies still build";
	};
	my $ret;
	{
		my $fresh = "${pkg}::Recovered";
		eval "package $fresh; our \@ISA = (); \$ret = Class::Abstract->import(); 1" or die $@;    ## no critic (ProhibitStringyEval) -- package name built at run time
	}
	is( $ret, $CLASS_ABSTRACT, "$label: import() works again after recovery" );
	return;
}

# Purpose: a slow upstream slows only import(); results are still right,
# and routines that do not call it are not slowed down
subtest 'sabotage -- latency in set_return' => sub {
	plan tests => 7;

	around $config{fn_set_return} => sub {
		my ($orig, @args) = @_;
		sleep($config{latency});
		return $orig->(@args);
	};

	my $ret;
	my $elapsed = within_time_limit { package IT::Slow; our @ISA = (); $ret = Class::Abstract->import() };
	my $new_elapsed = within_time_limit { IT::Dog->new() for 1 .. $config{instance_count} };
	restore_all();

	diag sprintf('import %.3fs, new() x %d %.3fs', $elapsed, $config{instance_count}, $new_elapsed)
		if $ENV{TEST_VERBOSE};

	is( $ret, $CLASS_ABSTRACT, 'import() still returns the class name' );
	cmp_ok( $elapsed, '>=', $config{latency}, 'import() waited for the slow upstream' );
	cmp_ok( $new_elapsed, '<', $config{latency}, 'new() does not wait on Return::Set' );
	no_cascade('IT::Slow', 'latency');
};

# Purpose: an upstream error (e.g. a timeout) surfaces at once, unchanged
subtest 'sabotage -- set_return reports a timeout error' => sub {
	plan tests => 6;

	my $elapsed;
	{
		my $guard = mock_scoped $config{fn_set_return} => sub { die $config{sabotage_error} };
		$elapsed = within_time_limit {
			throws_ok { package IT::Failing; our @ISA = (); Class::Abstract->import() }
				qr/\A\Q$config{sabotage_error}\E\z/, 'the upstream error reaches the caller unchanged';
		};
	}
	cmp_ok( $elapsed, '<', $config{fast_fail}, 'failure surfaced quickly (no retry, no wait)' );
	no_cascade('IT::Failing', 'timeout');
};

# Purpose: a hung upstream can be stopped by the caller's own alarm; the
# module does not block signals or leave half-finished state behind
subtest 'sabotage -- hung set_return is stopped by the caller watchdog' => sub {
	plan tests => 7;

	my ($elapsed, $error);
	{
		my $guard = mock_scoped $config{fn_set_return} => sub { sleep($config{hang}); return $_[0] };
		$elapsed = within_time_limit {
			local $SIG{ALRM} = sub { die $config{watchdog_error} };
			alarm($config{watchdog});
			eval { package IT::Hung; our @ISA = (); Class::Abstract->import() };
			$error = $@;
			alarm(0);
		};
	}

	diag sprintf('watchdog stopped import after %.3fs', $elapsed) if $ENV{TEST_VERBOSE};

	is( $error, $config{watchdog_error}, 'the watchdog interrupted import()' );
	cmp_ok( $elapsed, '<', $config{hang}, 'did not wait for the hung upstream' );
	cmp_ok( $elapsed, '<', $config{watchdog} + $config{fast_fail}, 'stopped promptly after the alarm' );
	no_cascade('IT::Hung', 'hang');
};

# Purpose: junk from upstream must not crash import() or corrupt the
# class registration
subtest 'sabotage -- malformed values from set_return' => sub {
	plan tests => 2 * scalar @MALFORMED;

	foreach my $i (0 .. $#MALFORMED) {
		my $junk = $MALFORMED[$i];
		my $pkg  = "IT::Malformed$i";
		my $guard = mock_scoped $config{fn_set_return} => sub { $junk };

		lives_ok { eval "package $pkg; our \@ISA = (); Class::Abstract->import(); 1" or die $@ }    ## no critic (ProhibitStringyEval)
			"malformed value #$i does not crash import()";
		undef $guard;

		is_deeply( isa_of($pkg), [$CLASS_ABSTRACT], "malformed value #$i: registration intact" );
	}
};

# Purpose: after all the sabotage, the original workflows still behave
subtest 'sabotage -- full workflow is healthy afterwards' => sub {
	plan tests => 4;

	enforcement_on {
		throws_ok { IT::Vehicle->new() } $config{err_abstract}, 'Vehicle still abstract';
		throws_ok { IT::Bird->new() }    $config{err_abstract}, 'Bird still abstract';
		lives_ok  { IT::Car->new(); IT::Sparrow->new() } 'concrete classes still build';
	};
	is_deeply( diagnose_mocks(), {}, 'no mocks left installed' );
};

done_testing;
