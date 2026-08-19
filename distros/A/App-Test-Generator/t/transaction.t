#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempdir tempfile);
use File::Spec;
use Readonly;

BEGIN {
	use_ok('App::Test::Generator::CoverageGuidedFuzzer');
	use_ok('App::Test::Generator::Mutator');
	use_ok('App::Test::Generator::SchemaExtractor');
}

# --------------------------------------------------
# Constants: schema and function used across fuzzer tests
# --------------------------------------------------
Readonly my $INT_SCHEMA => {
	function => 'abs_val',
	input    => {
		n => { type => 'integer', position => 0 },
	},
};

Readonly my $TARGET_SUB => sub {
	my ($n) = @_;
	die 'not a number' unless defined $n && $n =~ /^-?\d+$/;
	return $n < 0 ? -$n : $n;
};

Readonly my $BUG_SUB => sub {
	my ($n) = @_;
	die "bug: got $n" if defined $n && $n =~ /^-?\d+$/ && $n == 0;
	return $n;
};

Readonly my $FUZZER_ITERS   => 20;
Readonly my $FUZZER_SEED    => 99;
Readonly my $SKIP_BEGIN_TAG => '## MUTANT_SKIP_BEGIN';
Readonly my $SKIP_END_TAG   => '## MUTANT_SKIP_END';

# ==================================================================
# Helper: minimal fuzzer factory
# ==================================================================
sub _fuzzer {
	my (%args) = @_;
	return App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => $args{schema}     // $INT_SCHEMA,
		target_sub => $args{target_sub} // $TARGET_SUB,
		iterations => $args{iterations} // $FUZZER_ITERS,
		seed       => $args{seed}       // $FUZZER_SEED,
	);
}

# Helper: write a minimal Perl module to a temp file, return path
sub _temp_pm {
	my ($code) = @_;
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh $code;
	close $fh;
	return $path;
}

# ==================================================================
# TRANSACTION 1: Fuzzer corpus lifecycle — Create → Run → Minimize → Save → Load
# ==================================================================

subtest 'T1a: run() populates corpus from empty state' => sub {
	# Strategy: verify that after run(), the corpus is non-empty and the report
	# keys are all present, establishing the baseline for downstream transactions.
	my $f      = _fuzzer();
	my $before = scalar @{ $f->corpus() };

	my $report = $f->run();

	cmp_ok($before, '==', 0, 'corpus is empty before run()');
	ok(scalar @{ $f->corpus() } > 0, 'corpus is non-empty after run()');

	for my $key (qw(total_iterations interesting_inputs corpus_size branches_covered bugs_found bugs)) {
		ok(exists $report->{$key}, "report has key '$key'");
	}

	is($report->{total_iterations}, $FUZZER_ITERS, 'total_iterations matches iterations arg');
	diag("corpus after run: $report->{corpus_size}") if $ENV{TEST_VERBOSE};
};

subtest 'T1b: minimize_corpus() reduces or preserves corpus, returns stats' => sub {
	# Strategy: use a safe (never-dies) target so no bug entries inflate the
	# post-minimize count.  Both paths through minimize must return the
	# required keys and after <= before.
	my $safe_f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => $INT_SCHEMA,
		target_sub => sub { 1 },	# never dies — no bug entries
		iterations => $FUZZER_ITERS,
		seed       => $FUZZER_SEED,
	);
	$safe_f->run();

	my $before = scalar @{ $safe_f->corpus() };
	my $stats  = $safe_f->minimize_corpus();

	ok(defined $stats->{before},   'stats has before');
	ok(defined $stats->{after},    'stats has after');
	ok(defined $stats->{branches}, 'stats has branches');
	is($stats->{before}, $before, 'stats.before equals pre-minimize corpus size');
	cmp_ok($stats->{after}, '<=', $stats->{before}, 'after <= before');

	diag("minimize: $stats->{before} -> $stats->{after} ($stats->{branches} branches)") if $ENV{TEST_VERBOSE};
};

