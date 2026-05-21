#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

# Black-box unit tests for App::Test::Generator::Mutation::BooleanNegation
# and App::Test::Generator::Mutation::ReturnUndef.
# Tests each public function according to its POD API specification.

BEGIN {
	use_ok('App::Test::Generator::Mutation::BooleanNegation');
	use_ok('App::Test::Generator::Mutation::ReturnUndef');
}

# --------------------------------------------------
# Helper: parse a Perl snippet into a PPI document
# --------------------------------------------------
sub _doc {
	require PPI;
	return PPI::Document->new(\$_[0]);
}

# --------------------------------------------------
# Helper: find first return/break statement in doc
# --------------------------------------------------
sub _first_return {
	my ($doc) = @_;
	my $nodes = $doc->find(sub {
		my $node = $_[1];
		return 0 unless $node->isa('PPI::Statement::Break');
		my $first = $node->schild(0) or return 0;
		return $first->content eq 'return';
	}) || [];
	return $nodes->[0];
}

# ==================================================================
# BooleanNegation — new()
# ==================================================================

subtest 'BooleanNegation::new() returns a blessed object' => sub {
	my $m = App::Test::Generator::Mutation::BooleanNegation->new();
	isa_ok($m, 'App::Test::Generator::Mutation::BooleanNegation');
	isa_ok($m, 'App::Test::Generator::Mutation::Base');
};

subtest 'BooleanNegation::new() each call returns distinct object' => sub {
	my $m1 = new_ok('App::Test::Generator::Mutation::BooleanNegation');
	my $m2 = new_ok('App::Test::Generator::Mutation::BooleanNegation');
	isnt($m1, $m2, 'distinct objects returned');
};

# ==================================================================
# BooleanNegation — applies_to()
#
# POD spec:
#   Returns true for PPI::Statement::Return (Break) nodes
#   that are specifically return statements.
#   Returns false otherwise.
# ==================================================================

subtest 'BooleanNegation::applies_to() returns 1 for return statement' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc('sub foo { return $x; }');
	my $ret = _first_return($doc);
	SKIP: {
		skip 'no return statement found by PPI', 1 unless $ret;
		is($m->applies_to($ret), 1, 'return statement -> applies_to returns 1');
	}
};

subtest 'BooleanNegation::applies_to() returns 0 for plain expression' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc('sub foo { my $x = 1; }');
	my $stmt = $doc->find_first('PPI::Statement');
	ok($stmt, 'found a statement');
	is($m->applies_to($stmt), 0, 'plain statement -> applies_to returns 0');
};

subtest 'BooleanNegation::applies_to() returns 0 for if compound statement' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc('sub foo { if($x) { return 1; } }');
	my $if  = $doc->find_first('PPI::Statement::Compound');
	ok($if, 'found compound statement');
	is($m->applies_to($if), 0, 'if statement -> applies_to returns 0');
};

subtest 'BooleanNegation::applies_to() returns 0 for last statement' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc('sub foo { for my $i (1..10) { last; } }');
	my $nodes = $doc->find(sub {
		$_[1]->isa('PPI::Statement::Break') &&
		do {
			my $f = $_[1]->schild(0);
			$f && $f->content eq 'last';
		}
	}) || [];
	SKIP: {
		skip 'no last statement found', 1 unless @{$nodes};
		ok(!$m->applies_to($nodes->[0]), 'last statement -> applies_to false');
	}
};

# ==================================================================
# BooleanNegation — mutate()
#
# POD spec:
#   Returns a list of Mutant objects, one per qualifying return stmt.
#   Skips bare return; statements.
#   Each mutant wraps the return expr in !().
#   Returns empty list when no return stmts found.
# ==================================================================

subtest 'BooleanNegation::mutate() returns a list' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc('sub foo { return $ok; }');
	my @mutants;
	lives_ok(sub { @mutants = $m->mutate($doc) }, 'mutate() lives');
	ok(ref(\@mutants) eq 'ARRAY', 'returns a list');
};

subtest 'BooleanNegation::mutate() returns Mutant objects' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc('sub foo { return $ok; }');
	my @mutants = $m->mutate($doc);
	for my $mutant (@mutants) {
		isa_ok($mutant, 'App::Test::Generator::Mutant');
	}
};

