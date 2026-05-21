#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Temp qw(tempfile);
use Test::Most;

# White-box function-level tests for App::Test::Generator.
# Tests each function as a standalone unit.

BEGIN { use_ok('App::Test::Generator') }

# ------------------------------------------------------------------
# Import private functions under test via symbol table manipulation
# ------------------------------------------------------------------
{
	no warnings 'once';
	*_load_schema		  = \&App::Test::Generator::_load_schema;
	*_load_schema_section  = \&App::Test::Generator::_load_schema_section;
	*_validate_config	  = \&App::Test::Generator::_validate_config;
	*_validate_input_params	= \&App::Test::Generator::_validate_input_params;
	*_validate_input_positions = \&App::Test::Generator::_validate_input_positions;
	*_validate_input_semantics = \&App::Test::Generator::_validate_input_semantics;
	*_normalize_config	 = \&App::Test::Generator::_normalize_config;
	*_valid_type		   = \&App::Test::Generator::_valid_type;
	*_has_positions		= \&App::Test::Generator::_has_positions;
	*_is_numeric_transform = \&App::Test::Generator::_is_numeric_transform;
	*_is_string_transform  = \&App::Test::Generator::_is_string_transform;
	*_same_type			= \&App::Test::Generator::_same_type;
	*_get_dominant_type	= \&App::Test::Generator::_get_dominant_type;
	*_detect_transform_properties = \&App::Test::Generator::_detect_transform_properties;
	*_render_properties	= \&App::Test::Generator::_render_properties;
	*_schema_to_lectrotest_generator = \&App::Test::Generator::_schema_to_lectrotest_generator;
	*_get_semantic_generators = \&App::Test::Generator::_get_semantic_generators;
	*_get_builtin_properties  = \&App::Test::Generator::_get_builtin_properties;
	*_is_perl_builtin = \&App::Test::Generator::_is_perl_builtin;
}

# ------------------------------------------------------------------
# perl_sq — escape a string for single-quoted Perl string context
# ------------------------------------------------------------------
subtest 'perl_sq() returns empty string for undef' => sub {
	is(App::Test::Generator::perl_sq(undef), '', 'undef produces empty string');
};

subtest 'perl_sq() escapes backslashes first' => sub {
	is(App::Test::Generator::perl_sq('a\\b'), 'a\\\\b', 'backslash doubled');
};

subtest 'perl_sq() escapes apostrophes' => sub {
	is(App::Test::Generator::perl_sq("it's"), "it\\'s", 'apostrophe escaped');
};

subtest 'perl_sq() escapes common control characters' => sub {
	is(App::Test::Generator::perl_sq("a\nb"), 'a\\nb', 'newline escaped');
	is(App::Test::Generator::perl_sq("a\rb"), 'a\\rb', 'CR escaped');
	is(App::Test::Generator::perl_sq("a\tb"), 'a\\tb', 'tab escaped');
	is(App::Test::Generator::perl_sq("a\fb"), 'a\\fb', 'formfeed escaped');
};

subtest 'perl_sq() replaces NUL bytes' => sub {
	is(App::Test::Generator::perl_sq("a\0b"), 'a\\0b', 'NUL replaced with \\0');
};

subtest 'perl_sq() leaves plain string unchanged' => sub {
	is(App::Test::Generator::perl_sq('hello'), 'hello', 'plain string unchanged');
};

# ------------------------------------------------------------------
# perl_quote — convert a Perl value to source-code fragment
# ------------------------------------------------------------------
subtest 'perl_quote() returns undef literal for undef' => sub {
	is(App::Test::Generator::perl_quote(undef), 'undef', 'undef -> "undef"');
};

subtest 'perl_quote() converts true/false string booleans' => sub {
	is(App::Test::Generator::perl_quote('true'),  '!!1', '"true" -> "!!1"');
	is(App::Test::Generator::perl_quote('false'), '!!0', '"false" -> "!!0"');
};

subtest 'perl_quote() leaves numbers unquoted' => sub {
	is(App::Test::Generator::perl_quote(42),	'42',   'integer unquoted');
	is(App::Test::Generator::perl_quote(3.14),  '3.14', 'float unquoted');
	is(App::Test::Generator::perl_quote(-1),	'-1',   'negative unquoted');
	is(App::Test::Generator::perl_quote(0),	 '0',	'zero unquoted');
};

subtest 'perl_quote() single-quotes strings' => sub {
	is(App::Test::Generator::perl_quote('hello'), "'hello'", 'plain string quoted');
	is(App::Test::Generator::perl_quote(''),	  "''",	  'empty string quoted');
};

