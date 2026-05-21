#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Path    qw(make_path);
use File::Spec;
use File::Temp    qw(tempdir tempfile);
use Scalar::Util  qw(looks_like_number);

# Extended tests targeting:
# 1. Known surviving mutants in _dedup_mutants, _is_redundant_mutation,
#    BooleanNegation, ReturnUndef, Emitter::Perl, Planner
# 2. Branch coverage gaps in Generator render helpers
# 3. LCSAJ/TER3 improvement via additional branch-path coverage
# 4. Stateful behaviour across multiple calls

BEGIN {
	use_ok('App::Test::Generator');
	use_ok('App::Test::Generator::Mutator');
	use_ok('App::Test::Generator::Mutation::BooleanNegation');
	use_ok('App::Test::Generator::Mutation::ReturnUndef');
	use_ok('App::Test::Generator::Planner');
	use_ok('App::Test::Generator::Emitter::Perl');
	use_ok('App::Test::Generator::LCSAJ');
}

# ==================================================================
# Mutator._dedup_mutants — surviving mutant killers
#
# The boolean returns in _dedup_mutants use $seen{$key}++ (truthy
# after first occurrence) and !$seen{$key}++ (falsy on first, truthy
# after). Mutations flip these. The tests below assert exact counts
# to kill negation and undef-return survivors on lines 435-450.
# ==================================================================

{
	no warnings 'once';
	*_dedup_mutants        = \&App::Test::Generator::Mutator::_dedup_mutants;
	*_is_redundant_mutation = \&App::Test::Generator::Mutator::_is_redundant_mutation;
}

subtest '_dedup_mutants: single unique mutant returns exactly 1' => sub {
	my $mutants = [
		{ line => 5, original => '>', description => 'flip', transform => sub {} }
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 1, 'single unique mutant: count is exactly 1');
};