subtest 'BooleanNegation::mutate() produces mutant for return with expression' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc("sub foo { return \$ok; }\n");
	my @mutants = $m->mutate($doc);
	ok(scalar @mutants > 0, 'at least one mutant for return $ok');
};

subtest 'BooleanNegation::mutate() mutant description mentions negation' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc("sub foo { return \$ok; }\n");
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		like($mutants[0]->description, qr/negate|boolean/i,
			'description mentions negation');
	}
};

subtest 'BooleanNegation::mutate() mutant type is boolean' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc("sub foo { return \$ok; }\n");
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		is($mutants[0]->type, 'boolean', 'mutant type is boolean');
	}
};

subtest 'BooleanNegation::mutate() mutant transform wraps expression in !()' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc("sub foo { return \$ok; }\n");
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		my $copy = _doc("sub foo { return \$ok; }\n");
		$mutants[0]->transform->($copy);
		like($copy->serialize, qr/!\(/, 'transform wraps expr in !()');
	}
};

subtest 'BooleanNegation::mutate() skips bare return statement' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc("sub foo { return; }\n");
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'bare return produces no mutants');
};

subtest 'BooleanNegation::mutate() returns empty list for no return stmts' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc("sub foo { my \$x = 1; }\n");
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'no return statements -> empty list');
};

subtest 'BooleanNegation::mutate() produces one mutant per return stmt' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc("sub foo {\n\tif(\$x) { return \$a; }\n\treturn \$b;\n}\n");
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 2, 'two return stmts -> two mutants');
};

subtest 'BooleanNegation::mutate() mutant IDs are unique' => sub {
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc = _doc("sub foo {\n\tif(\$x) { return \$a; }\n\treturn \$b;\n}\n");
	my @mutants = $m->mutate($doc);
	my %ids = map { $_->id => 1 } @mutants;
	is(scalar keys %ids, scalar @mutants, 'all mutant IDs are unique');
};

subtest 'BooleanNegation::mutate() does not modify the original document' => sub {
	my $m	= App::Test::Generator::Mutation::BooleanNegation->new();
	my $src  = "sub foo { return \$ok; }\n";
	my $doc  = _doc($src);
	my $before = $doc->serialize;
	$m->mutate($doc);
	is($doc->serialize, $before, 'original document unchanged after mutate()');
};

subtest 'BooleanNegation::mutate() returns exactly 0 not undef for non-Break node' => sub {
	require PPI;
	my $m    = App::Test::Generator::Mutation::BooleanNegation->new();
	my $doc  = PPI::Document->new(\'sub foo { my $x = 1; }');
	my $stmt = $doc->find_first('PPI::Statement::Variable');
	my $result = $m->applies_to($stmt);
	is($result, 0, 'non-Break node returns exactly 0 not undef');
};

# ==================================================================
# ReturnUndef — new()
# ==================================================================

subtest 'ReturnUndef::new() returns a blessed object' => sub {
	my $m = App::Test::Generator::Mutation::ReturnUndef->new();
	isa_ok($m, 'App::Test::Generator::Mutation::ReturnUndef');
	isa_ok($m, 'App::Test::Generator::Mutation::Base');
};

subtest 'ReturnUndef::new() each call returns distinct object' => sub {
	my $m1 = App::Test::Generator::Mutation::ReturnUndef->new();
	my $m2 = App::Test::Generator::Mutation::ReturnUndef->new();
	isnt($m1, $m2, 'distinct objects returned');
};

# ==================================================================
# ReturnUndef — applies_to()
#
# POD spec:
#   Returns true for return statements (PPI::Statement::Break).
#   Returns false otherwise.
# ==================================================================

subtest 'ReturnUndef::applies_to() returns 1 for return statement' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc('sub foo { return $x; }');
	my $ret = _first_return($doc);
	SKIP: {
		skip 'no return statement found', 1 unless $ret;
		is($m->applies_to($ret), 1, 'return statement -> applies_to returns 1');
	}
};

