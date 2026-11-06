#!/usr/bin/perl
# t/function.t -- white-box tests for every function in Class::Abstract.
#
# Unlike t/unit.t (black-box), these tests look inside each function:
#   - which internal helpers each function calls, with which arguments,
#     and in which order (spies)
#   - how each function reacts when a helper returns something unexpected
#     or dies part-way through (mocks)
#   - exact error strings, and that errors point at the caller's line
#   - that $_ and other globals are never written
#   - that nothing the module returns or keeps holds a memory cycle or
#     keeps an argument alive after the call
#
# The strategy is "test to fail": most subtests try to break, bypass or
# corrupt a function with hostile input or a failing dependency.

use strict;
use warnings;

use Readonly;
use Scalar::Util     qw(blessed weaken);
use Test::Most;
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Returns;

# Load with an empty import list.  A bare "use Class::Abstract;" would make
# package main abstract (see POD: COMMON PITFALLS), and Carp would then
# treat main as trusted and print full backtraces instead of short
# "at FILE line N." messages, which the exact-message tests rely on.
use Class::Abstract ();

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
	pkg_import_boom	=> 'FT::ImportBoom',
	pkg_import_sr	=> 'FT::ImportSetReturnDies',
	pkg_import_list	=> 'FT::ImportList',
	pkg_wide_isa	=> 'FT::WideISA',
	pkg_scalar_isa	=> 'FT::ScalarISA',
	pkg_odd_stash	=> 'FT::OddStash',
	pkg_never	=> 'FT::Never::Created',
	pkg_zero	=> '0',
	pkg_overload	=> 'FT::Overloaded',
	pkg_module	=> 'Class::Abstract',
	pkg_regexp	=> 'Regexp',

	# Fully-qualified helper names, for spies and mocks
	fn_fail		=> 'Class::Abstract::_fail',
	fn_resolve	=> 'Class::Abstract::_resolve_class',
	fn_bypass	=> 'Class::Abstract::_bypass_active',
	fn_enforce	=> 'Class::Abstract::_enforce',
	fn_direct_isa	=> 'Class::Abstract::_direct_isa',
	fn_ida		=> 'Class::Abstract::_is_direct_abstract',
	fn_set_return	=> 'Class::Abstract::set_return',

	# Message-key prefixes passed to _resolve_class by each public routine
	routine_new	=> 'new',
	routine_check	=> 'check',
	routine_isabs	=> 'is_abstract',

	# Sentinel value for $_ clobber tests
	sentinel	=> 'sentinel_do_not_change',

	# Text injected by "mid-flight" failure mocks
	boom		=> 'simulated failure mid-flight',

	# Resource-exhaustion sizes: big enough to expose quadratic or
	# recursive behaviour, small enough to run in well under a second
	huge_name_len	=> 100_000,
	deep_segments	=> 2_000,
	wide_isa_len	=> 50_000,

	# Patterns (prefix-only; the exact strings are in %EXACT below)
	err_abstract	=> qr/Cannot instantiate abstract class \S+ directly/,
	err_new_unblessed	=> qr/new\(\) invocant must be a class name or blessed object, got/,
	err_new_undef		=> qr/new\(\) requires a defined class name as invocant/,
	err_chk_unblessed	=> qr/check_abstract\(\) requires a class name or blessed object, got/,
	err_chk_undef		=> qr/check_abstract\(\) requires a defined class name/,
	err_isabs_undef		=> qr/is_abstract\(\) requires a class name or object invocant/,

	# Test::Returns schemas
	schema_string	=> { type => 'string' },
	schema_integer	=> { type => 'integer', min => 0, max => 1 },
	schema_arrayref	=> { type => 'arrayref' },
	schema_object	=> { type => 'object' },
);

# The exact text of every message, keyed by the module's internal message
# key.  These strings are the public contract documented in the POD.
Readonly::Hash my %EXACT => (
	'abstract'              => 'Cannot instantiate abstract class %s directly',
	'new:unblessed'         => 'new() invocant must be a class name or blessed object, got %s',
	'new:undef'             => 'new() requires a defined class name as invocant',
	'check:unblessed'       => 'check_abstract() requires a class name or blessed object, got %s',
	'check:undef'           => 'check_abstract() requires a defined class name',
	'is_abstract:unblessed' => 'is_abstract() requires a class name or object invocant, got %s',
	'is_abstract:undef'     => 'is_abstract() requires a class name or object invocant',
	'internal:key'          => 'Class::Abstract internal error: unknown message key %s',
);

# Readonly constants -- avoid bare literals
Readonly::Scalar my $CLASS_ABSTRACT	=> 'Class::Abstract';
Readonly::Scalar my $TRUE		=> 1;
Readonly::Scalar my $FALSE		=> 0;
Readonly::Scalar my $ZERO_CALLS		=> 0;
Readonly::Scalar my $ONE_CALL		=> 1;
Readonly::Scalar my $ARG1		=> 1;	# index of the first real argument in a spy record
Readonly::Scalar my $ARG2		=> 2;	# index of the second real argument in a spy record

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

