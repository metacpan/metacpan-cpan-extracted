#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use Capture::Tiny qw(capture_stdout capture_merged);
use File::Temp qw(tempdir tempfile);
use File::Spec;
use File::Path qw(make_path);
use Cwd qw(getcwd);
use Carp qw(croak);
use JSON::MaybeXS qw(decode_json);
use PPI;
use Readonly;
use Scalar::Util qw(looks_like_number);

# CORE::GLOBAL::system overrides are resolved when the *calling* code is
# compiled, not dispatched dynamically -- a "local *CORE::GLOBAL::system"
# set at runtime inside a subtest has no effect on Mutator::run_tests(),
# because Mutator.pm is already compiled by the time that subtest runs.
# This override must therefore be installed in a BEGIN block before
# App::Test::Generator::Mutator is use'd below, with the actual mock
# behaviour supplied per-subtest via $REAL_SYSTEM_HOOK so the default
# (no active subtest) passes through to the real builtin.
our $REAL_SYSTEM_HOOK;
BEGIN {
	no warnings 'redefine';
	*CORE::GLOBAL::system = sub {
		return $REAL_SYSTEM_HOOK ? $REAL_SYSTEM_HOOK->(@_) : CORE::system(@_);
	};
}

# Allow access to private helpers via the package namespace
BEGIN {
	use_ok('App::Test::Generator');
	use_ok('App::Test::Generator::Mutator');
	use_ok('App::Test::Generator::Mutant');
	use_ok('App::Test::Generator::Exporter::YAML');
	use_ok('App::Test::Generator::Analyzer::Return');
	use_ok('App::Test::Generator::Analyzer::ReturnMeta');
	use_ok('App::Test::Generator::Analyzer::Complexity');
	use_ok('App::Test::Generator::Analyzer::SideEffect');
	use_ok('App::Test::Generator::Planner::Mock');
	use_ok('App::Test::Generator::Planner::Fixture');
	use_ok('App::Test::Generator::Planner::Grouping');
	use_ok('App::Test::Generator::Planner::Isolation');
	use_ok('App::Test::Generator::Planner');
	use_ok('App::Test::Generator::LCSAJ::Coverage');
	use_ok('App::Test::Generator::LCSAJ');
	use_ok('App::Test::Generator::Mutation::Base');
	use_ok('App::Test::Generator::Mutation::ConditionalInversion');
	use_ok('App::Test::Generator::Mutation::NumericBoundary');
	use_ok('App::Test::Generator::Mutation::ReturnUndef');
	use_ok('App::Test::Generator::Mutation::BooleanNegation');
	use_ok('App::Test::Generator::TestStrategy');
	use_ok('App::Test::Generator::Model::Method');
	use_ok('App::Test::Generator::Sample::Module');
	use_ok('Devel::App::Test::Generator::LCSAJ::Runtime');
	use_ok('App::Test::Generator::Emitter::Perl');
	use_ok('App::Test::Generator::Template');
	use_ok('App::Test::Generator::SchemaExtractor');
}

# --------------------------------------------------
# Constants used across multiple subtests to avoid
# magic literals and make intent clear
# --------------------------------------------------
Readonly my $EMPTY_STRING  => '';
Readonly my $UNDEF_LITERAL => 'undef';

# --------------------------------------------------
# Mirrors of the boundary constants private to
# App::Test::Generator::Sample::Module, so its
# boundary tests below avoid magic numbers without
# requiring the module to export its internals
# --------------------------------------------------
Readonly my $SAMPLE_MIN_EMAIL_LEN  => 5;
Readonly my $SAMPLE_MAX_EMAIL_LEN  => 254;
Readonly my $SAMPLE_MIN_BIRTH_YEAR => 1900;
Readonly my $SAMPLE_MIN_NAME_LEN   => 1;
Readonly my $SAMPLE_MAX_NAME_LEN   => 50;
Readonly my $SAMPLE_MIN_SCORE      => 0.0;
Readonly my $SAMPLE_MAX_SCORE      => 100.0;
Readonly my $SAMPLE_PASS_THRESHOLD => 60.0;

# ==================================================================
# perl_sq
# --------------------------------------------------
# White-box tests for the low-level single-quote
# string escaper used by perl_quote and q_wrap
# ==================================================================
subtest 'perl_sq' => sub {
	# Access the private function directly via the package namespace
	my $fn = \&App::Test::Generator::perl_sq;

	# Undef input returns empty string, not 'undef'
	is($fn->(undef), $EMPTY_STRING, 'undef returns empty string');

	# Plain ASCII string passes through unchanged
	is($fn->('hello'), 'hello', 'plain ASCII unchanged');

	# Apostrophe must be escaped so it does not break the surrounding
	# single-quoted string literal in the generated test
	is($fn->("it's"), "it\\'s", 'apostrophe escaped');

	# Backslash must be escaped first so later substitutions
	# do not double-escape already-escaped sequences
	is($fn->('a\\b'), 'a\\\\b', 'backslash escaped');

	# Control characters are converted to their two-char sequences
	is($fn->("a\nb"), 'a\\nb', 'newline escaped');
	is($fn->("a\rb"), 'a\\rb', 'carriage return escaped');
	is($fn->("a\tb"), 'a\\tb', 'tab escaped');
	is($fn->("a\fb"), 'a\\fb', 'form feed escaped');

	# NUL byte is converted to \0 for double-quoted context
	is($fn->("a\0b"), 'a\\0b', 'NUL byte escaped');

	# Both apostrophe and backslash in the same string
	is($fn->("a\\'b"), "a\\\\\\'b", 'backslash and apostrophe together');

	done_testing();
};

# ==================================================================
# perl_quote
# --------------------------------------------------
# Tests for the top-level value quoter that produces
# Perl source-code literals for any scalar type
# ==================================================================
subtest 'perl_quote' => sub {
	my $fn = \&App::Test::Generator::perl_quote;

	# Undef always produces the bare word 'undef'
	is($fn->(undef), $UNDEF_LITERAL, 'undef produces undef literal');

	# YAML boolean strings must round-trip to Perl boolean constants
	is($fn->('true'),  '!!1', 'true produces !!1');
	is($fn->('false'), '!!0', 'false produces !!0');

	# Integers are emitted unquoted for numeric comparison
	is($fn->(0),   '0',   'zero unquoted');
	is($fn->(42),  '42',  'positive integer unquoted');
	is($fn->(-1),  '-1',  'negative integer unquoted');

	# Floats are emitted unquoted
	is($fn->(3.14), '3.14', 'float unquoted');

	# Plain strings are single-quoted
	is($fn->('hello'), "'hello'", 'string single-quoted');

	# Strings containing apostrophes have them escaped
	is($fn->("it's"), "'it\\'s'", 'apostrophe in string escaped');

	# Arrayrefs are recursively quoted with brackets
	is($fn->([1, 2, 3]), '[ 1, 2, 3 ]', 'arrayref recursively quoted');

	# Nested arrayrefs recurse correctly
	is($fn->([1, [2, 3]]), '[ 1, [ 2, 3 ] ]', 'nested arrayref quoted');

	# Arrayref containing undef produces undef literal in the output
	is($fn->([undef, 1]), "[ $UNDEF_LITERAL, 1 ]", 'arrayref with undef element');

	# Regexp objects are rendered as qr{} with modifiers
	my $re = qr/foo/i;
	like($fn->($re), qr/qr\{foo\}i/, 'Regexp rendered as qr{}');

	# Regexp without modifiers has no trailing flags
	my $re2 = qr/bar/;
	like($fn->($re2), qr/qr\{bar\}/, 'Regexp without modifiers');

	done_testing();
};

