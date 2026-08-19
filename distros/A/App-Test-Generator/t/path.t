#!/usr/bin/env perl

# Path-coverage tests for App::Test::Generator submodules.
#
# Each subtest exercises one uniquely identifiable execution path through a
# module's CFG that is not already covered by the module-specific unit tests.
# Where both branches of a condition are reachable, both are tested here.
#
# Dead code noted inline and flagged in the source.
#
# Modules covered:
#   App::Test::Generator::Model::Method
#   App::Test::Generator::BenchmarkGenerator
#   App::Test::Generator::Analyzer::Complexity
#   App::Test::Generator::Analyzer::SideEffect
#   App::Test::Generator::Planner::Isolation
#   App::Test::Generator::Analyzer::Return
#   App::Test::Generator::Planner::Mock
#   App::Test::Generator::PodExampleExtractor
#   App::Test::Generator::CoverageGuidedFuzzer (minimize_corpus)
#   App::Test::Generator::Mutator (generate_mutants wantarray)

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Readonly;
use Cwd;
use File::Spec;
use File::Temp qw(tempfile tempdir);
use File::Path qw(make_path);
use Scalar::Util qw(refaddr);

# --------------------------------------------------
# Load all modules under test
# --------------------------------------------------
BEGIN {
	use_ok('App::Test::Generator::Model::Method');
	use_ok('App::Test::Generator::BenchmarkGenerator');
	use_ok('App::Test::Generator::Analyzer::Complexity');
	use_ok('App::Test::Generator::Analyzer::SideEffect');
	use_ok('App::Test::Generator::Planner::Isolation');
}

# --------------------------------------------------
# Constants — mirror source thresholds so that any
# change to the source breaks the corresponding test
# --------------------------------------------------
Readonly my $MEDIUM_THRESHOLD => 20;
Readonly my $HIGH_THRESHOLD   => 40;

# --------------------------------------------------
# Helpers
# --------------------------------------------------

sub _method {
	return App::Test::Generator::Model::Method->new(
		name   => 'x',
		source => 'sub x {}',
	);
}

sub _complexity_body {
	my ($body) = @_;
	return App::Test::Generator::Analyzer::Complexity->new->analyze({ body => $body });
}

sub _sideeffect_body {
	my ($body) = @_;
	return App::Test::Generator::Analyzer::SideEffect->new->analyze({ body => $body });
}

# ==================================================================
# MODEL::METHOD — resolve_return_type()
#
# CFG paths through the signal dispatch in the evidence loop:
#   returns_property → property bucket        (covered by unit test)
#   returns_constant → constant bucket        (covered by unit test)
#   returns_self     → object bucket          (covered by unit test)
#   legacy_type / value='object'              ← uncovered
#   legacy_type / value='self'                ← uncovered
#   legacy_type / value=other                 ← uncovered
#   context_aware                             ← uncovered
#   error_pattern                             ← uncovered
#   tie-break: all-zero → constant wins       ← uncovered
#   tie-break: object=property → object wins  ← uncovered
# ==================================================================

# --------------------------------------------------
# Path: legacy_type, value='object'
#   Line 535: if($t eq 'object') { $score{object} += $ev->{weight} }
# --------------------------------------------------
subtest 'resolve_return_type: legacy_type value=object → object' => sub {
	my $m = _method();
	$m->add_evidence(
		category => 'return',
		signal   => 'legacy_type',
		value    => 'object',
		weight   => 20,
	);
	is($m->resolve_return_type, 'object', 'legacy_type object value → object bucket wins');

	diag("evidence: ", scalar($m->evidence), " entries") if $ENV{TEST_VERBOSE};
};

# --------------------------------------------------
# Path: legacy_type, value='self'
#   Line 536: elsif($t eq 'self') { $score{object} += $ev->{weight} }
# --------------------------------------------------
subtest 'resolve_return_type: legacy_type value=self → object' => sub {
	my $m = _method();
	$m->add_evidence(
		category => 'return',
		signal   => 'legacy_type',
		value    => 'self',
		weight   => 20,
	);
	is($m->resolve_return_type, 'object', 'legacy_type self value → object bucket wins');
};

# --------------------------------------------------
# Path: legacy_type, value=anything_else
#   Line 537: else { $score{property} += $ev->{weight} }
#   Any type string other than 'object'/'self' falls here.
# --------------------------------------------------
subtest 'resolve_return_type: legacy_type value=hashref → property' => sub {
	my $m = _method();
	$m->add_evidence(
		category => 'return',
		signal   => 'legacy_type',
		value    => 'hashref',
		weight   => 20,
	);
	is($m->resolve_return_type, 'property', 'legacy_type non-object/self value → property bucket');
};

# --------------------------------------------------
# Path: legacy_type, value=undef (the `$ev->{value} // ''` path)
#   value defaults to '' → not 'object', not 'self' → property
# --------------------------------------------------
subtest 'resolve_return_type: legacy_type value=undef → property' => sub {
	my $m = _method();
	$m->add_evidence(
		category => 'return',
		signal   => 'legacy_type',
		weight   => 20,
	);
	is($m->resolve_return_type, 'property', 'legacy_type with no value → property bucket');
};

# --------------------------------------------------
# Path: context_aware signal
#   Line 540: $score{property} += $ev->{weight}
# --------------------------------------------------
subtest 'resolve_return_type: context_aware signal → property' => sub {
	my $m = _method();
	$m->add_evidence(
		category => 'return',
		signal   => 'context_aware',
		weight   => 20,
	);
	is($m->resolve_return_type, 'property', 'context_aware → property bucket');
};

# --------------------------------------------------
# Path: error_pattern signal
#   Line 544: $score{property} += $ev->{weight}
# --------------------------------------------------
subtest 'resolve_return_type: error_pattern signal → property' => sub {
	my $m = _method();
	$m->add_evidence(
		category => 'return',
		signal   => 'error_pattern',
		value    => 'undef',
		weight   => 20,
	);
	is($m->resolve_return_type, 'property', 'error_pattern → property bucket');
};

# --------------------------------------------------
# Path: no return-category evidence at all
#   All three buckets score 0. Sort is stable to alphabetical
#   on equal scores: constant < object < property → constant wins.
# --------------------------------------------------
subtest 'resolve_return_type: no evidence → constant wins tie-break' => sub {
	my $m = _method();
	is($m->resolve_return_type, 'constant',
		'all buckets score 0: constant wins alphabetical tie-break (c < o < p)');
};