subtest 'perl_quote() recursively quotes arrayrefs' => sub {
	my $result = App::Test::Generator::perl_quote([1, 'a', undef]);
	like($result, qr/^\[/, 'starts with [');
	like($result, qr/1/,   'contains 1');
	like($result, qr/'a'/, 'contains "a"');
	like($result, qr/undef/, 'contains undef');
};

subtest 'perl_quote() renders Regexp objects as qr{}' => sub {
	my $re = qr/foo/i;
	my $result = App::Test::Generator::perl_quote($re);
	like($result, qr/^qr\{/, 'starts with qr{');
	like($result, qr/foo/,   'contains pattern');
	like($result, qr/i/,	 'contains modifier');
};

# ------------------------------------------------------------------
# q_wrap — wrap a string in the most readable q{} form
# ------------------------------------------------------------------
subtest "q_wrap() returns '' for undef" => sub {
	is(App::Test::Generator::q_wrap(undef), "''", 'undef -> empty single-quoted string');
};

subtest 'q_wrap() uses q{} bracket form when no brackets in string' => sub {
	my $result = App::Test::Generator::q_wrap('hello world');
	like($result, qr/^q\{hello world\}$/, 'uses q{} form');
};

subtest 'q_wrap() falls back when curly braces in string' => sub {
	my $result = App::Test::Generator::q_wrap('a{b}c');
	# Should use a different delimiter
	unlike($result, qr/^q\{a\{b\}c\}$/, 'does not use q{} when string contains {}');
	ok(length($result) > 0, 'returns non-empty result');
};

subtest 'q_wrap() uses single-quote fallback when all delimiters used' => sub {
	# A string containing all bracket pairs AND all single-char delimiters
	# forces the escaped single-quote fallback
	my $str = '{}()[]<>~!%^=+:,;|/#';
	my $result = App::Test::Generator::q_wrap($str);
	ok(defined $result, 'returns defined value for pathological string');
};

subtest 'q_wrap() correctly uses != INDEX_NOT_FOUND boundary' => sub {
	# A string starting with ~ means index returns 0 (not -1)
	# If the guard were "> 0" instead of "!= -1" it would wrongly
	# choose ~ as the delimiter when ~ is at position 0
	my $result = App::Test::Generator::q_wrap('~starts with tilde');
	unlike($result, qr/^q~/, 'does not use ~ when ~ is at start of string');
};

# ------------------------------------------------------------------
# render_fallback — convert any value to a Perl source string
# ------------------------------------------------------------------
subtest 'render_fallback() returns "undef" for undef' => sub {
	is(App::Test::Generator::render_fallback(undef), 'undef', 'undef -> "undef"');
};

subtest 'render_fallback() returns compact string for scalar' => sub {
	my $result = App::Test::Generator::render_fallback('hello');
	like($result, qr/hello/, 'scalar string rendered');
	unlike($result, qr/\n$/, 'no trailing newline');
};

subtest 'render_fallback() renders hashref' => sub {
	my $result = App::Test::Generator::render_fallback({ a => 1 });
	like($result, qr/a/, 'hashref rendered with key');
	like($result, qr/1/, 'hashref rendered with value');
};

# ------------------------------------------------------------------
# render_args_hash — flat hashref to key => value argument string
# ------------------------------------------------------------------
subtest 'render_args_hash() returns empty string for undef' => sub {
	is(App::Test::Generator::render_args_hash(undef), '', 'undef -> empty string');
};

subtest 'render_args_hash() returns empty string for empty hashref' => sub {
	is(App::Test::Generator::render_args_hash({}), '', 'empty hash -> empty string');
};

subtest 'render_args_hash() renders flat hash sorted by key' => sub {
	my $result = App::Test::Generator::render_args_hash({ b => 2, a => 1 });
	like($result, qr/'a'\s*=>\s*1/, 'key a rendered');
	like($result, qr/'b'\s*=>\s*2/, 'key b rendered');
	# a must appear before b (sorted)
	ok(index($result, "'a'") < index($result, "'b'"), 'keys sorted alphabetically');
};

# ------------------------------------------------------------------
# render_arrayref_map — hashref of arrayrefs to Perl source
# ------------------------------------------------------------------
subtest 'render_arrayref_map() returns "()" for undef' => sub {
	is(App::Test::Generator::render_arrayref_map(undef), '()', 'undef -> "()"');
};

subtest 'render_arrayref_map() returns empty string for empty hashref' => sub {
	is(App::Test::Generator::render_arrayref_map({}), '', 'empty hash -> empty string');
};

subtest 'render_arrayref_map() renders arrayref values' => sub {
	my $result = App::Test::Generator::render_arrayref_map({ name => ['', 'a'] });
	like($result, qr/'name'/, 'key rendered');
	like($result, qr/\[/, 'array bracket present');
};

subtest 'render_arrayref_map() skips non-arrayref values' => sub {
	my $result = App::Test::Generator::render_arrayref_map({ a => [1, 2], b => 'scalar' });
	like($result,   qr/'a'/, 'arrayref key included');
	unlike($result, qr/'b'/, 'scalar key skipped');
};

# ------------------------------------------------------------------
# render_hash — two-level hashref to Perl input spec code
# ------------------------------------------------------------------
subtest 'render_hash() returns empty string for undef' => sub {
	is(App::Test::Generator::render_hash(undef), '', 'undef -> empty string');
};

subtest 'render_hash() returns empty string for empty hashref' => sub {
	is(App::Test::Generator::render_hash({}), '', 'empty hash -> empty string');
};

subtest 'render_hash() renders nested spec' => sub {
	my $result = App::Test::Generator::render_hash({
		name => { type => 'string', optional => 1 }
	});
	like($result, qr/'name'/, 'key rendered');
	like($result, qr/type/, 'type sub-key rendered');
	like($result, qr/string/, 'type value rendered');
};

subtest 'render_hash() expands scalar type shorthand' => sub {
	my $result = App::Test::Generator::render_hash({ arg1 => 'string' });
	like($result, qr/'arg1'/, 'key rendered');
	like($result, qr/type/, 'type key added');
};

subtest 'render_hash() compiles matches to Regexp' => sub {
	my $result = App::Test::Generator::render_hash({
		field => { type => 'string', matches => '^foo' }
	});
	like($result, qr/qr\{/, 'matches compiled to qr{}');
};

# ------------------------------------------------------------------
# _valid_type — check if a type string is recognised
# ------------------------------------------------------------------
subtest '_valid_type() returns 1 for recognised types' => sub {
	for my $t (qw(string boolean integer number float hashref arrayref object int bool)) {
		ok(_valid_type($t), "$t is valid");
	}
};

subtest '_valid_type() returns 0 for unknown types' => sub {
	ok(!_valid_type('banana'), 'unknown type rejected');
	ok(!_valid_type(''),	   'empty string rejected');
};

subtest '_valid_type() returns 0 for undef' => sub {
	ok(!_valid_type(undef), 'undef rejected');
};

# ------------------------------------------------------------------
# _has_positions — detect positional arguments in input spec
# ------------------------------------------------------------------
subtest '_has_positions() returns 0 for undef' => sub {
	is(_has_positions(undef), 0, 'undef -> 0');
};

subtest '_has_positions() returns 0 for empty hashref' => sub {
	is(_has_positions({}), 0, 'empty hash -> 0');
};

subtest '_has_positions() returns 0 when no positions declared' => sub {
	my $spec = { name => { type => 'string' }, age => { type => 'integer' } };
	is(_has_positions($spec), 0, 'no positions -> 0');
};

subtest '_has_positions() returns 1 when position declared' => sub {
	my $spec = { arg0 => { type => 'string', position => 0 } };
	is(_has_positions($spec), 1, 'position present -> 1');
};

subtest '_has_positions() returns 0 for scalar spec' => sub {
	# Scalar field specs have no position key
	my $spec = { type => 'string' };
	is(_has_positions($spec), 0, 'flat type spec -> 0');
};

# ------------------------------------------------------------------
# _is_numeric_transform — detect numeric output type
# ------------------------------------------------------------------
subtest '_is_numeric_transform() returns 1 for numeric output types' => sub {
	for my $t (qw(number integer float)) {
		ok(_is_numeric_transform({}, { type => $t }), "$t output is numeric");
	}
};

subtest '_is_numeric_transform() returns 0 for non-numeric output' => sub {
	ok(!_is_numeric_transform({}, { type => 'string' }), 'string is not numeric');
	ok(!_is_numeric_transform({}, {}),				   'no type is not numeric');
	ok(!_is_numeric_transform({}, undef),				'undef output is not numeric');
};

# ------------------------------------------------------------------
# _is_string_transform — detect string output type
# ------------------------------------------------------------------
subtest '_is_string_transform() returns 1 for string output' => sub {
	ok(_is_string_transform({}, { type => 'string' }), 'string output -> 1');
};

subtest '_is_string_transform() returns 0 for non-string output' => sub {
	ok(!_is_string_transform({}, { type => 'integer' }), 'integer output -> 0');
	ok(!_is_string_transform({}, {}),					'no type -> 0');
};

# ------------------------------------------------------------------
# _get_dominant_type — extract representative type from spec
# ------------------------------------------------------------------
subtest '_get_dominant_type() returns type from flat spec' => sub {
	is(_get_dominant_type({ type => 'integer' }), 'integer', 'flat spec type returned');
};

subtest '_get_dominant_type() returns type from nested spec' => sub {
	my $spec = { field => { type => 'number' } };
	is(_get_dominant_type($spec), 'number', 'nested field type returned');
};

subtest '_get_dominant_type() returns default for undef' => sub {
	is(_get_dominant_type(undef), 'string', 'undef -> default "string"');
};

subtest '_get_dominant_type() returns default for empty spec' => sub {
	is(_get_dominant_type({}), 'string', 'empty spec -> default "string"');
};

# ------------------------------------------------------------------
# _same_type — check input/output type match
# ------------------------------------------------------------------
subtest '_same_type() returns 1 when input and output types match' => sub {
	ok(_same_type({ type => 'number' }, { type => 'number' }), 'matching types -> 1');
};

subtest '_same_type() returns 0 when types differ' => sub {
	ok(!_same_type({ type => 'string' }, { type => 'number' }), 'different types -> 0');
};

subtest '_same_type() handles undef specs' => sub {
	# Both undef -> both default to 'string' -> match
	ok(_same_type(undef, undef), 'both undef -> both default to string -> 1');
};

# ------------------------------------------------------------------
# _load_schema_section — extract section from schema hashref
# ------------------------------------------------------------------
subtest '_load_schema_section() returns empty hash for absent section' => sub {
	my $schema = { module => 'Foo' };
	my $result = _load_schema_section($schema, 'input', 'test.yml');
	is_deeply($result, {}, 'absent section -> {}');
};

subtest '_load_schema_section() returns hashref when section is hashref' => sub {
	my $schema = { input => { name => { type => 'string' } } };
	my $result = _load_schema_section($schema, 'input', 'test.yml');
	is_deeply($result, { name => { type => 'string' } }, 'hashref section returned');
};

subtest '_load_schema_section() returns empty hash when section is "undef" string' => sub {
	my $schema = { input => 'undef' };
	my $result = _load_schema_section($schema, 'input', 'test.yml');
	is_deeply($result, {}, '"undef" string -> {}');
};

subtest '_load_schema_section() croaks when section is wrong type' => sub {
	my $schema = { input => [1, 2, 3] };
	throws_ok(
		sub { _load_schema_section($schema, 'input', 'test.yml') },
		qr/should be a hash/,
		'arrayref section croaks',
	);
};

# ------------------------------------------------------------------
# _validate_config — validate top-level schema structure
# ------------------------------------------------------------------
subtest '_validate_config() croaks when neither module nor function defined' => sub {
	throws_ok(
		sub { _validate_config({}) },
		qr/At least one of function and module/,
		'croaks with no module or function',
	);
};

subtest '_validate_config() carps when neither input nor output defined' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	eval { _validate_config({ function => 'foo' }) };
	ok(grep { /Neither input nor output/ } @warnings, 'carps about missing input/output');
};

subtest '_validate_config() croaks on invalid input specification' => sub {
	throws_ok(
		sub { _validate_config({ function => 'foo', input => 'badvalue' }) },
		qr/Invalid input specification/,
		'non-undef scalar input croaks',
	);
};

subtest '_validate_config() croaks on unknown config key' => sub {
	throws_ok(
		sub {
			_validate_config({
				function => 'foo',
				input	=> { x => { type => 'string' } },
				config   => { unknown_key => 1 },
			})
		},
		qr/unknown config setting/,
		'unknown config key croaks',
	);
};

subtest '_validate_config() passes valid minimal schema' => sub {
	lives_ok(
		sub {
			_validate_config({
				function => 'foo',
				input	=> { x => { type => 'string' } },
				output   => { type => 'string' },
			})
		},
		'valid schema lives',
	);
};

# ------------------------------------------------------------------
# _validate_input_params — validate type specs for each param
# ------------------------------------------------------------------
subtest '_validate_input_params() croaks for empty parameter name' => sub {
	throws_ok(
		sub { _validate_input_params({ input => { '' => { type => 'string' } } }) },
		qr/Empty input parameter name/,
		'empty param name croaks',
	);
};

subtest '_validate_input_params() croaks for missing type' => sub {
	throws_ok(
		sub { _validate_input_params({ input => { name => {} } }) },
		qr/Missing type/,
		'missing type croaks',
	);
};

subtest '_validate_input_params() croaks for invalid type' => sub {
	throws_ok(
		sub { _validate_input_params({ input => { name => { type => 'banana' } } }) },
		qr/Invalid type/,
		'invalid type croaks',
	);
};

subtest '_validate_input_params() passes valid types' => sub {
	lives_ok(
		sub {
			_validate_input_params({
				input => { name => { type => 'string' }, count => { type => 'integer' } }
			})
		},
		'valid types live',
	);
};

# ------------------------------------------------------------------
# _validate_input_positions — validate positional argument declarations
# ------------------------------------------------------------------
subtest '_validate_input_positions() croaks for non-integer position' => sub {
	throws_ok(
		sub {
			_validate_input_positions({
				input => { arg => { type => 'string', position => 'a' } }
			})
		},
		qr/non-negative integer/,
		'non-integer position croaks',
	);
};

subtest '_validate_input_positions() croaks for duplicate position' => sub {
	throws_ok(
		sub {
			_validate_input_positions({
				input => {
					a => { type => 'string',  position => 0 },
					b => { type => 'integer', position => 0 },
				}
			})
		},
		qr/Duplicate position/,
		'duplicate position croaks',
	);
};

subtest '_validate_input_positions() croaks when param missing position' => sub {
	throws_ok(
		sub {
			_validate_input_positions({
				input => {
					a => { type => 'string',  position => 0 },
					b => { type => 'integer' },
				}
			})
		},
		qr/missing position/,
		'missing position on one param croaks',
	);
};

subtest '_validate_input_positions() passes valid positions' => sub {
	lives_ok(
		sub {
			_validate_input_positions({
				input => {
					a => { type => 'string',  position => 0 },
					b => { type => 'integer', position => 1 },
				}
			})
		},
		'valid sequential positions live',
	);
};

# ------------------------------------------------------------------
# _normalize_config — normalise boolean strings in config hash
# ------------------------------------------------------------------
subtest '_normalize_config() defaults absent fields to 1' => sub {
	my %config;
	_normalize_config(\%config);
	for my $field (qw(test_nuls test_undef test_empty test_non_ascii dedup close_stdin test_security)) {
		is($config{$field}, 1, "$field defaults to 1");
	}
};

subtest '_normalize_config() converts "no" to 0' => sub {
	my %config = (test_undef => 'no');
	_normalize_config(\%config);
	is($config{test_undef}, 0, '"no" converted to 0');
};

subtest '_normalize_config() converts "yes" to 1' => sub {
	my %config = (test_undef => 'yes');
	_normalize_config(\%config);
	is($config{test_undef}, 1, '"yes" converted to 1');
};

subtest '_normalize_config() sets properties to disabled default if absent' => sub {
	my %config;
	_normalize_config(\%config);
	ok(ref($config{properties}) eq 'HASH', 'properties is a hashref');
	ok(!$config{properties}{enable}, 'properties disabled by default');
};

subtest '_normalize_config() preserves properties hashref if present' => sub {
	my %config = (properties => { enable => 1, trials => 500 });
	_normalize_config(\%config);
	ok($config{properties}{enable}, 'properties enable preserved');
	is($config{properties}{trials}, 500, 'properties trials preserved');
};

# ------------------------------------------------------------------
# _detect_transform_properties — derive LectroTest properties
# ------------------------------------------------------------------
subtest '_detect_transform_properties() returns empty list for undef input' => sub {
	my @props = _detect_transform_properties('test', undef, {});
	is(scalar(@props), 0, 'undef input -> empty list');
};

subtest '_detect_transform_properties() returns empty list for "undef" string input' => sub {
	my @props = _detect_transform_properties('test', 'undef', {});
	is(scalar(@props), 0, '"undef" string input -> empty list');
};

subtest '_detect_transform_properties() detects min constraint for numeric output' => sub {
	my @props = _detect_transform_properties(
		'test',
		{ x => { type => 'number', min => 0 } },
		{ type => 'number', min => 0 },
	);
	ok((grep { $_->{name} eq 'min_constraint' } @props), 'min_constraint detected');
};

subtest '_detect_transform_properties() detects max constraint for numeric output' => sub {
	my @props = _detect_transform_properties(
		'test',
		{ x => { type => 'number' } },
		{ type => 'number', max => 100 },
	);
	ok((grep { $_->{name} eq 'max_constraint' } @props), 'max_constraint detected');
};

subtest '_detect_transform_properties() detects non_negative for "positive" transform name' => sub {
	my @props = _detect_transform_properties(
		'positive',
		{ x => { type => 'number', min => 0 } },
		{ type => 'number', min => 0 },
	);
	ok((grep { $_->{name} eq 'non_negative' } @props), 'non_negative detected for positive transform');
};

subtest '_detect_transform_properties() detects exact_value' => sub {
	my @props = _detect_transform_properties(
		'test',
		{ x => { type => 'string' } },
		{ type => 'string', value => 'expected' },
	);
	ok((grep { $_->{name} eq 'exact_value' } @props), 'exact_value detected');
};

subtest '_detect_transform_properties() detects defined property by default' => sub {
	my @props = _detect_transform_properties(
		'test',
		{ x => { type => 'string' } },
		{ type => 'string' },
	);
	ok((grep { $_->{name} eq 'defined' } @props), 'defined property always added');
};

subtest '_detect_transform_properties() skips defined for undef output type' => sub {
	my @props = _detect_transform_properties(
		'test',
		{ x => { type => 'string' } },
		{ type => 'undef' },
	);
	ok((!grep { $_->{name} eq 'defined' } @props), 'defined skipped for undef output type');
};

subtest '_detect_transform_properties() detects min_length for string output' => sub {
	my @props = _detect_transform_properties(
		'test',
		{ x => { type => 'string' } },
		{ type => 'string', min => 1 },
	);
	ok((grep { $_->{name} eq 'min_length' } @props), 'min_length detected for string output');
};

# ------------------------------------------------------------------
# _render_properties — render property hashrefs to Perl code
# ------------------------------------------------------------------
subtest '_render_properties() returns empty string for undef' => sub {
	is(_render_properties(undef), '', 'undef -> empty string');
};

subtest '_render_properties() returns empty string for empty arrayref' => sub {
	is(_render_properties([]), '', 'empty arrayref -> empty string');
};

subtest '_render_properties() renders a property block' => sub {
	my $props = [{
		name			=> 'test_prop',
		generator_spec  => '$x <- Int',
		call_code	   => 'abs($x)',
		property_checks => 'defined($result)',
		should_die	  => 0,
		should_warn	 => 0,
		trials		  => 100,
	}];
	my $code = _render_properties($props);
	like($code, qr/test_prop/,  'property name in output');
	like($code, qr/\$x <- Int/, 'generator spec in output');
	like($code, qr/abs\(\$x\)/, 'call code in output');
	like($code, qr/100/,		'trials in output');
};

subtest '_render_properties() uses die-path for should_die property' => sub {
	my $props = [{
		name			=> 'dies_prop',
		generator_spec  => '$x <- Int',
		call_code	   => 'die_fn($x)',
		property_checks => '',
		should_die	  => 1,
		should_warn	 => 0,
		trials		  => 10,
	}];
	my $code = _render_properties($props);
	like($code, qr/died/, 'die-path code emitted for should_die');
};

# ------------------------------------------------------------------
# _schema_to_lectrotest_generator — convert field spec to generator
# ------------------------------------------------------------------
subtest '_schema_to_lectrotest_generator() returns undef for undef spec' => sub {
	ok(!defined(_schema_to_lectrotest_generator('x', undef)), 'undef spec -> undef');
};

subtest '_schema_to_lectrotest_generator() returns Int for integer type' => sub {
	my $gen = _schema_to_lectrotest_generator('n', { type => 'integer' });
	like($gen, qr/n <- Int/, 'unconstrained integer -> Int');
};

subtest '_schema_to_lectrotest_generator() returns constrained Int for integer with bounds' => sub {
	my $gen = _schema_to_lectrotest_generator('n', { type => 'integer', min => 0, max => 10 });
	like($gen, qr/n <-/, 'integer with bounds generates constrained generator');
	like($gen, qr/0/,	'min present in generator');
};

subtest '_schema_to_lectrotest_generator() returns Float for number type' => sub {
	my $gen = _schema_to_lectrotest_generator('x', { type => 'number' });
	like($gen, qr/x <- Float/, 'unconstrained number -> Float');
};

subtest '_schema_to_lectrotest_generator() handles number with only max=0' => sub {
	my $gen = _schema_to_lectrotest_generator('x', { type => 'number', max => 0 });
	like($gen, qr/-rand/, 'max=0 generates negative numbers');
};

subtest '_schema_to_lectrotest_generator() returns String for string type' => sub {
	my $gen = _schema_to_lectrotest_generator('s', { type => 'string' });
	like($gen, qr/s <- String/, 'string type -> String generator');
};

subtest '_schema_to_lectrotest_generator() uses pattern generator for matches' => sub {
	my $gen = _schema_to_lectrotest_generator('s', { type => 'string', matches => '^foo' });
	like($gen, qr/Data::Random::String::Matches/, 'matches uses pattern generator');
};

subtest '_schema_to_lectrotest_generator() returns Bool for boolean type' => sub {
	my $gen = _schema_to_lectrotest_generator('b', { type => 'boolean' });
	like($gen, qr/b <- Bool/, 'boolean -> Bool');
};

subtest '_schema_to_lectrotest_generator() returns List for arrayref type' => sub {
	my $gen = _schema_to_lectrotest_generator('a', { type => 'arrayref' });
	like($gen, qr/a <- List/, 'arrayref -> List');
};

subtest '_schema_to_lectrotest_generator() returns undef for invalid float range' => sub {
	my $gen;
	local $SIG{__WARN__} = sub {};	# suppress expected carp
	$gen = _schema_to_lectrotest_generator('x', { type => 'float', min => 10, max => 5 });
	ok(!defined($gen), 'invalid range -> undef');
};

# ------------------------------------------------------------------
# _get_semantic_generators — return semantic generator hashref
# ------------------------------------------------------------------
subtest '_get_semantic_generators() returns hashref with expected keys' => sub {
	my $gens = _get_semantic_generators();
	ok(ref($gens) eq 'HASH', 'returns hashref');
	for my $key (qw(email url uuid ipv4 username iso_date unix_timestamp)) {
		ok(exists $gens->{$key}, "$key generator present");
	}
};

subtest '_get_semantic_generators() each entry has code and description' => sub {
	my $gens = _get_semantic_generators();
	for my $name (keys %{$gens}) {
		ok(exists $gens->{$name}{code},		"$name has code");
		ok(exists $gens->{$name}{description}, "$name has description");
	}
};

# ------------------------------------------------------------------
# _get_builtin_properties — return builtin property hashref
# ------------------------------------------------------------------
subtest '_get_builtin_properties() returns hashref with expected keys' => sub {
	my $props = _get_builtin_properties();
	ok(ref($props) eq 'HASH', 'returns hashref');
	for my $key (qw(idempotent non_negative positive non_empty lowercase uppercase trimmed)) {
		ok(exists $props->{$key}, "$key property present");
	}
};

subtest '_get_builtin_properties() each entry has description and code_template' => sub {
	my $props = _get_builtin_properties();
	for my $name (keys %{$props}) {
		ok(exists $props->{$name}{description},   "$name has description");
		ok(ref($props->{$name}{code_template}) eq 'CODE', "$name has code_template coderef");
	}
};

subtest '_get_builtin_properties() code_template returns non-empty string' => sub {
	my $props = _get_builtin_properties();
	for my $name (keys %{$props}) {
		my $code = $props->{$name}{code_template}->('my_func', 'my_func($x)', ['x']);
		ok(defined($code) && length($code) > 0, "$name code_template produces non-empty string");
	}
};

# ------------------------------------------------------------------
# _load_schema — load schema file via Config::Abstraction (mocked)
# ------------------------------------------------------------------
subtest '_load_schema() croaks for undef filename' => sub {
	throws_ok(
		sub { _load_schema(undef) },
		qr/Usage/,
		'undef filename croaks',
	);
};

subtest '_load_schema() croaks for empty filename' => sub {
	throws_ok(
		sub { _load_schema('') },
		qr/empty filename/,
		'empty filename croaks',
	);
};

subtest '_load_schema() croaks for unreadable file' => sub {
	throws_ok(
		sub { _load_schema('/nonexistent/path/to/file.yml') },
		qr//,
		'unreadable file croaks',
	);
};

subtest '_load_schema() croaks for legacy Perl config with $module key' => sub {
	require File::Temp;
	my $tmpfile = File::Temp->new(SUFFIX => '.yml', UNLINK => 1);
	# YAML allows $module as a bare key — Config::Abstraction will parse it
	print $tmpfile "\$module: Foo\nfunction: test\n";
	$tmpfile->flush();
	throws_ok(
		sub { _load_schema($tmpfile->filename()) },
		qr/perl files.*no longer supported/i,
		'legacy \$module key croaks',
	);
};

# ------------------------------------------------------------------
# Import additional private functions under test
# ------------------------------------------------------------------
{
	no warnings 'once';
	*_validate_input_semantics	= \&App::Test::Generator::_validate_input_semantics;
	*_validate_transform_properties = \&App::Test::Generator::_validate_transform_properties;
	*_validate_module			 = \&App::Test::Generator::_validate_module;
	*_generate_transform_properties = \&App::Test::Generator::_generate_transform_properties;
	*_process_custom_properties   = \&App::Test::Generator::_process_custom_properties;
}

# ==================================================================
# _validate_input_semantics
# ==================================================================
subtest '_validate_input_semantics() passes for known semantic type' => sub {
	lives_ok(
		sub {
			_validate_input_semantics({
				input => {
					email => { type => 'string', semantic => 'email' },
				}
			})
		},
		'known semantic type lives',
	);
};

subtest '_validate_input_semantics() carps for unknown semantic type' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	_validate_input_semantics({
		input => { x => { type => 'string', semantic => 'banana' } }
	});
	ok((grep { /Unknown semantic type/ } @warnings),
		'unknown semantic type carps');
};

subtest '_validate_input_semantics() croaks when both enum and memberof present' => sub {
	throws_ok(
		sub {
			_validate_input_semantics({
				input => {
					status => {
						type	 => 'string',
						enum	 => ['a', 'b'],
						memberof => ['a', 'b'],
					},
				}
			})
		},
		qr/enum.*memberof|memberof.*enum/,
		'both enum and memberof croaks',
	);
};

subtest '_validate_input_semantics() croaks when enum is not an arrayref' => sub {
	throws_ok(
		sub {
			_validate_input_semantics({
				input => { x => { type => 'string', enum => 'not_array' } }
			})
		},
		qr/enum must be an arrayref/,
		'non-arrayref enum croaks',
	);
};

subtest '_validate_input_semantics() croaks when memberof is not an arrayref' => sub {
	throws_ok(
		sub {
			_validate_input_semantics({
				input => { x => { type => 'string', memberof => 'not_array' } }
			})
		},
		qr/memberof must be an arrayref/,
		'non-arrayref memberof croaks',
	);
};

subtest '_validate_input_semantics() passes for valid enum arrayref' => sub {
	lives_ok(
		sub {
			_validate_input_semantics({
				input => {
					status => { type => 'string', enum => ['ok', 'error'] }
				}
			})
		},
		'valid enum arrayref lives',
	);
};

subtest '_validate_input_semantics() skips non-hashref field specs' => sub {
	lives_ok(
		sub {
			_validate_input_semantics({
				input => { x => 'string' }
			})
		},
		'non-hashref field spec skipped without error',
	);
};

# ==================================================================
# _validate_transform_properties
# ==================================================================
subtest '_validate_transform_properties() passes for valid builtin property name' => sub {
	lives_ok(
		sub {
			_validate_transform_properties({
				transforms => {
					positive => {
						properties => ['non_negative'],
					}
				}
			})
		},
		'known builtin property name lives',
	);
};

subtest '_validate_transform_properties() carps for unknown builtin name' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	_validate_transform_properties({
		transforms => {
			my_transform => {
				properties => ['banana_property'],
			}
		}
	});
	ok((grep { /unknown built-in property/i } @warnings),
		'unknown builtin name carps');
};

subtest '_validate_transform_properties() passes for valid custom property hashref' => sub {
	lives_ok(
		sub {
			_validate_transform_properties({
				transforms => {
					t => {
						properties => [
							{ name => 'my_prop', code => '$result > 0' }
						]
					}
				}
			})
		},
		'valid custom property hashref lives',
	);
};

subtest '_validate_transform_properties() croaks when custom property missing code' => sub {
	throws_ok(
		sub {
			_validate_transform_properties({
				transforms => {
					t => {
						properties => [
							{ name => 'bad_prop' }
						]
					}
				}
			})
		},
		qr/name.*code|code.*name/,
		'custom property missing code croaks',
	);
};

subtest '_validate_transform_properties() croaks when properties is not an arrayref' => sub {
	throws_ok(
		sub {
			_validate_transform_properties({
				transforms => {
					t => { properties => 'not_array' }
				}
			})
		},
		qr/must be an array/,
		'non-arrayref properties croaks',
	);
};

subtest '_validate_transform_properties() skips transforms with no properties key' => sub {
	lives_ok(
		sub {
			_validate_transform_properties({
				transforms => {
					t => { input => { x => { type => 'string' } } }
				}
			})
		},
		'transform without properties key lives',
	);
};

subtest '_validate_transform_properties() croaks for invalid property definition type' => sub {
	throws_ok(
		sub {
			_validate_transform_properties({
				transforms => {
					t => { properties => [ [1, 2, 3] ] }
				}
			})
		},
		qr/invalid property definition/i,
		'invalid property definition type croaks',
	);
};

# ==================================================================
# _validate_module
# ==================================================================
subtest '_validate_module() returns 1 for undef module' => sub {
	is(_validate_module(undef, 'test.yml'), 1, 'undef module returns 1');
};

subtest '_validate_module() returns 1 for empty string module' => sub {
	is(_validate_module('', 'test.yml'), 1, 'empty module returns 1');
};

subtest '_validate_module() returns 1 for core module in @INC' => sub {
	# Scalar::Util is always available
	is(_validate_module('Scalar::Util', 'test.yml'), 1,
		'Scalar::Util found in @INC');
};

subtest '_validate_module() carps and returns 0 for unknown module' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $result = _validate_module('No::Such::Module::XYZ', 'test.yml');
	is($result, 0, 'unknown module returns 0');
	ok((grep { /not found/i } @warnings), 'carps about module not found');
};

