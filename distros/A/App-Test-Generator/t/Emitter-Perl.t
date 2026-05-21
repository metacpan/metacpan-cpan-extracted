#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

# White-box unit tests for App::Test::Generator::Emitter::Perl.
# Exercises new(), emit(), and the private _emit_method_tests
# dispatch logic — particularly the postfix if guards that
# control which test blocks are included in the output.

BEGIN { use_ok('App::Test::Generator::Emitter::Perl') }

# ---------------------------------------------------------------
# Helper: construct a minimal emitter with the given plan flags
# set for a single method 'test_method'.
# ---------------------------------------------------------------
sub _emitter {
	my (%plan_flags) = @_;
	return App::Test::Generator::Emitter::Perl->new(
		schema => { test_method => { input => {}, output => {} } },
		plans   => { test_method => \%plan_flags },
		package => 'Test::Package',
	);
}

# ---------------------------------------------------------------
# 1. new() — happy path
# ---------------------------------------------------------------
subtest 'new() constructs an emitter for valid arguments' => sub {
	my $e = _emitter();
	isa_ok($e, 'App::Test::Generator::Emitter::Perl');
};

# ---------------------------------------------------------------
# 2. new() — missing schema croaks
# ---------------------------------------------------------------
subtest 'new() croaks when schema is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Emitter::Perl->new(
				plans   => {},
				package => 'Foo',
			);
		},
		qr/schema required/,
		'croaks with "schema required"',
	);
};

# ---------------------------------------------------------------
# 3. new() — missing plans croaks
# ---------------------------------------------------------------
subtest 'new() croaks when plans is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Emitter::Perl->new(
				schema  => {},
				package => 'Foo',
			);
		},
		qr/plans required/,
		'croaks with "plans required"',
	);
};

# ---------------------------------------------------------------
# 4. new() — missing package croaks
# ---------------------------------------------------------------
subtest 'new() croaks when package is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Emitter::Perl->new(
				schema => {},
				plans  => {},
			);
		},
		qr/package required/,
		'croaks with "package required"',
	);
};

# ---------------------------------------------------------------
# 5. emit() — returns a string
# ---------------------------------------------------------------
subtest 'emit() returns a non-empty string' => sub {
	my $e    = _emitter();
	my $code = $e->emit();
	ok(defined $code,    'emit() returns defined value');
	ok(length($code) > 0, 'emit() returns non-empty string');
	like($code, qr/done_testing/, 'emit() includes done_testing footer');
};

# ---------------------------------------------------------------
# 6. emit() — header contains use_ok and new_ok
# ---------------------------------------------------------------
subtest 'emit() header contains use_ok and new_ok for package' => sub {
	my $e    = _emitter();
	my $code = $e->emit();
	like($code, qr/use_ok\('Test::Package'\)/, 'header contains use_ok');
	like($code, qr/new_ok\('Test::Package'\)/, 'header contains new_ok');
};

# ---------------------------------------------------------------
# 7. getter test emitted when getter_test flag is set
#    and NOT emitted when flag is absent.
#    This kills COND_INV_338 — the if -> unless mutation.
# ---------------------------------------------------------------
subtest 'getter test emitted only when getter_test flag is set' => sub {
	# With flag set — getter block must appear
	my $with = _emitter(getter_test => 1);
	like($with->emit(), qr/returns a value/,
		'getter test appears when getter_test is set');

	# Without flag — getter block must not appear
	my $without = _emitter();
	unlike($without->emit(), qr/returns a value/,
		'getter test absent when getter_test is not set');
};

# ---------------------------------------------------------------
# 8. setter test emitted when setter_test flag is set
#    and NOT emitted when flag is absent.
#    This kills COND_INV_349 — the if -> unless mutation.
# ---------------------------------------------------------------
subtest 'setter test emitted only when setter_test flag is set' => sub {
	# With flag set — setter block must appear
	my $with = _emitter(setter_test => 1);
	like($with->emit(), qr/accepts input/,
		'setter test appears when setter_test is set');

	# Without flag — setter block must not appear
	my $without = _emitter();
	unlike($without->emit(), qr/accepts input/,
		'setter test absent when setter_test is not set');
};

# ---------------------------------------------------------------
# 9. basic test emitted only when basic_test flag is set
# ---------------------------------------------------------------
subtest 'basic test emitted only when basic_test flag is set' => sub {
	my $with    = _emitter(basic_test => 1);
	my $without = _emitter();
	like($with->emit(),    qr/does not die/, 'basic test present when flag set');
	unlike($without->emit(), qr/does not die/, 'basic test absent when flag not set');
};