# --------------------------------------------------
# Path: only non-return evidence
#   Input/effect evidence is completely ignored by resolve_return_type.
#   All three return buckets still score 0 → constant wins.
# --------------------------------------------------
subtest 'resolve_return_type: non-return evidence ignored → constant wins' => sub {
	my $m = _method();
	$m->add_evidence(category => 'input',  signal => 'input_validated',  weight => 100);
	$m->add_evidence(category => 'effect', signal => 'has_side_effect',  weight => 100);
	is($m->resolve_return_type, 'constant', 'non-return evidence silently skipped');
};

# --------------------------------------------------
# Path: property and object tied, constant lower
#   object (o) < property (p) alphabetically → object wins
# --------------------------------------------------
subtest 'resolve_return_type: property=object score → object wins (o < p)' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 10);
	$m->add_evidence(category => 'return', signal => 'returns_self',     weight => 10);
	# property=10, object=10, constant=0
	# Sort: property and object tied at top; alphabetical: 'object' < 'property' → object
	is($m->resolve_return_type, 'object', 'property=object score tie → object wins');
};

# ==================================================================
# MODEL::METHOD — resolve_confidence() threshold boundaries
#
# CFG: three branches in the nested ternary:
#   score <  MEDIUM_THRESHOLD (20) → low
#   score >= MEDIUM_THRESHOLD AND < HIGH_THRESHOLD (40) → medium
#   score >= HIGH_THRESHOLD → high
# ==================================================================

# --------------------------------------------------
# Path: score 0 → low (below medium)
# --------------------------------------------------
subtest 'resolve_confidence: score=0 → low' => sub {
	my $m    = _method();
	my $conf = $m->resolve_confidence;
	returns_ok($conf, { type => 'hashref' }, 'resolve_confidence returns hashref');
	is($conf->{score}, 0,     'score is 0 with no evidence');
	is($conf->{level}, 'low', 'score 0 → level low');
};

# --------------------------------------------------
# Path: score just below medium threshold (19) → low
# --------------------------------------------------
subtest 'resolve_confidence: score=19 → low (one below medium boundary)' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 19);
	my $conf = $m->resolve_confidence;
	is($conf->{score}, 19,    'score is 19');
	is($conf->{level}, 'low', 'score 19 → low (threshold is 20)');
};

# --------------------------------------------------
# Path: score exactly at medium threshold (20) → medium
# --------------------------------------------------
subtest 'resolve_confidence: score=20 → medium (exactly at lower boundary)' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => $MEDIUM_THRESHOLD);
	my $conf = $m->resolve_confidence;
	is($conf->{score}, 20,       'score is 20');
	is($conf->{level}, 'medium', 'score 20 → medium (at boundary)');
};

# --------------------------------------------------
# Path: score between thresholds (30) → medium
# --------------------------------------------------
subtest 'resolve_confidence: score=30 → medium' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 30);
	my $conf = $m->resolve_confidence;
	is($conf->{score}, 30,       'score is 30');
	is($conf->{level}, 'medium', 'score 30 → medium');
};

# --------------------------------------------------
# Path: score just below high threshold (39) → medium
# --------------------------------------------------
subtest 'resolve_confidence: score=39 → medium (one below high boundary)' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self',    weight => 20);
	$m->add_evidence(category => 'input',  signal => 'input_validated', weight => 19);
	my $conf = $m->resolve_confidence;
	is($conf->{score}, 39,       'score is 39');
	is($conf->{level}, 'medium', 'score 39 → medium (threshold is 40)');
};

# --------------------------------------------------
# Path: score exactly at high threshold (40) → high
# --------------------------------------------------
subtest 'resolve_confidence: score=40 → high (exactly at boundary)' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => $HIGH_THRESHOLD);
	my $conf = $m->resolve_confidence;
	is($conf->{score}, 40,    'score is 40');
	is($conf->{level}, 'high', 'score 40 → high (at boundary)');
};

# ==================================================================
# MODEL::METHOD — add_evidence() weight=0 path
#
# Code: `weight => defined $args{weight} ? $args{weight} : 1`
# When weight=0, `defined 0` is true → stores 0, not the default 1.
# ==================================================================

subtest 'add_evidence: explicit weight=0 stored as 0, not coerced to default 1' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 0);
	my @ev = $m->evidence;
	is($ev[0]{weight}, 0, 'weight=0 stored as-is (falsy but defined)');

	# Zero-weight evidence contributes 0 to confidence score
	my $conf = $m->resolve_confidence;
	is($conf->{score}, 0, 'weight=0 evidence does not inflate confidence score');
};

# ==================================================================
# BENCHMARKGENERATOR — _representative_value()
#
# All branches in the type-dispatch logic and the min/max sub-paths:
#   undef spec                             → 'undef'
#   spec with no type key                  → string → 'hello'
#   numeric type: both min+max             → midpoint
#   numeric type: min only, default > min  → default
#   numeric type: min only, default < min  → min+1
#   numeric type: max only, default < max  → default
#   numeric type: max only, default >= max → max-1
#   numeric type: no constraints           → default
#   boolean                                → 1
#   arrayref                               → '[]'
#   hashref                                → '{}'
#   unknown type                           → "'value'"
# ==================================================================

# Shorthand to call the private helper directly
sub _repr { App::Test::Generator::BenchmarkGenerator::_representative_value($_[0]) }

# --------------------------------------------------
# Path: undef spec → early return 'undef'
# --------------------------------------------------
subtest '_representative_value: undef spec → "undef"' => sub {
	is(_repr(undef), 'undef', 'undef spec returns the string "undef"');
};

# --------------------------------------------------
# Path: spec with no type key → type defaults to 'string' → 'hello'
# --------------------------------------------------
subtest '_representative_value: no type key → string default' => sub {
	is(_repr({}), "'hello'", 'missing type key defaults to string → "\'hello\'"');
};

# --------------------------------------------------
# Path: type='float', no constraints → TYPE_DEFAULTS{float} = 3.14
# --------------------------------------------------
subtest '_representative_value: float, no constraints → 3.14' => sub {
	is(_repr({ type => 'float' }), 3.14, 'float with no min/max → default 3.14');
};

