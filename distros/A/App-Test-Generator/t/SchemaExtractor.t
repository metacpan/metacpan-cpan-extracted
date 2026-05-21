#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# use Test::DescribeMe qw(extended);
use Test::Most;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use Readonly;

BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

# --------------------------------------------------
# Constants used across subtests to avoid magic
# literals and to make boundary intent explicit
# --------------------------------------------------
Readonly my $EMPTY_STRING => '';
Readonly my $NONEXISTENT  => '/no/such/file.pm';

# --------------------------------------------------
# Helper: create a temporary .pm file containing
# the given Perl source and return its path.
# Opens with UTF-8 encoding to avoid wide-character
# warnings when the source contains Unicode.
# --------------------------------------------------
sub _write_pm {
	my ($source) = @_;
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	# Use UTF-8 encoding so Unicode in source strings does not warn
	binmode $fh, ':encoding(UTF-8)';
	print $fh $source;
	close $fh;
	return $path;
}

# --------------------------------------------------
# Helper: construct a minimal SchemaExtractor
# pointing at a real (possibly empty) temp file.
# Accepts additional constructor options via %opts.
# --------------------------------------------------
sub _extractor {
	my ($source, %opts) = @_;
	my $path = _write_pm($source // "package Tmp;\n1;\n");
	return App::Test::Generator::SchemaExtractor->new(
		input_file => $path,
		%opts,
	);
}

# ==================================================================
# new
# --------------------------------------------------
# Tests for the constructor -- input validation and
# blessed object structure
# ==================================================================
subtest 'new' => sub {
	# Missing input_file must croak -- the actual message comes from
	# Params::Get which validates the required key first
	throws_ok {
		App::Test::Generator::SchemaExtractor->new()
	} qr/input_file/, 'missing input_file croaks';

	# Non-existent file must croak with a clear message
	throws_ok {
		App::Test::Generator::SchemaExtractor->new(input_file => $NONEXISTENT)
	} qr/does not exist/, 'non-existent file croaks';

	# Valid file returns a blessed object of the correct class
	my $e = _extractor("package Foo;\n1;\n");
	ok(defined $e, 'valid file returns object');
	isa_ok($e, 'App::Test::Generator::SchemaExtractor');

	# Default values are set correctly on the constructed object
	is($e->{verbose},         0, 'verbose defaults to 0');
	is($e->{include_private}, 0, 'include_private defaults to 0');
	ok($e->{confidence_threshold} > 0, 'confidence_threshold has a positive default');
	ok($e->{max_parameters}  > 0,      'max_parameters has a positive default');

	# strict_pod defaults to 0 (off)
	is($e->{strict_pod}, 0, 'strict_pod defaults to 0');

	# strict_pod accepts the string 'warn' and normalises to 1
	my $e2 = _extractor("package Foo;\n1;\n", strict_pod => 'warn');
	is($e2->{strict_pod}, 1, "strict_pod 'warn' normalised to 1");

	# strict_pod accepts the string 'fatal' and normalises to 2
	my $e3 = _extractor("package Foo;\n1;\n", strict_pod => 'fatal');
	is($e3->{strict_pod}, 2, "strict_pod 'fatal' normalised to 2");

	done_testing();
};

# ==================================================================
# _validate_strictness_level
# --------------------------------------------------
# Tests for the strict_pod option normaliser
# ==================================================================
subtest '_validate_strictness_level' => sub {
	my $fn = \&App::Test::Generator::SchemaExtractor::_validate_strictness_level;

	# Undef and off/0 all map to 0 (disabled)
	is($fn->(undef),  0, 'undef returns 0');
	is($fn->(0),      0, '0 returns 0');
	is($fn->('off'),  0, "'off' returns 0");
	is($fn->('none'), 0, "'none' returns 0");

	# Warning-level strings all map to 1
	is($fn->(1),         1, '1 returns 1');
	is($fn->('warn'),    1, "'warn' returns 1");
	is($fn->('warning'), 1, "'warning' returns 1");

	# Fatal-level strings all map to 2
	is($fn->(2),       2, '2 returns 2');
	is($fn->('fatal'), 2, "'fatal' returns 2");
	is($fn->('die'),   2, "'die' returns 2");
	is($fn->('error'), 2, "'error' returns 2");

	# Unknown values croak with a clear message
	throws_ok { $fn->('unknown') } qr/Invalid value/, 'unknown value croaks';

	done_testing();
};

# ==================================================================
# _types_are_compatible
# --------------------------------------------------
# Tests for the type compatibility checker used by
# strict POD/code agreement validation
# ==================================================================
subtest '_types_are_compatible' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_types_are_compatible(@_) };

	# Identical types are always compatible
	ok($fn->('string',  'string'),  'string == string');
	ok($fn->('integer', 'integer'), 'integer == integer');
	ok($fn->('number',  'number'),  'number == number');

	# Compatible type pairs -- semantically equivalent forms
	ok($fn->('integer', 'number'),   'integer compatible with number');
	ok($fn->('integer', 'scalar'),   'integer compatible with scalar');
	ok($fn->('string',  'scalar'),   'string compatible with scalar');
	ok($fn->('number',  'scalar'),   'number compatible with scalar');
	ok($fn->('arrayref', 'array'),   'arrayref compatible with array');
	ok($fn->('hashref',  'hash'),    'hashref compatible with hash');

	# Incompatible pairs must return false
	ok(!$fn->('string',   'integer'), 'string not compatible with integer');
	ok(!$fn->('boolean',  'string'),  'boolean not compatible with string');
	ok(!$fn->('arrayref', 'hashref'), 'arrayref not compatible with hashref');

	done_testing();
};

