use strict;
use warnings;

use Test::Most;
use File::Temp  qw(tempfile tempdir);
use Readonly;
use Scalar::Util qw(refaddr);
use YAML::XS    qw(LoadFile);

use App::Test::Generator::Analyzer::SideEffect;
use App::Test::Generator::BenchmarkGenerator;
use App::Test::Generator::CoverageGuidedFuzzer;
use App::Test::Generator::Exporter::YAML;
use App::Test::Generator::Model::Method;
use App::Test::Generator::Planner::Mock;

# --------------------------------------------------
# Shared fixtures
# --------------------------------------------------

Readonly my $INT_SCHEMA => {
	function => 'identity',
	input    => { n => { type => 'integer', position => 0 } },
};

# A target that never dies — no bug entries will be recorded,
# so corpus growth reflects only interesting-input decisions.
Readonly my $SAFE_TARGET => sub { return $_[0] };

# Number of iterations small enough to keep tests fast.
Readonly my $ITERS => 15;

# Construct a fuzzer with sensible defaults.
sub _fuzzer {
	my (%args) = @_;
	return App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => $INT_SCHEMA,
		target_sub => $SAFE_TARGET,
		iterations => $ITERS,
		timeout    => 0,
		%args,
	);
}

# ======================================================
# Group 1 — CoverageGuidedFuzzer internal state DU chains
# ======================================================

subtest 'DF01 — seed D→U chain: stored at construction, immediately consumed by srand' => sub {
	# D: seed => 99 stored in new()
	# U: srand($self->{seed}) called immediately in new()
	# Invariant: object's seed field matches what was passed

	my $fuzzer = _fuzzer(seed => 99);
	is($fuzzer->{seed}, 99, 'seed stored as passed');

	# srand is called at construction, not at run() time.  Reproducibility
	# holds only when construction and run() are paired with no intervening
	# rand() calls.  Test the pair: construct → run → construct → run.
	my $f1 = _fuzzer(seed => 42);
	$f1->run();

	my $f2 = _fuzzer(seed => 42);    # srand(42) resets the global stream
	$f2->run();

	is(scalar @{ $f1->corpus }, scalar @{ $f2->corpus },
		'same seed with construct-run-construct-run pairing → identical corpus size');
};

subtest 'DF02 — stats.total DU: total_iterations == iterations after run()' => sub {
	# D: stats.total = 0 in new()
	# U: stats.total++ per main-loop iteration in run()
	# K: reported as total_iterations by _build_report

	my $fuzzer = _fuzzer(iterations => $ITERS);
	my $report = $fuzzer->run();

	is($report->{total_iterations}, $ITERS,
		'total_iterations equals the iterations arg');
};

subtest 'DF03 — corpus_size vs interesting_inputs coherence' => sub {
	# corpus_size includes SEED_CORPUS_SIZE seed entries added before
	# the main loop; interesting_inputs only counts main-loop additions.
	# Invariant: corpus_size >= interesting_inputs (seed entries are extra).

	my $fuzzer = _fuzzer();
	my $report = $fuzzer->run();

	cmp_ok($report->{corpus_size}, '>=', $report->{interesting_inputs},
		'corpus_size >= interesting_inputs (seed entries not counted as interesting)');
	is(scalar @{ $fuzzer->corpus }, $report->{corpus_size},
		'corpus() array length matches reported corpus_size');
};

subtest 'DF04 — stats.bugs vs bugs() array coherence' => sub {
	# D: bugs = [] in new()
	# U: pushed in _run_one when target dies on valid input
	# U: stats.bugs++ in same branch
	# U: both read by _build_report
	# Invariant: bugs_found == scalar @{ $fuzzer->bugs }

	my $fuzzer = _fuzzer();
	my $report = $fuzzer->run();

	is($report->{bugs_found}, scalar @{ $fuzzer->bugs },
		'bugs_found count matches bugs() array length');
	is($report->{bugs_found}, scalar @{ $report->{bugs} },
		'report bugs arrayref length matches bugs_found');
};

subtest 'DF05 — corpus ref stale after minimize_corpus (D→K→D chain)' => sub {
	# D: corpus = [] in new()
	# U: entries pushed during run()
	# K: $self->{corpus} = \@minimized in minimize_corpus() — NEW arrayref
	# Any caller holding the old corpus() ref sees stale data after minimize.

	my $fuzzer = _fuzzer();
	$fuzzer->run();

	my $ref_before = $fuzzer->corpus;          # grab ref to current array
	my $count_before = scalar @$ref_before;

	$fuzzer->minimize_corpus();

	my $ref_after = $fuzzer->corpus;           # may be a new arrayref

	# The two refs must point to different objects — minimize replaces
	# $self->{corpus} with a freshly built \@minimized.
	isnt(refaddr($ref_before), refaddr($ref_after),
		'minimize_corpus replaces corpus arrayref (old ref is now stale)');

	diag("corpus before minimize: $count_before, after: ", scalar @$ref_after)
		if $ENV{TEST_VERBOSE};
};