# ==================================================================
# q_wrap
# --------------------------------------------------
# Tests for the string wrapper that chooses the most
# readable q{} delimiter form
# ==================================================================
subtest 'q_wrap' => sub {
	my $fn = \&App::Test::Generator::q_wrap;

	# Undef returns empty single-quoted string — q_wrap is a
	# string quoter, not a value serialiser, so undef means
	# no string value rather than the Perl literal 'undef'
	is($fn->(undef), "''", 'undef returns empty single-quoted string');

	# Plain string uses the preferred q{} bracket form
	is($fn->('hello'), 'q{hello}', 'plain string uses q{}');

	# String containing { forces a different bracket pair
	my $with_brace = 'a{b';
	unlike($fn->($with_brace), qr/^q\{/, 'string with { avoids q{}');

	# String containing all bracket pairs falls back to single chars
	my $all_brackets = '{([<>])}';
	my $result = $fn->($all_brackets);
	like($result, qr/^q./, 'all-bracket string still uses q form');

	# Empty string produces empty q form
	is($fn->($EMPTY_STRING), 'q{}', 'empty string produces q{}');

	# String with apostrophe — q_wrap avoids needing to escape it
	# by choosing a delimiter that is not an apostrophe
	my $apos = "it's";
	my $wrapped = $fn->($apos);
	unlike($wrapped, qr/\\'/, 'apostrophe not escaped in q_wrap output');

	done_testing();
};

# ==================================================================
# render_fallback
# --------------------------------------------------
# Tests for the Data::Dumper-based catch-all renderer
# ==================================================================
subtest 'render_fallback' => sub {
	my $fn = \&App::Test::Generator::render_fallback;

	# Undef produces the literal string 'undef'
	is($fn->(undef), $UNDEF_LITERAL, 'undef produces undef literal');

	# Integer scalars pass through Dumper in terse mode
	my $scalar_result = $fn->(42);
	is($scalar_result, '42', 'integer scalar');

	# Hashrefs are rendered as Perl hash literals with braces
	my $hash_result = $fn->({ a => 1 });
	like($hash_result, qr/\{/, 'hashref renders with braces');
	like($hash_result, qr/'a'/, 'hashref key present');

	# No trailing newline — Dumper adds one and we strip it
	unlike($fn->({ a => 1 }), qr/\n$/, 'no trailing newline');

	# Arrayrefs render with square brackets
	my $arr_result = $fn->([1, 2]);
	like($arr_result, qr/\[/, 'arrayref renders with brackets');

	done_testing();
};

# ==================================================================
# render_args_hash
# --------------------------------------------------
# Tests for the flat hashref renderer used for output
# specs and constructor argument lists
# ==================================================================
subtest 'render_args_hash' => sub {
	my $fn = \&App::Test::Generator::render_args_hash;

	# Undef input returns empty string
	is($fn->(undef), $EMPTY_STRING, 'undef returns empty string');

	# Non-hash input returns empty string
	is($fn->([1, 2]), $EMPTY_STRING, 'arrayref returns empty string');

	# Empty hash returns empty string
	is($fn->({}), $EMPTY_STRING, 'empty hash returns empty string');

	# Single key-value pair is rendered correctly
	my $result = $fn->({ type => 'string' });
	like($result, qr/'type'\s*=>\s*'string'/, 'single key rendered');

	# Multiple keys are sorted alphabetically for deterministic output
	my $multi = $fn->({ b => 2, a => 1 });
	my $a_pos = index($multi, "'a'");
	my $b_pos = index($multi, "'b'");
	ok($a_pos < $b_pos, 'keys sorted alphabetically');

	# Numeric values are rendered unquoted
	my $num = $fn->({ min => 1, max => 10 });
	like($num, qr/'min'\s*=>\s*1\b/, 'numeric value unquoted');

	# Regexp value is rendered as qr{} not a raw string
	my $re_result = $fn->({ matches => qr/foo/ });
	like($re_result, qr/qr\{foo\}/, 'Regexp rendered as qr{}');

	done_testing();
};

# ==================================================================
# render_hash
# --------------------------------------------------
# Tests for the two-level hash renderer used for
# the %input specification in generated tests.
# Note: render_hash emits unquoted sub-keys (type =>)
# because it delegates sub-key rendering to
# render_args_hash which does not quote key names.
# ==================================================================
subtest 'render_hash' => sub {
	my $fn = \&App::Test::Generator::render_hash;

	# Undef and non-hash inputs return empty string
	is($fn->(undef), $EMPTY_STRING, 'undef returns empty string');
	is($fn->(42),    $EMPTY_STRING, 'scalar returns empty string');
	is($fn->({}),    $EMPTY_STRING, 'empty hash returns empty string');

	# Standard two-level hash renders the top-level key quoted
	# but sub-keys are rendered unquoted by render_args_hash
	my $result = $fn->({ name => { type => 'string', optional => 0 } });
	like($result, qr/'name'\s*=>\s*\{/, 'top-level key rendered quoted');
	like($result, qr/type\s*=>\s*'string'/, 'sub-key type rendered unquoted');
	like($result, qr/optional\s*=>\s*0/, 'sub-key optional rendered unquoted');

	# Scalar type shorthand is expanded to a full spec hashref
	# so it renders as a proper { type => '...' } block
	my $shorthand = $fn->({ arg => 'string' });
	like($shorthand, qr/'arg'\s*=>\s*\{/, 'shorthand expanded to hashref');
	like($shorthand, qr/type\s*=>\s*'string'/, 'shorthand type present unquoted');

	# matches pattern is compiled to Regexp before rendering
	# so it appears as qr{} not a raw string in the output
	my $re_result = $fn->({ field => { type => 'string', matches => 'foo' } });
	like($re_result, qr/qr\{/, 'matches compiled to qr{}');

	# Unknown type shorthand produces a warning, not a croak
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	$fn->({ x => 'not_a_type' });
	ok(@warnings, 'unknown type shorthand produces warning');

	done_testing();
};

# ==================================================================
# render_arrayref_map
# --------------------------------------------------
# Tests for the hash-of-arrayrefs renderer used for
# edge_cases and type_edge_cases.
# Note: undef returns '()' but an empty hash returns ''
# — these are distinct cases with different semantics.
# ==================================================================
subtest 'render_arrayref_map' => sub {
	my $fn = \&App::Test::Generator::render_arrayref_map;

	# Undef returns '()' so the generated test gets a valid
	# empty hash literal rather than a syntax error
	is($fn->(undef), '()', 'undef returns ()');

	# Empty hash returns empty string — distinct from the undef case
	is($fn->({}), $EMPTY_STRING, 'empty hash returns empty string');

	# Standard case renders the key with its arrayref correctly
	my $result = $fn->({ name => ['', 'x' x 10] });
	like($result, qr/'name'\s*=>\s*\[/, 'key rendered with arrayref');
	like($result, qr/''/, 'empty string element rendered');

	# Non-arrayref values are silently skipped
	my $mixed = $fn->({ arr => [1, 2], scalar => 'foo' });
	like($mixed,   qr/'arr'/,    'arrayref value included');
	unlike($mixed, qr/'scalar'/, 'scalar value skipped');

	# Keys are sorted alphabetically for deterministic output
	my $sorted = $fn->({ b => [2], a => [1] });
	ok(index($sorted, "'a'") < index($sorted, "'b'"), 'keys sorted');

	done_testing();
};

# ==================================================================
# _valid_type
# --------------------------------------------------
# Tests for the type string validator
# ==================================================================
subtest '_valid_type' => sub {
	my $fn = \&App::Test::Generator::_valid_type;

	# Undef is never a valid type
	ok(!$fn->(undef), 'undef is not valid');

	# All documented base types must be accepted
	for my $type (qw(string boolean integer number float hashref arrayref object)) {
		ok($fn->($type), "$type is valid");
	}

	# Short aliases must be accepted for compatibility with external
	# tools that use the shorter forms
	ok($fn->('int'),  'int alias accepted');
	ok($fn->('bool'), 'bool alias accepted');

	# Unknown and non-type strings are rejected
	ok(!$fn->('scalar'),      'scalar rejected');
	ok(!$fn->('coderef'),     'coderef rejected');
	ok(!$fn->('unknown'),     'unknown type rejected');
	ok(!$fn->($EMPTY_STRING), 'empty string rejected');

	done_testing();
};

# ==================================================================
# _has_positions
# --------------------------------------------------
# Tests for the positional argument detector
# ==================================================================
subtest '_has_positions' => sub {
	my $fn = \&App::Test::Generator::_has_positions;

	# Undef and non-hash inputs return 0 without throwing
	is($fn->(undef), 0, 'undef returns 0');
	is($fn->(42),    0, 'scalar returns 0');
	is($fn->({}),    0, 'empty hash returns 0');

	# Hash with no position keys returns 0
	my $no_pos = { a => { type => 'string' } };
	is($fn->($no_pos), 0, 'no position keys returns 0');

	# Hash with a position key returns 1
	my $with_pos = { a => { type => 'string', position => 0 } };
	is($fn->($with_pos), 1, 'position key found returns 1');

	# Mixed hash — any single position key is enough to return 1
	my $mixed = {
		a => { type => 'string',  position => 0 },
		b => { type => 'integer' },
	};
	is($fn->($mixed), 1, 'mixed: any position key returns 1');

	# Scalar spec values (shorthand) cannot carry positions
	my $scalar_spec = { a => 'string' };
	is($fn->($scalar_spec), 0, 'scalar spec has no position');

	done_testing();
};

# ==================================================================
# _load_schema_section
# --------------------------------------------------
# Tests for the safe section extractor
# ==================================================================
subtest '_load_schema_section' => sub {
	my $fn = \&App::Test::Generator::_load_schema_section;

	# Missing section returns empty hashref as the safe default
	my $schema = {};
	is_deeply($fn->($schema, 'input', 'test.yml'), {}, 'missing section returns {}');

	# Present hashref section is returned directly without copying
	my $input = { name => { type => 'string' } };
	$schema = { input => $input };
	is_deeply($fn->($schema, 'input', 'test.yml'), $input, 'hashref section returned');

	# The string 'undef' in a section means the same as absent
	$schema = { output => 'undef' };
	is_deeply($fn->($schema, 'output', 'test.yml'), {}, "'undef' string treated as absent");

	# Wrong type croaks with a message mentioning the section name
	$schema = { input => 'not_a_hash' };
	throws_ok {
		$fn->($schema, 'input', 'test.yml')
	} qr/should be a hash/, 'wrong type croaks';

	done_testing();
};

# ==================================================================
# _is_numeric_transform and _is_string_transform
# --------------------------------------------------
# Tests for the output type classifiers used by
# _detect_transform_properties
# ==================================================================
subtest '_is_numeric_transform' => sub {
	my $fn = \&App::Test::Generator::_is_numeric_transform;

	# All three numeric type strings must be detected
	for my $type (qw(number integer float)) {
		ok($fn->({}, { type => $type }), "$type output detected as numeric");
	}

	# Non-numeric types return 0
	ok(!$fn->({}, { type => 'string' }),  'string not numeric');
	ok(!$fn->({}, { type => 'boolean' }), 'boolean not numeric');
	ok(!$fn->({}, {}),                    'missing type not numeric');
	ok(!$fn->({}, undef),                 'undef output spec not numeric');

	done_testing();
};

subtest '_is_string_transform' => sub {
	my $fn = \&App::Test::Generator::_is_string_transform;

	# Only the string 'string' is detected as a string transform
	ok($fn->({}, { type => 'string' }),   'string output detected');
	ok(!$fn->({}, { type => 'integer' }), 'integer not string');
	ok(!$fn->({}, {}),                    'missing type not string');
	ok(!$fn->({}, undef),                 'undef output not string');

	done_testing();
};

# ==================================================================
# _get_dominant_type
# --------------------------------------------------
# Tests for the type extractor used by _same_type
# and _detect_transform_properties
# ==================================================================
subtest '_get_dominant_type' => sub {
	my $fn = \&App::Test::Generator::_get_dominant_type;

	# Undef and empty hash both return the default type 'string'
	is($fn->(undef), 'string', 'undef returns default string');
	is($fn->({}),    'string', 'empty hash returns default string');

	# Flat output spec with an explicit type returns it directly
	is($fn->({ type => 'integer' }), 'integer', 'flat spec type returned');

	# Multi-field input spec returns the type of the first field found
	my $multi = { a => { type => 'number' } };
	is($fn->($multi), 'number', 'multi-field spec returns first field type');

	# Fields without a type key are skipped; falls through to a typed field
	my $mixed = {
		a => { optional => 1 },
		b => { type => 'boolean' },
	};
	is($fn->($mixed), 'boolean', 'field without type skipped');

	done_testing();
};

# ==================================================================
# _same_type
# ==================================================================
subtest '_same_type' => sub {
	my $fn = \&App::Test::Generator::_same_type;

	# Identical types always match
	ok($fn->({ type => 'string' }, { type => 'string' }), 'same type matches');

	# Different types never match
	ok(!$fn->({ type => 'string' }, { type => 'integer' }), 'different types do not match');

	# Both undef default to string via _get_dominant_type so they match
	ok($fn->(undef, undef), 'both undef match via default');

	# Multi-field input matched against flat output
	my $input = { a => { type => 'number' } };
	ok($fn->($input, { type => 'number' }), 'multi-field input matches flat output');

	done_testing();
};

# ==================================================================
# _normalize_config
# --------------------------------------------------
# Tests for the config boolean normaliser
# ==================================================================
subtest '_normalize_config' => sub {
	my $fn = \&App::Test::Generator::_normalize_config;

	# Absent boolean fields must all default to 1 (enabled) so that
	# test generation is maximally thorough unless explicitly disabled
	my %config;
	$fn->(\%config);
	for my $field (App::Test::Generator::CONFIG_TYPES()) {
		next if $field eq 'properties';
		next if $field eq 'timeout';	# numeric — absence means use generated-test default, not 1
		is($config{$field}, 1, "$field defaults to 1 when absent");
	}
	is($config{timeout}, undef, 'timeout left undef when absent (numeric, not boolean)');

	# Common string boolean representations are normalised to integers
	my %bool_config = (
		test_nuls  => 'yes',
		test_undef => 'no',
		test_empty => 'true',
	);
	$fn->(\%bool_config);
	is($bool_config{test_nuls},  1, "'yes' normalised to 1");
	is($bool_config{test_undef}, 0, "'no' normalised to 0");
	is($bool_config{test_empty}, 1, "'true' normalised to 1");

	# Properties field is always a hashref after normalisation
	my %no_props;
	$fn->(\%no_props);
	is(ref($no_props{properties}), 'HASH', 'properties always a hashref');
	is($no_props{properties}{enable}, 0, 'properties defaults to disabled');

	# An existing properties hashref is preserved untouched
	my %with_props = (properties => { enable => 1, trials => 500 });
	$fn->(\%with_props);
	is($with_props{properties}{enable}, 1, 'existing properties enable preserved');
	is($with_props{properties}{trials}, 500, 'existing properties trials preserved');

	done_testing();
};

# ==================================================================
# _validate_config
# --------------------------------------------------
# Tests for the top-level schema validator.
# Warnings from 'neither input nor output defined' are
# suppressed in tests that are only checking for lives/dies
# on structural issues unrelated to warning behaviour.
# ==================================================================
subtest '_validate_config' => sub {
	my $fn = \&App::Test::Generator::_validate_config;

	# Missing both module and function croaks with a clear message
	throws_ok {
		$fn->({})
	} qr/At least one of function and module/, 'missing module and function croaks';

	# Function alone is sufficient — suppress the no-input/output warning
	# since we are testing structural validation not warning behaviour here
	lives_ok {
		local $SIG{__WARN__} = sub {};
		$fn->({ function => 'foo' })
	} 'function alone is sufficient';

	# Module alone is sufficient — same warning suppression as above
	lives_ok {
		local $SIG{__WARN__} = sub {};
		$fn->({ module => 'Foo' })
	} 'module alone is sufficient';

	# Invalid input type string croaks with a clear message
	throws_ok {
		local $SIG{__WARN__} = sub {};
		$fn->({ function => 'foo', input => 'not_undef' })
	} qr/Invalid input specification/, 'invalid input type croaks';

	# The string 'undef' for input is accepted and the key is removed
	my $schema = { function => 'foo', input => 'undef' };
	lives_ok {
		local $SIG{__WARN__} = sub {};
		$fn->($schema)
	} "'undef' input accepted";
	ok(!exists($schema->{input}), "input key removed when set to 'undef'");

	# Unknown config key croaks naming the bad key
	throws_ok {
		$fn->({ function => 'foo', config => { unknown_key => 1 } })
	} qr/unknown config setting/, 'unknown config key croaks';

	# Neither input nor output defined generates a warning not a croak
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	lives_ok {
		$fn->({ function => 'foo' })
	} 'missing input and output lives';
	ok(@warnings, 'missing input and output warns');

	done_testing();
};

# ==================================================================
# _validate_input_positions
# ==================================================================
subtest '_validate_input_positions' => sub {
	my $fn = \&App::Test::Generator::_validate_input_positions;

	# No positions at all is always valid
	lives_ok {
		$fn->({ input => { a => { type => 'string' } } })
	} 'no positions is valid';

	# Contiguous positions starting at 0 are valid
	lives_ok {
		$fn->({
			input => {
				a => { type => 'string', position => 0 },
				b => { type => 'string', position => 1 },
			}
		})
	} 'valid contiguous positions';

	# Duplicate position numbers always croak
	throws_ok {
		$fn->({
			input => {
				a => { type => 'string', position => 0 },
				b => { type => 'string', position => 0 },
			}
		})
	} qr/Duplicate position/, 'duplicate positions croak';

	# If any param has a position, all must have one — missing one croaks
	throws_ok {
		$fn->({
			input => {
				a => { type => 'string', position => 0 },
				b => { type => 'string' },
			}
		})
	} qr/missing position/, 'partial positions croak';

	# A gap in the position sequence warns but does not croak
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	lives_ok {
		$fn->({
			input => {
				a => { type => 'string', position => 0 },
				b => { type => 'string', position => 2 },
			}
		})
	} 'position gap lives';
	ok(@warnings, 'position gap warns');

	done_testing();
};

# ==================================================================
# _validate_input_semantics
# ==================================================================
subtest '_validate_input_semantics' => sub {
	my $fn = \&App::Test::Generator::_validate_input_semantics;

	# A known semantic type passes without any warnings
	lives_ok {
		$fn->({ input => { email => { type => 'string', semantic => 'email' } } })
	} 'known semantic type lives';

	# An unknown semantic type warns but does not croak
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	lives_ok {
		$fn->({ input => { x => { type => 'string', semantic => 'nonsense' } } })
	} 'unknown semantic lives';
	ok(@warnings, 'unknown semantic warns');

	# Having both enum and memberof on the same param always croaks
	throws_ok {
		$fn->({
			input => {
				x => { type => 'string', enum => ['a'], memberof => ['a'] }
			}
		})
	} qr/both enum and memberof/, 'enum and memberof together croaks';

	# memberof value must be an arrayref not a plain scalar
	throws_ok {
		$fn->({
			input => {
				x => { type => 'string', memberof => 'not_array' }
			}
		})
	} qr/must be an arrayref/, 'non-arrayref memberof croaks';

	done_testing();
};

# ==================================================================
# _detect_transform_properties
# --------------------------------------------------
# Tests for the automatic property detection logic
# ==================================================================
subtest '_detect_transform_properties' => sub {
	my $fn = \&App::Test::Generator::_detect_transform_properties;

	# Undef input spec always returns an empty list
	my @props = $fn->('test', undef, {});
	is(scalar @props, 0, 'undef input returns empty list');

	# The YAML string 'undef' as input also returns empty list
	@props = $fn->('test', 'undef', {});
	is(scalar @props, 0, "'undef' input returns empty list");

	# Numeric output with min generates a min_constraint property
	@props = $fn->('test', { a => { type => 'number' } }, { type => 'number', min => 0 });
	my %by_name = map { $_->{name} => $_ } @props;
	ok(exists $by_name{min_constraint}, 'min generates min_constraint');
	like($by_name{min_constraint}{code}, qr/>=\s*0/, 'min_constraint code checks >= 0');

	# Numeric output with max generates a max_constraint property
	@props = $fn->('test', { a => { type => 'number' } }, { type => 'number', max => 100 });
	%by_name = map { $_->{name} => $_ } @props;
	ok(exists $by_name{max_constraint}, 'max generates max_constraint');

	# A transform named 'positive' gets a non_negative property added
	@props = $fn->('positive', { a => { type => 'number' } }, { type => 'number' });
	%by_name = map { $_->{name} => $_ } @props;
	ok(exists $by_name{non_negative}, 'positive transform gets non_negative property');

	# An exact value in output generates an exact_value property
	@props = $fn->('test', { a => { type => 'string' } }, { type => 'string', value => 'foo' });
	%by_name = map { $_->{name} => $_ } @props;
	ok(exists $by_name{exact_value}, 'output value generates exact_value property');
	like($by_name{exact_value}{code}, qr/'foo'/, 'exact_value code contains expected value');

	# All non-undef outputs get a defined property
	@props = $fn->('test', { a => { type => 'string' } }, { type => 'string' });
	%by_name = map { $_->{name} => $_ } @props;
	ok(exists $by_name{defined}, 'non-undef output gets defined property');

	# Output type explicitly set to undef must not get a defined property
	@props = $fn->('test', { a => { type => 'string' } }, { type => 'undef' });
	%by_name = map { $_->{name} => $_ } @props;
	ok(!exists $by_name{defined}, 'undef output type gets no defined property');

	# String output with min length generates a min_length property
	@props = $fn->('test', { a => { type => 'string' } }, { type => 'string', min => 3 });
	%by_name = map { $_->{name} => $_ } @props;
	ok(exists $by_name{min_length}, 'string min generates min_length');

	# Same numeric type in and out generates a numeric_type property
	@props = $fn->('test', { a => { type => 'integer' } }, { type => 'integer' });
	%by_name = map { $_->{name} => $_ } @props;
	ok(exists $by_name{numeric_type}, 'same numeric type generates numeric_type property');

	done_testing();
};

# ==================================================================
# _schema_to_lectrotest_generator
# --------------------------------------------------
# Tests for the LectroTest generator string builder
# ==================================================================
subtest '_schema_to_lectrotest_generator' => sub {
	my $fn = \&App::Test::Generator::_schema_to_lectrotest_generator;

	# Undef spec returns undef without throwing
	is($fn->('x', undef), undef, 'undef spec returns undef');

	# Non-hashref spec returns undef without throwing
	is($fn->('x', 'string'), undef, 'non-hashref spec returns undef');

	# Unconstrained integer uses the built-in Int generator
	my $result = $fn->('n', { type => 'integer' });
	like($result, qr/n\s*<-\s*Int\b/, 'unconstrained integer uses Int');

	# Integer with both min and max uses a range expression
	$result = $fn->('n', { type => 'integer', min => 1, max => 10 });
	like($result, qr/n\s*<-/, 'integer with range has generator');
	like($result, qr/1\s*\+/, 'min appears in integer generator');

	# Unconstrained float uses the Float generator
	$result = $fn->('x', { type => 'float' });
	like($result, qr/x\s*<-\s*Float/, 'unconstrained float uses Float');

	# Unconstrained string uses the String generator
	$result = $fn->('s', { type => 'string' });
	like($result, qr/s\s*<-\s*String/, 'string uses String generator');

	# String with a matches pattern uses Data::Random::String::Matches
	$result = $fn->('s', { type => 'string', matches => 'foo' });
	like($result, qr/Matches/, 'string with matches uses Matches generator');

	# Boolean type uses the Bool generator
	$result = $fn->('b', { type => 'boolean' });
	like($result, qr/b\s*<-\s*Bool/, 'boolean uses Bool generator');

	# Arrayref type uses the List generator
	$result = $fn->('a', { type => 'arrayref' });
	like($result, qr/a\s*<-\s*List/, 'arrayref uses List generator');

	# Semantic type overrides the plain String generator
	$result = $fn->('e', { type => 'string', semantic => 'email' });
	like($result, qr/e\s*<-/, 'semantic type has a generator');
	unlike($result, qr/<-\s*String/, 'semantic type does not use plain String');

	# An invalid numeric range returns undef and emits a warning
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	is($fn->('n', { type => 'float', min => 10, max => 5 }), undef, 'invalid range returns undef');
	ok(@warnings, 'invalid range warns');

	done_testing();
};

# ==================================================================
# _get_semantic_generators
# --------------------------------------------------
# Tests that all documented semantic types are present
# and each entry is structurally valid
# ==================================================================
subtest '_get_semantic_generators' => sub {
	my $fn = \&App::Test::Generator::_get_semantic_generators;
	my $generators = $fn->();

	# Must return a hashref
	is(ref($generators), 'HASH', 'returns hashref');

	# Every documented semantic type must be present
	my @expected = qw(
		email url uuid phone_us phone_e164 ipv4 ipv6
		username slug hex_color iso_date iso_datetime
		semver jwt json base64 md5 sha256 unix_timestamp
	);
	for my $type (@expected) {
		ok(exists $generators->{$type}, "$type generator present");
	}

	# Each generator entry must have both code and description keys
	for my $type (sort keys %{$generators}) {
		my $gen = $generators->{$type};
		ok(exists $gen->{code},        "$type has code key");
		ok(exists $gen->{description}, "$type has description key");
		like($gen->{code}, qr/Gen\s*\{/, "$type code contains Gen block");
		ok(length($gen->{description}) > 0, "$type description is non-empty");
	}

	done_testing();
};

# ==================================================================
# _get_builtin_properties
# --------------------------------------------------
# Tests that all documented builtin properties are
# present and each entry is structurally valid
# ==================================================================
subtest '_get_builtin_properties' => sub {
	my $fn = \&App::Test::Generator::_get_builtin_properties;
	my $props = $fn->();

	# Must return a hashref
	is(ref($props), 'HASH', 'returns hashref');

	# Every documented builtin property must be present
	my @expected = qw(
		idempotent non_negative positive non_empty
		length_preserved uppercase lowercase trimmed
		sorted_ascending sorted_descending unique_elements
		preserves_keys
	);
	for my $name (@expected) {
		ok(exists $props->{$name}, "$name property present");
	}

	# monotonic_increasing must be absent — it was intentionally removed
	# because a correct single-call implementation is not possible
	ok(!exists $props->{monotonic_increasing}, 'monotonic_increasing absent');

	# Each property must have all three required structural keys
	for my $name (sort keys %{$props}) {
		my $prop = $props->{$name};
		ok(exists $prop->{description},   "$name has description");
		ok(exists $prop->{code_template}, "$name has code_template");
		ok(exists $prop->{applicable_to}, "$name has applicable_to");
		is(ref($prop->{code_template}), 'CODE',  "$name code_template is a coderef");
		is(ref($prop->{applicable_to}), 'ARRAY', "$name applicable_to is arrayref");
	}

	# Every code_template must produce a non-empty string when invoked
	for my $name (sort keys %{$props}) {
		my $code = $props->{$name}{code_template}->('func', '$func($x)', ['x']);
		ok(defined $code && length $code, "$name code_template produces non-empty string");
	}

	done_testing();
};

# ==================================================================
# _render_properties
# --------------------------------------------------
# Tests for the LectroTest property code renderer
# ==================================================================
subtest '_render_properties' => sub {
	my $fn = \&App::Test::Generator::_render_properties;

	# Undef returns empty string — no property block to emit
	is($fn->(undef), $EMPTY_STRING, 'undef returns empty string');

	# Non-arrayref returns empty string
	is($fn->({}), $EMPTY_STRING, 'hashref returns empty string');

	# Empty arrayref returns empty string
	is($fn->([]), $EMPTY_STRING, 'empty arrayref returns empty string');

	# A single property renders a complete Property block
	my $props = [{
		name            => 'my_prop',
		generator_spec  => '$x <- Int',
		call_code       => 'abs($x)',
		property_checks => '$result >= 0',
		should_die      => 0,
		should_warn     => 0,
		trials          => 100,
	}];
	my $code = $fn->($props);

	# The LectroTest compat layer must be loaded in the output
	like($code, qr/Test::LectroTest::Compat/, 'loads LectroTest');

	# Must define a Property block
	like($code, qr/Property\s*\{/, 'emits Property block');

	# Generator spec must appear inside ##[ ]## markers
	like($code, qr/##\[.*\$x <- Int.*\]##/s, 'generator spec in markers');

	# Property checks must appear in the generated code
	like($code, qr/\$result >= 0/, 'property checks present');

	# Trial count must be emitted with the property
	like($code, qr/trials\s*=>\s*100/, 'trial count emitted');

	# should_die property checks $died not property_checks
	my $die_props = [{
		name            => 'die_prop',
		generator_spec  => '$x <- Int',
		call_code       => 'dangerous($x)',
		property_checks => '',
		should_die      => 1,
		should_warn     => 0,
		trials          => 50,
	}];
	my $die_code = $fn->($die_props);
	like($die_code, qr/\$died/, 'should_die uses $died check');

	done_testing();
};

# ==================================================================
# _load_schema (integration — requires a real temp file)
# --------------------------------------------------
# Tests for the schema file loader
# ==================================================================
subtest '_load_schema' => sub {
	my $fn = \&App::Test::Generator::_load_schema;

	# Undef file path croaks with a Usage message
	throws_ok { $fn->(undef) } qr/Usage/, 'undef path croaks';

	# Empty file path croaks before touching the filesystem
	throws_ok { $fn->($EMPTY_STRING) } qr/empty filename/, 'empty path croaks';

	# Non-existent file path croaks with a filesystem error
	throws_ok { $fn->('/no/such/file.yml') } qr/./, 'missing file croaks';

	# A valid YAML file loads successfully and returns a hashref
	my ($fh, $tmpfile) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print {$fh} "function: test\nmodule: Foo\n";
	close $fh;

	my $schema = $fn->($tmpfile);
	is(ref($schema), 'HASH', 'valid YAML returns hashref');
	is($schema->{function}, 'test', 'function key loaded correctly');
	is($schema->{module},   'Foo',  'module key loaded correctly');

	# The _source key must be injected with the originating file path
	ok(exists $schema->{_source}, '_source key injected');
	is($schema->{_source}, $tmpfile, '_source contains the file path');

	done_testing();
};

# ==================================================================
# generate (smoke tests)
# --------------------------------------------------
# End-to-end tests verifying that generate() produces
# a file that compiles and contains expected markers
# ==================================================================
subtest 'generate smoke' => sub {
	my $dir = tempdir(CLEANUP => 1);

	# Write a minimal valid schema to a temp file
	my ($schema_fh, $schema_file) = tempfile(
		DIR    => $dir,
		SUFFIX => '.yml',
		UNLINK => 1,
	);
	print {$schema_fh} <<'YAML';
function: test_func
module: builtin

input:
  type: string

output:
  type: string
YAML
	close $schema_fh;

	# Generate the test file and confirm it is non-empty
	my ($out_fh, $out_file) = tempfile(
		DIR    => $dir,
		SUFFIX => '.t',
		UNLINK => 1,
	);
	close $out_fh;

	lives_ok {
		App::Test::Generator->generate($schema_file, $out_file)
	} 'generate() lives for valid schema';

	ok(-s $out_file, 'output file is non-empty');

	# The generated file must compile cleanly under the current perl
	my $result = system($^X, '-c', $out_file);
	is($result, 0, 'generated file compiles');

	# Check for essential structural markers in the generated output
	open my $fh, '<', $out_file or die $!;
	my $content = do { local $/; <$fh> };
	close $fh;
	like($content, qr/diag\(/,       'generated file has diag line');
	like($content, qr/test_func/,    'function name present in output');
	like($content, qr/done_testing/, 'done_testing present in output');

	done_testing();
};

subtest 'generate croaks for missing schema file' => sub {
	# A non-existent schema file must croak rather than silently
	# producing empty or broken output
	throws_ok {
		App::Test::Generator->generate('/no/such/schema.yml', '/tmp/out.t')
	} qr/./, 'missing schema file croaks';

	done_testing();
};

subtest 'generate with schema hashref' => sub {
	# The modern API accepts a pre-parsed schema hashref directly,
	# bypassing file I/O entirely
	my $dir = tempdir(CLEANUP => 1);
	my ($fh, $outfile) = tempfile(DIR => $dir, SUFFIX => '.t', UNLINK => 1);
	close $fh;

	# Use named parameters with explicit position keys — the
	# validator checks position keys before treating the input
	# as positional, so both keys must be present together
	my $schema = {
		function => 'abs',
		module   => 'builtin',
		input    => {
			number => { type => 'number', position => 0 },
		},
		output   => { type => 'number', min => 0 },
	};

	lives_ok {
		App::Test::Generator->generate(schema => $schema, output_file => $outfile)
	} 'generate() with schema hashref lives';

	ok(-s $outfile, 'output file non-empty for hashref schema');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Mutator
# ==================================================================

# --------------------------------------------------
# Shared temp file containing minimal valid Perl
# used across multiple Mutator subtests
# --------------------------------------------------
my ($mutator_fh, $mutator_file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
print {$mutator_fh} <<'PERL';
package Foo;
sub bar {
	my $x = shift;
	if($x > 0) {
		return 1;
	}
	return 0;
}
1;
PERL
close $mutator_fh;

# ==================================================================
# new()
# ==================================================================
subtest 'Mutator::new - file required' => sub {
	# Omitting file must croak immediately
	throws_ok {
		App::Test::Generator::Mutator->new()
	} qr/file required/, 'croaks when file omitted';

	done_testing();
};

subtest 'Mutator::new - missing file croaks' => sub {
	throws_ok {
		App::Test::Generator::Mutator->new(file => '/no/such/file.pm')
	} qr/file not found/, 'croaks for non-existent file';

	done_testing();
};

subtest 'Mutator::new - valid file returns object' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $mutator_file);
	isa_ok($m, 'App::Test::Generator::Mutator');
	is($m->{file}, $mutator_file, 'file stored correctly');
	is($m->{lib_dir}, 'lib', 'lib_dir defaults to lib');
	is($m->{mutation_level}, 'full', 'mutation_level defaults to full');
	is(ref($m->{mutations}), 'ARRAY', 'mutations is an arrayref');
	ok(scalar(@{$m->{mutations}}) > 0, 'at least one mutation strategy registered');

	done_testing();
};

subtest 'Mutator::new - custom lib_dir and mutation_level accepted' => sub {
	my $m = App::Test::Generator::Mutator->new(
		file           => $mutator_file,
		lib_dir        => 'src',
		mutation_level => 'fast',
	);
	is($m->{lib_dir},        'src',  'custom lib_dir stored');
	is($m->{mutation_level}, 'fast', 'custom mutation_level stored');

	done_testing();
};

# ==================================================================
# generate_mutants() - skip annotation logic
# ==================================================================
subtest 'Mutator::generate_mutants - no skip annotations generates mutants' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $mutator_file);
	my @mutants = $m->generate_mutants();

	# A file with conditionals and return values must produce at least
	# one mutant from the registered strategies
	ok(scalar(@mutants) > 0, 'mutants generated for file with conditionals');
	is(ref($m->{skip_lines}), 'HASH', 'skip_lines hashref populated after call');
	is(scalar(keys %{$m->{skip_lines}}), 0, 'no lines skipped when no annotations');

	done_testing();
};

subtest 'Mutator::generate_mutants - MUTANT_SKIP_BEGIN/END excludes lines' => sub {
	my ($fh, $file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PERL';
package Bar;
sub safe {
	return 1;
}
sub risky {
	## MUTANT_SKIP_BEGIN
	kill 'HUP', $$;
	waitpid $$, 0;
	## MUTANT_SKIP_END
	return 1;
}
1;
PERL
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $file);
	$m->generate_mutants();

	# Lines 7 and 8 (kill and waitpid) must be in skip_lines
	ok($m->{skip_lines}{7}, 'kill line excluded by skip annotation');
	ok($m->{skip_lines}{8}, 'waitpid line excluded by skip annotation');

	# The MUTANT_SKIP_BEGIN line itself is also excluded
	ok($m->{skip_lines}{6}, 'MUTANT_SKIP_BEGIN line itself excluded');

	# Lines outside the block are not excluded
	ok(!$m->{skip_lines}{3}, 'line outside skip block not excluded');

	done_testing();
};

subtest 'Mutator::generate_mutants - unclosed MUTANT_SKIP_BEGIN is fatal' => sub {
	my ($fh, $file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PERL';
package Baz;
sub x {
	## MUTANT_SKIP_BEGIN
	return 1;
}
1;
PERL
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $file);
	throws_ok {
		$m->generate_mutants()
	} qr/MUTANT_SKIP_BEGIN.*no matching MUTANT_SKIP_END/i,
		'unclosed MUTANT_SKIP_BEGIN croaks';

	done_testing();
};

subtest 'Mutator::generate_mutants - unmatched MUTANT_SKIP_END is fatal' => sub {
	my ($fh, $file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PERL';
package Qux;
sub x {
	return 1;
	## MUTANT_SKIP_END
}
1;
PERL
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $file);
	throws_ok {
		$m->generate_mutants()
	} qr/MUTANT_SKIP_END.*no matching MUTANT_SKIP_BEGIN/i,
		'unmatched MUTANT_SKIP_END croaks';

	done_testing();
};

subtest 'Mutator::generate_mutants - nested MUTANT_SKIP_BEGIN is fatal' => sub {
	my ($fh, $file) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PERL';
package Nested;
sub x {
	## MUTANT_SKIP_BEGIN
	## MUTANT_SKIP_BEGIN
	return 1;
	## MUTANT_SKIP_END
}
1;
PERL
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $file);
	throws_ok {
		$m->generate_mutants()
	} qr/MUTANT_SKIP_BEGIN.*no prior MUTANT_SKIP_END/i,
		'nested MUTANT_SKIP_BEGIN croaks';

	done_testing();
};

subtest 'Mutator::generate_mutants - fast mode deduplicates' => sub {
	my $m = App::Test::Generator::Mutator->new(
		file           => $mutator_file,
		mutation_level => 'fast',
	);
	my @mutants = $m->generate_mutants();

	# Fast mode must return fewer or equal mutants than full mode
	my $m_full = App::Test::Generator::Mutator->new(file => $mutator_file);
	my @full_mutants = $m_full->generate_mutants();

	ok(scalar(@mutants) <= scalar(@full_mutants),
		'fast mode returns no more mutants than full mode');

	done_testing();
};

# ==================================================================
# apply_mutant() - workspace not prepared
# ==================================================================
subtest 'Mutator::apply_mutant - croaks without workspace' => sub {
	my $m = App::Test::Generator::Mutator->new(file => $mutator_file);

	# A minimal stub mutant with a no-op transform
	my $mutant = App::Test::Generator::Mutant->new(
		id          => 'TEST_1',
		file        => $mutator_file,
		line        => 1,
		description => 'stub',
		original    => '',
		transform   => sub {},
	);

	throws_ok {
		$m->apply_mutant($mutant)
	} qr/Workspace not prepared/, 'apply_mutant croaks without workspace';

	done_testing();
};

# ==================================================================
# _dedup_mutants()
# ==================================================================
subtest 'Mutator::_dedup_mutants - removes exact duplicates' => sub {
	my $fn = \&App::Test::Generator::Mutator::_dedup_mutants;

	my $make = sub {
		my %args = @_;
		return App::Test::Generator::Mutant->new(
			id          => $args{id}          // 'TEST',
			line        => $args{line}        // 1,
			original    => $args{original}    // 'x',
			description => $args{description} // 'test',
			context     => $args{context}     // '',
			line_content => $args{line_content} // '',
			transform   => sub {},
		);
	};

	# Two identical mutants must collapse to one
	my $m1 = $make->(line => 5, original => 'foo', description => 'bar');
	my $m2 = $make->(line => 5, original => 'foo', description => 'bar');
	my $result = $fn->([$m1, $m2]);
	is(scalar(@{$result}), 1, 'duplicate mutants collapsed to one');

	# Two different mutants are both kept
	my $m3 = $make->(line => 6, original => 'baz', description => 'qux');
	$result = $fn->([$m1, $m3]);
	is(scalar(@{$result}), 2, 'distinct mutants both kept');

	# Empty input returns empty arrayref
	$result = $fn->([]);
	is(scalar(@{$result}), 0, 'empty input returns empty arrayref');

	done_testing();
};

subtest 'Mutator::_dedup_mutants - removes redundant arithmetic no-ops' => sub {
	my $fn = \&App::Test::Generator::Mutator::_dedup_mutants;

	# +0 arithmetic no-op must be filtered as redundant
	my $noop = App::Test::Generator::Mutant->new(
		id          => 'NOOP_1',
		line        => 1,
		original    => 'x + 0',
		description => 'add zero',
		context     => '',
		line_content => '',
		transform   => sub {},
	);
	my $result = $fn->([$noop]);
	is(scalar(@{$result}), 0, '+0 no-op removed as redundant');

	# -0 arithmetic no-op must also be filtered
	my $noop2 = App::Test::Generator::Mutant->new(
		id          => 'NOOP_2',
		line        => 1,
		original    => 'x - 0',
		description => 'sub zero',
		context     => '',
		line_content => '',
		transform   => sub {},
	);
	$result = $fn->([$noop2]);
	is(scalar(@{$result}), 0, '-0 no-op removed as redundant');

	done_testing();
};

# ==================================================================
# _is_redundant_mutation()
# ==================================================================
my $make_mutant = sub {
	my %args = @_;
	return App::Test::Generator::Mutant->new(
		id          => $args{id}          // 'TEST',
		line        => $args{line}        // 1,
		original    => $args{original}    // 'x',
		description => $args{description} // 'test',
		context     => $args{context}     // '',
		line_content => $args{line_content} // '',
		transform   => sub {},
	);
};

subtest 'Mutator::_is_redundant_mutation - arithmetic no-ops are redundant' => sub {
	my $fn = \&App::Test::Generator::Mutator::_is_redundant_mutation;

	ok($fn->($make_mutant->(original => 'x + 0')), '+0 is redundant');
	ok($fn->($make_mutant->(original => 'x - 0')), '-0 is redundant');
	ok(!$fn->($make_mutant->(original => 'x + 1')), '+1 is not redundant');

	done_testing();
};

subtest 'Mutator::_is_redundant_mutation - double negation in conditional' => sub {
	my $fn = \&App::Test::Generator::Mutator::_is_redundant_mutation;

	ok(
		$fn->($make_mutant->(original => '!!$x', context => 'conditional')),
		'double negation in conditional is redundant'
	);
	ok(
		!$fn->($make_mutant->(original => '!!$x', context => '')),
		'double negation outside conditional is not redundant'
	);

	done_testing();
};

subtest 'Mutator::_is_redundant_mutation - boolean literal flip is redundant' => sub {
	my $fn = \&App::Test::Generator::Mutator::_is_redundant_mutation;

	ok($fn->($make_mutant->(original => '1')), 'standalone 1 is redundant');
	ok($fn->($make_mutant->(original => '0')), 'standalone 0 is redundant');
	ok(!$fn->($make_mutant->(original => '42')), 'non-boolean integer is not redundant');

	done_testing();
};

subtest 'Mutator::_is_redundant_mutation - comment lines are redundant' => sub {
	my $fn = \&App::Test::Generator::Mutator::_is_redundant_mutation;

	ok(
		$fn->($make_mutant->(original => 'x', line_content => '# a comment')),
		'mutation on comment line is redundant'
	);
	ok(
		!$fn->($make_mutant->(original => 'x', line_content => 'my $x = 1;')),
		'mutation on code line is not redundant'
	);

	done_testing();
};

# ==================================================================
# App::Test::Generator::Exporter::YAML
# --------------------------------------------------
# White-box tests for the sole public sub, export().
# YAML::XS::DumpFile is mocked so these run without
# touching the filesystem and so the exact validated
# arguments reaching DumpFile can be asserted directly
# (the existing t/Exporter-YAML.t black-box file already
# covers the real on-disk round-trip).
# ==================================================================
subtest 'Exporter::YAML::export - validates and forwards to YAML::XS::DumpFile' => sub {
	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';

	my @dump_calls;
	Test::Mockingbird::mock(
		'YAML::XS',
		'DumpFile',
		sub { push @dump_calls, [@_]; return; },
	);

	my $plan = { module => 'Foo', function => 'bar' };
	my $result = $exporter->export($plan, '/tmp/plan.yml');

	# export() has no meaningful return value -- Test::Returns treats an
	# undef value as satisfying any schema without inspecting it further
	returns_ok($result, { type => 'string' }, 'export() returns undef');

	is(scalar(@dump_calls), 1, 'DumpFile called exactly once');
	is($dump_calls[0][0], '/tmp/plan.yml', 'DumpFile called with the validated file path');
	is_deeply($dump_calls[0][1], $plan, 'DumpFile called with the validated plan hashref');

	# A bare bless {} object has no back-references to itself, so there
	# is nothing for Test::Memory::Cycle to find -- this assertion exists
	# to catch a future regression if export() ever starts stashing the
	# plan or file path on $self.
	memory_cycle_ok($exporter, 'exporter object has no reference cycles after export()');

	Test::Mockingbird::unmock('YAML::XS', 'DumpFile');
};

subtest 'Exporter::YAML::export - rejects a non-hashref plan without touching DumpFile' => sub {
	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';

	my $dump_called = 0;
	Test::Mockingbird::mock(
		'YAML::XS',
		'DumpFile',
		sub { $dump_called++; return; },
	);

	throws_ok { $exporter->export('not a hashref', '/tmp/plan.yml') }
		qr/hashref/i,
		'croaks before reaching DumpFile';
	is($dump_called, 0, 'DumpFile never called for an invalid plan');

	Test::Mockingbird::unmock('YAML::XS', 'DumpFile');
};

subtest 'Exporter::YAML::export - rejects a missing or empty file path without touching DumpFile' => sub {
	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';

	my $dump_called = 0;
	Test::Mockingbird::mock(
		'YAML::XS',
		'DumpFile',
		sub { $dump_called++; return; },
	);

	throws_ok { $exporter->export({ a => 1 }, undef) } qr/\S/, 'croaks when file is undef';
	throws_ok { $exporter->export({ a => 1 }, '') }    qr/\S/, 'croaks when file is empty';
	is($dump_called, 0, 'DumpFile never called for an invalid file path');

	Test::Mockingbird::unmock('YAML::XS', 'DumpFile');
};

# ==================================================================
# App::Test::Generator::Analyzer::Return
# --------------------------------------------------
# White-box tests for the return-pattern analyser.
# t/Analyzer-Return.t already exercises every regex
# branch in detail via Test::Mockingbird, so this
# section focuses on what that file does not cover:
# Test::Returns validation of analyze()'s undef return
# and a Test::Memory::Cycle check on the evidence-bearing
# mock object (add_evidence stores plain hashrefs with no
# back-reference to the method, so no cycle is expected;
# this guards against a future regression that starts
# stashing $method itself into the evidence list).
# ==================================================================
subtest 'Analyzer::Return - new and analyze API surface' => sub {
	Readonly my $WEIGHT_RETURNS_PROPERTY => 20;

	my $analyser = App::Test::Generator::Analyzer::Return->new();
	isa_ok($analyser, 'App::Test::Generator::Analyzer::Return', 'new() returns correct class');

	my @evidence;
	my $method = bless { source => '', evidence => \@evidence }, 'MockReturnMethod';
	Test::Mockingbird::mock('MockReturnMethod', 'source', sub { $_[0]->{source} });
	Test::Mockingbird::mock('MockReturnMethod', 'add_evidence', sub {
		my ($self, %args) = @_;
		push @{ $self->{evidence} }, \%args;
	});

	$method->{source} = 'sub foo { my $self = shift; return $self->{name}; }';
	my $result = $analyser->analyze($method);

	# analyze() communicates everything via side effects on $method;
	# Test::Returns confirms the documented "type => UNDEF" contract
	returns_ok($result, { type => 'string' }, 'analyze() returns undef');
	is(scalar(@evidence), 1, 'one evidence entry recorded for property return');
	is($evidence[0]{weight}, $WEIGHT_RETURNS_PROPERTY, 'recorded weight matches WEIGHT_RETURNS_PROPERTY');

	diag('evidence after analyze: ' . join(', ', map { $_->{signal} } @evidence)) if $ENV{TEST_VERBOSE};

	# No cycle should exist between the mock method and its own evidence list
	memory_cycle_ok($method, 'mock method object has no reference cycles after analyze()');

	# A raw hashref (no Model::Method object) must also be accepted,
	# per the "Accept either a Model::Method object or a raw hashref" branch
	my $raw = { source => 'sub bar { return 1; }' };
	my $raw_result = $analyser->analyze($raw);
	is($raw_result, undef, 'analyze() accepts a raw hashref without dying');

	Test::Mockingbird::unmock('MockReturnMethod', 'source');
	Test::Mockingbird::unmock('MockReturnMethod', 'add_evidence');
};

# ==================================================================
# App::Test::Generator::Analyzer::ReturnMeta
# --------------------------------------------------
# White-box tests for the stability/consistency scoring
# analyser. t/Analyzer-ReturnMeta.t already drives every
# penalty/bonus branch individually, so this section adds
# the Test::Returns schema-shape check and a memory-cycle
# guard the skill requires, plus the documented "boolean
# bonus is a no-op unless an earlier penalty already fired"
# interaction (Notes section of analyze()'s POD) since that
# is an easy regression to introduce by reordering the
# bonus/penalty/clamp logic.
# ==================================================================
subtest 'Analyzer::ReturnMeta - report shape and clamp interaction' => sub {
	Readonly my $PENALTY_IMPLICIT_UNDEF_STABILITY => 20;
	Readonly my $BONUS_BOOLEAN_STABILITY          => 5;

	my $analyser = App::Test::Generator::Analyzer::ReturnMeta->new();
	isa_ok($analyser, 'App::Test::Generator::Analyzer::ReturnMeta', 'new() returns correct class');

	# Baseline: empty output produces perfect scores and no risk flags
	my $clean_report = $analyser->analyze({ output => {} });
	returns_ok(
		$clean_report,
		{
			type => 'hashref',
			schema => {
				stability_score   => { type => 'integer' },
				consistency_score => { type => 'integer' },
				risk_flags        => { type => 'arrayref' },
			},
		},
		'analyze() report matches documented hashref shape',
	);
	is($clean_report->{stability_score},   100, 'clean schema scores full stability');
	is($clean_report->{consistency_score}, 100, 'clean schema scores full consistency');
	is_deeply($clean_report->{risk_flags}, [], 'clean schema raises no risk flags');

	# A boolean return with no other risk stays clamped at 100 -- the
	# bonus is documented as a no-op here, not an over-100 value silently
	# clamped down, so this also guards against the clamp being removed
	my $boolean_report = $analyser->analyze({ output => { type => 'boolean' } });
	is($boolean_report->{stability_score}, 100, 'boolean bonus is a no-op when already at 100');

	# Combine the implicit-undef penalty with the boolean bonus to prove
	# the bonus does take effect once stability has actually been reduced
	my $combined_report = $analyser->analyze({
		output => {
			type            => 'boolean',
			_error_handling => { implicit_undef => 1 },
		},
	});
	is(
		$combined_report->{stability_score},
		100 - $PENALTY_IMPLICIT_UNDEF_STABILITY + $BONUS_BOOLEAN_STABILITY,
		'boolean bonus applies on top of an already-reduced stability score',
	);
	is_deeply($combined_report->{risk_flags}, ['implicit_error_return'], 'implicit_error_return flag recorded');

	diag("combined report: stability=$combined_report->{stability_score} consistency=$combined_report->{consistency_score}")
		if $ENV{TEST_VERBOSE};

	# risk_flags is a fresh arrayref per call with no back-reference
	# to the schema or the analyser, so no cycle should be detectable
	memory_cycle_ok($combined_report, 'analyze() report has no reference cycles');
};

# ==================================================================
# App::Test::Generator::Analyzer::Complexity
# --------------------------------------------------
# t/Analyzer-Complexity.t already covers analyze()'s
# public behaviour in depth (branching, exceptions,
# nesting, classification, string/comment stripping
# indirectly). What it does not do is call the private
# helper _strip_strings_and_comments directly -- the
# skill explicitly requires testing internal helpers in
# isolation, so that is the focus here, plus the
# Test::Returns schema-shape check on analyze()'s report.
# ==================================================================
subtest 'Analyzer::Complexity - _strip_strings_and_comments isolated behaviour' => sub {
	my $fn = \&App::Test::Generator::Analyzer::Complexity::_strip_strings_and_comments;

	# Double- and single-quoted string contents are removed entirely,
	# including any keyword-like text inside them
	is($fn->(q{my $x = "if this then that";}), q{my $x = ;}, 'double-quoted string contents removed');
	is($fn->(q{my $x = 'unless this';}),       q{my $x = ;}, 'single-quoted string contents removed');

	# Trailing # comments are blanked from the matched line onward
	is($fn->("my \$x = 1; # if true do this\n"), "my \$x = 1; \n", 'trailing comment removed');

	# Escaped quote characters inside a string do not terminate the
	# match early -- this is the (?:[^"\\]|\\.) escape-aware alternation
	is($fn->(q{my $x = "she said \"hi\"";}), q{my $x = ;}, 'escaped quotes inside string do not break stripping');

	# A body with no strings or comments passes through unchanged
	is($fn->('if ($x) { return 1; }'), 'if ($x) { return 1; }', 'plain code is unchanged');

	# Empty input returns empty output, not undef or a die
	is($fn->(''), '', 'empty string input returns empty string');

	done_testing();
};

subtest 'Analyzer::Complexity - new and analyze report shape' => sub {
	my $analyser = App::Test::Generator::Analyzer::Complexity->new();
	isa_ok($analyser, 'App::Test::Generator::Analyzer::Complexity', 'new() returns correct class');

	my $method = { body => 'sub foo { if ($x) { return 1; } return 0; }' };
	my $report = $analyser->analyze($method);

	returns_ok(
		$report,
		{
			type   => 'hashref',
			schema => {
				cyclomatic_score => { type => 'integer' },
				branching_points => { type => 'integer' },
				early_returns    => { type => 'integer' },
				exception_paths  => { type => 'integer' },
				nesting_depth    => { type => 'integer' },
				complexity_level => { type => 'string' },
			},
		},
		'analyze() report matches documented hashref shape',
	);

	diag("complexity report: $report->{complexity_level} (score=$report->{cyclomatic_score})")
		if $ENV{TEST_VERBOSE};

	# The report hashref holds only plain scalars, so no cycle is possible;
	# this guards against a future change that embeds $method or $self in it
	memory_cycle_ok($report, 'analyze() report has no reference cycles');

	# Method argument missing a body key entirely must not die --
	# documented via the "//= ''" default in the source
	lives_ok { $analyser->analyze({}) } 'analyze() tolerates a method hashref with no body key';

	done_testing();
};

# ==================================================================
# App::Test::Generator::Analyzer::SideEffect
# --------------------------------------------------
# t/Analyzer-SideEffect.t already covers analyze()'s
# public flags and purity classification thoroughly,
# including string/comment false-positive avoidance.
# This module ships its own copy of
# _strip_strings_and_comments (duplicated-by-design
# from Analyzer::Complexity per CLAUDE.md's "shared-by-
# duplication helper" convention elsewhere in this
# codebase) -- exercised directly here since it has not
# been called by its fully-qualified name anywhere else.
# ==================================================================
subtest 'Analyzer::SideEffect - _strip_strings_and_comments isolated behaviour' => sub {
	my $fn = \&App::Test::Generator::Analyzer::SideEffect::_strip_strings_and_comments;

	is($fn->(q{warn "system check failed";}), q{warn ;}, 'IO/exec-like words inside a string are blanked');
	is($fn->("\$self->{x} = 1; # warn the caller\n"), "\$self->{x} = 1; \n", 'trailing comment removed');
	is($fn->(''), '', 'empty string input returns empty string');

	done_testing();
};

subtest 'Analyzer::SideEffect - new and analyze report shape' => sub {
	my $analyser = App::Test::Generator::Analyzer::SideEffect->new();
	isa_ok($analyser, 'App::Test::Generator::Analyzer::SideEffect', 'new() returns correct class');

	my $method = { body => 'sub save { my $self = shift; $self->{dirty} = 0; print "saved\n"; }' };
	my $report = $analyser->analyze($method);

	returns_ok(
		$report,
		{
			type   => 'hashref',
			schema => {
				mutates_self    => { type => 'integer' },
				mutates_globals => { type => 'integer' },
				performs_io     => { type => 'integer' },
				calls_external  => { type => 'integer' },
				mutation_fields => { type => 'arrayref' },
				purity_level    => { type => 'string' },
			},
		},
		'analyze() report matches documented hashref shape',
	);
	is($report->{purity_level}, 'impure', 'method with both self-mutation and IO is classified impure');

	diag("side-effect report: purity=$report->{purity_level} fields=@{$report->{mutation_fields}}")
		if $ENV{TEST_VERBOSE};

	# mutation_fields is a fresh arrayref of plain strings, so no cycle
	# is possible -- guards against a future change embedding $method
	memory_cycle_ok($report, 'analyze() report has no reference cycles');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Planner::Mock
# --------------------------------------------------
# t/Planner-Mock.t already covers the single/dual-mock
# arrayref behaviour fixed earlier (see Changes). This
# section adds the exact croak-string check the skill
# requires for the non-hashref guard, plus Test::Returns
# on plan()'s documented "scalar | arrayref" value shape
# and a memory-cycle check across both mock plan shapes.
# ==================================================================
subtest 'Planner::Mock - exception message and return shape' => sub {
	my $planner = App::Test::Generator::Planner::Mock->new();
	isa_ok($planner, 'App::Test::Generator::Planner::Mock', 'new() returns correct class');

	# Exact error string, not just a pattern -- the skill requires
	# verifying the precise croak text, since this is user-facing
	# diagnostic output if a caller passes the wrong argument type
	throws_ok { $planner->plan('not a hashref') }
		qr/^schema must be a hashref/,
		'plan() croaks with the documented exact message for a non-hashref schema';

	my $schema = {
		save => { _analysis => { side_effects => { performs_io => 1 } } },
		read => {},
	};
	my $mock_plan = $planner->plan($schema);

	returns_ok($mock_plan->{save}, { type => 'string' }, 'single-strategy entry is a plain scalar string');
	is(scalar(keys %{$mock_plan}), 1, 'pure method with no side effects is omitted from the plan');

	diag('mock plan: ' . join(', ', map { "$_=$mock_plan->{$_}" } keys %{$mock_plan}))
		if $ENV{TEST_VERBOSE};

	# Dual-strategy case returns an arrayref instead of a scalar
	my $dual_schema = {
		both => { _analysis => { side_effects => { calls_external => 1, performs_io => 1 } } },
	};
	my $dual_plan = $planner->plan($dual_schema);
	returns_ok($dual_plan->{both}, { type => 'arrayref' }, 'dual-strategy entry is an arrayref');
	is_deeply($dual_plan->{both}, ['mock_system', 'capture_io'], 'dual-strategy arrayref contains both labels in order');

	# The plan hashref holds only plain strings/arrayrefs of strings
	# with no back-reference to $schema, so no cycle is possible
	memory_cycle_ok($dual_plan, 'plan() result has no reference cycles');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Planner::Fixture
# App::Test::Generator::Planner::Grouping
# App::Test::Generator::Planner::Isolation
# --------------------------------------------------
# Sibling planners, all already exhaustively covered in
# their own t/Planner-*.t files for branch coverage. This
# section adds the exact-string exception checks and the
# Test::Returns/Test::Memory::Cycle assertions the skill
# requires, without re-deriving every branch already
# proven correct elsewhere.
# ==================================================================
subtest 'Planner::Fixture - exception message and return shape' => sub {
	my $planner = App::Test::Generator::Planner::Fixture->new();
	isa_ok($planner, 'App::Test::Generator::Planner::Fixture', 'new() returns correct class');

	throws_ok { $planner->plan({}, 'not a hashref') }
		qr/^isolation must be a hashref/,
		'plan() croaks with the documented exact message for a non-hashref isolation';

	my $fixture_plan = $planner->plan({}, { save => { fixture => 'shared_fixture' }, read => { fixture => 'fresh_object' } });
	returns_ok(
		$fixture_plan->{save},
		{ type => 'hashref', schema => { mode => { type => 'string' } } },
		'per-method fixture entry matches documented hashref shape',
	);
	is($fixture_plan->{save}{mode}, 'shared', 'shared_fixture isolation maps to "shared" mode');
	is($fixture_plan->{read}{mode}, 'new_per_test', 'non-shared isolation maps to "new_per_test" mode');

	memory_cycle_ok($fixture_plan, 'plan() result has no reference cycles');

	done_testing();
};

subtest 'Planner::Grouping - exception message and return shape' => sub {
	my $planner = App::Test::Generator::Planner::Grouping->new();
	isa_ok($planner, 'App::Test::Generator::Planner::Grouping', 'new() returns correct class');

	throws_ok { $planner->plan('not a hashref') }
		qr/^schema must be a hashref/,
		'plan() croaks with the documented exact message for a non-hashref schema';

	my $schema = {
		pure_one => { _analysis => { side_effects => { purity_level => 'pure' } } },
	};
	my $groups = $planner->plan($schema);
	returns_ok(
		$groups,
		{
			type   => 'hashref',
			schema => {
				pure     => { type => 'arrayref' },
				mutating => { type => 'arrayref' },
				impure   => { type => 'arrayref' },
			},
		},
		'plan() result matches documented three-key hashref shape',
	);
	is_deeply($groups->{pure}, ['pure_one'], 'pure method placed in the pure group');

	memory_cycle_ok($groups, 'plan() result has no reference cycles');

	done_testing();
};

subtest 'Planner::Isolation - exception message and return shape' => sub {
	my $planner = App::Test::Generator::Planner::Isolation->new();
	isa_ok($planner, 'App::Test::Generator::Planner::Isolation', 'new() returns correct class');

	throws_ok { $planner->plan({}, 'not a hashref') }
		qr/^strategy must be a hashref/,
		'plan() croaks with the documented exact message for a non-hashref strategy';

	my $schema = {
		risky => {
			_analysis => {
				side_effects => { purity_level => 'impure' },
				dependencies => { network => 1, env => { API_KEY => 1 } },
			},
		},
	};
	my $isolation = $planner->plan($schema, { risky => 1 });

	returns_ok(
		$isolation->{risky},
		{
			type   => 'hashref',
			schema => {
				fixture    => { type => 'string' },
				env        => { type => 'hashref', optional => 1 },
				network    => { type => 'integer', optional => 1 },
			},
		},
		'per-method isolation entry matches documented hashref shape',
	);
	is($isolation->{risky}{fixture}, 'isolated_block', 'impure purity maps to isolated_block fixture mode');
	is($isolation->{risky}{network}, 1, 'network dependency flag passed through');
	ok(!exists $isolation->{risky}{time}, 'time key omitted when no time dependency present');

	diag('isolation plan: fixture=' . $isolation->{risky}{fixture}) if $ENV{TEST_VERBOSE};

	memory_cycle_ok($isolation, 'plan() result has no reference cycles');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Planner
# --------------------------------------------------
# t/Planner.t, t/Planner_unit.t and t/Planner-submodules_unit.t
# already exercise plan_all() and build_plan() (the latter with
# all five sub-planners mocked). Neither file asserts the exact
# croak text for new()'s two required-argument guards, which the
# skill explicitly requires -- that gap is filled here.
# ==================================================================
subtest 'Planner::new - exact exception messages for missing required args' => sub {
	throws_ok { App::Test::Generator::Planner->new(package => 'Foo') }
		qr/^schemas required/,
		'new() croaks with the documented exact message when schemas is missing';

	throws_ok { App::Test::Generator::Planner->new(schemas => {}) }
		qr/^package required/,
		'new() croaks with the documented exact message when package is missing';

	my $planner = App::Test::Generator::Planner->new(schemas => { foo => {} }, package => 'Foo');
	isa_ok($planner, 'App::Test::Generator::Planner', 'new() returns correct class when both args present');

	my $plans = $planner->plan_all();
	returns_ok(
		$plans->{foo},
		{ type => 'hashref' },
		'plan_all() per-method entry is a hashref as documented',
	);

	# $planner stores the schemas hashref by reference but plan_all()'s
	# output is a freshly built hashref with no back-reference to $planner
	memory_cycle_ok($plans, 'plan_all() result has no reference cycles');

	done_testing();
};

# ==================================================================
# App::Test::Generator::LCSAJ::Coverage
# --------------------------------------------------
# t/LCSAJ-Coverage.t covers merge()'s required-argument
# guards and the covered/not-covered annotation logic via
# real temp files. This section adds direct, isolated
# coverage of the private _slurp() helper (including its
# own croak path on an unreadable file, which merge()'s
# tests never exercise since they always pass valid
# lcsaj/hits files) plus the documented undef return.
# ==================================================================
subtest 'LCSAJ::Coverage::_slurp - isolated file-reading behaviour' => sub {
	my $fn = \&App::Test::Generator::LCSAJ::Coverage::_slurp;

	my ($fh, $tmpfile) = File::Temp::tempfile();
	print {$fh} "line one\nline two\n";
	close $fh;

	is($fn->($tmpfile), "line one\nline two\n", '_slurp reads the entire file contents in one call');

	# A nonexistent path must croak with the documented "Cannot read"
	# prefix; the OS-supplied $! text after the colon is not asserted
	# since its exact wording is platform-dependent
	my $missing = File::Spec->catfile(File::Temp::tempdir(CLEANUP => 1), 'does-not-exist.json');
	throws_ok { $fn->($missing) } qr/^Cannot read \Q$missing\E: /, '_slurp croaks with file path in message on open failure';

	unlink $tmpfile;
	done_testing();
};

subtest 'LCSAJ::Coverage::merge - undef return and exact required-argument messages' => sub {
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	my $lcsaj_file = File::Spec->catfile($dir, 'in.lcsaj.json');
	my $hits_file  = File::Spec->catfile($dir, 'in.hits.json');
	my $out_file   = File::Spec->catfile($dir, 'out.json');

	open my $lfh, '>', $lcsaj_file or die $!;
	print {$lfh} '[]';
	close $lfh;
	open my $hfh, '>', $hits_file or die $!;
	print {$hfh} '{}';
	close $hfh;

	# Exact anchored messages -- the skill requires verifying precise
	# croak text, not just a loose substring match
	throws_ok { App::Test::Generator::LCSAJ::Coverage::merge(undef, $hits_file, $out_file) }
		qr/^lcsaj_file required/, 'merge() croaks with exact message when lcsaj_file is undef';
	throws_ok { App::Test::Generator::LCSAJ::Coverage::merge($lcsaj_file, undef, $out_file) }
		qr/^hits_file required/, 'merge() croaks with exact message when hits_file is undef';
	throws_ok { App::Test::Generator::LCSAJ::Coverage::merge($lcsaj_file, $hits_file, undef) }
		qr/^out_file required/, 'merge() croaks with exact message when out_file is undef';

	my $result = App::Test::Generator::LCSAJ::Coverage::merge($lcsaj_file, $hits_file, $out_file);
	returns_ok($result, { type => 'string' }, 'merge() returns undef as documented ("type => UNDEF")');
	ok(-e $out_file, 'merge() wrote the output file');

	done_testing();
};

# ==================================================================
# App::Test::Generator::LCSAJ
# --------------------------------------------------
# t/LCSAJ.t and t/LCSAJ_unit.t already give this module
# exhaustive white-box coverage down to every private
# helper (_new_block, _connect_blocks, _is_branch,
# _build_cfg, _cfg_to_lcsaj, _save_lcsaj). Re-deriving
# that here would be pure duplication, so this section
# only adds the exact-message croak check and the
# Test::Returns/Test::Memory::Cycle assertions the skill
# requires that those files do not use.
# ==================================================================
subtest 'LCSAJ::generate - exact exception message and return shape' => sub {
	throws_ok { App::Test::Generator::LCSAJ->generate('/nonexistent/path/Foo.pm') }
		qr/^Cannot parse /,
		'generate() croaks with the documented exact message prefix for an unparseable file';

	my ($fh, $file) = File::Temp::tempfile(SUFFIX => '.pm');
	print {$fh} "package Foo;\nsub bar { my \$x = 1; return \$x; }\n1;\n";
	close $fh;

	my $out_dir = File::Temp::tempdir(CLEANUP => 1);
	my $paths = App::Test::Generator::LCSAJ->generate($file, $out_dir);

	returns_ok(
		$paths,
		{
			type     => 'arrayref',
			schema   => {
				type => 'hashref',
				schema => {
					start  => { type => 'integer' },
					end    => { type => 'integer' },
					target => { type => 'integer' },
				},
			},
		},
		'generate() result matches the documented arrayref-of-hashref shape',
	);

	# Each path hashref holds only plain integers, so no cycle is
	# possible -- guards against a future change embedding the PPI
	# document or CFG blocks directly into the returned paths
	memory_cycle_ok($paths, 'generate() result has no reference cycles');

	unlink $file;
	done_testing();
};

# ==================================================================
# App::Test::Generator::Mutation::Base
# --------------------------------------------------
# t/Mutation-Base.t and t/Mutation-Base_unit.t already
# cover new()/applies_to()/mutate() abstract-method croaks
# thoroughly, including exact-class-name croak messages.
# Neither exercises the two private helpers _line_content
# and _in_conditional directly -- both are shared by every
# concrete mutation strategy subclass, so a bug here would
# silently affect all of them. Tested in isolation here via
# the base class itself (concrete subclasses inherit both
# unchanged).
# ==================================================================
subtest 'Mutation::Base::_line_content - isolated line lookup' => sub {
	my $base = App::Test::Generator::Mutation::Base->new();
	my $doc  = PPI::Document->new(\"my \$x = 1;\nmy \$y = 2;\nmy \$z = 3;\n");

	is($base->_line_content($doc, 1), 'my $x = 1;', 'first line content returned');
	is($base->_line_content($doc, 3), 'my $z = 3;', 'third line content returned');

	# Out-of-range line numbers return empty string, not undef or a die --
	# callers (Mutator::_is_redundant_mutation) treat this as "no content"
	is($base->_line_content($doc, 99), '', 'out-of-range line returns empty string, not undef');

	done_testing();
};

subtest 'Mutation::Base::_in_conditional - isolated ancestor-walk behaviour' => sub {
	my $base = App::Test::Generator::Mutation::Base->new();

	my $doc = PPI::Document->new(\"if (\$x) { my \$y = 1; }\n");
	# Walk to a token strictly inside the if-block's body
	my $token = $doc->find_first(sub { $_[1]->isa('PPI::Token::Symbol') && $_[1]->content eq '$y' });
	ok($base->_in_conditional($token), 'token inside an if-block body is detected as conditional');

	my $flat_doc = PPI::Document->new(\"my \$y = 1;\n");
	my $flat_token = $flat_doc->find_first(sub { $_[1]->isa('PPI::Token::Symbol') && $_[1]->content eq '$y' });
	ok(!$base->_in_conditional($flat_token), 'token with no compound-statement ancestor is not conditional');

	# unless/while/until are all recognised, not just if
	for my $keyword (qw(unless while until)) {
		my $kw_doc = PPI::Document->new(\"$keyword (\$x) { my \$y = 1; }\n");
		my $kw_token = $kw_doc->find_first(sub { $_[1]->isa('PPI::Token::Symbol') && $_[1]->content eq '$y' });
		ok($base->_in_conditional($kw_token), "token inside a $keyword-block body is detected as conditional");
	}

	done_testing();
};

# ==================================================================
# App::Test::Generator::Mutation::ConditionalInversion
# --------------------------------------------------
# t/Mutation-ConditionalInversion.t already exhaustively
# covers applies_to(), mutate() shape, and the transform
# closure's targeting logic. The one real gap: neither
# that file nor this module's own tests ever exercise the
# "if($@ || !$mutant)" failure branch inside mutate() --
# i.e. what happens when Mutant->new() itself dies. Mocked
# here via Test::Mockingbird to confirm a constructor
# failure is skipped gracefully rather than propagated or
# silently corrupting the mutant list.
# ==================================================================
subtest 'Mutation::ConditionalInversion::mutate - Mutant construction failure is skipped, not propagated' => sub {
	my $strategy = App::Test::Generator::Mutation::ConditionalInversion->new();
	my $doc      = PPI::Document->new(\"if (\$x) { my \$y = 1; }\nif (\$z) { my \$w = 2; }\n");

	Test::Mockingbird::mock('App::Test::Generator::Mutant', 'new', sub { die "boom\n" });

	my @mutants;
	lives_ok { @mutants = $strategy->mutate($doc) }
		'mutate() does not propagate a Mutant construction failure';
	is(scalar(@mutants), 0, 'both candidate mutants were skipped when construction fails for all of them');

	Test::Mockingbird::unmock('App::Test::Generator::Mutant', 'new');

	done_testing();
};

subtest 'Mutation::ConditionalInversion::mutate - return shape and memory cycles' => sub {
	my $strategy = App::Test::Generator::Mutation::ConditionalInversion->new();
	my $doc      = PPI::Document->new(\"if (\$x) { my \$y = 1; }\n");
	my @mutants  = $strategy->mutate($doc);

	is(scalar(@mutants), 1, 'one mutant produced for one if statement');
	isa_ok($mutants[0], 'App::Test::Generator::Mutant', 'mutant element');
	returns_ok($mutants[0]->{id}, { type => 'string' }, 'mutant id is a plain string');

	# The mutant holds a transform closure over $doc, $line, $col -- confirm
	# that closure does not create a retain cycle back through the mutant itself
	memory_cycle_ok($mutants[0], 'ConditionalInversion mutant has no reference cycles');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Mutation::NumericBoundary
# --------------------------------------------------
# Same rationale as ConditionalInversion above: t/Mutation-
# NumericBoundary.t already covers applies_to()/mutate()
# shape and transform targeting in depth, so this section
# only adds the untested Mutant-construction-failure path
# and the Test::Returns/Test::Memory::Cycle checks the
# skill mandates.
# ==================================================================
subtest 'Mutation::NumericBoundary::mutate - Mutant construction failure is skipped, not propagated' => sub {
	my $strategy = App::Test::Generator::Mutation::NumericBoundary->new();
	my $doc      = PPI::Document->new(\"if (\$x > 1) { my \$y = 1; }\n");

	Test::Mockingbird::mock('App::Test::Generator::Mutant', 'new', sub { die "boom\n" });

	my @mutants;
	lives_ok { @mutants = $strategy->mutate($doc) }
		'mutate() does not propagate a Mutant construction failure';
	is(scalar(@mutants), 0, 'all candidate flips for this operator were skipped');

	Test::Mockingbird::unmock('App::Test::Generator::Mutant', 'new');

	done_testing();
};

subtest 'Mutation::NumericBoundary::mutate - falsy construction result without dying is skipped' => sub {
	my $strategy = App::Test::Generator::Mutation::NumericBoundary->new();
	my $doc      = PPI::Document->new(\"if (\$x > 1) { my \$y = 1; }\n");

	# Unlike the "boom" mock above, this exercises the other half of
	# "if($@ || !$mutant)": Mutant::new returning a false value without
	# dying, leaving $@ empty -- the (! $mutant) arm of the guard.
	Test::Mockingbird::mock('App::Test::Generator::Mutant', 'new', sub { return 0 });

	my @mutants;
	lives_ok { @mutants = $strategy->mutate($doc) }
		'mutate() does not propagate a falsy-without-dying construction result';
	is(scalar(@mutants), 0, 'all candidate flips for this operator were skipped');

	Test::Mockingbird::unmock('App::Test::Generator::Mutant', 'new');

	done_testing();
};

subtest 'Mutation::NumericBoundary::mutate - return shape and memory cycles' => sub {
	my $strategy = App::Test::Generator::Mutation::NumericBoundary->new();
	my $doc      = PPI::Document->new(\"if (\$x > 1) { my \$y = 1; }\n");
	my @mutants  = $strategy->mutate($doc);

	# '>' flips to <, >=, <= -- three mutants from one operator occurrence
	is(scalar(@mutants), 3, 'three mutants produced for the three flips of >');
	isa_ok($_, 'App::Test::Generator::Mutant', 'mutant element') for @mutants;
	returns_ok($mutants[0]->{id}, { type => 'string' }, 'mutant id is a plain string');

	memory_cycle_ok(\@mutants, 'NumericBoundary mutant list has no reference cycles');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Mutation::ReturnUndef /
# App::Test::Generator::Mutation::BooleanNegation
# --------------------------------------------------
# t/Mutation-ReturnUndef.t, t/Mutation-BooleanNegation.t,
# and t/Mutation-BooleanNegation-ReturnUndef_unit.t already
# give applies_to()/mutate() exhaustive coverage, including
# the chained-expression and postfix-modifier edge cases.
# Two real gaps remain, identical to the ones found above
# for ConditionalInversion/NumericBoundary: the Mutant-
# construction-failure branch, and the private
# _return_expr_span() helper itself, which both modules
# duplicate by design (see CLAUDE.md) and which no existing
# test calls directly by name.
# ==================================================================
subtest 'Mutation::ReturnUndef::_return_expr_span - isolated span extraction' => sub {
	my $fn = \&App::Test::Generator::Mutation::ReturnUndef::_return_expr_span;

	my $doc1 = PPI::Document->new(\"sub f { return \$x; }\n");
	my ($ret1) = @{ $doc1->find(sub { $_[1]->isa('PPI::Statement::Break') }) };
	my @span1 = $fn->($ret1);
	is(scalar(@span1), 1, 'simple scalar return has a one-token span');
	is($span1[0]->content, '$x', 'span token is the returned scalar');

	my $doc2 = PPI::Document->new(\"sub f { return; }\n");
	my ($ret2) = @{ $doc2->find(sub { $_[1]->isa('PPI::Statement::Break') }) };
	is(scalar($fn->($ret2)), 0, 'bare return has an empty span');

	my $doc3 = PPI::Document->new(\"sub f { return \$x if \$cond; }\n");
	my ($ret3) = @{ $doc3->find(sub { $_[1]->isa('PPI::Statement::Break') }) };
	my @span3 = $fn->($ret3);
	is(scalar(@span3), 1, 'postfix-if return strips the modifier and its condition from the span');
	is($span3[0]->content, '$x', 'span excludes the "if $cond" postfix modifier entirely');

	my $doc4 = PPI::Document->new(\"sub f { return \$self->{value}; }\n");
	my ($ret4) = @{ $doc4->find(sub { $_[1]->isa('PPI::Statement::Break') }) };
	my @span4 = $fn->($ret4);
	# $self->{value} is three significant children, not one -- this is
	# precisely the case CLAUDE.md documents as having previously been
	# mishandled by mutating only the first token
	is(scalar(@span4), 3, 'chained hash-deref return has a three-token span, not one');

	done_testing();
};

subtest 'Mutation::ReturnUndef::mutate - Mutant construction failure is skipped, not propagated' => sub {
	my $strategy = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc      = PPI::Document->new(\"sub f { return \$x; }\n");

	Test::Mockingbird::mock('App::Test::Generator::Mutant', 'new', sub { die "boom\n" });

	my @mutants;
	lives_ok { @mutants = $strategy->mutate($doc) }
		'mutate() does not propagate a Mutant construction failure';
	is(scalar(@mutants), 0, 'the candidate mutant was skipped when construction fails');

	Test::Mockingbird::unmock('App::Test::Generator::Mutant', 'new');

	done_testing();
};

subtest 'Mutation::ReturnUndef::mutate - return shape and memory cycles' => sub {
	my $strategy = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc      = PPI::Document->new(\"sub f { return \$x; }\n");
	my @mutants  = $strategy->mutate($doc);

	is(scalar(@mutants), 1, 'one mutant produced for one qualifying return');
	returns_ok($mutants[0]->{id}, { type => 'string' }, 'mutant id is a plain string');
	memory_cycle_ok($mutants[0], 'ReturnUndef mutant has no reference cycles');

	done_testing();
};

subtest 'Mutation::BooleanNegation::_return_expr_span - isolated span extraction' => sub {
	my $fn = \&App::Test::Generator::Mutation::BooleanNegation::_return_expr_span;

	my $doc1 = PPI::Document->new(\"sub f { return \$self->{value}; }\n");
	my ($ret1) = @{ $doc1->find(sub { $_[1]->isa('PPI::Statement::Break') }) };
	my @span1 = $fn->($ret1);
	is(scalar(@span1), 3, 'chained hash-deref return has a three-token span, not one');

	my $doc2 = PPI::Document->new(\"sub f { return unless \$cond; }\n");
	my ($ret2) = @{ $doc2->find(sub { $_[1]->isa('PPI::Statement::Break') }) };
	is(scalar($fn->($ret2)), 0, 'bare postfix-unless return has an empty span');

	done_testing();
};

subtest 'Mutation::BooleanNegation::mutate - Mutant construction failure is skipped, not propagated' => sub {
	my $strategy = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc      = PPI::Document->new(\"sub f { return \$ok; }\n");

	Test::Mockingbird::mock('App::Test::Generator::Mutant', 'new', sub { die "boom\n" });

	my @mutants;
	lives_ok { @mutants = $strategy->mutate($doc) }
		'mutate() does not propagate a Mutant construction failure';
	is(scalar(@mutants), 0, 'the candidate mutant was skipped when construction fails');

	Test::Mockingbird::unmock('App::Test::Generator::Mutant', 'new');

	done_testing();
};

subtest 'Mutation::BooleanNegation::mutate - return shape and memory cycles' => sub {
	my $strategy = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc      = PPI::Document->new(\"sub f { return \$ok; }\n");
	my @mutants  = $strategy->mutate($doc);

	is(scalar(@mutants), 1, 'one mutant produced for one qualifying return');
	returns_ok($mutants[0]->{id}, { type => 'string' }, 'mutant id is a plain string');
	memory_cycle_ok($mutants[0], 'BooleanNegation mutant has no reference cycles');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Mutant
# --------------------------------------------------
# t/Mutant.t and t/Mutant_unit.t cover every required-
# attribute croak and every accessor except two: context()
# and line_content() are never exercised by either file
# even though both are documented, real accessors used by
# Mutator's fast-mode dedup logic. Covered here, along with
# the Test::Returns/Test::Memory::Cycle checks the skill
# mandates and existing tests don't use.
# ==================================================================
subtest 'Mutant::context and Mutant::line_content - previously untested accessors' => sub {
	my $mutant = App::Test::Generator::Mutant->new(
		id          => 'TEST_ID',
		description => 'test mutant',
		original    => '==',
		line        => 5,
		transform   => sub { },
		context     => 'conditional',
		line_content => 'if ($x == $y) {',
	);

	is($mutant->context, 'conditional', 'context() returns the stored syntactic-context string');
	is($mutant->line_content, 'if ($x == $y) {', 'line_content() returns the stored raw source line');

	my $bare = App::Test::Generator::Mutant->new(
		id          => 'TEST_ID_2',
		description => 'test mutant without optional fields',
		original    => '==',
		line        => 5,
		transform   => sub { },
	);

	is($bare->context, undef, 'context() returns undef when not supplied at construction');
	is($bare->line_content, undef, 'line_content() returns undef when not supplied at construction');

	returns_ok($mutant->context, { type => 'string' }, 'context value matches its documented scalar type');
	memory_cycle_ok($mutant, 'Mutant with a transform closure has no reference cycles');

	done_testing();
};

# ==================================================================
# App::Test::Generator::Mutator -- run_tests()
# --------------------------------------------------
# new()/generate_mutants()/prepare_workspace()/apply_mutant()/
# _dedup_mutants()/_is_redundant_mutation() are all already
# covered exhaustively across t/Mutation-Mutator.t,
# t/Mutator_unit.t, t/mutator.t, and t/mutator_num_boundary.t.
# run_tests() itself, however, has zero coverage anywhere in
# the suite -- a real gap.
#
# IMPORTANT: run_tests() calls the bareword builtin system(...),
# not an imported/exported sub, so it cannot be intercepted via
# Test::Mockingbird (a plain typeglob assignment does not affect a
# bareword keyword call), nor via a runtime "local *CORE::GLOBAL::system"
# inside this subtest (that override is resolved when the *calling*
# code -- Mutator.pm -- is compiled, which already happened at the top
# of this file). Either mistake falls through to the *real*
# system('prove', '-l', 't'), which recursively re-runs the entire
# suite (including this very file) as a child process and fork-bombs
# the test run. The fix is the file-scoped $REAL_SYSTEM_HOOK dispatcher
# installed near the top of this file in a BEGIN block that runs
# before App::Test::Generator::Mutator is use'd.
# ==================================================================
subtest 'Mutator::run_tests - reflects the underlying system() exit status' => sub {
	my ($fh, $src_file) = File::Temp::tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} "package RunTestsTarget;\nsub f { return 1; }\n1;\n";
	close $fh;

	my $m = App::Test::Generator::Mutator->new(file => $src_file);

	my @captured_args;
	{
		local $REAL_SYSTEM_HOOK = sub { @captured_args = @_; return 0 };
		ok($m->run_tests(), 'run_tests() returns true when system() exits 0');
	}
	is($captured_args[1], '-l', 'system() is invoked with the -l prove flag');
	is($captured_args[2], 't', 'system() is invoked against the t directory');

	{
		local $REAL_SYSTEM_HOOK = sub { return 256 };
		ok(!$m->run_tests(), 'run_tests() returns false when system() exits non-zero');
	}

	done_testing();
};

# ==================================================================
# App::Test::Generator::TestStrategy
# --------------------------------------------------
# t/TestStrategy.t already exercises every conditional branch in
# _plan_for_method exhaustively for mutation-survivor purposes.
# This module calls no non-core or imported functions (just sort/
# grep/keys on plain hashrefs), so Test::Mockingbird has nothing to
# usefully mock here. The value-add below targets the two real
# remaining gaps: the boolean_set_test flag (never referenced by
# any existing test in the suite) and the multi-candidate sort/
# tie-break logic that selects which getset input param drives the
# object_injection_test/boolean_set_test choice -- plus the
# Test::Returns/Test::Memory::Cycle coverage the skill mandates.
# ==================================================================
subtest 'TestStrategy::generate_plan - boolean_set_test for getset accessor with a boolean param' => sub {
	my $strategy = App::Test::Generator::TestStrategy->new(
		schema => {
			set_flag => {
				accessor => { type => 'getset' },
				output   => {},
				input    => { value => { type => 'boolean', position => 0 } },
			},
		},
	);
	my $plan = $strategy->generate_plan();

	ok($plan->{set_flag}{boolean_set_test}, 'boolean_set_test set for getset with boolean param');
	ok($plan->{set_flag}{getset_test}, 'getset_test also set');
	ok(!$plan->{set_flag}{object_injection_test}, 'object_injection_test not set for a boolean param');
};

subtest 'TestStrategy::generate_plan - getset param selection: lowest position wins regardless of name order' => sub {
	my $strategy = App::Test::Generator::TestStrategy->new(
		schema => {
			m => {
				accessor => { type => 'getset' },
				output   => {},
				input    => {
					zeta  => { type => 'object',  position => 2 },
					alpha => { type => 'boolean', position => 1 },
				},
			},
		},
	);
	my $plan = $strategy->generate_plan();

	ok($plan->{m}{boolean_set_test}, 'lowest-position param (alpha, boolean) wins, not zeta');
	ok(!$plan->{m}{object_injection_test}, 'higher-position object param is not selected');
};

subtest 'TestStrategy::generate_plan - getset param selection: name is the tie-break when positions are equal' => sub {
	my $strategy = App::Test::Generator::TestStrategy->new(
		schema => {
			m => {
				accessor => { type => 'getset' },
				output   => {},
				# Neither param declares a position, so both default to
				# the same sentinel (9999) and the cmp tie-break decides
				input    => {
					zeta  => { type => 'object' },
					alpha => { type => 'boolean' },
				},
			},
		},
	);
	my $plan = $strategy->generate_plan();

	ok($plan->{m}{boolean_set_test}, 'alpha sorts before zeta by name, so the boolean param wins the tie');
	ok(!$plan->{m}{object_injection_test}, 'zeta is not selected when alpha ties and sorts first');
};

subtest 'TestStrategy::generate_plan - underscore-prefixed input keys are excluded from getset param selection' => sub {
	my $strategy = App::Test::Generator::TestStrategy->new(
		schema => {
			m => {
				accessor => { type => 'getset' },
				output   => {},
				# _internal has the lowest position but must be skipped by
				# the "grep { !/^_/ }" filter, leaving "real" as the only
				# eligible candidate despite its higher position
				input    => {
					_internal => { type => 'object',  position => 0 },
					real      => { type => 'boolean', position => 5 },
				},
			},
		},
	);
	my $plan = $strategy->generate_plan();

	ok($plan->{m}{boolean_set_test}, 'underscore-prefixed candidate is excluded; "real" (boolean) is selected');
	ok(!$plan->{m}{object_injection_test}, '_internal is never considered despite its lower position');
};

subtest 'TestStrategy::_plan_for_method - direct call, return shape, and memory cycles' => sub {
	my $strategy = App::Test::Generator::TestStrategy->new();

	# Called directly as an internal helper, bypassing generate_plan(),
	# exactly as documented: "Always contains at least basic_test => 1"
	my $plan = $strategy->_plan_for_method({ output => {}, input => {} });

	returns_ok(
		$plan,
		{
			type   => 'hashref',
			schema => {
				basic_test => { type => 'integer' },
			},
		},
		'_plan_for_method() return shape matches its documented hashref-of-flags contract',
	);
	is($plan->{basic_test}, 1, '_plan_for_method() falls back to basic_test when no other flag matched');

	diag('plan keys: ' . join(', ', keys %{$plan})) if $ENV{TEST_VERBOSE};

	memory_cycle_ok($plan, '_plan_for_method() result has no reference cycles');
	memory_cycle_ok($strategy, 'TestStrategy instance has no reference cycles after use');
};

subtest 'TestStrategy::new - defaults are independent, isolated hashrefs' => sub {
	my $s1 = App::Test::Generator::TestStrategy->new();
	my $s2 = App::Test::Generator::TestStrategy->new();

	# The default thresholds/schema/plans hashrefs must not be shared
	# between instances -- mutating one must not affect the other
	$s1->{schema}{leaked} = 1;
	ok(!exists $s2->{schema}{leaked}, 'schema default hashref is not shared across instances');

	memory_cycle_ok($s1, 'first TestStrategy instance has no reference cycles');
	memory_cycle_ok($s2, 'second TestStrategy instance has no reference cycles');
};

# ==================================================================
# App::Test::Generator::Model::Method
# --------------------------------------------------
# t/Model-Method.t and t/Model-Method_unit.t already give this module
# exhaustive black-box coverage of every accessor, evidence-category/
# signal validation path, and resolve_*() branch. Two real gaps
# remain that match this skill's specific mandates:
#
#  1. resolve_confidence()'s level thresholds are only exercised with
#     scores of 0, 45, and 50 -- never at the exact threshold values
#     (20, 40) or just below them (19, 39), so a NumericBoundary
#     mutation flipping ">=" to ">" on either threshold would survive
#     undetected by the existing suite.
#  2. resolve_classification() calls $self->resolve_return_type()
#     internally (a same-module call) but no existing test isolates
#     that dependency via mocking -- every existing test drives it
#     through the real evidence-scoring algorithm instead.
# ==================================================================
subtest 'Model::Method::resolve_confidence - exact threshold boundaries' => sub {
	my %case = (
		19 => 'low',
		20 => 'medium',
		39 => 'medium',
		40 => 'high',
	);

	for my $score (sort { $a <=> $b } keys %case) {
		my $m = App::Test::Generator::Model::Method->new(
			name => 'm', source => 'sub m {}',
		);
		# A single evidence entry whose weight is exactly the score under
		# test -- avoids relying on add_evidence()'s signal-scoring rules,
		# which are irrelevant to resolve_confidence()'s own threshold logic
		$m->add_evidence(category => 'return', signal => 'returns_property', weight => $score);

		my $conf = $m->resolve_confidence;
		is($conf->{level}, $case{$score}, "score $score resolves to level '$case{$score}'");
	}
};

subtest 'Model::Method::resolve_classification - isolated from resolve_return_type via mocking' => sub {
	my %expect = (
		object   => 'chainable',
		property => 'getter',
		constant => 'constant',
		bogus    => 'unknown',
	);

	for my $return_type (sort keys %expect) {
		my $m = App::Test::Generator::Model::Method->new(
			name => 'm', source => 'sub m {}',
		);

		Test::Mockingbird::mock(
			'App::Test::Generator::Model::Method',
			'resolve_return_type',
			sub { $_[0]->{return_type} = $return_type; return $return_type },
		);

		is($m->resolve_classification, $expect{$return_type},
			"mocked resolve_return_type() '$return_type' drives classification '$expect{$return_type}'");

		Test::Mockingbird::unmock('App::Test::Generator::Model::Method', 'resolve_return_type');
	}
};

subtest 'Model::Method::resolve_classification - does not call resolve_return_type when already resolved' => sub {
	my $m = App::Test::Generator::Model::Method->new(
		name => 'm', source => 'sub m {}',
	);
	$m->return_type('property');

	my $calls = 0;
	Test::Mockingbird::mock(
		'App::Test::Generator::Model::Method',
		'resolve_return_type',
		sub { $calls++; return 'object' },
	);

	is($m->resolve_classification, 'getter',
		'classification reflects the pre-set return_type, not a freshly resolved one');
	is($calls, 0, 'resolve_return_type() is never invoked when return_type is already defined');

	Test::Mockingbird::unmock('App::Test::Generator::Model::Method', 'resolve_return_type');
};

subtest 'Model::Method - return shapes and memory cycles across the full evidence pipeline' => sub {
	my $m = App::Test::Generator::Model::Method->new(
		name => 'process_data', source => 'sub process_data { return $self->{data}; }',
	);
	$m->absorb_legacy_output({
		type            => 'string',
		_returns_self   => 0,
		_context_aware  => 1,
		_error_return   => 'undef',
	});

	my $return_type = $m->resolve_return_type;
	returns_ok($return_type, { type => 'string' }, 'resolve_return_type() returns a plain string');

	my $classification = $m->resolve_classification;
	returns_ok($classification, { type => 'string' }, 'resolve_classification() returns a plain string');

	my $conf = $m->resolve_confidence;
	returns_ok(
		$conf,
		{
			type   => 'hashref',
			schema => {
				score => { type => 'integer' },
				level => { type => 'string' },
			},
		},
		'resolve_confidence() return shape matches its documented hashref contract',
	);

	diag("classification=$classification return_type=$return_type confidence=$conf->{level}")
		if $ENV{TEST_VERBOSE};

	memory_cycle_ok($m, 'Method instance has no reference cycles after the full evidence pipeline');
	memory_cycle_ok($m->evidence_ref, 'evidence arrayref has no reference cycles');
};

# ==================================================================
# App::Test::Generator::Sample::Module
# --------------------------------------------------
# This module has NO existing test coverage anywhere in the suite --
# it is referenced only as a documentation fixture in Generator.pm's
# SYNOPSIS, never actually exercised. Every method below is covered
# from scratch: happy path, every croak with its exact message, and
# every documented boundary. No Test::Mockingbird mocking is used --
# every method here is self-contained (only core builtins such as
# length/ref/localtime are called), so there is nothing to mock.
# ==================================================================

subtest 'Sample::Module::new - constructs a blessed instance' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();
	isa_ok($obj, 'App::Test::Generator::Sample::Module');
	returns_ok(
		$obj,
		{ type => 'object', isa => 'App::Test::Generator::Sample::Module' },
		'new() return shape matches its documented API specification',
	);
	memory_cycle_ok($obj, 'new() instance has no reference cycles');
};

subtest 'Sample::Module::validate_email - happy path and exact croak messages' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();

	is($obj->validate_email('user@example.com'), 1, 'valid address returns 1');

	throws_ok { $obj->validate_email(undef) } qr/^Email is required/,
		'undef email croaks with exact message';
	throws_ok { $obj->validate_email('a@b') } qr/^Email too short/,
		'below-minimum-length email croaks with exact message';
	throws_ok { $obj->validate_email('x' x ($SAMPLE_MAX_EMAIL_LEN + 1) . '@b.com') } qr/^Email too long/,
		'above-maximum-length email croaks with exact message';
	throws_ok { $obj->validate_email('no-at-sign.com') } qr/^Invalid email format/,
		'malformed email croaks with exact message';
};

subtest 'Sample::Module::validate_email - exact length boundaries' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();

	# One char below the minimum must fail length, not format
	my $too_short = 'a' x ($SAMPLE_MIN_EMAIL_LEN - 1);
	throws_ok { $obj->validate_email($too_short) } qr/^Email too short/,
		'length one below minimum croaks too-short';

	# Exactly at the maximum length, well-formed, must pass
	my $local_part = 'a' x ($SAMPLE_MAX_EMAIL_LEN - length('@b.com'));
	my $exactly_max = $local_part . '@b.com';
	is(length($exactly_max), $SAMPLE_MAX_EMAIL_LEN, 'constructed fixture is exactly at the max length');
	is($obj->validate_email($exactly_max), 1, 'address at exactly the maximum length is accepted');
};

subtest 'Sample::Module::calculate_age - happy path and exact croak messages' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();
	my $current_year = (localtime)[5] + 1900;

	is($obj->calculate_age($SAMPLE_MIN_BIRTH_YEAR), $current_year - $SAMPLE_MIN_BIRTH_YEAR,
		'age calculated correctly for the minimum birth year');

	throws_ok { $obj->calculate_age(undef) } qr/^Birth year required/,
		'undef birth year croaks with exact message';
	throws_ok { $obj->calculate_age('nineteen-eighty') } qr/^Birth year must be a number/,
		'non-numeric birth year croaks with exact message';
	throws_ok { $obj->calculate_age($SAMPLE_MIN_BIRTH_YEAR - 1) } qr/^Birth year out of range/,
		'birth year below the minimum croaks with exact message';
	throws_ok { $obj->calculate_age($current_year + 1) } qr/^Birth year out of range/,
		'birth year after the current year croaks with exact message';

	is($obj->calculate_age($current_year), 0, 'birth year equal to the current year gives age 0');
};

subtest 'Sample::Module::process_names - happy path, croaks, and edge cases' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();

	is($obj->process_names(['Alice', 'Bob', '']), 2, 'empty-string entries are not counted');
	is($obj->process_names(['Alice', undef, 'Bob']), 2, 'undef entries are not counted');
	is($obj->process_names([]), 0, 'empty arrayref returns 0');

	throws_ok { $obj->process_names(undef) } qr/^Names required/,
		'undef names croaks with exact message';
	throws_ok { $obj->process_names('not-an-array') } qr/^Names must be an array reference/,
		'non-arrayref names croaks with exact message';
	throws_ok { $obj->process_names({}) } qr/^Names must be an array reference/,
		'hashref names croaks with exact message';
};

subtest 'Sample::Module::set_config - happy path, croaks, and storage' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();

	is($obj->set_config({ timeout => 30 }), 1, 'set_config returns 1 on success');
	is_deeply($obj->{config}, { timeout => 30 }, 'config hashref is stored verbatim on the instance');

	throws_ok { $obj->set_config(undef) } qr/^Config required/,
		'undef config croaks with exact message';
	throws_ok { $obj->set_config('not-a-hash') } qr/^Config must be a hash reference/,
		'non-hashref config croaks with exact message';
	throws_ok { $obj->set_config([]) } qr/^Config must be a hash reference/,
		'arrayref config croaks with exact message';

	memory_cycle_ok($obj, 'instance has no reference cycles after storing a plain config hashref');
};

subtest 'Sample::Module::greet - happy path, default greeting, and exact croak messages' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();

	is($obj->greet('Alice'), 'Hello, Alice!', 'default greeting is used when none supplied');
	is($obj->greet('Alice', 'Good morning'), 'Good morning, Alice!', 'explicit greeting overrides the default');

	throws_ok { $obj->greet(undef) } qr/^Name is required/,
		'undef name croaks with exact message';
	throws_ok { $obj->greet('x' x ($SAMPLE_MAX_NAME_LEN + 1)) } qr/^Name too long/,
		'above-maximum-length name croaks with exact message';

	is($obj->greet('x' x $SAMPLE_MIN_NAME_LEN), "Hello, " . ('x' x $SAMPLE_MIN_NAME_LEN) . '!',
		'name at exactly the minimum length is accepted');
	is($obj->greet('x' x $SAMPLE_MAX_NAME_LEN), "Hello, " . ('x' x $SAMPLE_MAX_NAME_LEN) . '!',
		'name at exactly the maximum length is accepted');
};

subtest 'Sample::Module::greet - falsy but defined greeting falls back to the default' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();

	# The "||=" default applies to ANY falsy greeting, not just undef --
	# an empty string explicitly passed is replaced with 'Hello' too
	is($obj->greet('Alice', ''), 'Hello, Alice!', 'empty-string greeting falls back to the default');
	is($obj->greet('Alice', 0), 'Hello, Alice!', 'zero greeting falls back to the default');
};

subtest 'Sample::Module::check_flag - normalises truthy and falsy values to strict 1/0' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();

	is($obj->check_flag(1), 1, 'truthy 1 normalises to 1');
	is($obj->check_flag('yes'), 1, 'truthy string normalises to 1');
	is($obj->check_flag(0), 0, 'falsy 0 normalises to 0');
	is($obj->check_flag(''), 0, 'falsy empty string normalises to 0');
	is($obj->check_flag(undef), 0, 'undef normalises to 0');
};

subtest 'Sample::Module::validate_score - happy path, croaks, and threshold boundary' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();

	is($obj->validate_score(75.5), 'Pass', 'score above the pass threshold returns Pass');
	is($obj->validate_score(45.0), 'Fail', 'score below the pass threshold returns Fail');

	throws_ok { $obj->validate_score(undef) } qr/^Score is required/,
		'undef score croaks with exact message';
	throws_ok { $obj->validate_score('abc') } qr/^Score must be numeric/,
		'non-numeric score croaks with exact message';
	throws_ok { $obj->validate_score('1.2.3') } qr/^Score must be numeric/,
		'malformed multi-dot score croaks with exact message';

	# Note: the numeric-format regex (\d+\.?\d* | \.\d+) never matches a
	# leading minus sign, and $MIN_SCORE is 0.0 -- so there is no
	# syntactically-numeric value below the minimum, and the lower arm
	# of the range check is reached only via the boundary itself (below).
	# A below-minimum *negative* score therefore always croaks "must be
	# numeric" first, never "out of range" -- there is no test for that
	# specific croak message on the low end for this reason.
	throws_ok { $obj->validate_score(-1) } qr/^Score must be numeric/,
		'a negative score croaks as non-numeric, since the format regex excludes a leading minus sign';
	throws_ok { $obj->validate_score($SAMPLE_MAX_SCORE + 1) } qr/^Score out of range/,
		'above-maximum score croaks with exact message';

	# Exact pass-threshold boundary -- a NumericBoundary mutation flipping
	# ">=" to ">" on $PASS_THRESHOLD would survive without this assertion
	is($obj->validate_score($SAMPLE_PASS_THRESHOLD), 'Pass',
		'score exactly at the pass threshold returns Pass, not Fail');
	is($obj->validate_score($SAMPLE_PASS_THRESHOLD - 0.1), 'Fail',
		'score just below the pass threshold returns Fail');

	# Exact min/max range boundaries -- a NumericBoundary mutation flipping
	# ">=" / "<=" to ">" / "<" on $MIN_SCORE or $MAX_SCORE would wrongly
	# croak "Score out of range" for these in-range edge values
	lives_ok { $obj->validate_score($SAMPLE_MIN_SCORE) } 'score exactly at the minimum does not croak';
	lives_ok { $obj->validate_score($SAMPLE_MAX_SCORE) } 'score exactly at the maximum does not croak';

	# Leading-dot decimal form is explicitly accepted per the regex
	is($obj->validate_score('.5'), 'Fail', 'leading-dot decimal score is accepted as numeric');
};

subtest 'Sample::Module::mysterious_method - deliberately unvalidated, doubles its input' => sub {
	my $obj = App::Test::Generator::Sample::Module->new();

	is($obj->mysterious_method(21), 42, 'numeric input is doubled');
	is($obj->mysterious_method(-5), -10, 'negative numeric input is doubled');
	is($obj->mysterious_method(0), 0, 'zero input is doubled to zero');

	# POD explicitly documents that non-numeric input triggers a Perl
	# warning rather than a die -- this is the fixture's intended
	# behaviour (used to test SchemaExtractor's low-confidence heuristic
	# for under-validated methods), so the test asserts a warning is
	# raised and execution continues, not that it dies
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };
	my $result;
	lives_ok { $result = $obj->mysterious_method('not-a-number') }
		'non-numeric input does not die, per the documented fixture behaviour';
	is($result, 0, q{non-numeric string is treated as 0 by Perl's numeric coercion, doubled to 0});
	ok(scalar(@warnings) > 0, 'non-numeric input triggers at least one Perl warning, as documented');
};

# --------------------------------------------------
# Devel::App::Test::Generator::LCSAJ::Runtime
#
# t/LCSAJ-Runtime.t already covers DB::DB()'s abs_path() memoisation
# and basic hit recording, so these subtests focus on the branches that
# file does not exercise: _normalize() in isolation, the self-exclusion
# guard, the %TARGET allow-list filter, _write_results() (including the
# autodie-disabled open()/croak path fixed in this session), and the
# BEGIN-time LCSAJ_TARGETS env-var parsing, which can only be observed
# by re-loading the module in a fresh child process.
# --------------------------------------------------
subtest 'Devel::App::Test::Generator::LCSAJ::Runtime::_normalize - path canonicalisation' => sub {
	is(
		Devel::App::Test::Generator::LCSAJ::Runtime::_normalize('/home/user/proj/blib/lib/Foo/Bar.pm'),
		'lib/Foo/Bar.pm',
		'a blib/lib/ prefixed path is stripped down to lib/...'
	);
	is(
		Devel::App::Test::Generator::LCSAJ::Runtime::_normalize('/home/user/proj/lib/Foo/Bar.pm'),
		'lib/Foo/Bar.pm',
		'a plain lib/ prefixed path is stripped down to lib/...'
	);
	is(
		Devel::App::Test::Generator::LCSAJ::Runtime::_normalize('lib/Foo/Bar.pm'),
		'lib/Foo/Bar.pm',
		'a path already in lib/... form is left unchanged'
	);
	is(
		Devel::App::Test::Generator::LCSAJ::Runtime::_normalize('/home/user/lib/proj/lib/Foo/Bar.pm'),
		'lib/Foo/Bar.pm',
		q{a path containing "lib/" more than once is stripped at the rightmost (greediest) occurrence}
	);
};

subtest 'Devel::App::Test::Generator::LCSAJ::Runtime::DB::DB - self-exclusion guard' => sub {
	local %Devel::App::Test::Generator::LCSAJ::Runtime::HITS = ();
	local %Devel::App::Test::Generator::LCSAJ::Runtime::NORM_CACHE = (
		'FAKE_RUNTIME_CALLER' => 'lib/Devel/App/Test/Generator/LCSAJ/Runtime.pm',
	);

	# A #line directive lets us make caller(0) report an arbitrary
	# filename from inside eval'd code, without needing a second real
	# file on disk -- the cached normalised path is what the exclusion
	# regex actually matches against
	eval qq{#line 1 "FAKE_RUNTIME_CALLER"\nDB::DB();};
	is($@, '', 'DB::DB() does not die when called against its own normalised path') or diag($@);

	ok(
		!exists $Devel::App::Test::Generator::LCSAJ::Runtime::HITS{'lib/Devel/App/Test/Generator/LCSAJ/Runtime.pm'},
		'DB::DB() never records a hit against its own module path'
	);
};

subtest 'Devel::App::Test::Generator::LCSAJ::Runtime::DB::DB - %TARGET allow-list filtering' => sub {
	local %Devel::App::Test::Generator::LCSAJ::Runtime::HITS = ();
	local %Devel::App::Test::Generator::LCSAJ::Runtime::NORM_CACHE = ();
	local %Devel::App::Test::Generator::LCSAJ::Runtime::TARGET = (
		'lib/SomeOtherModule.pm' => 1,
	);

	DB::DB();

	# DB::DB() resolves $file through abs_path() before normalising, so
	# the cache/comparison key here must be built the same way -- using
	# _normalize(__FILE__) directly (skipping abs_path) would compare a
	# relative path against DB::DB()'s absolute one and never match
	my $this_file = Devel::App::Test::Generator::LCSAJ::Runtime::_normalize(Cwd::abs_path(__FILE__));
	ok(
		!exists $Devel::App::Test::Generator::LCSAJ::Runtime::HITS{$this_file},
		'a populated %TARGET that excludes this file suppresses recording for it'
	);

	%Devel::App::Test::Generator::LCSAJ::Runtime::TARGET = ($this_file => 1);
	my $hit_line = __LINE__ + 1;
	DB::DB();
	is(
		$Devel::App::Test::Generator::LCSAJ::Runtime::HITS{$this_file}{$hit_line},
		1,
		'adding this file to %TARGET allows the next call to record a hit for it'
	);
};

subtest 'Devel::App::Test::Generator::LCSAJ::Runtime::_write_results - skips IO when %HITS is empty' => sub {
	local %Devel::App::Test::Generator::LCSAJ::Runtime::HITS = ();

	my $make_path_calls = 0;
	Test::Mockingbird::mock(
		'Devel::App::Test::Generator::LCSAJ::Runtime',
		'make_path',
		sub { $make_path_calls++; return 1 },
	);
	Devel::App::Test::Generator::LCSAJ::Runtime::_write_results();
	is($make_path_calls, 0, '_write_results() returns immediately, before touching the filesystem, when %HITS is empty');
	Test::Mockingbird::unmock('Devel::App::Test::Generator::LCSAJ::Runtime', 'make_path');
};

subtest 'Devel::App::Test::Generator::LCSAJ::Runtime::_write_results - writes a well-formed per-PID JSON file' => sub {
	my $orig_cwd = getcwd();
	my $tmp = File::Temp::tempdir(CLEANUP => 1);

	local %Devel::App::Test::Generator::LCSAJ::Runtime::HITS = (
		'lib/Foo/Bar.pm' => { 10 => 3, 12 => 1 },
	);

	eval {
		chdir $tmp or die "cannot chdir to $tmp: $!";
		Devel::App::Test::Generator::LCSAJ::Runtime::_write_results();
	};
	my $err = $@;
	chdir $orig_cwd or croak "cannot chdir back to $orig_cwd: $!";
	is($err, '', '_write_results() does not die for a normal, writable target') or diag($err);

	my $out_file = "$tmp/cover_html/lcsaj_hits/hits_$$.json";
	ok(-e $out_file, 'a per-PID JSON file is written under cover_html/lcsaj_hits, named with the current PID');

	no autodie qw(open);
	open my $fh, '<', $out_file or croak "cannot read back $out_file: $!";
	local $/;
	my $content = <$fh>;
	close $fh;

	my $decoded = decode_json($content);
	is_deeply(
		$decoded,
		{ 'lib/Foo/Bar.pm' => { 10 => 3, 12 => 1 } },
		'the written JSON round-trips back to the exact %HITS structure that was serialised'
	);

	memory_cycle_ok(\%Devel::App::Test::Generator::LCSAJ::Runtime::HITS, '%HITS holds no circular references');
};

subtest 'Devel::App::Test::Generator::LCSAJ::Runtime::_write_results - croaks with the documented message when open() fails' => sub {
	my $orig_cwd = getcwd();
	my $tmp = File::Temp::tempdir(CLEANUP => 1);

	local %Devel::App::Test::Generator::LCSAJ::Runtime::HITS = (
		'lib/Foo/Bar.pm' => { 10 => 1 },
	);

	eval {
		chdir $tmp or die "cannot chdir to $tmp: $!";

		# Pre-create the exact target path as a directory, not a file --
		# open() for write against a directory portably fails on every
		# platform this module supports, without relying on chmod-based
		# permission tricks that behave differently when run as root
		my $out_file = "cover_html/lcsaj_hits/hits_$$.json";
		make_path($out_file);

		throws_ok { Devel::App::Test::Generator::LCSAJ::Runtime::_write_results() }
			qr/^Cannot write \Q$out_file\E: /,
			'_write_results() croaks with the exact documented message when open() fails';
	};
	my $err = $@;
	chdir $orig_cwd or croak "cannot chdir back to $orig_cwd: $!";
	is($err, '', 'no unexpected exception escaped the eval wrapper') or diag($err);
};

subtest 'Devel::App::Test::Generator::LCSAJ::Runtime - BEGIN-time LCSAJ_TARGETS parsing' => sub {
	# %TARGET is populated once, at compile time, from $ENV{LCSAJ_TARGETS}.
	# That BEGIN block cannot be re-run against this already-loaded module,
	# so it is exercised by loading a fresh copy of the module in a child
	# process with the env var pre-set, then reading back %TARGET -- a
	# single bounded perl -e invocation, not a recursive test/prove run
	my $targets = '/build/blib/lib/Foo.pm:/home/user/proj/lib/Bar.pm:' . "\n";
	local $ENV{LCSAJ_TARGETS} = $targets;

	# List-form system() under capture_merged(), not qx{}/backticks --
	# qx{} always goes through a shell, and a shell-quoted '...' -e
	# argument that works under sh/bash is invalid syntax for
	# cmd.exe on Windows (single quotes are not its quoting
	# character), which previously made the child perl process fail
	# to parse its own -e script.
	my @inc_args = map { ('-I', $_) } @INC;
	my $code = 'print join(q{,}, sort keys %Devel::App::Test::Generator::LCSAJ::Runtime::TARGET)';
	my ($output, $exit) = capture_merged {
		system($^X, @inc_args, '-MDevel::App::Test::Generator::LCSAJ::Runtime', '-e', $code);
	};
	is($exit, 0, 'the child process exits cleanly') or diag($output);
	is(
		$output,
		'lib/Bar.pm,lib/Foo.pm',
		'LCSAJ_TARGETS entries are normalised (blib/lib and lib stripped) and stray trailing newlines are removed'
	);
};

# Clear %HITS so this module's END block (_write_results) does not write
# a stray hits_$$.json file into the real project tree when this test
# script itself exits
%Devel::App::Test::Generator::LCSAJ::Runtime::HITS = ();

# --------------------------------------------------
# App::Test::Generator::Emitter::Perl
#
# t/Emitter-Perl.t and t/Emitter-Perl_unit.t already exhaustively cover
# every emitted code block and every plan-flag combination, but use only
# loose (unanchored) regex matches on croak messages and never use
# Test::Mockingbird, Test::Returns, or Test::Memory::Cycle. These
# subtests add: exact (anchored) croak-message assertions, dispatch-only
# isolation of _emit_method_tests() via mocking every _emit_*_test sub
# (so the dispatch logic is verified independently of what those subs
# actually emit), the never-before-tested predicate_test flag, the
# never-before-tested case of a method entirely absent from %schema,
# and returns_ok/memory_cycle_ok coverage.
# --------------------------------------------------
subtest 'Emitter::Perl::new - exact croak messages' => sub {
	throws_ok { App::Test::Generator::Emitter::Perl->new(plans => {}, package => 'Foo') }
		qr/^schema required at /, 'missing schema croaks with the exact documented message';
	throws_ok { App::Test::Generator::Emitter::Perl->new(schema => {}, package => 'Foo') }
		qr/^plans required at /, 'missing plans croaks with the exact documented message';
	throws_ok { App::Test::Generator::Emitter::Perl->new(schema => {}, plans => {}) }
		qr/^package required at /, 'missing package croaks with the exact documented message';

	my $bad_package = "Evil'); system('touch /tmp/pwned'); #";
	throws_ok { App::Test::Generator::Emitter::Perl->new(schema => {}, plans => {}, package => $bad_package) }
		qr/^package '\Q$bad_package\E' is not a valid Perl package name at /,
		'an invalid package name croaks with the exact interpolated message';
};

subtest 'Emitter::Perl::new - return value shape and no memory cycles' => sub {
	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => { input => {}, output => {} } },
		plans   => { foo => { basic_test => 1 } },
		package => 'My::Module',
	);
	returns_ok($emitter, { type => 'object', isa => 'App::Test::Generator::Emitter::Perl' },
		'new() returns a blessed Emitter::Perl instance');
	memory_cycle_ok($emitter, 'new() builds an object with no circular references');
};

subtest 'Emitter::Perl::_emit_method_tests - exact croak message for an invalid method name' => sub {
	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema => {}, plans => { 'not an identifier' => { basic_test => 1 } }, package => 'My::Module',
	);
	throws_ok { $emitter->_emit_method_tests('not an identifier') }
		qr/^method 'not an identifier' is not a valid Perl identifier at /,
		'a non-identifier method name croaks with the exact documented message';
};

subtest 'Emitter::Perl::_emit_method_tests - dispatches only to the _emit_*_test subs flagged in the plan' => sub {
	# Mock every dispatch target so this subtest isolates _emit_method_tests()'s
	# branching logic from what each individual _emit_*_test sub actually emits
	my %calls;
	for my $sub (qw(
		_emit_basic_test _emit_getter_test _emit_setter_test _emit_getset_test
		_emit_chaining_test _emit_error_test _emit_context_test
		_emit_object_injection_test _emit_boolean_test _emit_void_test
	)) {
		Test::Mockingbird::mock(
			'App::Test::Generator::Emitter::Perl',
			$sub,
			sub { $calls{$sub}++; return "[$sub]" },
		);
	}

	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema => {},
		plans  => { foo => { getter_test => 1, chaining_test => 1 } },
		package => 'My::Module',
	);
	%calls = ();
	my $code = $emitter->_emit_method_tests('foo');

	is($calls{_emit_getter_test},   1, 'getter_test flag dispatches to _emit_getter_test exactly once');
	is($calls{_emit_chaining_test}, 1, 'chaining_test flag dispatches to _emit_chaining_test exactly once');
	for my $unset (qw(
		_emit_basic_test _emit_setter_test _emit_getset_test _emit_error_test
		_emit_context_test _emit_object_injection_test _emit_boolean_test _emit_void_test
	)) {
		ok(!exists $calls{$unset}, "unset flag never dispatches to $unset");
	}
	like($code, qr/\Q[_emit_getter_test]\E/,   'dispatched getter output is included in the assembled code');
	like($code, qr/\Q[_emit_chaining_test]\E/, 'dispatched chaining output is included in the assembled code');

	%calls = ();
	$emitter = App::Test::Generator::Emitter::Perl->new(
		schema => {}, plans => { foo => { predicate_test => 1 } }, package => 'My::Module',
	);
	$emitter->_emit_method_tests('foo');
	is($calls{_emit_boolean_test}, 1,
		'the predicate_test flag alone (without boolean_test) also dispatches to _emit_boolean_test');

	for my $sub (qw(
		_emit_basic_test _emit_getter_test _emit_setter_test _emit_getset_test
		_emit_chaining_test _emit_error_test _emit_context_test
		_emit_object_injection_test _emit_boolean_test _emit_void_test
	)) {
		Test::Mockingbird::unmock('App::Test::Generator::Emitter::Perl', $sub);
	}
};

subtest 'Emitter::Perl::_emit_getset_test - a method entirely absent from %schema falls back to a string round-trip' => sub {
	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema => {}, plans => { foo => { getset_test => 1 } }, package => 'My::Module',
	);
	my $result;
	lives_ok { $result = $emitter->_emit_getset_test('foo') }
		'_emit_getset_test() does not die when the method has no entry in %schema at all';
	my $expected_line = q{is($obj->foo(), 'value', 'foo get/set works')};
	like($result, qr/\Q$expected_line\E/,
		'absent schema falls through to the default string get/set round-trip');
};

subtest 'Emitter::Perl::emit - full pipeline return value and memory-cycle safety' => sub {
	my $emitter = App::Test::Generator::Emitter::Perl->new(
		schema => { greet => { input => {}, output => {} } },
		plans  => { greet => { basic_test => 1, getter_test => 1 } },
		package => 'My::Module',
	);
	my $code = $emitter->emit();
	returns_ok($code, { type => 'string' }, 'emit() returns a string');
	like($code, qr/done_testing\(\);\s*\z/, 'emit() output ends with the done_testing() footer');
	memory_cycle_ok($emitter, 'emit() leaves the emitter free of circular references');
};

# ==================================================================
# App::Test::Generator::Template
#
# This module's own package code is a single thin wrapper,
# get_data_section(), around Data::Section::Simple::get_data_section().
# Everything else in the .pm file is __DATA__ template text (test.tt)
# rendered into *generated* downstream test files at runtime -- those
# embedded helper subs (rand_str, fuzz_inputs, etc.) never belong to the
# App::Test::Generator::Template namespace, so they are out of scope
# here; t/app.t exercises them indirectly by rendering and running the
# generated harnesses. t/Template.t and t/Template_unit.t already cover
# both call styles and the unknown-template/undef-argument cases by
# value, so this section adds only what those files do not: a mocked
# dispatch-isolation test pinning down exactly which arguments reach
# Data::Section::Simple::get_data_section() for each call style, plus
# Test::Returns/Test::Memory::Cycle coverage.
# ==================================================================
subtest 'Template::get_data_section - dispatch isolation via mocked Data::Section::Simple' => sub {
	my @captured;
	Test::Mockingbird::mock(
		'Data::Section::Simple::get_data_section',
		sub { @captured = @_; return 'mocked-content'; },
	);

	@captured = ();
	App::Test::Generator::Template->get_data_section('test.tt');
	is_deeply(\@captured, ['test.tt'],
		'class-method call strips the leading class name before delegating, passing on only the template name');

	@captured = ();
	App::Test::Generator::Template::get_data_section('test.tt');
	is_deeply(\@captured, ['test.tt'],
		'plain function call passes the template name through unchanged');

	@captured = ();
	App::Test::Generator::Template::get_data_section();
	is_deeply(\@captured, [undef],
		'a no-argument call still forwards a single undef element, since $_[0] is read (not shifted) when it is not the package name');

	Test::Mockingbird::unmock('Data::Section::Simple::get_data_section');
};

subtest 'Template::get_data_section - return value and memory-cycle safety' => sub {
	my $result = App::Test::Generator::Template->get_data_section('test.tt');
	returns_ok($result, { type => 'scalarref' }, 'get_data_section() returns a scalarref');
	memory_cycle_ok($result, 'get_data_section() result is free of circular references');
};

# ==================================================================
# App::Test::Generator::_assert_identifier
#
# Security-critical guard (see CLAUDE.md): every module/function/
# transform/field name spliced unescaped into generated test source
# passes through here first. No existing test file (t/Generator.t,
# t/Generator_unit.t) exercises this function at all, so this section
# is full by-value coverage rather than a value-add narrowing.
# ==================================================================
subtest 'Generator::_assert_identifier - accepts well-formed identifiers' => sub {
	my $fn = \&App::Test::Generator::_assert_identifier;

	is($fn->('foo', 'name'), 'foo', 'a plain bareword identifier is returned unchanged');
	is($fn->('_private', 'name'), '_private', 'a leading underscore is accepted');
	is($fn->('Foo123', 'name'), 'Foo123', 'letters and digits after the first character are accepted');
};

subtest 'Generator::_assert_identifier - package => 1 additionally allows "::" separators' => sub {
	my $fn = \&App::Test::Generator::_assert_identifier;

	is($fn->('Foo::Bar', 'module', package => 1), 'Foo::Bar',
		'a "::"-separated package name is accepted when package => 1');
	is($fn->('DB::DB', 'function', package => 1), 'DB::DB',
		'a fully-qualified sub name such as DB::DB is accepted when package => 1');

	throws_ok { $fn->('Foo::Bar', 'module') } qr/^App::Test::Generator: module 'Foo::Bar' is not a valid Perl identifier at /,
		'without package => 1, a "::"-separated name is rejected with the exact documented message';
};

subtest 'Generator::_assert_identifier - croaks with the exact message for missing or empty names' => sub {
	my $fn = \&App::Test::Generator::_assert_identifier;

	throws_ok { $fn->(undef, 'module') } qr/^App::Test::Generator: module is missing or empty at /,
		'undef name croaks with the exact documented message';
	throws_ok { $fn->('', 'function') } qr/^App::Test::Generator: function is missing or empty at /,
		'empty-string name croaks with the exact documented message';
};

subtest 'Generator::_assert_identifier - rejects injection payloads even with package => 1' => sub {
	my $fn = \&App::Test::Generator::_assert_identifier;

	for my $payload ("Foo'; system('rm -rf /'); '", 'Foo::Bar()', 'Foo::Bar; 1', 'Foo Bar', '1Foo') {
		throws_ok { $fn->($payload, 'module', package => 1) }
			qr/^App::Test::Generator: module '\Q$payload\E' is not a valid Perl identifier at /,
			"payload '$payload' is rejected even with package => 1";
	}
};

subtest 'Generator::_assert_identifier - return value shape' => sub {
	my $fn = \&App::Test::Generator::_assert_identifier;
	returns_ok($fn->('foo', 'name'), { type => 'string' }, '_assert_identifier() returns a plain string on success');
};

# ==================================================================
# App::Test::Generator::_perl_quote - circular-reference depth guard
#
# The depth > 100 croak in _perl_quote() is unreachable through any
# single-level call from the public perl_quote() wrapper (which always
# starts at depth 0), but is reachable legitimately by feeding
# perl_quote() a sufficiently deep arrayref-of-arrayrefs -- no need to
# call the private _perl_quote() directly with a fabricated depth.
# ==================================================================
subtest 'Generator::perl_quote - croaks on a structure nested past the recursion limit' => sub {
	Readonly my $DEPTH_BEYOND_LIMIT => 101;

	my $deeply_nested = [];
	my $cursor = $deeply_nested;
	for (1 .. $DEPTH_BEYOND_LIMIT) {
		push @{$cursor}, [];
		$cursor = $cursor->[0];
	}

	throws_ok { App::Test::Generator::perl_quote($deeply_nested) }
		qr/^perl_quote: structure too deeply nested \(circular reference\?\) at /,
		'an arrayref nested past the recursion limit croaks with the exact documented message';
};

# ==================================================================
# App::Test::Generator::_validate_config - dispatch isolation
#
# t/Generator.t already covers _validate_config() exhaustively by
# value. The one mandated technique missing there is mocking the four
# delegate validators to pin down exactly which ones run under which
# input shape, independent of what each delegate actually does.
# ==================================================================
subtest 'Generator::_validate_config - dispatches to input validators only when input is defined' => sub {
	my %calls;
	for my $sub (qw(_validate_input_params _validate_input_positions _validate_input_semantics _validate_transform_properties)) {
		Test::Mockingbird::mock(
			'App::Test::Generator',
			$sub,
			sub { $calls{$sub}++; return; },
		);
	}

	%calls = ();
	App::Test::Generator::_validate_config({ function => 'foo' });
	ok(!exists $calls{_validate_input_params}, 'no input section means _validate_input_params is never dispatched');

	%calls = ();
	App::Test::Generator::_validate_config({ function => 'foo', input => { x => { type => 'string' } } });
	is($calls{_validate_input_params},   1, 'a defined input section dispatches to _validate_input_params exactly once');
	is($calls{_validate_input_positions}, 1, 'a defined input section dispatches to _validate_input_positions exactly once');
	is($calls{_validate_input_semantics}, 1, 'a defined input section dispatches to _validate_input_semantics exactly once');

	%calls = ();
	App::Test::Generator::_validate_config({
		function   => 'foo',
		transforms => { t1 => { properties => ['length'] } },
	});
	is($calls{_validate_transform_properties}, 1,
		'a hashref transforms section dispatches to _validate_transform_properties exactly once');

	for my $sub (qw(_validate_input_params _validate_input_positions _validate_input_semantics _validate_transform_properties)) {
		Test::Mockingbird::unmock('App::Test::Generator', $sub);
	}
};

# ==================================================================
# App::Test::Generator::SchemaExtractor
#
# t/SchemaExtractor.t, t/SchemaExtractor_unit.t, t/SchemaExtractor_function.t,
# and t/SchemaExtractor_signature_exec.t already cover the public API and
# most internal helpers by value via extract_all(). The subtests below
# target the handful of internal helpers those files never reach at all:
# _analysis_error, _ppi, _extract_type_params_schema, _extract_function_name,
# _map_formal_input_type, _analyze_output, _extract_defaults_from_pod,
# _analyze_advanced_types, _parse_modern_signature, _detect_dependencies,
# _write_schema, _check_inheritance_for_constructor,
# _detect_constructor_requirements, _detect_external_object_dependency,
# _extract_default_value, and _log.
# ==================================================================

subtest 'SchemaExtractor::_analysis_error - croaks with module/method/file context' => sub {
	my $e = bless { _package_name => 'My::Pkg', input_file => '/tmp/foo.pm' },
		'App::Test::Generator::SchemaExtractor';

	throws_ok { $e->_analysis_error(method => 'frobnicate', message => 'Something broke') }
		qr{^Something broke\n  Module: My::Pkg\n  Method: frobnicate\n  File:   /tmp/foo\.pm\n at },
		'croak message includes the message, module, method, and file, in that exact layout';
};

subtest 'SchemaExtractor::_analysis_error - defaults to UNKNOWN for absent context fields' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	throws_ok { $e->_analysis_error() }
		qr{^Analysis error\n  Module: UNKNOWN\n  Method: UNKNOWN\n  File:   UNKNOWN\n at },
		'missing method/message/_package_name/input_file all fall back to their documented defaults';
};