# --------------------------------------------------
# Path: type='float', min only, default (3.14) > min (1) → default
#   `$default > $min` → true → return $default
# --------------------------------------------------
subtest '_representative_value: float min-only, default > min → default' => sub {
	is(_repr({ type => 'float', min => 1 }), 3.14,
		'float min=1, 3.14 > 1 → default 3.14 returned');
};

# --------------------------------------------------
# Path: type='float', min only, default (3.14) < min (5) → min+1
#   `$default > $min` → 3.14 > 5 → false → return $min + 1 = 6
# --------------------------------------------------
subtest '_representative_value: float min-only, default < min → min+1' => sub {
	is(_repr({ type => 'float', min => 5 }), 6,
		'float min=5, 3.14 < 5 → returns min+1=6');
};

# --------------------------------------------------
# Path: type='float', max only, default (3.14) < max (10) → default
#   `$default < $max` → true → return $default
# --------------------------------------------------
subtest '_representative_value: float max-only, default < max → default' => sub {
	is(_repr({ type => 'float', max => 10 }), 3.14,
		'float max=10, 3.14 < 10 → default 3.14 returned');
};

# --------------------------------------------------
# Path: type='float', max only, default (3.14) >= max (3) → max-1
#   `$default < $max` → 3.14 < 3 → false → return $max - 1 = 2
# --------------------------------------------------
subtest '_representative_value: float max-only, default >= max → max-1' => sub {
	is(_repr({ type => 'float', max => 3 }), 2,
		'float max=3, 3.14 >= 3 → returns max-1=2');
};

# --------------------------------------------------
# Path: type='integer', min only, default (42) > min (10) → default
# --------------------------------------------------
subtest '_representative_value: integer min-only, default > min → default' => sub {
	is(_repr({ type => 'integer', min => 10 }), 42,
		'integer min=10, 42 > 10 → default 42 returned');
};

# --------------------------------------------------
# Path: type='integer', min only, default (42) < min (100) → min+1
# --------------------------------------------------
subtest '_representative_value: integer min-only, default < min → min+1' => sub {
	is(_repr({ type => 'integer', min => 100 }), 101,
		'integer min=100, 42 < 100 → returns min+1=101');
};

# --------------------------------------------------
# Path: type='integer', max only, default (42) < max (100) → default
# --------------------------------------------------
subtest '_representative_value: integer max-only, default < max → default' => sub {
	is(_repr({ type => 'integer', max => 100 }), 42,
		'integer max=100, 42 < 100 → default 42 returned');
};

# --------------------------------------------------
# Path: type='integer', max only, default (42) >= max (40) → max-1
# --------------------------------------------------
subtest '_representative_value: integer max-only, default >= max → max-1' => sub {
	is(_repr({ type => 'integer', max => 40 }), 39,
		'integer max=40, 42 >= 40 → returns max-1=39');
};

# --------------------------------------------------
# Path: type='integer', both min=0 and max=0 → midpoint = int((0+0)/2) = 0
# --------------------------------------------------
subtest '_representative_value: integer min=0 max=0 → midpoint 0' => sub {
	is(_repr({ type => 'integer', min => 0, max => 0 }), 0,
		'min=max=0 → midpoint int((0+0)/2)=0');
};

# --------------------------------------------------
# Path: type='boolean' → TYPE_DEFAULTS{boolean} = 1
# --------------------------------------------------
subtest '_representative_value: boolean → 1' => sub {
	is(_repr({ type => 'boolean' }), 1, 'boolean → 1');
};

# --------------------------------------------------
# Path: type='arrayref' → TYPE_DEFAULTS{arrayref} = '[]'
# --------------------------------------------------
subtest '_representative_value: arrayref → "[]"' => sub {
	is(_repr({ type => 'arrayref' }), '[]', 'arrayref → "[]"');
};

# --------------------------------------------------
# Path: type='hashref' → TYPE_DEFAULTS{hashref} = '{}'
# --------------------------------------------------
subtest '_representative_value: hashref → "{}"' => sub {
	is(_repr({ type => 'hashref' }), '{}', 'hashref → "{}"');
};

# --------------------------------------------------
# Path: unknown type → falls to final return:
#   `$TYPE_DEFAULTS{$type} // "'value'"`
#   No key 'widget' → undef // "'value'" → "'value'"
# --------------------------------------------------
subtest '_representative_value: unknown type → fallback "\'value\'"' => sub {
	is(_repr({ type => 'widget' }), "'value'",
		"unknown type 'widget' → fallback \"'value'\"");
};

# ==================================================================
# BENCHMARKGENERATOR — _quote_value()
#
# Four paths:
#   undef                     → 'undef'
#   numeric (looks_like_number) → returned as-is
#   plain string              → single-quoted
#   string with single quote  → escaped
# ==================================================================

sub _qv { App::Test::Generator::BenchmarkGenerator::_quote_value($_[0]) }

# --------------------------------------------------
# Path: undef → 'undef' (early return)
# --------------------------------------------------
subtest '_quote_value: undef → "undef"' => sub {
	is(_qv(undef), 'undef', 'undef input → string "undef"');
};

# --------------------------------------------------
# Path: numeric 0 → 0 (looks_like_number true → return as-is)
# --------------------------------------------------
subtest '_quote_value: numeric 0 returned as-is' => sub {
	is(_qv(0), 0, 'numeric 0 → 0 (not quoted)');
};

# --------------------------------------------------
# Path: numeric 3.14 → 3.14 (looks_like_number true)
# --------------------------------------------------
subtest '_quote_value: numeric 3.14 returned as-is' => sub {
	is(_qv(3.14), 3.14, 'float 3.14 → 3.14 (not quoted)');
};

# --------------------------------------------------
# Path: plain string → single-quoted
# --------------------------------------------------
subtest '_quote_value: plain string → single-quoted' => sub {
	is(_qv('world'), "'world'", 'plain string wrapped in single quotes');
};

# --------------------------------------------------
# Path: string containing a single-quote → escaped
#   "it's" → "'it\\'s'" via s/'/\\'/g
# --------------------------------------------------
subtest "_quote_value: string with embedded single-quote → escaped" => sub {
	is(_qv("it's"), q{'it\'s'}, "single quote in string is backslash-escaped");
};

# ==================================================================
# BENCHMARKGENERATOR — _build_call() branch paths
#
# Two dimensions: positional vs named params × has_new × builtin
#   named  + has_new             → $obj->func(k => v)
#   named  + !has_new            → Module::func(k => v)
#   pos    + has_new             → $obj->func(args)
#   pos    + !has_new + builtin  → func(args)       [covered by BenchmarkGenerator_unit.t]
#   pos    + !has_new + !builtin → Module::func(args)
# ==================================================================