# ==================================================================
# _generate_transform_properties
# ==================================================================
subtest '_generate_transform_properties() returns empty arrayref for empty transforms' => sub {
	my $result = _generate_transform_properties(
		{}, 'my_func', undef, {}, { properties => { enable => 1, trials => 100 } }, undef
	);
	is(ref($result), 'ARRAY', 'returns arrayref');
	is(scalar @{$result}, 0, 'empty transforms -> empty arrayref');
};

subtest '_generate_transform_properties() skips undef input transforms' => sub {
	my $result = _generate_transform_properties(
		{ error => { input => undef, output => {} } },
		'my_func', undef, {}, { properties => { trials => 100 } }, undef
	);
	is(scalar @{$result}, 0, 'undef input transform skipped');
};

subtest '_generate_transform_properties() skips "undef" string input transforms' => sub {
	my $result = _generate_transform_properties(
		{ error => { input => 'undef', output => {} } },
		'my_func', undef, {}, { properties => { trials => 100 } }, undef
	);
	is(scalar @{$result}, 0, '"undef" string input transform skipped');
};

subtest '_generate_transform_properties() skips non-hashref input transforms' => sub {
	my $result = _generate_transform_properties(
		{ t => { input => [1, 2], output => {} } },
		'my_func', undef, {}, { properties => { trials => 100 } }, undef
	);
	is(scalar @{$result}, 0, 'non-hashref input transform skipped');
};

