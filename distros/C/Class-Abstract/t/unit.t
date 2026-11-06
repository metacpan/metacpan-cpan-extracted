#!/usr/bin/perl
# t/unit.t -- black-box unit tests for the public API of Class::Abstract.
#
# Every subtest checks one documented behaviour of one public routine
# (import, new, check_abstract, is_abstract) or public variable ($BYPASS,
# %config) against the module's POD.  The tests use only the public API;
# the one external function the module calls (Return::Set::set_return) is
# spied on or mocked to reach its success and failure paths.
#
# API ledger: the documented error messages are read from the POD's
# ERROR MESSAGES table at run time, and the documented return states are
# listed below.  Each subtest crosses off what it proves.  The last test
# fails if anything documented was never triggered, so a message added to
# the POD without a test makes this file fail.

use strict;
use warnings;

use Errno        qw(ENOENT);
use Readonly;
use Scalar::Util qw(blessed);
use Test::Most;
use Test::Mockingbird;
use Test::Returns;

# Empty import list: a bare "use Class::Abstract;" would make package main
# abstract (see POD: COMMON PITFALLS).  Carp would then trust main and
# print backtraces instead of the short messages checked below.
use Class::Abstract ();

# ---------------------------------------------------------------------------
# Configuration -- all constants and strings live here; no magic values
# ---------------------------------------------------------------------------

my %config = (
	# Package names used as test fixtures
	pkg_abstract	=> 'UT::Abstract',
	pkg_concrete	=> 'UT::Concrete',
	pkg_import_a	=> 'UT::ImportA',
	pkg_import_b	=> 'UT::ImportB',
	pkg_import_err	=> 'UT::ImportErr',
	pkg_import_sr	=> 'UT::ImportSetReturnDies',
	pkg_global	=> 'UT::Global',
	pkg_never	=> 'UT::Never::Defined',
	pkg_zero	=> '0',

	# The module under test; its POD is read from the copy actually loaded
	pkg_module	=> 'Class::Abstract',
	module_file	=> $INC{'Class/Abstract.pm'},

	# The external function the module calls
	fn_set_return	=> 'Class::Abstract::set_return',

	# Placeholders the POD uses in its ERROR MESSAGES table
	pod_placeholder	=> qr/\b(?:CLASS|TYPE|KEY)\b/,

	# Global-state sentinels
	sentinel	=> 'sentinel_do_not_change',
	sentinel_error	=> "earlier error the caller has not read yet\n",
	alarm_seconds	=> 100,
	alarm_slack	=> 2,    # seconds the clock may move during a test

	# Injected by mocks that simulate a failing dependency
	boom		=> 'simulated set_return failure',

	# Test::Returns schemas, as documented under API SPECIFICATION
	schema_string	=> { type => 'string' },
	schema_integer	=> { type => 'integer', min => 0, max => 1 },
	schema_object	=> { type => 'object' },
);

Readonly::Scalar my $CLASS_ABSTRACT	=> 'Class::Abstract';
Readonly::Scalar my $TRUE		=> 1;
Readonly::Scalar my $FALSE		=> 0;
Readonly::Scalar my $NONE		=> 0;
Readonly::Scalar my $ONCE		=> 1;

# ---------------------------------------------------------------------------
# The API ledger
# ---------------------------------------------------------------------------

# Read the ERROR MESSAGES table from the POD.  Each row starts at a 4-space
# indent; a wrapped message continues at a 6-space indent; anything indented
# further is the wrapped "Comes from" column.  Placeholders become %s.
sub documented_messages {
	my ($file) = @_;
	open(my $fh, '<', $file) or BAIL_OUT("Cannot read $file: $!");
	my $pod = do { local $/; <$fh> };
	close $fh;

	my ($table) = $pod =~ /^=head1 ERROR MESSAGES\n(.*?)^=head1 /ms
		or BAIL_OUT("No ERROR MESSAGES section in $file");

	my @rows;
	foreach my $line (split /\n/, $table) {
		if ($line =~ /^ {4}(\S.*?)(?: {2,}\S.*)?$/) {
			my $text = $1;
			next if $text =~ /^(?:Message|-+)$/;    # header rows
			push @rows, $text;
		} elsif (@rows && $line =~ /^ {6}(\S.*?)(?: {2,}\S.*)?$/) {
			$rows[-1] .= " $1";
		}
	}
	s/$config{pod_placeholder}/%s/g for @rows;
	return @rows;
}