subtest 'ReturnUndef::applies_to() returns 0 for plain expression' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc('sub foo { my $x = 1; }');
	my $stmt = $doc->find_first('PPI::Statement');
	ok($stmt, 'found a statement');
	is($m->applies_to($stmt), 0, 'plain statement -> applies_to returns 0');
};

subtest 'ReturnUndef::applies_to() returns 0 for if statement' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc('sub foo { if($x) { return 1; } }');
	my $if  = $doc->find_first('PPI::Statement::Compound');
	ok($if, 'found compound statement');
	is($m->applies_to($if), 0, 'if statement -> applies_to returns 0');
};

# ==================================================================
# ReturnUndef — mutate()
#
# POD spec:
#   Returns a list of Mutant objects, one per qualifying return stmt.
#   Skips bare return; statements.
#   Each mutant replaces the return expr with undef.
#   Returns empty list when no qualifying return stmts found.
# ==================================================================

subtest 'ReturnUndef::mutate() returns a list' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc("sub foo { return \$result; }\n");
	my @mutants;
	lives_ok(sub { @mutants = $m->mutate($doc) }, 'mutate() lives');
	ok(ref(\@mutants) eq 'ARRAY', 'returns a list');
};

subtest 'ReturnUndef::mutate() returns Mutant objects' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc("sub foo { return \$result; }\n");
	my @mutants = $m->mutate($doc);
	for my $mutant (@mutants) {
		isa_ok($mutant, 'App::Test::Generator::Mutant');
	}
};

subtest 'ReturnUndef::mutate() produces mutant for return with expression' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc("sub foo { return \$result; }\n");
	my @mutants = $m->mutate($doc);
	ok(scalar @mutants > 0, 'at least one mutant for return $result');
};

subtest 'ReturnUndef::mutate() mutant type is return' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc("sub foo { return \$result; }\n");
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		is($mutants[0]->type, 'return', 'mutant type is return');
	}
};

subtest 'ReturnUndef::mutate() mutant description mentions undef' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc("sub foo { return \$result; }\n");
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		like($mutants[0]->description, qr/undef/i,
			'description mentions undef');
	}
};

subtest 'ReturnUndef::mutate() transform replaces expr with undef' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc("sub foo { return \$result; }\n");
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		my $copy = _doc("sub foo { return \$result; }\n");
		$mutants[0]->transform->($copy);
		like($copy->serialize, qr/return undef/, 'transform produces return undef');
	}
};

subtest 'ReturnUndef::mutate() skips bare return statement' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc("sub foo { return; }\n");
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'bare return produces no mutants');
};

subtest 'ReturnUndef::mutate() returns empty list for no return stmts' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc("sub foo { my \$x = 1; }\n");
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 0, 'no return statements -> empty list');
};

subtest 'ReturnUndef::mutate() produces one mutant per qualifying return' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc("sub foo {\n\tif(\$x) { return \$a; }\n\treturn \$b;\n}\n");
	my @mutants = $m->mutate($doc);
	is(scalar @mutants, 2, 'two return stmts -> two mutants');
};

subtest 'ReturnUndef::mutate() mutant IDs are unique' => sub {
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $doc = _doc("sub foo {\n\tif(\$x) { return \$a; }\n\treturn \$b;\n}\n");
	my @mutants = $m->mutate($doc);
	my %ids = map { $_->id => 1 } @mutants;
	is(scalar keys %ids, scalar @mutants, 'all mutant IDs are unique');
};

subtest 'ReturnUndef::mutate() does not modify the original document' => sub {
	my $m	= App::Test::Generator::Mutation::ReturnUndef->new();
	my $src  = "sub foo { return \$result; }\n";
	my $doc  = _doc($src);
	my $before = $doc->serialize;
	$m->mutate($doc);
	is($doc->serialize, $before, 'original document unchanged after mutate()');
};

# ==================================================================
# Cross-check: both modules inherit from Base
# ==================================================================

subtest 'both mutation classes inherit from Base' => sub {
	for my $class (qw(
		App::Test::Generator::Mutation::BooleanNegation
		App::Test::Generator::Mutation::ReturnUndef
	)) {
		my $m = $class->new();
		isa_ok($m, 'App::Test::Generator::Mutation::Base',
			"$class inherits from Base");
	}
};

done_testing();