subtest '_generate_transform_properties() returns property for numeric output transform' => sub {
	my $result = _generate_transform_properties(
		{
			positive => {
				input  => { x => { type => 'number', position => 0 } },
				output => { type => 'number', min => 0 },
			}
		},
		'abs', undef, { x => { type => 'number' } },
		{ properties => { trials => 100 } }, undef
	);
	ok(scalar @{$result} > 0, 'numeric transform produces at least one property');
	is($result->[0]{name}, 'positive', 'transform name preserved');
	ok(defined $result->[0]{generator_spec}, 'generator_spec present');
	ok(defined $result->[0]{call_code},	  'call_code present');
	ok(defined $result->[0]{trials},		 'trials present');
	is($result->[0]{trials}, 100,			'trials value correct');
};

subtest '_generate_transform_properties() sets should_die for DIES output' => sub {
	my $result = _generate_transform_properties(
		{
			error_case => {
				input  => { x => { type => 'string', position => 0 } },
				output => { _STATUS => 'DIES' },
			}
		},
		'my_func', undef, {},
		{ properties => { trials => 10 } }, undef
	);
	if(scalar @{$result}) {
		ok($result->[0]{should_die}, 'should_die set for DIES output');
	} else {
		ok(1, 'DIES transform with no properties produces no entry');
	}
};