subtest 'DF06 — load_corpus does not restore bugs (D→ save →K on reload)' => sub {
	# D: bugs accumulated during run() saved into JSON under "bugs" key
	# K: load_corpus() only reads the "corpus" key — bugs are NOT reloaded
	# Invariant: fresh fuzzer after load_corpus has empty bugs()

	my ($fh, $path) = tempfile(SUFFIX => '.json', UNLINK => 1);
	close $fh;

	# Use a target that always dies on truthy input so we get at least
	# one bug entry (dies on what the schema considers a valid integer).
	my $die_target = sub { die "always\n" };
	my $fuzzer = App::Test::Generator::CoverageGuidedFuzzer->new(
		schema     => $INT_SCHEMA,
		target_sub => $die_target,
		iterations => $ITERS,
		timeout    => 0,
	);
	$fuzzer->run();

	# Skip if no bugs were recorded (extremely unlikely but possible if all
	# generated inputs happened to fail schema validation).
	if(!@{ $fuzzer->bugs }) {
		pass('SKIP: no bugs triggered during run — cannot test bug-load isolation');
		done_testing();
		return;
	}

	$fuzzer->save_corpus($path);

	# Load into a fresh fuzzer
	my $fresh = _fuzzer();
	$fresh->load_corpus($path);

	is(scalar @{ $fresh->bugs }, 0,
		'bugs are NOT reloaded from corpus file — fresh fuzzer starts with empty bugs');

	cmp_ok(scalar @{ $fresh->corpus }, '>', 0,
		'corpus entries ARE loaded from file');
};

subtest 'DF07 — load_corpus does not overwrite seed (D isolation)' => sub {
	# D: seed => 7 stored in fresh->new()
	# U: load_corpus reads the "seed" from the file but does NOT store it
	# Invariant: fresh->seed is 7, not the saved seed

	my ($fh, $path) = tempfile(SUFFIX => '.json', UNLINK => 1);
	close $fh;

	my $saver = _fuzzer(seed => 123);
	$saver->run();
	$saver->save_corpus($path);

	my $fresh = _fuzzer(seed => 7);
	$fresh->load_corpus($path);

	is($fresh->{seed}, 7, 'load_corpus does not overwrite fresh fuzzer\'s seed');
};

subtest 'DF08 — accumulated run() stats across two consecutive calls' => sub {
	# stats.total accumulates — it is NEVER reset between run() calls.
	# D: stats.total = 0 in new()
	# U: += ITERS in first run()
	# U: += ITERS more in second run() (additive, not reset)

	my $fuzzer = _fuzzer(iterations => $ITERS);
	my $r1 = $fuzzer->run();
	my $r2 = $fuzzer->run();

	is($r1->{total_iterations}, $ITERS,           'first run total == ITERS');
	is($r2->{total_iterations}, 2 * $ITERS,       'second run total == 2*ITERS (accumulates)');
	cmp_ok($r2->{corpus_size}, '>=', $r1->{corpus_size},
		'corpus only grows between runs');
};

# ======================================================
# Group 2 — Model::Method evidence DU chains
# ======================================================

subtest 'DF09 — evidence insertion order preserved (D→push→U list)' => sub {
	# D: evidence = [] in new()
	# U: pushed in add_evidence(), maintaining insertion order
	# U: evidence() returns them in that order

	my $m = App::Test::Generator::Model::Method->new(
		name   => 'get_x',
		source => 'sub get_x { $_[0]->{x} }',
	);

	my @signals = qw(returns_property returns_constant returns_self);
	for my $sig (@signals) {
		$m->add_evidence(category => 'return', signal => $sig, weight => 1);
	}

	my @got = map { $_->{signal} } $m->evidence;
	is_deeply(\@got, \@signals, 'evidence entries returned in insertion order');
};

subtest 'DF10 — evidence_ref() aliasing: live reference modifies internal state' => sub {
	# D: evidence = [] in new()
	# U: evidence_ref() returns the LIVE internal arrayref (no copy)
	# Mutation via the returned ref changes evidence() count — aliasing risk.

	my $m = App::Test::Generator::Model::Method->new(
		name   => 'x',
		source => 'sub x { }',
	);

	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 5);
	is(scalar($m->evidence), 1, 'one evidence entry before aliasing');

	my $ref = $m->evidence_ref;   # live ref to internal array

	# Directly mutate through the alias
	push @$ref, {
		category => 'return',
		signal   => 'returns_constant',
		weight   => 1,
	};

	is(scalar($m->evidence), 2,
		'aliasing confirmed: push to evidence_ref is visible via evidence()');

	diag('evidence_ref is the live internal arrayref, not a copy — callers must not mutate it')
		if $ENV{TEST_VERBOSE};
};