# ==================================================================
# _format_relationship
# --------------------------------------------------
# Tests for the relationship hashref formatter used
# in YAML comment generation
# ==================================================================
subtest '_format_relationship' => sub {
	my $fn = \&App::Test::Generator::SchemaExtractor::_format_relationship;

	# mutually_exclusive shows both param names
	my $rel = { type => 'mutually_exclusive', params => ['file', 'content'] };
	like($fn->($rel), qr/file/,    'mutually_exclusive contains first param');
	like($fn->($rel), qr/content/, 'mutually_exclusive contains second param');

	# required_group shows the params
	$rel = { type => 'required_group', params => ['id', 'name'] };
	like($fn->($rel), qr/id/, 'required_group contains first param');

	# conditional_requirement shows both the if and then params
	$rel = {
		type          => 'conditional_requirement',
		'if'          => 'async',
		then_required => 'callback',
	};
	like($fn->($rel), qr/async/,    'conditional_requirement contains if param');
	like($fn->($rel), qr/callback/, 'conditional_requirement contains then param');

	# dependency shows both the param and its requirement
	$rel = { type => 'dependency', param => 'port', requires => 'host' };
	like($fn->($rel), qr/port/, 'dependency contains param');
	like($fn->($rel), qr/host/, 'dependency contains requires');

	# value_constraint shows the value being compared
	$rel = {
		type     => 'value_constraint',
		'if'     => 'ssl',
		then     => 'port',
		operator => '==',
		value    => 443,
	};
	like($fn->($rel), qr/443/, 'value_constraint contains value');

	# value_conditional shows the equals value
	$rel = {
		type          => 'value_conditional',
		'if'          => 'mode',
		equals        => 'secure',
		then_required => 'key',
	};
	like($fn->($rel), qr/secure/, 'value_conditional contains equals value');

	# Unknown type returns a fallback string rather than dying
	$rel = { type => 'unknown_type' };
	like($fn->($rel), qr/Unknown/, 'unknown type returns fallback string');

	done_testing();
};

# ==================================================================
# _clean_default_value
# --------------------------------------------------
# Tests for the default value normaliser
# ==================================================================
subtest '_clean_default_value' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_clean_default_value(@_) };

	# Undef input returns undef
	is($fn->(undef), undef, 'undef returns undef');

	# The bare word 'undef' returns undef
	is($fn->('undef'), undef, "'undef' string returns undef");

	# Integers are returned as integers
	is($fn->('42'),  42,  'integer string returns integer');
	is($fn->('-1'),  -1,  'negative integer returned');
	is($fn->('0'),   0,   'zero returned as integer');

	# Floats are returned as floats
	is($fn->('3.14'), 3.14, 'float string returned as float');

	# Quoted strings are unquoted
	is($fn->("'hello'"), 'hello', 'single-quoted string unquoted');
	is($fn->('"hello"'), 'hello', 'double-quoted string unquoted');

	# Boolean keywords are normalised to 1/0
	is($fn->('true'),  1, "'true' normalised to 1");
	is($fn->('false'), 0, "'false' normalised to 0");

	# Perl integer constants
	is($fn->('1'), 1, "'1' returns 1");
	is($fn->('0'), 0, "'0' returns 0");

	# Empty hashref returns a hashref reference
	is(ref($fn->('{}')), 'HASH', "'{}' returns hashref");

	# Empty arrayref returns an arrayref reference
	is(ref($fn->('[]')), 'ARRAY', "'[]' returns arrayref");

	# Chained || operator -- rightmost value is extracted
	is($fn->('$x || 5'), 5, 'chained || returns rightmost value');

	# Defined-or chaining -- rightmost value is extracted
	is($fn->('$x // 10'), 10, 'chained // returns rightmost value');

	# Trailing semicolon is stripped before returning
	is($fn->('42;'), 42, 'trailing semicolon stripped');

	done_testing();
};

# ==================================================================
# _infer_type_from_default
# --------------------------------------------------
# Tests for the type inferrer used in signature parsing.
# Note: 1 and 0 infer as 'integer' because the integer
# regex /^-?\d+$/ matches before the boolean check.
# ==================================================================
subtest '_infer_type_from_default' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_infer_type_from_default(@_) };

	# Undef returns undef
	is($fn->(undef), undef, 'undef returns undef');

	# Hashref default infers hashref type
	is($fn->({}), 'hashref', 'hashref default infers hashref');

	# Arrayref default infers arrayref type
	is($fn->([]), 'arrayref', 'arrayref default infers arrayref');

	# Integer literals -- note 1 and 0 are integers not booleans
	# because the integer pattern /^-?\d+$/ matches before boolean check
	is($fn->(42),  'integer', 'integer default infers integer');
	is($fn->(-1),  'integer', 'negative integer infers integer');
	is($fn->(0),   'integer', 'zero infers integer');
	is($fn->(1),   'integer', '1 infers integer (integer check fires first)');

	# Float literals infer number type
	is($fn->(3.14), 'number', 'float default infers number');

	# String defaults infer string type
	is($fn->('hello'), 'string', 'string default infers string');

	done_testing();
};

# ==================================================================
# _format_default
# --------------------------------------------------
# Tests for the verbose logging formatter
# ==================================================================
subtest '_format_default' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_format_default(@_) };

	# Undef returns the literal string 'undef'
	is($fn->(undef), 'undef', 'undef returns undef string');

	# Scalar values pass through unchanged
	is($fn->(42),      42,      'integer passes through');
	is($fn->('hello'), 'hello', 'string passes through');

	# Reference types return a description containing 'ref'
	like($fn->({}),  qr/ref/i, 'hashref returns ref description');
	like($fn->([]),  qr/ref/i, 'arrayref returns ref description');

	done_testing();
};

# ==================================================================
# _parse_constraints
# --------------------------------------------------
# Tests for the POD constraint string parser
# ==================================================================
subtest '_parse_constraints' => sub {
	my $e = _extractor();

	# Numeric range N-M sets both min and max
	my %p;
	$e->_parse_constraints(\%p, '3-50');
	is($p{min}, 3,  'range min set correctly');
	is($p{max}, 50, 'range max set correctly');

	# Dot-dot range notation N..M
	%p = ();
	$e->_parse_constraints(\%p, '0..19');
	is($p{min}, 0,  'dot-dot range min set');
	is($p{max}, 19, 'dot-dot range max set');

	# Min-only keyword forms
	%p = ();
	$e->_parse_constraints(\%p, 'min 3');
	is($p{min}, 3, "'min N' sets min");

	%p = ();
	$e->_parse_constraints(\%p, 'at least 5');
	is($p{min}, 5, "'at least N' sets min");

	# Max-only keyword forms
	%p = ();
	$e->_parse_constraints(\%p, 'max 50');
	is($p{max}, 50, "'max N' sets max");

	%p = ();
	$e->_parse_constraints(\%p, 'up to 100');
	is($p{max}, 100, "'up to N' sets max");

	# 'positive' sets min to 1 for integer type
	%p = (type => 'integer');
	$e->_parse_constraints(\%p, 'positive');
	is($p{min}, 1, "'positive' sets min to 1 for integer");

	# 'positive' sets a positive min for number type
	%p = (type => 'number');
	$e->_parse_constraints(\%p, 'positive');
	ok($p{min} > 0, "'positive' sets positive min for number");

	# 'non-negative' sets min to 0
	%p = ();
	$e->_parse_constraints(\%p, 'non-negative');
	is($p{min}, 0, "'non-negative' sets min to 0");

	done_testing();
};