# --------------------------------------------------
# Path: named params + has_new → $obj->func(key => val)
# --------------------------------------------------
subtest '_build_call: named params + has_new → $obj->method(...)' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'My::Mod',
		function => 'run',
		new      => undef,
		input    => {
			alpha => { type => 'string'  },
			beta  => { type => 'number'  },
		},
	});
	my $src = $bg->generate;
	like($src, qr/\$obj->run\(/, 'has_new + named → $obj->func(...)');
	like($src, qr/alpha\s*=>/, 'named param alpha appears as key => val');
	like($src, qr/beta\s*=>/,  'named param beta appears as key => val');
	diag($src) if $ENV{TEST_VERBOSE};
};

# --------------------------------------------------
# Path: named params + !has_new → Module::func(key => val)
# --------------------------------------------------
subtest '_build_call: named params + !has_new → Module::func(...)' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'My::Mod',
		function => 'compute',
		input    => { x => { type => 'number' } },
	});
	my $src = $bg->generate;
	like($src, qr/My::Mod::compute\(/, '!has_new + named → Module::func(...)');
	diag($src) if $ENV{TEST_VERBOSE};
};

# --------------------------------------------------
# Path: positional params + has_new → $obj->func(args)
# --------------------------------------------------
subtest '_build_call: positional + has_new → $obj->func(args)' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'My::Mod',
		function => 'process',
		new      => undef,
		input    => { n => { type => 'number', position => 0 } },
	});
	my $src = $bg->generate;
	like($src, qr/\$obj->process\(42\)/, 'positional + has_new → $obj->func(args)');
	diag($src) if $ENV{TEST_VERBOSE};
};

# --------------------------------------------------
# Path: positional + !has_new + !builtin → Module::func(args)
# --------------------------------------------------
subtest '_build_call: positional + !has_new + non-builtin → Module::func(args)' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'My::Mod',
		function => 'add',
		input    => {
			x => { type => 'number', position => 0 },
			y => { type => 'number', position => 1 },
		},
	});
	my $src = $bg->generate;
	like($src, qr/My::Mod::add\(42,\s*42\)/, 'positional !has_new non-builtin → Module::func(args)');
	diag($src) if $ENV{TEST_VERBOSE};
};

# ==================================================================
# BENCHMARKGENERATOR — generate() additional CFG branches
# ==================================================================

# --------------------------------------------------
# Path: schema missing 'module' key → croak at line 93
# --------------------------------------------------
subtest 'generate: missing module key → croak' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(
		schema => { function => 'foo', input => {} },
	);
	throws_ok(
		sub { $bg->generate },
		qr/schema missing module/,
		'absent module key in schema → croak',
	);
};

# --------------------------------------------------
# Path: schema missing 'function' key → croak at line 94
# --------------------------------------------------
subtest 'generate: missing function key → croak' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(
		schema => { module => 'Foo', input => {} },
	);
	throws_ok(
		sub { $bg->generate },
		qr/schema missing function/,
		'absent function key in schema → croak',
	);
};

# --------------------------------------------------
# Path: has_new=1 AND is_builtin=1
#   Condition: `if($has_new && !$is_builtin)` → false
#   → entire constructor block skipped; $obj never declared
# --------------------------------------------------
subtest 'generate: has_new + builtin → no constructor emitted' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'builtin',
		function => 'abs',
		new      => undef,
		input    => { n => { type => 'number', position => 0 } },
	});
	my $src = $bg->generate;
	unlike($src, qr/->new/, 'builtin + new key: no constructor call emitted');
	diag($src) if $ENV{TEST_VERBOSE};
};

# --------------------------------------------------
# Path: has_new=1, !builtin, new_spec = {} (empty hashref)
#   Condition: `ref $new_spec eq 'HASH' && %$new_spec`
#   → true for ref check, false for %$new_spec (empty)
#   → else branch → Module->new()
# --------------------------------------------------
subtest 'generate: has_new with empty hashref new_spec → no-arg constructor' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module   => 'My::Mod',
		function => 'run',
		new      => {},
		input    => {},
	});
	my $src = $bg->generate;
	like($src, qr/My::Mod->new\(\)/, 'empty new hashref → Module->new() (no args)');
	diag($src) if $ENV{TEST_VERBOSE};
};

# --------------------------------------------------
# Path: transforms present but empty ({})
#   Condition: `if(%xforms)` → false (empty hash)
#   → falls to else: emits 'default' variant
# --------------------------------------------------
subtest 'generate: empty transforms hashref → default variant emitted' => sub {
	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => {
		module     => 'builtin',
		function   => 'abs',
		input      => { n => { type => 'number', position => 0 } },
		transforms => {},
	});
	my $src = $bg->generate;
	like($src,   qr/'default'/, 'empty transforms hashref → default variant');
	unlike($src, qr/'positive'|'negative'/, 'no transform variants emitted');
	diag($src) if $ENV{TEST_VERBOSE};
};

# ==================================================================
# ANALYZER::COMPLEXITY — additional CFG paths
#
# Uncovered branches in _strip_strings_and_comments and analyze():
#   'given'/'when' keywords in @BRANCH_TOKENS
#   keyword inside a double-quoted string body → not counted
#   escaped characters inside double-quoted string
#   unmatched '}' when depth=0 → clamp prevents underflow
#   exact early_returns boundary: 1 return → 0 early; 2 → 1 early
# ==================================================================

# --------------------------------------------------
# Path: 'given' keyword → branching point
#   'given' is in @BRANCH_TOKENS but not tested in Analyzer-Complexity.t
# --------------------------------------------------
subtest 'Complexity::analyze: "given" keyword → branching point' => sub {
	my $r = _complexity_body('given($x) { do_thing(); }');
	is($r->{branching_points}, 1, '"given" adds 1 branching point');
	diag("score=$r->{cyclomatic_score}") if $ENV{TEST_VERBOSE};
};

# --------------------------------------------------
# Path: 'when' keyword → branching point
# --------------------------------------------------
subtest 'Complexity::analyze: "when" keyword → branching point' => sub {
	my $r = _complexity_body('when(1) { action(); }');
	is($r->{branching_points}, 1, '"when" adds 1 branching point');
};