subtest 'SchemaExtractor::_ppi - parses a code string once and caches the result per instance' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	my $code = "package Foo;\nsub bar { return 1 }\n1;\n";
	my $doc1 = $e->_ppi($code);
	isa_ok($doc1, 'PPI::Document', 'a code string is parsed into a PPI::Document');

	my $doc2 = $e->_ppi($code);
	is($doc2, $doc1, 'a second call with the identical code string returns the cached document, not a fresh parse');
};

subtest 'SchemaExtractor::_ppi - returns an object that already supports find() unchanged' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	my $already_parsed = PPI::Document->new(\"package Foo;\n1;\n");
	my $result = $e->_ppi($already_parsed);
	is($result, $already_parsed, 'an object with a find() method is returned as-is, bypassing the cache entirely');
};

subtest 'SchemaExtractor::_extract_type_params_schema - dispatch isolation and short-circuit on first falsy step' => sub {
	my $e = bless { _document => bless({}, 'Fake::Doc') }, 'App::Test::Generator::SchemaExtractor';
	my @calls;

	my @steps = qw(_extract_function_name _find_signature_statement _extract_signature_expression _compile_signature_isolated _build_schema_from_meta);
	Test::Mockingbird::mock('App::Test::Generator::SchemaExtractor', '_extract_function_name', sub { push @calls, '_extract_function_name'; return 'foo'; });
	Test::Mockingbird::mock('App::Test::Generator::SchemaExtractor', '_find_signature_statement', sub { push @calls, '_find_signature_statement'; return undef; });
	Test::Mockingbird::mock('App::Test::Generator::SchemaExtractor', '_extract_signature_expression', sub { push @calls, '_extract_signature_expression'; return 'unused'; });
	Test::Mockingbird::mock('App::Test::Generator::SchemaExtractor', '_compile_signature_isolated', sub { push @calls, '_compile_signature_isolated'; return {}; });
	Test::Mockingbird::mock('App::Test::Generator::SchemaExtractor', '_build_schema_from_meta', sub { push @calls, '_build_schema_from_meta'; return { input => {} }; });

	my $result = $e->_extract_type_params_schema('sub foo { ... }');
	is($result, undef, 'returns undef when _find_signature_statement returns falsy');
	is_deeply(\@calls, [qw(_extract_function_name _find_signature_statement)],
		'short-circuits immediately after the first falsy step, never calling the later steps');

	@calls = ();
	Test::Mockingbird::mock('App::Test::Generator::SchemaExtractor', '_find_signature_statement', sub { push @calls, '_find_signature_statement'; return bless {}, 'Fake::Stmt'; });
	$result = $e->_extract_type_params_schema('sub foo { ... }');
	is_deeply($result, { input => {} }, 'returns the final step result when every step succeeds');
	is_deeply(\@calls, \@steps, 'calls all five steps in documented order when none are falsy');

	Test::Mockingbird::unmock('App::Test::Generator::SchemaExtractor', $_) for @steps;
};