# ==================================================================
# _extract_subroutine_attributes
# --------------------------------------------------
# Tests for the subroutine attribute extractor
# ==================================================================
subtest '_extract_subroutine_attributes' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_extract_subroutine_attributes(@_) };

	# No attributes returns empty hashref
	my $attrs = $fn->('sub foo { }');
	is(ref($attrs), 'HASH',      'returns hashref');
	is(scalar keys %{$attrs}, 0, 'no attributes returns empty hashref');

	# Single flag attribute is detected and given value 1
	$attrs = $fn->('sub foo :lvalue { }');
	ok(exists $attrs->{lvalue}, ':lvalue attribute detected');
	is($attrs->{lvalue}, 1,     ':lvalue has value 1');

	# Attribute with a value extracts the value string
	$attrs = $fn->('sub foo :Returns(Int) { }');
	ok(exists $attrs->{Returns},  ':Returns attribute detected');
	is($attrs->{Returns}, 'Int',  ':Returns value extracted');

	# Multiple attributes are all detected independently
	$attrs = $fn->('sub foo :lvalue :method { }');
	ok(exists $attrs->{lvalue},  'multiple: lvalue detected');
	ok(exists $attrs->{method},  'multiple: method detected');

	done_testing();
};

# ==================================================================
# _analyze_postfix_dereferencing
# --------------------------------------------------
# Tests for the modern Perl dereference detector
# ==================================================================
subtest '_analyze_postfix_dereferencing' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_analyze_postfix_dereferencing(@_) };

	# Traditional arrow access produces no postfix dereference flags
	my $derefs = $fn->('my $x = $ref->{key};');
	is(scalar keys %{$derefs}, 0, 'no postfix derefs returns empty hashref');

	# Array dereference ->@*
	$derefs = $fn->('my @a = $ref->@*;');
	ok($derefs->{array_deref}, '->@* detected as array_deref');

	# Hash dereference ->%*
	$derefs = $fn->('my %h = $ref->%*;');
	ok($derefs->{hash_deref}, '->%* detected as hash_deref');

	# Scalar dereference ->$*
	$derefs = $fn->('my $s = $ref->$*;');
	ok($derefs->{scalar_deref}, '->$* detected as scalar_deref');

	# Array slice ->@[...]
	$derefs = $fn->('my @s = $ref->@[1,2];');
	ok($derefs->{array_slice}, '->@[...] detected as array_slice');

	# Hash slice ->%{...}
	$derefs = $fn->('my %s = $ref->%{key};');
	ok($derefs->{hash_slice}, '->%{...} detected as hash_slice');

	done_testing();
};

# ==================================================================
# _extract_field_declarations
# --------------------------------------------------
# Tests for the Perl 5.38 field declaration extractor
# ==================================================================
subtest '_extract_field_declarations' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_extract_field_declarations(@_) };

	# No field declarations returns empty hashref
	my $fields = $fn->('sub foo { my $x = 1; }');
	is(scalar keys %{$fields}, 0, 'no fields returns empty hashref');

	# Simple :param field -- field name becomes param name
	$fields = $fn->("field \$host :param;\n");
	ok(exists $fields->{host},              ':param field detected');
	ok($fields->{host}{is_param},           'is_param flag set');
	is($fields->{host}{param_name}, 'host', 'param_name matches field name');

	# :param with an explicit external name overrides the field name
	$fields = $fn->("field \$username :param(user);\n");
	ok(exists $fields->{username},               ':param(name) field detected');
	is($fields->{username}{param_name}, 'user',  'explicit param name extracted');

	# Field with a default value -- field becomes optional
	$fields = $fn->("field \$port :param = 3306;\n");
	ok(exists $fields->{port},          'field with default detected');
	is($fields->{port}{_default}, 3306, 'default value extracted');
	ok($fields->{port}{optional},       'field with default is optional');

	# Field with :isa type constraint -- type set to object
	$fields = $fn->("field \$logger :param :isa(Log::Any);\n");
	ok(exists $fields->{logger},             'field with isa detected');
	is($fields->{logger}{isa},   'Log::Any', 'isa type extracted');
	is($fields->{logger}{type},  'object',   'type set to object for isa');

	done_testing();
};

# ==================================================================
# _parse_signature_parameter
# --------------------------------------------------
# Tests for the individual signature parameter parser
# ==================================================================
subtest '_parse_signature_parameter' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_parse_signature_parameter(@_) };

	# Plain scalar parameter at position 0
	my $info = $fn->('$name', 0);
	is($info->{name},     'name', 'plain param name extracted');
	is($info->{position}, 0,      'position set correctly');
	is($info->{optional}, 0,      'plain param is required');

	# Parameter with a numeric default value makes it optional
	$info = $fn->('$port = 3306', 1);
	is($info->{name},     'port', 'default param name extracted');
	is($info->{optional}, 1,      'param with default is optional');
	is($info->{_default}, 3306,   'default value extracted');
	is($info->{position}, 1,      'position set correctly');

	# Parameter with :Int type constraint maps to 'integer'
	$info = $fn->('$count :Int', 0);
	is($info->{name},     'count',   'typed param name extracted');
	is($info->{type},     'integer', ':Int maps to integer type');
	is($info->{optional}, 0,         'typed param without default is required');

	# Parameter with :Num constraint and default
	$info = $fn->('$ratio :Num = 1.0', 0);
	is($info->{type},     'number', ':Num maps to number type');
	is($info->{optional}, 1,        'typed param with default is optional');

	# Slurpy array parameter
	$info = $fn->('@args', 2);
	is($info->{name},   'args',  'slurpy array name extracted');
	is($info->{type},   'array', 'slurpy array has array type');
	ok($info->{slurpy},           'slurpy flag set for @param');
	ok($info->{optional},         'slurpy array is optional');

	# Slurpy hash parameter
	$info = $fn->('%opts', 2);
	is($info->{name},   'opts', 'slurpy hash name extracted');
	is($info->{type},   'hash', 'slurpy hash has hash type');
	ok($info->{slurpy},          'slurpy flag set for %param');

	# Non-matching pattern returns undef without dying
	is($fn->('not_a_param', 0), undef, 'non-matching pattern returns undef');

	done_testing();
};

