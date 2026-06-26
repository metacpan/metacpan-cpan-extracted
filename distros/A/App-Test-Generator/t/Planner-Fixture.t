#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('App::Test::Generator::Planner::Fixture') }

# ==================================================================
# new
# ==================================================================
subtest 'new() returns a blessed object' => sub {
	my $f = App::Test::Generator::Planner::Fixture->new();
	ok(defined $f, 'new() returns defined value');
	isa_ok($f, 'App::Test::Generator::Planner::Fixture');
};

subtest 'new() takes no arguments' => sub {
	my $f = App::Test::Generator::Planner::Fixture->new();
	is(scalar keys %{$f}, 0, 'object is an empty hashref');
};

subtest 'new() each call returns a distinct object' => sub {
	my $f1 = App::Test::Generator::Planner::Fixture->new();
	my $f2 = App::Test::Generator::Planner::Fixture->new();
	isnt($f1, $f2, 'each call produces a distinct object');
};

# ==================================================================
# plan — argument validation
# ==================================================================
subtest 'plan() croaks when isolation is not a hashref' => sub {
	my $f = App::Test::Generator::Planner::Fixture->new();
	throws_ok(
		sub { $f->plan({}, 'not a hashref') },
		qr/isolation must be a hashref/,
		'string isolation croaks',
	);
	throws_ok(
		sub { $f->plan({}, undef) },
		qr/isolation must be a hashref/,
		'undef isolation croaks',
	);
	throws_ok(
		sub { $f->plan({}, []) },
		qr/isolation must be a hashref/,
		'arrayref isolation croaks',
	);
};

# ==================================================================
# plan — return structure
# ==================================================================
subtest 'plan() returns a hashref' => sub {
	my $f      = App::Test::Generator::Planner::Fixture->new();
	my $result = $f->plan({}, {});
	is(ref($result), 'HASH', 'returns a hashref');
};

subtest 'plan() returns empty hashref for empty isolation' => sub {
	my $f      = App::Test::Generator::Planner::Fixture->new();
	my $result = $f->plan({}, {});
	is(scalar keys %{$result}, 0, 'empty isolation -> empty fixture plan');
};

# ==================================================================
# plan — shared_fixture mode
# ==================================================================
subtest 'plan() assigns "shared" mode for shared_fixture isolation' => sub {
	my $f = App::Test::Generator::Planner::Fixture->new();
	my $result = $f->plan({}, { get_name => { fixture => 'shared_fixture' } });
	ok(exists $result->{get_name}, 'method key present in result');
	is($result->{get_name}{mode}, 'shared', 'shared_fixture -> shared mode');
};

# ==================================================================
# plan — all other isolation modes
#
# Isolation::plan() returns a hashref per method with a 'fixture' key
# (not a bare string), so plan() must read $isolation->{$method}{fixture}.
# ==================================================================
subtest 'plan() assigns "new_per_test" for non-shared_fixture isolation' => sub {
	my $f = App::Test::Generator::Planner::Fixture->new();
	for my $mode (qw(isolated_block fresh_object process_isolated)) {
		my $result = $f->plan({}, { my_method => { fixture => $mode } });
		is($result->{my_method}{mode}, 'new_per_test',
			"'$mode' isolation -> new_per_test mode");
	}
};

subtest 'plan() assigns "new_per_test" for empty string isolation' => sub {
	my $f      = App::Test::Generator::Planner::Fixture->new();
	my $result = $f->plan({}, { foo => { fixture => '' } });
	is($result->{foo}{mode}, 'new_per_test', 'empty string -> new_per_test');
};

subtest 'plan() assigns "new_per_test" when fixture key is absent' => sub {
	my $f      = App::Test::Generator::Planner::Fixture->new();
	my $result = $f->plan({}, { foo => {} });
	is($result->{foo}{mode}, 'new_per_test', 'missing fixture key -> new_per_test');
};

# ==================================================================
# plan — multiple methods
# ==================================================================
subtest 'plan() handles multiple methods independently' => sub {
	my $f = App::Test::Generator::Planner::Fixture->new();
	my $result = $f->plan({}, {
		shared_method   => { fixture => 'shared_fixture' },
		isolated_method => { fixture => 'isolated_block' },
		plain_method    => { fixture => 'fresh_object' },
	});
	is(scalar keys %{$result}, 3, 'all three methods present');
	is($result->{shared_method}{mode},   'shared',       'shared_method -> shared');
	is($result->{isolated_method}{mode}, 'new_per_test', 'isolated_method -> new_per_test');
	is($result->{plain_method}{mode},    'new_per_test', 'plain_method -> new_per_test');
};

# ==================================================================
# plan — schema argument is accepted but unused
# ==================================================================
subtest 'plan() schema argument is accepted and does not affect output' => sub {
	my $f = App::Test::Generator::Planner::Fixture->new();
	my $isolation = { foo => { fixture => 'shared_fixture' } };
	my $result_no_schema   = $f->plan(undef, $isolation);
	my $result_with_schema = $f->plan({ module => 'Foo', input => {} }, $isolation);
	is_deeply($result_no_schema, $result_with_schema,
		'schema content does not affect fixture plan');
};

done_testing();