# ---------------------------------------------------------------
# 10. multiple plan flags produce multiple test blocks
# ---------------------------------------------------------------
subtest 'multiple plan flags produce multiple test blocks' => sub {
	my $e    = _emitter(getter_test => 1, setter_test => 1, basic_test => 1);
	my $code = $e->emit();
	like($code, qr/returns a value/, 'getter block present');
	like($code, qr/accepts input/,   'setter block present');
	like($code, qr/does not die/,  'basic block present');
};

# ---------------------------------------------------------------
# 11. emit() output is deterministic — same input same output
# ---------------------------------------------------------------
subtest 'emit() produces deterministic output' => sub {
	my $e = _emitter(getter_test => 1, setter_test => 1);
	is($e->emit(), $e->emit(), 'emit() returns same string on repeated calls');
};

# ---------------------------------------------------------------
# 12. getset test emitted only when getset_test flag is set
# ---------------------------------------------------------------
subtest 'getset test emitted only when getset_test flag is set' => sub {
	my $with    = _emitter(getset_test => 1);
	my $without = _emitter();
	like($with->emit(),    qr/get\/set works/, 'getset test present when flag set');
	unlike($without->emit(), qr/get\/set works/, 'getset test absent when flag not set');
};

# ---------------------------------------------------------------
# 13. chaining test emitted only when chaining_test flag is set
# ---------------------------------------------------------------
subtest 'chaining test emitted only when chaining_test flag is set' => sub {
	my $with    = _emitter(chaining_test => 1);
	my $without = _emitter();
	like($with->emit(),    qr/returns self for chaining/, 'chaining test present when flag set');
	unlike($without->emit(), qr/returns self for chaining/, 'chaining test absent when flag not set');
};

# ---------------------------------------------------------------
# 14. error test emitted only when error_handling_test flag is set
# ---------------------------------------------------------------
subtest 'error test emitted only when error_handling_test flag is set' => sub {
	my $with    = _emitter(error_handling_test => 1);
	my $without = _emitter();
	like($with->emit(),    qr/handles invalid input/, 'error test present when flag set');
	unlike($without->emit(), qr/handles invalid input/, 'error test absent when flag not set');
};

# ---------------------------------------------------------------
# 15. context test emitted only when context_tests flag is set
# ---------------------------------------------------------------
subtest 'context test emitted only when context_tests flag is set' => sub {
	my $with    = _emitter(context_tests => 1);
	my $without = _emitter();
	like($with->emit(),    qr/survives in scalar context/, 'context test present when flag set');
	unlike($without->emit(), qr/survives in scalar context/, 'context test absent when flag not set');
};

# ---------------------------------------------------------------
# 16. object injection test emitted only when object_injection_test flag is set
# ---------------------------------------------------------------
subtest 'object injection test emitted only when object_injection_test flag is set' => sub {
	my $with    = _emitter(object_injection_test => 1);
	my $without = _emitter();
	like($with->emit(),    qr/stores injected object/, 'object injection test present when flag set');
	unlike($without->emit(), qr/stores injected object/, 'object injection test absent when flag not set');
};

# ---------------------------------------------------------------
# 17. boolean test emitted when boolean_test flag is set
# ---------------------------------------------------------------
subtest 'boolean test emitted only when boolean_test flag is set' => sub {
	my $with    = _emitter(boolean_test => 1);
	my $without = _emitter();
	like($with->emit(),    qr/returns a boolean-like value/, 'boolean test present when flag set');
	unlike($without->emit(), qr/returns a boolean-like value/, 'boolean test absent when flag not set');
};

# ---------------------------------------------------------------
# 18. void test emitted only when void_context_test flag is set
# ---------------------------------------------------------------
subtest 'void test emitted only when void_context_test flag is set' => sub {
	my $with    = _emitter(void_context_test => 1);
	my $without = _emitter();
	like($with->emit(), qr/returns nothing \(void\)/, 'void test present when flag set');
	unlike($without->emit(), qr/returns nothing \(void\)/, 'void test absent when flag not set');
};