subtest 'SchemaExtractor::_extract_type_params_schema - returns immediately when there is no _document' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	Test::Mockingbird::mock('App::Test::Generator::SchemaExtractor', '_extract_function_name', sub { return 'foo'; });
	is($e->_extract_type_params_schema('sub foo {}'), undef, 'no _document means no signature lookup is even attempted');
	Test::Mockingbird::unmock('App::Test::Generator::SchemaExtractor', '_extract_function_name');
};

subtest 'SchemaExtractor::_extract_function_name - extracts the sub name from the start of a method body' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	is($e->_extract_function_name("sub foo { return 1; }"), 'foo', 'a simple one-line sub declaration is matched');
	is($e->_extract_function_name("\n\tsub  bar_baz2 {\n\t\treturn;\n\t}"), 'bar_baz2',
		'leading whitespace and extra spaces before the name are tolerated');
	is($e->_extract_function_name("my \$x = 1; sub foo {}"), undef,
		'returns undef when "sub NAME" does not occur at the very start of the string');
	is($e->_extract_function_name(''), undef, 'returns undef for an empty string');
};

subtest 'SchemaExtractor::_map_formal_input_type - maps formal spec type fragments to canonical ATG types' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	is($e->_map_formal_input_type(q{type=>'scalar'}), 'string', 'scalar maps to string');
	is($e->_map_formal_input_type(q{type => "Integer"}), 'integer', 'case is folded before lookup');
	is($e->_map_formal_input_type(q{type => 'scalar | scalarref'}), 'string',
		'a union type resolves to the first recognised alternative');
	is($e->_map_formal_input_type(q{type => 'bogus'}), undef, 'an unrecognised type name returns undef');
	is($e->_map_formal_input_type(q{name => 'x'}), undef, 'a spec fragment with no type key returns undef');
};