my %ledger = map { ("message: $_" => 1) } documented_messages($config{module_file});

# Documented return states (POD: RETURNS of each routine), documented side
# effects that a caller can observe, and documented settings.
$ledger{$_} = 1 foreach (
	'return: import gives the string Class::Abstract',
	'return: new gives a new empty object of the class',
	'return: check_abstract gives undef in scalar context',
	'return: check_abstract gives an empty list in list context',
	'return: is_abstract gives 1',
	'return: is_abstract gives 0',
	'effect: import adds Class::Abstract to the caller @ISA',
	'effect: import is a no-op when already registered',
	'effect: import is a no-op for Class::Abstract itself',
	'effect: import is a no-op when the caller is unknown',
	'effect: is_abstract does not create unknown packages',
	'effect: errors report the caller file and line',
	'setting: $BYPASS true turns the check off',
	'setting: harness_bypass and HARNESS_ACTIVE turn the check off',
	'setting: $BYPASS wins over harness_bypass = 0',
	'setting: defaults leave the check on inside a harness',
	'globals: $_ $@ $! and alarm survive every routine',
);

# Documented messages that the public API cannot produce on purpose.  Each
# entry says why; the ledger test checks that every entry really is in the
# POD, so a stale entry is caught too.
Readonly::Hash my %UNREACHABLE => (
	'message: Class::Abstract internal error: unknown message key %s'
		=> 'raised only if the module itself has a bug (see t/function.t)',
);

# Cross an item off the ledger
sub covered {
	my ($item) = @_;
	diag "ledger: covered '$item'" if $ENV{TEST_VERBOSE} && exists $ledger{$item};
	delete $ledger{$item};
	return;
}

# Expect $code to croak with exactly the documented message, reported at
# this test file (not inside the module).  Crosses the message off.
sub croaks_with {
	my ($code, $template, $args, $name) = @_;
	my $message = sprintf($template, @{$args});
	my $ok = throws_ok { $code->() } qr/\A\Q$message\E at \Q$0\E line \d+\.\n\z/, $name;
	if ($ok) {
		covered("message: $template");
		covered('effect: errors report the caller file and line');
	}
	return $ok;
}

# Disable both bypass paths so enforcement fires inside a harness
sub enforcement_on (&) {
	my ($code) = @_;
	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;
	return $code->();
}

# Run $code with $_, $@, $! and an alarm set to known values, then report
# which of them changed.  $code must not croak: an eval would reset $@.
sub globals_after (&) {
	my ($code) = @_;
	local $SIG{ALRM} = sub { die "alarm fired during test\n" };
	local $_ = $config{sentinel};
	local $@ = $config{sentinel_error};
	local $! = ENOENT;
	alarm($config{alarm_seconds});

	$code->();

	my %after = (
		underscore => $_,
		error      => $@,
		errno      => 0 + $!,
	);
	$after{alarm_left} = alarm(0);
	return \%after;
}

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

diag 'Class::Abstract unit tests -- one subtest per documented behaviour'
	if $ENV{TEST_VERBOSE};
diag 'ledger starts with ' . scalar(keys %ledger) . ' items' if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION: the ledger itself
# ===========================================================================

# Purpose: prove the POD parser found the messages.  If the POD layout
# changes and the parser silently finds nothing, every later check would
# pass vacuously.
subtest 'ledger -- POD ERROR MESSAGES table was parsed' => sub {
	plan tests => 3;

	my @messages = grep { /^message: / } keys %ledger;
	ok( scalar @messages > $ONCE, 'more than one message found in the POD' );
	ok( exists $ledger{'message: Cannot instantiate abstract class %s directly'},
		'the core "abstract" message was found' );
	ok( exists $ledger{'message: new() invocant must be a class name or blessed object, got %s'},
		'wrapped table rows are joined correctly' );

	diag explain [sort @messages] if $ENV{TEST_VERBOSE};
};

# Purpose: every message excluded as unreachable must be in the POD; then
# drop it from the ledger
subtest 'ledger -- unreachable messages are documented, then excluded' => sub {
	plan tests => scalar keys %UNREACHABLE;

	foreach my $item (sort keys %UNREACHABLE) {
		ok( exists $ledger{$item}, "unreachable item is in the POD: $UNREACHABLE{$item}" );
		delete $ledger{$item};
	}
};