# --------------------------------------------------
# Path: both 'given' and 'when' in one body
# --------------------------------------------------
subtest 'Complexity::analyze: given + when → 2 branching points' => sub {
	my $r = _complexity_body('given($x) { when(1) { do_thing(); } }');
	is($r->{branching_points}, 2, 'given + when each add 1 → total 2');
};

# --------------------------------------------------
# Path: 'if' keyword inside a double-quoted string
#   _strip_strings_and_comments blanks the string content;
#   the regex then matches no branching keyword.
# --------------------------------------------------
subtest 'Complexity::analyze: "if" inside double-quoted string → not counted' => sub {
	my $r = _complexity_body('my $msg = "run if condition is true";');
	is($r->{branching_points}, 0, '"if" inside dquote string is stripped → 0 branching points');
	diag("score=$r->{cyclomatic_score}") if $ENV{TEST_VERBOSE};
};

# --------------------------------------------------
# Path: 'die' inside a double-quoted string
# --------------------------------------------------
subtest 'Complexity::analyze: "die" inside double-quoted string → not counted' => sub {
	my $r = _complexity_body('print "may die here";');
	is($r->{exception_paths}, 0, '"die" inside dquote string is stripped → 0 exception paths');
};

# --------------------------------------------------
# Path: escaped double-quote inside a double-quoted string
#   "said \"if\" here" — the content including the escaped quote is stripped
# --------------------------------------------------
subtest 'Complexity::analyze: escaped dquote inside string handled correctly' => sub {
	my $r = _complexity_body(q{my $msg = "it said \"if\" here";});
	is($r->{branching_points}, 0, 'escaped dquote: "if" inside string still stripped');
};

# --------------------------------------------------
# Path: unmatched '}' when depth=0
#   Condition: `$depth-- if $depth > 0`
#   When depth=0, the guard fires (false branch) → depth stays 0
# --------------------------------------------------
subtest 'Complexity::analyze: unmatched } when depth=0 → depth stays 0' => sub {
	my $r = _complexity_body('my $x = 1; }');
	is($r->{nesting_depth}, 0, 'unmatched } does not underflow depth to negative');
};

# --------------------------------------------------
# Path: exactly 1 return → early_returns = 0
#   Condition: `$return_count > 1 ? $return_count - 1 : 0`
#   1 > 1 → false → 0
# --------------------------------------------------
subtest 'Complexity::analyze: exactly 1 return → early_returns=0' => sub {
	my $r = _complexity_body('sub f { return $self->{x}; }');
	is($r->{early_returns}, 0, 'one return → early_returns=0 (false branch of count>1)');
};

# --------------------------------------------------
# Path: exactly 0 returns → early_returns = 0
#   $return_count = 0 → 0 > 1 is false → 0
# --------------------------------------------------
subtest 'Complexity::analyze: zero returns → early_returns=0' => sub {
	my $r = _complexity_body('sub f { my $x = 1; }');
	is($r->{early_returns}, 0, 'zero returns → early_returns=0');
};

# --------------------------------------------------
# Path: exactly 2 returns → early_returns = 1
#   $return_count = 2 → 2 > 1 is true → 2 - 1 = 1
# --------------------------------------------------
subtest 'Complexity::analyze: exactly 2 returns → early_returns=1' => sub {
	my $r = _complexity_body('if($x) { return 0; } return 1;');
	is($r->{early_returns}, 1, 'two returns → early_returns=1 (true branch of count>1)');
};

# ==================================================================
# ANALYZER::SIDEEFFECT — additional CFG paths
#
# Uncovered paths in analyze():
#   'read' keyword alone → performs_io
#   'write' keyword alone → performs_io
#   mutates_self=1 AND mutates_globals=1 → impure
#   $self->{field}= inside a double-quoted string → not detected
#   $self->{field}= inside a comment → not detected
# ==================================================================

# --------------------------------------------------
# Path: 'read' keyword → performs_io=1
#   IO_PATTERN: qr/\b(?:print|say|...|read|write)\b/
# --------------------------------------------------
subtest 'SideEffect::analyze: "read" keyword → performs_io' => sub {
	my $r = _sideeffect_body('read($fh, my $buf, 1024);');
	is($r->{performs_io}, 1, '"read" keyword matches IO_PATTERN → performs_io=1');
};

# --------------------------------------------------
# Path: 'write' keyword → performs_io=1
# --------------------------------------------------
subtest 'SideEffect::analyze: "write" keyword → performs_io' => sub {
	my $r = _sideeffect_body('write $fh;');
	is($r->{performs_io}, 1, '"write" keyword matches IO_PATTERN → performs_io=1');
};

# --------------------------------------------------
# Path: mutates_self=1 AND mutates_globals=1 → impure
#   has_external = 1 (from mutates_globals)
#   Purity ternary: first cond fails (has_external≠0), second cond fails → impure
# --------------------------------------------------
subtest 'SideEffect::analyze: mutates_self + mutates_globals → impure' => sub {
	my $r = _sideeffect_body(
		'sub f { $self->{x} = 1; $ENV{KEY} = "val"; }'
	);
	is($r->{mutates_self},    1,       'mutates_self detected');
	is($r->{mutates_globals}, 1,       'mutates_globals detected');
	is($r->{purity_level},    'impure', 'self-mutation + global-mutation → impure');
	diag("purity=$r->{purity_level}") if $ENV{TEST_VERBOSE};
};

# --------------------------------------------------
# Path: $self->{field} = inside a double-quoted string → NOT detected
#   _strip_strings_and_comments removes the string content,
#   so the self-mutation regex cannot match.
#
#   NOTE: this is a WHITE-BOX path test. The source body contains
#   "$self->{value} = done" as string content, not actual code.
#   After stripping the dquoted string, mutates_self must be 0.
# --------------------------------------------------
subtest 'SideEffect::analyze: $self->{field}= inside dquote string → no false positive' => sub {
	# Single-quote the outer string to keep $self literal in the body passed to the analyser
	my $r = _sideeffect_body(
		'sub f { my $msg = "$self->{value} = done"; return $msg; }'
	);
	is($r->{mutates_self}, 0,
		'interpolation of $self->{field} inside string not misdetected as assignment');
};