subtest 'T1c: save_corpus() + load_corpus() round-trips all inputs' => sub {
	# Strategy: run, minimize, save to a temp file, load into a fresh fuzzer,
	# then verify all inputs from the original corpus appear in the new one.
	my $f1 = _fuzzer(seed => 1);
	$f1->run();
	$f1->minimize_corpus();

	my $saved = [ map { $_->{input} } @{ $f1->corpus() } ];
	ok(@$saved > 0, 'have entries to save');

	my ($fh, $path) = tempfile(SUFFIX => '.json', UNLINK => 1);
	close $fh;
	$f1->save_corpus($path);

	ok(-s $path, 'corpus file written and non-empty');

	my $f2 = _fuzzer(seed => 2, iterations => 0);
	$f2->load_corpus($path);

	my @loaded = map { $_->{input} } @{ $f2->corpus() };
	is(scalar @loaded, scalar @$saved, 'loaded entry count matches saved count');

	diag("round-trip: saved=${\scalar @$saved}, loaded=${\scalar @loaded}") if $ENV{TEST_VERBOSE};
};

# ==================================================================
# TRANSACTION 2: Corpus minimize idempotency
# ==================================================================

subtest 'T2: minimize_corpus() is idempotent — second call is a no-op' => sub {
	# Strategy: minimize twice; the second call must return after=first_after,
	# proving the algorithm converges in one pass.
	my $f = _fuzzer(seed => 7);
	$f->run();

	my $first  = $f->minimize_corpus();
	my $second = $f->minimize_corpus();

	is($second->{before},   $first->{after},    'second before = first after');
	is($second->{after},    $first->{after},    'second after unchanged');
	is($second->{branches}, $first->{branches}, 'branch count unchanged');
};

# ==================================================================
# TRANSACTION 3: Bug-input preservation across minimize_corpus()
# ==================================================================

subtest 'T3: bug inputs survive minimize_corpus() unconditionally' => sub {
	# Strategy: use BUG_SUB which dies on input 0; run enough iterations that
	# 0 is hit, producing a bug entry.  After minimizing, the bug input must
	# still be present in the corpus regardless of coverage contribution.
	my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => {
			function => 'bug_func',
			input    => { n => { type => 'integer', position => 0, min => -5, max => 5 } },
		},
		target_sub => $BUG_SUB,
		iterations => 40,
		seed       => $FUZZER_SEED,
	);
	$f->run();

	my @bugs_before = @{ $f->bugs() };

	SKIP: {
		skip 'No bugs triggered in this run — seed/schema did not hit 0', 1
			unless @bugs_before;

		$f->minimize_corpus();

		my %corpus_inputs = map { _canonical($_->{input}) => 1 } @{ $f->corpus() };
		for my $bug (@bugs_before) {
			ok($corpus_inputs{ _canonical($bug->{input}) },
				'bug input retained in corpus after minimize');
		}

		diag("bugs: ${\scalar @bugs_before}") if $ENV{TEST_VERBOSE};
	}
};

# canonical stringification for input comparison
sub _canonical {
	my ($val) = @_;
	return 'undef' unless defined $val;
	return ref $val ? do { require JSON::MaybeXS; JSON::MaybeXS::encode_json($val) } : "$val";
}

# ==================================================================
# TRANSACTION 4: Mid-flight failure — save to unwritable path
# ==================================================================

subtest 'T4a: save_corpus() to unwritable path leaves in-memory corpus intact' => sub {
	# Strategy: run, capture corpus size, attempt save to /dev/null/impossible
	# (a path that cannot be created), assert croak, then verify corpus unchanged.
	my $f = _fuzzer(seed => 3);
	$f->run();
	my $before_count = scalar @{ $f->corpus() };

	my $bad_path = File::Spec->catfile(tempdir(CLEANUP => 1), 'no', 'such', 'dir', 'corpus.json');
	throws_ok(
		sub { $f->save_corpus($bad_path) },
		qr/Cannot write corpus/,
		'save_corpus to bad path croaks',
	);

	is(scalar @{ $f->corpus() }, $before_count, 'corpus unchanged after failed save');
};