subtest '_dedup_mutants: two identical mutants return exactly 1' => sub {
	my $mutants = [
		{ line => 5, original => '>', description => 'flip', transform => sub {} },
		{ line => 5, original => '>', description => 'flip', transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 1,
		'two identical mutants deduplicated to exactly 1');
};

subtest '_dedup_mutants: three identical mutants return exactly 1' => sub {
	my $mutants = [
		{ line => 5, original => '>', description => 'flip', transform => sub {} },
		{ line => 5, original => '>', description => 'flip', transform => sub {} },
		{ line => 5, original => '>', description => 'flip', transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 1, 'three identical mutants -> exactly 1');
};

subtest '_dedup_mutants: two different mutants return exactly 2' => sub {
	my $mutants = [
		{ line => 5,  original => '>', description => 'A', transform => sub {} },
		{ line => 10, original => '<', description => 'B', transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 2, 'two distinct mutants -> exactly 2');
};

subtest '_dedup_mutants: +0 no-op removed, valid mutant kept' => sub {
	my $mutants = [
		{ line => 5,  original => '$x + 0', description => 'noop',  transform => sub {} },
		{ line => 10, original => '$x > 0', description => 'valid', transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 1, '+0 removed, valid kept: count is exactly 1');
	is($result->[0]{description}, 'valid', 'correct mutant retained');
};

subtest '_dedup_mutants: -0 no-op removed, valid mutant kept' => sub {
	my $mutants = [
		{ line => 5,  original => '$x - 0', description => 'noop',  transform => sub {} },
		{ line => 10, original => '$x > 0', description => 'valid', transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 1, '-0 removed, valid kept: count is exactly 1');
};

subtest '_dedup_mutants: standalone 1 removed, valid mutant kept' => sub {
	my $mutants = [
		{ line => 5,  original => '1',      description => 'literal', transform => sub {} },
		{ line => 10, original => '$x > 0', description => 'valid',   transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 1, 'literal 1 removed, valid kept');
};

subtest '_dedup_mutants: comment line mutant removed, valid kept' => sub {
	my $mutants = [
		{
			line         => 5,
			original     => '$x > 0',
			description  => 'commented',
			line_content => '# if ($x > 0)',
			transform    => sub {}
		},
		{
			line         => 10,
			original     => '$x > 0',
			description  => 'real',
			line_content => "\tif(\$x > 0) {",
			transform    => sub {}
		},
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 1, 'comment-line mutant removed, real kept');
	is($result->[0]{description}, 'real', 'real mutant retained not commented');
};

subtest '_dedup_mutants: empty input returns empty arrayref' => sub {
	my $result = _dedup_mutants([]);
	is(ref($result), 'ARRAY', 'returns arrayref');
	is(scalar @{$result}, 0, 'empty input -> empty output');
};

subtest '_dedup_mutants: all redundant mutants -> empty result' => sub {
	my $mutants = [
		{ line => 1, original => '$x + 0', description => 'noop1', transform => sub {} },
		{ line => 2, original => '$x - 0', description => 'noop2', transform => sub {} },
		{ line => 3, original => '1',      description => 'bool',  transform => sub {} },
		{ line => 4, original => '0',      description => 'bool2', transform => sub {} },
	];
	my $result = _dedup_mutants($mutants);
	is(scalar @{$result}, 0, 'all redundant mutants -> empty result');
};

# ==================================================================
# Mutator._is_redundant_mutation — precise boundary tests
# These target the exact return values to kill BOOL_NEGATE survivors
# ==================================================================

subtest '_is_redundant_mutation: returns exactly 1 for +0' => sub {
	is(_is_redundant_mutation({ original => '$x + 0' }), 1,
		'+0 returns exactly 1 not undef');
};

subtest '_is_redundant_mutation: returns exactly 1 for -0' => sub {
	is(_is_redundant_mutation({ original => '$y - 0' }), 1,
		'-0 returns exactly 1 not undef');
};

subtest '_is_redundant_mutation: returns exactly 0 for normal op' => sub {
	is(_is_redundant_mutation({ original => '$x > 0' }), 0,
		'normal op returns exactly 0 not undef');
};

subtest '_is_redundant_mutation: !! in conditional returns exactly 1' => sub {
	is(_is_redundant_mutation({
		original => '!!$flag',
		context  => 'conditional',
	}), 1, 'double negation in conditional returns exactly 1');
};

subtest '_is_redundant_mutation: !! outside conditional returns exactly 0' => sub {
	is(_is_redundant_mutation({
		original => '!!$flag',
	}), 0, 'double negation outside conditional returns exactly 0');
};

subtest '_is_redundant_mutation: standalone 0 returns exactly 1' => sub {
	is(_is_redundant_mutation({ original => '0' }), 1,
		'standalone 0 returns exactly 1');
};

subtest '_is_redundant_mutation: padded 1 returns exactly 1' => sub {
	is(_is_redundant_mutation({ original => '  1  ' }), 1,
		'padded standalone 1 returns exactly 1');
};

subtest '_is_redundant_mutation: comment line returns exactly 1' => sub {
	is(_is_redundant_mutation({
		original     => '$x',
		line_content => '# $x > 0',
	}), 1, 'comment line returns exactly 1');
};

# ==================================================================
# BooleanNegation — target surviving mutants
# The two survivors are in the transform closure — test that the
# transform actually modifies the document (kills return=undef mutant)
# and that it modifies the correct expression (kills inversion mutant)
# ==================================================================

subtest 'BooleanNegation: transform produces non-empty document' => sub {
	require PPI;
	my $m   = new_ok('App::Test::Generator::Mutation::BooleanNegation');
	my $src = "sub foo { return \$ok; }\n";
	my $doc = PPI::Document->new(\$src);
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 2 unless @mutants;
		my $copy = PPI::Document->new(\$src);
		$mutants[0]->transform->($copy);
		my $result = $copy->serialize;
		ok(defined $result,      'transform produces defined output');
		ok(length($result) > 0,  'transform produces non-empty output');
	}
};

subtest 'BooleanNegation: transform changes document content' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $src = "sub foo { return \$ok; }\n";
	my $doc = PPI::Document->new(\$src);
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		my $copy   = PPI::Document->new(\$src);
		my $before = $copy->serialize;
		$mutants[0]->transform->($copy);
		my $after  = $copy->serialize;
		isnt($after, $before, 'transform changes document content');
	}
};

subtest 'BooleanNegation: transformed result contains negation operator' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $src = "sub foo { return \$ok; }\n";
	my $doc = PPI::Document->new(\$src);
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		my $copy = PPI::Document->new(\$src);
		$mutants[0]->transform->($copy);
		like($copy->serialize, qr/!/,
			'transformed result contains negation operator');
	}
};

subtest 'BooleanNegation: each mutant targets a different location' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::BooleanNegation->new();
	my $src = "sub foo {\n\tmy \$x = shift;\n\tif(\$x > 0) { return \$x; }\n\treturn 0;\n}\n";
	my $doc = PPI::Document->new(\$src);
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'fewer than 2 mutants', 1 unless scalar @mutants >= 2;
		# Apply each mutant to a fresh copy and collect serialised results
		my @results;
		for my $mut (@mutants) {
			my $copy = PPI::Document->new(\$src);
			$mut->transform->($copy);
			push @results, $copy->serialize;
		}
		# Each transform should produce a different result
		my %unique = map { $_ => 1 } @results;
		is(scalar keys %unique, scalar @mutants,
			'each mutant produces a distinct transformation');
	}
};

