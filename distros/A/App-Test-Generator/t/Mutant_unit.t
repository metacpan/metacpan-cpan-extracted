#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

# Black-box unit tests for App::Test::Generator::Mutant.
# Tests each public function according to its POD API specification.
# No mocking required — Mutant has no external dependencies.

BEGIN { use_ok('App::Test::Generator::Mutant') }

# --------------------------------------------------
# Helper: build a minimal valid Mutant
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
# new()
#
# POD spec:
#   Required: id, description, original, line, transform (CODE ref)
#   Optional: type, group
#   Returns:  blessed hashref
#   Croaks:   when any required attribute is missing
#             when transform is not a CODE reference
# ==================================================================

subtest 'new() returns a blessed Mutant object' => sub {
	my $m = _mutant();
	isa_ok($m, 'App::Test::Generator::Mutant');
};

subtest 'new() croaks when id is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Mutant->new(
				description => 'x', original => '>', line => 1,
				transform   => sub { 1 },
			)
		},
		qr/Missing required attribute: id/,
		'missing id croaks',
	);
};

subtest 'new() croaks when description is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Mutant->new(
				id        => 'X', original => '>', line => 1,
				transform => sub { 1 },
			)
		},
		qr/Missing required attribute: description/,
		'missing description croaks',
	);
};

subtest 'new() croaks when original is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Mutant->new(
				id          => 'X', description => 'x', line => 1,
				transform   => sub { 1 },
			)
		},
		qr/Missing required attribute: original/,
		'missing original croaks',
	);
};

subtest 'new() croaks when line is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Mutant->new(
				id          => 'X', description => 'x', original => '>',
				transform   => sub { 1 },
			)
		},
		qr/Missing required attribute: line/,
		'missing line croaks',
	);
};

subtest 'new() croaks when transform is missing' => sub {
	throws_ok(
		sub {
			App::Test::Generator::Mutant->new(
				id => 'X', description => 'x', original => '>', line => 1,
			)
		},
		qr/Missing required attribute: transform/,
		'missing transform croaks',
	);
};

subtest 'new() croaks when transform is not a CODE reference' => sub {
	throws_ok(
		sub { _mutant(transform => 'not_a_coderef') },
		qr/transform must be a CODE reference/,
		'string transform croaks',
	);
	throws_ok(
		sub {
			App::Test::Generator::Mutant->new(
				id          => 'X',
				description => 'x',
				original    => '>',
				line        => 1,
				transform   => undef,
			)
		},
		qr/transform must be a CODE reference/,
		'undef transform croaks',
	);
};

subtest 'new() type and group default to undef when not supplied' => sub {
	my $m = _mutant();
	is($m->type,  undef, 'type defaults to undef');
	is($m->group, undef, 'group defaults to undef');
};

subtest 'new() each call produces a distinct object' => sub {
	my $m1 = _mutant();
	my $m2 = _mutant();
	isnt($m1, $m2, 'distinct objects returned');
};

# ==================================================================
# id()
#
# POD spec:
#   Returns the id string.
#   Read-only — argument is ignored.
# ==================================================================

subtest 'id() returns the stored id' => sub {
	my $m = _mutant(id => 'NUM_BOUNDARY_42_7_!=');
	is($m->id, 'NUM_BOUNDARY_42_7_!=', 'id returned correctly');
};

subtest 'id() is read-only — value unchanged after write attempt' => sub {
	my $m    = _mutant(id => 'ORIGINAL');
	my $orig = $m->id;
	eval { $m->id('CHANGED') };
	is($m->id, $orig, 'id unchanged after write attempt');
};

# ==================================================================
# description()
#
# POD spec:
#   Returns the description string.
# ==================================================================

subtest 'description() returns the stored description' => sub {
	my $m = _mutant(description => 'Flip > to <');
	is($m->description, 'Flip > to <', 'description returned correctly');
};

# ==================================================================
# original()
#
# POD spec:
#   Returns the original source fragment string.
# ==================================================================

subtest 'original() returns the stored original value' => sub {
	my $m = _mutant(original => '>=');
	is($m->original, '>=', 'original returned correctly');
};

subtest 'original() can hold arbitrary Perl code snippets' => sub {
	my $m = _mutant(original => 'return $self->{name}');
	is($m->original, 'return $self->{name}',
		'code snippet stored and returned correctly');
};

# ==================================================================
# line()
#
# POD spec:
#   Returns the line number integer.
# ==================================================================

subtest 'line() returns the stored line number' => sub {
	my $m = _mutant(line => 99);
	is($m->line, 99, 'line number returned correctly');
};

subtest 'line() accepts line number 1' => sub {
	my $m = _mutant(line => 1);
	is($m->line, 1, 'line 1 valid');
};

# ==================================================================
# transform()
#
# POD spec:
#   Returns the CODE reference.
#   The coderef is callable and receives a document argument.
# ==================================================================

subtest 'transform() returns a CODE reference' => sub {
	my $m = _mutant();
	is(ref($m->transform), 'CODE', 'transform returns CODE ref');
};

subtest 'transform() coderef is callable' => sub {
	my $called = 0;
	my $m = _mutant(transform => sub { $called++ });
	$m->transform->();
	is($called, 1, 'transform coderef callable');
};

subtest 'transform() coderef receives its argument correctly' => sub {
	my $received;
	my $sentinel = { marker => 'doc' };
	my $m = _mutant(transform => sub { $received = $_[0] });
	$m->transform->($sentinel);
	is($received, $sentinel, 'argument passed through to transform coderef');
};

# ==================================================================
# type()
#
# POD spec:
#   Returns the optional type string, or undef.
# ==================================================================

subtest 'type() returns the stored type' => sub {
	my $m = _mutant(type => 'comparison');
	is($m->type, 'comparison', 'type returned correctly');
};

subtest 'type() returns undef when not set' => sub {
	my $m = _mutant();
	is($m->type, undef, 'type is undef when not supplied');
};

subtest 'type() accepts various type strings' => sub {
	for my $t (qw(boolean comparison return numeric)) {
		my $m = _mutant(type => $t);
		is($m->type, $t, "type '$t' stored and returned");
	}
};

# ==================================================================
# group()
#
# POD spec:
#   Returns the optional group string, or undef.
# ==================================================================

subtest 'group() returns the stored group' => sub {
	my $m = _mutant(group => 'NUM_BOUNDARY:42');
	is($m->group, 'NUM_BOUNDARY:42', 'group returned correctly');
};

subtest 'group() returns undef when not set' => sub {
	my $m = _mutant();
	is($m->group, undef, 'group is undef when not supplied');
};

subtest 'group() accepts various group format strings' => sub {
	for my $g ('BOOL_NEGATE:10', 'COND_INV:5', 'RETURN_UNDEF:20') {
		my $m = _mutant(group => $g);
		is($m->group, $g, "group '$g' stored and returned");
	}
};

# ==================================================================
# Multiple independent instances
# ==================================================================

subtest 'multiple Mutant instances are independent' => sub {
	my $count_a = 0;
	my $count_b = 0;
	my $a = _mutant(id => 'A', transform => sub { $count_a++ });
	my $b = _mutant(id => 'B', transform => sub { $count_b++ });

	$a->transform->() for 1..3;
	is($count_a, 3, 'a transform called 3 times');
	is($count_b, 0, 'b transform unaffected');

	$b->transform->();
	is($count_b, 1, 'b transform called once');
	is($count_a, 3, 'a count unchanged');
};

done_testing();