subtest 'DF11 — weight=0 stored as 0, not coerced to default of 1' => sub {
	# The guard is: defined $args{weight} ? $args{weight} : 1
	# weight => 0 is defined, so it is stored as 0, not 1.
	# A score of 0 has a different effect on resolve_confidence than 1.

	my $m = App::Test::Generator::Model::Method->new(
		name   => 'x',
		source => 'sub x { }',
	);

	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 0);

	my ($entry) = $m->evidence;
	is($entry->{weight}, 0, 'weight=0 stored as 0 (not coerced to 1)');

	# Confirm it contributes 0 to the confidence score
	my $conf = $m->resolve_confidence;
	is($conf->{score}, 0, 'score is 0 when only weight-0 evidence present');
};

subtest 'DF12 — weight omitted → defaults to 1' => sub {
	my $m = App::Test::Generator::Model::Method->new(
		name   => 'x',
		source => 'sub x { }',
	);

	$m->add_evidence(category => 'return', signal => 'returns_property');

	my ($entry) = $m->evidence;
	is($entry->{weight}, 1, 'omitted weight defaults to 1');
};

subtest 'DF13 — resolve_return_type idempotent (DD write is harmless)' => sub {
	# D: return_type = undef in new()
	# D: set to winner in resolve_return_type() call 1
	# D: set again to same winner in resolve_return_type() call 2 (DD)
	# Both writes produce the same value from the same evidence — no bug.

	my $m = App::Test::Generator::Model::Method->new(
		name   => 'x',
		source => 'sub x { }',
	);

	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 10);

	my $first  = $m->resolve_return_type;
	my $second = $m->resolve_return_type;

	is($first,  'property', 'first resolve gives property');
	is($second, 'property', 'second resolve gives same result (idempotent DD write)');
};

subtest 'DF14 — evidence isolation between two Method objects' => sub {
	# D: each object has its own evidence = [] in new()
	# Adding evidence to one must not bleed into the other.

	my $m1 = App::Test::Generator::Model::Method->new(
		name   => 'get_name',
		source => 'sub get_name { $_[0]->{name} }',
	);
	my $m2 = App::Test::Generator::Model::Method->new(
		name   => 'chain',
		source => 'sub chain { $_[0] }',
	);

	$m1->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	$m2->add_evidence(category => 'return', signal => 'returns_self',     weight => 20);

	is($m1->resolve_return_type, 'property', 'm1 resolves to property');
	is($m2->resolve_return_type, 'object',   'm2 resolves to object');

	is(scalar($m1->evidence), 1, 'm1 evidence count unaffected by m2');
	is(scalar($m2->evidence), 1, 'm2 evidence count unaffected by m1');
};

# ======================================================
# Group 3 — Exporter::YAML round-trip DU
# ======================================================

subtest 'DF15 — plan round-trip: write then read is_deeply equal' => sub {
	# D: $plan hashref (complex nested structure)
	# U: passed through validate_strict → DumpFile (O-U)
	# U: loaded back via LoadFile (U)
	# Invariant: LoadFile(DumpFile($plan)) ≅ $plan

	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	close $fh;

	my $plan = {
		strategy  => { getter_test => 1, setter_test => 0 },
		isolation => { fixture => 'fresh_object' },
		metadata  => { version => 2, tags => [qw(unit fast)] },
	};

	# Exporter::YAML has no new() — construct via bless as existing tests do
	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';
	$exporter->export($plan, $path);

	# File must be readable (O-U-K chain closed properly)
	ok(-f $path && -s $path, 'YAML file written and non-empty');

	my $loaded = LoadFile($path);
	is_deeply($loaded, $plan, 'round-trip: loaded YAML is_deeply equal to original plan');
};

subtest 'DF16 — undef plan croaks (required field missing from %args)' => sub {
	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';
	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	close $fh;

	throws_ok(
		sub { $exporter->export(undef, $path) },
		qr/required|missing|plan/i,
		'export with undef plan croaks',
	);
};

subtest 'DF17 — undef file croaks (required field missing from %args)' => sub {
	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';

	throws_ok(
		sub { $exporter->export({a => 1}, undef) },
		qr/required|missing|file/i,
		'export with undef file croaks',
	);
};

subtest 'DF18 — file handle closed after export (O-U-K chain complete)' => sub {
	# After export() returns the file must be readable without any
	# further action by the caller — the handle is closed inside export().

	my ($fh, $path) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	close $fh;

	my $exporter = bless {}, 'App::Test::Generator::Exporter::YAML';
	$exporter->export({ x => 1 }, $path);

	# If the handle were still open for writing, ReadFile might see 0 bytes
	# or a partial write; LoadFile would then croak.  A clean load proves
	# the handle was properly closed.
	my $loaded;
	lives_ok(
		sub { $loaded = LoadFile($path) },
		'LoadFile succeeds immediately after export — file handle was closed',
	);
	is($loaded->{x}, 1, 'data correct after close-and-reopen');
};

