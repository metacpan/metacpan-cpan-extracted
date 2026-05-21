#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

# White-box unit tests for App::Test::Generator::TestStrategy.
# Exercises new() and generate_plan() — targeting each conditional
# branch in _plan_for_method that is a known mutation survivor.

BEGIN {
	use_ok('App::Test::Generator::TestStrategy');
	use_ok('App::Test::Generator::Planner');
}

# ---------------------------------------------------------------
# Helper: build a TestStrategy with a single method schema
# ---------------------------------------------------------------
sub _strategy {
	my (%schema) = @_;
	return App::Test::Generator::TestStrategy->new(
		schema => { test_method => \%schema },
	);
}

# ---------------------------------------------------------------
# 1. new() — constructs a blessed object
# ---------------------------------------------------------------
subtest 'new() constructs a TestStrategy' => sub {
	my $s = App::Test::Generator::TestStrategy->new();
	isa_ok($s, 'App::Test::Generator::TestStrategy');
};

# ---------------------------------------------------------------
# 2. new() — defaults applied when no arguments given
# ---------------------------------------------------------------
subtest 'new() applies default schema and thresholds' => sub {
	my $s = new_ok('App::Test::Generator::TestStrategy');
	my $plan = $s->generate_plan();
	ok(ref($plan) eq 'HASH', 'generate_plan returns a hashref');
	is(scalar keys %{$plan}, 0, 'empty schema produces empty plan');
};

# ---------------------------------------------------------------
# 3. generate_plan() — schema with no recognised flags
#	produces basic_test as fallback.
#	Kills COND_INV on the unless %plan guard.
# ---------------------------------------------------------------
subtest 'generate_plan() produces basic_test fallback for plain method' => sub {
	my $plan = _strategy(output => {}, input => {})->generate_plan();
	ok($plan->{test_method}{basic_test},
		'basic_test set when no other flags match');
};

# ---------------------------------------------------------------
# 4. context_aware output sets context_tests flag.
#	Kills COND_INV on if($schema->{output}{_context_aware}).
# ---------------------------------------------------------------
subtest 'context_aware output sets context_tests flag' => sub {
	my $plan = _strategy(
		output => { _context_aware => 1 }, input => {}
	)->generate_plan();
	ok($plan->{test_method}{context_tests},
		'context_tests set for context_aware output');
	ok(!$plan->{test_method}{basic_test},
		'basic_test not set when other flags present');
};

# ---------------------------------------------------------------
# 5. getter accessor sets getter_test flag.
#	Kills COND_INV on if($acc_type eq $ACCESSOR_GETTER).
# ---------------------------------------------------------------
subtest "getter accessor sets getter_test flag" => sub {
	my $plan = _strategy(
		accessor => { type => 'getter' },
		output   => {},
		input	=> {},
	)->generate_plan();
	ok($plan->{test_method}{getter_test}, 'getter_test set for getter accessor');
	ok(!$plan->{test_method}{setter_test}, 'setter_test not set for getter');
	ok(!$plan->{test_method}{getset_test}, 'getset_test not set for getter');
};

# ---------------------------------------------------------------
# 6. boolean getter sets both getter_test and predicate_test.
#	Kills COND_INV on the boolean output check inside getter.
# ---------------------------------------------------------------
subtest "boolean getter sets getter_test and predicate_test" => sub {
	my $plan = _strategy(
		accessor => { type => 'getter' },
		output   => { type => 'boolean' },
		input	=> {},
	)->generate_plan();
	ok($plan->{test_method}{getter_test},	'getter_test set for boolean getter');
	ok($plan->{test_method}{predicate_test}, 'predicate_test set for boolean getter');
};

# ---------------------------------------------------------------
# 7. setter accessor sets setter_test flag.
#	Kills COND_INV on elsif($acc_type eq $ACCESSOR_SETTER).
# ---------------------------------------------------------------
subtest "setter accessor sets setter_test flag" => sub {
	my $plan = _strategy(
		accessor => { type => 'setter' },
		output   => {},
		input	=> {},
	)->generate_plan();
	ok($plan->{test_method}{setter_test}, 'setter_test set for setter accessor');
	ok(!$plan->{test_method}{getter_test}, 'getter_test not set for setter');
};

