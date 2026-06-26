#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use PPI;

BEGIN {
	use_ok('App::Test::Generator::Mutation::ReturnUndef');
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
# Helper: build a fresh ReturnUndef instance
# --------------------------------------------------
sub _mutation {
	return new_ok('App::Test::Generator::Mutation::ReturnUndef');
}

# ==================================================================
# new and inheritance
# ==================================================================
subtest 'new and inheritance' => sub {
	my $m = _mutation();
	ok(defined $m, 'new() returns defined value');
	isa_ok($m, 'App::Test::Generator::Mutation::ReturnUndef');
	isa_ok($m, 'App::Test::Generator::Mutation::Base', 'inherits from Base');

	done_testing();
};

# ==================================================================
# applies_to
# ==================================================================
subtest 'applies_to' => sub {
	my $m  = _mutation();

	# applies_to() is a document-level pre-filter (see Mutation::Base
	# POD) used by Mutator::generate_mutants to skip the mutate() walk
	# entirely when a document has nothing to mutate -- it takes the
	# whole PPI::Document, not an individual node.
	my $doc = _doc('sub foo { return $x; }');
	ok($m->applies_to($doc), 'applies_to returns true for doc containing a return stmt');

	# A document with no return statements at all
	my $doc_no_return = _doc('sub foo { my $x = 1; }');
	ok(!$m->applies_to($doc_no_return), 'applies_to returns false for doc with no return stmts');

	# last/next/redo are PPI::Statement::Break but not return -- a
	# document containing only those must not qualify
	my $doc_last = _doc('sub foo { while(1) { last; } }');
	ok(!$m->applies_to($doc_last),
		'applies_to returns false for doc with only last/next/redo');

	done_testing();
};

# ==================================================================
# mutate -- empty document
# ==================================================================
subtest 'mutate: empty document' => sub {
	my $m   = _mutation();
	my $doc = _doc('package Foo; 1;');

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'no mutants for document with no return statements');

	done_testing();
};

# ==================================================================
# mutate -- bare return produces no mutant
# --------------------------------------------------
# bare return already returns undef -- redundant to mutate
# ==================================================================
subtest 'mutate: bare return produces no mutant' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { return; }');

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

	# ID format: RETURN_UNDEF_line_col
	like($mut->id, qr/^RETURN_UNDEF_\d+_\d+$/, 'mutant ID has correct format');

	# Description is correct
	is($mut->description, 'Replace return expression with undef',
		'mutant description correct');

	# Original captures the return statement content
	like($mut->original, qr/return\s+\$ok/, 'original contains return statement');

	# Line number is positive
	ok($mut->line > 0, 'line number is positive');

	# Type is return
	is($mut->type, 'return', 'mutant type is return');

	# Transform is a coderef
	is(ref($mut->transform), 'CODE', 'transform is a coderef');

	# Group format: RETURN_UNDEF:line
	like($mut->group, qr/^RETURN_UNDEF:\d+$/, 'group has correct format');

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

	done_testing();
};

# ==================================================================
# mutate -- transform replaces expression with undef
# ==================================================================
subtest 'mutate: transform replaces expression with undef' => sub {
	my $m   = _mutation();
	my $src = 'sub foo { return $ok; }';
	my $doc = _doc($src);

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 1, 'one mutant produced');

	# Apply the transform to a fresh copy
	my $copy = _doc($src);
	$mutants[0]->transform->($copy);

	my $transformed = $copy->serialize;

	# The transformed source must contain undef
	like($transformed, qr/\bundef\b/, 'transform inserts undef');

	# The original expression must be replaced
	unlike($transformed, qr/\$ok/, 'transform removes original expression');

	done_testing();
};

# ==================================================================
# mutate -- transform targets correct return when multiple exist
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

	my $doc     = _doc($src);
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 2, 'two mutants for two return-with-expression statements');

	# Apply each transform to a fresh copy and verify only one expression is replaced
	for my $mut (@mutants) {
		my $copy        = _doc($src);
		$mut->transform->($copy);
		my $transformed = $copy->serialize;

		# Exactly one undef must appear in the transformed source
		my @undefs = ($transformed =~ /\bundef\b/g);
		is(scalar @undefs, 1,
			"transform for mutant ${\$mut->id} replaces exactly one return expression");
	}

	done_testing();
};