# ===========================================================================
# SECTION: import()
#
# POD: adds 'Class::Abstract' to the caller's @ISA; does nothing if it is
# already there, if the caller is Class::Abstract, or if the caller is
# unknown; returns the string 'Class::Abstract'; ignores an import list.
# ===========================================================================

# Purpose: the first import registers the caller exactly once
subtest 'import() -- adds Class::Abstract to the caller @ISA' => sub {
	plan tests => 3;

	{ package UT::ImportA; our @ISA = () }
	ok( !grep({ $_ eq $CLASS_ABSTRACT } @UT::ImportA::ISA), 'precondition: not yet registered' );

	# The "package" line makes caller() inside import() return UT::ImportA
	{ package UT::ImportA; Class::Abstract->import() }

	diag '@UT::ImportA::ISA = (' . join(', ', @UT::ImportA::ISA) . ')' if $ENV{TEST_VERBOSE};

	is_deeply( \@UT::ImportA::ISA, [$CLASS_ABSTRACT], 'Class::Abstract added once' );
	is( UT::ImportA->is_abstract(), $TRUE, 'the caller is now abstract' );
	covered('effect: import adds Class::Abstract to the caller @ISA');
};

# Purpose: importing again changes nothing
subtest 'import() -- no-op when the caller is already registered' => sub {
	plan tests => 1;

	{ package UT::ImportA; Class::Abstract->import() }
	is_deeply( \@UT::ImportA::ISA, [$CLASS_ABSTRACT], 'still exactly one entry' );
	covered('effect: import is a no-op when already registered');
};

# Purpose: Class::Abstract cannot become its own parent
subtest 'import() -- no-op when the caller is Class::Abstract itself' => sub {
	plan tests => 1;

	my @before = @Class::Abstract::ISA;
	{ package Class::Abstract; Class::Abstract->import() }
	is_deeply( \@Class::Abstract::ISA, \@before, '@Class::Abstract::ISA unchanged' );
	covered('effect: import is a no-op for Class::Abstract itself');
};

# Purpose: when Perl cannot name the caller, nothing is registered -- in
# particular @main::ISA, which an empty name would mean.
# Strategy: override CORE::GLOBAL::caller so import() sees ''.
subtest 'import() -- no-op when the caller is unknown' => sub {
	plan tests => 2;

	my @before = @main::ISA;
	my $ret;
	{
		no warnings 'redefine';
		local *CORE::GLOBAL::caller = sub { return wantarray ? ('', '', 0) : '' };
		$ret = Class::Abstract->import();
	}
	is_deeply( \@main::ISA, \@before, '@main::ISA unchanged' );
	is( $ret, $CLASS_ABSTRACT, 'still returns the class name' );
	covered('effect: import is a no-op when the caller is unknown');
};

# Purpose: the documented return value, validated through set_return
subtest 'import() -- returns the string "Class::Abstract" via set_return' => sub {
	plan tests => 4;

	my $spy = spy $config{fn_set_return};
	my $ret;
	{ package UT::ImportB; our @ISA = (); $ret = Class::Abstract->import() }
	restore_all();

	diag "import() returned: '$ret'" if $ENV{TEST_VERBOSE};

	is( $ret, $CLASS_ABSTRACT, 'import() returns "Class::Abstract"' );
	returns_ok( $ret, $config{schema_string}, 'return satisfies the documented { type => "string" }' );
	my @calls = $spy->();
	is( scalar @calls, $ONCE, 'set_return called once' );
	is_deeply( $calls[0][2], $config{schema_string}, 'set_return given the documented schema' );
	covered('return: import gives the string Class::Abstract');
};

# Purpose: an import list is ignored (POD: ARGUMENTS)
subtest 'import() -- import list is ignored' => sub {
	plan tests => 2;

	{ package UT::ImportList; our @ISA = () }
	my $ret;
	{ package UT::ImportList; $ret = Class::Abstract->import(qw(x y), [], undef) }
	is( $ret, $CLASS_ABSTRACT, 'same return value' );
	is_deeply( \@UT::ImportList::ISA, [$CLASS_ABSTRACT], 'same single registration' );
};

