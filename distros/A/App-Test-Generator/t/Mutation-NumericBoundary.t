#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use PPI;
use Readonly;

BEGIN {
	use_ok('App::Test::Generator::Mutation::NumericBoundary');
	use_ok('App::Test::Generator::Mutant');
}

# --------------------------------------------------
# Helper: parse a Perl source string into a PPI doc
# --------------------------------------------------
sub _doc {
	my ($source) = @_;
	return PPI::Document->new(\$source);
}

# --------------------------------------------------
# Helper: build a fresh NumericBoundary instance
# --------------------------------------------------
sub _mutation {
	return App::Test::Generator::Mutation::NumericBoundary->new();
}

# --------------------------------------------------
# Constants: expected flip targets per operator,
# matching the %FLIP hash in the module under test.
# Changes to the flip table will cause deliberate
# test failures here.
# --------------------------------------------------
Readonly my %EXPECTED_FLIPS => (
	'>'  => [ '<', '>=', '<=' ],
	'<'  => [ '>', '<=', '>=' ],
	'>=' => [ '>', '<',  '<=' ],
	'<=' => [ '<', '>',  '>=' ],
	'==' => [ '!=' ],
	'!=' => [ '==' ],
);

# ==================================================================
# new and inheritance
# ==================================================================
subtest 'new and inheritance' => sub {
	my $m = _mutation();
	ok(defined $m, 'new() returns defined value');
	isa_ok($m, 'App::Test::Generator::Mutation::NumericBoundary');
	isa_ok($m, 'App::Test::Generator::Mutation::Base', 'inherits from Base');
};

# ==================================================================
# mutate -- empty document
# ==================================================================
subtest 'mutate: empty document' => sub {
	my $m   = _mutation();
	my $doc = _doc('package Foo; 1;');

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'no mutants for document with no operators');
};

# ==================================================================
# mutate -- flip counts per operator
# --------------------------------------------------
# Each operator must produce exactly the number of
# mutants matching its %FLIP entry
# ==================================================================
subtest 'mutate: correct flip count per operator' => sub {
	my $m = _mutation();

	# > produces 3 flips: <, >=, <=
	my @mutants = $m->mutate(_doc('sub foo { if($x > 0) { 1; } }'));
	is(scalar @mutants, 3, '> produces 3 mutants');

	# < produces 3 flips: >, <=, >=
	@mutants = $m->mutate(_doc('sub foo { if($x < 0) { 1; } }'));
	is(scalar @mutants, 3, '< produces 3 mutants');

	# >= produces 3 flips: >, <, <=
	@mutants = $m->mutate(_doc('sub foo { if($x >= 0) { 1; } }'));
	is(scalar @mutants, 3, '>= produces 3 mutants');

	# <= produces 3 flips: <, >, >=
	@mutants = $m->mutate(_doc('sub foo { if($x <= 0) { 1; } }'));
	is(scalar @mutants, 3, '<= produces 3 mutants');

	# == produces 1 flip: !=
	@mutants = $m->mutate(_doc('sub foo { if($x == 0) { 1; } }'));
	is(scalar @mutants, 1, '== produces 1 mutant');

	# != produces 1 flip: ==
	@mutants = $m->mutate(_doc('sub foo { if($x != 0) { 1; } }'));
	is(scalar @mutants, 1, '!= produces 1 mutant');
};

# ==================================================================
# mutate -- flip targets are correct
# ==================================================================
subtest 'mutate: flip targets are correct' => sub {
	my $m = _mutation();

	for my $op (sort keys %EXPECTED_FLIPS) {
		# Build a simple source containing just this operator
		my $src = "sub foo { if(\$x $op 0) { 1; } }";
		my @mutants = $m->mutate(_doc($src));

		my @expected = @{ $EXPECTED_FLIPS{$op} };
		is(scalar @mutants, scalar @expected,
			"$op produces correct number of mutants");

		# Collect the flip targets from the mutant descriptions
		my @got_targets = map { $_->description =~ /to (\S+)$/; $1 } @mutants;
		my %got_set  = map { $_ => 1 } @got_targets;
		my %exp_set  = map { $_ => 1 } @expected;

		for my $t (@expected) {
			ok($got_set{$t}, "$op flip to $t is present");
		}
	}
};

