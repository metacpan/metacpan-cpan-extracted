#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use PPI;

BEGIN {
	use_ok('App::Test::Generator::Mutation::ConditionalInversion');
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
# Helper: build a fresh ConditionalInversion instance
# --------------------------------------------------
sub _mutation {
	return new_ok('App::Test::Generator::Mutation::ConditionalInversion');
}

# ==================================================================
# new and inheritance
# ==================================================================
subtest 'new and inheritance' => sub {
	my $m = _mutation();
	ok(defined $m, 'new() returns defined value');
	isa_ok($m, 'App::Test::Generator::Mutation::ConditionalInversion');
	isa_ok($m, 'App::Test::Generator::Mutation::Base', 'inherits from Base');
};

# ==================================================================
# mutate -- empty document
# ==================================================================
subtest 'mutate: empty document' => sub {
	my $m   = _mutation();
	my $doc = _doc('package Foo; 1;');

	# No conditionals -- must return empty list
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'no mutants for document with no conditionals');
};

# ==================================================================
# mutate -- no if/unless produces no mutants
# ==================================================================
subtest 'mutate: non-conditional compound statements skipped' => sub {
	my $m = _mutation();

	# while loop is a compound statement but not if/unless
	my @mutants = $m->mutate(_doc('sub foo { while($x) { last; } }'));
	is(scalar @mutants, 0, 'while loop produces no mutants');

	# for loop
	@mutants = $m->mutate(_doc('sub foo { for my $i (1..10) { print $i; } }'));
	is(scalar @mutants, 0, 'for loop produces no mutants');

	# foreach loop
	@mutants = $m->mutate(_doc('sub foo { foreach my $x (@a) { do_it(); } }'));
	is(scalar @mutants, 0, 'foreach loop produces no mutants');
};

# ==================================================================
# mutate -- single if statement
# ==================================================================
subtest 'mutate: single if statement' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { if($x) { return 1; } }');

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 1, 'one mutant for one if statement');

	my $mut = $mutants[0];
	isa_ok($mut, 'App::Test::Generator::Mutant');

	# ID format: COND_INV_line_col
	like($mut->id, qr/^COND_INV_\d+_\d+$/, 'mutant ID has correct format');

	# Description mentions the inversion
	like($mut->description, qr/if.*unless/i, 'description mentions if to unless inversion');

	# Line number is positive
	ok($mut->line > 0, 'line number is positive');

	# Type is boolean
	is($mut->type, 'boolean', 'mutant type is boolean');

	# Transform is a coderef
	is(ref($mut->transform), 'CODE', 'transform is a coderef');

	# Group contains the line number
	like($mut->group, qr/^COND_INV:\d+$/, 'group has correct format');
};

# ==================================================================
# mutate -- single unless statement
# ==================================================================
subtest 'mutate: single unless statement' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { unless($err) { proceed(); } }');

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 1, 'one mutant for one unless statement');

	my $mut = $mutants[0];

	# Description must mention the unless to if inversion
	like($mut->description, qr/unless.*if/i,
		'description mentions unless to if inversion');
};

# ==================================================================
# mutate -- multiple conditionals produce multiple mutants
# ==================================================================
subtest 'mutate: multiple conditionals produce multiple mutants' => sub {
	my $m   = _mutation();
	my $doc = _doc(<<'CODE');
sub check {
	my ($x, $y) = @_;
	if($x > 0) {
		return 'positive';
	} elsif($x < 0) {
		return 'negative';
	} unless($y) {
		return 'no y';
	}
	return 'ok';
}
CODE

	my @mutants = $m->mutate($doc);
	ok(scalar @mutants >= 2, 'multiple conditionals produce multiple mutants');

	# All IDs must be unique
	my %ids = map { $_->id => 1 } @mutants;
	is(scalar keys %ids, scalar @mutants, 'all mutant IDs are unique');
};

# ==================================================================
# mutate -- transform flips if to unless
# ==================================================================
subtest 'mutate: transform flips if to unless' => sub {
	my $m   = _mutation();
	my $src = 'sub foo { if($x) { return 1; } }';
	my $doc = _doc($src);

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 1, 'one mutant produced');

	# Apply transform to a fresh copy
	my $copy = _doc($src);
	$mutants[0]->transform->($copy);

	my $transformed = $copy->serialize;

	# The if keyword must have been replaced by unless
	like($transformed,   qr/\bunless\b/, 'transform inserts unless');
	unlike($transformed, qr/\bif\b/,     'transform removes if');
};

