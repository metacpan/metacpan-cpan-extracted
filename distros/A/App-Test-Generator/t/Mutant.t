#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN {
	use_ok('App::Test::Generator::Mutant');
}

# --------------------------------------------------
# Helper: build a minimal valid Mutant object
# --------------------------------------------------
sub _mutant {
	my (%args) = @_;
	return App::Test::Generator::Mutant->new(
		id          => $args{id}          // 'TEST_1_1_x',
		description => $args{description} // 'Test mutation',
		original    => $args{original}    // '>',
		line        => $args{line}        // 10,
		transform   => $args{transform}   // sub { 1 },
		exists $args{type}  ? (type  => $args{type})  : (),
		exists $args{group} ? (group => $args{group}) : (),
	);
}

# ==================================================================
# new -- required attribute validation
# ==================================================================
subtest 'new: required attribute validation' => sub {
	# Each required attribute must croak when missing
	for my $attr (qw(id description original line transform)) {
		my %args = (
			id          => 'TEST_1_1_x',
			description => 'Test mutation',
			original    => '>',
			line        => 10,
			transform   => sub { 1 },
		);
		delete $args{$attr};

		throws_ok {
			App::Test::Generator::Mutant->new(%args)
		} qr/Missing required attribute: $attr/,
			"missing $attr croaks with correct message";
	}
};

# ==================================================================
# new -- transform must be a CODE reference
# ==================================================================
subtest 'new: transform must be a CODE reference' => sub {
	# String instead of coderef
	throws_ok {
		App::Test::Generator::Mutant->new(
			id          => 'TEST_1_1_x',
			description => 'Test mutation',
			original    => '>',
			line        => 10,
			transform   => 'not a coderef',
		)
	} qr/transform must be a CODE reference/,
		'string transform croaks';

	# Undef instead of coderef
	throws_ok {
		App::Test::Generator::Mutant->new(
			id          => 'TEST_1_1_x',
			description => 'Test mutation',
			original    => '>',
			line        => 10,
			transform   => undef,
		)
	} qr/transform must be a CODE reference/,
		'undef transform croaks';

	# Arrayref instead of coderef
	throws_ok {
		App::Test::Generator::Mutant->new(
			id          => 'TEST_1_1_x',
			description => 'Test mutation',
			original    => '>',
			line        => 10,
			transform   => [],
		)
	} qr/transform must be a CODE reference/,
		'arrayref transform croaks';
};

# ==================================================================
# new -- valid construction
# ==================================================================
subtest 'new: valid construction' => sub {
	my $m = _mutant();
	ok(defined $m, 'new() returns defined value');
	isa_ok($m, 'App::Test::Generator::Mutant');
	is(ref($m), 'App::Test::Generator::Mutant', 'blessed into correct class');

	# Each call produces a distinct object
	my $m2 = _mutant();
	isnt($m, $m2, 'each call produces a distinct object');
};

# ==================================================================
# new -- optional attributes default to undef
# ==================================================================
subtest 'new: optional attributes default to undef' => sub {
	# Construct without optional type and group
	my $m = App::Test::Generator::Mutant->new(
		id          => 'TEST_1_1_x',
		description => 'Test mutation',
		original    => '>',
		line        => 10,
		transform   => sub { 1 },
	);

	is($m->type,  undef, 'type defaults to undef when not provided');
	is($m->group, undef, 'group defaults to undef when not provided');
};

# ==================================================================
# id accessor
# ==================================================================
subtest 'id accessor' => sub {
	my $m = _mutant(id => 'NUM_BOUNDARY_42_7_!=');
	is($m->id, 'NUM_BOUNDARY_42_7_!=', 'id returns correct value');

	# Read-only — passing an argument should either be silently ignored
	# or croak; it must not change the value
	my $orig = $m->id();
	eval { $m->id('other') };
	is($m->id(), $orig, 'id value unchanged after attempted write');
};

# ==================================================================
# description accessor
# ==================================================================
subtest 'description accessor' => sub {
	my $m = _mutant(description => 'Flip > to <');
	is($m->description, 'Flip > to <', 'description returns correct value');
};

# ==================================================================
# original accessor
# ==================================================================
subtest 'original accessor' => sub {
	my $m = _mutant(original => '>=');
	is($m->original, '>=', 'original returns correct value');

	# Can hold arbitrary strings including Perl code snippets
	$m = _mutant(original => 'return $self->{name}');
	is($m->original, 'return $self->{name}', 'original can hold code snippet');
};

