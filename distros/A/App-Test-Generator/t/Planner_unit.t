#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;

# Black-box unit tests for App::Test::Generator::Planner.
# Tests each public function according to its POD API specification.
# build_plan() dependencies are mocked via Test::Mockingbird.

BEGIN { use_ok('App::Test::Generator::Planner') }

# --------------------------------------------------
# Helper: build a Planner with a single method schema
# --------------------------------------------------
sub _planner {
	my (%schema) = @_;
	return App::Test::Generator::Planner->new(
		schemas => { test_method => \%schema },
		package => 'Test::Package',
	);
}

# ==================================================================
# new()
#
# POD spec:
#   Arguments: schemas (hashref), package (string)
#   Returns:   blessed hashref
# ==================================================================

subtest 'new() returns a blessed Planner object' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => {},
		package => 'Foo',
	);
	isa_ok($p, 'App::Test::Generator::Planner');
};

subtest 'new() stores schemas and package' => sub {
	my $schemas = { foo => { output => {} } };
	my $p = App::Test::Generator::Planner->new(
		schemas => $schemas,
		package => 'My::Module',
	);
	is_deeply($p->{schemas}, $schemas, 'schemas stored');
	is($p->{package}, 'My::Module',    'package stored');
};

subtest 'new() each call returns a distinct object' => sub {
	my $p1 = App::Test::Generator::Planner->new(schemas => {}, package => 'A');
	my $p2 = App::Test::Generator::Planner->new(schemas => {}, package => 'B');
	isnt($p1, $p2, 'distinct objects returned');
};

# ==================================================================
# plan_all()
#
# POD spec:
#   Returns a hashref mapping method names to plan hashrefs.
#   accessor type 'get'      -> getter_test flag
#   accessor type 'getset'   -> getset_test flag
#   accessor type 'injector' -> object_injection_test flag
#   output type 'boolean'    -> boolean_test flag
# ==================================================================

subtest 'plan_all() returns a hashref' => sub {
	my $p = _planner(output => {});
	is(ref($p->plan_all()), 'HASH', 'returns hashref');
};

subtest 'plan_all() includes an entry for each method in schemas' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => {
			foo => { output => {} },
			bar => { output => {} },
		},
		package => 'X',
	);
	my $plan = $p->plan_all();
	ok(exists $plan->{foo}, 'foo present in plan');
	ok(exists $plan->{bar}, 'bar present in plan');
};

subtest 'plan_all() returns empty hashref for empty schemas' => sub {
	my $p = App::Test::Generator::Planner->new(schemas => {}, package => 'X');
	is_deeply($p->plan_all(), {}, 'empty schemas -> empty plan');
};

subtest "plan_all() accessor type 'get' sets getter_test flag" => sub {
	my $p    = _planner(accessor => { type => 'get' }, output => {});
	my $plan = $p->plan_all()->{test_method};
	ok( $plan->{getter_test},              'getter_test set');
	ok(!$plan->{getset_test},              'getset_test not set');
	ok(!$plan->{object_injection_test},    'object_injection_test not set');
};

subtest "plan_all() accessor type 'getset' sets getset_test flag" => sub {
	my $p    = _planner(accessor => { type => 'getset' }, output => {});
	my $plan = $p->plan_all()->{test_method};
	ok( $plan->{getset_test},              'getset_test set');
	ok(!$plan->{getter_test},              'getter_test not set');
	ok(!$plan->{object_injection_test},    'object_injection_test not set');
};

subtest "plan_all() accessor type 'injector' sets object_injection_test flag" => sub {
	my $p    = _planner(accessor => { type => 'injector' }, output => {});
	my $plan = $p->plan_all()->{test_method};
	ok( $plan->{object_injection_test},    'object_injection_test set');
	ok(!$plan->{getter_test},              'getter_test not set');
	ok(!$plan->{getset_test},              'getset_test not set');
};

subtest "plan_all() output type 'boolean' sets boolean_test flag" => sub {
	my $p    = _planner(output => { type => 'boolean' });
	my $plan = $p->plan_all()->{test_method};
	ok($plan->{boolean_test}, 'boolean_test set for boolean output');
};

subtest 'plan_all() non-boolean output type does not set boolean_test' => sub {
	my $p    = _planner(output => { type => 'string' });
	my $plan = $p->plan_all()->{test_method};
	ok(!$plan->{boolean_test}, 'boolean_test not set for string output');
};

subtest 'plan_all() no accessor or output type produces empty plan hashref' => sub {
	my $p    = _planner(output => {});
	my $plan = $p->plan_all()->{test_method};
	ok(!$plan->{getter_test},           'no getter_test');
	ok(!$plan->{getset_test},           'no getset_test');
	ok(!$plan->{object_injection_test}, 'no object_injection_test');
	ok(!$plan->{boolean_test},          'no boolean_test');
};

subtest 'plan_all() unknown accessor type sets no flags' => sub {
	my $p    = _planner(accessor => { type => 'unknown' }, output => {});
	my $plan = $p->plan_all()->{test_method};
	ok(!$plan->{getter_test},           'no getter_test for unknown type');
	ok(!$plan->{getset_test},           'no getset_test for unknown type');
	ok(!$plan->{object_injection_test}, 'no object_injection_test for unknown type');
};