# ==================================================================
# mutate -- mutant metadata
# ==================================================================
subtest 'mutate: mutant metadata is correct' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { if($x > 0) { return 1; } }');

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 3, 'three mutants for > operator');

	for my $mut (@mutants) {
		isa_ok($mut, 'App::Test::Generator::Mutant');

		# ID format: NUM_BOUNDARY_line_col_flipoperator
		like($mut->id, qr/^NUM_BOUNDARY_\d+_\d+_\S+$/,
			'mutant ID has correct format');

		# Description mentions the flip
		like($mut->description, qr/^Numeric boundary flip > to /,
			'description mentions the flip');

		# Type is comparison
		is($mut->type, 'comparison', 'mutant type is comparison');

		# Original is the source operator
		is($mut->original, '>', 'original is >');

		# Line number is positive
		ok($mut->line > 0, 'line number is positive');

		# Transform is a coderef
		is(ref($mut->transform), 'CODE', 'transform is a coderef');

		# Group format: NUM_BOUNDARY:line
		like($mut->group, qr/^NUM_BOUNDARY:\d+$/,
			'group has correct format');
	}
};

# ==================================================================
# mutate -- all flip IDs are unique
# ==================================================================
subtest 'mutate: all mutant IDs are unique' => sub {
	my $m   = _mutation();
	my $doc = _doc(<<'CODE');
sub check {
	my ($x, $y) = @_;
	return 1 if $x > 0;
	return 2 if $y < 10;
	return 3 if $x == $y;
}
CODE

	my @mutants = $m->mutate($doc);
	ok(scalar @mutants > 0, 'some mutants produced');

	my %ids = map { $_->id => 1 } @mutants;
	is(scalar keys %ids, scalar @mutants, 'all mutant IDs are unique');
};

# ==================================================================
# mutate -- readline operator is skipped
# --------------------------------------------------
# < immediately followed by a symbol token ($fh) is
# a readline, not a numeric comparison -- must be skipped
# ==================================================================
subtest 'mutate: readline operator is skipped' => sub {
	my $m = _mutation();

	# Readline <$fh> -- the < must not produce mutants
	my @mutants = $m->mutate(_doc('sub foo { my $line = <$fh>; }'));
	is(scalar @mutants, 0, 'readline <$fh> produces no mutants');

	# Regular < comparison still works
	@mutants = $m->mutate(_doc('sub foo { if($x < 10) { 1; } }'));
	is(scalar @mutants, 3, 'regular < comparison still produces mutants');
};

# ==================================================================
# mutate -- transform applies flip correctly
# ==================================================================
subtest 'mutate: transform applies flip correctly' => sub {
	my $m   = _mutation();
	my $src = 'sub foo { if($x > 0) { return 1; } }';
	my $doc = _doc($src);

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 3, 'three mutants for > operator');

	# Verify each flip target appears in the transformed source
	my %seen_flips;
	for my $mut (@mutants) {
		my $copy = _doc($src);
		$mut->transform->($copy);
		my $transformed = $copy->serialize;

		# Extract the flip target from the ID
		my ($flip) = $mut->id =~ /NUM_BOUNDARY_\d+_\d+_(\S+)$/;
		$seen_flips{$flip} = 1;

		# The transformed source must contain the flip operator
		like($transformed, qr/\Q$flip\E/,
			"transform inserts $flip into source");

		# The original > must be gone (replaced by flip)
		# Note: >= and <= contain > or < so use word boundary where possible
		unlike($transformed, qr/(?<![=!<>])>(?![=])/,
			"transform removes bare > from source")
			if $flip ne '>=' && $flip ne '<=';
	}

	# All three flip targets must have been seen
	is(scalar keys %seen_flips, 3, 'all three flip targets were applied');
};

# ==================================================================
# mutate -- transform targets correct operator by line and col
# ==================================================================
subtest 'mutate: transform targets correct operator' => sub {
	my $m   = _mutation();
	my $src = <<'CODE';
sub check {
	return 1 if $a > 0;
	return 2 if $b > 0;
}
CODE

	my $doc     = _doc($src);
	my @mutants = $m->mutate($doc);

	# Two > operators, each producing 3 mutants = 6 total
	is(scalar @mutants, 6, 'two > operators produce 6 mutants');

	# The mutants must have two distinct line numbers
	my %lines = map { $_->line => 1 } @mutants;
	is(scalar keys %lines, 2, 'mutants span two distinct lines');
};

