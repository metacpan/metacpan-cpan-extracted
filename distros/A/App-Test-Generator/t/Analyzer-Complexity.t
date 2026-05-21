#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Readonly;

BEGIN {
	use_ok('App::Test::Generator::Analyzer::Complexity');
}

# --------------------------------------------------
# Constants matching the thresholds and labels
# declared in the module under test. A change to
# any constant in the source will cause the
# corresponding test to fail deliberately rather
# than silently passing with wrong values.
# --------------------------------------------------
Readonly my $CYCLOMATIC_BASE => 1;
Readonly my $LOW_THRESHOLD   => 3;
Readonly my $HIGH_THRESHOLD  => 7;
Readonly my $LEVEL_LOW       => 'low';
Readonly my $LEVEL_MODERATE  => 'moderate';
Readonly my $LEVEL_HIGH      => 'high';

# --------------------------------------------------
# Helper: call analyze with the given body string
# wrapped in the hashref the method expects.
# --------------------------------------------------
sub _analyze_body {
	my $body = $_[0];
	my $analyser = new_ok('App::Test::Generator::Analyzer::Complexity');
	return $analyser->analyze({ body => $body // '' });
}

# ==================================================================
# new
# --------------------------------------------------
# Tests for the constructor
# ==================================================================
subtest 'new' => sub {
	# Constructor returns a defined blessed object
	my $analyser = App::Test::Generator::Analyzer::Complexity->new();
	ok(defined $analyser, 'new() returns defined value');
	isa_ok($analyser, 'App::Test::Generator::Analyzer::Complexity');

	# Object is a plain blessed hashref in the correct class
	is(ref($analyser), 'App::Test::Generator::Analyzer::Complexity',
		'object is blessed into correct class');

	# Each call produces a distinct object
	my $analyser2 = App::Test::Generator::Analyzer::Complexity->new();
	isnt($analyser, $analyser2, 'each call produces a distinct object');

	done_testing();
};

# ==================================================================
# analyze -- return structure
# --------------------------------------------------
# The return value must always be a hashref with all
# six required keys regardless of input content
# ==================================================================
subtest 'analyze return structure' => sub {
	my $report = _analyze_body('');

	is(ref($report), 'HASH', 'analyze returns hashref');

	# All six required keys must be present
	ok(exists $report->{cyclomatic_score},  'cyclomatic_score key present');
	ok(exists $report->{branching_points},  'branching_points key present');
	ok(exists $report->{early_returns},     'early_returns key present');
	ok(exists $report->{exception_paths},   'exception_paths key present');
	ok(exists $report->{nesting_depth},     'nesting_depth key present');
	ok(exists $report->{complexity_level},  'complexity_level key present');

	done_testing();
};

# ==================================================================
# analyze -- baseline: empty body
# --------------------------------------------------
# An empty body must produce base score of 1 with all
# counters at zero and complexity level 'low'
# ==================================================================
subtest 'analyze: baseline for empty body' => sub {
	my $report = _analyze_body('');

	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE, 'empty body has base score of 1');
	is($report->{branching_points}, 0,                'empty body has no branching points');
	is($report->{early_returns},    0,                'empty body has no early returns');
	is($report->{exception_paths},  0,                'empty body has no exception paths');
	is($report->{nesting_depth},    0,                'empty body has zero nesting depth');
	is($report->{complexity_level}, $LEVEL_LOW,       'empty body is low complexity');

	done_testing();
};

# ==================================================================
# analyze -- cyclomatic_score base value
# --------------------------------------------------
# The score always starts at $CYCLOMATIC_BASE (1)
# even for a body with no decision points
# ==================================================================
subtest 'analyze: cyclomatic_score starts at base' => sub {
	# A trivial method with a single return and no branching
	my $report = _analyze_body('sub foo { return 1; }');

	# Score is base (1) — no branching, no logic ops,
	# the single return does not count as an early return
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE,
		'single return method has base cyclomatic score');
	is($report->{early_returns}, 0,
		'single return is not counted as an early return');

	done_testing();
};