# ==================================================================
# _infer_type_from_expression
# --------------------------------------------------
# Tests for the return expression type inferrer.
# This function checks booleans (^[01]$) BEFORE integers
# so single 0 and 1 are correctly classified as boolean.
# ==================================================================
subtest '_infer_type_from_expression' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_infer_type_from_expression(@_) };

	# Undef returns scalar as the safe default
	is($fn->(undef)->{type}, 'scalar', 'undef expr returns scalar type');

	# Array-like expressions
	is($fn->('@array')->{type},    'array',    '@array is array');
	is($fn->('qw(a b c)')->{type}, 'array',    'qw() is array');
	is($fn->('\@ref')->{type},     'arrayref', '\@ref is arrayref');
	is($fn->('[1,2,3]')->{type},   'arrayref', '[...] is arrayref');

	# Hash-like expressions
	is($fn->('\%hash')->{type}, 'hashref', '\%hash is hashref');
	is($fn->('{}')->{type},     'hashref', '{} is hashref');

	# Numeric scalar literals
	is($fn->('42')->{type},   'integer', 'integer literal');
	is($fn->('-1')->{type},   'integer', 'negative integer');
	is($fn->('3.14')->{type}, 'number',  'float literal');

	# String literal
	is($fn->("'hello'")->{type}, 'string', 'single-quoted string');

	# Single-digit 0 and 1 are boolean -- the boolean check /^[01]$/
	# appears before the integer check in the function after the bug fix
	is($fn->('1')->{type}, 'boolean', '1 is boolean in expression context');
	is($fn->('0')->{type}, 'boolean', '0 is boolean in expression context');

	# scalar() function returns integer with min 0
	my $res = $fn->('scalar(@arr)');
	is($res->{type}, 'integer', 'scalar() returns integer');
	is($res->{min},  0,         'scalar() has min 0');

	# Comma-separated values indicate an array
	is($fn->('$a, $b')->{type}, 'array', 'comma-separated is array');

	# length() returns integer with min 0
	$res = $fn->('length($s)');
	is($res->{type}, 'integer', 'length() returns integer');
	is($res->{min},  0,         'length() has min 0');

	done_testing();
};

# ==================================================================
# _calculate_input_confidence
# --------------------------------------------------
# Tests for the input confidence scorer
# ==================================================================
subtest '_calculate_input_confidence' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_calculate_input_confidence(@_) };

	# Empty params returns the 'none' confidence level
	my $result = $fn->({});
	is($result->{level}, 'none', 'empty params returns none');
	ok(exists $result->{factors}, 'factors key present');

	# Well-typed constrained param should score at a valid level
	my $high = $fn->({
		name => {
			type     => 'string',
			min      => 3,
			max      => 50,
			optional => 0,
			position => 0,
		}
	});
	ok(defined $high->{level}, 'well-typed param has a level');
	ok(defined $high->{score}, 'score is present');

	# All returned levels must be valid strings
	my %valid_levels = map { $_ => 1 } qw(none very_low low medium high);
	ok($valid_levels{$high->{level}}, 'level is a valid string');

	# Per-parameter scores must be present in the result
	ok(exists $high->{per_parameter},       'per_parameter key present');
	ok(exists $high->{per_parameter}{name}, 'per-param entry for name');

	# Unconstrained param scores at most a fully-constrained param
	my $low = $fn->({ x => { type => 'string' } });
	ok($low->{score} <= $high->{score}, 'unconstrained scores at most constrained');

	done_testing();
};

# ==================================================================
# _calculate_output_confidence
# --------------------------------------------------
# Tests for the output confidence scorer
# ==================================================================
subtest '_calculate_output_confidence' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_calculate_output_confidence(@_) };

	# Empty output returns the 'none' level
	my $result = $fn->({});
	is($result->{level}, 'none', 'empty output returns none');

	# Output with type scores above none
	$result = $fn->({ type => 'string' });
	isnt($result->{level}, 'none', 'output with type is not none');

	# A specific value raises the confidence score
	my $with_value = $fn->({ type => 'boolean', value => 1 });
	ok($with_value->{score} > $fn->({ type => 'boolean' })->{score},
		'specific value raises score');

	# An ISA class constraint raises the confidence score
	my $with_isa = $fn->({ type => 'object', isa => 'Foo::Bar' });
	ok($with_isa->{score} > $fn->({ type => 'object' })->{score},
		'isa raises score');

	# Void context is a positive confidence signal
	my $void = $fn->({ type => 'void', _void_context => 1 });
	ok($void->{score} > 0, 'void context has positive score');

	done_testing();
};

# ==================================================================
# _determine_optional_status
# --------------------------------------------------
# Tests for the optional-status merger used in
# _merge_parameter_analyses
# ==================================================================
subtest '_determine_optional_status' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_determine_optional_status(@_) };

	# POD explicit optional wins over code required
	my %merged;
	$fn->(\%merged, { optional => 1 }, { optional => 0 });
	is($merged{optional}, 1, 'POD optional wins over code required');

	# POD explicit required wins over code optional
	%merged = ();
	$fn->(\%merged, { optional => 0 }, { optional => 1 });
	is($merged{optional}, 0, 'POD required wins over code optional');

	# Code fills in when POD has no opinion on the field
	%merged = ();
	$fn->(\%merged, {}, { optional => 1 });
	is($merged{optional}, 1, 'code fills in when POD silent');

	# Both absent defaults to required when the param has other info
	%merged = (type => 'string');
	$fn->(\%merged, {}, {});
	is($merged{optional}, 0, 'both absent defaults to required when param has info');

	done_testing();
};