# Purpose: import() never dies itself (POD: MESSAGES "None"), but a
# failure in set_return must still reach the caller, not be swallowed.
subtest 'import() -- a failing set_return propagates' => sub {
	plan tests => 1;

	{ package UT::ImportSetReturnDies; our @ISA = () }
	my $guard = mock_scoped $config{fn_set_return} => sub { die "$config{boom}\n" };
	throws_ok { package UT::ImportSetReturnDies; Class::Abstract->import() }
		qr/\A\Q$config{boom}\E\n\z/, 'set_return failure reaches the caller';
};

# ===========================================================================
# SECTION: new()
#
# POD: returns a new, empty hashref blessed into the class; dies for an
# abstract class unless a bypass is on; accepts a class name or object;
# rejects undef, '' and unblessed references; ignores extra arguments.
# ===========================================================================

# Purpose: a concrete class gives an empty object of exactly that class
subtest 'new() -- concrete class: new, empty object of that class' => sub {
	plan tests => 5;

	my $obj = enforcement_on { UT::Concrete->new() };

	diag 'new() returned: ' . explain($obj) if $ENV{TEST_VERBOSE};

	returns_ok( $obj, $config{schema_object}, 'returns an object' );
	is( ref($obj), $config{pkg_concrete}, 'blessed into UT::Concrete, not a base class' );
	is_deeply( {%{$obj}}, {}, 'the object is an empty hash' );

	my $other = enforcement_on { UT::Concrete->new() };
	ok( $obj != $other, 'each call gives a new object' );

	my $with_args = Class::Abstract::new($config{pkg_concrete}, name => 'Rex', 1 .. 4);
	is_deeply( {%{$with_args}}, {}, 'extra arguments are ignored' );
	covered('return: new gives a new empty object of the class');
};

# Purpose: an object can be the invocant; its class is used
subtest 'new() -- object invocant: new object of the same class' => sub {
	plan tests => 2;

	my $existing = UT::Concrete->new();
	my $copy     = enforcement_on { $existing->new() };
	is( ref($copy), $config{pkg_concrete}, 'same class as the invocant object' );
	ok( $copy != $existing, 'a different object, not the invocant' );
};

# Purpose: the documented error for an abstract class, exact text
subtest 'new() -- abstract class: exact error' => sub {
	plan tests => 2;

	croaks_with( sub { enforcement_on { UT::Abstract->new() } },
		'Cannot instantiate abstract class %s directly', [$config{pkg_abstract}],
		'UT::Abstract->new croaks with the documented message' );

	croaks_with( sub { enforcement_on { Class::Abstract->new() } },
		'Cannot instantiate abstract class %s directly', [$CLASS_ABSTRACT],
		'Class::Abstract itself is abstract' );
};

# Purpose: an object of an abstract class (made during a bypass) cannot be
# used to make another one once the check is back on (POD: COMMON PITFALLS)
subtest 'new() -- object of an abstract class as invocant still croaks' => sub {
	plan tests => 1;

	my $abstract_obj = do { local $Class::Abstract::BYPASS = 1; UT::Abstract->new() };
	croaks_with( sub { enforcement_on { $abstract_obj->new() } },
		'Cannot instantiate abstract class %s directly', [$config{pkg_abstract}],
		'$abstract_obj->new croaks' );
};

# Purpose: every documented invocant error, exact text
subtest 'new() -- bad invocants: exact errors' => sub {
	my %bad = (
		ARRAY  => [],
		HASH   => {},
		CODE   => sub { 1 },
		SCALAR => \my $scalar,
	);
	plan tests => scalar(keys %bad) + 2;

	foreach my $type (sort keys %bad) {
		croaks_with( sub { Class::Abstract::new($bad{$type}) },
			'new() invocant must be a class name or blessed object, got %s', [$type],
			"unblessed $type rejected" );
	}
	croaks_with( sub { Class::Abstract::new(undef) },
		'new() requires a defined class name as invocant', [], 'undef rejected' );
	croaks_with( sub { Class::Abstract::new('') },
		'new() requires a defined class name as invocant', [], 'empty string rejected' );
};

# Purpose: the class name "0" is false but valid
subtest 'new() -- class named "0" is accepted' => sub {
	plan tests => 1;

	is( ref(Class::Abstract::new($config{pkg_zero})), $config{pkg_zero}, 'object blessed into "0"' );
};

# ===========================================================================
# SECTION: check_abstract()
#
# POD: same check as new() without making an object; returns nothing
# (undef in scalar context, empty list in list context); same errors.
# ===========================================================================

