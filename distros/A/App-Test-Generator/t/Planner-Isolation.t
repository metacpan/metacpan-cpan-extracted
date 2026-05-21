#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('App::Test::Generator::Planner::Isolation') }

# ==================================================================
# new
# ==================================================================
subtest 'new() returns a blessed object' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new();
	ok(defined $p, 'new() returns defined value');
	isa_ok($p, 'App::Test::Generator::Planner::Isolation');
};

subtest 'new() object is an empty hashref' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new();
	is(scalar keys %{$p}, 0, 'object is an empty hashref');
};

subtest 'new() each call returns a distinct object' => sub {
	my $p1 = new_ok('App::Test::Generator::Planner::Isolation');
	my $p2 = new_ok('App::Test::Generator::Planner::Isolation');
	isnt($p1, $p2, 'each call produces a distinct object');
};

# ==================================================================
# plan — argument validation
# ==================================================================
subtest 'plan() croaks when strategy is not a hashref' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new();
	throws_ok(
		sub { $p->plan({}, 'not a hashref') },
		qr/strategy must be a hashref/,
		'string strategy croaks',
	);
	throws_ok(
		sub { $p->plan({}, undef) },
		qr/strategy must be a hashref/,
		'undef strategy croaks',
	);
	throws_ok(
		sub { $p->plan({}, []) },
		qr/strategy must be a hashref/,
		'arrayref strategy croaks',
	);
};

# ==================================================================
# plan — return structure
# ==================================================================
subtest 'plan() returns a hashref' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $result = $p->plan({}, {});
	is(ref($result), 'HASH', 'returns a hashref');
};

subtest 'plan() returns empty hashref for empty strategy' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $result = $p->plan({}, {});
	is(scalar keys %{$result}, 0, 'empty strategy -> empty isolation plan');
};

# ==================================================================
# plan — fixture modes from purity level
# ==================================================================
subtest 'plan() assigns "shared_fixture" for purity_level "pure"' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		get_name => { _analysis => { side_effects => { purity_level => 'pure' } } },
	};
	my $result = $p->plan($schema, { get_name => 1 });
	is($result->{get_name}{fixture}, 'shared_fixture',
		'pure -> shared_fixture');
};

subtest 'plan() assigns "fresh_object" for purity_level "self_mutating"' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		set_name => { _analysis => { side_effects => { purity_level => 'self_mutating' } } },
	};
	my $result = $p->plan($schema, { set_name => 1 });
	is($result->{set_name}{fixture}, 'fresh_object',
		'self_mutating -> fresh_object');
};

subtest 'plan() assigns "isolated_block" for unknown purity level' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		write_log => { _analysis => { side_effects => { purity_level => 'impure' } } },
	};
	my $result = $p->plan($schema, { write_log => 1 });
	is($result->{write_log}{fixture}, 'isolated_block',
		'impure -> isolated_block');
};

subtest 'plan() assigns "isolated_block" when purity_level is absent' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $result = $p->plan({ my_method => {} }, { my_method => 1 });
	is($result->{my_method}{fixture}, 'isolated_block',
		'absent purity_level -> isolated_block');
};

subtest 'plan() assigns "isolated_block" when _analysis is absent' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $result = $p->plan({}, { my_method => 1 });
	is($result->{my_method}{fixture}, 'isolated_block',
		'absent _analysis -> isolated_block');
};

# ==================================================================
# plan — dependency keys
# ==================================================================
subtest 'plan() passes through env dependency hashref' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $env    = { HOME => '/home/test', PATH => '/usr/bin' };
	my $schema = {
		foo => { _analysis => { dependencies => { env => $env } } },
	};
	my $result = $p->plan($schema, { foo => 1 });
	is_deeply($result->{foo}{env}, $env, 'env hashref passed through');
};

subtest 'plan() passes through filesystem dependency hashref' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $fs     = { reads => ['/etc/config'], writes => ['/tmp/out'] };
	my $schema = {
		foo => { _analysis => { dependencies => { filesystem => $fs } } },
	};
	my $result = $p->plan($schema, { foo => 1 });
	is_deeply($result->{foo}{filesystem}, $fs, 'filesystem hashref passed through');
};

subtest 'plan() sets time flag to 1 when time dependency present' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		foo => { _analysis => { dependencies => { time => 1 } } },
	};
	my $result = $p->plan($schema, { foo => 1 });
	is($result->{foo}{time}, 1, 'time dependency sets time flag');
};

subtest 'plan() sets network flag to 1 when network dependency present' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		foo => { _analysis => { dependencies => { network => 1 } } },
	};
	my $result = $p->plan($schema, { foo => 1 });
	is($result->{foo}{network}, 1, 'network dependency sets network flag');
};

subtest 'plan() omits env key when no env dependency' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $result = $p->plan({}, { foo => 1 });
	ok(!exists $result->{foo}{env}, 'env key absent when no dependency');
};

subtest 'plan() omits filesystem key when no filesystem dependency' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $result = $p->plan({}, { foo => 1 });
	ok(!exists $result->{foo}{filesystem}, 'filesystem key absent when no dependency');
};

subtest 'plan() omits time key when no time dependency' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $result = $p->plan({}, { foo => 1 });
	ok(!exists $result->{foo}{time}, 'time key absent when no dependency');
};

subtest 'plan() omits network key when no network dependency' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $result = $p->plan({}, { foo => 1 });
	ok(!exists $result->{foo}{network}, 'network key absent when no dependency');
};

# ==================================================================
# plan — strategy keys drive output, not schema keys
# ==================================================================
subtest 'plan() only plans methods present in strategy' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		method_a => { _analysis => { side_effects => { purity_level => 'pure' } } },
		method_b => { _analysis => { side_effects => { purity_level => 'pure' } } },
	};
	my $result = $p->plan($schema, { method_a => 1 });
	ok( exists $result->{method_a}, 'method_a in result (in strategy)');
	ok(!exists $result->{method_b}, 'method_b absent (not in strategy)');
};

# ==================================================================
# plan — multiple methods with mixed dependencies
# ==================================================================
subtest 'plan() handles multiple methods with mixed profiles' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		pure_method => {
			_analysis => {
				side_effects => { purity_level => 'pure' },
				dependencies => {},
			},
		},
		mutating_method => {
			_analysis => {
				side_effects => { purity_level => 'self_mutating' },
				dependencies => { time => 1 },
			},
		},
		impure_method => {
			_analysis => {
				side_effects => { purity_level => 'network_io' },
				dependencies => { network => 1, env => { HOST => 'localhost' } },
			},
		},
	};
	my $result = $p->plan($schema, {
		pure_method    => 1,
		mutating_method => 1,
		impure_method   => 1,
	});

	is($result->{pure_method}{fixture},    'shared_fixture', 'pure -> shared_fixture');
	is($result->{mutating_method}{fixture}, 'fresh_object',  'self_mutating -> fresh_object');
	is($result->{impure_method}{fixture},   'isolated_block','impure -> isolated_block');

	ok(!exists $result->{pure_method}{time},       'pure: no time flag');
	is($result->{mutating_method}{time}, 1,         'mutating: time flag set');
	is($result->{impure_method}{network}, 1,        'impure: network flag set');
	ok(exists $result->{impure_method}{env},        'impure: env present');
};

done_testing();