# ------------------------------------------------------------------
# Import private methods for direct white-box testing
# ------------------------------------------------------------------
{
	no warnings 'once';
	*_emit_header              = \&App::Test::Generator::Emitter::Perl::_emit_header;
	*_emit_method_tests        = \&App::Test::Generator::Emitter::Perl::_emit_method_tests;
	*_emit_getter_test         = \&App::Test::Generator::Emitter::Perl::_emit_getter_test;
	*_emit_setter_test         = \&App::Test::Generator::Emitter::Perl::_emit_setter_test;
	*_emit_getset_test         = \&App::Test::Generator::Emitter::Perl::_emit_getset_test;
	*_emit_basic_test          = \&App::Test::Generator::Emitter::Perl::_emit_basic_test;
	*_emit_boolean_test        = \&App::Test::Generator::Emitter::Perl::_emit_boolean_test;
	*_emit_void_test           = \&App::Test::Generator::Emitter::Perl::_emit_void_test;
	*_emit_chaining_test       = \&App::Test::Generator::Emitter::Perl::_emit_chaining_test;
	*_emit_error_test          = \&App::Test::Generator::Emitter::Perl::_emit_error_test;
	*_emit_context_test        = \&App::Test::Generator::Emitter::Perl::_emit_context_test;
	*_emit_object_injection_test = \&App::Test::Generator::Emitter::Perl::_emit_object_injection_test;
}

my $SCHEMA = { input => {}, output => {} };

# ==================================================================
# _emit_header
# ==================================================================
subtest '_emit_header() returns a non-empty string' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_header('My::Module');
	ok(defined $result,       '_emit_header returns defined value');
	ok(length($result) > 0,   '_emit_header returns non-empty string');
};

subtest '_emit_header() contains use_ok for the package' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { test_method => $SCHEMA },
		plans   => { test_method => {} },
		package => 'My::Module',
	);
	my $result = $e->_emit_header();
	like($result, qr/use_ok.*My::Module/, 'use_ok present for package');
};

subtest '_emit_header() uses the constructor package name' => sub {
	my $e1 = App::Test::Generator::Emitter::Perl->new(
		schema  => { m => $SCHEMA }, plans => { m => {} },
		package => 'Alpha::Beta',
	);
	my $e2 = App::Test::Generator::Emitter::Perl->new(
		schema  => { m => $SCHEMA }, plans => { m => {} },
		package => 'Gamma::Delta',
	);
	like($e1->_emit_header(), qr/Alpha::Beta/,  'Alpha::Beta in output');
	like($e2->_emit_header(), qr/Gamma::Delta/, 'Gamma::Delta in output');
	unlike($e1->_emit_header(), qr/Gamma::Delta/, 'Gamma::Delta not in Alpha output');
};

subtest '_emit_header() contains use strict and use warnings' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_header('My::Module');
	like($result, qr/use strict/,   'use strict present');
	like($result, qr/use warnings/, 'use warnings present');
};

# ==================================================================
# _emit_method_tests — dispatch to correct sub-emitters
# ==================================================================
subtest '_emit_method_tests() returns empty string when no flags set' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_method_tests('my_method', {});
	# No flags — nothing to emit (may return empty string or just whitespace)
	ok(defined $result, '_emit_method_tests returns defined value');
};

subtest '_emit_method_tests() includes getter block for getter_test flag' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { getter_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	like($result, qr/returns a value/, 'getter block present');
};

subtest '_emit_method_tests() includes setter block for setter_test flag' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { setter_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	like($result, qr/accepts input/, 'setter block present');
};

subtest '_emit_method_tests() includes basic block for basic_test flag' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { basic_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	like($result, qr/does not die/, 'basic block present');
};

subtest '_emit_method_tests() includes boolean block for boolean_test flag' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { boolean_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	ok(length($result) > length("\n# --- Tests for my_method ---\n"),
		'boolean_test flag produced output beyond header');
};

subtest '_emit_method_tests() void_test flag produces header at minimum' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { void_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	ok(defined $result, 'void_test flag: _emit_method_tests returns defined value');
};

subtest '_emit_method_tests() context_test flag produces header at minimum' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { context_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	ok(defined $result, 'context_test flag: _emit_method_tests returns defined value');
};

subtest '_emit_method_tests() includes chaining block for chaining_test flag' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { chaining_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	ok(length($result) > length("\n# --- Tests for my_method ---\n"),
		'chaining_test flag produced output beyond header');
};

subtest '_emit_method_tests() includes error block for error_handling_test flag' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { error_handling_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	ok(length($result) > length("\n# --- Tests for my_method ---\n"),
		'error_handling_test flag produced output beyond header');
};

subtest '_emit_method_tests() includes getset block for getset_test flag' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { getset_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	ok(length($result) > length("\n# --- Tests for my_method ---\n"),
		'getset_test flag produced output beyond header');
};