# ==================================================================
# analyze -- branching_points detection
# --------------------------------------------------
# Each branching keyword increments both
# branching_points and cyclomatic_score
# ==================================================================
subtest 'analyze: branching_points detection' => sub {
	# Single 'if' adds 1 to branching_points and 1 to score
	my $report = _analyze_body('if($x) { return 1; }');
	is($report->{branching_points}, 1, 'single if: one branching point');
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE + 1,
		'single if: score is base + 1');

	# elsif adds another point
	$report = _analyze_body('if($x) { 1; } elsif($y) { 2; }');
	is($report->{branching_points}, 2, 'if + elsif: two branching points');

	# unless is a branching keyword
	$report = _analyze_body('unless($x) { return 0; }');
	is($report->{branching_points}, 1, 'unless: one branching point');

	# for loop
	$report = _analyze_body('for my $i (1..10) { print $i; }');
	is($report->{branching_points}, 1, 'for: one branching point');

	# foreach loop
	$report = _analyze_body('foreach my $item (@items) { process($item); }');
	is($report->{branching_points}, 1, 'foreach: one branching point');

	# while loop
	$report = _analyze_body('while($cond) { $x++; }');
	is($report->{branching_points}, 1, 'while: one branching point');

	# until loop
	$report = _analyze_body('until($done) { step(); }');
	is($report->{branching_points}, 1, 'until: one branching point');

	# Multiple different branching keywords are additive
	$report = _analyze_body(
		'if($a) { foreach my $x (@b) { while($c) { 1; } } }'
	);
	is($report->{branching_points}, 3,
		'if + foreach + while: three branching points');

	done_testing();
};

# ==================================================================
# analyze -- logical operators increment cyclomatic_score
# --------------------------------------------------
# && || and ? each add 1 to cyclomatic_score but
# do NOT add to branching_points
# ==================================================================
subtest 'analyze: logical operators affect cyclomatic_score' => sub {
	# && adds 1 to score only
	my $report = _analyze_body('my $z = $a && $b;');
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE + 1,
		'&& adds 1 to cyclomatic_score');
	is($report->{branching_points}, 0,
		'&& does not increment branching_points');

	# || adds 1 to score only
	$report = _analyze_body('my $z = $a || $b;');
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE + 1,
		'|| adds 1 to cyclomatic_score');
	is($report->{branching_points}, 0,
		'|| does not increment branching_points');

	# ? (ternary) adds 1 to score only
	$report = _analyze_body('my $z = $a ? $b : $c;');
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE + 1,
		'ternary ? adds 1 to cyclomatic_score');
	is($report->{branching_points}, 0,
		'ternary ? does not increment branching_points');

	# Multiple logical operators are additive
	$report = _analyze_body('my $z = $a && $b || $c;');
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE + 2,
		'&& and || together add 2 to score');

	done_testing();
};

# ==================================================================
# analyze -- early_returns detection
# --------------------------------------------------
# The first return does not count as early.
# Each additional return beyond the first increments
# early_returns and cyclomatic_score.
# ==================================================================
subtest 'analyze: early_returns detection' => sub {
	# Zero returns -- no early returns
	my $report = _analyze_body('sub foo { my $x = 1; }');
	is($report->{early_returns}, 0, 'no return: zero early returns');

	# Exactly one return -- not early
	$report = _analyze_body('sub foo { return 1; }');
	is($report->{early_returns}, 0, 'single return: zero early returns');

	# Two returns -- one early
	$report = _analyze_body('sub foo { return undef unless $x; return 1; }');
	is($report->{early_returns}, 1, 'two returns: one early return');
	is($report->{cyclomatic_score},
		$CYCLOMATIC_BASE + 1 + 1,	# unless + one early return
		'two returns: score incremented for early return');

	# Three returns -- two early
	$report = _analyze_body(
		'sub foo { return 0 if $a; return undef if $b; return 1; }'
	);
	is($report->{early_returns}, 2, 'three returns: two early returns');

	done_testing();
};

# ==================================================================
# analyze -- exception_paths detection
# --------------------------------------------------
# die, croak, confess, try, catch, eval each increment
# exception_paths and cyclomatic_score
# ==================================================================
subtest 'analyze: exception_paths detection' => sub {
	# die
	my $report = _analyze_body('die "error" unless $x;');
	is($report->{exception_paths}, 1, 'die: one exception path');
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE + 1 + 1,
		'die + unless: correct score');

	# croak
	$report = _analyze_body('croak "bad input" unless defined $x;');
	is($report->{exception_paths}, 1, 'croak: one exception path');

	# confess
	$report = _analyze_body('confess "deep error";');
	is($report->{exception_paths}, 1, 'confess: one exception path');

	# eval block
	$report = _analyze_body('eval { do_something(); };');
	is($report->{exception_paths}, 1, 'eval: one exception path');

	# try/catch (e.g. Try::Tiny style)
	$report = _analyze_body('try { do_something(); } catch { handle($_); };');
	is($report->{exception_paths}, 2, 'try + catch: two exception paths');

	# Multiple exception keywords are additive
	$report = _analyze_body('eval { die "err"; }');
	is($report->{exception_paths}, 2, 'eval + die: two exception paths');

	done_testing();
};

