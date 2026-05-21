#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

# White-box unit tests for App::Test::Generator::Planner::Mock.
# Exercises new() and plan() — particularly the calls_external and
# performs_io branches that are the likely mutation survivors.

BEGIN { use_ok('App::Test::Generator::Planner::Mock') }

# ---------------------------------------------------------------
# Helper: build a schema with given side effect flags for
# a single method 'test_method'.
# ---------------------------------------------------------------
sub _schema {
	my (%effects) = @_;
	return {
		test_method => {
			_analysis => {
				side_effects => \%effects,
			},
		},
	};
}

# ---------------------------------------------------------------
# 1. new() — returns a blessed object
# ---------------------------------------------------------------
subtest 'new() constructs a Mock planner' => sub {
	my $p = new_ok('App::Test::Generator::Planner::Mock');
	isa_ok($p, 'App::Test::Generator::Planner::Mock');
};

# ---------------------------------------------------------------
# 2. plan() — croaks when schema is not a hashref
# ---------------------------------------------------------------
subtest 'plan() croaks when schema is not a hashref' => sub {
	my $p = new_ok('App::Test::Generator::Planner::Mock');
	throws_ok(
		sub { $p->plan('not a hashref') },
		qr/schema must be a hashref/,
		'croaks with "schema must be a hashref"',
	);
};

# ---------------------------------------------------------------
# 3. plan() — returns a hashref
# ---------------------------------------------------------------
subtest 'plan() returns a hashref' => sub {
	my $p    = App::Test::Generator::Planner::Mock->new();
	my $plan = $p->plan({});
	ok(ref($plan) eq 'HASH', 'plan() returns a hashref');
};

# ---------------------------------------------------------------
# 4. plan() — calls_external sets mock_system strategy.
#    Kills COND_INV on if($effects->{calls_external}).
# ---------------------------------------------------------------
subtest "plan() assigns mock_system for calls_external methods" => sub {
	my $p    = App::Test::Generator::Planner::Mock->new();
	my $plan = $p->plan(_schema(calls_external => 1));
	is($plan->{test_method}, 'mock_system',
		'calls_external method gets mock_system strategy');
};

# ---------------------------------------------------------------
# 5. plan() — performs_io sets capture_io strategy.
#    Kills COND_INV on elsif($effects->{performs_io}) —
#    if inverted, IO methods would not get capture_io.
# ---------------------------------------------------------------
subtest "plan() assigns capture_io for performs_io methods" => sub {
	my $p    = App::Test::Generator::Planner::Mock->new();
	my $plan = $p->plan(_schema(performs_io => 1));
	is($plan->{test_method}, 'capture_io',
		'performs_io method gets capture_io strategy');
};

# ---------------------------------------------------------------
# 6. plan() — pure method omitted from plan
# ---------------------------------------------------------------
subtest 'plan() omits pure methods with no side effects' => sub {
	my $p    = App::Test::Generator::Planner::Mock->new();
	my $plan = $p->plan(_schema());
	ok(!exists $plan->{test_method},
		'pure method with no side effects omitted from plan');
};

# ---------------------------------------------------------------
# 7. plan() — calls_external takes precedence over performs_io
# ---------------------------------------------------------------
subtest 'plan() gives mock_system precedence over capture_io' => sub {
	my $p    = App::Test::Generator::Planner::Mock->new();
	my $plan = $p->plan(_schema(calls_external => 1, performs_io => 1));
	is($plan->{test_method}, 'mock_system',
		'mock_system takes precedence when both side effects present');
};

# ---------------------------------------------------------------
# 8. plan() — multiple methods planned independently
# ---------------------------------------------------------------
subtest 'plan() handles multiple methods independently' => sub {
	my $p    = App::Test::Generator::Planner::Mock->new();
	my $plan = $p->plan({
		external_method => { _analysis => { side_effects => { calls_external => 1 } } },
		io_method       => { _analysis => { side_effects => { performs_io    => 1 } } },
		pure_method     => { _analysis => { side_effects => {}                     } },
	});
	is($plan->{external_method}, 'mock_system', 'external method gets mock_system');
	is($plan->{io_method},       'capture_io',  'io method gets capture_io');
	ok(!exists $plan->{pure_method}, 'pure method omitted');
};

done_testing();