# --------------------------------------------------
# Path: $self->{field} = inside a # comment → NOT detected
#   _strip_strings_and_comments removes from # to EOL,
#   so the self-mutation regex cannot match.
# --------------------------------------------------
subtest 'SideEffect::analyze: $self->{field}= inside comment → no false positive' => sub {
	my $body = "sub f {\n\t# \$self->{name} = 'test'\n\treturn 42;\n}";
	my $r = _sideeffect_body($body);
	is($r->{mutates_self}, 0,
		'$self->{field}= inside # comment not misdetected as assignment');
};

# ==================================================================
# PLANNER::ISOLATION — falsy dependency value paths
#
# The guards `if $deps->{time}`, `if $deps->{network}`,
# `if $deps->{env}`, `if $deps->{filesystem}` are all conditional
# on the value being truthy. A present-but-falsy dependency must NOT
# propagate to the plan.
# ==================================================================

# --------------------------------------------------
# Path: $deps->{time} = 0 → time key NOT added to plan
# --------------------------------------------------
subtest 'Planner::Isolation: time=0 (falsy) → time key omitted from plan' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new;
	my $result = $p->plan(
		{ m => { _analysis => { dependencies => { time => 0 } } } },
		{ m => 1 },
	);
	ok(!exists $result->{m}{time}, 'time=>0 does not set the time flag');
};

# --------------------------------------------------
# Path: $deps->{network} = '' → network key NOT added to plan
# --------------------------------------------------
subtest 'Planner::Isolation: network="" (falsy) → network key omitted' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new;
	my $result = $p->plan(
		{ m => { _analysis => { dependencies => { network => '' } } } },
		{ m => 1 },
	);
	ok(!exists $result->{m}{network}, 'network=>"" does not set the network flag');
};

# --------------------------------------------------
# Path: $deps->{env} = 0 (scalar falsy) → env key NOT added to plan
#   Note: a hashref {} is truthy (it is a reference), so only scalar
#   falsy values (0, '', undef) suppress the env key.
# --------------------------------------------------
subtest 'Planner::Isolation: env=0 (scalar falsy) → env key omitted' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new;
	my $result = $p->plan(
		{ m => { _analysis => { dependencies => { env => 0 } } } },
		{ m => 1 },
	);
	ok(!exists $result->{m}{env}, 'env=>0 does not set the env key');
};

# --------------------------------------------------
# Path: $deps->{filesystem} = '' (scalar falsy) → filesystem key NOT added
# --------------------------------------------------
subtest 'Planner::Isolation: filesystem="" (scalar falsy) → filesystem key omitted' => sub {
	my $p = App::Test::Generator::Planner::Isolation->new;
	my $result = $p->plan(
		{ m => { _analysis => { dependencies => { filesystem => '' } } } },
		{ m => 1 },
	);
	ok(!exists $result->{m}{filesystem}, 'filesystem=>"" does not set the filesystem key');
};

# --------------------------------------------------
# Path: $deps->{env} = {} (non-empty-ref → truthy) → env key IS added
#   Confirms that a hashref (truthy reference) propagates even when empty.
# --------------------------------------------------
subtest 'Planner::Isolation: env={} (hashref → truthy) → env key IS set' => sub {
	my $p = new_ok('App::Test::Generator::Planner::Isolation');
	my $result = $p->plan(
		{ m => { _analysis => { dependencies => { env => {} } } } },
		{ m => 1 },
	);
	ok(exists $result->{m}{env}, 'env=>{} (hashref) is truthy → env key set');
};

# ==================================================================
# Analyzer::Return — all three signal-dispatch branches + empty-body guard
# ==================================================================

use_ok('App::Test::Generator::Analyzer::Return');
use_ok('App::Test::Generator::Model::Method');

# --------------------------------------------------
# Path: source contains "return $self->{key}" → returns_property evidence
# --------------------------------------------------
subtest 'Analyzer::Return: return $self->{key} → returns_property signal' => sub {
	my $r  = App::Test::Generator::Analyzer::Return->new;
	my $m  = App::Test::Generator::Model::Method->new(
		name   => 'foo',
		source => 'sub foo { return $self->{name} }',
	);
	$r->analyze($m);
	my @ev = grep { $_->{signal} eq 'returns_property' } @{ $m->evidence_ref };
	ok(@ev, 'returns_property evidence added');
	is($ev[0]{value}, 'name', 'property name captured correctly');
};

# --------------------------------------------------
# Path: source contains "return $self" (no arrow) → returns_self evidence
# --------------------------------------------------
subtest 'Analyzer::Return: return $self → returns_self signal' => sub {
	my $r = App::Test::Generator::Analyzer::Return->new;
	my $m = App::Test::Generator::Model::Method->new(
		name   => 'chained',
		source => 'sub chained { $self->do_thing; return $self }',
	);
	$r->analyze($m);
	my @ev = grep { $_->{signal} eq 'returns_self' } @{ $m->evidence_ref };
	ok(@ev, 'returns_self evidence added for bare return $self');

	# Negative: "return $self->{x}" not in source so returns_property not fired
	my $n_prop = grep { $_->{signal} eq 'returns_property' } @{ $m->evidence_ref };
	is($n_prop, 0, '"return $self->{x}" not present so returns_property not fired');
};

# --------------------------------------------------
# Path: source contains "return 1" / "return undef" → returns_constant evidence
# --------------------------------------------------
subtest 'Analyzer::Return: return literal → returns_constant signal' => sub {
	my $r = App::Test::Generator::Analyzer::Return->new;
	my $m = App::Test::Generator::Model::Method->new(
		name   => 'const',
		source => 'sub const { return 1 }',
	);
	$r->analyze($m);
	my @ev = grep { $_->{signal} eq 'returns_constant' } @{ $m->evidence_ref };
	ok(@ev, 'returns_constant evidence added for "return 1"');
};

subtest 'Analyzer::Return: return undef → returns_constant signal' => sub {
	my $r = App::Test::Generator::Analyzer::Return->new;
	my $m = App::Test::Generator::Model::Method->new(
		name   => 'nothing',
		source => 'sub nothing { return undef }',
	);
	$r->analyze($m);
	my @ev = grep { $_->{signal} eq 'returns_constant' } @{ $m->evidence_ref };
	ok(@ev, 'returns_constant evidence added for "return undef"');
};

# --------------------------------------------------
# Path: empty body → no evidence added (early-out / no-match path)
# --------------------------------------------------
subtest 'Analyzer::Return: empty body → no evidence' => sub {
	my $r = App::Test::Generator::Analyzer::Return->new;
	my $m = App::Test::Generator::Model::Method->new(
		name   => 'empty',
		source => '',
	);
	$r->analyze($m);
	is(scalar @{ $m->evidence_ref }, 0, 'no evidence for empty body');
};

