#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

# Black-box unit tests for App::Test::Generator::Planner::Fixture,
# App::Test::Generator::Planner::Grouping, and
# App::Test::Generator::Planner::Isolation.
# Tests each public function according to its POD API specification.
# No mocking required — all three modules are self-contained.

BEGIN {
	use_ok('App::Test::Generator::Planner::Fixture');
	use_ok('App::Test::Generator::Planner::Grouping');
	use_ok('App::Test::Generator::Planner::Isolation');
	use_ok('App::Test::Generator::Planner::Mock');
}

# ==================================================================
# Planner::Fixture
# ==================================================================

subtest 'Fixture::new() returns a blessed object' => sub {
	my $f = App::Test::Generator::Planner::Fixture->new();
	isa_ok($f, 'App::Test::Generator::Planner::Fixture');
};

subtest 'Fixture::new() takes no arguments' => sub {
	lives_ok(
		sub { App::Test::Generator::Planner::Fixture->new() },
		'new() with no arguments lives',
	);
};

subtest 'Fixture::new() each call returns a distinct object' => sub {
	my $f1 = new_ok('App::Test::Generator::Planner::Fixture');
	my $f2 = new_ok('App::Test::Generator::Planner::Fixture');
	isnt($f1, $f2, 'distinct objects returned');
};

subtest 'Fixture::plan() croaks when isolation is not a hashref' => sub {
	my $f = new_ok('App::Test::Generator::Planner::Fixture');
	throws_ok(
		sub { $f->plan({}, undef) },
		qr/isolation must be a hashref/,
		'undef isolation croaks',
	);
	throws_ok(
		sub { $f->plan({}, 'string') },
		qr/isolation must be a hashref/,
		'string isolation croaks',
	);
	throws_ok(
		sub { $f->plan({}, []) },
		qr/isolation must be a hashref/,
		'arrayref isolation croaks',
	);
};

subtest 'Fixture::plan() returns a hashref' => sub {
	my $f      = App::Test::Generator::Planner::Fixture->new();
	my $result = $f->plan({}, {});
	is(ref($result), 'HASH', 'returns hashref');
};

subtest 'Fixture::plan() returns empty hashref for empty isolation' => sub {
	my $f      = App::Test::Generator::Planner::Fixture->new();
	my $result = $f->plan({}, {});
	is(scalar keys %{$result}, 0, 'empty isolation -> empty result');
};

subtest 'Fixture::plan() assigns shared mode for shared_fixture isolation' => sub {
	my $f      = App::Test::Generator::Planner::Fixture->new();
	my $result = $f->plan({}, { get_name => 'shared_fixture' });
	is($result->{get_name}{mode}, 'shared', 'shared_fixture -> shared');
};

subtest 'Fixture::plan() assigns new_per_test for all other isolation modes' => sub {
	my $f = App::Test::Generator::Planner::Fixture->new();
	for my $mode (qw(isolated fresh_object isolated_block none)) {
		my $result = $f->plan({}, { my_method => $mode });
		is($result->{my_method}{mode}, 'new_per_test',
			"'$mode' -> new_per_test");
	}
};

subtest 'Fixture::plan() handles multiple methods' => sub {
	my $f      = App::Test::Generator::Planner::Fixture->new();
	my $result = $f->plan({}, {
		a => 'shared_fixture',
		b => 'isolated',
		c => 'none',
	});
	is(scalar keys %{$result},   3,            'three methods in result');
	is($result->{a}{mode}, 'shared',       'a -> shared');
	is($result->{b}{mode}, 'new_per_test', 'b -> new_per_test');
	is($result->{c}{mode}, 'new_per_test', 'c -> new_per_test');
};

subtest 'Fixture::plan() schema argument is accepted but does not affect output' => sub {
	my $f = App::Test::Generator::Planner::Fixture->new();
	my $isolation = { foo => 'shared_fixture' };
	my $r1 = $f->plan(undef,           $isolation);
	my $r2 = $f->plan({ module => 'X' }, $isolation);
	is_deeply($r1, $r2, 'schema content does not affect fixture plan');
};

# ==================================================================
# Planner::Grouping
# ==================================================================

subtest 'Grouping::new() returns a blessed object' => sub {
	my $g = App::Test::Generator::Planner::Grouping->new();
	isa_ok($g, 'App::Test::Generator::Planner::Grouping');
};

subtest 'Grouping::new() takes no arguments' => sub {
	lives_ok(
		sub { App::Test::Generator::Planner::Grouping->new() },
		'new() with no arguments lives',
	);
};