# FT::Overloaded: stringifies as an abstract class name.  The module must
# use the object's real class, not what it claims to be when stringified.
{
	package FT::Overloaded;
	use overload '""' => sub { 'FT::Abstract' }, fallback => 1;
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Disable both bypass paths so enforcement fires inside a harness
sub enforcement_on (&) {
	my ($code) = @_;
	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 0;
	return $code->();
}

# Build the exact text croak() produces for a message key: the message,
# then " at <this test file> line N.\n".  The file must be this test, not
# lib/Class/Abstract.pm -- that proves Carp reports the caller's line.
sub exact_error {
	my ($key, @args) = @_;
	my $msg = sprintf($EXACT{$key}, @args);
	return qr/\A\Q$msg\E at \Q$0\E line \d+\.\n\z/;
}

# Run a block and return every warning it emits
sub warnings_from (&) {
	my ($code) = @_;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	$code->();
	return \@warnings;
}

# Number of calls a spy has recorded
sub call_count {
	my ($spy) = @_;
	my @calls = $spy->();
	return scalar @calls;
}

diag 'Class::Abstract white-box (function-level) tests' if $ENV{TEST_VERBOSE};

# ===========================================================================
# SECTION: _fail (private helper)
#
# _fail is the only place the module croaks.  If its text or its reported
# location drifts, every error the user sees drifts with it.
# ===========================================================================

# Purpose: every message key produces exactly the documented text.
# Strategy: call _fail directly for each key with a recognisable argument.
subtest '_fail -- every message key gives the exact documented text' => sub {
	plan tests => scalar keys %EXACT;

	# Pass an argument only to messages that take one, as the module does
	foreach my $key (sort keys %EXACT) {
		my @args = ($EXACT{$key} =~ /%s/) ? ('ARG') : ();
		throws_ok { Class::Abstract::_fail($key, @args) }
			exact_error($key, @args),
			"_fail('$key') croaks with the exact documented message";
	}
};

# Purpose: a mistyped key must still produce a useful message.  A Readonly
# hash returns undef for a missing key, which would otherwise croak ''.
subtest '_fail -- unknown message key names the key instead of an empty message' => sub {
	plan tests => 1;

	throws_ok { Class::Abstract::_fail('no_such_key') }
		exact_error('internal:key', 'no_such_key'),
		'_fail with an unknown key reports the bad key';
};

# Purpose: hostile class names must not be treated as sprintf formats.
# Strategy: pass printf directives as the argument and expect them verbatim.
subtest '_fail -- format directives in arguments are not interpreted' => sub {
	plan tests => 2;

	my $hostile = '%s%n%d%x%%';
	my $warnings = warnings_from {
		throws_ok { Class::Abstract::_fail('abstract', $hostile) }
			exact_error('abstract', $hostile),
			'printf directives in the class name appear literally';
	};
	is( scalar @{$warnings}, $ZERO_CALLS, 'no "Missing argument" or other warnings' );
};

# Purpose: _fail must never return; the code after it relies on that.
subtest '_fail -- never returns control to the caller' => sub {
	plan tests => 1;

	my $reached = $FALSE;
	eval { Class::Abstract::_fail('abstract', $config{pkg_abstract}); $reached = $TRUE };
	is( $reached, $FALSE, 'statement after _fail() is never reached' );
};

# ===========================================================================
# SECTION: _resolve_class (private helper)
#
# Every public routine funnels its invocant through here, so it is the
# module's input-validation boundary.  Hostile values are thrown at it.
# ===========================================================================

# Purpose: valid names and objects come back as the right class string,
# and _fail is not touched on the success path.
subtest '_resolve_class -- names and objects resolve; _fail not called' => sub {
	plan tests => 4;

	my $spy = spy $config{fn_fail};
	my $from_name = Class::Abstract::_resolve_class($config{routine_new}, $config{pkg_concrete});
	my $from_obj  = Class::Abstract::_resolve_class($config{routine_new}, bless({}, $config{pkg_concrete}));
	restore_all();

	is( $from_name, $config{pkg_concrete}, 'class name is returned unchanged' );
	is( $from_obj,  $config{pkg_concrete}, 'object resolves to its class' );
	returns_ok( $from_obj, $config{schema_string}, 'return value is a plain string' );
	is( call_count($spy), $ZERO_CALLS, '_fail not called on the success path' );
};

# Purpose: every kind of unblessed reference is rejected with the exact
# message of the routine that asked, for all three routines.
# Strategy: cross every reference type with every routine prefix.
subtest '_resolve_class -- every unblessed reftype is rejected, per routine' => sub {
	my $glob = \*STDOUT;
	my %refs = (
		ARRAY  => [],
		HASH   => {},
		CODE   => sub { 1 },
		SCALAR => \my $scalar,
		REF    => \\my $inner,
		GLOB   => $glob,
	);
	my @routines = ($config{routine_new}, $config{routine_check}, $config{routine_isabs});
	plan tests => scalar(keys %refs) * scalar(@routines);

	foreach my $routine (@routines) {
		foreach my $type (sort keys %refs) {
			throws_ok { Class::Abstract::_resolve_class($routine, $refs{$type}) }
				exact_error("$routine:unblessed", $type),
				"$routine: unblessed $type rejected with exact message";
		}
	}
};

# Purpose: undef and '' can never name a package ('' would mean main::).
subtest '_resolve_class -- undef and empty string rejected, per routine' => sub {
	my @routines = ($config{routine_new}, $config{routine_check}, $config{routine_isabs});
	plan tests => 2 * scalar @routines;

	foreach my $routine (@routines) {
		throws_ok { Class::Abstract::_resolve_class($routine, undef) }
			exact_error("$routine:undef"), "$routine: undef rejected with exact message";
		throws_ok { Class::Abstract::_resolve_class($routine, '') }
			exact_error("$routine:undef"), "$routine: '' rejected with exact message";
	}
};

# Purpose: _resolve_class must hand _fail the right key and arguments.
# Strategy: replace _fail with a recorder that dies (the real one never
# returns, so the replacement must not return either).
subtest '_resolve_class -- passes the correct key and arguments to _fail' => sub {
	plan tests => 4;

	my @recorded;
	my $guard = mock_scoped $config{fn_fail} => sub { push @recorded, [@_]; die "recorded\n" };

	eval { Class::Abstract::_resolve_class($config{routine_new}, []) };
	eval { Class::Abstract::_resolve_class($config{routine_check}, undef) };
	undef $guard;

	diag explain \@recorded if $ENV{TEST_VERBOSE};

	is( $recorded[0][0], 'new:unblessed', 'unblessed ref uses the "<routine>:unblessed" key' );
	is( $recorded[0][1], 'ARRAY',         'the reftype is passed as the sprintf argument' );
	is( $recorded[1][0], 'check:undef',   'undef uses the "<routine>:undef" key' );
	is( scalar @{ $recorded[1] }, $ONE_CALL, 'no stray arguments for the argument-less message' );
};

# Purpose: objects whose class name is false ('0'), or that lie about
# their name via overloading, or that are built-in (qr//) must all be
# resolved by their real class.
subtest '_resolve_class -- hostile and unusual objects use their real class' => sub {
	plan tests => 4;

	is( Class::Abstract::_resolve_class($config{routine_new}, bless({}, $config{pkg_zero})),
		$config{pkg_zero}, 'object blessed into "0" resolves to "0" (not treated as false)' );
	is( Class::Abstract::_resolve_class($config{routine_new}, bless({}, $config{pkg_overload})),
		$config{pkg_overload}, 'overloaded "" is ignored; the real class is used' );
	is( Class::Abstract::_resolve_class($config{routine_new}, qr/x/),
		$config{pkg_regexp}, 'qr// is an object of class Regexp' );
	is( Class::Abstract::_resolve_class($config{routine_new}, $config{pkg_zero}),
		$config{pkg_zero}, 'the string "0" is a valid class name' );
};

# Purpose: very long names pass through untouched (no truncation, no error)
subtest '_resolve_class -- very long class name is returned intact' => sub {
	plan tests => 1;

	my $huge = 'A' x $config{huge_name_len};
	is( length(Class::Abstract::_resolve_class($config{routine_new}, $huge)),
		$config{huge_name_len}, 'long name returned at full length' );
};

# ===========================================================================
# SECTION: _bypass_active (private helper)
# ===========================================================================

# Purpose: exact integers for every combination; $BYPASS wins
subtest '_bypass_active -- truth table returns exact integers' => sub {
	plan tests => 5;

	local $Class::Abstract::BYPASS                 = 0;
	local $Class::Abstract::config{harness_bypass} = 0;
	local $ENV{HARNESS_ACTIVE}                     = 1;
	is( Class::Abstract::_bypass_active(), $FALSE, 'no bypass when both off' );

	local $Class::Abstract::config{harness_bypass} = 1;
	is( Class::Abstract::_bypass_active(), $TRUE, 'harness bypass when harness_bypass && HARNESS_ACTIVE' );

	local $ENV{HARNESS_ACTIVE} = '';
	is( Class::Abstract::_bypass_active(), $FALSE, 'no bypass outside a harness' );

	local $Class::Abstract::BYPASS = 1;
	local $Class::Abstract::config{harness_bypass} = 0;
	is( Class::Abstract::_bypass_active(), $TRUE, '$BYPASS wins regardless of harness_bypass' );
	returns_ok( Class::Abstract::_bypass_active(), $config{schema_integer}, 'returns an integer 0 or 1' );
};

# Purpose: values that look false to a person but are true to Perl turn
# the bypass on, and the result is still normalised to exactly 1.
subtest '_bypass_active -- truthy oddities normalise to exactly 1' => sub {
	my @truthy = ('0E0', 'false', ' ', '00', [], 0.1);
	plan tests => scalar @truthy;

	local $Class::Abstract::config{harness_bypass} = 0;
	foreach my $value (@truthy) {
		local $Class::Abstract::BYPASS = $value;
		is( Class::Abstract::_bypass_active(), $TRUE, 'BYPASS=' . (ref $value || "'$value'") . ' gives exactly 1' );
	}
};

# Purpose: falsy values, including undef, give exactly 0 without warnings
subtest '_bypass_active -- falsy values give exactly 0' => sub {
	my @falsy = (0, '0', '', undef);
	plan tests => scalar @falsy;

	local $Class::Abstract::config{harness_bypass} = 0;
	foreach my $value (@falsy) {
		local $Class::Abstract::BYPASS = $value;
		is( Class::Abstract::_bypass_active(), $FALSE,
			'BYPASS=' . (defined $value ? "'$value'" : 'undef') . ' gives exactly 0' );
	}
};

# Purpose: a caller who wipes %config or unsets HARNESS_ACTIVE must not
# cause warnings or an accidental bypass.
subtest '_bypass_active -- missing config key and missing env var are safe' => sub {
	plan tests => 2;

	local $Class::Abstract::BYPASS = 0;
	local %Class::Abstract::config = ();
	local $ENV{HARNESS_ACTIVE};
	delete $ENV{HARNESS_ACTIVE};

	my $result;
	my $warnings = warnings_from { $result = Class::Abstract::_bypass_active() };
	is( $result, $FALSE, 'empty %config + no HARNESS_ACTIVE: enforcement stays on' );
	is( scalar @{$warnings}, $ZERO_CALLS, 'no "uninitialized" warnings' );
};

# ===========================================================================
# SECTION: _enforce (private helper)
# ===========================================================================

# Purpose: a concrete class passes through and comes back unchanged
subtest '_enforce -- returns the class for a concrete class' => sub {
	plan tests => 2;

	my $result = enforcement_on { Class::Abstract::_enforce($config{pkg_concrete}) };
	is( $result, $config{pkg_concrete}, '_enforce returns its argument' );
	returns_ok( $result, $config{schema_string}, 'return value is a string' );
};

# Purpose: with a bypass on, the abstract check must not even run.
# Strategy: force _bypass_active to 1 and spy on _is_direct_abstract.
subtest '_enforce -- bypass short-circuits before _is_direct_abstract' => sub {
	plan tests => 2;

	my $guard = mock_scoped $config{fn_bypass} => sub { $TRUE };
	my $spy   = spy $config{fn_ida};

	lives_ok { Class::Abstract::_enforce($config{pkg_abstract}) }
		'abstract class allowed while _bypass_active says 1';
	restore_all();
	undef $guard;

	is( call_count($spy), $ZERO_CALLS, '_is_direct_abstract never consulted under bypass' );
};

# Purpose: _bypass_active is consulted before _is_direct_abstract.  The
# order matters: the check must not run (and cannot fail) under a bypass.
subtest '_enforce -- calls _bypass_active before _is_direct_abstract' => sub {
	plan tests => 1;

	clear_call_log();
	my $spy_b = spy $config{fn_bypass};
	my $spy_i = spy $config{fn_ida};

	enforcement_on { Class::Abstract::_enforce($config{pkg_concrete}) };

	assert_call_order($config{fn_bypass}, $config{fn_ida});
	restore_all();
};

# Purpose: on an abstract class, _enforce asks _fail for the 'abstract'
# message with the class name.
subtest '_enforce -- passes "abstract" and the class to _fail' => sub {
	plan tests => 3;

	# The spy wraps _fail in Test::Mockingbird's package, so Carp reports
	# the spy's file as the location here.  Match the message only; the
	# location is checked by the exact_error() tests that use no spy.
	my $spy = spy $config{fn_fail};
	my $msg = sprintf($EXACT{abstract}, $config{pkg_abstract});
	throws_ok { enforcement_on { Class::Abstract::_enforce($config{pkg_abstract}) } }
		qr/\A\Q$msg\E at /,
		'_enforce croaks with the exact message';
	restore_all();

	my @calls = $spy->();
	is( $calls[0][$ARG1], 'abstract',             '_fail key is "abstract"' );
	is( $calls[0][$ARG2], $config{pkg_abstract},  '_fail argument is the class name' );
};

# Purpose: if the abstract check itself dies mid-flight, the error must
# reach the caller unchanged -- not be swallowed or turned into a pass.
subtest '_enforce -- failure inside _is_direct_abstract propagates' => sub {
	plan tests => 1;

	my $guard = mock_scoped $config{fn_ida} => sub { die "$config{boom}\n" };
	throws_ok { enforcement_on { Class::Abstract::_enforce($config{pkg_concrete}) } }
		qr/\A\Q$config{boom}\E\n\z/,
		'exception from _is_direct_abstract is not swallowed';
};

# ===========================================================================
# SECTION: _direct_isa (private helper)
#
# Reads a package's own @ISA by walking the symbol table, without ever
# creating a package.  Hostile names and damaged symbol tables are thrown
# at it.
# ===========================================================================

# Purpose: name resolution for nested, leading-'::', 'main::' and '' names
subtest '_direct_isa -- resolves names to the live @ISA' => sub {
	plan tests => 6;

	is_deeply( Class::Abstract::_direct_isa($config{pkg_abstract}), [$CLASS_ABSTRACT],
		'_direct_isa("FT::Abstract") is its @ISA' );
	is_deeply( Class::Abstract::_direct_isa("::$config{pkg_abstract}"), [$CLASS_ABSTRACT],
		'leading "::" is ignored' );
	is_deeply( Class::Abstract::_direct_isa("main::$config{pkg_abstract}"), [$CLASS_ABSTRACT],
		'"main::" prefix resolves to the same package' );

	# The returned ref is the live array, not a copy
	ok( \@FT::Abstract::ISA == Class::Abstract::_direct_isa($config{pkg_abstract}),
		'returns a reference to the live @ISA' );

	{
		local @main::ISA = ('Some::Base');
		is_deeply( Class::Abstract::_direct_isa(''), ['Some::Base'], '"" resolves to @main::ISA' );
	}

	returns_ok( Class::Abstract::_direct_isa($config{pkg_abstract}),
		$config{schema_arrayref}, 'return value is an arrayref' );
};

# Purpose: asking about a package that does not exist must not create it,
# and the empty result must be a fresh array each time, so a caller that
# changes it cannot affect later answers.
subtest '_direct_isa -- unknown package: [], not created, fresh each call' => sub {
	plan tests => 4;

	my $first = Class::Abstract::_direct_isa($config{pkg_never});
	is_deeply( $first, [], 'unknown package gives []' );
	ok( !exists $FT::{'Never::'}, 'unknown package stash was not created' );

	push @{$first}, $CLASS_ABSTRACT;
	my $second = Class::Abstract::_direct_isa($config{pkg_never});
	is_deeply( $second, [], 'changing one result does not leak into the next' );
	ok( $first != $second, 'each call returns a new empty array' );
};

# Purpose: a symbol table can hold non-glob values (Perl stores some
# constants that way, and hostile code can put anything there).  The walk
# must step over them, not die dereferencing them.
subtest '_direct_isa -- non-glob symbol-table entries are skipped safely' => sub {
	plan tests => 4;

	# A package segment whose stash entry is a plain scalar ref
	{
		no strict 'refs';
		${"FT::"}{'Junk::'} = \'not a glob';
	}
	my $result;
	lives_ok { $result = Class::Abstract::_direct_isa('FT::Junk::Deeper') }
		'non-glob package segment does not die';
	is_deeply( $result, [], 'non-glob package segment gives []' );

	# A real package whose ISA slot is a plain scalar ref
	{
		package FT::OddStash;
		our $marker = 1;
	}
	{
		no strict 'refs';
		${"FT::OddStash::"}{ISA} = \'not a glob either';
	}
	lives_ok { $result = Class::Abstract::_direct_isa($config{pkg_odd_stash}) }
		'non-glob ISA slot does not die';
	is_deeply( $result, [], 'non-glob ISA slot gives []' );
};

# Purpose: a package with a scalar $ISA but no array @ISA has no parents
subtest '_direct_isa -- glob with no ARRAY slot gives []' => sub {
	plan tests => 1;

	{
		no strict 'refs';
		no warnings 'once';
		${"FT::ScalarISA::ISA"} = $CLASS_ABSTRACT;
	}
	is_deeply( Class::Abstract::_direct_isa($config{pkg_scalar_isa}), [],
		'$ISA scalar is ignored; only @ISA counts' );
};

# Purpose: hostile names must be looked up, never evaluated or created.
subtest '_direct_isa -- hostile names are inert' => sub {
	my @hostile = (
		'::::',                         # only separators (means main::)
		'FT::::Abstract',               # doubled separator
		"FT::Nul\0Byte",                # embedded NUL
		'FT::Evil; system("false")',    # code-like text
		'FT::%s%n',                     # printf directives
		'   ',                          # whitespace only
	);
	plan tests => 2 * scalar @hostile;

	foreach my $name (@hostile) {
		my $result;
		lives_ok { $result = Class::Abstract::_direct_isa($name) } 'lookup lives for hostile name';
		ok( ref($result) eq 'ARRAY', 'and returns an arrayref' );
	}
};

# Purpose: resource exhaustion -- a huge name and a very deep name must be
# handled quickly and must not create anything.
subtest '_direct_isa -- huge and deeply nested names' => sub {
	plan tests => 4;

	my $huge = 'FT::' . ('B' x $config{huge_name_len});
	my $deep = join '::', 'FT', ('Seg') x $config{deep_segments};

	is_deeply( Class::Abstract::_direct_isa($huge), [], 'huge name gives []' );
	is_deeply( Class::Abstract::_direct_isa($deep), [], 'deep name gives []' );
	ok( !exists $FT::{'Seg::'}, 'deep lookup created no stash' );
	ok( !grep({ length($_) > $config{deep_segments} } keys %FT::), 'huge lookup created no stash' );
};

# ===========================================================================
# SECTION: _is_direct_abstract (private helper)
#
# The core predicate.  It inspects only the IMMEDIATE @ISA of a class --
# never the full MRO -- and must always return exactly 1 or 0.
# ===========================================================================

# Purpose: exact integer results for every kind of class
subtest '_is_direct_abstract -- exact 1/0 for every kind of class' => sub {
	my %expect = (
		$CLASS_ABSTRACT          => $TRUE,    # special-cased
		$config{pkg_abstract}    => $TRUE,    # direct entry
		$config{pkg_concrete}    => $FALSE,   # one hop away
		$config{pkg_transitive}  => $FALSE,   # two hops away
		$config{pkg_plain}       => $FALSE,   # unrelated parent
		$config{pkg_no_isa}      => $FALSE,   # empty @ISA
		$config{pkg_never}       => $FALSE,   # no such package
	);
	plan tests => 2 * scalar(keys %expect) + 2;

	foreach my $class (sort keys %expect) {
		my $result = Class::Abstract::_is_direct_abstract($class);
		is( $result, $expect{$class}, "_is_direct_abstract('$class') = $expect{$class}" );
		returns_ok( $result, $config{schema_integer}, "'$class' result is an integer 0 or 1" );
	}

	# undef must give 0, not undef, and not croak
	my $result;
	lives_ok { $result = Class::Abstract::_is_direct_abstract(undef) } 'undef does not croak';
	is( $result, $FALSE, '_is_direct_abstract(undef) = 0 (defined)' );
};

# Purpose: the cheap short-circuits (undef, Class::Abstract) must not walk
# the symbol table; everything else must ask _direct_isa for the class.
subtest '_is_direct_abstract -- _direct_isa called only when needed' => sub {
	plan tests => 3;

	my $spy = spy $config{fn_direct_isa};
	Class::Abstract::_is_direct_abstract(undef);
	Class::Abstract::_is_direct_abstract($CLASS_ABSTRACT);
	is( call_count($spy), $ZERO_CALLS, 'no symbol-table walk for undef or Class::Abstract' );

	Class::Abstract::_is_direct_abstract($config{pkg_abstract});
	restore_all();

	my @calls = $spy->();
	is( scalar @calls, $ONE_CALL, 'one walk for an ordinary class' );
	is( $calls[0][$ARG1], $config{pkg_abstract}, 'walk is for the class asked about' );
};

# Purpose: a messy @ISA (undef holes, references, numbers, duplicates) must
# still give exactly 1 or 0, with no warnings.
# Strategy: mock _direct_isa to return each messy list.
subtest '_is_direct_abstract -- messy @ISA contents give exact results' => sub {
	my @cases = (
		[ [undef, $CLASS_ABSTRACT],               $TRUE,  'undef hole before Class::Abstract' ],
		[ [undef, undef],                         $FALSE, 'only undef holes' ],
		[ [[], {}, 42],                           $FALSE, 'references and numbers' ],
		[ [($CLASS_ABSTRACT) x 3],                $TRUE,  'Class::Abstract listed three times' ],
		[ ["$CLASS_ABSTRACT "],                   $FALSE, 'near-miss with trailing space' ],
		[ [lc $CLASS_ABSTRACT],                   $FALSE, 'near-miss in lower case' ],
	);
	plan tests => 2 * scalar @cases;

	foreach my $case (@cases) {
		my ($isa, $want, $label) = @{$case};
		my $guard = mock_scoped $config{fn_direct_isa} => sub { $isa };
		my $result;
		my $warnings = warnings_from { $result = Class::Abstract::_is_direct_abstract($config{pkg_plain}) };
		is( $result, $want, "$label: result is exactly $want" );
		is( scalar @{$warnings}, $ZERO_CALLS, "$label: no warnings" );
	}
};

# Purpose: a failure inside the symbol-table walk must propagate
subtest '_is_direct_abstract -- failure inside _direct_isa propagates' => sub {
	plan tests => 1;

	my $guard = mock_scoped $config{fn_direct_isa} => sub { die "$config{boom}\n" };
	throws_ok { Class::Abstract::_is_direct_abstract($config{pkg_plain}) }
		qr/\A\Q$config{boom}\E\n\z/, 'exception from _direct_isa is not swallowed';
};

# Purpose: resource exhaustion -- a very wide @ISA is scanned correctly
subtest '_is_direct_abstract -- very wide @ISA' => sub {
	plan tests => 2;

	{
		no strict 'refs';
		@{"$config{pkg_wide_isa}::ISA"} = ((map { "FT::Base$_" } 1 .. $config{wide_isa_len}), $CLASS_ABSTRACT);
	}
	is( Class::Abstract::_is_direct_abstract($config{pkg_wide_isa}), $TRUE,
		'Class::Abstract found at the end of a very wide @ISA' );

	{
		no strict 'refs';
		pop @{"$config{pkg_wide_isa}::ISA"};
	}
	is( Class::Abstract::_is_direct_abstract($config{pkg_wide_isa}), $FALSE,
		'and not found once removed' );
};

# ===========================================================================
# SECTION: Global-variable hygiene for every function
#
# grep and foreach alias $_, so a helper that wrote to $_ would corrupt
# the caller's loop.  Running each function while $_ is aliased to a
# read-only constant makes any write die with "Modification of a
# read-only value", so these tests catch writes, not just lasting changes.
# ===========================================================================

# Purpose: no function writes to $_
subtest 'all functions -- $_ is never written (read-only alias)' => sub {
	my %calls = (
		_direct_isa         => sub { Class::Abstract::_direct_isa("main::$config{pkg_abstract}") },
		_is_direct_abstract => sub { Class::Abstract::_is_direct_abstract($config{pkg_abstract}) },
		_resolve_class      => sub { Class::Abstract::_resolve_class($config{routine_new}, $config{pkg_concrete}) },
		_bypass_active      => sub { Class::Abstract::_bypass_active() },
		_enforce            => sub { enforcement_on { Class::Abstract::_enforce($config{pkg_concrete}) } },
		new                 => sub { FT::Concrete->new() },
		check_abstract      => sub { enforcement_on { Class::Abstract::check_abstract($config{pkg_concrete}) } },
		is_abstract         => sub { FT::Abstract->is_abstract() },
		import              => sub { package FT::ImportHygiene; Class::Abstract->import() },
	);
	plan tests => 2 * scalar keys %calls;

	foreach my $name (sort keys %calls) {
		for ($config{sentinel}) {    # $_ is now a read-only alias
			lives_ok { $calls{$name}->() } "$name: lives with a read-only \$_";
			is( $_, $config{sentinel}, "$name: \$_ unchanged" );
		}
	}
};

# Purpose: a failing call must not disturb $_ either
subtest 'all functions -- $_ survives a croak' => sub {
	plan tests => 2;

	local $_ = $config{sentinel};
	eval { enforcement_on { FT::Abstract->new() } };
	is( $_, $config{sentinel}, '$_ unchanged after new() croaks' );
	eval { Class::Abstract::is_abstract([]) };
	is( $_, $config{sentinel}, '$_ unchanged after is_abstract() croaks' );
};

# ===========================================================================
# SECTION: import()
#
# White-box focus:
#   - which helpers are called on each path, with which arguments
#   - every early-exit guard fires before any helper is consulted
#   - a failure part-way through leaves @ISA consistent
# ===========================================================================

# Purpose: this test file loaded the module with "()", so main is untouched
subtest 'import() -- "use Class::Abstract ()" does not make main abstract' => sub {
	plan tests => 1;

	ok( !grep({ defined && $_ eq $CLASS_ABSTRACT } @main::ISA), 'Class::Abstract is not in @main::ISA' );
};

# Purpose: on the self-call path, _is_direct_abstract must NOT be called
subtest 'import() -- self-guard exits before calling _is_direct_abstract' => sub {
	plan tests => 2;

	my $spy_ida = spy $config{fn_ida};
	my $spy_sr  = spy $config{fn_set_return};

	# Calling import() from within Class::Abstract itself triggers the self-guard
	{ package Class::Abstract; Class::Abstract->import() }

	restore_all();

	is( call_count($spy_ida), $ZERO_CALLS,
		'_is_direct_abstract not called when caller is Class::Abstract (self-guard)' );
	is( call_count($spy_sr), $ONE_CALL,
		'set_return still called exactly once on the self-guard path' );
};

# Purpose: when Perl cannot name the caller, nothing must be registered --
# least of all @main::ISA, which is what '' would resolve to.
# Strategy: override CORE::GLOBAL::caller so the bare "caller" in import()
# returns ''.
subtest 'import() -- empty caller: no helper called, @main::ISA untouched' => sub {
	plan tests => 2;

	my @isa_before = @main::ISA;
	my $spy = spy $config{fn_ida};
	{
		no warnings 'redefine';
		local *CORE::GLOBAL::caller = sub { return wantarray ? ('', '', 0) : '' };
		Class::Abstract->import();
	}
	restore_all();

	is( call_count($spy), $ZERO_CALLS, '_is_direct_abstract not called for an empty caller' );
	is_deeply( \@main::ISA, \@isa_before, '@main::ISA unchanged' );
};

# Purpose: normal import() path calls _is_direct_abstract with the caller package
subtest 'import() -- calls _is_direct_abstract with the caller package name' => sub {
	plan tests => 2;

	{ package FT::ImportNew; our @ISA = () }

	my $spy = spy $config{fn_ida};
	{ package FT::ImportNew; Class::Abstract->import() }
	restore_all();

	my @calls = $spy->();
	ok( scalar @calls >= $ONE_CALL, '_is_direct_abstract called inside import() for a new caller package' );

	diag "import() called _is_direct_abstract with: '$calls[0][$ARG1]'" if $ENV{TEST_VERBOSE};

	is( $calls[0][$ARG1], $config{pkg_import_new}, '_is_direct_abstract passed the caller package name' );
};

# Purpose: set_return receives the class and the documented string schema,
# and import() returns what set_return returns.
subtest 'import() -- set_return gets ($class, {type => "string"})' => sub {
	plan tests => 3;

	{ package FT::ImportSR; our @ISA = () }

	my $spy = spy $config{fn_set_return};
	my $ret;
	{ package FT::ImportSR; $ret = Class::Abstract->import() }
	restore_all();

	my @calls = $spy->();
	is( $calls[0][$ARG1], $CLASS_ABSTRACT, 'set_return value is the class name' );
	is_deeply( $calls[0][$ARG2], $config{schema_string}, 'set_return schema is { type => "string" }' );
	returns_ok( $ret, $config{schema_string}, 'import() returns a string' );
};

# Purpose: when _is_direct_abstract says "already abstract", no push happens
subtest 'import() -- no @ISA push when _is_direct_abstract returns 1' => sub {
	plan tests => 2;

	{ package FT::ImportDup; our @ISA = ($CLASS_ABSTRACT) }

	my $count_before = grep { $_ eq $CLASS_ABSTRACT } @FT::ImportDup::ISA;
	{
		my $guard = mock_scoped $config{fn_ida} => sub { $TRUE };
		package FT::ImportDup;
		Class::Abstract->import();
	}
	my $count_after = grep { $_ eq $CLASS_ABSTRACT } @FT::ImportDup::ISA;

	is( $count_after, $count_before, '@ISA not modified when _is_direct_abstract returns 1' );
	is( $count_after, $ONE_CALL, 'Class::Abstract appears exactly once in @FT::ImportDup::ISA' );
};

# Purpose: when _is_direct_abstract says "not abstract", exactly one push
subtest 'import() -- pushes to @ISA when _is_direct_abstract returns 0' => sub {
	plan tests => 1;

	{ package FT::ImportEarly; our @ISA = () }
	{
		my $guard = mock_scoped $config{fn_ida} => sub { $FALSE };
		package FT::ImportEarly;
		Class::Abstract->import();
	}

	is_deeply( \@FT::ImportEarly::ISA, [$CLASS_ABSTRACT], 'Class::Abstract pushed exactly once' );
};

# Purpose: if the duplicate check dies mid-flight, @ISA must be untouched
# (the push happens only after the check succeeds).
subtest 'import() -- failure in _is_direct_abstract leaves @ISA untouched' => sub {
	plan tests => 2;

	{ package FT::ImportBoom; our @ISA = () }
	{
		my $guard = mock_scoped $config{fn_ida} => sub { die "$config{boom}\n" };
		throws_ok { package FT::ImportBoom; Class::Abstract->import() }
			qr/\A\Q$config{boom}\E\n\z/, 'exception propagates out of import()';
	}
	is_deeply( \@FT::ImportBoom::ISA, [], '@ISA unchanged after the failure' );
};

# Purpose: if set_return dies, the error must propagate.  Registration
# already happened by then, so the class is abstract.
subtest 'import() -- failure in set_return propagates' => sub {
	plan tests => 2;

	{ package FT::ImportSetReturnDies; our @ISA = () }
	{
		my $guard = mock_scoped $config{fn_set_return} => sub { die "$config{boom}\n" };
		throws_ok { package FT::ImportSetReturnDies; Class::Abstract->import() }
			qr/\A\Q$config{boom}\E\n\z/, 'exception from set_return propagates';
	}
	is_deeply( \@FT::ImportSetReturnDies::ISA, [$CLASS_ABSTRACT], 'registration happened before the failure' );
};

# Purpose: an import list (even a hostile one) is ignored
subtest 'import() -- import list is ignored' => sub {
	plan tests => 2;

	{ package FT::ImportList; our @ISA = () }
	my $ret;
	lives_ok { package FT::ImportList; $ret = Class::Abstract->import('junk', [], { a => 1 }, undef) }
		'import() with a junk import list lives';
	is_deeply( \@FT::ImportList::ISA, [$CLASS_ABSTRACT], 'only Class::Abstract is added' );
};

# ===========================================================================
# SECTION: new()
#
# White-box focus:
#   - _resolve_class('new', ...) then _enforce(class), in that order
#   - a failure in either helper stops construction
#   - returned objects are empty, distinct, cycle-free and collectable
# ===========================================================================

# Purpose: new() delegates validation and enforcement to the helpers
subtest 'new() -- calls _resolve_class("new", $invocant) then _enforce($class)' => sub {
	plan tests => 4;

	clear_call_log();
	my $spy_r = spy $config{fn_resolve};
	my $spy_e = spy $config{fn_enforce};

	my $obj = bless {}, $config{pkg_concrete};
	enforcement_on { Class::Abstract::new($obj) };

	assert_call_order($config{fn_resolve}, $config{fn_enforce});
	restore_all();

	my @r = $spy_r->();
	my @e = $spy_e->();
	is( $r[0][$ARG1], $config{routine_new}, '_resolve_class told it is serving new()' );
	ok( $r[0][$ARG2] == $obj, '_resolve_class got the original invocant' );
	is( $e[0][$ARG1], $config{pkg_concrete}, '_enforce got the resolved class name' );
};

# Purpose: _is_direct_abstract is called with the resolved class name
subtest 'new() -- calls _is_direct_abstract with the class name when enforcement on' => sub {
	plan tests => 2;

	my $spy = spy $config{fn_ida};
	enforcement_on { FT::Concrete->new() };
	restore_all();

	my @calls = $spy->();
	ok( scalar @calls >= $ONE_CALL, '_is_direct_abstract called inside new() when enforcement is active' );

	diag "new() called _is_direct_abstract with: '$calls[0][$ARG1]'" if $ENV{TEST_VERBOSE};

	is( $calls[0][$ARG1], $config{pkg_concrete}, '_is_direct_abstract passed the concrete class, not a base class' );
};

# Purpose: when $BYPASS is truthy, _is_direct_abstract must not be called
subtest 'new() -- _is_direct_abstract skipped when $BYPASS is truthy' => sub {
	plan tests => 1;

	my $spy = spy $config{fn_ida};
	local $Class::Abstract::BYPASS                 = $TRUE;
	local $Class::Abstract::config{harness_bypass} = $FALSE;
	local $ENV{HARNESS_ACTIVE}                     = $FALSE;
	eval { FT::Abstract->new() };
	restore_all();

	is( call_count($spy), $ZERO_CALLS, '_is_direct_abstract not called at all when $BYPASS is truthy' );
};

# Purpose: when harness bypass fires, _is_direct_abstract must not be called
subtest 'new() -- _is_direct_abstract skipped under harness bypass' => sub {
	plan tests => 1;

	my $spy = spy $config{fn_ida};
	local $Class::Abstract::BYPASS                 = $FALSE;
	local $Class::Abstract::config{harness_bypass} = $TRUE;
	local $ENV{HARNESS_ACTIVE}                     = $TRUE;
	eval { FT::Abstract->new() };
	restore_all();

	is( call_count($spy), $ZERO_CALLS, '_is_direct_abstract not called when harness_bypass + HARNESS_ACTIVE active' );
};

# Purpose: new() obeys _is_direct_abstract, in both directions
subtest 'new() -- respects _is_direct_abstract (mock 1 croaks, mock 0 builds)' => sub {
	plan tests => 2;

	{
		my $guard = mock_scoped $config{fn_ida} => sub { $TRUE };
		throws_ok { enforcement_on { FT::Concrete->new() } }
			exact_error('abstract', $config{pkg_concrete}),
			'new() croaks for FT::Concrete when told it is abstract';
	}
	{
		my $guard = mock_scoped $config{fn_ida} => sub { $FALSE };
		lives_ok { enforcement_on { FT::Abstract->new() } }
			'new() builds FT::Abstract when told it is concrete';
	}
};

# Purpose: a failure in either helper stops construction: no object, and
# the error reaches the caller unchanged.
subtest 'new() -- failure in a helper stops construction' => sub {
	plan tests => 4;

	my $obj;
	{
		my $guard = mock_scoped $config{fn_enforce} => sub { die "$config{boom}\n" };
		throws_ok { $obj = FT::Concrete->new() } qr/\A\Q$config{boom}\E\n\z/, '_enforce failure propagates';
	}
	ok( !defined $obj, 'no object returned when _enforce fails' );

	my $spy_e = spy $config{fn_enforce};
	{
		my $guard = mock_scoped $config{fn_resolve} => sub { die "$config{boom}\n" };
		throws_ok { Class::Abstract::new($config{pkg_concrete}) } qr/\A\Q$config{boom}\E\n\z/,
			'_resolve_class failure propagates';
	}
	restore_all();
	is( call_count($spy_e), $ZERO_CALLS, '_enforce never reached when _resolve_class fails' );
};

# Purpose: every bad invocant croaks with the exact message, at the caller
subtest 'new() -- bad invocants croak with exact messages' => sub {
	plan tests => 4;

	throws_ok { Class::Abstract::new(undef) } exact_error('new:undef'),           'undef';
	throws_ok { Class::Abstract::new('') }    exact_error('new:undef'),           'empty string';
	throws_ok { Class::Abstract::new([]) }    exact_error('new:unblessed', 'ARRAY'), 'array ref';
	throws_ok { enforcement_on { FT::Abstract->new() } }
		exact_error('abstract', $config{pkg_abstract}), 'abstract class';
};

# Purpose: the "" guard fires before any enforcement work is done
subtest 'new() -- empty string: _is_direct_abstract never called' => sub {
	plan tests => 2;

	my $spy = spy $config{fn_ida};
	throws_ok { Class::Abstract::new('') } $config{err_new_undef}, 'new("") croaks at the guard';
	restore_all();
	is( call_count($spy), $ZERO_CALLS, '_is_direct_abstract never called' );
};

# Purpose: the result is an empty hash of the exact class, extra arguments
# are ignored, and every call makes a new object.
subtest 'new() -- returns a new, empty object of the exact class' => sub {
	plan tests => 5;

	my $a = FT::Concrete->new(name => 'ignored', 1 .. 4);
	my $b = FT::Concrete->new();

	returns_ok( $a, $config{schema_object}, 'new() returns an object' );
	is( ref($a), $config{pkg_concrete}, 'blessed into the invocant class' );
	is_deeply( {%{$a}}, {}, 'object is an empty hash (arguments ignored)' );
	ok( $a != $b, 'two calls give two distinct objects' );
	memory_cycle_ok( $a, 'returned object has no memory cycles' );
};

# Purpose: the module keeps no reference to objects it creates or is
# given, so they are freed as soon as the caller drops them.
subtest 'new() -- objects are freed when the caller drops them' => sub {
	plan tests => 2;

	my $made = FT::Concrete->new();
	my $weak_made = $made;
	weaken($weak_made);
	undef $made;
	ok( !defined $weak_made, 'object made by new() is freed' );

	my $proto = FT::Concrete->new();
	my $copy  = $proto->new();
	my $weak_proto = $proto;
	weaken($weak_proto);
	undef $proto;
	ok( !defined $weak_proto, 'object used as invocant is not kept alive' );
};

# ===========================================================================
# SECTION: check_abstract()
# ===========================================================================

# Purpose: check_abstract() delegates with the 'check' message prefix
subtest 'check_abstract() -- calls _resolve_class("check", ...) and _enforce' => sub {
	plan tests => 2;

	my $spy_r = spy $config{fn_resolve};
	my $spy_e = spy $config{fn_enforce};
	enforcement_on { Class::Abstract::check_abstract($config{pkg_concrete}) };
	restore_all();

	my @r = $spy_r->();
	my @e = $spy_e->();
	is( $r[0][$ARG1], $config{routine_check}, '_resolve_class told it is serving check_abstract()' );
	is( $e[0][$ARG1], $config{pkg_concrete}, '_enforce got the class name' );
};

# Purpose: _is_direct_abstract called with the correct class during enforcement
subtest 'check_abstract() -- calls _is_direct_abstract with the correct class' => sub {
	plan tests => 2;

	my $obj = FT::Concrete->new();
	my $spy = spy $config{fn_ida};
	enforcement_on { Class::Abstract::check_abstract($config{pkg_concrete}) };
	enforcement_on { Class::Abstract::check_abstract($obj) };
	restore_all();

	my @calls = $spy->();
	is( $calls[0][$ARG1], $config{pkg_concrete}, 'class name passed through' );
	is( $calls[1][$ARG1], $config{pkg_concrete}, 'object resolved to its class, not passed as a reference' );
};

# Purpose: either bypass path skips the abstract check entirely
subtest 'check_abstract() -- _is_direct_abstract skipped under either bypass' => sub {
	plan tests => 2;

	my $spy = spy $config{fn_ida};
	{
		local $Class::Abstract::BYPASS                 = $TRUE;
		local $Class::Abstract::config{harness_bypass} = $FALSE;
		eval { Class::Abstract::check_abstract($config{pkg_abstract}) };
	}
	is( call_count($spy), $ZERO_CALLS, 'skipped when $BYPASS is truthy' );
	{
		local $Class::Abstract::BYPASS                 = $FALSE;
		local $Class::Abstract::config{harness_bypass} = $TRUE;
		local $ENV{HARNESS_ACTIVE}                     = $TRUE;
		eval { Class::Abstract::check_abstract($config{pkg_abstract}) };
	}
	restore_all();
	is( call_count($spy), $ZERO_CALLS, 'skipped under harness_bypass + HARNESS_ACTIVE' );
};

# Purpose: on success it returns nothing: undef in scalar context and an
# empty list in list context (a bare "return;").
subtest 'check_abstract() -- returns undef / empty list on success' => sub {
	plan tests => 2;

	my $scalar = enforcement_on { scalar Class::Abstract::check_abstract($config{pkg_concrete}) };
	my @list   = enforcement_on { Class::Abstract::check_abstract($config{pkg_concrete}) };
	ok( !defined $scalar, 'scalar context: undef' );
	is( scalar @list, $ZERO_CALLS, 'list context: empty list' );
};

# Purpose: every bad argument croaks with the exact message, at the caller
subtest 'check_abstract() -- bad arguments croak with exact messages' => sub {
	plan tests => 4;

	throws_ok { Class::Abstract::check_abstract(undef) }      exact_error('check:undef'),           'undef';
	throws_ok { Class::Abstract::check_abstract('') }         exact_error('check:undef'),           'empty string';
	throws_ok { Class::Abstract::check_abstract(sub { 1 }) }  exact_error('check:unblessed', 'CODE'), 'code ref';
	throws_ok { enforcement_on { Class::Abstract::check_abstract($config{pkg_abstract}) } }
		exact_error('abstract', $config{pkg_abstract}), 'abstract class';
};

# Purpose: a failure inside _enforce propagates unchanged
subtest 'check_abstract() -- failure in _enforce propagates' => sub {
	plan tests => 1;

	my $guard = mock_scoped $config{fn_enforce} => sub { die "$config{boom}\n" };
	throws_ok { Class::Abstract::check_abstract($config{pkg_concrete}) }
		qr/\A\Q$config{boom}\E\n\z/, 'exception from _enforce is not swallowed';
};

# Purpose: the "" guard fires before any enforcement work is done
subtest 'check_abstract() -- empty string: _is_direct_abstract never called' => sub {
	plan tests => 2;

	my $spy = spy $config{fn_ida};
	throws_ok { Class::Abstract::check_abstract('') } $config{err_chk_undef}, 'check_abstract("") croaks';
	restore_all();
	is( call_count($spy), $ZERO_CALLS, '_is_direct_abstract never called' );
};

# Purpose: an object passed in is not kept alive by the module
subtest 'check_abstract() -- object argument is not retained' => sub {
	plan tests => 1;

	my $obj = FT::Concrete->new();
	enforcement_on { Class::Abstract::check_abstract($obj) };
	my $weak = $obj;
	weaken($weak);
	undef $obj;
	ok( !defined $weak, 'object freed after check_abstract()' );
};

# ===========================================================================
# SECTION: is_abstract()
#
# White-box focus:
#   - an explicit target is used instead of the invocant when it is
#     DEFINED (not when it is true): '0' is a real target
#   - an undef target falls back to the invocant; an empty target does not
# ===========================================================================

# Purpose: the invocant is checked when no target is given
subtest 'is_abstract() -- no target: invocant class is checked' => sub {
	plan tests => 3;

	my $obj = FT::Concrete->new();
	my $spy = spy $config{fn_ida};
	FT::Abstract->is_abstract();
	$obj->is_abstract();
	restore_all();

	my @calls = $spy->();

	diag "is_abstract() passed: '$calls[0][$ARG1]', '$calls[1][$ARG1]'" if $ENV{TEST_VERBOSE};

	is( $calls[0][$ARG1], $config{pkg_abstract}, 'class-method form checks the invocant class' );
	is( $calls[1][$ARG1], $config{pkg_concrete}, 'object form checks ref($obj), not the reference' );
	is( scalar @calls, 2, 'one check per call' );
};

# Purpose: an explicit target replaces the invocant
subtest 'is_abstract() -- explicit target replaces the invocant' => sub {
	plan tests => 3;

	my $spy_r = spy $config{fn_resolve};
	my $spy_i = spy $config{fn_ida};
	Class::Abstract->is_abstract($config{pkg_abstract});
	restore_all();

	my @r = $spy_r->();
	my @i = $spy_i->();
	is( $r[0][$ARG1], $config{routine_isabs}, '_resolve_class told it is serving is_abstract()' );
	is( $r[0][$ARG2], $config{pkg_abstract}, '_resolve_class given the target, not the invocant' );
	is( $i[0][$ARG1], $config{pkg_abstract}, '_is_direct_abstract checks the target' );
};

# Purpose: target "0" is defined, so it must be used even though it is
# false.  A truth test here would silently check the invocant instead.
subtest 'is_abstract() -- target "0" is used, not ignored as false' => sub {
	plan tests => 1;

	my $spy = spy $config{fn_ida};
	FT::Abstract->is_abstract($config{pkg_zero});
	restore_all();

	my @calls = $spy->();
	is( $calls[0][$ARG1], $config{pkg_zero}, 'class "0" checked, not FT::Abstract' );
};

# Purpose: an undef target means "not given"; an empty or reference
# target is an error, not a silent fallback to the invocant.
subtest 'is_abstract() -- undef target falls back; bad targets croak' => sub {
	plan tests => 4;

	is( FT::Abstract->is_abstract(undef), $TRUE, 'undef target: invocant checked' );
	throws_ok { FT::Abstract->is_abstract('') } exact_error('is_abstract:undef'),
		'"" target croaks rather than falling back';
	throws_ok { FT::Abstract->is_abstract([]) } exact_error('is_abstract:unblessed', 'ARRAY'),
		'array-ref target croaks';
	throws_ok { Class::Abstract::is_abstract(undef) } exact_error('is_abstract:undef'),
		'undef invocant with no target croaks';
};

# Purpose: is_abstract() passes the helper's answer through unchanged
subtest 'is_abstract() -- propagates _is_direct_abstract return value unchanged' => sub {
	plan tests => 3;

	my ($yes, $no);
	{
		my $guard = mock_scoped $config{fn_ida} => sub { $TRUE };
		$yes = FT::Concrete->is_abstract();
	}
	{
		my $guard = mock_scoped $config{fn_ida} => sub { $FALSE };
		$no = FT::Abstract->is_abstract();
	}

	is( $yes, $TRUE,  'returns 1 when _is_direct_abstract returns 1' );
	is( $no,  $FALSE, 'returns 0 when _is_direct_abstract returns 0' );
	returns_ok( $no, $config{schema_integer}, 'return value is an integer 0 or 1' );
};

# Purpose: a validation failure stops before the check, and errors from
# the check propagate unchanged
subtest 'is_abstract() -- failures stop or propagate' => sub {
	plan tests => 2;

	my $spy = spy $config{fn_ida};
	eval { Class::Abstract::is_abstract({}) };
	restore_all();
	is( call_count($spy), $ZERO_CALLS, '_is_direct_abstract not called after a validation failure' );

	my $guard = mock_scoped $config{fn_ida} => sub { die "$config{boom}\n" };
	throws_ok { FT::Abstract->is_abstract() } qr/\A\Q$config{boom}\E\n\z/,
		'exception from _is_direct_abstract propagates';
};

# Purpose: hostile objects are judged by their real class
subtest 'is_abstract() -- overloaded object cannot pose as an abstract class' => sub {
	plan tests => 1;

	my $liar = bless {}, $config{pkg_overload};    # stringifies as FT::Abstract
	is( Class::Abstract->is_abstract($liar), $FALSE, 'checked as FT::Overloaded, so 0' );
};

# Purpose: an object passed as target is not kept alive by the module
subtest 'is_abstract() -- object target is not retained' => sub {
	plan tests => 1;

	my $obj = FT::Concrete->new();
	Class::Abstract->is_abstract($obj);
	my $weak = $obj;
	weaken($weak);
	undef $obj;
	ok( !defined $weak, 'object freed after is_abstract()' );
};

# ===========================================================================
# SECTION: Global module state
# ===========================================================================

# Purpose: module-level public data structures must be cycle-free, so the
# garbage collector can always clean up after them
subtest 'module state -- $BYPASS and %config contain no memory cycles' => sub {
	plan tests => 3;

	memory_cycle_ok( \$Class::Abstract::BYPASS, '$Class::Abstract::BYPASS has no memory cycles' );
	memory_cycle_ok( \%Class::Abstract::config, '%Class::Abstract::config has no memory cycles' );
	memory_cycle_ok( Class::Abstract::_direct_isa($config{pkg_abstract}), '_direct_isa result has no memory cycles' );
};

# Purpose: no test above leaked a mock or spy into the rest of the suite
subtest 'module state -- no mocks or spies left installed' => sub {
	plan tests => 1;

	restore_all();
	is_deeply( diagnose_mocks(), {}, 'diagnose_mocks() reports nothing active' );
};

done_testing;