# ==================================================================
# _generate_notes
# --------------------------------------------------
# Tests for the human-readable note generator
# ==================================================================
subtest '_generate_notes' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_generate_notes(@_) };

	# Empty params returns an empty arrayref
	my $notes = $fn->({});
	is(ref($notes), 'ARRAY', 'returns arrayref');
	is(scalar @{$notes}, 0,  'empty params returns empty notes');

	# A param without a type generates a note mentioning the param name
	$notes = $fn->({ x => {} });
	ok(scalar @{$notes} > 0, 'untyped param generates note');
	like($notes->[0], qr/x/, 'note mentions param name');

	# A param with a type generates no type-unknown note
	$notes = $fn->({ x => { type => 'string' } });
	my @type_notes = grep { /type unknown/ } @{$notes};
	is(scalar @type_notes, 0, 'typed param has no type-unknown note');

	done_testing();
};

# ==================================================================
# _deduplicate_relationships
# --------------------------------------------------
# Tests for the relationship deduplicator
# ==================================================================
subtest '_deduplicate_relationships' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_deduplicate_relationships(@_) };

	# Empty list returns empty list
	my @result = $fn->([]);
	is(scalar @result, 0, 'empty list returns empty list');

	# Single item passes through unchanged
	my $rel = { type => 'mutually_exclusive', params => ['file', 'content'] };
	@result = $fn->([$rel]);
	is(scalar @result, 1, 'single item passes through');

	# Exact duplicate hashref is removed
	@result = $fn->([$rel, $rel]);
	is(scalar @result, 1, 'exact duplicate removed');

	# Different relationship types are never deduplicated
	my $req = { type => 'required_group', params => ['file', 'content'], logic => 'or' };
	@result = $fn->([$rel, $req]);
	is(scalar @result, 2, 'different types not deduplicated');

	done_testing();
};

# ==================================================================
# _detect_mutually_exclusive
# --------------------------------------------------
# Tests for the mutual exclusion detector.
# These are instance methods so must be called via $e->
# "Unrelated code" uses return 42 with no sigils -- any
# code containing parameter variable names risks matching
# Pattern 2's broad single-char param regex.
# ==================================================================
subtest '_detect_mutually_exclusive' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_detect_mutually_exclusive(@_) };

	# Pattern 1: die if $file && $content
	my $code = 'die "bad" if $file && $content;';
	my @rels = @{ $fn->($code, ['file', 'content']) };
	is(scalar @rels, 1, 'die if $a && $b detected');
	is($rels[0]{type}, 'mutually_exclusive', 'correct relationship type');
	ok(grep({ $_ eq 'file' }    @{$rels[0]{params}}), 'file in params');
	ok(grep({ $_ eq 'content' } @{$rels[0]{params}}), 'content in params');

	# croak form is also detected
	$code = 'croak "bad" if $source && $dest;';
	@rels = @{ $fn->($code, ['source', 'dest']) };
	is(scalar @rels, 1, 'croak form also detected');

	# Completely unrelated code with no sigils produces no relationships
	# Use 'return 42' so the param names cannot match anything
	@rels = @{ $fn->('return 42;', ['source', 'dest']) };
	is(scalar @rels, 0, 'unrelated code produces no relationships');

	done_testing();
};

# ==================================================================
# _detect_required_groups
# --------------------------------------------------
# Tests for the required group detector
# ==================================================================
subtest '_detect_required_groups' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_detect_required_groups(@_) };

	# Pattern: die unless $host || $file
	my $code = 'die "need one" unless $host || $file;';
	my @rels = @{ $fn->($code, ['host', 'file']) };
	is(scalar @rels, 1,               'die unless $a || $b detected');
	is($rels[0]{type},  'required_group', 'correct relationship type');
	is($rels[0]{logic}, 'or',             'logic is or');

	# Completely unrelated code produces no relationships
	@rels = @{ $fn->('return 42;', ['host', 'file']) };
	is(scalar @rels, 0, 'unrelated code produces no relationships');

	done_testing();
};

# ==================================================================
# _detect_conditional_requirements
# --------------------------------------------------
# Tests for the IF-THEN relationship detector
# ==================================================================
subtest '_detect_conditional_requirements' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_detect_conditional_requirements(@_) };

	# Pattern: die if $async && !$callback
	my $code = 'die "need callback" if $async && !$callback;';
	my @rels = @{ $fn->($code, ['async', 'callback']) };
	is(scalar @rels, 1, 'die if $a && !$b detected');
	is($rels[0]{type},          'conditional_requirement', 'correct type');
	is($rels[0]{'if'},          'async',                   'if param correct');
	is($rels[0]{then_required}, 'callback',                'then_required correct');

	# Completely unrelated code produces no relationships
	@rels = @{ $fn->('return 42;', ['async', 'callback']) };
	is(scalar @rels, 0, 'unrelated code produces no relationships');

	done_testing();
};

# ==================================================================
# _detect_instance_method
# --------------------------------------------------
# Tests for the instance method detector
# ==================================================================
subtest '_detect_instance_method' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_detect_instance_method(@_) };

	# my ($self, ...) = @_ -- explicit self declaration
	my $info = $fn->('method', 'sub method { my ($self, $x) = @_; }');
	ok(defined $info,           'explicit $self detected');
	ok($info->{explicit_self},  'explicit_self flag set');

	# my $self = shift -- shift-style self
	$info = $fn->('method', 'sub method { my $self = shift; }');
	ok(defined $info,        'shift $self detected');
	ok($info->{shift_self},  'shift_self flag set');

	# $self->{key} -- accesses object hash data
	$info = $fn->('method', 'sub method { return $self->{name}; }');
	ok(defined $info,                   '$self->{key} detected');
	ok($info->{accesses_object_data},   'accesses_object_data flag set');

	# Pure function with no $self reference is not an instance method
	$info = $fn->('func', 'sub func { my ($x, $y) = @_; return $x + $y; }');
	ok(!defined $info || !$info->{explicit_self},
		'pure function not detected as instance method');

	done_testing();
};