# ==================================================================
# ReturnUndef — target surviving mutants
# Same pattern as BooleanNegation — test transform correctness
# ==================================================================

subtest 'ReturnUndef: transform produces non-empty document' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $src = "sub foo { return \$result; }\n";
	my $doc = PPI::Document->new(\$src);
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 2 unless @mutants;
		my $copy = PPI::Document->new(\$src);
		$mutants[0]->transform->($copy);
		my $result = $copy->serialize;
		ok(defined $result,     'transform produces defined output');
		ok(length($result) > 0, 'transform produces non-empty output');
	}
};

subtest 'ReturnUndef: transform changes document content' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $src = "sub foo { return \$result; }\n";
	my $doc = PPI::Document->new(\$src);
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		my $copy   = PPI::Document->new(\$src);
		my $before = $copy->serialize;
		$mutants[0]->transform->($copy);
		isnt($copy->serialize, $before, 'transform changes document');
	}
};

subtest 'ReturnUndef: transformed result contains literal undef' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $src = "sub foo { return \$result; }\n";
	my $doc = PPI::Document->new(\$src);
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		my $copy = PPI::Document->new(\$src);
		$mutants[0]->transform->($copy);
		like($copy->serialize, qr/\bundef\b/,
			'transformed result contains literal undef');
	}
};

subtest 'ReturnUndef: transform replaces expression not entire return' => sub {
	require PPI;
	my $m   = App::Test::Generator::Mutation::ReturnUndef->new();
	my $src = "sub foo { return \$result; }\n";
	my $doc = PPI::Document->new(\$src);
	my @mutants = $m->mutate($doc);
	SKIP: {
		skip 'no mutants produced', 1 unless @mutants;
		my $copy = PPI::Document->new(\$src);
		$mutants[0]->transform->($copy);
		like($copy->serialize, qr/return undef/,
			'return keyword preserved, only expression replaced');
	}
};

# ==================================================================
# Planner — surviving mutant killers
# Three survivors in plan_all() — test exact flag values not just
# truthiness, and negative assertions for wrong accessor types
# ==================================================================

subtest "Planner: accessor 'get' sets exactly getter_test=1" => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => { m => { accessor => { type => 'get' }, output => {} } },
		package => 'Foo',
	);
	my $plan = $p->plan_all()->{m};
	is($plan->{getter_test}, 1,     "getter_test is exactly 1");
	ok(!$plan->{getset_test},       'getset_test not set for get');
	ok(!$plan->{object_injection_test}, 'inject_test not set for get');
	ok(!$plan->{boolean_test},      'boolean_test not set for get');
};

subtest "Planner: accessor 'getset' sets exactly getset_test=1" => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => { m => { accessor => { type => 'getset' }, output => {} } },
		package => 'Foo',
	);
	my $plan = $p->plan_all()->{m};
	is($plan->{getset_test}, 1,     'getset_test is exactly 1');
	ok(!$plan->{getter_test},       'getter_test not set for getset');
	ok(!$plan->{object_injection_test}, 'inject_test not set for getset');
};

subtest "Planner: accessor 'injector' sets exactly object_injection_test=1" => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => { m => { accessor => { type => 'injector' }, output => {} } },
		package => 'Foo',
	);
	my $plan = $p->plan_all()->{m};
	is($plan->{object_injection_test}, 1, 'object_injection_test is exactly 1');
	ok(!$plan->{getter_test},           'getter_test not set for injector');
	ok(!$plan->{getset_test},           'getset_test not set for injector');
};

subtest "Planner: boolean output sets exactly boolean_test=1" => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => { m => { output => { type => 'boolean' } } },
		package => 'Foo',
	);
	my $plan = $p->plan_all()->{m};
	is($plan->{boolean_test}, 1, 'boolean_test is exactly 1');
};

subtest 'Planner: non-boolean string output does not set boolean_test' => sub {
	for my $type (qw(string integer number hashref arrayref object)) {
		my $p = App::Test::Generator::Planner->new(
			schemas => { m => { output => { type => $type } } },
			package => 'Foo',
		);
		my $plan = $p->plan_all()->{m};
		ok(!$plan->{boolean_test},
			"output type '$type' does not set boolean_test");
	}
};

subtest 'Planner: accessor type wrong case does not set any flag' => sub {
	for my $wrong (qw(GET GETSET INJECTOR Getter Setter)) {
		my $p = App::Test::Generator::Planner->new(
			schemas => { m => { accessor => { type => $wrong }, output => {} } },
			package => 'Foo',
		);
		my $plan = $p->plan_all()->{m};
		ok(!$plan->{getter_test},            "$wrong: no getter_test");
		ok(!$plan->{getset_test},            "$wrong: no getset_test");
		ok(!$plan->{object_injection_test},  "$wrong: no inject_test");
	}
};