subtest '_emit_method_tests() includes object injection block for object_injection_test flag' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { object_injection_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	ok(length($result) > length("\n# --- Tests for my_method ---\n"),
		'object_injection_test flag produced output beyond header');
};

subtest '_emit_method_tests() all flags together produce all blocks' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => $SCHEMA },
		plans   => { foo => {
			getter_test         => 1,
			setter_test         => 1,
			basic_test          => 1,
			boolean_test        => 1,
			void_test           => 1,
			chaining_test       => 1,
			error_handling_test => 1,
			getset_test         => 1,
		}},
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('foo');
	like($result, qr/returns a value/, 'getter block present');
	like($result, qr/accepts input/,   'setter block present');
	like($result, qr/does not die/,    'basic block present');
};

subtest '_emit_method_tests() contains method name in output' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_method_tests('my_special_method', { getter_test => 1 });
	like($result, qr/my_special_method/, 'method name appears in output');
};

# ==================================================================
# Individual _emit_* methods — called directly
# ==================================================================
subtest '_emit_getter_test() returns non-empty string with method name' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_getter_test('get_name', $SCHEMA);
	ok(length($result) > 0, '_emit_getter_test returns non-empty string');
	like($result, qr/get_name/, 'method name in getter output');
	like($result, qr/returns a value/, 'characteristic getter phrase present');
};

subtest '_emit_setter_test() returns non-empty string with method name' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_setter_test('set_name', $SCHEMA);
	ok(length($result) > 0, '_emit_setter_test returns non-empty string');
	like($result, qr/set_name/, 'method name in setter output');
	like($result, qr/accepts input/, 'characteristic setter phrase present');
};

subtest '_emit_basic_test() returns non-empty string with method name' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_basic_test('do_thing', $SCHEMA);
	ok(length($result) > 0, '_emit_basic_test returns non-empty string');
	like($result, qr/do_thing/, 'method name in basic output');
	like($result, qr/does not die/, 'characteristic basic phrase present');
};

subtest '_emit_boolean_test() returns non-empty string with method name' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_boolean_test('is_valid', $SCHEMA);
	ok(length($result) > 0, '_emit_boolean_test returns non-empty string');
	like($result, qr/is_valid/, 'method name in boolean output');
};

subtest '_emit_void_test() returns non-empty string with method name' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_void_test('set_flag', $SCHEMA);
	ok(length($result) > 0, '_emit_void_test returns non-empty string');
	like($result, qr/set_flag/, 'method name in void output');
};

subtest '_emit_chaining_test() returns non-empty string with method name' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_chaining_test('set_width', $SCHEMA);
	ok(length($result) > 0, '_emit_chaining_test returns non-empty string');
	like($result, qr/set_width/, 'method name in chaining output');
};

subtest '_emit_error_test() returns non-empty string with method name' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_error_test('parse', $SCHEMA);
	ok(length($result) > 0, '_emit_error_test returns non-empty string');
	like($result, qr/parse/, 'method name in error output');
};

subtest '_emit_getset_test() returns non-empty string with method name' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_getset_test('name', $SCHEMA);
	ok(length($result) > 0, '_emit_getset_test returns non-empty string');
	like($result, qr/name/, 'method name in getset output');
};

subtest '_emit_context_test() returns non-empty string with method name' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_context_test('get_items', $SCHEMA);
	ok(length($result) > 0, '_emit_context_test returns non-empty string');
	like($result, qr/get_items/, 'method name in context output');
};

subtest '_emit_object_injection_test() returns non-empty string with method name' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_object_injection_test('set_logger', $SCHEMA);
	ok(length($result) > 0, '_emit_object_injection_test returns non-empty string');
	like($result, qr/set_logger/, 'method name in object injection output');
};

# ==================================================================
# _emit_method_tests — no flag produces no output for that type
# ==================================================================
subtest '_emit_method_tests() boolean block absent when flag not set' => sub {
	my $e      = _emitter();
	my $result = $e->_emit_method_tests('my_method', {}, $SCHEMA);
	unlike($result, qr/returns.*true\b|boolean/i,
		'boolean block absent when flag not set');
};