subtest 'Grouping::plan() croaks when schema is not a hashref' => sub {
	my $g = App::Test::Generator::Planner::Grouping->new();
	throws_ok(
		sub { $g->plan(undef) },
		qr/schema must be a hashref/,
		'undef schema croaks',
	);
	throws_ok(
		sub { $g->plan('string') },
		qr/schema must be a hashref/,
		'string schema croaks',
	);
	throws_ok(
		sub { $g->plan([]) },
		qr/schema must be a hashref/,
		'arrayref schema croaks',
	);
};

subtest 'Grouping::plan() always returns all three group keys' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({});
	is(ref($result), 'HASH', 'returns hashref');
	for my $key (qw(pure mutating impure)) {
		ok(exists $result->{$key},      "$key key present");
		is(ref($result->{$key}), 'ARRAY', "$key value is arrayref");
	}
};

subtest 'Grouping::plan() empty schema returns three empty arrays' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({});
	is(scalar @{$result->{pure}},     0, 'pure empty');
	is(scalar @{$result->{mutating}}, 0, 'mutating empty');
	is(scalar @{$result->{impure}},   0, 'impure empty');
};

subtest 'Grouping::plan() pure purity_level -> pure group' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({
		get_name => { _analysis => { side_effects => { purity_level => 'pure' } } },
	});
	ok((grep { $_ eq 'get_name' } @{$result->{pure}}),
		'pure method in pure group');
	is(scalar @{$result->{mutating}}, 0, 'mutating empty');
	is(scalar @{$result->{impure}},   0, 'impure empty');
};

subtest 'Grouping::plan() self_mutating purity_level -> mutating group' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({
		set_name => { _analysis => { side_effects => { purity_level => 'self_mutating' } } },
	});
	ok((grep { $_ eq 'set_name' } @{$result->{mutating}}),
		'self_mutating method in mutating group');
};

subtest 'Grouping::plan() missing purity_level -> impure group' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({ my_method => {} });
	ok((grep { $_ eq 'my_method' } @{$result->{impure}}),
		'method with no metadata -> impure');
};

subtest 'Grouping::plan() unknown purity_level -> impure group' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({
		net_call => { _analysis => { side_effects => { purity_level => 'network' } } },
	});
	ok((grep { $_ eq 'net_call' } @{$result->{impure}}),
		'unknown purity level -> impure');
};

subtest 'Grouping::plan() total count equals input method count' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $schema = {
		a => { _analysis => { side_effects => { purity_level => 'pure' } } },
		b => { _analysis => { side_effects => { purity_level => 'self_mutating' } } },
		c => {},
		d => { _analysis => { side_effects => { purity_level => 'pure' } } },
	};
	my $result = $g->plan($schema);
	my $total  = scalar(@{$result->{pure}}) +
	             scalar(@{$result->{mutating}}) +
	             scalar(@{$result->{impure}});
	is($total, scalar keys %{$schema}, 'total equals input count');
};

# ==================================================================
# Planner::Isolation
# ==================================================================

subtest 'Isolation::new() returns a blessed object' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new();
	isa_ok($p, 'App::Test::Generator::Planner::Isolation');
};

subtest 'Isolation::new() takes no arguments' => sub {
	lives_ok(
		sub { App::Test::Generator::Planner::Isolation->new() },
		'new() with no arguments lives',
	);
};

subtest 'Isolation::plan() croaks when strategy is not a hashref' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new();
	throws_ok(
		sub { $p->plan({}, undef) },
		qr/strategy must be a hashref/,
		'undef strategy croaks',
	);
	throws_ok(
		sub { $p->plan({}, 'string') },
		qr/strategy must be a hashref/,
		'string strategy croaks',
	);
	throws_ok(
		sub { $p->plan({}, []) },
		qr/strategy must be a hashref/,
		'arrayref strategy croaks',
	);
};

subtest 'Isolation::plan() returns a hashref' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new();
	is(ref($p->plan({}, {})), 'HASH', 'returns hashref');
};

subtest 'Isolation::plan() returns empty hashref for empty strategy' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new();
	is(scalar keys %{$p->plan({}, {})}, 0, 'empty strategy -> empty result');
};

subtest 'Isolation::plan() pure purity_level -> shared_fixture' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		get_name => { _analysis => { side_effects => { purity_level => 'pure' } } },
	};
	my $result = $p->plan($schema, { get_name => 1 });
	is($result->{get_name}{fixture}, 'shared_fixture', 'pure -> shared_fixture');
};

subtest 'Isolation::plan() self_mutating -> fresh_object' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		set_name => { _analysis => { side_effects => { purity_level => 'self_mutating' } } },
	};
	my $result = $p->plan($schema, { set_name => 1 });
	is($result->{set_name}{fixture}, 'fresh_object', 'self_mutating -> fresh_object');
};

subtest 'Isolation::plan() missing purity_level -> isolated_block' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $result = $p->plan({}, { my_method => 1 });
	is($result->{my_method}{fixture}, 'isolated_block',
		'missing purity_level -> isolated_block');
};