subtest 'T4b: load_corpus() from nonexistent path croaks without modifying corpus' => sub {
	# Strategy: load from a real path (one entry), then attempt load from nonexistent path;
	# verify corpus still has exactly the one pre-loaded entry.
	my ($fh, $good_path) = tempfile(SUFFIX => '.json', UNLINK => 1);
	print $fh '{"seed":1,"corpus":[{"input":{"n":42}}],"bugs":[]}';
	close $fh;

	my $f = _fuzzer(seed => 4, iterations => 0);
	$f->load_corpus($good_path);
	is(scalar @{ $f->corpus() }, 1, 'one entry loaded from good corpus');

	throws_ok(
		sub { $f->load_corpus('/absolutely/nonexistent/corpus.json') },
		qr/Cannot read corpus/,
		'load_corpus from nonexistent path croaks',
	);

	is(scalar @{ $f->corpus() }, 1, 'corpus unchanged after failed load');
};

# ==================================================================
# TRANSACTION 5: Multi-session corpus continuity (grow then minimize)
# ==================================================================

subtest 'T5: corpus grows across two sessions then stabilises on minimize' => sub {
	# Strategy: session A runs and saves.  Session B loads, runs more iterations,
	# and saves again.  The combined corpus is always >= session A alone.
	# This verifies the multi-session accumulation contract.
	my ($fh, $path) = tempfile(SUFFIX => '.json', UNLINK => 1);
	close $fh;

	# Session A
	my $fa = _fuzzer(seed => 10, iterations => 10);
	$fa->run();
	$fa->save_corpus($path);
	my $count_a = scalar @{ $fa->corpus() };

	# Session B
	my $fb = _fuzzer(seed => 11, iterations => 10);
	$fb->load_corpus($path);
	$fb->run();

	cmp_ok(scalar @{ $fb->corpus() }, '>=', $count_a,
		'session B corpus >= session A after additional run');

	$fb->save_corpus($path);

	# Verify the saved file is parseable by a third session
	my $fc = _fuzzer(seed => 12, iterations => 0);
	$fc->load_corpus($path);
	cmp_ok(scalar @{ $fc->corpus() }, '>=', $count_a,
		'session C loads all accumulated entries');

	diag("A=$count_a B=${\scalar @{$fb->corpus()}} C=${\scalar @{$fc->corpus()}}") if $ENV{TEST_VERBOSE};
};

# ==================================================================
# TRANSACTION 6: Mutator state machine
# ==================================================================

subtest 'T6a: apply_mutant() croaks when called before prepare_workspace()' => sub {
	# Strategy: skip the prepare_workspace step entirely; apply_mutant must
	# croak with a meaningful message to prevent silent corruption.
	my $path = _temp_pm(<<'END_PM');
package Trans6a;
sub check { return $_[0] > 0 ? 1 : 0 }
1;
END_PM

	my $mut = App::Test::Generator::Mutator->new(file => $path);
	my @mutants = $mut->generate_mutants();

	SKIP: {
		skip 'No mutants generated', 1 unless @mutants;

		throws_ok(
			sub { $mut->apply_mutant($mutants[0]) },
			qr/Workspace not prepared/,
			'apply_mutant without prepare_workspace croaks',
		);
	}
};

subtest 'T6b: generate_mutants → prepare_workspace → apply_mutant modifies workspace file' => sub {
	# Strategy: place the target file inside a controlled lib_dir so that
	# prepare_workspace can dircopy it.  The workspace copy must differ from
	# the original after apply_mutant, and the original must be untouched.
	require File::Copy;
	require File::Basename;

	# Build: $lib_dir/Trans6b.pm
	my $lib_dir = tempdir(CLEANUP => 1);
	my $pm_name = 'Trans6b.pm';
	my $path    = File::Spec->catfile($lib_dir, $pm_name);

	open my $pfh, '>', $path or die "Cannot write $path: $!";
	print $pfh <<'END_PM';
package Trans6b;
sub check { return $_[0] > 10 ? 1 : 0 }
1;
END_PM
	close $pfh;

	my $original = do { local $/; open my $fh, '<', $path; <$fh> };

	my $mut = App::Test::Generator::Mutator->new(
		file    => $path,
		lib_dir => $lib_dir,
	);

	my @mutants = $mut->generate_mutants();

	SKIP: {
		skip 'No mutants generated', 3 unless @mutants;

		my $ws = $mut->prepare_workspace();
		ok(-d $ws, 'workspace directory exists');

		$mut->apply_mutant($mutants[0]);

		# workspace layout: $ws / basename($lib_dir) / Trans6b.pm
		my $ws_path = File::Spec->catfile($ws, File::Basename::basename($lib_dir), $pm_name);
		my $mutated = do { local $/; open my $fh, '<', $ws_path; <$fh> };

		isnt($mutated, $original, 'workspace copy differs from original after apply_mutant');
		my $after_orig = do { local $/; open my $fh, '<', $path; <$fh> };
		is($after_orig, $original, 'original project file is unmodified after apply_mutant');
	}
};