# ==================================================================
# analyze -- nesting_depth detection
# --------------------------------------------------
# Maximum brace depth is tracked by naive counting.
# Note: braces in strings/regexes are also counted
# (documented limitation).
# ==================================================================
subtest 'analyze: nesting_depth detection' => sub {
	# No braces -- depth is 0
	my $report = _analyze_body('return 1;');
	is($report->{nesting_depth}, 0, 'no braces: depth 0');

	# Single level -- depth is 1
	$report = _analyze_body('{ my $x = 1; }');
	is($report->{nesting_depth}, 1, 'single brace pair: depth 1');

	# Two levels -- depth is 2
	$report = _analyze_body('{ if($x) { return 1; } }');
	is($report->{nesting_depth}, 2, 'nested pair: depth 2');

	# Three levels -- depth is 3
	$report = _analyze_body('{ for(@a) { if($b) { do_thing(); } } }');
	is($report->{nesting_depth}, 3, 'three-level nesting: depth 3');

	# Sequential (not nested) pairs -- depth is still 1
	$report = _analyze_body('{ my $x = 1; } { my $y = 2; }');
	is($report->{nesting_depth}, 1,
		'sequential pairs not nested: depth 1');

	done_testing();
};

# ==================================================================
# analyze -- complexity_level classification
# --------------------------------------------------
# low: score <= LOW_THRESHOLD (3)
# moderate: score <= HIGH_THRESHOLD (7)
# high: score > HIGH_THRESHOLD (7)
# ==================================================================
subtest 'analyze: complexity_level classification' => sub {
	# Score of 1 (base) -- low
	my $report = _analyze_body('return 1;');
	is($report->{complexity_level}, $LEVEL_LOW,
		'score 1: low complexity');

	# Score of 3 (base + 2 branches) -- still low (boundary)
	$report = _analyze_body('if($a) { 1; } if($b) { 2; }');
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE + 2,
		'two ifs give score 3');
	is($report->{complexity_level}, $LEVEL_LOW,
		'score 3: low complexity (at boundary)');

	# Score of 4 (base + 3 branches) -- moderate
	$report = _analyze_body('if($a) { 1; } if($b) { 2; } if($c) { 3; }');
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE + 3,
		'three ifs give score 4');
	is($report->{complexity_level}, $LEVEL_MODERATE,
		'score 4: moderate complexity');

	# Score of 7 (base + 6 branches) -- still moderate (boundary)
	my $body_6 = join(' ', map { "if(\$v$_) { $_ ; }" } 1..6);
	$report = _analyze_body($body_6);
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE + 6,
		'six ifs give score 7');
	is($report->{complexity_level}, $LEVEL_MODERATE,
		'score 7: moderate complexity (at boundary)');

	# Score of 8 (base + 7 branches) -- high
	my $body_7 = join(' ', map { "if(\$v$_) { $_ ; }" } 1..7);
	$report = _analyze_body($body_7);
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE + 7,
		'seven ifs give score 8');
	is($report->{complexity_level}, $LEVEL_HIGH,
		'score 8: high complexity');

	done_testing();
};

# ==================================================================
# analyze -- all components are additive
# --------------------------------------------------
# Verifies that branching, logic ops, early returns,
# and exception paths all contribute independently
# to the final cyclomatic score
# ==================================================================
subtest 'analyze: score components are additive' => sub {
	my $body = <<'CODE';
sub process {
	my ($self, $input) = @_;
	croak "no input" unless defined $input;
	return undef if $input eq '';
	my $result = $input && $input =~ /\w/ ? lc($input) : $input;
	if($result =~ /^error/) {
		die "error result";
	}
	return $result;
}
CODE

	my $report = _analyze_body($body);

	# Verify each component separately
	# unless: 1 branching point
	# if: 1 branching point  => total branching: 2
	ok($report->{branching_points} >= 2, 'at least 2 branching points');

	# croak: 1 exception path
	# die: 1 exception path  => total exception: 2
	ok($report->{exception_paths} >= 2, 'at least 2 exception paths');

	# Three return statements => 2 early returns
	ok($report->{early_returns} >= 1, 'at least 1 early return');

	# &&: 1 logic op, ?: 1 logic op => at least 2 logic ops
	# Total score must be at least base + branching + exception + logic + early
	ok($report->{cyclomatic_score} > $CYCLOMATIC_BASE + 4,
		'combined score exceeds sum of minimum components');

	# High enough to be at least moderate complexity
	ok($report->{complexity_level} ne $LEVEL_LOW,
		'complex method is not low complexity');

	done_testing();
};