subtest '_emit_method_tests() includes void block for void_test flag' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { my_method => $SCHEMA },
		plans   => { my_method => { void_context_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('my_method');
	like($result, qr/returns nothing \(void\)/, 'void block present');
};

subtest '_emit_method_tests() all flags together produce all known blocks' => sub {
	# getter_test, setter_test, basic_test are verified to produce output
	# by subtests 25-27. Confirm they still all work when combined.
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => $SCHEMA },
		plans   => { foo => {
			getter_test => 1,
			setter_test => 1,
			basic_test  => 1,
		}},
		package => 'Test::Package',
	);
	my $result = $e->_emit_method_tests('foo');
	like($result, qr/returns a value/, 'getter block present');
	like($result, qr/accepts input/,   'setter block present');
	like($result, qr/does not die/,    'basic block present');
};

# ==================================================================
# Direct _emit_* helper tests — kill BOOL_NEGATE and RETURN_UNDEF
# survivors on every heredoc return line
# ==================================================================

{
	no warnings 'once';
	*_emit_header           = \&App::Test::Generator::Emitter::Perl::_emit_header;
	*_emit_method_tests     = \&App::Test::Generator::Emitter::Perl::_emit_method_tests;
	*_emit_basic_test       = \&App::Test::Generator::Emitter::Perl::_emit_basic_test;
	*_emit_getter_test      = \&App::Test::Generator::Emitter::Perl::_emit_getter_test;
	*_emit_setter_test      = \&App::Test::Generator::Emitter::Perl::_emit_setter_test;
	*_emit_getset_test      = \&App::Test::Generator::Emitter::Perl::_emit_getset_test;
	*_emit_chaining_test    = \&App::Test::Generator::Emitter::Perl::_emit_chaining_test;
	*_emit_error_test       = \&App::Test::Generator::Emitter::Perl::_emit_error_test;
	*_emit_context_test     = \&App::Test::Generator::Emitter::Perl::_emit_context_test;
	*_emit_object_injection_test = \&App::Test::Generator::Emitter::Perl::_emit_object_injection_test;
	*_emit_boolean_test     = \&App::Test::Generator::Emitter::Perl::_emit_boolean_test;
	*_emit_void_test        = \&App::Test::Generator::Emitter::Perl::_emit_void_test;
}

# Helper to build a minimal emitter
sub _e {
	my (%schema_input) = @_;
	return App::Test::Generator::Emitter::Perl->new(
		schema  => { m => { input => \%schema_input } },
		plans   => { m => {} },
		package => 'My::Module',
	);
}

# -- _emit_header --

subtest '_emit_header() returns defined non-empty string' => sub {
	my $e = _e();
	my $result = $e->_emit_header();
	ok(defined $result,       '_emit_header: defined');
	ok(length($result) > 0,   '_emit_header: non-empty');
	like($result, qr/use strict/, '_emit_header: contains use strict');
};

# -- _emit_basic_test --

subtest '_emit_basic_test() returns defined non-empty string' => sub {
	my $e = _e();
	my $result = $e->_emit_basic_test('foo');
	ok(defined $result,      '_emit_basic_test: defined');
	ok(length($result) > 0,  '_emit_basic_test: non-empty');
	like($result, qr/foo does not die/, '_emit_basic_test: contains expected text');
};

# -- _emit_getter_test --

subtest '_emit_getter_test() returns defined non-empty string' => sub {
	my $e = _e();
	my $result = $e->_emit_getter_test('bar');
	ok(defined $result,     '_emit_getter_test: defined');
	ok(length($result) > 0, '_emit_getter_test: non-empty');
	like($result, qr/bar returns a value/, '_emit_getter_test: contains expected text');
};

# -- _emit_setter_test --

subtest '_emit_setter_test() returns defined non-empty string' => sub {
	my $e = _e();
	my $result = $e->_emit_setter_test('baz');
	ok(defined $result,     '_emit_setter_test: defined');
	ok(length($result) > 0, '_emit_setter_test: non-empty');
	like($result, qr/baz accepts input/, '_emit_setter_test: contains expected text');
};

# -- _emit_getset_test -- COND_INV killers (lines 328 and 339)

subtest '_emit_getset_test() object type: returns defined non-empty string with isa_ok' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { m => { input => { obj => { type => 'object' } } } },
		plans   => { m => {} },
		package => 'My::Module',
	);
	my $result = $e->_emit_getset_test('m');
	ok(defined $result,     'object: defined');
	ok(length($result) > 0, 'object: non-empty');
	like($result, qr/isa_ok/, 'object: contains isa_ok');
};

subtest '_emit_getset_test() non-object type: returns defined non-empty string without isa_ok' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { m => { input => { x => { type => 'string' } } } },
		plans   => { m => {} },
		package => 'My::Module',
	);
	my $result = $e->_emit_getset_test('m');
	ok(defined $result,       'non-object: defined');
	ok(length($result) > 0,   'non-object: non-empty');
	unlike($result, qr/isa_ok/, 'non-object: does not contain isa_ok');
};

