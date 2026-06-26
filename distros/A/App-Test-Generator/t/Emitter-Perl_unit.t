#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

# Black-box unit tests for App::Test::Generator::Emitter::Perl.
# Tests each public function according to its POD API specification.
# No mocking required — Emitter::Perl has no external dependencies.

BEGIN { use_ok('App::Test::Generator::Emitter::Perl') }

# --------------------------------------------------
# Helper: build a minimal valid Emitter
# --------------------------------------------------
sub _emitter {
	my (%args) = @_;
	return App::Test::Generator::Emitter::Perl->new(
		schema  => $args{schema}  // { test_method => {} },
		plans   => $args{plans}   // { test_method => {} },
		package => $args{package} // 'Test::Package',
	);
}

# ==================================================================
# new()
#
# POD spec:
#   Required: schema (hashref), plans (hashref), package (scalar)
#   Returns:  blessed hashref
#   Croaks:   when any required argument is missing
# ==================================================================

subtest 'new() returns a blessed Emitter::Perl object' => sub {
	my $e = _emitter();
	isa_ok($e, 'App::Test::Generator::Emitter::Perl');
};

subtest 'new() croaks when schema is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Emitter::Perl->new(
				plans   => {},
				package => 'Foo',
			)
		},
		qr/schema required/,
		'missing schema croaks',
	);
};

subtest 'new() croaks when plans is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Emitter::Perl->new(
				schema  => {},
				package => 'Foo',
			)
		},
		qr/plans required/,
		'missing plans croaks',
	);
};

subtest 'new() croaks when package is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Emitter::Perl->new(
				schema => {},
				plans  => {},
			)
		},
		qr/package required/,
		'missing package croaks',
	);
};

subtest 'new() croaks when package is not a valid Perl package name' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Emitter::Perl->new(
				schema  => {},
				plans   => {},
				package => "Evil'); system('touch /tmp/pwned'); #",
			)
		},
		qr/not a valid Perl package name/,
		'malformed package name croaks rather than being spliced into generated code',
	);
};

subtest 'new() stores all three arguments' => sub {
	my $schema  = { foo => { output => {} } };
	my $plans   = { foo => { basic_test => 1 } };
	my $package = 'My::Module';
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => $schema,
		plans   => $plans,
		package => $package,
	);
	is_deeply($e->{schema},  $schema,  'schema stored');
	is_deeply($e->{plans},   $plans,   'plans stored');
	is($e->{package}, $package, 'package stored');
};

subtest 'new() each call returns a distinct object' => sub {
	my $e1 = _emitter();
	my $e2 = _emitter();
	isnt($e1, $e2, 'distinct objects returned');
};

# ==================================================================
# emit()
#
# POD spec:
#   Returns a string containing the complete Perl test file source.
#   Includes header, one block per method, done_testing() footer.
# ==================================================================

subtest 'emit() returns a string' => sub {
	my $e = _emitter();
	my $result = $e->emit();
	ok(defined $result,    'returns defined value');
	ok(!ref($result),      'returns a scalar string');
	ok(length($result) > 0, 'returns non-empty string');
};

subtest 'emit() contains use strict and use warnings' => sub {
	my $e = _emitter();
	my $result = $e->emit();
	like($result, qr/use strict/,   'contains use strict');
	like($result, qr/use warnings/, 'contains use warnings');
};

subtest 'emit() contains use_ok for the package' => sub {
	my $e = _emitter(package => 'My::Module');
	my $result = $e->emit();
	like($result, qr/use_ok.*My::Module/, 'contains use_ok for package');
};

subtest 'emit() contains new_ok for the package' => sub {
	my $e = _emitter(package => 'My::Module');
	my $result = $e->emit();
	like($result, qr/new_ok.*My::Module/, 'contains new_ok for package');
};

subtest 'emit() contains done_testing() footer' => sub {
	my $e = _emitter();
	my $result = $e->emit();
	like($result, qr/done_testing\(\)/, 'contains done_testing()');
};