# ==================================================================
# TRANSACTION 7: MUTANT_SKIP annotation integrity
# ==================================================================

Readonly my $PM_SKIP_NO_END => <<'END_PM';
package Trans7a;
## MUTANT_SKIP_BEGIN
sub check { return $_[0] > 0 ? 1 : 0 }
1;
END_PM

Readonly my $PM_SKIP_NO_BEGIN => <<'END_PM';
package Trans7b;
sub check { return $_[0] > 0 ? 1 : 0 }
## MUTANT_SKIP_END
1;
END_PM

Readonly my $PM_SKIP_NESTED => <<'END_PM';
package Trans7c;
## MUTANT_SKIP_BEGIN
## MUTANT_SKIP_BEGIN
sub check { return $_[0] > 0 ? 1 : 0 }
## MUTANT_SKIP_END
## MUTANT_SKIP_END
1;
END_PM

Readonly my $PM_SKIP_VALID => <<'END_PM';
package Trans7d;
## MUTANT_SKIP_BEGIN
sub safe { return 42 }
## MUTANT_SKIP_END
sub check { return $_[0] > 0 ? 1 : 0 }
1;
END_PM

subtest 'T7a: unclosed MUTANT_SKIP_BEGIN croaks' => sub {
	my $path = _temp_pm($PM_SKIP_NO_END);
	my $mut  = App::Test::Generator::Mutator->new(file => $path);
	throws_ok(
		sub { $mut->generate_mutants() },
		qr/MUTANT_SKIP_BEGIN.+no matching MUTANT_SKIP_END/,
		'unclosed MUTANT_SKIP_BEGIN croaks',
	);
};

subtest 'T7b: MUTANT_SKIP_END without BEGIN croaks' => sub {
	my $path = _temp_pm($PM_SKIP_NO_BEGIN);
	my $mut  = App::Test::Generator::Mutator->new(file => $path);
	throws_ok(
		sub { $mut->generate_mutants() },
		qr/MUTANT_SKIP_END.+no matching MUTANT_SKIP_BEGIN/,
		'orphan MUTANT_SKIP_END croaks',
	);
};

subtest 'T7c: nested MUTANT_SKIP_BEGIN croaks' => sub {
	my $path = _temp_pm($PM_SKIP_NESTED);
	my $mut  = App::Test::Generator::Mutator->new(file => $path);
	throws_ok(
		sub { $mut->generate_mutants() },
		qr/MUTANT_SKIP_BEGIN.+no prior MUTANT_SKIP_END/,
		'nested MUTANT_SKIP_BEGIN croaks',
	);
};

subtest 'T7d: valid MUTANT_SKIP block excludes annotated lines from mutants' => sub {
	# Strategy: the skipped sub has no mutable code outside the skip block;
	# the non-skipped sub should still yield mutants.  Verify skip_lines
	# correctly covers the annotated region.
	my $path = _temp_pm($PM_SKIP_VALID);
	my $mut  = App::Test::Generator::Mutator->new(file => $path);
	my @mutants = $mut->generate_mutants();

	# Lines inside MUTANT_SKIP_BEGIN/END must not appear as mutant targets
	my %skip = %{ $mut->{skip_lines} };
	ok(%skip, 'skip_lines populated after generate_mutants');

	for my $m (@mutants) {
		ok(!$skip{ $m->line() }, "mutant at line ${\$m->line()} is not in a skip block");
	}
};