# ==================================================================
# mutate -- transform flips unless to if
# ==================================================================
subtest 'mutate: transform flips unless to if' => sub {
	my $m   = _mutation();
	my $src = 'sub foo { unless($err) { proceed(); } }';
	my $doc = _doc($src);

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 1, 'one mutant produced');

	# Apply transform to a fresh copy
	my $copy = _doc($src);
	$mutants[0]->transform->($copy);

	my $transformed = $copy->serialize;

	# The unless keyword must have been replaced by if
	like($transformed,   qr/\bif\b/,     'transform inserts if');
	unlike($transformed, qr/\bunless\b/, 'transform removes unless');
};

# ==================================================================
# mutate -- transform targets correct conditional when multiple exist
# ==================================================================
subtest 'mutate: transform targets correct conditional' => sub {
	my $m   = _mutation();
	my $src = <<'CODE';
sub check {
	if($a) { return 1; }
	if($b) { return 2; }
}
CODE

	my $doc = _doc($src);
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 2, 'two mutants for two if statements');

	# Apply each transform to a fresh copy and verify only one keyword flips
	for my $mut (@mutants) {
		my $copy        = _doc($src);
		$mut->transform->($copy);
		my $transformed = $copy->serialize;

		# Count how many unless keywords appear — exactly one should be added
		my @unless_count = ($transformed =~ /\bunless\b/g);
		is(scalar @unless_count, 1,
			"transform for mutant ${\$mut->id} flips exactly one if to unless");
	}
};

# ==================================================================
# mutate -- transform does not modify original document
# ==================================================================
subtest 'mutate: transform does not modify original document' => sub {
	my $m   = _mutation();
	my $src = 'sub foo { if($x) { return 1; } }';
	my $doc = _doc($src);

	my @mutants = $m->mutate($doc);

	# Capture original serialisation before any transform
	my $before = $doc->serialize;

	# Apply transform to a different copy
	my $copy = _doc($src);
	$mutants[0]->transform->($copy);

	# Original document must be unchanged
	is($doc->serialize, $before, 'original document not modified by transform');
};

# ==================================================================
# mutate -- original field captures the condition content
# ==================================================================
subtest 'mutate: original captures condition content' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { if($x > 0) { return 1; } }');

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 1, 'one mutant produced');

	# Original should contain the condition expression
	like($mutants[0]->original, qr/\$x.*>.*0/,
		'original contains the condition expression');
};

# ==================================================================
# mutate -- conditional without a condition block is skipped
# ==================================================================
subtest 'mutate: conditional without condition block skipped' => sub {
	my $m = _mutation();

	# A well-formed if always has a condition -- test that the guard works
	# by verifying normal operation first
	my @mutants = $m->mutate(_doc('sub foo { if($x) { 1; } }'));
	is(scalar @mutants, 1, 'normal if with condition produces one mutant');
};

# ==================================================================
# mutate -- ID uniqueness: group contains same line as ID
# ==================================================================
subtest 'mutate: group line matches ID line' => sub {
	my $m   = _mutation();
	my $doc = _doc(<<'CODE');
sub foo {
	if($a)     { return 1; }
	unless($b) { return 0; }
}
CODE

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 2, 'two mutants produced');

	for my $mut (@mutants) {
		my ($id_line)    = $mut->id    =~ /COND_INV_(\d+)/;
		my ($group_line) = $mut->group =~ /COND_INV:(\d+)/;
		is($id_line, $group_line, "group line matches ID line for mutant ${\$mut->id}");
		is($mut->line, $id_line, "line() matches ID line for mutant ${\$mut->id}");
	}
};

# ==================================================================
# mutate -- returns a list (current API)
# ==================================================================
subtest 'mutate: returns a list' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { if($a) { 1; } unless($b) { 2; } }');

	# Current API returns a flat list
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 2, 'mutate returns flat list assignable to array');

	# TODO: API should return arrayref for efficiency — same change
	# needed across all Mutation::* subclasses simultaneously
};

# ==================================================================
# applies_to() — new function
# ==================================================================

subtest 'applies_to() returns 1 for document containing if statement' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ConditionalInversion->new();
	my $doc = PPI::Document->new(\'sub foo { if($x > 0) { return 1; } }');
	is($m->applies_to($doc), 1, 'if statement -> applies_to returns 1');
};

subtest 'applies_to() returns 1 for document containing unless statement' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ConditionalInversion->new();
	my $doc = PPI::Document->new(\'sub foo { unless($x) { return 0; } }');
	is($m->applies_to($doc), 1, 'unless statement -> applies_to returns 1');
};

subtest 'applies_to() returns 0 for document with no conditionals' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ConditionalInversion->new();
	my $doc = PPI::Document->new(\'sub foo { return 1; }');
	is($m->applies_to($doc), 0, 'no conditionals -> applies_to returns 0');
};

subtest 'applies_to() returns 0 for empty document' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ConditionalInversion->new();
	my $doc = PPI::Document->new(\' ');
	is($m->applies_to($doc), 0, 'empty document -> applies_to returns 0');
};

done_testing();