# ======================================================
# Group 4 — Analyzer::SideEffect analyze DU chains
# ======================================================

subtest 'DF19 — purity_level derived after all flag assignments' => sub {
	# D: %result = (...) with all flags 0
	# U: mutates_self=1 set by $self->{field}= pattern
	# U: mutates_globals=1 set by GLOBAL_PATTERN
	# D: purity_level computed AFTER both assignments
	# Invariant: mutates_self AND mutates_globals → purity_level='impure'

	my $analyzer = App::Test::Generator::Analyzer::SideEffect->new;

	my $report = $analyzer->analyze({
		body => '$self->{x} = 1; $ENV{FOO} = 1;'
	});

	is($report->{mutates_self},    1,        'mutates_self detected');
	is($report->{mutates_globals}, 1,        'mutates_globals detected');
	is($report->{purity_level},    'impure', 'purity_level=impure when both flags set');

	diag('purity classification: ', $report->{purity_level}) if $ENV{TEST_VERBOSE};
};

subtest 'DF20 — mutation_fields deduplication (DD-free accumulation)' => sub {
	# D: %seen_fields = () before the while loop
	# U: $seen_fields{$field}++ checked/set for each match
	# Invariant: same field appearing twice → once in mutation_fields

	my $analyzer = App::Test::Generator::Analyzer::SideEffect->new;

	my $report = $analyzer->analyze({
		body => <<'BODY'
$self->{x} = 1;
$self->{y} = 2;
$self->{x} = 3;
BODY
	});

	is($report->{mutates_self}, 1, 'mutates_self set');

	my @fields = @{ $report->{mutation_fields} };
	my %uniq = map { $_ => 1 } @fields;

	is(scalar keys %uniq, scalar @fields,
		'mutation_fields contains no duplicates');

	ok(grep({ $_ eq 'x' } @fields), 'field x present');
	ok(grep({ $_ eq 'y' } @fields), 'field y present');
};

subtest 'DF21 — empty body → all flags 0, purity_level=pure (D only, no U)' => sub {
	# D: %result initialized with all zeros
	# No matches → flags stay at 0 → purity_level=pure
	# This is a D~ test: flags are defined and used only in the return value

	my $analyzer = App::Test::Generator::Analyzer::SideEffect->new;
	my $report = $analyzer->analyze({ body => '' });

	is($report->{mutates_self},    0,      'mutates_self=0 for empty body');
	is($report->{mutates_globals}, 0,      'mutates_globals=0 for empty body');
	is($report->{performs_io},     0,      'performs_io=0 for empty body');
	is($report->{calls_external},  0,      'calls_external=0 for empty body');
	is($report->{purity_level},    'pure', 'purity_level=pure for empty body');
	is_deeply($report->{mutation_fields}, [], 'mutation_fields empty for empty body');
};

subtest 'DF22 — IO keyword inside string literal stripped from code_only (U on stripped copy)' => sub {
	# D: $code_only = _strip_strings_and_comments($body)
	# U: IO_PATTERN matched against $code_only, not $body
	# Invariant: "print" inside a string literal must not trigger performs_io

	my $analyzer = App::Test::Generator::Analyzer::SideEffect->new;

	my $report = $analyzer->analyze({
		body => 'my $msg = "print this to screen"; return $msg;'
	});

	is($report->{performs_io}, 0,
		'IO keyword inside string literal does not trigger performs_io');
};

subtest 'DF23 — distinct mutation_fields: two different fields both appear' => sub {
	# D: %seen_fields tracks each new field
	# U: push only when field is NEW (first occurrence)
	# Invariant: two distinct fields → both in mutation_fields

	my $analyzer = App::Test::Generator::Analyzer::SideEffect->new;

	my $report = $analyzer->analyze({
		body => '$self->{alpha} = 1; $self->{beta} = 2;'
	});

	my @fields = sort @{ $report->{mutation_fields} };
	is_deeply(\@fields, [qw(alpha beta)],
		'both distinct fields present in mutation_fields (sorted)');
};

# ======================================================
# Group 5 — Planner::Mock plan DU chains
# ======================================================

subtest 'DF24 — pure method (no _analysis) omitted from plan (D~ for $effects)' => sub {
	# D: $effects = {} (default) for method with no _analysis
	# U: $effects->{calls_external} and $effects->{performs_io} both falsy
	# $mock_plan{$method} is never set → method absent from result

	my $planner = App::Test::Generator::Planner::Mock->new;

	my $plan = $planner->plan({
		pure_method => { description => 'no side effects' }
	});

	ok(!exists $plan->{pure_method},
		'pure method (no _analysis key) is omitted from mock plan');
};