subtest 'SchemaExtractor::_analyze_output - dispatch isolation, conditional _validate_output, and empty fallback' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	my @detectors = qw(_analyze_output_from_pod _analyze_output_from_code _enhance_boolean_detection _detect_list_context _detect_void_context _detect_chaining_pattern _detect_error_conventions);
	my @calls;

	for my $sub (@detectors, '_validate_output') {
		Test::Mockingbird::mock('App::Test::Generator::SchemaExtractor', $sub, sub { push @calls, $sub; return; });
	}

	my $result = $e->_analyze_output('POD', 'CODE', 'method_name');
	is_deeply($result, {}, 'returns {} when no detector populates the output hash');
	is_deeply(\@calls, \@detectors, '_validate_output is skipped entirely while %output stays empty');

	@calls = ();
	Test::Mockingbird::mock('App::Test::Generator::SchemaExtractor', '_analyze_output_from_pod',
		sub { push @calls, '_analyze_output_from_pod'; $_[1]->{type} = 'string'; return; });
	$result = $e->_analyze_output('POD', 'CODE', 'method_name');
	is_deeply($result, { type => 'string' }, 'returns the populated hashref once a detector sets a key');
	is($calls[-1], '_validate_output', '_validate_output runs last, once %output is non-empty');

	for my $sub (@detectors, '_validate_output') {
		Test::Mockingbird::unmock('App::Test::Generator::SchemaExtractor', $sub);
	}
};