# ==================================================================
# mutate -- transform does not modify original document
# ==================================================================
subtest 'mutate: transform does not modify original document' => sub {
	my $m   = _mutation();
	my $src = 'sub foo { return $ok; }';
	my $doc = _doc($src);

	my @mutants = $m->mutate($doc);
	my $before  = $doc->serialize;

	# Apply transform to a different copy
	my $copy = _doc($src);
	$mutants[0]->transform->($copy);

	# Original document must be unchanged
	is($doc->serialize, $before, 'original document not modified by transform');

	done_testing();
};

# ==================================================================
# mutate -- group line matches ID line
# ==================================================================
subtest 'mutate: group line matches ID line' => sub {
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
		my ($id_line)    = $mut->id    =~ /RETURN_UNDEF_(\d+)/;
		my ($group_line) = $mut->group =~ /RETURN_UNDEF:(\d+)/;
		is($id_line, $group_line,
			"group line matches ID line for mutant ${\$mut->id}");
		is($mut->line, $id_line,
			"line() matches ID line for mutant ${\$mut->id}");
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
	@mutants = $m->mutate(_doc('sub foo { return $self->value(); }'));
	is(scalar @mutants, 1, 'method call return produces mutant');

	# Comparison expression
	@mutants = $m->mutate(_doc('sub foo { return $x > 0; }'));
	is(scalar @mutants, 1, 'comparison return produces mutant');

	done_testing();
};

# ==================================================================
# mutate -- returns a list (current API)
# ==================================================================
subtest 'mutate: returns a list' => sub {
	my $m   = _mutation();
	my $doc = _doc('sub foo { return $x; return $y; }');

	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 2, 'mutate returns flat list assignable to array');

	# TODO: API should return arrayref for efficiency -- same change
	# needed across all Mutation::* subclasses simultaneously

	done_testing();
};

# ==================================================================
# mutate -- postfix conditional returns produce no mutant
# return unless ..., return if ... etc are not valid mutation targets
# because wrapping the keyword in !() or replacing with undef
# produces a syntax error
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
# mutate -- chained/dereferencing return expressions are replaced
# in full, not just their leading token
# --------------------------------------------------
# Regression: $ret->schild(1) only ever captured the first token of
# a multi-token return expression (e.g. just $self out of
# $self->{value}), so the transform replaced only that leading token
# and left the rest of the chain dangling, producing the broken
# mutant 'return undef->{value};' (dies at runtime: "Can't use
# string ... as a HASH ref").
# ==================================================================
subtest 'mutate: chained return expression is replaced as a whole' => sub {
	my $m = _mutation();

	my $src     = 'sub foo { return $self->{value}; }';
	my @mutants = $m->mutate(_doc($src));
	is(scalar @mutants, 1, 'one mutant for chained property return');

	my $copy = _doc($src);
	$mutants[0]->transform->($copy);
	is($copy->serialize, 'sub foo { return undef; }',
		'whole $self->{value} expression replaced with undef, not just $self');

	# Same chain, but with a postfix conditional appended
	$src     = 'sub foo { return $self->{value} if $x; }';
	@mutants = $m->mutate(_doc($src));
	is(scalar @mutants, 1, 'one mutant for chained property return with postfix conditional');

	$copy = _doc($src);
	$mutants[0]->transform->($copy);
	is($copy->serialize, 'sub foo { return undef if $x; }',
		'whole $self->{value} expression replaced with undef, postfix conditional preserved');

	done_testing();
};

subtest 'ReturnUndef::applies_to() returns exactly 0 not undef when nothing qualifies' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = PPI::Document->new(\'sub foo { my $x = 1; }');
	my $result = $m->applies_to($doc);
	is($result, 0, 'no qualifying return stmt returns exactly 0 not undef');
};

done_testing();