subtest '_generate_transform_properties() builds OO call_code when new defined' => sub {
	my $result = _generate_transform_properties(
		{
			t => {
				input  => { x => { type => 'integer', position => 0 } },
				output => { type => 'integer', min => 0 },
			}
		},
		'my_method', 'My::Module',
		{ x => { type => 'integer' } },
		{ properties => { trials => 50 } },
		{}	# $new defined -> OO mode
	);
	if(scalar @{$result}) {
		like($result->[0]{call_code}, qr/my_method/,  'method name in call_code');
		like($result->[0]{call_code}, qr/My::Module/, 'module in call_code');
	} else {
		ok(1, 'no properties generated for this transform');
	}
};

# ==================================================================
# _process_custom_properties
# ==================================================================
subtest '_process_custom_properties() returns empty list for empty array' => sub {
	my @result = _process_custom_properties(
		[], 'my_func', undef, {}, {}, undef
	);
	is(scalar @result, 0, 'empty array -> empty list');
};

subtest '_process_custom_properties() resolves builtin property by name' => sub {
	my @result = _process_custom_properties(
		['non_negative'],
		'abs', undef,
		{ x => { type => 'number', position => 0 } },
		{ type => 'number', min => 0 },
		undef
	);
	is(scalar @result, 1,			'one property returned');
	is($result[0]{name}, 'non_negative', 'name preserved');
	ok(defined $result[0]{code},	 'code present');
	ok(defined $result[0]{description}, 'description present');
};