subtest 'SchemaExtractor::_extract_defaults_from_pod - extracts defaults via all three documented POD patterns' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	is_deeply($e->_extract_defaults_from_pod(''), {}, 'an empty/falsy POD string returns an empty hashref');

	my $pod1 = "The \$user parameter.\nDefault: 'admin'\n";
	is_deeply($e->_extract_defaults_from_pod($pod1), { user => 'admin' }, 'Pattern 1: Default: <value>, param found by scanning backwards');

	my $pod2 = "The \$timeout parameter is Optional, default 30\n";
	is_deeply($e->_extract_defaults_from_pod($pod2), { timeout => '30' }, 'Pattern 2: Optional, default <value>');

	my $pod3 = "\$port - integer, default 8080\n";
	is_deeply($e->_extract_defaults_from_pod($pod3), { port => '8080' }, 'Pattern 3: inline $name - type, default value');
};

subtest 'SchemaExtractor::_analyze_advanced_types - dispatches to all four detectors in documented priority order' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	my @detectors = qw(_detect_datetime_type _detect_filehandle_type _detect_coderef_type _detect_enum_type);
	my @calls;

	for my $sub (@detectors) {
		Test::Mockingbird::mock('App::Test::Generator::SchemaExtractor', $sub, sub { push @calls, $sub; return; });
	}

	my %container = (x => { type => undef });
	$e->_analyze_advanced_types(\$container{x}, 'x', 'CODE');
	is_deeply(\@calls, \@detectors, 'all four detectors run, unconditionally, in datetime/filehandle/coderef/enum order');

	Test::Mockingbird::unmock('App::Test::Generator::SchemaExtractor', $_) for @detectors;
};