# Purpose: success returns nothing, in both contexts
subtest 'check_abstract() -- concrete class: returns nothing' => sub {
	plan tests => 4;

	my $scalar = enforcement_on { scalar Class::Abstract::check_abstract($config{pkg_concrete}) };
	my @list   = enforcement_on { Class::Abstract::check_abstract($config{pkg_concrete}) };

	ok( !defined $scalar, 'scalar context: undef' );
	covered('return: check_abstract gives undef in scalar context');
	is( scalar @list, $NONE, 'list context: empty list' );
	covered('return: check_abstract gives an empty list in list context');

	my $obj = UT::Concrete->new();
	lives_ok { enforcement_on { Class::Abstract::check_abstract($obj) } } 'an object of a concrete class passes';
	my $obj_result = enforcement_on { scalar Class::Abstract::check_abstract($obj) };
	ok( !defined $obj_result, 'and returns undef too' );
};

# Purpose: every documented error, exact text
subtest 'check_abstract() -- abstract class and bad arguments: exact errors' => sub {
	plan tests => 5;

	croaks_with( sub { enforcement_on { Class::Abstract::check_abstract($config{pkg_abstract}) } },
		'Cannot instantiate abstract class %s directly', [$config{pkg_abstract}],
		'abstract class rejected' );
	croaks_with( sub { Class::Abstract::check_abstract([]) },
		'check_abstract() requires a class name or blessed object, got %s', ['ARRAY'],
		'unblessed array ref rejected' );
	croaks_with( sub { Class::Abstract::check_abstract(sub { 1 }) },
		'check_abstract() requires a class name or blessed object, got %s', ['CODE'],
		'unblessed code ref rejected' );
	croaks_with( sub { Class::Abstract::check_abstract(undef) },
		'check_abstract() requires a defined class name', [], 'undef rejected' );
	croaks_with( sub { Class::Abstract::check_abstract('') },
		'check_abstract() requires a defined class name', [], 'empty string rejected' );
};

# Purpose: the POD's own example -- an abstract class with its own new()
subtest 'check_abstract() -- POD example: abstract class with its own new()' => sub {
	plan tests => 3;

	{
		package UT::Shape;
		our @ISA = ('Class::Abstract');
		sub new {
			my ($class, %args) = @_;
			Class::Abstract::check_abstract($class);
			return bless { sides => $args{sides} }, $class;
		}
		package UT::Square;
		our @ISA = ('UT::Shape');
	}

	my $square = enforcement_on { UT::Square->new(sides => 4) };
	is( ref($square), 'UT::Square', 'concrete child builds' );
	is( $square->{sides}, 4, 'and keeps its own data' );
	croaks_with( sub { enforcement_on { UT::Shape->new(sides => 4) } },
		'Cannot instantiate abstract class %s directly', ['UT::Shape'],
		'the abstract class itself croaks' );
};

# ===========================================================================
# SECTION: is_abstract()
#
# POD: 1 if the class is directly abstract (or is Class::Abstract), else 0;
# the class is the invocant, or the target when the target is defined;
# objects are checked by their class; unknown names give 0 and are not
# created; undef/'' and unblessed references are errors.
# ===========================================================================

# Purpose: both documented return values, as exact integers
subtest 'is_abstract() -- returns exactly 1 or 0' => sub {
	plan tests => 6;

	my $yes = UT::Abstract->is_abstract();
	my $no  = UT::Concrete->is_abstract();

	diag "is_abstract: UT::Abstract=$yes UT::Concrete=$no" if $ENV{TEST_VERBOSE};

	is( $yes, $TRUE, 'directly abstract class gives 1' );
	returns_ok( $yes, $config{schema_integer}, '1 is an integer 0..1' );
	covered('return: is_abstract gives 1');

	is( $no, $FALSE, 'child of an abstract class gives 0' );
	returns_ok( $no, $config{schema_integer}, '0 is an integer 0..1' );
	covered('return: is_abstract gives 0');

	is( Class::Abstract->is_abstract(), $TRUE, 'Class::Abstract itself gives 1' );
	is( UT::Concrete->new()->is_abstract(), $FALSE, 'object form checks the object class' );
};