subtest 'DF25 — calls_external only → mock_system scalar' => sub {
	my $planner = App::Test::Generator::Planner::Mock->new;

	my $plan = $planner->plan({
		launcher => {
			_analysis => { side_effects => { calls_external => 1, performs_io => 0 } }
		}
	});

	is($plan->{launcher}, 'mock_system',
		'calls_external-only method gets mock_system scalar');
};

subtest 'DF26 — performs_io only → capture_io scalar' => sub {
	my $planner = App::Test::Generator::Planner::Mock->new;

	my $plan = $planner->plan({
		writer => {
			_analysis => { side_effects => { calls_external => 0, performs_io => 1 } }
		}
	});

	is($plan->{writer}, 'capture_io',
		'performs_io-only method gets capture_io scalar');
};

subtest 'DF27 — both effects → arrayref [mock_system, capture_io]' => sub {
	my $planner = App::Test::Generator::Planner::Mock->new;

	my $plan = $planner->plan({
		heavy => {
			_analysis => { side_effects => { calls_external => 1, performs_io => 1 } }
		}
	});

	is(ref($plan->{heavy}), 'ARRAY',
		'both effects → arrayref result');
	is_deeply($plan->{heavy}, ['mock_system', 'capture_io'],
		'arrayref contains mock_system then capture_io');
};

# ======================================================
# Group 6 — BenchmarkGenerator schema DU chains
# ======================================================

subtest 'DF28 — schema without input key: %input = {} (no croak on empty hash)' => sub {
	# D: %input = %{ $schema->{input} // {} }  — undef coerced to {}
	# U: %input iterated for representative values → empty → no params emitted
	# Invariant: generate() must not croak when input is absent

	my $schema = { module => 'Scalar::Util', function => 'blessed' };
	my $bg     = App::Test::Generator::BenchmarkGenerator->new(schema => $schema);
	my $output;

	lives_ok(sub { $output = $bg->generate }, 'generate() survives schema with no input key');
	ok(defined($output) && length($output), 'output is non-empty');
};

subtest 'DF29 — schema without transforms key: single default variant emitted' => sub {
	# D: %xforms = %{ $schema->{transforms} // {} } — undef coerced to {}
	# U: if(!%xforms) branch taken → single 'default' variant emitted
	# Invariant: output contains 'default' when transforms absent

	my $schema = {
		module   => 'POSIX',
		function => 'floor',
		input    => { x => { type => 'number', position => 0 } },
	};
	my $bg     = App::Test::Generator::BenchmarkGenerator->new(schema => $schema);
	my $output = $bg->generate;

	like($output, qr/'default'/, "output contains 'default' variant when no transforms");
};

subtest 'DF30 — schema hashref not mutated by generate() (D-preserve invariant)' => sub {
	# D: schema stored in $self->{schema} at new()
	# U: generate() reads from it — must not write back
	# Invariant: deep comparison before and after generate() is equal

	my $schema = {
		module   => 'List::Util',
		function => 'sum',
		input    => { list => { type => 'arrayref', position => 0 } },
	};

	# Deep copy to compare against
	require Storable;
	my $schema_copy = Storable::dclone($schema);

	my $bg = App::Test::Generator::BenchmarkGenerator->new(schema => $schema);
	$bg->generate;

	is_deeply($schema, $schema_copy,
		'schema hashref is not mutated by generate()');
};

# ==================================================================
# GROUP A: Analyzer::Complexity DU chains (DF31-DF36)
# ==================================================================

use App::Test::Generator::Analyzer::Complexity;

# Helper: build a minimal method hashref with the given body string.
sub _method { { body => $_[0] } }

subtest 'DF31 — cyclomatic_score D-U chain: computed from tokens, not mutated after' => sub {
	# D: cyclomatic_score set inside analyze()
	# U: returned in the result hashref
	# Invariant: modifying the returned hashref does not affect the analyser

	my $ca  = App::Test::Generator::Analyzer::Complexity->new;
	my $res = $ca->analyze(_method('if($x){return 1} return 0'));

	ok(exists $res->{cyclomatic_score}, 'cyclomatic_score key present');
	ok($res->{cyclomatic_score} >= 2,   'if + early-return raises score above 1');

	# Mutate the returned value — the analyser must not share state
	my $orig = $res->{cyclomatic_score};
	$res->{cyclomatic_score} = 9999;

	my $res2 = $ca->analyze(_method('if($x){return 1} return 0'));
	is($res2->{cyclomatic_score}, $orig, 'analyser state unaffected by caller mutation');
};