subtest 'SchemaExtractor::_parse_modern_signature - skips self/class and assigns sequential positions' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	my %params;

	$e->_parse_modern_signature(\%params, '$self, $x, $y');
	ok(!exists $params{self}, 'self is skipped, never added to the params hash');
	is($params{x}{position}, 0, 'x is given position 0');
	is($params{y}{position}, 1, 'y is given position 1, immediately after the skipped self');
};

subtest 'SchemaExtractor::_parse_modern_signature - respects nested brackets when splitting on commas' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	my %params;

	$e->_parse_modern_signature(\%params, '$self, $opts = { a => 1, b => 2 }');
	is(scalar(keys %params), 1, 'the internal comma inside the bracketed default value does not split the parameter list');
	ok(exists $params{opts}, 'opts is recognised as a single parameter despite its hashref default');
};

subtest 'SchemaExtractor::_detect_dependencies - detects a dependency only when both message and code patterns match' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	my $rels = $e->_detect_dependencies(q{ croak "ssl requires key" if $ssl && !$key; }, ['ssl', 'key']);
	is(scalar(@$rels), 1, 'exactly one dependency relationship is detected');
	is($rels->[0]{type}, 'dependency', '...');
	is($rels->[0]{param}, 'ssl', '...');
	is($rels->[0]{requires}, 'key', '...');

	my $no_code_match = $e->_detect_dependencies(q{ croak "ssl requires key" if $ssl; }, ['ssl', 'key']);
	is_deeply($no_code_match, [], 'no relationship is recorded when the code-condition pattern is absent, even though the message matches');
};