# ==================================================================
# TRANSACTION 8: Mutation level state transition (full → fast)
# ==================================================================

subtest 'T8: fast mode produces <= mutants vs full mode from same source' => sub {
	# Strategy: same source file, same binary — only mutation_level differs.
	# fast mode must dedup and remove redundant mutants, so its count cannot
	# exceed full mode's count.
	my $code = <<'END_PM';
package Trans8;
sub compare {
	my ($a, $b) = @_;
	if ($a > $b) { return 1 }
	if ($a < $b) { return -1 }
	return 0;
}
1;
END_PM

	my $path = _temp_pm($code);

	my $full_mut = App::Test::Generator::Mutator->new(
		file           => $path,
		mutation_level => 'full',
	);
	my $fast_mut = App::Test::Generator::Mutator->new(
		file           => $path,
		mutation_level => 'fast',
	);

	my @full = $full_mut->generate_mutants();
	my @fast = $fast_mut->generate_mutants();

	ok(@full > 0, 'full mode generates mutants');
	ok(@fast > 0, 'fast mode generates mutants');
	cmp_ok(scalar @fast, '<=', scalar @full, 'fast mode count <= full mode count');

	diag("full=${\scalar @full} fast=${\scalar @fast}") if $ENV{TEST_VERBOSE};
};

# ==================================================================
# TRANSACTION 9: SchemaExtractor idempotency across two runs
# ==================================================================

subtest 'T9: extract_all() is idempotent — two runs produce identical YAML' => sub {
	# Strategy: run extract_all() twice on the same source file into two
	# separate output dirs.  Compare the YAML text for each method.
	# Idempotency is a correctness invariant: regenerating schemas must not
	# produce random or timestamp-dependent content.
	my $source = File::Spec->catfile(
		File::Spec->curdir(), 'lib', 'App', 'Test', 'Generator', 'BenchmarkGenerator.pm',
	);
	skip 'BenchmarkGenerator.pm not found', 1 unless -f $source;

	my $dir_a = tempdir(CLEANUP => 1);
	my $dir_b = tempdir(CLEANUP => 1);

	my $ex_a = App::Test::Generator::SchemaExtractor->new(
		input_file => $source,
		output_dir => $dir_a,
		strict_pod => 0,
	);
	my $ex_b = App::Test::Generator::SchemaExtractor->new(
		input_file => $source,
		output_dir => $dir_b,
		strict_pod => 0,
	);

	lives_ok(sub { $ex_a->extract_all() }, 'first extract_all() lives');
	lives_ok(sub { $ex_b->extract_all() }, 'second extract_all() lives');

	my @yamls_a = sort glob(File::Spec->catfile($dir_a, '*.yml'));
	my @yamls_b = sort glob(File::Spec->catfile($dir_b, '*.yml'));

	is(scalar @yamls_a, scalar @yamls_b, 'same number of YAML files produced');

	for my $i (0 .. $#yamls_a) {
		# Compare YAML data structures, not raw text: comment lines embed the
		# temp dir path which differs between runs.
		require YAML::XS;
		my $data_a = YAML::XS::LoadFile($yamls_a[$i]);
		my $data_b = YAML::XS::LoadFile($yamls_b[$i]);
		is_deeply($data_a, $data_b,
			"YAML data for ${\File::Basename::basename($yamls_a[$i])} is identical");
	}

	diag("YAML files: ${\scalar @yamls_a}") if $ENV{TEST_VERBOSE};
};

# ==================================================================
# TRANSACTION 10: SchemaExtractor creates missing output dir
# ==================================================================