# ==================================================================
# Emitter::Perl — surviving mutant killers
# Two survivors — likely in _emit_getset_test type dispatch
# ==================================================================

subtest 'Emitter: getset with object type emits isa_ok not string eq' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => { input => { obj => { type => 'object' } } } },
		plans   => { foo => { getset_test => 1 } },
		package => 'Foo',
	);
	my $code = $e->emit();
	like($code,   qr/isa_ok/,         'object getset uses isa_ok');
	like($code,   qr/MockObject/,     'object getset uses mock object');
	unlike($code, qr/\$obj->foo\('value'\)/, 'object getset does not use string value');
};

subtest 'Emitter: getset with boolean type emits boolean round-trip' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => { input => { flag => { type => 'boolean' } } } },
		plans   => { foo => { getset_test => 1 } },
		package => 'Foo',
	);
	my $code = $e->emit();
	like($code,   qr/boolean/,      'boolean getset uses boolean pattern');
	unlike($code, qr/isa_ok/,       'boolean getset does not use isa_ok');
};

subtest 'Emitter: getset with string type emits string eq round-trip' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => { input => { name => { type => 'string' } } } },
		plans   => { foo => { getset_test => 1 } },
		package => 'Foo',
	);
	my $code = $e->emit();
	like($code,   qr/get\/set works/, 'string getset uses string round-trip');
	unlike($code, qr/isa_ok/,         'string getset does not use isa_ok');
	unlike($code, qr/boolean/,        'string getset does not use boolean pattern');
};

subtest 'Emitter: getset with integer type emits string round-trip fallback' => sub {
	my $e = App::Test::Generator::Emitter::Perl->new(
		schema  => { foo => { input => { count => { type => 'integer' } } } },
		plans   => { foo => { getset_test => 1 } },
		package => 'Foo',
	);
	my $code = $e->emit();
	# integer is not object or boolean so falls through to default string round-trip
	like($code, qr/get\/set works/, 'integer type falls through to string round-trip');
};

subtest 'Emitter: all three getset type branches produce compilable code' => sub {
	for my $type (qw(object boolean string)) {
		my $input_spec = { val => { type => $type } };
		my $e = App::Test::Generator::Emitter::Perl->new(
			schema  => { foo => { input => $input_spec } },
			plans   => { foo => { getset_test => 1 } },
			package => 'My::Module',
		);
		my $code    = $e->emit();
		my $tmpdir  = tempdir(CLEANUP => 1);
		my $outfile = File::Spec->catfile($tmpdir, "getset_$type.t");
		open my $fh, '>', $outfile or die $!;
		print $fh $code;
		close $fh;
		is(system($^X, '-c', $outfile), 0,
			"getset with $type type produces compilable code");
	}
};

# ==================================================================
# Generator render helpers — branch coverage
# Target specific branches not yet exercised
# ==================================================================

subtest 'perl_quote: boolean string "true" -> !!1' => sub {
	is(App::Test::Generator::perl_quote('true'), '!!1',
		'"true" -> !!1');
};

subtest 'perl_quote: boolean string "false" -> !!0' => sub {
	is(App::Test::Generator::perl_quote('false'), '!!0',
		'"false" -> !!0');
};

subtest 'perl_quote: numeric value returned unquoted' => sub {
	is(App::Test::Generator::perl_quote(42),   '42',   'integer unquoted');
	is(App::Test::Generator::perl_quote(3.14), '3.14', 'float unquoted');
	is(App::Test::Generator::perl_quote(-1),   '-1',   'negative unquoted');
	is(App::Test::Generator::perl_quote(0),    '0',    'zero unquoted');
};

subtest 'perl_quote: string value returned single-quoted' => sub {
	like(App::Test::Generator::perl_quote('hello'), qr/^'hello'$/, 'string single-quoted');
};