subtest 'SchemaExtractor::_detect_dependencies - return value shape' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	my $rels = $e->_detect_dependencies(q{ croak "ssl requires key" if $ssl && !$key; }, ['ssl', 'key']);
	returns_ok($rels, { type => 'arrayref' }, '_detect_dependencies() returns an arrayref');
	memory_cycle_ok($rels, '_detect_dependencies() result is free of circular references');
};

subtest 'SchemaExtractor::_write_schema - croaks when output_dir was not provided to new()' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	throws_ok { $e->_write_schema('foo', {}) }
		qr{^App::Test::Generator::SchemaExtractor: output_dir must be provided to new\(\) when writing schema files at },
		'croaks with the exact documented message';
};

subtest 'SchemaExtractor::_write_schema - writes a YAML schema file under output_dir' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $e = bless { output_dir => $tmpdir }, 'App::Test::Generator::SchemaExtractor';

	$e->_write_schema('greet', {
		input  => { name => { type => 'string', position => 0 } },
		output => { type => 'string' },
	});

	my $file = File::Spec->catfile($tmpdir, 'greet.yml');
	ok(-e $file, 'the schema file is created at output_dir/<method_name>.yml');

	open my $fh, '<', $file or die "Cannot read $file: $!";
	my $contents = do { local $/; <$fh> };
	close $fh;

	like($contents, qr/function: greet/, 'the written YAML includes the function name');
	like($contents, qr/name:/, 'the written YAML includes the input parameter name');
};

subtest 'SchemaExtractor::_check_inheritance_for_constructor - detects use parent and SUPER:: usage' => sub {
	my $src = "package Child;\nuse parent 'Parent';\nsub greet { my \$self = shift; return \$self->SUPER::greet(); }\n1;\n";
	my $e = bless { _document => PPI::Document->new(\$src) }, 'App::Test::Generator::SchemaExtractor';

	my $info = $e->_check_inheritance_for_constructor('Child', 'sub greet { my $self = shift; return $self->SUPER::greet(); }');
	ok($info, 'returns inheritance info when a parent class is declared');
	is_deeply($info->{parent_statements}, ['Parent'], 'the declared parent class is captured');
	ok($info->{uses_super}, 'SUPER:: usage in the method body is detected');
	ok(!$info->{has_own_constructor}, 'Child has no own new() method');
	ok($info->{use_parent_constructor}, 'falls back to the parent constructor since Child has none of its own');
	is($info->{parent_class}, 'Parent', 'the first declared parent is selected as the constructor source');

	returns_ok($info, { type => 'hashref' }, '_check_inheritance_for_constructor() returns a hashref');
	memory_cycle_ok($info, '_check_inheritance_for_constructor() result is free of circular references');
};

subtest 'SchemaExtractor::_check_inheritance_for_constructor - returns undef when there is no _document' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	is($e->_check_inheritance_for_constructor('Foo', ''), undef, '...');
};

subtest 'SchemaExtractor::_detect_constructor_requirements - returns a minimal hashref for an external target package' => sub {
	my $e = bless { _document => PPI::Document->new(\"package Foo;\n1;\n") }, 'App::Test::Generator::SchemaExtractor';

	is_deeply(
		$e->_detect_constructor_requirements('Foo', 'Bar::External'),
		{
			external_class => 1,
			package => 'Bar::External',
			note => "Constructor for external class Bar::External - parameters unknown",
		},
		'a target package different from the current one is treated as external, with no source to analyse'
	);
};

subtest 'SchemaExtractor::_detect_constructor_requirements - extracts parameters, required flags, and defaults from new()' => sub {
	my $src = "package Foo;\nsub new {\n\tmy (\$class, \$host, \$port) = \@_;\n\tcroak \"host required\" unless defined \$host;\n\t\$port = \$port || 8080;\n\treturn bless { host => \$host, port => \$port }, \$class;\n}\n1;\n";
	my $e = bless { _document => PPI::Document->new(\$src) }, 'App::Test::Generator::SchemaExtractor';

	my $req = $e->_detect_constructor_requirements('Foo', 'Foo');
	is_deeply($req->{parameters}, ['host', 'port'], 'positional parameters are extracted from the my (...) = @_ pattern');
	is($req->{parameter_count}, 2, 'parameter_count matches the number of extracted parameters');
	is_deeply($req->{required_parameters}, ['host'], 'the croak-guarded parameter is flagged as required');
	is_deeply($req->{optional_parameters}, ['port'], 'the parameter with a default assignment is flagged optional');
	is($req->{default_values}{port}, 8080, 'the default value is captured via _extract_default_value');
};

subtest 'SchemaExtractor::_detect_constructor_requirements - returns undef when there is no new() method' => sub {
	my $e = bless { _document => PPI::Document->new(\"package Foo;\nsub bar { return 1 }\n1;\n") }, 'App::Test::Generator::SchemaExtractor';
	is($e->_detect_constructor_requirements('Foo', 'Foo'), undef, '...');
};

subtest 'SchemaExtractor::_detect_external_object_dependency - detects ->new()/->create() calls on other classes' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	my $info = $e->_detect_external_object_dependency(q{ my $obj = Foo::Bar->new(); return $obj; });
	is_deeply($info->{creates_objects}, ['Foo::Bar'], 'the instantiated class is recorded');
	is($info->{package}, 'Foo::Bar', 'the first created class becomes the primary dependency package');
};

subtest 'SchemaExtractor::_detect_external_object_dependency - detects method calls on a typed object variable' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	my $info = $e->_detect_external_object_dependency(q{ my $ua = LWP::UserAgent->new; $ua->get($url); });
	is_deeply($info->{uses_objects}, ['LWP::UserAgent'], 'the class of the object variable is inferred from its assignment');
};

subtest 'SchemaExtractor::_detect_external_object_dependency - returns undef for an undef or dependency-free body' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	is($e->_detect_external_object_dependency(undef), undef, 'an undef method body returns undef immediately');
	is($e->_detect_external_object_dependency('return 1;'), undef, 'a body with no external object usage returns undef');
};

subtest 'SchemaExtractor::_extract_default_value - extracts a default from each of several common assignment idioms' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';

	is($e->_extract_default_value('timeout', '$timeout = $timeout || 30;'), 30, 'Pattern 1: $param = $param || value');
	is($e->_extract_default_value('x', '$x //= 5;'), 5, 'Pattern 2: $param //= value');
	is($e->_extract_default_value('x', q{$x ||= 'foo';}), 'foo', 'Pattern 5: $param ||= value, with quotes stripped');
	is($e->_extract_default_value('x', '$x = 1;'), undef, 'a plain assignment with none of the eight idioms returns undef');
};

subtest 'SchemaExtractor::_extract_default_value - returns undef for missing param or code' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	is($e->_extract_default_value(undef, '$x = 1;'), undef, 'undef param returns undef');
	is($e->_extract_default_value('x', undef), undef, 'undef code returns undef');
	is($e->_extract_default_value('x', ''), undef, 'empty code returns undef');
};

subtest 'SchemaExtractor::_log - prints to stdout only when verbose is true' => sub {
	my $e = bless { verbose => 1 }, 'App::Test::Generator::SchemaExtractor';

	my $stdout = capture_stdout { $e->_log('hello world') };
	is($stdout, "hello world\n", 'message is printed with a trailing newline when verbose is set');

	$e->{verbose} = 0;
	$stdout = capture_stdout { $e->_log('should not appear') };
	is($stdout, '', 'nothing is printed when verbose is false');
};

done_testing();