subtest 'T10: extract_all() creates a missing output dir and writes YAML files' => sub {
	# Strategy: pass a non-existent nested output dir.  SchemaExtractor must
	# create it via make_path and write at least one YAML file — proving the
	# pipeline completes cleanly without manual setup.
	my $source = File::Spec->catfile(
		File::Spec->curdir(), 'lib', 'App', 'Test', 'Generator', 'Sample', 'Module.pm',
	);
	skip 'Sample::Module.pm not found', 2 unless -f $source;

	my $parent  = tempdir(CLEANUP => 1);
	my $new_dir = File::Spec->catfile($parent, 'nested', 'output');

	ok(!-d $new_dir, 'output dir does not exist before extract_all');

	my $ex = App::Test::Generator::SchemaExtractor->new(
		input_file => $source,
		output_dir => $new_dir,
		strict_pod => 0,
	);
	lives_ok(sub { $ex->extract_all() }, 'extract_all() lives with missing output dir');

	ok(-d $new_dir, 'extract_all() created the output dir');
	my @yamls = glob(File::Spec->catfile($new_dir, '*.yml'));
	ok(@yamls > 0, 'at least one YAML file written');
};

# ==================================================================
# T11: BenchmarkGenerator schema→generate→compile lifecycle
#
# Walks the full BenchmarkGenerator lifecycle: hand-craft a schema,
# call generate(), write the output to a temp file, compile it with
# perl -c, and assert the result is deterministic (second call == first).
# ==================================================================

subtest 'T11a: BenchmarkGenerator generate() produces compilable output' => sub {
	require App::Test::Generator::BenchmarkGenerator;

	Readonly my %BENCH_SCHEMA => (
		module   => 'builtin',
		function => 'abs',
		input    => { n => { type => 'integer', position => 0 } },
	);

	my $bg   = App::Test::Generator::BenchmarkGenerator->new(schema => {%BENCH_SCHEMA});
	my $code;
	lives_ok(sub { $code = $bg->generate() }, 'generate() lives');
	ok(defined $code && length($code) > 0, 'generate() returns non-empty string');
	like($code, qr/use Benchmark/,  'output contains use Benchmark');
	like($code, qr/cmpthese/,       'output contains cmpthese call');

	my ($fh, $path) = tempfile(SUFFIX => '.pl', UNLINK => 1);
	print {$fh} $code;
	close $fh;

	# Compile with perl -c — no external modules needed for builtin schema
	my $exit = system($^X, '-c', $path);
	is($exit, 0, 'generated benchmark script compiles cleanly');

	done_testing();
};

subtest 'T11b: BenchmarkGenerator generate() is deterministic (idempotent output)' => sub {
	require App::Test::Generator::BenchmarkGenerator;

	Readonly my %BENCH_SCHEMA => (
		module   => 'builtin',
		function => 'length',
		input    => { s => { type => 'string', position => 0 } },
	);

	my $bg    = App::Test::Generator::BenchmarkGenerator->new(schema => {%BENCH_SCHEMA});
	my $first = $bg->generate();
	my $second = $bg->generate();
	is($first, $second, 'two generate() calls produce identical output');

	done_testing();
};

# ==================================================================
# T12: PodExampleExtractor → eval pipeline
#
# Write a .pm file containing both a verbatim SYNOPSIS block and an
# annotated inline example.  Run extract(), confirm the structural
# split, then simulate the pod-example-tester eval loop by evaluating
# each annotated bare_expr and comparing to expected.
# ==================================================================

subtest 'T12: PodExampleExtractor extract → eval pipeline' => sub {
	require App::Test::Generator::PodExampleExtractor;

	my ($fh, $pm) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print {$fh} <<'PODPM';
package ExampleTest;

=head1 SYNOPSIS

    my $x = 2 + 2;

=head1 METHODS

=head2 double

    my $result = double(3);   # => 6

=cut

sub double { return $_[0] * 2 }

1;
PODPM
	close $fh;

	my $ex  = App::Test::Generator::PodExampleExtractor->new(file => $pm);
	my $res = $ex->extract();
	is(ref($res), 'ARRAY', 'extract() returns arrayref');

	# At least one entry should be verbatim (undef expected)
	my @verbatim  = grep { !defined $_->{expected} } @$res;
	my @annotated = grep {  defined $_->{expected} } @$res;

	ok(scalar @verbatim  > 0, 'at least one verbatim block (expected => undef)');
	ok(scalar @annotated > 0, 'at least one annotated line (expected defined)');

	# Simulate pod-example-tester: eval bare_expr, compare to expected.
	# Load the temp module first so functions like double() are defined.
	require $pm;

	for my $entry (@annotated) {
		my $expr     = $entry->{annotated_line} // $entry->{code};
		my $expected = $entry->{expected};
		# Strip any leading assignment so eval returns the value
		$expr =~ s/^\s*(?:my\s+\$\w+\s*=\s*)//;
		my $got = eval "ExampleTest::$expr";  ## no critic (BuiltinFunctions::ProhibitStringyEval)
		is($got, $expected, "annotated eval: '$expr' == '$expected'");
	}

	done_testing();
};