# ---------------------------------------------------------------
# 8. getset accessor sets getset_test flag.
#	Kills COND_INV on elsif($acc_type eq $ACCESSOR_GETSET).
# ---------------------------------------------------------------
subtest "getset accessor sets getset_test flag" => sub {
	my $plan = _strategy(
		accessor => { type => 'getset' },
		output   => {},
		input	=> { value => { type => 'string' } },
	)->generate_plan();
	ok($plan->{test_method}{getset_test}, 'getset_test set for getset accessor');
};

# ---------------------------------------------------------------
# 9. getset with object param sets object_injection_test.
#	Kills COND_INV on if($param_type eq $TYPE_OBJECT).
# ---------------------------------------------------------------
subtest "getset with object param sets object_injection_test" => sub {
	my $plan = _strategy(
		accessor => { type => 'getset' },
		output   => {},
		input	=> { dep => { type => 'object' } },
	)->generate_plan();
	ok($plan->{test_method}{object_injection_test},
		'object_injection_test set for object param');
	ok($plan->{test_method}{getset_test}, 'getset_test also set');
};

# ---------------------------------------------------------------
# 10. void output type sets void_context_test flag.
#	 Kills COND_INV on if(output type eq void).
# ---------------------------------------------------------------
subtest "void output type sets void_context_test flag" => sub {
	my $plan = _strategy(
		output => { type => 'void' },
		input  => {},
	)->generate_plan();
	ok($plan->{test_method}{void_context_test},
		'void_context_test set for void output');
};

# ---------------------------------------------------------------
# 11. error_return flag sets error_handling_test.
#	 Kills COND_INV on if($schema->{output}{_error_return}).
# ---------------------------------------------------------------
subtest "error_return flag sets error_handling_test" => sub {
	my $plan = _strategy(
		output => { _error_return => 1 },
		input  => {},
	)->generate_plan();
	ok($plan->{test_method}{error_handling_test},
		'error_handling_test set when _error_return present');
};

# ---------------------------------------------------------------
# 12. success_failure_pattern sets error_handling_test.
#	 Kills COND_INV on the success_failure_pattern check.
# ---------------------------------------------------------------
subtest "success_failure_pattern sets error_handling_test" => sub {
	my $plan = _strategy(
		output => { success_failure_pattern => 1 },
		input  => {},
	)->generate_plan();
	ok($plan->{test_method}{error_handling_test},
		'error_handling_test set when success_failure_pattern present');
};

# ---------------------------------------------------------------
# 13. yamltest_hints sets boundary_tests flag.
#	 Kills COND_INV on if($schema->{_yamltest_hints} ...).
# ---------------------------------------------------------------
subtest "yamltest_hints sets boundary_tests flag" => sub {
	my $plan = _strategy(
		output		 => {},
		input		  => {},
		_yamltest_hints => { min => 0, max => 100 },
	)->generate_plan();
	ok($plan->{test_method}{boundary_tests},
		'boundary_tests set when _yamltest_hints present');
};

# ---------------------------------------------------------------
# 14. _returns_self sets chaining_test flag.
#	 Kills COND_INV on if($schema->{output}{_returns_self}).
# ---------------------------------------------------------------
subtest "_returns_self sets chaining_test flag" => sub {
	my $plan = _strategy(
		output => { _returns_self => 1 },
		input  => {},
	)->generate_plan();
	ok($plan->{test_method}{chaining_test},
		'chaining_test set when _returns_self present');
};

# ---------------------------------------------------------------
# 15. boolean output (non-accessor) sets predicate_test.
#	 Kills COND_INV on the final boolean output check.
# ---------------------------------------------------------------
subtest "boolean output without accessor sets predicate_test" => sub {
	my $plan = _strategy(
		output => { type => 'boolean' },
		input  => {},
	)->generate_plan();
	ok($plan->{test_method}{predicate_test}, 'predicate_test set for boolean output with no accessor');
};

subtest 'TestStrategy: non-boolean output does not set boolean_test' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => { m => { output => { type => 'string' } } },
		package => 'Foo',
	);
	my $plan = $p->plan_all()->{m};
	ok(!$plan->{boolean_test}, 'string output: no boolean_test');
};

done_testing();