subtest 'emit() includes a section comment for each method' => sub {
	my $e = _emitter(
		schema => { my_method => {} },
		plans  => { my_method => {} },
	);
	my $result = $e->emit();
	like($result, qr/my_method/, 'method name appears in output');
};

subtest 'emit() handles multiple methods in sorted order' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { alpha => {}, beta => {}, gamma => {} },
		plans   => { alpha => {}, beta => {}, gamma => {} },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	my $pos_alpha = index($result, 'alpha');
	my $pos_beta  = index($result, 'beta');
	my $pos_gamma = index($result, 'gamma');
	ok($pos_alpha < $pos_beta,  'alpha appears before beta');
	ok($pos_beta  < $pos_gamma, 'beta appears before gamma');
};

subtest 'emit() croaks when a method name is not a valid Perl identifier' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { "foo'); system('touch /tmp/pwned'); #" => {} },
		plans   => { "foo'); system('touch /tmp/pwned'); #" => { basic_test => 1 } },
		package => 'Test::Package',
	);
	throws_ok(
		sub { $e->emit() },
		qr/not a valid Perl identifier/,
		'malformed method name croaks rather than being spliced into generated code',
	);
};

subtest 'emit() with no methods still produces valid header and footer' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => {},
		plans   => {},
		package => 'Empty::Module',
	);
	my $result = $e->emit();
	like($result, qr/use strict/,      'header present with no methods');
	like($result, qr/done_testing\(\)/, 'footer present with no methods');
};

subtest 'emit() basic_test flag produces does-not-die block' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => {} },
		plans   => { foo => { basic_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/does not die/, 'basic_test block present');
};

subtest 'emit() getter_test flag produces returns-a-value block' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => {} },
		plans   => { foo => { getter_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/returns a value/, 'getter_test block present');
};

subtest 'emit() setter_test flag produces accepts-input block' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => {} },
		plans   => { foo => { setter_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/accepts input/, 'setter_test block present');
};

subtest 'emit() chaining_test flag produces returns-self block' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => {} },
		plans   => { foo => { chaining_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/chaining/, 'chaining_test block present');
};

subtest 'emit() error_handling_test flag produces error block' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => {} },
		plans   => { foo => { error_handling_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/invalid input|handles|error/i,
		'error_handling_test block present');
};

subtest 'emit() object_injection_test flag produces injection block' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => {} },
		plans   => { foo => { object_injection_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/inject|Mock::Object/i, 'object_injection_test block present');
};

subtest 'emit() boolean_test flag produces boolean block' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => {} },
		plans   => { foo => { boolean_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/boolean|defined.*result/i, 'boolean_test block present');
};

subtest 'emit() getset_test with no schema type produces string round-trip' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => { input => {} } },
		plans   => { foo => { getset_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/get\/set works/, 'getset string round-trip block present');
};

subtest 'emit() getset_test with boolean type produces boolean round-trip' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => { input => {
			flag => { type => 'boolean' }
		} } },
		plans   => { foo => { getset_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/boolean true|boolean false/, 'boolean round-trip present');
};

subtest 'emit() getset_test with object type produces isa_ok round-trip' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => { input => {
			obj => { type => 'object' }
		} } },
		plans   => { foo => { getset_test => 1 } },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/isa_ok/, 'object round-trip uses isa_ok');
};

subtest 'emit() multiple flags together produce multiple blocks' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => {} },
		plans   => { foo => {
			basic_test  => 1,
			getter_test => 1,
			setter_test => 1,
		} },
		package => 'Test::Package',
	);
	my $result = $e->emit();
	like($result, qr/does not die/,  'basic block present');
	like($result, qr/returns a value/, 'getter block present');
	like($result, qr/accepts input/,   'setter block present');
};

subtest 'emit() package name appears in use_ok and new_ok' => sub {
	my $e = _emitter(package => 'Alpha::Beta');
	my $result = $e->emit();
	my @uses = ($result =~ /(Alpha::Beta)/g);
	ok(scalar @uses >= 2, 'package name appears at least twice');
};

done_testing();