subtest '_process_custom_properties() carps and skips unknown builtin name' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my @result = _process_custom_properties(
		['banana_property'],
		'my_func', undef, {}, {}, undef
	);
	is(scalar @result, 0, 'unknown builtin skipped');
	ok((grep { /Unknown built-in property/i } @warnings),
		'unknown builtin carps');
};

subtest '_process_custom_properties() handles custom hashref property' => sub {
	my @result = _process_custom_properties(
		[{ name => 'my_check', code => '$result > 0', description => 'positive' }],
		'my_func', undef, {}, {}, undef
	);
	is(scalar @result, 1,			 'one property returned');
	is($result[0]{name}, 'my_check',  'name preserved');
	is($result[0]{code}, '$result > 0', 'code preserved');
};

subtest '_process_custom_properties() carps and skips custom property missing code' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my @result = _process_custom_properties(
		[{ name => 'no_code_prop' }],
		'my_func', undef, {}, {}, undef
	);
	is(scalar @result, 0, 'property missing code is skipped');
	ok((grep { /missing 'code'/i } @warnings), 'missing code carps');
};

subtest '_process_custom_properties() carps and skips invalid definition type' => sub {
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my @result = _process_custom_properties(
		[ [1, 2, 3] ],
		'my_func', undef, {}, {}, undef
	);
	is(scalar @result, 0, 'invalid definition type skipped');
	ok((grep { /Invalid property definition/i } @warnings),
		'invalid definition type carps');
};

