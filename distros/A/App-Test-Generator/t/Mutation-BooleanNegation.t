#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use PPI;

BEGIN {
	use_ok('App::Test::Generator::Mutation::BooleanNegation');
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
# Helper: build a fresh BooleanNegation instance
# --------------------------------------------------
sub _mutation {
	return new_ok('App::Test::Generator::Mutation::BooleanNegation');
}

# ==================================================================
# new and inheritance
# ==================================================================
subtest 'new and inheritance' => sub {
	my $m = _mutation();
	ok(defined $m, 'new() returns defined value');
	isa_ok($m, 'App::Test::Generator::Mutation::BooleanNegation');
	isa_ok($m, 'App::Test::Generator::Mutation::Base',
		'inherits from Base');

	done_testing();
};

# ==================================================================
# applies_to
# ==================================================================
subtest 'applies_to' => sub {
	my $m = _mutation();

	# PPI >= 1.270 classifies return statements as PPI::Statement::Break
	# rather than PPI::Statement::Return -- use a custom predicate to find them
	my $doc = _doc('sub foo { return $x; }');

	my $breaks = $doc->find(sub {
		my $node = $_[1];
		# Match Break nodes that are specifically return statements
		return 0 unless $node->isa('PPI::Statement::Break');
		my $first = $node->schild(0) or return 0;
		return $first->content eq 'return';
	}) || [];

	ok($breaks && @{$breaks}, 'found return statement in doc');

	if($breaks && @{$breaks}) {
		ok($m->applies_to($breaks->[0]),
			'applies_to returns true for return Break node');
	} else {
		fail('applies_to returns true for return Break node -- no node found');
	}

	# Other node types are rejected
	my $words = $doc->find('PPI::Token::Word');
	ok($words && @{$words}, 'found word tokens in doc');
	ok(!$m->applies_to($words->[0]),
		'applies_to returns false for non-Return node');

	# last/next/redo are PPI::Statement::Break but not return -- must be rejected
	my $doc2   = _doc('sub foo { while(1) { last; } }');
	my $lasts  = $doc2->find(sub {
		my $node = $_[1];
		return 0 unless $node->isa('PPI::Statement::Break');
		my $first = $node->schild(0) or return 0;
		return $first->content eq 'last';
	}) || [];

	if($lasts && @{$lasts}) {
		ok(!$m->applies_to($lasts->[0]),
			'applies_to returns false for last (non-return Break node)');
	} else {
		# last may not parse as Break in all PPI versions -- skip gracefully
		pass('applies_to last test skipped -- no last node found');
	}

	done_testing();
};

# ==================================================================
# mutate -- empty document
# ==================================================================
subtest 'mutate: empty document' => sub {
	my $m   = _mutation();
	my $doc = _doc('package Foo; 1;');

	# No return statements -- must return empty list
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'no mutants for document with no return statements');

	done_testing();
};

# ==================================================================
# mutate -- bare return produces no mutant
# ==================================================================
subtest 'mutate: bare return produces no mutant' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { return; }');

	# Bare return has no expression -- must be skipped
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'bare return produces no mutant');

	done_testing();
};

# ==================================================================
# mutate -- single return with expression
# ==================================================================
subtest 'mutate: single return with expression' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { return $ok; }');

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 1, 'one mutant for one return with expression');

	my $mut = $mutants[0];
	isa_ok($mut, 'App::Test::Generator::Mutant');

	# ID must contain BOOL_NEGATE and a line number
	like($mut->id, qr/BOOL_NEGATE_\d+_\d+/, 'mutant ID has correct format');

	# Description is correct
	is($mut->description, 'Negate boolean return expression',
		'mutant description correct');

	# Original captures the return statement content
	like($mut->original, qr/return\s+\$ok/, 'original contains return statement');

	# Line number is set
	ok(defined $mut->line, 'line number is defined');
	ok($mut->line > 0,     'line number is positive');

	# Type is boolean
	is($mut->type, 'boolean', 'mutant type is boolean');

	# Transform is a coderef
	is(ref($mut->transform), 'CODE', 'transform is a coderef');

	done_testing();
};

# ==================================================================
# mutate -- multiple return statements produce multiple mutants
# ==================================================================
subtest 'mutate: multiple returns produce multiple mutants' => sub {
	my $m   = _mutation();
	my $doc = _doc(<<'CODE');
sub check {
	my ($x) = @_;
	return 0 if $x < 0;
	return 1 if $x > 0;
	return $x == 0;
}
CODE

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 3, 'three mutants for three return-with-expression statements');

	# All IDs must be unique
	my %ids = map { $_->id => 1 } @mutants;
	is(scalar keys %ids, 3, 'all mutant IDs are unique');

	# All line numbers must be positive
	ok($_->line > 0, 'line number positive for mutant ' . $_->id)
		for @mutants;

	done_testing();
};

# ==================================================================
# mutate -- ID uniqueness across same-line returns (col differentiates)
# ==================================================================
subtest 'mutate: IDs are unique across same file' => sub {
	my $m   = _mutation();
	my $doc = _doc(<<'CODE');
sub a { return $x; }
sub b { return $y; }
sub c { return $z; }
CODE

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 3, 'three mutants for three subs');

	my %ids = map { $_->id => 1 } @mutants;
	is(scalar keys %ids, 3, 'all IDs distinct across different lines');

	done_testing();
};