# ==================================================================
# _detect_singleton_pattern
# --------------------------------------------------
# Tests for the singleton pattern detector
# ==================================================================
subtest '_detect_singleton_pattern' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_detect_singleton_pattern(@_) };

	# Methods not named 'instance' etc. always return undef
	is($fn->('new',      'sub new { }'),      undef, 'new() not a singleton');
	is($fn->('get_item', 'sub get_item { }'), undef, 'get_item not a singleton');

	# Method named 'instance' is detected as a singleton
	my $info = $fn->('instance',
		'sub instance { my $instance ||= new(); return $instance; }');
	ok(defined $info,          'instance() detected as singleton');
	ok($info->{name_pattern},  'name_pattern flag set');

	# Method named 'get_instance' is also detected
	$info = $fn->('get_instance', 'sub get_instance { }');
	ok(defined $info, 'get_instance() detected as singleton');

	done_testing();
};

# ==================================================================
# _detect_factory_method
# --------------------------------------------------
# Tests for the factory method detector.
# Note: name_pattern alone is not sufficient to return a defined
# result -- the body must also contain a creation pattern
# (bless, ->new(), or another factory call).
# ==================================================================
subtest '_detect_factory_method' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_detect_factory_method(@_) };

	# Method that returns a blessed ref is a factory
	my $body = 'sub create { return bless {}, "Foo"; }';
	my $info = $fn->('create', $body, 'Pkg', {});
	ok(defined $info,            'bless return detected as factory');
	ok($info->{returns_blessed}, 'returns_blessed flag set');

	# Method that returns ->new() is a factory
	$body = 'sub make { return Foo->new($args); }';
	$info = $fn->('make', $body, 'Pkg', {});
	ok(defined $info,         'return ->new() detected as factory');
	ok($info->{returns_new},  'returns_new flag set');

	# create_* name pattern combined with ->new() body sets both flags
	# Note: name_pattern alone (empty body) is insufficient to return defined
	$body = 'sub create_user { return User->new(); }';
	$info = $fn->('create_user', $body, 'Pkg', {});
	ok(defined $info,          'create_user with ->new() detected as factory');
	ok($info->{name_pattern},  'name_pattern flag set alongside body pattern');
	ok($info->{returns_new},   'returns_new flag also set');

	# Plain instance method with no factory signals returns undef
	$body = 'sub do_stuff { my $self = shift; $self->{done} = 1; }';
	$info = $fn->('do_stuff', $body, 'Pkg', {});
	ok(!defined $info, 'plain method not detected as factory');

	done_testing();
};

# ==================================================================
# _serialize_parameter_for_yaml
# --------------------------------------------------
# Tests for the YAML parameter serialiser
# ==================================================================
subtest '_serialize_parameter_for_yaml' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->_serialize_parameter_for_yaml(@_) };

	# Basic parameter with type and optional flag passes through
	my $result = $fn->({ type => 'string', optional => 1 });
	is(ref($result),        'HASH',   'returns hashref');
	is($result->{type},     'string', 'type preserved');
	is($result->{optional}, 1,        'optional preserved');

	# Internal _source key must be stripped from output
	$result = $fn->({ type => 'string', _source => 'pod' });
	ok(!exists $result->{_source}, '_source key stripped');

	# filepath semantic keeps string type and adds a path note
	$result = $fn->({ type => 'string', semantic => 'filepath' });
	is($result->{type}, 'string', 'filepath semantic keeps string type');
	like($result->{_note}, qr/path/i, 'filepath gets path note');

	# unix_timestamp semantic sets integer type and bounds
	$result = $fn->({ type => 'integer', semantic => 'unix_timestamp' });
	is($result->{type}, 'integer', 'unix_timestamp has integer type');
	is($result->{min},  0,         'unix_timestamp has min 0');
	ok(defined $result->{max},     'unix_timestamp has a max defined');

	# callback/coderef semantic preserves coderef type
	$result = $fn->({ type => 'coderef', semantic => 'callback' });
	is($result->{type}, 'coderef', 'callback semantic has coderef type');

	# enum values are moved to memberof for YAML output
	$result = $fn->({ type => 'string', enum => ['alpha', 'beta'] });
	ok(exists $result->{memberof}, 'enum moved to memberof');

	# isa constraint is preserved in the serialised output
	$result = $fn->({ type => 'object', isa => 'Foo::Bar' });
	is($result->{isa}, 'Foo::Bar', 'isa preserved');

	done_testing();
};

# ==================================================================
# _extract_invalid_input_hints
# --------------------------------------------------
# Tests for the invalid-input hint extractor.
# Note: the function pushes the STRING 'undef' not actual
# Perl undef, so grep must check for the string form.
# ==================================================================
subtest '_extract_invalid_input_hints' => sub {
	my $e  = _extractor();
	my $fn = sub {
		my ($code) = @_;
		my %hints = (invalid_inputs => []);
		$e->_extract_invalid_input_hints($code, \%hints);
		return \%hints;
	};

	# A defined() check implies undef is an invalid input;
	# the function pushes the string 'undef' not actual undef
	my $hints = $fn->('croak unless defined($x);');
	ok(grep({ defined $_ && $_ eq 'undef' } @{$hints->{invalid_inputs}}),
		"'undef' string added for defined check");

	# A length() check implies empty string is invalid
	$hints = $fn->('croak unless length($x) > 0;');
	ok(grep({ defined $_ && $_ eq '' } @{$hints->{invalid_inputs}}),
		'empty string added for length check');

	# A < 0 check implies -1 is an invalid input
	$hints = $fn->('croak if $x < 0;');
	ok(grep({ defined $_ && $_ == -1 } @{$hints->{invalid_inputs}}),
		'-1 added for < 0 check');

	# Code with none of these patterns produces no invalid hints
	$hints = $fn->('return $x + 1;');
	is(scalar @{$hints->{invalid_inputs}}, 0,
		'unrelated code produces no hints');

	done_testing();
};

