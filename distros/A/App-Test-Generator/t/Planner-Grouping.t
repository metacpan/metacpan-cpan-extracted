#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('App::Test::Generator::Planner::Grouping') }

# ==================================================================
# new
# ==================================================================
subtest 'new() returns a blessed object' => sub {
	my $g = App::Test::Generator::Planner::Grouping->new();
	ok(defined $g, 'new() returns defined value');
	isa_ok($g, 'App::Test::Generator::Planner::Grouping');
};

subtest 'new() object is an empty hashref' => sub {
	my $g = new_ok('App::Test::Generator::Planner::Grouping');
	is(scalar keys %{$g}, 0, 'object is an empty hashref');
};

subtest 'new() each call returns a distinct object' => sub {
	my $g1 = App::Test::Generator::Planner::Grouping->new();
	my $g2 = App::Test::Generator::Planner::Grouping->new();
	isnt($g1, $g2, 'each call produces a distinct object');
};

# ==================================================================
# plan — argument validation
# ==================================================================
subtest 'plan() croaks when schema is not a hashref' => sub {
	my $g = App::Test::Generator::Planner::Grouping->new();
	throws_ok(
		sub { $g->plan('not a hashref') },
		qr/schema must be a hashref/,
		'string schema croaks',
	);
	throws_ok(
		sub { $g->plan(undef) },
		qr/schema must be a hashref/,
		'undef schema croaks',
	);
	throws_ok(
		sub { $g->plan([]) },
		qr/schema must be a hashref/,
		'arrayref schema croaks',
	);
};

# ==================================================================
# plan — return structure always has all three keys
# ==================================================================
subtest 'plan() always returns all three group keys' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({});
	is(ref($result), 'HASH', 'returns a hashref');
	ok(exists $result->{pure},     'pure key always present');
	ok(exists $result->{mutating}, 'mutating key always present');
	ok(exists $result->{impure},   'impure key always present');
	is(ref($result->{pure}),     'ARRAY', 'pure value is arrayref');
	is(ref($result->{mutating}), 'ARRAY', 'mutating value is arrayref');
	is(ref($result->{impure}),   'ARRAY', 'impure value is arrayref');
};

subtest 'plan() empty schema returns three empty arrays' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({});
	is(scalar @{$result->{pure}},     0, 'pure is empty for empty schema');
	is(scalar @{$result->{mutating}}, 0, 'mutating is empty for empty schema');
	is(scalar @{$result->{impure}},   0, 'impure is empty for empty schema');
};

# ==================================================================
# plan — pure purity level
# ==================================================================
subtest 'plan() assigns "pure" group for purity_level "pure"' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({
		get_name => { _analysis => { side_effects => { purity_level => 'pure' } } },
	});
	ok((grep { $_ eq 'get_name' } @{$result->{pure}}),
		'pure method in pure group');
	is(scalar @{$result->{mutating}}, 0, 'mutating group empty');
	is(scalar @{$result->{impure}},   0, 'impure group empty');
};

# ==================================================================
# plan — self_mutating maps to mutating
# ==================================================================
subtest 'plan() assigns "mutating" group for purity_level "self_mutating"' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({
		set_name => { _analysis => { side_effects => { purity_level => 'self_mutating' } } },
	});
	ok((grep { $_ eq 'set_name' } @{$result->{mutating}}),
		'self_mutating method in mutating group');
	is(scalar @{$result->{pure}},   0, 'pure group empty');
	is(scalar @{$result->{impure}}, 0, 'impure group empty');
};

# ==================================================================
# plan — unknown/missing purity level falls through to impure
# ==================================================================
subtest 'plan() assigns "impure" group for unknown purity level' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({
		connect => { _analysis => { side_effects => { purity_level => 'network' } } },
	});
	ok((grep { $_ eq 'connect' } @{$result->{impure}}),
		'unknown purity level -> impure group');
};

subtest 'plan() assigns "impure" group when purity_level is absent' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({
		write_file => { _analysis => { side_effects => {} } },
	});
	ok((grep { $_ eq 'write_file' } @{$result->{impure}}),
		'missing purity_level -> impure group');
};

subtest 'plan() assigns "impure" when _analysis is absent' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({ my_method => {} });
	ok((grep { $_ eq 'my_method' } @{$result->{impure}}),
		'absent _analysis -> impure group');
};

# ==================================================================
# plan — multiple methods distributed across groups
# ==================================================================
subtest 'plan() distributes multiple methods across groups correctly' => sub {
	my $g      = App::Test::Generator::Planner::Grouping->new();
	my $result = $g->plan({
		get_name  => { _analysis => { side_effects => { purity_level => 'pure' } } },
		get_value => { _analysis => { side_effects => { purity_level => 'pure' } } },
		set_name  => { _analysis => { side_effects => { purity_level => 'self_mutating' } } },
		write_log => { _analysis => { side_effects => { purity_level => 'impure' } } },
		no_meta   => {},
	});
	is(scalar @{$result->{pure}},     2, 'two pure methods');
	is(scalar @{$result->{mutating}}, 1, 'one mutating method');
	is(scalar @{$result->{impure}},   2, 'two impure methods (one explicit, one missing meta)');
	ok((grep { $_ eq 'get_name'  } @{$result->{pure}}),     'get_name in pure');
	ok((grep { $_ eq 'get_value' } @{$result->{pure}}),     'get_value in pure');
	ok((grep { $_ eq 'set_name'  } @{$result->{mutating}}), 'set_name in mutating');
	ok((grep { $_ eq 'write_log' } @{$result->{impure}}),   'write_log in impure');
	ok((grep { $_ eq 'no_meta'   } @{$result->{impure}}),   'no_meta in impure');
};

# ==================================================================
# plan — total method count is preserved
# ==================================================================
subtest 'plan() total count across groups equals input method count' => sub {
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
	is($total, scalar keys %{$schema}, 'total methods across groups equals input count');
};

done_testing();
