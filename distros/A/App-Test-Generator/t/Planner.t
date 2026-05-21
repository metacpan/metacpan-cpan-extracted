#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

# White-box unit tests for App::Test::Generator::Planner.
# Exercises new() and plan_all() — particularly the accessor
# type and output type branches that are the known mutation survivors.

BEGIN { use_ok('App::Test::Generator::Planner') }

# ---------------------------------------------------------------
# Helper: build a Planner with a single method schema
# ---------------------------------------------------------------
sub _planner {
	my (%schema) = @_;
	return App::Test::Generator::Planner->new(
		schemas => { test_method => \%schema },
		package => 'Test::Package',
	);
}

# ---------------------------------------------------------------
# 1. new() — constructs a blessed object
# ---------------------------------------------------------------
subtest 'new() constructs a Planner' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => {},
		package => 'Foo',
	);
	isa_ok($p, 'App::Test::Generator::Planner');
};

# ---------------------------------------------------------------
# 2. plan_all() — returns a hashref
# ---------------------------------------------------------------
subtest 'plan_all() returns a hashref' => sub {
	my $p    = _planner(output => {});
	my $plan = $p->plan_all();
	ok(ref($plan) eq 'HASH', 'plan_all returns a hashref');
	ok(exists $plan->{test_method}, 'plan includes the method');
};

# ---------------------------------------------------------------
# 3. accessor type 'get' sets getter_test flag.
#    Kills COND_INV on the 'get' eq comparison — if inverted,
#    getter_test would be set for non-get accessors instead.
# ---------------------------------------------------------------
subtest "accessor type 'get' sets getter_test flag" => sub {
	my $p    = _planner(
		accessor => { type => 'get' },
		output   => {},
	);
	my $plan = $p->plan_all()->{test_method};
	ok($plan->{getter_test},   'getter_test set for get accessor');
	ok(!$plan->{getset_test},  'getset_test not set for get accessor');
	ok(!$plan->{object_injection_test},
		'object_injection_test not set for get accessor');
};

# ---------------------------------------------------------------
# 4. accessor type 'getset' sets getset_test flag.
#    Kills COND_INV on the 'getset' eq comparison.
# ---------------------------------------------------------------
subtest "accessor type 'getset' sets getset_test flag" => sub {
	my $p    = _planner(
		accessor => { type => 'getset' },
		output   => {},
	);
	my $plan = $p->plan_all()->{test_method};
	ok($plan->{getset_test},   'getset_test set for getset accessor');
	ok(!$plan->{getter_test},  'getter_test not set for getset accessor');
	ok(!$plan->{object_injection_test},
		'object_injection_test not set for getset accessor');
};

# ---------------------------------------------------------------
# 5. accessor type 'injector' sets object_injection_test flag.
#    Kills COND_INV on the 'injector' eq comparison.
# ---------------------------------------------------------------
subtest "accessor type 'injector' sets object_injection_test flag" => sub {
	my $p    = _planner(
		accessor => { type => 'injector' },
		output   => {},
	);
	my $plan = $p->plan_all()->{test_method};
	ok($plan->{object_injection_test},
		'object_injection_test set for injector accessor');
	ok(!$plan->{getter_test},  'getter_test not set for injector accessor');
	ok(!$plan->{getset_test},  'getset_test not set for injector accessor');
};

# ---------------------------------------------------------------
# 6. output type 'boolean' sets boolean_test flag.
#    Kills COND_INV on the 'boolean' eq comparison.
# ---------------------------------------------------------------
subtest "output type 'boolean' sets boolean_test flag" => sub {
	my $p    = _planner(
		output => { type => 'boolean' },
	);
	my $plan = $p->plan_all()->{test_method};
	ok($plan->{boolean_test}, 'boolean_test set for boolean output type');
};

# ---------------------------------------------------------------
# 7. non-boolean output type does not set boolean_test flag.
#    Ensures the boolean branch is not triggered spuriously.
# ---------------------------------------------------------------
subtest 'non-boolean output type does not set boolean_test' => sub {
	my $p    = _planner(
		output => { type => 'string' },
	);
	my $plan = $p->plan_all()->{test_method};
	ok(!$plan->{boolean_test}, 'boolean_test not set for string output type');
};

# ---------------------------------------------------------------
# 8. no accessor or output type produces empty plan
# ---------------------------------------------------------------
subtest 'schema with no accessor or output type produces empty plan' => sub {
	my $p    = _planner(output => {});
	my $plan = $p->plan_all()->{test_method};
	ok(!$plan->{getter_test},            'no getter_test');
	ok(!$plan->{getset_test},            'no getset_test');
	ok(!$plan->{object_injection_test},  'no object_injection_test');
	ok(!$plan->{boolean_test},           'no boolean_test');
};

# ---------------------------------------------------------------
# 9. plan_all() handles multiple methods correctly
# ---------------------------------------------------------------
subtest 'plan_all() handles multiple methods' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => {
			get_name  => { accessor => { type => 'get' },    output => {} },
			is_active => { output   => { type => 'boolean' } },
		},
		package => 'Foo',
	);
	my $plans = $p->plan_all();
	ok($plans->{get_name}{getter_test},   'get_name has getter_test');
	ok($plans->{is_active}{boolean_test}, 'is_active has boolean_test');
	ok(!$plans->{get_name}{boolean_test}, 'get_name has no boolean_test');
};

done_testing();