# ==================================================================
# mutate -- transform applies negation correctly
# ==================================================================
subtest 'mutate: transform negates return expression' => sub {
	my $m   = _mutation();
	my $src = 'sub foo { return $ok; }';
	my $doc = _doc($src);

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 1, 'one mutant produced');

	# Apply the transform to a fresh copy of the document
	my $copy = _doc($src);
	$mutants[0]->transform->($copy);

	# The transformed document must contain the negation
	my $transformed = $copy->serialize;
	like($transformed, qr/!\(/, 'transform inserts negation operator');
	like($transformed, qr/!\(\s*\$ok\s*\)/, 'negation wraps original expression');

	done_testing();
};

# ==================================================================
# mutate -- transform targets correct line when multiple returns exist
# ==================================================================
subtest 'mutate: transform targets correct return statement' => sub {
	my $m   = _mutation();
	my $src = <<'CODE';
sub check {
	my ($x) = @_;
	return 0 unless $x;
	return $x > 0;
}
CODE

	my $doc = _doc($src);
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 2, 'two mutants for two return-with-expression statements');

	# Apply each transform to a fresh copy and verify only one return is negated
	for my $mut (@mutants) {
		my $copy        = _doc($src);
		$mut->transform->($copy);
		my $transformed = $copy->serialize;

		# Exactly one negation must appear in the transformed source
		my @negs = ($transformed =~ /!\(/g);
		is(scalar @negs, 1,
			"transform for mutant ${\$mut->id} negates exactly one return");
	}

	done_testing();
};

# ==================================================================
# mutate -- transform does not modify the original document
# ==================================================================
subtest 'mutate: transform does not modify original document' => sub {
	my $m   = _mutation();
	my $src = 'sub foo { return $ok; }';
	my $doc = _doc($src);

	my @mutants = $m->mutate($doc);

	# Capture original serialisation before transform
	my $before = $doc->serialize;

	# Apply transform to a different copy
	my $copy = _doc($src);
	$mutants[0]->transform->($copy);

	# Original document must be unchanged
	is($doc->serialize, $before, 'original document not modified by transform');

	done_testing();
};

# ==================================================================
# mutate -- return value is a list (current API)
# ==================================================================
subtest 'mutate: returns a list' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { return $x; return $y; }');

	# Current API returns a flat list -- verify it can be assigned to an array
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 2, 'mutate returns flat list assignable to array');

	# TODO: API should return arrayref for efficiency -- see note at end of file

	done_testing();
};

# ==================================================================
# mutate -- group field is set correctly
# ==================================================================
subtest 'mutate: group field contains line number' => sub {
	my $m   = _mutation();
	my $doc = _doc(<<'CODE');
sub foo {
	return $a;
	return $b;
}
CODE

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 2, 'two mutants produced');

	for my $mut (@mutants) {
		like($mut->group, qr/^BOOL_NEGATE:\d+$/,
			'group has correct format for mutant ' . $mut->id);

		# Group must contain the same line number as the ID
		my ($id_line)    = $mut->id    =~ /BOOL_NEGATE_(\d+)/;
		my ($group_line) = $mut->group =~ /BOOL_NEGATE:(\d+)/;
		is($id_line, $group_line,
			'group line matches ID line for mutant ' . $mut->id);
	}

	done_testing();
};

# ==================================================================
# mutate -- various expression types are handled
# ==================================================================
subtest 'mutate: various expression types' => sub {
	my $m = _mutation();

	# Numeric literal
	my @mutants = $m->mutate(_doc('sub foo { return 1; }'));
	is(scalar @mutants, 1, 'numeric literal return produces mutant');

	# String literal
	@mutants = $m->mutate(_doc("sub foo { return 'ok'; }"));
	is(scalar @mutants, 1, 'string literal return produces mutant');

	# Method call
	@mutants = $m->mutate(_doc('sub foo { return $self->is_valid(); }'));
	is(scalar @mutants, 1, 'method call return produces mutant');

	# Comparison expression
	@mutants = $m->mutate(_doc('sub foo { return $x > 0; }'));
	is(scalar @mutants, 1, 'comparison return produces mutant');

	# Undef return
	@mutants = $m->mutate(_doc('sub foo { return undef; }'));
	is(scalar @mutants, 1, 'undef return produces mutant');

	done_testing();
};

# ==================================================================
# mutate -- postfix conditional returns produce no mutant
# return unless ..., return if ... etc are not valid mutation targets
# because wrapping the keyword in !() produces a syntax error
# ==================================================================
subtest 'mutate: postfix conditional returns produce no mutant' => sub {
	my $m = _mutation();

	# return unless condition
	my @mutants = $m->mutate(_doc('sub foo { return unless $x; }'));
	is(scalar @mutants, 0, 'return unless produces no mutant');

	# return if condition
	@mutants = $m->mutate(_doc('sub foo { return if $x; }'));
	is(scalar @mutants, 0, 'return if produces no mutant');

	# return while condition
	@mutants = $m->mutate(_doc('sub foo { return while $x; }'));
	is(scalar @mutants, 0, 'return while produces no mutant');

	# return until condition
	@mutants = $m->mutate(_doc('sub foo { return until $x; }'));
	is(scalar @mutants, 0, 'return until produces no mutant');

	done_testing();
};

# ==================================================================
# NOTE: API improvement opportunity
# --------------------------------------------------
# The mutate() method currently returns a flat list which is copied
# onto the caller's stack. For large documents with many return
# statements this wastes memory. The method should return an arrayref:
#
#   return \@mutants;
#
# and callers updated to dereference:
#
#   my @mutants = @{ $mutation->mutate($doc) };
#
# This applies to all Mutation::* subclasses for consistency.
# The same change should be made to ReturnUndef, NumericBoundary,
# and ConditionalInversion at the same time.
# ==================================================================

done_testing();