# Purpose: the explicit-target forms from the POD's EXAMPLE
subtest 'is_abstract() -- explicit target: name or object' => sub {
	plan tests => 5;

	my $abstract_obj = do { local $Class::Abstract::BYPASS = 1; UT::Abstract->new() };
	my $concrete_obj = UT::Concrete->new();

	is( Class::Abstract->is_abstract($config{pkg_abstract}), $TRUE,  'target name: abstract' );
	is( Class::Abstract->is_abstract($config{pkg_concrete}), $FALSE, 'target name: concrete' );
	is( Class::Abstract->is_abstract($abstract_obj), $TRUE,  'target object: abstract class' );
	is( Class::Abstract->is_abstract($concrete_obj), $FALSE, 'target object: concrete class' );
	is( UT::Abstract->is_abstract($config{pkg_zero}), $FALSE, 'target "0" is used, not ignored as false' );
};

# Purpose: "undef target" means "no target" (POD: ARGUMENTS)
subtest 'is_abstract() -- undef target falls back to the invocant' => sub {
	plan tests => 1;

	is( UT::Abstract->is_abstract(undef), $TRUE, 'invocant UT::Abstract checked' );
};

# Purpose: a misspelt name gives 0 and does not create the package
subtest 'is_abstract() -- unknown class: 0, and the package is not created' => sub {
	plan tests => 2;

	is( Class::Abstract->is_abstract($config{pkg_never}), $FALSE, 'unknown class gives 0' );
	ok( !exists $UT::{'Never::'}, 'package was not created' );
	covered('effect: is_abstract does not create unknown packages');
};

# Purpose: every documented error, exact text
subtest 'is_abstract() -- bad class to check: exact errors' => sub {
	plan tests => 4;

	croaks_with( sub { Class::Abstract::is_abstract([]) },
		'is_abstract() requires a class name or object invocant, got %s', ['ARRAY'],
		'unblessed invocant rejected' );
	croaks_with( sub { Class::Abstract->is_abstract({}) },
		'is_abstract() requires a class name or object invocant, got %s', ['HASH'],
		'unblessed target rejected' );
	croaks_with( sub { Class::Abstract::is_abstract(undef) },
		'is_abstract() requires a class name or object invocant', [], 'undef rejected' );
	croaks_with( sub { UT::Abstract->is_abstract('') },
		'is_abstract() requires a class name or object invocant', [],
		'empty target rejected (not treated as "no target")' );
};

# ===========================================================================
# SECTION: public variables ($BYPASS, %config)
# ===========================================================================

# Purpose: documented defaults (POD: PUBLIC VARIABLES), and that with the
# defaults the check is on even inside a test harness
subtest 'settings -- defaults leave the check on inside a harness' => sub {
	plan tests => 3;

	is( $Class::Abstract::BYPASS, $FALSE, '$BYPASS defaults to 0' );
	is( $Class::Abstract::config{harness_bypass}, $FALSE, 'harness_bypass defaults to 0' );

	local $ENV{HARNESS_ACTIVE} = 1;
	croaks_with( sub { UT::Abstract->new() },
		'Cannot instantiate abstract class %s directly', [$config{pkg_abstract}],
		'abstract class croaks under a harness with default settings' );
	covered('setting: defaults leave the check on inside a harness');
};

# Purpose: $BYPASS turns the check off, for any value Perl calls true,
# including strings that look false to a person (POD: PUBLIC VARIABLES)
subtest 'settings -- $BYPASS true turns the check off' => sub {
	my @true_values = (1, 'false', 'no', '0E0');
	plan tests => scalar(@true_values) + 1;

	local $Class::Abstract::config{harness_bypass} = 0;
	foreach my $value (@true_values) {
		local $Class::Abstract::BYPASS = $value;
		lives_ok { UT::Abstract->new() } "BYPASS='$value': abstract class allowed";
	}
	local $Class::Abstract::BYPASS = 1;
	lives_ok { Class::Abstract::check_abstract($config{pkg_abstract}) } 'check_abstract obeys it too';
	covered('setting: $BYPASS true turns the check off');
};