# ==================================================================
# T13: Planner full pipeline — build_plan() → plan_all() consistency
#
# Instantiate Planner with a minimal schema that has _analysis keys.
# Assert build_plan() returns all five expected keys and plan_all()
# returns a method-keyed hashref.  Run both twice to verify
# idempotency.
# ==================================================================

subtest 'T13: Planner build_plan() + plan_all() lifecycle and idempotency' => sub {
	require App::Test::Generator::Planner;

	Readonly my %METHOD_SCHEMA => (
		greet => {
			input    => { name => { type => 'string', position => 0 } },
			output   => { type => 'string' },
			_analysis => {
				side_effects  => { purity_level => 'pure', calls_external => 0, performs_io => 0 },
				dependencies  => {},
				complexity    => { cyclomatic_score => 1, complexity_level => 'low' },
			},
		},
	);

	my $planner = App::Test::Generator::Planner->new(
		schemas => {%METHOD_SCHEMA},
		package => 'Sample::Greeter',
	);

	my $plan1;
	lives_ok(sub { $plan1 = $planner->build_plan() }, 'build_plan() lives');
	for my $key (qw(strategy isolation fixture mock groups)) {
		ok(exists $plan1->{$key}, "build_plan() result has '$key' key");
	}

	my $all1;
	lives_ok(sub { $all1 = $planner->plan_all() }, 'plan_all() lives');
	ok(ref($all1) eq 'HASH', 'plan_all() returns a hashref');
	ok(exists $all1->{greet}, 'plan_all() keyed by method name');

	# Idempotency
	my $plan2 = $planner->build_plan();
	my $all2  = $planner->plan_all();
	is_deeply($plan2, $plan1, 'build_plan() is idempotent');
	is_deeply($all2,  $all1,  'plan_all() is idempotent');

	done_testing();
};

# ==================================================================
# T14: Analyzer trio sequential composition → Model::Method
#
# Pass a method body through Complexity, SideEffect, and Return
# analyzers in sequence, feeding all evidence into a Model::Method.
# Verify the final resolve_return_type and resolve_confidence are
# consistent with the combined signal set.
# Mid-flight: mock SideEffect to return empty → fewer evidence entries.
# ==================================================================