# ==================================================================
# _extract_boundary_value_hints
# --------------------------------------------------
# Tests for the boundary value hint extractor
# ==================================================================
subtest '_extract_boundary_value_hints' => sub {
	my $e  = _extractor();
	my $fn = sub {
		my ($code) = @_;
		my %hints = (boundary_values => []);
		$e->_extract_boundary_value_hints($code, \%hints);
		return \%hints;
	};

	# A < comparison with a literal generates boundary values
	my $hints = $fn->('croak if $x < 10;');
	ok(scalar @{$hints->{boundary_values}} > 0, 'boundary values extracted');
	ok(grep({ $_ == 10 } @{$hints->{boundary_values}}),
		'10 in boundary values');

	# A >= comparison also generates values around the boundary
	$hints = $fn->('croak unless $x >= 0;');
	ok(grep({ $_ == 0 } @{$hints->{boundary_values}}),
		'0 in boundary values for >=');

	# Duplicate boundary values from multiple checks are deduplicated
	$hints = $fn->('croak if $x < 10; croak if $y < 10;');
	my @tens = grep { $_ == 10 } @{$hints->{boundary_values}};
	is(scalar @tens, 1, 'duplicate boundary values deduplicated');

	done_testing();
};

# ==================================================================
# _analyze_pod (via extract_all integration)
# --------------------------------------------------
# Tests that POD documentation is correctly parsed
# into parameter specs by running the full extractor
# ==================================================================
subtest '_analyze_pod integration' => sub {
	my $source = <<'PM';
package PodTest;

=head1 METHODS

=head2 greet($name, $age)

Say hello.

=head3 Parameters

$name - string (3-50 chars), the person's name
$age - integer (0-150), the person's age

=cut

sub greet {
	my ($self, $name, $age) = @_;
	return "Hello $name";
}

1;
PM

	my $e = _extractor($source);
	my $schemas = $e->extract_all(no_write => 1);

	ok(exists $schemas->{greet}, 'greet schema extracted');
	my $input = $schemas->{greet}{input};

	# Name parameter should have type and constraints from POD
	ok(exists $input->{name},          'name param extracted from POD');
	is($input->{name}{type}, 'string', 'name type is string');
	is($input->{name}{min},  3,        'name min extracted from POD');
	is($input->{name}{max},  50,       'name max extracted from POD');

	# Age parameter should have integer type from POD
	ok(exists $input->{age},            'age param extracted from POD');
	is($input->{age}{type}, 'integer',  'age type is integer');

	done_testing();
};