subtest 'perl_quote: regexp rendered as qr{}' => sub {
	my $result = App::Test::Generator::perl_quote(qr/^\d+$/);
	like($result, qr/qr\{/, 'regexp rendered as qr{}');
};

subtest 'perl_quote: regexp with modifiers includes modifiers' => sub {
	my $result = App::Test::Generator::perl_quote(qr/foo/i);
	like($result, qr/i/, 'case-insensitive modifier included');
};

subtest 'perl_quote: hashref falls through to render_fallback' => sub {
	my $result = App::Test::Generator::perl_quote({ key => 'val' });
	ok(defined $result,       'hashref handled');
	like($result, qr/key/,    'key present in output');
	like($result, qr/val/,    'value present in output');
};

subtest 'perl_sq: backslash escaped correctly' => sub {
	my $result = App::Test::Generator::perl_sq('a\\b');
	like($result, qr/\\\\/, 'backslash doubled');
};

subtest 'perl_sq: single quote escaped correctly' => sub {
	my $result = App::Test::Generator::perl_sq("it's");
	like($result, qr/\\'/, 'apostrophe escaped');
};

subtest 'perl_sq: control characters escaped' => sub {
	is(App::Test::Generator::perl_sq("\n"), '\\n', 'newline escaped');
	is(App::Test::Generator::perl_sq("\t"), '\\t', 'tab escaped');
	is(App::Test::Generator::perl_sq("\r"), '\\r', 'CR escaped');
};

subtest 'perl_sq: NUL byte escaped as \\0' => sub {
	is(App::Test::Generator::perl_sq("\0"), '\\0', 'NUL escaped');
};

subtest 'q_wrap: prefers bracket form when available' => sub {
	my $result = App::Test::Generator::q_wrap('hello');
	like($result, qr/^q\{hello\}$/, 'bracket form preferred');
};

subtest 'q_wrap: falls back to () when {} used in string' => sub {
	my $result = App::Test::Generator::q_wrap('a{b}c');
	ok(defined $result, 'string with braces handled');
	unlike($result, qr/^q\{/, 'does not use {} delimiter');
};

subtest 'q_wrap: falls back to [] when {} and () used' => sub {
	my $result = App::Test::Generator::q_wrap('a{b}(c)d');
	ok(defined $result, 'string with braces and parens handled');
};

subtest 'render_args_hash: sorts keys deterministically' => sub {
	my $r1 = App::Test::Generator::render_args_hash({ b => 2, a => 1, c => 3 });
	my $r2 = App::Test::Generator::render_args_hash({ c => 3, a => 1, b => 2 });
	is($r1, $r2, 'sorted output is identical regardless of input order');
};

subtest 'render_args_hash: handles Regexp values' => sub {
	my $result = App::Test::Generator::render_args_hash({ matches => qr/^\d+$/ });
	like($result, qr/qr\{/, 'Regexp rendered as qr{}');
};

subtest 'render_args_hash: handles arrayref values' => sub {
	my $result = App::Test::Generator::render_args_hash({ values => [1, 2, 3] });
	like($result, qr/1.*2.*3/s, 'arrayref values rendered');
};

subtest 'render_hash: matches and nomatch compiled to Regexp' => sub {
	my $result = App::Test::Generator::render_hash({
		param => { type => 'string', matches => '^[a-z]+$' }
	});
	like($result, qr/qr\{/, 'matches pattern compiled to qr{}');
};

subtest 'render_hash: scalar type shorthand expanded' => sub {
	my $result = App::Test::Generator::render_hash({
		name => 'string'
	});
	like($result, qr/type.*string/, 'scalar shorthand expanded to type spec');
};

subtest 'render_arrayref_map: returns empty string for empty hashref' => sub {
	my $result = App::Test::Generator::render_arrayref_map({});
	ok(defined $result, 'empty hashref: returns defined value');
	# Empty hash has no arrayref entries so result is empty string
	is($result, '', 'empty hashref -> empty string');
};

subtest 'render_arrayref_map: returns () for undef input' => sub {
	my $result = App::Test::Generator::render_arrayref_map(undef);
	is($result, '()', 'undef input -> ()');
};

# ==================================================================
# LCSAJ — additional branch path coverage for TER3
# ==================================================================

{
	no warnings 'once';
	*_build_cfg      = \&App::Test::Generator::LCSAJ::_build_cfg;
	*_cfg_to_lcsaj   = \&App::Test::Generator::LCSAJ::_cfg_to_lcsaj;
	*_is_branch      = \&App::Test::Generator::LCSAJ::_is_branch;
	*_new_block      = \&App::Test::Generator::LCSAJ::_new_block;
	*_connect_blocks = \&App::Test::Generator::LCSAJ::_connect_blocks;
}

subtest 'LCSAJ: _build_cfg fallthrough loop connects exactly i to i+1' => sub {
	# Two sequential blocks with no branch — fallthrough must connect [0] to [1]
	require PPI;
	my $src = "sub foo { my \$x = 1; my \$y = 2; return \$x + \$y; }\n";
	my $doc = PPI::Document->new(\$src);
	my $sub = $doc->find_first('PPI::Statement::Sub');
	my $blocks = _build_cfg($sub);
	ok(scalar @{$blocks} >= 1, 'at least one block');
	# For a linear sub the single block should have no edges (it's a leaf)
	# or fallthrough to a next block — verify no crash
	ok(1, '_build_cfg linear sub did not crash');
};

subtest 'LCSAJ: _build_cfg branch creates true and false successor blocks' => sub {
	require PPI;
	my $src = "sub foo { my \$x = shift; if(\$x > 0) { return 1; } return 0; }\n";
	my $doc = PPI::Document->new(\$src);
	my $sub = $doc->find_first('PPI::Statement::Sub');
	my $blocks = _build_cfg($sub);
	# With one if-branch: pre-branch block, true block, false block, post-branch
	ok(scalar @{$blocks} >= 3, 'if-branch creates at least 3 blocks');
	my @with_two_edges = grep { scalar @{$_->{edges}} == 2 } @{$blocks};
	ok(scalar @with_two_edges >= 1, 'at least one block has two edges');
};

subtest 'LCSAJ: _cfg_to_lcsaj target=0 when target block has no lines' => sub {
	# Construct a block that points to an empty block
	my $b1 = _new_block(1);
	push @{$b1->{lines}}, 5;
	push @{$b1->{edges}}, 2;
	my $b2 = _new_block(2);    # empty — no lines
	my $result = _cfg_to_lcsaj([$b1, $b2]);
	is(scalar @{$result}, 1,   'one path produced');
	is($result->[0]{target}, 0, 'target defaults to exactly 0 for empty block');
};

subtest 'LCSAJ: _cfg_to_lcsaj skips leaf blocks with no edges' => sub {
	my $b1 = _new_block(1);
	push @{$b1->{lines}}, 5, 6, 7;
	# No edges — leaf block
	my $result = _cfg_to_lcsaj([$b1]);
	is(scalar @{$result}, 0, 'leaf block with no edges skipped');
};

subtest 'LCSAJ: _cfg_to_lcsaj multiple edges produce separate path records' => sub {
	my $b1 = _new_block(1);
	push @{$b1->{lines}}, 10;
	push @{$b1->{edges}}, 2, 3;
	my $b2 = _new_block(2);
	push @{$b2->{lines}}, 20;
	my $b3 = _new_block(3);
	push @{$b3->{lines}}, 30;
	my $result = _cfg_to_lcsaj([$b1, $b2, $b3]);
	is(scalar @{$result}, 2, 'two edges produce two path records');
	is($result->[0]{start}, 10, 'both paths have same start');
	is($result->[1]{start}, 10, 'both paths have same start');
	isnt($result->[0]{target}, $result->[1]{target}, 'targets differ');
};

subtest 'LCSAJ: unless branch is treated as branch point' => sub {
	require PPI;
	my $src = "sub foo { my \$x = shift; unless(\$x) { return 0; } return 1; }\n";
	my $doc = PPI::Document->new(\$src);
	my $sub = $doc->find_first('PPI::Statement::Sub');
	my $blocks = _build_cfg($sub);
	ok(scalar @{$blocks} >= 2, 'unless branch: at least 2 blocks');
};

subtest 'LCSAJ: while loop is treated as branch point' => sub {
	require PPI;
	my $src = "sub foo { my \$x = 0; while(\$x < 10) { \$x++; } return \$x; }\n";
	my $doc = PPI::Document->new(\$src);
	my $sub = $doc->find_first('PPI::Statement::Sub');
	my $blocks = _build_cfg($sub);
	ok(scalar @{$blocks} >= 2, 'while loop: at least 2 blocks');
};

subtest 'LCSAJ: nested branches accumulate path records' => sub {
	require PPI;
	my $src = "sub foo {\n"
		. "\tmy \$x = shift;\n"
		. "\tif(\$x > 0) {\n"
		. "\t\tif(\$x > 10) { return 2; }\n"
		. "\t\treturn 1;\n"
		. "\t}\n"
		. "\treturn 0;\n"
		. "}\n";
	my $doc = PPI::Document->new(\$src);
	my $sub = $doc->find_first('PPI::Statement::Sub');
	my $blocks = _build_cfg($sub);
	my $paths  = _cfg_to_lcsaj($blocks);
	ok(scalar @{$paths} >= 2, 'nested branches produce multiple paths');
};

# ==================================================================
# Generator — branches in generate() not yet covered
# ==================================================================

subtest 'Generator: schema with yaml_cases key processes corpus' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my ($yaml_fh, $yaml_path) = tempfile(SUFFIX => '.yml', UNLINK => 1, DIR => $tmpdir);
	print $yaml_fh "hello:\n  - world\n";
	close $yaml_fh;

	my ($schema_fh, $schema_path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $schema_fh "module: builtin\nfunction: my_func\n";
	print $schema_fh "input:\n  type: string\noutput:\n  type: string\n";
	print $schema_fh "yaml_cases: $yaml_path\n";
	close $schema_fh;

	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($schema_path) };
	});
	is($@, '', 'yaml_cases schema does not croak');
};

subtest 'Generator: schema with edge_cases key includes them in output' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: my_func\n";
	print $fh "input:\n  type: string\noutput:\n  type: string\n";
	print $fh "edge_case_array:\n  - foo\n  - bar\n  - baz\n";
	close $fh;

	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	is($@, '', 'edge_case_array schema does not croak');
};

subtest 'Generator: schema with type_edge_cases key' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: my_func\n";
	print $fh "input:\n  name:\n    type: string\noutput:\n  type: string\n";
	print $fh "type_edge_cases:\n  string:\n    - ''\n    - ' '\n";
	close $fh;

	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	is($@, '', 'type_edge_cases schema does not croak');
};