# Purpose: harness_bypass needs HARNESS_ACTIVE as well
subtest 'settings -- harness_bypass works only together with HARNESS_ACTIVE' => sub {
	plan tests => 3;

	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 1;
	{
		local $ENV{HARNESS_ACTIVE} = 1;
		lives_ok { UT::Abstract->new() } 'harness_bypass + HARNESS_ACTIVE: allowed';
		lives_ok { Class::Abstract::check_abstract($config{pkg_abstract}) } 'check_abstract obeys it too';
	}
	{
		local $ENV{HARNESS_ACTIVE} = '';
		croaks_with( sub { UT::Abstract->new() },
			'Cannot instantiate abstract class %s directly', [$config{pkg_abstract}],
			'harness_bypass without HARNESS_ACTIVE: still croaks' );
	}
	covered('setting: harness_bypass and HARNESS_ACTIVE turn the check off');
};

# Purpose: $BYPASS wins; harness_bypass = 0 does not switch the check back on
subtest 'settings -- $BYPASS wins over harness_bypass = 0' => sub {
	plan tests => 1;

	local $Class::Abstract::BYPASS                 = 1;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 1;
	lives_ok { UT::Abstract->new() } 'still allowed';
	covered('setting: $BYPASS wins over harness_bypass = 0');
};

# Purpose: "local" restores the previous setting (POD: PUBLIC VARIABLES)
subtest 'settings -- local $BYPASS ends with its block' => sub {
	plan tests => 2;

	enforcement_on {
		{
			local $Class::Abstract::BYPASS = 1;
			lives_ok { UT::Abstract->new() } 'inside the block: allowed';
		}
		croaks_with( sub { UT::Abstract->new() },
			'Cannot instantiate abstract class %s directly', [$config{pkg_abstract}],
			'after the block: croaks again' );
	};
};

# ===========================================================================
# SECTION: global state integrity
#
# POD (SIDE EFFECTS): no routine changes $_, $@ or $!, or touches an
# alarm() timer.  $@ matters most: a caller may still be holding an error
# from an earlier eval.
# ===========================================================================

# Purpose: success paths leave every global exactly as it was
subtest 'globals -- success paths leave $_, $@, $! and alarm() alone' => sub {
	my %calls = (
		import         => sub { package UT::Global; Class::Abstract->import() },
		new            => sub { enforcement_on { UT::Concrete->new() } },
		check_abstract => sub { enforcement_on { Class::Abstract::check_abstract($config{pkg_concrete}) } },
		is_abstract    => sub { UT::Abstract->is_abstract() },
	);
	plan tests => 4 * scalar keys %calls;

	foreach my $name (sort keys %calls) {
		my $after = globals_after { $calls{$name}->() };

		diag "$name: " . explain($after) if $ENV{TEST_VERBOSE};

		is( $after->{underscore}, $config{sentinel},       "$name: \$_ unchanged" );
		is( $after->{error},      $config{sentinel_error}, "$name: \$\@ unchanged" );
		is( $after->{errno},      ENOENT,                  "$name: \$! unchanged" );
		cmp_ok( $after->{alarm_left}, '>=', $config{alarm_seconds} - $config{alarm_slack},
			"$name: alarm() timer still running" );
	}
	covered('globals: $_ $@ $! and alarm survive every routine');
};

# Purpose: error paths leave $_, $! and alarm() alone too ($@ is, by
# design, where the error goes)
subtest 'globals -- error paths leave $_, $! and alarm() alone' => sub {
	my %calls = (
		new            => sub { enforcement_on { UT::Abstract->new() } },
		check_abstract => sub { Class::Abstract::check_abstract(undef) },
		is_abstract    => sub { Class::Abstract::is_abstract([]) },
	);
	plan tests => 4 * scalar keys %calls;

	foreach my $name (sort keys %calls) {
		my $died;
		my $after = globals_after { $died = !eval { $calls{$name}->(); 1 } };
		ok( $died, "$name: the call did croak" );
		is( $after->{underscore}, $config{sentinel}, "$name: \$_ unchanged" );
		is( $after->{errno},      ENOENT,            "$name: \$! unchanged" );
		cmp_ok( $after->{alarm_left}, '>=', $config{alarm_seconds} - $config{alarm_slack},
			"$name: alarm() timer still running" );
	}
};

# ===========================================================================
# The ledger must now be empty
# ===========================================================================

# Purpose: everything documented was triggered by some subtest above
subtest 'ledger -- every documented message and state was tested' => sub {
	plan tests => 1;

	my @left = sort keys %ledger;
	if (@left) {
		fail( 'untested POD conditions remain' );
		diag "not tested: $_" foreach @left;
	} else {
		pass( 'ledger is empty' );
	}
};

done_testing();