# ==================================================================
# mutate -- transform does not modify original document
# ==================================================================
subtest 'mutate: transform does not modify original document' => sub {
	my $m   = _mutation();
	my $src = 'sub foo { if($x >= 0) { return 1; } }';
	my $doc = _doc($src);

	my @mutants = $m->mutate($doc);
	my $before  = $doc->serialize;

	# Apply all transforms to separate copies
	for my $mut (@mutants) {
		my $copy = _doc($src);
		$mut->transform->($copy);
	}

	# Original must be unchanged
	is($doc->serialize, $before,
		'original document not modified by any transform');
};

# ==================================================================
# mutate -- multiple operators on the same line produce unique IDs
# ==================================================================
subtest 'mutate: multiple operators on same line have unique IDs' => sub {
	my $m   = _mutation();

	# Two operators on the same line -- IDs must differ by column
	my $doc = _doc('sub foo { if($a > 0 && $b < 10) { 1; } }');
	my @mutants = $m->mutate($doc);

	# > produces 3 and < produces 3 = 6 total
	is(scalar @mutants, 6, 'two operators on same line produce 6 mutants');

	my %ids = map { $_->id => 1 } @mutants;
	is(scalar keys %ids, 6, 'all IDs are unique despite same line');
};

# ==================================================================
# mutate -- group contains same line as ID
# ==================================================================
subtest 'mutate: group line matches ID line' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { if($x > 0) { 1; } }');

	my @mutants = $m->mutate($doc);

	for my $mut (@mutants) {
		my ($id_line)    = $mut->id    =~ /NUM_BOUNDARY_(\d+)/;
		my ($group_line) = $mut->group =~ /NUM_BOUNDARY:(\d+)/;
		is($id_line, $group_line,
			"group line matches ID line for mutant ${\$mut->id}");
		is($mut->line, $id_line,
			"line() matches ID line for mutant ${\$mut->id}");
	}
};

# ==================================================================
# mutate -- flip table constant values
# ==================================================================
subtest 'flip table has correct entries' => sub {
	# Verify the expected flip table matches module behaviour
	# by checking that each operator produces the right targets
	my $m = _mutation();

	for my $op (sort keys %EXPECTED_FLIPS) {
		my $src     = "sub foo { if(\$x $op 0) { 1; } }";
		my @mutants = $m->mutate(_doc($src));
		my @targets = sort map { my ($t) = $_->description =~ /to (\S+)$/; $t }
			@mutants;
		my @expected = sort @{ $EXPECTED_FLIPS{$op} };
		is_deeply(\@targets, \@expected,
			"flip targets for $op are correct");
	}
};

# ==================================================================
# mutate -- returns a list (current API)
# ==================================================================
subtest 'mutate: returns a list' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { if($x > 0 && $y == 1) { 1; } }');

	# > gives 3, == gives 1 = 4 total
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 4, 'mutate returns flat list assignable to array');

	# TODO: API should return arrayref for efficiency -- same change
	# needed across all Mutation::* subclasses simultaneously
};

# ==================================================================
# applies_to() — new function
# ==================================================================

subtest 'applies_to() returns 1 for document containing > operator' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::NumericBoundary->new();
	my $doc = PPI::Document->new(\'sub foo { if($x > 0) { return 1; } }');
	is($m->applies_to($doc), 1, '> operator -> applies_to returns 1');
};

subtest 'applies_to() returns 1 for document containing == operator' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::NumericBoundary->new();
	my $doc = PPI::Document->new(\'sub foo { return 1 if $x == 0; }');
	is($m->applies_to($doc), 1, '== operator -> applies_to returns 1');
};

subtest 'applies_to() returns 1 for document containing >= operator' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::NumericBoundary->new();
	my $doc = PPI::Document->new(\'sub foo { die unless $n >= 1; }');
	is($m->applies_to($doc), 1, '>= operator -> applies_to returns 1');
};

subtest 'applies_to() returns 0 for document with no comparison operators' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::NumericBoundary->new();
	my $doc = PPI::Document->new(\'sub foo { return $x + $y; }');
	is($m->applies_to($doc), 0, 'no comparison operators -> applies_to returns 0');
};

subtest 'applies_to() returns 0 for empty document' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::NumericBoundary->new();
	my $doc = PPI::Document->new(\' ');
	is($m->applies_to($doc), 0, 'empty document -> applies_to returns 0');
};

subtest 'applies_to() returns 0 for readline < operator' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::NumericBoundary->new();
	# <$fh> is a readline, not a comparison — should be ignored
	my $doc = PPI::Document->new(\'sub foo { my $line = <$fh>; }');
	is($m->applies_to($doc), 0, 'readline < not treated as comparison operator');
};

done_testing();