subtest 'DF32 — early_returns counter DU: 0 for 1 return, 1 for 2, 2 for 3' => sub {
	# D: early_returns = max(0, return_count - 1) inside analyze()
	# U: returned in result hashref

	my $ca = App::Test::Generator::Analyzer::Complexity->new;

	my $r1 = $ca->analyze(_method('return 1;'));
	is($r1->{early_returns}, 0, '1 return → 0 early returns');

	my $r2 = $ca->analyze(_method('return 1; return 0;'));
	is($r2->{early_returns}, 1, '2 returns → 1 early return');

	my $r3 = $ca->analyze(_method('return 1; return 2; return 3;'));
	is($r3->{early_returns}, 2, '3 returns → 2 early returns');
};

subtest 'DF33 — nesting_depth counter: opens on {, closes on }, never below 0' => sub {
	# D: depth initialised to 0, incremented per {, decremented per } (guarded)
	# U: max_depth written to nesting_depth in result

	my $ca = App::Test::Generator::Analyzer::Complexity->new;

	my $flat = $ca->analyze(_method('my $x = 1;'));
	is($flat->{nesting_depth}, 0, 'no braces → depth 0');

	my $one = $ca->analyze(_method('{ my $x = 1; }'));
	is($one->{nesting_depth}, 1, 'one brace pair → depth 1');

	my $two = $ca->analyze(_method('{ { my $x = 1; } }'));
	is($two->{nesting_depth}, 2, 'nested braces → depth 2');

	# Unmatched } must not underflow below 0
	my $unmatched = $ca->analyze(_method('}'));
	ok($unmatched->{nesting_depth} >= 0, 'unmatched } does not produce negative depth');
};

subtest 'DF34 — $code_only DU: keywords inside strings not counted' => sub {
	# D: $code_only = _strip_strings_and_comments($body)
	# U: all pattern-match counts run against $code_only, not $body
	# If "if" inside a string were counted, cyclomatic_score would be > 1 for an
	# otherwise empty method body.

	my $ca = App::Test::Generator::Analyzer::Complexity->new;

	# "if" inside a double-quoted string — must not increment branching_points
	my $r = $ca->analyze(_method(q{my $msg = "if you're sure";}));
	is($r->{branching_points}, 0, '"if" inside string literal not counted as branch');
	is($r->{cyclomatic_score}, 1, 'cyclomatic score stays at base (1)');
};

subtest 'DF35 — complexity_level resolved from cyclomatic_score (threshold boundaries)' => sub {
	# D: complexity_level written based on score <= LOW_THRESHOLD (3), HIGH_THRESHOLD (7)
	# U: returned in result hashref; always present

	my $ca = App::Test::Generator::Analyzer::Complexity->new;

	# Score 1 (base, no branches) → low
	my $low = $ca->analyze(_method('my $x = 1;'));
	is($low->{complexity_level}, 'low', 'score 1 → low');

	# Score 4 (base + 3 ifs) → moderate (one above LOW_THRESHOLD)
	my $mod_body = join("\n", map { 'if($x){}' } 1..3);
	my $mod = $ca->analyze(_method($mod_body));
	is($mod->{complexity_level}, 'moderate', 'score 4 → moderate');

	# Score 8 (base + 7 ifs) → high (one above HIGH_THRESHOLD)
	my $high_body = join("\n", map { 'if($x){}' } 1..7);
	my $high = $ca->analyze(_method($high_body));
	is($high->{complexity_level}, 'high', 'score 8 → high');

	# Key always present regardless of body
	ok(exists $low->{complexity_level}, 'complexity_level key always in result');
};

subtest 'DF36 — two independent analyze() calls produce independent results' => sub {
	# Verify no shared mutable state is retained between calls

	my $ca = App::Test::Generator::Analyzer::Complexity->new;

	my $a = $ca->analyze(_method('if($x){ if($y){} }'));
	my $b = $ca->analyze(_method('my $z = 1;'));

	isnt($a->{cyclomatic_score}, $b->{cyclomatic_score},
		'two different bodies produce different scores');
	is($b->{branching_points}, 0,
		'second call not contaminated by first call branches');
};

# ==================================================================
# GROUP B: Planner::Isolation DU chains (DF37-DF42)
# ==================================================================

use App::Test::Generator::Planner::Isolation;

Readonly my $STRATEGY_ALL => { m => 1 };