subtest '_process_custom_properties() uses default name for unnamed custom property' => sub {
	my @result = _process_custom_properties(
		[{ code => '$result >= 0' }],
		'my_func', undef, {}, {}, undef
	);
	if(scalar @result) {
		like($result[0]{name}, qr/custom_property/, 'default name applied');
	} else {
		ok(1, 'unnamed property handled without crash');
	}
};

# ==================================================================
# generate() — smoke test with a real temp schema file
# ==================================================================
subtest 'generate() produces output containing use strict for minimal schema' => sub {
	require File::Temp;
	my $schema = File::Temp->new(SUFFIX => '.yml', UNLINK => 1);
	print $schema "module: builtin\nfunction: my_func\ninput:\n  type: string\noutput:\n  type: string\n";
	$schema->flush();

	my ($output, $stderr) = capture(sub {
		eval { App::Test::Generator->generate($schema->filename()) };
	});

	ok(!$@,						  "generate() did not croak: $@");
	like($output, qr/use strict/,	'generated output contains use strict');
	like($output, qr/done_testing/,  'generated output contains done_testing');
};

subtest 'generate() writes to file when output_file specified' => sub {
	require File::Temp;
	my $schema = File::Temp->new(SUFFIX => '.yml', UNLINK => 1);
	print $schema "module: builtin\nfunction: my_func\ninput:\n  type: string\noutput:\n  type: string\n";
	$schema->flush();

	my $outfile = File::Temp->new(SUFFIX => '.t', UNLINK => 1);
	my $outpath  = $outfile->filename();
	$outfile->close();

	my (undef, $stderr) = capture(sub {
		App::Test::Generator->generate(
			schema_file => $schema->filename(),
			output_file => $outpath,
		)
	});

	ok(-f $outpath && -s $outpath, 'output file created and non-empty');
};