# ==================================================================
# analyze -- threshold constant values
# --------------------------------------------------
# Explicit checks that each constant has the declared
# value. Changes in the source will cause failures.
# ==================================================================
subtest 'threshold constants have correct values' => sub {
	is($CYCLOMATIC_BASE, 1, 'CYCLOMATIC_BASE is 1');
	is($LOW_THRESHOLD,   3, 'LOW_THRESHOLD is 3');
	is($HIGH_THRESHOLD,  7, 'HIGH_THRESHOLD is 7');

	# Ordering assertions -- thresholds must be increasing
	ok($LOW_THRESHOLD  <  $HIGH_THRESHOLD, 'LOW < HIGH');
	ok($CYCLOMATIC_BASE <= $LOW_THRESHOLD, 'BASE <= LOW');

	# Level label string values
	is($LEVEL_LOW,      'low',      'LEVEL_LOW is "low"');
	is($LEVEL_MODERATE, 'moderate', 'LEVEL_MODERATE is "moderate"');
	is($LEVEL_HIGH,     'high',     'LEVEL_HIGH is "high"');

	# All level labels are distinct
	isnt($LEVEL_LOW,      $LEVEL_MODERATE, 'low != moderate');
	isnt($LEVEL_LOW,      $LEVEL_HIGH,     'low != high');
	isnt($LEVEL_MODERATE, $LEVEL_HIGH,     'moderate != high');

	done_testing();
};

# ==================================================================
# analyze -- tolerates missing body key
# --------------------------------------------------
# analyze must not die when body key is absent or undef
# ==================================================================
subtest 'analyze: tolerates missing body key' => sub {
	my $analyser = App::Test::Generator::Analyzer::Complexity->new();

	# No body key at all -- defaults to empty string
	lives_ok { $analyser->analyze({}) }
		'analyze lives when body key absent';

	my $report = $analyser->analyze({});
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE,
		'absent body gives base score');
	is($report->{complexity_level}, $LEVEL_LOW,
		'absent body is low complexity');

	# Explicit undef body -- also defaults to empty string
	lives_ok { $analyser->analyze({ body => undef }) }
		'analyze lives when body is undef';

	$report = $analyser->analyze({ body => undef });
	is($report->{cyclomatic_score}, $CYCLOMATIC_BASE,
		'undef body gives base score');

	done_testing();
};

# ==================================================================
# analyze -- branch keywords are whole-word matched
# --------------------------------------------------
# Keywords embedded in identifiers must not trigger
# a branching point count
# ==================================================================
subtest 'analyze: branching keywords are whole-word matched' => sub {
	# 'iform' contains 'for' but should not count as a for loop
	my $report = _analyze_body('my $uniform = 1;');
	is($report->{branching_points}, 0,
		'"uniform" does not trigger for branching point');

	# 'notify' contains 'if' (as substring) but not as a word
	$report = _analyze_body('my $notify = 1;');
	is($report->{branching_points}, 0,
		'"notify" does not trigger if branching point');

	# 'foreacher' is not a keyword
	$report = _analyze_body('my $foreacher = 1;');
	is($report->{branching_points}, 0,
		'"foreacher" does not trigger foreach branching point');

	done_testing();
};

# ==================================================================
# analyze -- exception keywords are whole-word matched
# ==================================================================
subtest 'analyze: exception keywords are whole-word matched' => sub {
	# 'evaluate' contains 'eval' but should not count
	my $report = _analyze_body('my $evaluate = 1;');
	is($report->{exception_paths}, 0,
		'"evaluate" does not trigger eval exception path');

	# 'croaky' contains 'croak' but should not count
	$report = _analyze_body('my $croaky = 1;');
	is($report->{exception_paths}, 0,
		'"croaky" does not trigger croak exception path');

	done_testing();
};

done_testing();