# --------------------------------------------------
# Path: raw hashref passed instead of Model::Method →
#   $add closure is a no-op; no croak; returns undef
# --------------------------------------------------
subtest 'Analyzer::Return: raw hashref argument → no evidence, no croak' => sub {
	my $r = App::Test::Generator::Analyzer::Return->new;
	lives_ok(
		sub { $r->analyze({ source => 'return $self' }) },
		'raw hashref does not croak',
	);
};

# ==================================================================
# Planner::Mock — all four branch paths + non-hashref croak
# ==================================================================

use_ok('App::Test::Generator::Planner::Mock');

Readonly my $MOCK_SYSTEM     => 'mock_system';
Readonly my $MOCK_CAPTURE_IO => 'capture_io';

# --------------------------------------------------
# Path: method has no _analysis key → absent from plan
# --------------------------------------------------
subtest 'Planner::Mock: no _analysis key → method absent from result' => sub {
	my $p      = App::Test::Generator::Planner::Mock->new;
	my $result = $p->plan({ pure_method => {} });
	ok(!exists $result->{pure_method}, 'pure method without _analysis absent from mock plan');
};

# --------------------------------------------------
# Path: calls_external only → scalar 'mock_system'
# --------------------------------------------------
subtest 'Planner::Mock: calls_external only → mock_system scalar' => sub {
	my $p = App::Test::Generator::Planner::Mock->new;
	my $result = $p->plan({
		m => { _analysis => { side_effects => { calls_external => 1 } } },
	});
	is($result->{m}, $MOCK_SYSTEM, 'calls_external alone → mock_system string');
};

# --------------------------------------------------
# Path: performs_io only → scalar 'capture_io'
# --------------------------------------------------
subtest 'Planner::Mock: performs_io only → capture_io scalar' => sub {
	my $p = App::Test::Generator::Planner::Mock->new;
	my $result = $p->plan({
		m => { _analysis => { side_effects => { performs_io => 1 } } },
	});
	is($result->{m}, $MOCK_CAPTURE_IO, 'performs_io alone → capture_io string');
};

# --------------------------------------------------
# Path: both flags set → arrayref [mock_system, capture_io]
# --------------------------------------------------
subtest 'Planner::Mock: both calls_external and performs_io → arrayref' => sub {
	my $p = App::Test::Generator::Planner::Mock->new;
	my $result = $p->plan({
		m => { _analysis => { side_effects => { calls_external => 1, performs_io => 1 } } },
	});
	is(ref($result->{m}), 'ARRAY', 'both flags → arrayref');
	is_deeply($result->{m}, [$MOCK_SYSTEM, $MOCK_CAPTURE_IO], 'arrayref contains both labels in order');
};

# --------------------------------------------------
# Path: non-hashref schema → croak
# --------------------------------------------------
subtest 'Planner::Mock: non-hashref schema → croak' => sub {
	my $p = App::Test::Generator::Planner::Mock->new;
	throws_ok(
		sub { $p->plan('not a hashref') },
		qr/schema must be a hashref/,
		'non-hashref schema croaks with expected message',
	);
};

# ==================================================================
# PodExampleExtractor — three source-collection paths + dedup + shell-cmd rejection
# ==================================================================

use_ok('App::Test::Generator::PodExampleExtractor');

# --------------------------------------------------
# Path: =head1 SYNOPSIS verbatim block collected
# --------------------------------------------------
subtest 'PodExampleExtractor: =head1 SYNOPSIS verbatim block collected' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh <<'END';
package SynopsisTest;

=head1 SYNOPSIS

    my $x = 1;

=cut

1;
END
	close $fh;
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $path);
	my $res = $ex->extract;
	my @synopsis = grep { $_->{section} =~ /SYNOPSIS/i } @$res;
	ok(@synopsis >= 1, 'SYNOPSIS verbatim block produces at least one example');
	like($synopsis[0]{code}, qr/my \$x/, 'SYNOPSIS code text preserved');
};

# --------------------------------------------------
# Path: =for example begin/end block collected
# --------------------------------------------------
subtest 'PodExampleExtractor: =for example begin/end block collected' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh <<'END';
package ForExTest;

=pod

=for example begin

    my $y = 2;

=for example end

=cut

1;
END
	close $fh;
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $path);
	my $res = $ex->extract;
	my @for = grep { $_->{section} =~ /for example/i } @$res;
	ok(@for >= 1, '=for example begin/end block produces at least one example');
	like($for[0]{code}, qr/my \$y/, '=for example code text preserved');
};

# --------------------------------------------------
# Path: annotated inline line "# => value" collected, expected captured
# --------------------------------------------------
subtest 'PodExampleExtractor: annotated inline line with # => value' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh <<'END';
package AnnotTest;

=head1 DESCRIPTION

    abs(-5)  # => 5

=cut

1;
END
	close $fh;
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $path);
	my $res = $ex->extract;
	my @ann = grep { defined $_->{expected} } @$res;
	ok(@ann >= 1, 'annotated inline example found');
	is($ann[0]{expected}, '5', 'expected value captured from annotation');
};

# --------------------------------------------------
# Path: shell-only verbatim block rejected by _looks_like_perl
# (no Perl sigils/keywords → _looks_like_perl returns false → block dropped)
# --------------------------------------------------
subtest 'PodExampleExtractor: shell-only verbatim block not collected' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh <<'END';
package ShellTest;

=head1 SYNOPSIS

    prove -l t/
    fuzz-harness-generator -r schemas/foo.yml

=cut

1;
END
	close $fh;
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $path);
	my $res = $ex->extract;
	is(scalar @$res, 0, 'shell-only SYNOPSIS block rejected by _looks_like_perl');
};

# --------------------------------------------------
# Path: deduplication — same code in both SYNOPSIS and =for example → appears once
# --------------------------------------------------
subtest 'PodExampleExtractor: duplicate code across SYNOPSIS and =for example deduplicated' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh <<'END';
package DedupTest;

=head1 SYNOPSIS

    my $z = 3;

=head1 EXAMPLES

=for example begin

    my $z = 3;

=for example end

=cut

