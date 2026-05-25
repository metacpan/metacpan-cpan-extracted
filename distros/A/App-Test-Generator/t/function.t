#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use Readonly;
use Scalar::Util qw(looks_like_number);

# Allow access to private helpers via the package namespace
BEGIN {
	use_ok('App::Test::Generator');
	use_ok('App::Test::Generator::Mutator');
	use_ok('App::Test::Generator::Mutant');
}

# --------------------------------------------------
# Constants used across multiple subtests to avoid
# magic literals and make intent clear
# --------------------------------------------------
Readonly my $EMPTY_STRING  => '';
Readonly my $UNDEF_LITERAL => 'undef';

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
		return {
			line        => $args{line}        // 1,
			original    => $args{original}    // 'x',
			description => $args{description} // 'test',
			context     => $args{context}     // '',
			line_content => $args{line_content} // '',
		};
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
	my $noop = {
		line        => 1,
		original    => 'x + 0',
		description => 'add zero',
		context     => '',
		line_content => '',
	};
	my $result = $fn->([$noop]);
	is(scalar(@{$result}), 0, '+0 no-op removed as redundant');

	# -0 arithmetic no-op must also be filtered
	my $noop2 = {
		line        => 1,
		original    => 'x - 0',
		description => 'sub zero',
		context     => '',
		line_content => '',
	};
	$result = $fn->([$noop2]);
	is(scalar(@{$result}), 0, '-0 no-op removed as redundant');

	done_testing();
};

# ==================================================================
# _is_redundant_mutation()
# ==================================================================
subtest 'Mutator::_is_redundant_mutation - arithmetic no-ops are redundant' => sub {
	my $fn = \&App::Test::Generator::Mutator::_is_redundant_mutation;

	ok($fn->({ original => 'x + 0' }), '+0 is redundant');
	ok($fn->({ original => 'x - 0' }), '-0 is redundant');
	ok(!$fn->({ original => 'x + 1' }), '+1 is not redundant');

	done_testing();
};

subtest 'Mutator::_is_redundant_mutation - double negation in conditional' => sub {
	my $fn = \&App::Test::Generator::Mutator::_is_redundant_mutation;

	ok(
		$fn->({ original => '!!$x', context => 'conditional' }),
		'double negation in conditional is redundant'
	);
	ok(
		!$fn->({ original => '!!$x', context => '' }),
		'double negation outside conditional is not redundant'
	);

	done_testing();
};

subtest 'Mutator::_is_redundant_mutation - boolean literal flip is redundant' => sub {
	my $fn = \&App::Test::Generator::Mutator::_is_redundant_mutation;

	ok($fn->({ original => '1' }), 'standalone 1 is redundant');
	ok($fn->({ original => '0' }), 'standalone 0 is redundant');
	ok(!$fn->({ original => '42' }), 'non-boolean integer is not redundant');

	done_testing();
};

subtest 'Mutator::_is_redundant_mutation - comment lines are redundant' => sub {
	my $fn = \&App::Test::Generator::Mutator::_is_redundant_mutation;

	ok(
		$fn->({ original => 'x', line_content => '# a comment' }),
		'mutation on comment line is redundant'
	);
	ok(
		!$fn->({ original => 'x', line_content => 'my $x = 1;' }),
		'mutation on code line is not redundant'
	);

	done_testing();
};

done_testing();