# Helper: build a schema for method 'm' with given purity and deps.
sub _iso_schema {
	my (%opts) = @_;
	return {
		m => {
			_analysis => {
				side_effects => { purity_level => $opts{purity} // 'pure' },
				dependencies => $opts{deps} // {},
			},
		},
	};
}

subtest 'DF37 — fixture key: pure→shared_fixture, self_mutating→fresh_object, impure→isolated_block' => sub {
	my $pl = App::Test::Generator::Planner::Isolation->new;

	my $r_pure = $pl->plan(_iso_schema(purity => 'pure'), $STRATEGY_ALL);
	is($r_pure->{m}{fixture}, 'shared_fixture', 'pure → shared_fixture');

	my $r_self = $pl->plan(_iso_schema(purity => 'self_mutating'), $STRATEGY_ALL);
	is($r_self->{m}{fixture}, 'fresh_object', 'self_mutating → fresh_object');

	my $r_imp = $pl->plan(_iso_schema(purity => 'impure'), $STRATEGY_ALL);
	is($r_imp->{m}{fixture}, 'isolated_block', 'impure → isolated_block');
};

subtest 'DF38 — env key: empty hashref propagated (truthy ref), scalar 0 omitted, hashref stored verbatim' => sub {
	my $pl = App::Test::Generator::Planner::Isolation->new;

	# env => {} — empty hashref is truthy as a ref — must propagate
	my $r_empty = $pl->plan(_iso_schema(deps => { env => {} }), $STRATEGY_ALL);
	ok(exists $r_empty->{m}{env}, 'env => {} (truthy ref) propagated');

	# env => 0 — falsy scalar — must be omitted
	my $r_zero = $pl->plan(_iso_schema(deps => { env => 0 }), $STRATEGY_ALL);
	ok(!exists $r_zero->{m}{env}, 'env => 0 (falsy scalar) omitted');

	# env => {K=>V} — stored verbatim
	my $env_hash = { HOME => '/tmp/test' };
	my $r_full = $pl->plan(_iso_schema(deps => { env => $env_hash }), $STRATEGY_ALL);
	is_deeply($r_full->{m}{env}, $env_hash, 'env hashref stored verbatim');
};

subtest 'DF39 — time key: falsy omitted, truthy normalised to 1' => sub {
	my $pl = App::Test::Generator::Planner::Isolation->new;

	my $r0 = $pl->plan(_iso_schema(deps => { time => 0 }), $STRATEGY_ALL);
	ok(!exists $r0->{m}{time}, 'time => 0 omitted from plan');

	my $r1 = $pl->plan(_iso_schema(deps => { time => 1 }), $STRATEGY_ALL);
	is($r1->{m}{time}, 1, 'time => 1 normalised to 1');
};

subtest 'DF40 — network key: falsy omitted, truthy normalised to 1' => sub {
	my $pl = App::Test::Generator::Planner::Isolation->new;

	my $r0 = $pl->plan(_iso_schema(deps => { network => '' }), $STRATEGY_ALL);
	ok(!exists $r0->{m}{network}, 'network => "" omitted');

	my $r1 = $pl->plan(_iso_schema(deps => { network => 1 }), $STRATEGY_ALL);
	is($r1->{m}{network}, 1, 'network => 1 normalised');
};

subtest 'DF41 — filesystem key: falsy omitted, truthy stored as-is' => sub {
	my $pl = App::Test::Generator::Planner::Isolation->new;

	my $r0 = $pl->plan(_iso_schema(deps => { filesystem => '' }), $STRATEGY_ALL);
	ok(!exists $r0->{m}{filesystem}, 'filesystem => "" omitted');

	my $fs = { path => '/tmp/data' };
	my $r1 = $pl->plan(_iso_schema(deps => { filesystem => $fs }), $STRATEGY_ALL);
	is_deeply($r1->{m}{filesystem}, $fs, 'filesystem hashref propagated');
};

subtest 'DF42 — two independent plan() calls produce independent result hashrefs' => sub {
	my $pl = App::Test::Generator::Planner::Isolation->new;

	my $r1 = $pl->plan(_iso_schema(purity => 'pure'), $STRATEGY_ALL);
	my $r2 = $pl->plan(_iso_schema(purity => 'impure'), $STRATEGY_ALL);

	isnt($r1->{m}{fixture}, $r2->{m}{fixture}, 'independent calls give different fixtures');

	# Mutating one result must not affect the other
	$r1->{m}{fixture} = 'CORRUPTED';
	my $r3 = $pl->plan(_iso_schema(purity => 'pure'), $STRATEGY_ALL);
	is($r3->{m}{fixture}, 'shared_fixture', 'analyser state not contaminated by r1 mutation');
};

# ==================================================================
# GROUP C: Mutator private state DU chains (DF43-DF48)
# ==================================================================

use App::Test::Generator::Mutator;
use File::Spec;
use File::Path qw(make_path);
use Cwd        qw(cwd);

# Helper: build a minimal .pm file under a temp dir's lib/ and return
# (mutator, tmpdir, pm_file) — the Mutator is ready to generate mutants.
sub _mutator_in_tmp {
	my $tmpdir = tempdir(CLEANUP => 1);
	my $lib    = File::Spec->catdir($tmpdir, 'lib');
	make_path($lib);
	my $pm = File::Spec->catfile($lib, 'Foo.pm');
	open my $fh, '>', $pm or die $!;
	print $fh "package Foo;\nsub bar { return 1 }\n1;\n";
	close $fh;

	my $m = App::Test::Generator::Mutator->new(
		file    => $pm,
		lib_dir => 'lib',
	);
	return ($m, $tmpdir, $pm);
}

# Helper: chdir into $dir, call $code, chdir back; propagate exceptions.
sub _in_dir {
	my ($dir, $code) = @_;
	my $orig = cwd();
	chdir $dir or die "chdir $dir: $!";
	my @r = eval { $code->() };
	my $e = $@;
	chdir $orig;
	die $e if $e;
	return @r;
}

subtest 'DF43 — _workspace key: absent before prepare_workspace(), defined after; lib_dir unchanged' => sub {
	my ($m, $tmpdir) = _mutator_in_tmp();

	ok(!exists $m->{_workspace}, '_workspace absent before prepare_workspace()');
	is($m->{lib_dir}, 'lib', 'lib_dir is "lib" before prepare_workspace()');

	_in_dir($tmpdir, sub { $m->prepare_workspace() });

	ok(defined $m->{_workspace}, '_workspace defined after prepare_workspace()');
	is($m->{lib_dir}, 'lib', 'lib_dir unchanged after prepare_workspace()');
};

subtest 'DF44 — _relative key: set during prepare_workspace(); ends with the .pm filename' => sub {
	# D: _relative = file with lib_dir prefix stripped inside prepare_workspace()
	# U: apply_mutant reads _relative to locate the file in the workspace
	# When file is an absolute path and lib_dir is 'lib', the strip removes
	# the 'lib/' component that actually appears in the path (if present),
	# leaving a path that ends with the module filename.

	my ($m, $tmpdir) = _mutator_in_tmp();

	_in_dir($tmpdir, sub { $m->prepare_workspace() });

	ok(defined $m->{_relative}, '_relative key set');
	like($m->{_relative}, qr/Foo\.pm$/, '_relative ends with the pm filename');
};

subtest 'DF45 — _lib_basename key: set during prepare_workspace()' => sub {
	my ($m, $tmpdir) = _mutator_in_tmp();

	_in_dir($tmpdir, sub { $m->prepare_workspace() });

	ok(defined $m->{_lib_basename}, '_lib_basename key set');
	is($m->{_lib_basename}, 'lib', '_lib_basename matches the lib_dir argument');
};

subtest 'DF46 — generate_mutants() context-sensitive: list→flat list, scalar→arrayref' => sub {
	# wantarray-sensitive API: list context returns a flat list of Mutant objects;
	# scalar context returns an arrayref containing the same data.
	# Two separate calls produce independent object sets — we verify type and count,
	# not object identity across calls.

	my ($m1, $tmpdir1) = _mutator_in_tmp();
	my ($m2, $tmpdir2) = _mutator_in_tmp();

	my @list_result = _in_dir($tmpdir1, sub { $m1->generate_mutants() });

	# Scalar context — call directly (not through _in_dir which forces list context)
	my $orig = cwd();
	chdir $tmpdir2 or die "chdir: $!";
	my $scalar_result = $m2->generate_mutants();   # wantarray false → arrayref
	chdir $orig;

	ok(ref($scalar_result) eq 'ARRAY', 'scalar context returns arrayref');
	is(scalar @list_result, scalar @{$scalar_result},
		'list and arrayref contain the same number of mutants');

	# Every element in list context is a Mutant
	for my $mut (@list_result) {
		isa_ok($mut, 'App::Test::Generator::Mutant');
	}
};

subtest 'DF47 — mutant objects are independent: modifying one does not affect another' => sub {
	my ($m, $tmpdir) = _mutator_in_tmp();

	my @mutants = _in_dir($tmpdir, sub { $m->generate_mutants() });
	skip 'no mutants generated for this body', 1 unless @mutants >= 2;

	my $orig_desc = $mutants[1]->{description};
	$mutants[0]->{description} = 'CORRUPTED';

	is($mutants[1]->{description}, $orig_desc,
		'modifying mutant[0] description does not affect mutant[1]');
};

subtest 'DF48 — apply_mutant() without prepare_workspace() croaks "Workspace not prepared"' => sub {
	my ($m, $tmpdir) = _mutator_in_tmp();

	# generate_mutants() first so we have something to pass to apply_mutant
	my @mutants = _in_dir($tmpdir, sub { $m->generate_mutants() });
	skip 'no mutants to apply', 1 unless @mutants;

	# No prepare_workspace() called — _workspace key is absent
	throws_ok(
		sub { $m->apply_mutant($mutants[0]) },
		qr/Workspace not prepared/,
		'apply_mutant() without prepare_workspace() croaks',
	);
};

done_testing();