subtest 'Isolation::plan() unknown purity_level -> isolated_block' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		net => { _analysis => { side_effects => { purity_level => 'network' } } },
	};
	my $result = $p->plan($schema, { net => 1 });
	is($result->{net}{fixture}, 'isolated_block', 'unknown -> isolated_block');
};

subtest 'Isolation::plan() env dependency passed through' => sub {
	my $p   = App::Test::Generator::Planner::Isolation->new();
	my $env = { HOME => '/tmp' };
	my $schema = {
		foo => { _analysis => { dependencies => { env => $env } } },
	};
	my $result = $p->plan($schema, { foo => 1 });
	is_deeply($result->{foo}{env}, $env, 'env hashref passed through');
};

subtest 'Isolation::plan() filesystem dependency passed through' => sub {
	my $p  = App::Test::Generator::Planner::Isolation->new();
	my $fs = { reads => ['/etc/hosts'] };
	my $schema = {
		foo => { _analysis => { dependencies => { filesystem => $fs } } },
	};
	my $result = $p->plan($schema, { foo => 1 });
	is_deeply($result->{foo}{filesystem}, $fs, 'filesystem hashref passed through');
};

subtest 'Isolation::plan() time dependency sets time flag to 1' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		foo => { _analysis => { dependencies => { time => 1 } } },
	};
	my $result = $p->plan($schema, { foo => 1 });
	is($result->{foo}{time}, 1, 'time flag set');
};

subtest 'Isolation::plan() network dependency sets network flag to 1' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $schema = {
		foo => { _analysis => { dependencies => { network => 1 } } },
	};
	my $result = $p->plan($schema, { foo => 1 });
	is($result->{foo}{network}, 1, 'network flag set');
};

subtest 'Isolation::plan() omits optional keys when dependencies absent' => sub {
	my $p      = App::Test::Generator::Planner::Isolation->new();
	my $result = $p->plan({}, { foo => 1 });
	ok(!exists $result->{foo}{env},        'env absent when no dependency');
	ok(!exists $result->{foo}{filesystem}, 'filesystem absent when no dependency');
	ok(!exists $result->{foo}{time},       'time absent when no dependency');
	ok(!exists $result->{foo}{network},    'network absent when no dependency');
};

subtest 'Isolation::plan() only plans methods present in strategy' => sub {
	my $p = new_ok('App::Test::Generator::Planner::Isolation');
	my $schema = {
		in_strategy  => { _analysis => { side_effects => { purity_level => 'pure' } } },
		not_strategy => { _analysis => { side_effects => { purity_level => 'pure' } } },
	};
	my $result = $p->plan($schema, { in_strategy => 1 });
	ok( exists $result->{in_strategy},  'in_strategy present');
	ok(!exists $result->{not_strategy}, 'not_strategy absent');
};

subtest 'Mock::plan() returns a hashref' => sub {
	my $p = App::Test::Generator::Planner::Mock->new;
	my $result = $p->plan({});
	is(ref($result), 'HASH', 'plan() returns a hashref not undef');
};

subtest 'Mock::plan() assigns mock_system for calls_external' => sub {
	my $p = App::Test::Generator::Planner::Mock->new;
	my $result = $p->plan({
		my_method => { _analysis => { side_effects => { calls_external => 1 } } }
	});
	is($result->{my_method}, 'mock_system',
		'calls_external -> exactly mock_system');
};

subtest 'Mock::plan() assigns capture_io for performs_io' => sub {
	my $p = App::Test::Generator::Planner::Mock->new;
	my $result = $p->plan({
		my_method => { _analysis => { side_effects => { performs_io => 1 } } }
	});
	is($result->{my_method}, 'capture_io', 'performs_io -> exactly capture_io');
};

subtest 'Mock::plan() mock_system takes precedence over capture_io' => sub {
	my $p = App::Test::Generator::Planner::Mock->new;
	my $result = $p->plan({
		my_method => { _analysis => { side_effects => {
			calls_external => 1,
			performs_io    => 1,
		} } }
	});
	is($result->{my_method}, 'mock_system',
		'mock_system takes precedence when both present');
};

subtest 'Mock::plan() omits pure methods from result' => sub {
	my $p = App::Test::Generator::Planner::Mock->new;
	my $result = $p->plan({
		pure_method => { _analysis => { side_effects => {} } }
	});
	ok(!exists $result->{pure_method}, 'pure method omitted from plan');
};

subtest 'Mock::plan() return value is defined for non-empty schema' => sub {
	my $p = App::Test::Generator::Planner::Mock->new;
	my $result = $p->plan({
		m => { _analysis => { side_effects => { calls_external => 1 } } }
	});
	ok(defined $result, 'return value is defined');
	is(ref($result), 'HASH', 'return value is a hashref not undef');
};

done_testing();