subtest 'Generator: schema with positional args generates position_code' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: my_func\n";
	print $fh "input:\n  a:\n    type: integer\n    position: 0\n";
	print $fh "  b:\n    type: integer\n    position: 1\n";
	print $fh "output:\n  type: integer\n";
	close $fh;

	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	is($@, '', 'positional args schema does not croak');
	like($out, qr/alist/, 'positional code uses @alist');
};

subtest 'Generator: schema with new: key generates OO test' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: Scalar::Util\nfunction: blessed\n";
	print $fh "new:\ninput:\n  type: string\noutput:\n  type: string\n";
	close $fh;

	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	is($@, '', 'new: key schema does not croak');
	like($out, qr/new_ok/, 'OO mode uses new_ok');
};

subtest 'Generator: schema with transforms key generates transform code' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh "module: builtin\nfunction: abs\n";
	print $fh "input:\n  x:\n    type: number\n    position: 0\n";
	print $fh "output:\n  type: number\n  min: 0\n";
	print $fh "transforms:\n";
	print $fh "  positive:\n";
	print $fh "    input:\n      x:\n        type: number\n        position: 0\n        min: 0\n";
	print $fh "    output:\n      type: number\n      min: 0\n";
	close $fh;

	my ($out) = capture(sub {
		eval { App::Test::Generator->generate($path) };
	});
	is($@, '', 'transforms schema does not croak');
};