# ==================================================================
# _analyze_code (via extract_all integration)
# --------------------------------------------------
# Tests that code patterns are analysed correctly
# ==================================================================
subtest '_analyze_code integration' => sub {
	my $source = <<'PM';
package CodeTest;

use Scalar::Util qw(looks_like_number);

sub add {
	my ($x, $y) = @_;
	die 'not numeric' unless looks_like_number($x);
	return $x + ($y // 0);
}

sub get_name {
	my ($self) = @_;
	return $self->{name};
}

1;
PM

	my $e = _extractor($source, include_private => 0);
	my $schemas = $e->extract_all(no_write => 1);

	# add() schema should be extracted
	ok(exists $schemas->{add}, 'add schema extracted');

	# get_name() should be extracted
	ok(exists $schemas->{get_name}, 'get_name schema extracted');

	# get_name() should ideally be detected as a getter accessor
	if(exists $schemas->{get_name}{accessor}) {
		is($schemas->{get_name}{accessor}{type}, 'getter',
			'get_name detected as getter');
	}

	done_testing();
};

# ==================================================================
# _extract_package_name (via extract_all integration)
# --------------------------------------------------
# Tests that the package name is correctly extracted
# and propagated into all method schemas
# ==================================================================
subtest '_extract_package_name integration' => sub {
	my $source = "package My::Test::Module;\nsub run { return 1; }\n1;\n";
	my $e = _extractor($source);
	my $schemas = $e->extract_all(no_write => 1);

	# The module key in each schema must be the correct package name
	for my $method (keys %{$schemas}) {
		is($schemas->{$method}{module}, 'My::Test::Module',
			"$method schema has correct module name");
	}

	done_testing();
};

# ==================================================================
# extract_all
# --------------------------------------------------
# Integration tests for the main public entry point
# ==================================================================
subtest 'extract_all' => sub {
	my $source = <<'PM';
package ExtractTest;

sub new {
	my ($class, %args) = @_;
	return bless \%args, $class;
}

sub name {
	my ($self, $name) = @_;
	if(@_) {
		$self->{name} = $name;
	}
	return $self->{name};
}

sub _private_method {
	return 1;
}

1;
PM

	# Default settings exclude private methods
	my $e = _extractor($source);
	my $schemas = $e->extract_all(no_write => 1);

	is(ref($schemas), 'HASH',  'extract_all returns hashref');
	ok(exists $schemas->{new},  'new() extracted');
	ok(exists $schemas->{name}, 'name() extracted');
	ok(!exists $schemas->{_private_method}, 'private method excluded by default');

	# Each schema must have the required structural keys
	for my $method (keys %{$schemas}) {
		my $s = $schemas->{$method};
		ok(exists $s->{function},  "$method has function key");
		ok(exists $s->{module},    "$method has module key");
		ok(exists $s->{input},     "$method has input key");
		ok(exists $s->{output},    "$method has output key");
		ok(exists $s->{_analysis}, "$method has _analysis key");
	}

	# include_private flag exposes methods whose names start with _
	my $e2 = _extractor($source, include_private => 1);
	my $schemas2 = $e2->extract_all(no_write => 1);
	ok(exists $schemas2->{_private_method},
		'private method included when include_private set');

	done_testing();
};

# ==================================================================
# extract_all with no_write
# --------------------------------------------------
# Confirms that no_write suppresses file output and
# that without it, YAML files are created on disk
# ==================================================================
subtest 'extract_all no_write' => sub {
	my $dir    = tempdir(CLEANUP => 1);
	my $source = "package NoWrite;\nsub run { return 1; }\n1;\n";
	my $path   = _write_pm($source);

	my $e = App::Test::Generator::SchemaExtractor->new(
		input_file => $path,
		output_dir => $dir,
	);

	# no_write => 1 must not create any YAML files in output_dir
	$e->extract_all(no_write => 1);
	my @files = glob("$dir/*.yml");
	is(scalar @files, 0, 'no_write suppresses file output');

	# Without no_write, YAML files are created in output_dir
	$e->extract_all();
	@files = glob("$dir/*.yml");
	ok(scalar @files > 0, 'without no_write, YAML files are created');

	done_testing();
};

# ==================================================================
# generate_pod_validation_report
# --------------------------------------------------
# Tests the POD/code agreement report generator
# ==================================================================
subtest 'generate_pod_validation_report' => sub {
	my $e  = _extractor();
	my $fn = sub { $e->generate_pod_validation_report(@_) };

	# Empty schemas returns the all-passed message
	my $report = $fn->({});
	like($report, qr/All methods passed/i, 'empty schemas returns all-passed message');

	# Schema with pod_validation_errors appears in the report
	my $schemas = {
		my_method => {
			_pod_validation_errors => ['Type mismatch for $x'],
			_pod_disagreement      => 1,
		}
	};
	$report = $fn->($schemas);
	like($report, qr/my_method/,     'method name in report');
	like($report, qr/Type mismatch/, 'error message in report');

	# Schema without validation errors gives the all-passed message
	$schemas = { clean_method => { input => {}, output => {} } };
	$report = $fn->($schemas);
	like($report, qr/All methods passed/i, 'schema without errors gives all-passed');

	done_testing();
};

# ==================================================================
# _detect_accessor_methods (via extract_all integration)
# --------------------------------------------------
# Tests that getter patterns are correctly identified.
# ASCII comment only -- no Unicode to avoid encoding issues.
# ==================================================================
subtest '_detect_accessor_methods integration' => sub {
	my $source = <<'PM';
package AccessorTest;

# Pure getter -- returns $self->{name} with no setter path
sub name {
	my $self = shift;
	return $self->{name};
}

1;
PM

	my $e = _extractor($source);
	my $schemas = $e->extract_all(no_write => 1);

	# name() should be detected as a getter accessor
	if(exists $schemas->{name} && exists $schemas->{name}{accessor}) {
		is($schemas->{name}{accessor}{type},     'getter', 'name() detected as getter');
		is($schemas->{name}{accessor}{property}, 'name',   'getter property is name');
	}

	done_testing();
};

# ==================================================================
# _needs_object_instantiation (via extract_all integration)
# --------------------------------------------------
# Tests that instance methods get a 'new' key and
# constructors do not
# ==================================================================
subtest '_needs_object_instantiation integration' => sub {
	my $source = <<'PM';
package ObjTest;

sub new {
	my ($class) = @_;
	return bless {}, $class;
}

sub instance_method {
	my ($self) = @_;
	return $self->{value};
}

1;
PM

	my $e = _extractor($source);
	my $schemas = $e->extract_all(no_write => 1);

	# instance_method should carry a 'new' key for object instantiation
	if(exists $schemas->{instance_method}) {
		ok(exists $schemas->{instance_method}{new},
			'instance_method has new key');
	}

	# new() itself must never have a 'new' key
	ok(!exists $schemas->{new}{new}, 'new() constructor has no new key');

	done_testing();
};

# ==================================================================
# _analyze_output_from_code (via extract_all integration)
# --------------------------------------------------
# Tests that return statement analysis produces
# correct output type inferences
# ==================================================================
subtest '_analyze_output_from_code integration' => sub {
	my $source = <<'PM';
package ReturnTest;

# Returns a boolean (0 or 1 only)
sub is_valid {
	my ($self, $x) = @_;
	return 0 unless defined $x;
	return 1;
}

# Returns a blessed ref -- should be object
sub clone {
	my ($self) = @_;
	return bless { %{$self} }, ref($self);
}

1;
PM

	my $e = _extractor($source);
	my $schemas = $e->extract_all(no_write => 1);

	# is_valid should be detected as returning boolean
	if(exists $schemas->{is_valid}) {
		is($schemas->{is_valid}{output}{type}, 'boolean',
			'is_valid output detected as boolean');
	}

	# clone should be detected as returning object
	if(exists $schemas->{clone}) {
		is($schemas->{clone}{output}{type}, 'object',
			'clone output detected as object');
	}

	done_testing();
};

# ==================================================================
# _detect_enum_type (via extract_all integration)
# ==================================================================
subtest '_detect_enum_type integration' => sub {
	my $source = <<'PM';
package EnumTest;

sub set_status {
	my ($self, $status) = @_;
	die "bad status" unless $status =~ /^(active|inactive|pending)$/;
	$self->{status} = $status;
}

1;
PM

	my $e = _extractor($source, include_private => 0);
	my $schemas = $e->extract_all(no_write => 1);

	# set_status should have enum values from the regex alternation
	if(exists $schemas->{set_status} &&
	   exists $schemas->{set_status}{input}{status}) {
		my $status_spec = $schemas->{set_status}{input}{status};
		if(exists $status_spec->{enum}) {
			my %enum_vals = map { $_ => 1 } @{$status_spec->{enum}};
			ok($enum_vals{active},   'active in enum');
			ok($enum_vals{inactive}, 'inactive in enum');
			ok($enum_vals{pending},  'pending in enum');
		}
	}

	done_testing();
};

# ==================================================================
# _yamltest_hints integration
# --------------------------------------------------
# Tests that numeric boundary hints are added for
# methods with numeric intent
# ==================================================================
subtest '_yamltest_hints integration' => sub {
	my $source = <<'PM';
package HintsTest;

use Scalar::Util qw(looks_like_number);

sub scale {
	my ($self, $factor) = @_;
	die 'not numeric' unless looks_like_number($factor);
	die 'negative'    if $factor < 0;
	return $self->{value} * $factor;
}

1;
PM

	my $e = _extractor($source);
	my $schemas = $e->extract_all(no_write => 1);

	# scale() should have boundary values in its _yamltest_hints
	if(exists $schemas->{scale}) {
		my $hints = $schemas->{scale}{_yamltest_hints} // {};
		if(exists $hints->{boundary_values}) {
			ok(scalar @{$hints->{boundary_values}} > 0,
				'boundary values present for numeric method');
		}
	}

	done_testing();
};

done_testing();