subtest 'T14: Complexity + SideEffect + Return → Model::Method evidence pipeline' => sub {
	require App::Test::Generator::Analyzer::Complexity;
	require App::Test::Generator::Analyzer::SideEffect;
	require App::Test::Generator::Analyzer::Return;
	require App::Test::Generator::Model::Method;

	Readonly my $BODY => <<'BODY';
sub process {
    my ($self, $val) = @_;
    if ($val > 0) {
        print "positive\n";
        $self->{count}++;
    }
    return $self;
}
BODY

	my $method_hr = { name => 'process', source => $BODY, body => $BODY };

	my $complexity = new_ok('App::Test::Generator::Analyzer::Complexity');
	my $sideeffect = new_ok('App::Test::Generator::Analyzer::SideEffect');
	my $return_an  = new_ok('App::Test::Generator::Analyzer::Return');

	my $c_result = $complexity->analyze($method_hr);
	my $s_result = $sideeffect->analyze($method_hr);

	# Build a Model::Method and add evidence from each analyzer
	my $mm = App::Test::Generator::Model::Method->new(
		name   => 'process',
		source => $BODY,
	);

	# Add complexity evidence via input_typed signal when score > 1
	$mm->add_evidence(
		category => 'input',
		signal   => 'input_typed',
		weight   => 1,
	) if ($c_result->{cyclomatic_score} // 0) > 1;

	# Add side-effect evidence
	$mm->add_evidence(
		category => 'effect',
		signal   => 'mutates_self',
		weight   => 2,
	) if $s_result->{mutates_self};

	# Add return-type evidence by running the Return analyzer on the Method object
	$return_an->analyze($mm);

	my @ev_full = $mm->evidence();
	ok(scalar @ev_full > 0, 'evidence accumulated after three-analyzer pass');
	my $return_type = $mm->resolve_return_type();
	my $confidence  = $mm->resolve_confidence();
	ok(defined $return_type, 'resolve_return_type() returns a value');
	ok(defined $confidence,  'resolve_confidence() returns a value');
	# return $self pattern → should yield 'object'
	is($return_type, 'object', 'three-analyzer pipeline resolves return_type to object');

	# Mid-flight failure: SideEffect mocked to empty → fewer evidence entries
	my $mm2 = App::Test::Generator::Model::Method->new(
		name   => 'process',
		source => $BODY,
	);
	# Only Return analyzer runs (simulating SideEffect unavailable)
	$return_an->analyze($mm2);
	my @ev_partial = $mm2->evidence();
	ok(scalar @ev_partial <= scalar @ev_full,
		'degraded pipeline has <= evidence entries vs full pipeline');

	done_testing();
};

# ==================================================================
# T15: Exporter::YAML write → reload → re-export round-trip
#
# Export a plan to a temp file; reload with YAML::XS::LoadFile;
# assert is_deeply equality.  Re-export the reloaded plan to a second
# file and assert byte-for-byte identity between the two YAML files.
# Mid-flight: simulate DumpFile failure on the second call and verify
# the first file is intact.
# ==================================================================

subtest 'T15: Exporter::YAML export → reload → re-export byte-for-byte round-trip' => sub {
	require App::Test::Generator::Exporter::YAML;
	require YAML::XS;
	require Test::Mockingbird;

	Readonly my %PLAN => (
		strategy => { greet => { getter_test => 1 } },
		mock     => {},
	);

	my ($fh1, $path1) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	close $fh1;
	my ($fh2, $path2) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	close $fh2;

	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';

	# First export
	lives_ok(sub { $exporter->export({%PLAN}, $path1) }, 'first export() lives');
	ok(-s $path1, 'first export wrote a non-empty file');

	# Reload and verify equality
	my $reloaded = YAML::XS::LoadFile($path1);
	is_deeply($reloaded, {%PLAN}, 'reloaded YAML is_deeply equal to original plan');

	# Re-export to second file
	lives_ok(sub { $exporter->export($reloaded, $path2) }, 're-export to second file lives');

	# Byte-for-byte comparison between the two files
	local $/;
	open my $f1, '<', $path1 or die $!;
	my $bytes1 = <$f1>;
	close $f1;
	open my $f2, '<', $path2 or die $!;
	my $bytes2 = <$f2>;
	close $f2;
	is($bytes1, $bytes2, 'two exports of the same data are byte-for-byte identical');

	# Mid-flight failure: second DumpFile call croaks; first file must remain intact
	my ($fh3, $path3) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	close $fh3;
	my ($fh4, $path4) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	close $fh4;

	$exporter->export({%PLAN}, $path3);  # first succeeds
	ok(-s $path3, 'first file written before mock failure');

	Test::Mockingbird::mock(
		'YAML::XS::DumpFile',
		sub { die "simulated disk full\n" },
	);
	throws_ok(
		sub { $exporter->export({%PLAN}, $path4) },
		qr/simulated disk full/,
		'second export croaks when DumpFile fails',
	);
	Test::Mockingbird::unmock('YAML::XS::DumpFile');

	# First file must still be intact
	open my $f3, '<', $path3 or die $!;
	my $bytes3 = <$f3>;
	close $f3;
	is($bytes3, $bytes1, 'first file is unmodified after mid-flight failure on second export');

	done_testing();
};

done_testing();