subtest 'plan_all() handles multiple methods independently' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => {
			get_name  => { accessor => { type => 'get' },    output => {} },
			is_active => { output   => { type => 'boolean' } },
			set_value => { accessor => { type => 'getset' },
			               output   => { type => 'string'  } },
		},
		package => 'Foo',
	);
	my $plans = $p->plan_all();
	ok( $plans->{get_name}{getter_test},    'get_name: getter_test set');
	ok(!$plans->{get_name}{boolean_test},   'get_name: boolean_test not set');
	ok( $plans->{is_active}{boolean_test},  'is_active: boolean_test set');
	ok(!$plans->{is_active}{getter_test},   'is_active: getter_test not set');
	ok( $plans->{set_value}{getset_test},   'set_value: getset_test set');
	ok(!$plans->{set_value}{boolean_test},  'set_value: boolean_test not set');
};

# ==================================================================
# build_plan()
#
# POD spec:
#   Returns a hashref with keys: strategy, isolation,
#   fixture, mock, groups.
#   Calls TestStrategy, Isolation, Fixture, Mock, Grouping.
#   Mock all five sub-planners.
# ==================================================================

subtest 'build_plan() returns hashref with all five keys' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => { foo => { output => {} } },
		package => 'Foo',
	);

	my $g1 = mock_scoped 'App::Test::Generator::TestStrategy::new'
		=> sub { bless {}, 'App::Test::Generator::TestStrategy' };
	my $g2 = mock_scoped 'App::Test::Generator::TestStrategy::generate_plan'
		=> sub { {} };
	my $g3 = mock_scoped 'App::Test::Generator::Planner::Isolation::new'
		=> sub { bless {}, 'App::Test::Generator::Planner::Isolation' };
	my $g4 = mock_scoped 'App::Test::Generator::Planner::Isolation::plan'
		=> sub { {} };
	my $g5 = mock_scoped 'App::Test::Generator::Planner::Fixture::new'
		=> sub { bless {}, 'App::Test::Generator::Planner::Fixture' };
	my $g6 = mock_scoped 'App::Test::Generator::Planner::Fixture::plan'
		=> sub { {} };
	my $g7 = mock_scoped 'App::Test::Generator::Planner::Mock::new'
		=> sub { bless {}, 'App::Test::Generator::Planner::Mock' };
	my $g8 = mock_scoped 'App::Test::Generator::Planner::Mock::plan'
		=> sub { {} };
	my $g9 = mock_scoped 'App::Test::Generator::Planner::Grouping::new'
		=> sub { bless {}, 'App::Test::Generator::Planner::Grouping' };
	my $g10 = mock_scoped 'App::Test::Generator::Planner::Grouping::plan'
		=> sub { { pure => [], mutating => [], impure => [] } };

	my $result;
	lives_ok(sub { $result = $p->build_plan() }, 'build_plan() lives');
	is(ref($result), 'HASH', 'returns hashref');
	for my $key (qw(strategy isolation fixture mock groups)) {
		ok(exists $result->{$key}, "$key key present");
	}
};

subtest 'build_plan() strategy key contains TestStrategy output' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => { foo => { output => {} } },
		package => 'Foo',
	);
	my $fake_strategy = { foo => { test_type => 'basic' } };

	my $g1 = mock_scoped 'App::Test::Generator::TestStrategy::new'
		=> sub { bless {}, 'App::Test::Generator::TestStrategy' };
	my $g2 = mock_scoped 'App::Test::Generator::TestStrategy::generate_plan'
		=> sub { $fake_strategy };
	my $g3 = mock_scoped 'App::Test::Generator::Planner::Isolation::new'
		=> sub { bless {}, 'App::Test::Generator::Planner::Isolation' };
	my $g4 = mock_scoped 'App::Test::Generator::Planner::Isolation::plan'
		=> sub { {} };
	my $g5 = mock_scoped 'App::Test::Generator::Planner::Fixture::new'
		=> sub { bless {}, 'App::Test::Generator::Planner::Fixture' };
	my $g6 = mock_scoped 'App::Test::Generator::Planner::Fixture::plan'
		=> sub { {} };
	my $g7 = mock_scoped 'App::Test::Generator::Planner::Mock::new'
		=> sub { bless {}, 'App::Test::Generator::Planner::Mock' };
	my $g8 = mock_scoped 'App::Test::Generator::Planner::Mock::plan'
		=> sub { {} };
	my $g9 = mock_scoped 'App::Test::Generator::Planner::Grouping::new'
		=> sub { bless {}, 'App::Test::Generator::Planner::Grouping' };
	my $g10 = mock_scoped 'App::Test::Generator::Planner::Grouping::plan'
		=> sub { { pure => [], mutating => [], impure => [] } };

	my $result = $p->build_plan();
	is_deeply($result->{strategy}, $fake_strategy,
		'strategy key contains TestStrategy output');
};

done_testing();