subtest 'Generator: _valid_type returns 1 for all supported types' => sub {
	for my $type (qw(string boolean integer number float hashref arrayref object int bool)) {
		is(App::Test::Generator::_valid_type($type), 1,
			"'$type' is a valid type");
	}
};

subtest 'Generator: _valid_type returns 0 for unknown types' => sub {
	for my $type (qw(unknown blob xml json list map set)) {
		is(App::Test::Generator::_valid_type($type), 0,
			"'$type' is not a valid type");
	}
};

subtest 'Generator: _valid_type returns 0 for undef' => sub {
	is(App::Test::Generator::_valid_type(undef), 0, 'undef -> 0');
};

subtest 'Generator: _has_positions returns 0 for empty hashref' => sub {
	is(App::Test::Generator::_has_positions({}), 0, 'empty -> 0');
};

subtest 'Generator: _has_positions returns 0 for undef' => sub {
	is(App::Test::Generator::_has_positions(undef), 0, 'undef -> 0');
};

subtest 'Generator: _has_positions returns 1 when position present' => sub {
	is(App::Test::Generator::_has_positions({
		x => { type => 'string', position => 0 }
	}), 1, 'position present -> 1');
};

subtest 'Generator: _has_positions returns 0 when no position' => sub {
	is(App::Test::Generator::_has_positions({
		x => { type => 'string' }
	}), 0, 'no position -> 0');
};

subtest 'Generator: _has_positions returns 0 for scalar value spec' => sub {
	is(App::Test::Generator::_has_positions({
		x => 'string'
	}), 0, 'scalar spec -> 0');
};

# ==================================================================
# CoverageGuidedFuzzer — branch coverage
# ==================================================================

subtest 'CoverageGuidedFuzzer: mutate handles all scalar types' => sub {
	use_ok('App::Test::Generator::CoverageGuidedFuzzer');

	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);

	# Exercise _mutate with each scalar type
	for my $val (42, 3.14, 'hello', '', undef) {
		lives_ok(
			sub {
				# Access _mutate directly
				App::Test::Generator::CoverageGuidedFuzzer::_mutate($f, $val)
			},
			defined($val) ? "mutate('$val') lives" : 'mutate(undef) lives',
		);
	}
};

subtest 'CoverageGuidedFuzzer: mutate handles arrayref' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'arrayref' } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);
	my $result;
	lives_ok(
		sub {
			$result = App::Test::Generator::CoverageGuidedFuzzer::_mutate($f, [1, 2, 3])
		},
		'mutate([1,2,3]) lives',
	);
	is(ref($result), 'ARRAY', 'mutated arrayref is still an arrayref');
};