# ==================================================================
# line accessor
# ==================================================================
subtest 'line accessor' => sub {
	my $m = _mutant(line => 99);
	is($m->line, 99, 'line returns correct value');

	# Line 1 is valid
	$m = _mutant(line => 1);
	is($m->line, 1, 'line 1 is valid');
};

# ==================================================================
# transform accessor
# ==================================================================
subtest 'transform accessor' => sub {
	my $called = 0;
	my $xform  = sub { $called++ };

	my $m = _mutant(transform => $xform);

	# Returns a coderef
	is(ref($m->transform), 'CODE', 'transform returns a CODE reference');

	# The returned coderef is callable and executes correctly
	$m->transform->();
	is($called, 1, 'transform coderef is callable and executes');

	# Calling again increments the counter
	$m->transform->();
	is($called, 2, 'transform coderef can be called multiple times');
};

# ==================================================================
# type accessor -- optional
# ==================================================================
subtest 'type accessor' => sub {
	# With type provided
	my $m = _mutant(type => 'comparison');
	is($m->type, 'comparison', 'type returns correct value');

	# With different type values
	$m = _mutant(type => 'boolean');
	is($m->type, 'boolean', 'type returns boolean');

	$m = _mutant(type => 'return');
	is($m->type, 'return', 'type returns return');

	# Without type -- returns undef
	$m = App::Test::Generator::Mutant->new(
		id          => 'TEST_1_1_x',
		description => 'Test',
		original    => '>',
		line        => 1,
		transform   => sub { 1 },
	);
	is($m->type, undef, 'type returns undef when not set');
};

# ==================================================================
# group accessor -- optional
# ==================================================================
subtest 'group accessor' => sub {
	# With group provided
	my $m = _mutant(group => 'NUM_BOUNDARY:42');
	is($m->group, 'NUM_BOUNDARY:42', 'group returns correct value');

	# With different group formats
	$m = _mutant(group => 'BOOL_NEGATE:10');
	is($m->group, 'BOOL_NEGATE:10', 'group returns BOOL_NEGATE format');

	$m = _mutant(group => 'COND_INV:5');
	is($m->group, 'COND_INV:5', 'group returns COND_INV format');

	# Without group -- returns undef
	$m = App::Test::Generator::Mutant->new(
		id          => 'TEST_1_1_x',
		description => 'Test',
		original    => '>',
		line        => 1,
		transform   => sub { 1 },
	);
	is($m->group, undef, 'group returns undef when not set');
};

# ==================================================================
# transform receives and modifies its argument
# ==================================================================
subtest 'transform receives document argument correctly' => sub {
	# Verify that the transform closure receives its argument
	my $received;
	my $sentinel = { marker => 'test_document' };

	my $m = _mutant(
		transform => sub { $received = $_[0] }
	);

	$m->transform->($sentinel);
	is($received, $sentinel, 'transform receives its argument correctly');
};

# ==================================================================
# multiple mutants are independent
# ==================================================================
subtest 'multiple mutants are independent' => sub {
	my $count_a = 0;
	my $count_b = 0;

	my $a = _mutant(
		id        => 'A_1_1_x',
		transform => sub { $count_a++ },
	);
	my $b = _mutant(
		id        => 'B_1_1_x',
		transform => sub { $count_b++ },
	);

	# Calling a's transform does not affect b's state
	$a->transform->();
	$a->transform->();
	is($count_a, 2, 'a transform called twice');
	is($count_b, 0, 'b transform unaffected by calling a');

	$b->transform->();
	is($count_b, 1, 'b transform called once');
	is($count_a, 2, 'a transform count unchanged after calling b');
};

# ==================================================================
# extra attributes are stored and accessible via hashref
# ==================================================================
subtest 'extra attributes passed to new are stored' => sub {
	# The constructor blesses \%args directly so extra attributes
	# are accessible as hashref keys — used by mutation modules
	# that store difficulty, hint, priority etc.
	my $m = App::Test::Generator::Mutant->new(
		id          => 'TEST_1_1_x',
		description => 'Test',
		original    => '>',
		line        => 1,
		transform   => sub { 1 },
		difficulty  => 'HIGH',
		hint        => 'Add boundary test',
		priority    => 3,
	);

	is($m->{difficulty}, 'HIGH',              'difficulty stored in hashref');
	is($m->{hint},       'Add boundary test', 'hint stored in hashref');
	is($m->{priority},   3,                   'priority stored in hashref');
};

done_testing();