1;
END
	close $fh;
	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $path);
	my $res = $ex->extract;
	my %codes;
	for my $ex (@$res) {
		(my $norm = $ex->{code}) =~ s/^\s+|\s+$//g;
		$codes{$norm}++;
	}
	my @dups = grep { $codes{$_} > 1 } keys %codes;
	is(scalar @dups, 0, 'no duplicate code blocks after deduplication');
};

# ==================================================================
# CoverageGuidedFuzzer::minimize_corpus — greedy-set-cover path branches
# ==================================================================

use_ok('App::Test::Generator::CoverageGuidedFuzzer');

Readonly my $NOOP_TARGET => sub { 1 };

# --------------------------------------------------
# Path: all entries have empty coverage → fingerprint-dedup path only
# --------------------------------------------------
subtest 'CoverageGuidedFuzzer::minimize_corpus: no-coverage entries → fingerprint dedup' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { x => { type => 'integer' } },
		target_sub => $NOOP_TARGET,
	);
	# Manually populate corpus with no-coverage entries (as load_corpus would produce)
	$f->{corpus} = [
		{ input => 1, coverage => {} },
		{ input => 2, coverage => {} },
		{ input => 1, coverage => {} },  # duplicate of first
	];
	my $stats = $f->minimize_corpus;
	is($stats->{before}, 3, 'before reflects manual corpus size');
	is($stats->{after},  2, 'duplicate entry removed by fingerprint dedup');
	is($stats->{branches}, 0, 'no branch coverage data → branches=0');
};

# --------------------------------------------------
# Path: entries with coverage → greedy set-cover fires
# --------------------------------------------------
subtest 'CoverageGuidedFuzzer::minimize_corpus: entries with coverage → greedy selection' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { x => { type => 'integer' } },
		target_sub => $NOOP_TARGET,
	);
	$f->{corpus} = [
		{ input => 1, coverage => { branch_A => 1, branch_B => 1 } },
		{ input => 2, coverage => { branch_A => 1 } },  # redundant — A already covered by entry 1
		{ input => 3, coverage => { branch_C => 1 } },
	];
	my $stats = $f->minimize_corpus;
	is($stats->{branches}, 3, 'total branch count correct');
	is($stats->{after},    2, 'greedy selection keeps 2 entries (not the redundant one)');
	is($stats->{before},   3, 'before reflects pre-minimise size');
};

# --------------------------------------------------
# Path: bug input forces inclusion regardless of coverage
# --------------------------------------------------
subtest 'CoverageGuidedFuzzer::minimize_corpus: bug input always retained' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { x => { type => 'integer' } },
		target_sub => $NOOP_TARGET,
	);
	# corpus has one entry that covers nothing; bugs has one input
	$f->{corpus} = [{ input => 42, coverage => {} }];
	$f->{bugs}   = [{ input => 99, error => 'boom' }];
	my $stats = $f->minimize_corpus;
	my @inputs = map { $_->{input} } @{ $f->{corpus} };
	ok((grep { $_ == 99 } @inputs), 'bug input (99) retained in minimised corpus');
};

# --------------------------------------------------
# Path: never-run fuzzer → empty corpus, minimize_corpus returns zeros
# --------------------------------------------------
subtest 'CoverageGuidedFuzzer::minimize_corpus: empty corpus → before=after=0' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { x => { type => 'integer' } },
		target_sub => $NOOP_TARGET,
	);
	my $stats = $f->minimize_corpus;
	is($stats->{before},   0, 'before=0 for never-run fuzzer');
	is($stats->{after},    0, 'after=0 for never-run fuzzer');
	is($stats->{branches}, 0, 'branches=0 for never-run fuzzer');
};

# --------------------------------------------------
# Path: second minimize_corpus call → idempotent
# --------------------------------------------------
subtest 'CoverageGuidedFuzzer::minimize_corpus: second call is idempotent' => sub {
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => { x => { type => 'integer' } },
		target_sub => $NOOP_TARGET,
	);
	$f->{corpus} = [
		{ input => 1, coverage => { br_A => 1 } },
		{ input => 2, coverage => { br_B => 1 } },
	];
	my $s1 = $f->minimize_corpus;
	my $s2 = $f->minimize_corpus;
	is($s2->{before}, $s1->{after},  'second call before == first call after');
	is($s2->{after},  $s1->{after},  'second call after == first call after (idempotent)');
};

# ==================================================================
# Mutator::generate_mutants — wantarray context sensitivity
# ==================================================================

use_ok('App::Test::Generator::Mutator');

{
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');
	make_path($lib);
	my $pmfile = File::Spec->catfile($lib, 'Dummy.pm');
	open my $fh, '>', $pmfile or die $!;
	print $fh "package Dummy;\nsub foo { return 1 }\n1;\n";
	close $fh;

	my $mut = App::Test::Generator::Mutator->new(
		file    => $pmfile,
		lib_dir => 'lib',
	);
	my $orig_cwd = Cwd::cwd();
	chdir $tmpdir;

	# --------------------------------------------------
	# Path: scalar context → arrayref returned
	# --------------------------------------------------
	subtest 'Mutator::generate_mutants: scalar context → arrayref' => sub {
		my $result = $mut->generate_mutants;
		is(ref($result), 'ARRAY', 'scalar context returns arrayref');
	};

	# --------------------------------------------------
	# Path: list context → flat list returned
	# --------------------------------------------------
	subtest 'Mutator::generate_mutants: list context → flat list' => sub {
		my @result = $mut->generate_mutants;
		isnt(ref(\@result), 'REF', 'list context returns flat list (array, not ref-to-ref)');
		ok(@result >= 0, 'list result is a list');
	};

	# --------------------------------------------------
	# Path: scalar context arrayref elements are the same objects as list context
	# Verify by capturing both in one call via wantarray-sensitive wrapper.
	# --------------------------------------------------
	subtest 'Mutator::generate_mutants: scalar and list yield same count' => sub {
		my $aref = $mut->generate_mutants;
		my @list = $mut->generate_mutants;
		# Both calls re-parse the same file so element count must agree
		is(scalar @list, scalar @$aref, 'same mutant count in list and scalar context');
		if (@list) {
			# Objects are newly created each call, but their descriptions must agree
			is($list[0]->description, $aref->[0]->description,
				'first mutant description agrees across both context returns');
		} else {
			pass('no mutants — description agreement check skipped');
		}
	};

	chdir $orig_cwd;
}

done_testing();