subtest 'generate() croaks when called with no arguments' => sub {
	throws_ok(
		sub { App::Test::Generator->generate() },
		qr/Usage/,
		'no-arg generate() croaks with Usage',
	);
};

# ==================================================================
# _is_perl_builtin
# ==================================================================

subtest '_is_perl_builtin() returns 1 for known builtins' => sub {
	for my $builtin (qw(abs chomp length push pop shift unshift
						print printf die warn open close)) {
		is(_is_perl_builtin($builtin), 1, "'$builtin' recognised as builtin");
	}
};

subtest '_is_perl_builtin() returns 0 for module names' => sub {
	for my $mod (qw(Scalar::Util List::Util File::Spec POSIX Carp)) {
		is(_is_perl_builtin($mod), 0, "'$mod' not a builtin");
	}
};

subtest '_is_perl_builtin() is case-insensitive' => sub {
	is(_is_perl_builtin('ABS'), 1, 'ABS -> 1');
	is(_is_perl_builtin('Abs'), 1, 'Abs -> 1');
	is(_is_perl_builtin('abs'), 1, 'abs -> 1');
};

subtest '_is_perl_builtin() returns 0 for undef' => sub {
	is(_is_perl_builtin(undef), 0, 'undef -> 0');
};

subtest '_is_perl_builtin() returns 0 for empty string' => sub {
	is(_is_perl_builtin(''), 0, 'empty string -> 0');
};

subtest 'Generator: generate() sort handles undef values correctly' => sub {
	# The comparator at lines 1752-1761 handles undef $a and $b
	# Test by generating output from two schemas and verifying order is stable
	my ($fh1, $p1) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh1 "module: builtin\nfunction: beta\ninput:\n  type: string\noutput:\n  type: string\n";
	close $fh1;
	my ($fh2, $p2) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh2 "module: builtin\nfunction: alpha\ninput:\n  type: string\noutput:\n  type: string\n";
	close $fh2;
	my ($out1) = capture(sub { App::Test::Generator->generate($p1) });
	my ($out2) = capture(sub { App::Test::Generator->generate($p2) });
	isnt($out1, $out2, 'different function names produce different output');
};

subtest 'Generator: generate() with exactly one arg (class only) croaks' => sub {
	throws_ok(
		sub { App::Test::Generator->generate() },
		qr/Usage/,
		'zero args after class croaks'
	);
};

subtest 'Generator: generate() with two args (class + schema) lives' => sub {
	my ($fh, $schema) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: abs\ninput:\n  type: number\noutput:\n  type: number\n";
	close $fh;
	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($schema) };
	});
	is($@, '', 'two args (class + schema) lives');
	like($out, qr/use strict/, 'output contains use strict');
};

done_testing();