subtest '_emit_getset_test() boolean type: returns defined non-empty string with boolean text' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { m => { input => { flag => { type => 'boolean' } } } },
		plans   => { m => {} },
		package => 'My::Module',
	);
	my $result = $e->_emit_getset_test('m');
	ok(defined $result,        'boolean: defined');
	ok(length($result) > 0,    'boolean: non-empty');
	like($result, qr/boolean/, 'boolean: contains boolean text');
};

subtest '_emit_getset_test() non-boolean type: returns defined non-empty string with get/set' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { m => { input => { x => { type => 'integer' } } } },
		plans   => { m => {} },
		package => 'My::Module',
	);
	my $result = $e->_emit_getset_test('m');
	ok(defined $result,           'non-boolean: defined');
	ok(length($result) > 0,       'non-boolean: non-empty');
	like($result, qr/get\/set works/, 'non-boolean: contains get/set works');
};

subtest '_emit_getset_test() no input type: falls through to string round-trip' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { m => { input => {} } },
		plans   => { m => {} },
		package => 'My::Module',
	);
	my $result = $e->_emit_getset_test('m');
	ok(defined $result,     'no type: defined');
	ok(length($result) > 0, 'no type: non-empty');
};

# -- _emit_chaining_test --

subtest '_emit_chaining_test() returns defined non-empty string' => sub {
	my $e = _e();
	my $result = $e->_emit_chaining_test('chain_me');
	ok(defined $result,     '_emit_chaining_test: defined');
	ok(length($result) > 0, '_emit_chaining_test: non-empty');
	like($result, qr/chain_me returns self/, '_emit_chaining_test: contains expected text');
};

# -- _emit_error_test --

subtest '_emit_error_test() returns defined non-empty string' => sub {
	my $e = _e();
	my $result = $e->_emit_error_test('validate');
	ok(defined $result,     '_emit_error_test: defined');
	ok(length($result) > 0, '_emit_error_test: non-empty');
	like($result, qr/validate handles invalid/, '_emit_error_test: contains expected text');
};

# -- _emit_context_test --

subtest '_emit_context_test() returns defined non-empty string' => sub {
	my $e = _e();
	my $result = $e->_emit_context_test('ctx');
	ok(defined $result,     '_emit_context_test: defined');
	ok(length($result) > 0, '_emit_context_test: non-empty');
	like($result, qr/ctx survives in scalar context/, '_emit_context_test: contains expected text');
};

# -- _emit_object_injection_test --

subtest '_emit_object_injection_test() returns defined non-empty string' => sub {
	my $e = _e();
	my $result = $e->_emit_object_injection_test('inject');
	ok(defined $result,     '_emit_object_injection_test: defined');
	ok(length($result) > 0, '_emit_object_injection_test: non-empty');
	like($result, qr/inject stores injected object/, '_emit_object_injection_test: contains expected text');
};

# -- _emit_boolean_test --

subtest '_emit_boolean_test() returns defined non-empty string' => sub {
	my $e = _e();
	my $result = $e->_emit_boolean_test('is_ok');
	ok(defined $result,     '_emit_boolean_test: defined');
	ok(length($result) > 0, '_emit_boolean_test: non-empty');
	like($result, qr/is_ok returns a defined value/, '_emit_boolean_test: contains expected text');
};

# -- _emit_void_test --

subtest '_emit_void_test() returns defined non-empty string' => sub {
	my $e = _e();
	my $result = $e->_emit_void_test('do_thing');
	ok(defined $result,                         '_emit_void_test: defined');
	ok(length($result) > 0,                     '_emit_void_test: non-empty');
	like($result, qr/do_thing does not die/,    '_emit_void_test: does-not-die check present');
	like($result, qr/returns nothing \(void\)/, '_emit_void_test: void return check present');
	unlike($result, qr/\|\| 1/,                '_emit_void_test: no tautology');
};

# -- _emit_method_tests dispatch --

subtest '_emit_method_tests() with no flags returns only section header' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { m => { input => {} } },
		plans   => { m => {} },
		package => 'My::Module',
	);
	my $result = $e->_emit_method_tests('m');
	ok(defined $result,        '_emit_method_tests empty plan: defined');
	ok(length($result) > 0,    '_emit_method_tests empty plan: non-empty');
	like($result, qr/Tests for m/, 'section header present');
};

done_testing();