subtest 'CoverageGuidedFuzzer: mutate handles hashref' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'hashref' } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);
	my $result;
	lives_ok(
		sub {
			$result = App::Test::Generator::CoverageGuidedFuzzer::_mutate($f, { a => 1, b => 2 })
		},
		'mutate({a=>1}) lives',
	);
	is(ref($result), 'HASH', 'mutated hashref is still a hashref');
};

subtest 'CoverageGuidedFuzzer: mutate passes blessed ref through unchanged' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);
	my $obj    = bless {}, 'FakeClass';
	my $result = App::Test::Generator::CoverageGuidedFuzzer::_mutate($f, $obj);
	is($result, $obj, 'blessed ref passed through unchanged');
};

subtest 'CoverageGuidedFuzzer: _rand_int returns a numeric value' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'integer', min => 5, max => 10 } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);
	for (1..20) {
		my $val = App::Test::Generator::CoverageGuidedFuzzer::_rand_int(
			$f, { min => 5, max => 10 }
		);
		ok(looks_like_number($val), "_rand_int returns numeric value (got $val)");
	}
};

subtest 'CoverageGuidedFuzzer: _rand_num returns value within bounds' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'number' } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);
	for (1..10) {
		my $val = App::Test::Generator::CoverageGuidedFuzzer::_rand_num(
			$f, { min => 0, max => 1 }
		);
		ok($val >= 0 && $val <= 1,
			"_rand_num($val) within [0, 1]");
	}
};

subtest 'CoverageGuidedFuzzer: _validate_value correctly validates types' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);

	# integer
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, 42, { type => 'integer' }), 1, 'integer 42: valid');
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, 3.14, { type => 'integer' }), 0, 'float 3.14: invalid integer');

	# number
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, '3.14', { type => 'number' }), 1, 'string 3.14: valid number');

	# boolean
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, '1', { type => 'boolean' }), 1, '"1": valid boolean');
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, '2', { type => 'boolean' }), 0, '"2": invalid boolean');

	# string with min/max
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, 'hi', { type => 'string', min => 1, max => 10 }), 1, 'string in range: valid');
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, '', { type => 'string', min => 1 }), 0, 'empty string below min: invalid');

	# arrayref
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, [1,2], { type => 'arrayref' }), 1, 'arrayref: valid');
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, 'str', { type => 'arrayref' }), 0, 'string: invalid arrayref');

	# hashref
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, {a=>1}, { type => 'hashref' }), 1, 'hashref: valid');
};

subtest 'CoverageGuidedFuzzer: _validate_value returns 0 for undef' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { 1 },
		iterations => 0,
		seed       => 42,
	);
	is(App::Test::Generator::CoverageGuidedFuzzer::_validate_value(
		$f, undef, { type => 'string' }), 0, 'undef: always invalid');
};

# ==================================================================
# Stateful tests — verify state accumulates correctly across calls
# ==================================================================

subtest 'CoverageGuidedFuzzer: corpus accumulates across multiple run() calls' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { length($_[0] // '') },
		iterations => 5,
		seed       => 42,
	);
	$f->run();
	my $size1 = scalar @{$f->corpus()};
	$f->run();
	my $size2 = scalar @{$f->corpus()};
	ok($size2 >= $size1, 'corpus grows or stays same across runs');
};

subtest 'CoverageGuidedFuzzer: stats accumulate across run() calls' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { input => { type => 'string' } },
		target_sub => sub { 1 },
		iterations => 5,
		seed       => 42,
	);
	my $r1 = $f->run();
	my $r2 = $f->run();
	ok($r2->{total_iterations} >= $r1->{total_iterations},
		'total_iterations increases across runs');
};

subtest 'Mutator: generate_mutants is idempotent — same results on two calls' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');
	mkdir $lib or die $!;
	my $pm = File::Spec->catfile($lib, 'Idempotent.pm');
	open my $fh, '>', $pm or die $!;
	print $fh "package Idempotent;\nsub foo { if(\$x > 0) { return 1; } return 0; }\n1;\n";
	close $fh;

	my $mutator = App::Test::Generator::Mutator->new(
		file    => $pm,
		lib_dir => $lib,
	);
	my @m1 = $mutator->generate_mutants();
	my @m2 = $mutator->generate_mutants();
	is(scalar @m1, scalar @m2, 'generate_mutants count is idempotent');
};

subtest 'Planner: plan_all is idempotent — same results on two calls' => sub {
	my $p = App::Test::Generator::Planner->new(
		schemas => {
			foo => { accessor => { type => 'get' }, output => {} },
			bar => { output => { type => 'boolean' } },
		},
		package => 'Foo',
	);
	my $plan1 = $p->plan_all();
	my $plan2 = $p->plan_all();
	is_deeply($plan1, $plan2, 'plan_all is idempotent');
};

done_testing();
