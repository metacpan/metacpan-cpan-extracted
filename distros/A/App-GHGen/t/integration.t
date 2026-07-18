#!/usr/bin/env perl
# t/integration.t
# Black-box end-to-end tests validating stateful cross-module workflows.
# Each subtest exercises a pipeline that spans two or more App::GHGen:: modules.
use v5.36;
use strict;
use warnings;

use Cwd        qw(getcwd);
use File::Temp qw(tempdir);
use IPC::Run3  qw(run3);
use Path::Tiny;
use Readonly;
use Test::Most;
use Test::Returns;
use Test::Mockingbird qw(spy mock restore_all);
use YAML::XS          qw(LoadFile DumpFile);

# Both CostEstimator and Reporter export estimate_savings; to avoid name
# shadowing we import selectively and call each variant by full package name.
use App::GHGen::Analyzer      qw(analyze_workflow find_workflows get_cache_suggestion);
use App::GHGen::CostEstimator qw(estimate_current_usage estimate_workflow_cost);
use App::GHGen::Detector      qw(detect_project_type get_project_indicators);
use App::GHGen::Fixer         qw(apply_fixes can_auto_fix fix_workflow);
use App::GHGen::Generator     qw(generate_workflow list_workflow_types);
use App::GHGen::PerlCustomizer qw(detect_perl_requirements generate_custom_perl_workflow);
use App::GHGen::Reporter      qw(generate_markdown_report generate_github_comment);

# ---------------------------------------------------------------------------
# Constants matching POD-documented thresholds

Readonly::Scalar my $FREE_TIER_MINUTES   => 2_000;
Readonly::Scalar my $COST_PER_MINUTE     => 0.008;
Readonly::Scalar my $DEFAULT_TIMEOUT_MIN => 30;

# ---------------------------------------------------------------------------
# Helpers

# in_tempdir: chdir to a fresh tempdir, run $code, then restore original CWD.
# Uses signatures (v5.36), not prototype syntax.
sub in_tempdir ($code) {
	my $orig = getcwd();
	my $dir  = tempdir(CLEANUP => 1);
	chdir $dir;
	eval { $code->() };
	my $err = $@;
	chdir $orig;
	die $err if $err;
}

# ---------------------------------------------------------------------------
# Fixture factories -- return a fresh, independently mutable hashref each time
# so subtests can pass them to apply_fixes without affecting one another.

sub _problem_workflow () {
	# Deliberately missing every best practice: no caching, outdated runner,
	# unpinned action, broad trigger, no concurrency, no timeout.
	return {
		name => 'Problem CI',
		on   => [qw(push)],
		jobs => {
			build => {
				'runs-on' => 'ubuntu-18.04',
				steps     => [
					{ uses => 'actions/checkout@main' },
					{ run  => 'npm install' },
					{ run  => 'npm test' },
				],
			},
		},
	};
}

sub _clean_workflow () {
	# Satisfies every Analyzer check: caching, concurrency, pinned actions,
	# branch-filtered trigger, current runner, and timeout-minutes.
	return {
		name        => 'Clean CI',
		on          => { push => { branches => ['main'] } },
		concurrency => {
			group              => '${{ github.workflow }}-${{ github.ref }}',
			'cancel-in-progress' => 'true',
		},
		jobs => {
			build => {
				'runs-on'         => 'ubuntu-latest',
				'timeout-minutes' => $DEFAULT_TIMEOUT_MIN,
				steps             => [
					{ uses => 'actions/checkout@v6' },
					{
						uses => 'actions/cache@v5',
						with => { path => '~/.npm', key => '${{ runner.os }}-node' },
					},
					{ run  => 'npm install' },
					{ run  => 'npm test' },
				],
			},
		},
	};
}

# ---------------------------------------------------------------------------
# Subtest 1: Analyzer -> Reporter markdown pipeline
# Verify that the issue list produced by Analyzer flows correctly into
# generate_markdown_report and produces structured output that reflects
# the issue types found.
subtest 'Analyzer + Reporter: issue list populates markdown report' => sub {
	my @issues = analyze_workflow(_problem_workflow(), 'problem.yml');
	ok(@issues > 0, 'Analyzer returns issues from problem workflow');

	my $report = generate_markdown_report(\@issues);
	ok(defined $report && length $report > 0, 'Reporter returns non-empty string');
	like($report, qr/# GHGen Workflow Analysis/, 'Report begins with documented heading');
	like($report, qr/## Issues by Category/,     'Issues section present when issues exist');

	# Every type that Analyzer found must appear in the report body.
	my %found_types = map { $_->{type} => 1 } @issues;
	for my $type (sort keys %found_types) {
		like($report, qr/\Q$type\E/i, "Report mentions issue type '$type'");
	}

	# performance/cost issues mean savings > 0, so savings section should appear.
	my @perf_cost = grep { $_->{type} =~ /^(?:performance|cost)$/ } @issues;
	if (@perf_cost) {
		like($report, qr/Estimated Savings/,
			'Savings section present when performance/cost issues detected');
	}

	diag('Issue types: ' . join(', ', sort keys %found_types)) if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# Subtest 2: Analyzer -> Reporter GitHub comment (no-issues early return)
# The POD for generate_github_comment documents an early return when the
# issues list is empty.  Verify that path end-to-end.
subtest 'Analyzer + Reporter: GitHub comment reflects no-issues state' => sub {
	# CLEAN_WORKFLOW passes every Analyzer check; issues should be empty.
	my @issues = analyze_workflow(_clean_workflow(), 'clean.yml');
	is(scalar @issues, 0, 'Clean workflow has zero issues');

	my $comment = generate_github_comment(\@issues, []);
	like($comment, qr/GHGen Workflow Analysis/,
		'Comment has documented heading even on early return');
	like($comment, qr/No issues found!/,
		'Early-return phrase present when issues list is empty');
	unlike($comment, qr/View Details/,
		'Details block absent on early return');
};

# ---------------------------------------------------------------------------
# Subtest 3: Analyzer -> Reporter GitHub comment (with issues, no fixes)
# POD: |fixes| = 0 and |issues| > 0  =>  "How to Fix" section present.
subtest 'Analyzer + Reporter: how-to-fix section when issues but no fixes' => sub {
	my @issues = analyze_workflow(_problem_workflow(), 'p.yml');
	ok(@issues > 0, 'Problem workflow produces issues');

	my $comment = generate_github_comment(\@issues, []);
	like($comment, qr/How to Fix/,
		'How-to-fix section appears when issues exist and no fixes applied');
	like($comment, qr/ghgen analyze/,
		'How-to-fix section references ghgen command');
};

# ---------------------------------------------------------------------------
# Subtest 4: Analyzer -> Fixer -> re-Analyzer round-trip (in-memory)
# Validates that Fixer mutations are meaningful: a second Analyzer pass
# on the mutated workflow finds fewer issues than the first pass.
subtest 'Analyzer + Fixer: apply_fixes reduces issue count on re-analysis' => sub {
	my $workflow = _problem_workflow();

	my @before       = analyze_workflow($workflow, 'before.yml');
	my $before_count = scalar @before;
	ok($before_count > 0, "Before: $before_count issue(s) found");

	my $fix_count = apply_fixes($workflow, \@before);
	cmp_ok($fix_count, '>', 0, "apply_fixes applied at least one fix ($fix_count)");

	my @after       = analyze_workflow($workflow, 'after.yml');
	my $after_count = scalar @after;
	cmp_ok($after_count, '<', $before_count,
		"Re-analysis finds fewer issues ($after_count < $before_count) after fixes");

	diag("Before: $before_count  After: $after_count  Fixes: $fix_count") if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# Subtest 5: Analyzer -> CostEstimator::estimate_savings data-flow
# Issues detected by Analyzer are fed into CostEstimator::estimate_savings.
# Every detail entry must correspond to an issue type that Analyzer actually found.
subtest 'Analyzer + CostEstimator: savings details reflect detected issues' => sub {
	my @issues  = analyze_workflow(_problem_workflow(), 'cost.yml');
	my $savings = App::GHGen::CostEstimator::estimate_savings(\@issues);

	ok(ref $savings eq 'HASH',            'estimate_savings returns a HashRef');
	ok(exists $savings->{minutes},        'minutes key present');
	ok(exists $savings->{cost},           'cost key present');
	ok(exists $savings->{details},        'details key present');
	ok(ref $savings->{details} eq 'ARRAY','details is an ArrayRef');
	ok(exists $savings->{percentage},     'percentage key present');

	my %analyzed_types = map { $_->{type} => 1 } @issues;
	for my $detail (@{$savings->{details}}) {
		ok(exists $analyzed_types{ $detail->{issue_type} },
			"Savings detail type '$detail->{issue_type}' corresponds to a detected issue type");
		diag("  Detail: $detail->{description} ($detail->{minutes} min)") if $ENV{TEST_VERBOSE};
	}

	# The problem workflow has a caching performance issue, which contributes savings.
	my $has_caching = grep { $_->{type} eq 'performance' && $_->{message} =~ /caching/ } @issues;
	cmp_ok($savings->{minutes}, '>', 0, 'Nonzero savings when caching issue detected')
		if $has_caching;
};

# ---------------------------------------------------------------------------
# Subtest 6: CostEstimator::estimate_savings with workflow files (percentage path)
# When workflow files are provided, the function proportions savings against
# current usage.  Mock LoadFile in CostEstimator's namespace so the test does
# not need real files.
subtest 'Analyzer + CostEstimator: savings percentage computed when workflows provided' => sub {
	my $mock_wf = {
		name => 'Mock WF',
		on   => { push => {} },
		jobs => { build => { steps => [{ run => 'npm install' }, { run => 'npm test' }] } },
	};
	mock 'App::GHGen::CostEstimator::LoadFile' => sub { return $mock_wf };

	my @issues  = (
		{
			type     => 'performance',
			severity => 'medium',
			message  => 'No dependency caching found - increases build times and costs',
		},
	);
	my $fake_path = Path::Tiny->new('/fake/ci.yml');
	my $savings   = App::GHGen::CostEstimator::estimate_savings(\@issues, [$fake_path]);

	cmp_ok($savings->{percentage}, '>=', 0,   'percentage is non-negative');
	cmp_ok($savings->{percentage}, '<=', 100, 'percentage is at most 100');
	cmp_ok($savings->{minutes},    '>',  0,   'nonzero minutes for caching issue');
	diag("Savings %: $savings->{percentage}")  if $ENV{TEST_VERBOSE};

	restore_all();
};

# ---------------------------------------------------------------------------
# Subtest 7: Detector -> Generator pipeline
# detect_project_type() in a Perl project directory should return 'perl',
# and generate_workflow('perl') must produce non-empty, Perl-specific YAML.
subtest 'Detector + Generator: detected type produces valid Perl workflow YAML' => sub {
	in_tempdir(sub {
		path('cpanfile')->spew("requires 'perl', '5.036';\n");
		path('Makefile.PL')->spew("use ExtUtils::MakeMaker;\n");
		path('lib')->mkpath;
		path('lib/MyApp.pm')->spew("package MyApp; 1;\n");
		path('t')->mkpath;

		my $detected = detect_project_type();
		is($detected, 'perl', 'detect_project_type returns perl in a Perl project dir');

		my $yaml = generate_workflow($detected);
		ok(defined $yaml && length $yaml > 0, 'generate_workflow returns non-empty YAML');
		like($yaml, qr/Perl/,               'YAML references Perl');
		like($yaml, qr/actions-setup-perl/, 'YAML uses the Perl setup action');
		like($yaml, qr/AUTOMATED_TESTING/,  'YAML sets AUTOMATED_TESTING env var');
	});
};

# ---------------------------------------------------------------------------
# Subtest 8: Detector list context in a Perl project
# In list context, detect_project_type() must return detections sorted by
# descending score with 'perl' ranked highest.
subtest 'Detector: list context returns descending-score ranked detections' => sub {
	in_tempdir(sub {
		path('cpanfile')->spew("requires 'perl', '5.036';\n");
		path('Makefile.PL')->spew("use ExtUtils::MakeMaker;\n");
		path('META.json')->spew('{"name":"Test"}');
		path('lib')->mkpath;
		path('t')->mkpath;

		my @ranked = detect_project_type();
		ok(@ranked > 0, 'list context returns at least one detection for a Perl project');
		is($ranked[0]{type}, 'perl', 'Highest-ranked detection is perl');
		cmp_ok($ranked[0]{score}, '>', 0, 'Top score is positive');

		# Verify descending-score ordering per the POD formal spec.
		for my $i (0 .. $#ranked - 1) {
			cmp_ok($ranked[$i]{score}, '>=', $ranked[$i + 1]{score},
				"Result[$i] score >= result[" . ($i + 1) . "] score (descending order)");
		}
	});
};

# ---------------------------------------------------------------------------
# Subtest 9: find_workflows + estimate_current_usage with real files on disk
# Write two YAML workflow files, discover them with find_workflows(), feed them
# to estimate_current_usage(), and verify aggregate totals.
# Spy on CostEstimator::LoadFile to confirm it is called exactly once per file.
subtest 'find_workflows + estimate_current_usage: real YAML files on disk' => sub {
	in_tempdir(sub {
		path('.github/workflows')->mkpath;
		path('.github/workflows/ci.yml')->spew(<<'END_YAML');
name: CI
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - run: npm install
      - run: npm test
END_YAML
		path('.github/workflows/deploy.yml')->spew(<<'END_YAML');
name: Deploy
on:
  release:
    types: [published]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - run: npm run deploy
END_YAML

		# Spy on the imported LoadFile symbol inside CostEstimator's namespace.
		# spy() calls through to the original so real YAML files are still parsed.
		my $get_load_calls = spy('App::GHGen::CostEstimator::LoadFile');

		my @wf_files = find_workflows();
		is(scalar @wf_files, 2, 'find_workflows discovers both workflow files');
		ok($wf_files[0]->isa('Path::Tiny'), 'find_workflows returns Path::Tiny objects');

		my $usage = estimate_current_usage(\@wf_files);

		# Verify LoadFile was called once per workflow file.
		my @load_calls = $get_load_calls->();
		is(scalar @load_calls, 2, 'LoadFile called once per workflow file');

		ok(ref $usage eq 'HASH', 'estimate_current_usage returns a HashRef');
		is(scalar @{$usage->{workflows}}, 2, 'workflows array has one entry per file');
		cmp_ok($usage->{total_minutes}, '>', 0, 'total_minutes is positive');
		cmp_ok($usage->{billable_minutes}, '>=', 0, 'billable_minutes is non-negative');

		# Documented invariant: total_minutes == sum of individual minutes_per_month.
		my $sum = 0;
		$sum += $_->{minutes_per_month} for @{$usage->{workflows}};
		is($usage->{total_minutes}, $sum,
			'total_minutes equals sum of per-workflow minutes_per_month');

		# Within free tier: billable_minutes == 0 and monthly_cost == 0.
		if ($usage->{total_minutes} <= $FREE_TIER_MINUTES) {
			is($usage->{billable_minutes}, 0, 'billable_minutes is 0 within free tier');
			is($usage->{monthly_cost},     0, 'monthly_cost is 0 within free tier');
		}

		diag(sprintf 'Total: %.1f min  billable: %.1f  cost: $%.2f',
			$usage->{total_minutes}, $usage->{billable_minutes}, $usage->{monthly_cost})
			if $ENV{TEST_VERBOSE};

		restore_all();
	});
};

# ---------------------------------------------------------------------------
# Subtest 10: Fixer::fix_workflow end-to-end file round-trip
# Write a YAML file with known issues, call fix_workflow(), read it back,
# and verify the mutations persisted to disk.
subtest 'Fixer::fix_workflow: mutations written to disk and re-loadable' => sub {
	in_tempdir(sub {
		path('.github/workflows')->mkpath;
		my $wf_path = '.github/workflows/fixme.yml';

		DumpFile($wf_path, {
			name => 'Fixable',
			on   => [qw(push)],
			jobs => {
				build => {
					'runs-on' => 'ubuntu-18.04',
					steps     => [
						{ uses => 'actions/checkout@main' },
						{ run  => 'cargo build' },
					],
				},
			},
		});

		my @issues = (
			{
				type     => 'cost',
				severity => 'low',
				message  => 'No concurrency group - old runs continue when superseded',
			},
			{
				type     => 'maintenance',
				severity => 'low',
				message  => 'Using older runner versions - consider updating',
			},
		);

		my $n = fix_workflow($wf_path, \@issues);
		cmp_ok($n, '>=', 1, "fix_workflow applied at least one fix (got $n)");

		# Re-read the YAML from disk and assert the fixes persisted.
		my $reloaded = LoadFile($wf_path);
		ok(defined $reloaded->{concurrency},
			'concurrency key present in reloaded workflow (persisted to disk)');
		isnt($reloaded->{jobs}{build}{'runs-on'}, 'ubuntu-18.04',
			'outdated runner updated in reloaded workflow');

		diag("Reloaded runs-on: $reloaded->{jobs}{build}{'runs-on'}") if $ENV{TEST_VERBOSE};
	});
};

# ---------------------------------------------------------------------------
# Subtest 11: fix_workflow skips DumpFile when no fixes applied
# POD: the file is only rewritten when fix count > 0.
# Spy on DumpFile to confirm it is never called when the issues list is empty.
subtest 'Fixer::fix_workflow: DumpFile not called when zero fixes applied' => sub {
	in_tempdir(sub {
		path('.github/workflows')->mkpath;
		my $wf_path = '.github/workflows/clean.yml';
		DumpFile($wf_path, _clean_workflow());

		# Spy (call-through) records calls without preventing them.
		my $get_dump_calls = spy('App::GHGen::Fixer::DumpFile');

		my $n = fix_workflow($wf_path, []);
		is($n, 0, 'fix_workflow returns 0 when no issues passed');
		is(scalar $get_dump_calls->(), 0,
			'DumpFile not called when fix count is zero');

		restore_all();
	});
};

# ---------------------------------------------------------------------------
# Subtest 12: PerlCustomizer detect_perl_requirements + generate_custom_perl_workflow
# Verify the detect -> configure -> generate pipeline and the step-ordering
# invariant documented in CLAUDE.md and PerlCustomizer POD.
subtest 'PerlCustomizer: detect_perl_requirements feeds generate_custom_perl_workflow' => sub {
	in_tempdir(sub {
		path('cpanfile')->spew("requires 'perl', '5.036';\nrequires 'Moose';\n");
		path('Makefile.PL')->spew("use ExtUtils::MakeMaker;\n");

		my $reqs = detect_perl_requirements();
		ok($reqs->{has_cpanfile},     'cpanfile detected');
		ok($reqs->{has_makefile_pl},  'Makefile.PL detected');
		is($reqs->{min_version}, '5.036', 'Correct minimum Perl version extracted');

		my $yaml = generate_custom_perl_workflow({
			enable_linter        => 1,
			enable_linter_unused => 0,
			enable_critic        => 1,
			enable_coverage      => 1,
		});
		ok(defined $yaml && length $yaml > 0, 'generate_custom_perl_workflow returns YAML');

		# Step ordering invariant per CLAUDE.md:
		# checkout -> setup-perl -> cache -> deps -> lint -> tests -> critic -> coverage
		my $checkout_pos = index($yaml, 'checkout');
		my $lint_pos     = index($yaml, 'perl {0}');
		my $prove_pos    = index($yaml, 'prove');
		my $critic_pos   = index($yaml, 'Perl::Critic');
		my $cover_pos    = index($yaml, 'Devel::Cover');

		cmp_ok($checkout_pos, '>=', 0, 'checkout step present in generated YAML');
		cmp_ok($lint_pos,     '>=', 0, 'lint step (perl {0}) present in generated YAML');
		cmp_ok($prove_pos,    '>=', 0, 'test step (prove) present in generated YAML');

		cmp_ok($checkout_pos, '<', $prove_pos,  'checkout precedes tests');
		cmp_ok($lint_pos,     '<', $prove_pos,  'lint precedes tests');
		cmp_ok($critic_pos,   '>', $prove_pos,  'critic follows tests');
		cmp_ok($cover_pos,    '>', $prove_pos,  'coverage follows tests');

		diag("min_version: $reqs->{min_version}") if $ENV{TEST_VERBOSE};
	});
};

# ---------------------------------------------------------------------------
# Subtest 13: Isolation -- two simultaneous analyses share no state
# Analyze a problem workflow and a clean workflow in the same scope.
# Issues from each run must reflect only their own input.
subtest 'Isolation: two simultaneous analyses do not cross-pollinate' => sub {
	# Run two independent analyses without any mutating step between them.
	my @issues_a = analyze_workflow(_problem_workflow(), 'a.yml');
	my @issues_b = analyze_workflow(_clean_workflow(),   'b.yml');

	# The problem workflow lacks caching; the clean one has it.
	my @cache_a = grep { $_->{type} eq 'performance' && $_->{message} =~ /caching/ } @issues_a;
	my @cache_b = grep { $_->{type} eq 'performance' && $_->{message} =~ /caching/ } @issues_b;
	ok(@cache_a > 0, 'Problem workflow (A) has caching issue');
	is(scalar @cache_b, 0, 'Clean workflow (B) has no caching issue');

	# The problem workflow has a broad trigger; the clean one uses branch filters.
	my @trig_a = grep { $_->{type} eq 'cost' && $_->{message} =~ /triggers/ } @issues_a;
	my @trig_b = grep { $_->{type} eq 'cost' && $_->{message} =~ /triggers/ } @issues_b;
	ok(@trig_a > 0, 'Problem workflow (A) has broad-trigger issue');
	is(scalar @trig_b, 0, 'Clean workflow (B) has no broad-trigger issue');

	# Clean workflow must report zero issues in total.
	is(scalar @issues_b, 0, 'Clean workflow (B) has zero issues overall');

	diag("Issues A: " . scalar(@issues_a) . "  Issues B: " . scalar(@issues_b))
		if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# Subtest 14: Reporter::estimate_savings vs CostEstimator::estimate_savings
# Both functions share a name but document different return-value contracts.
# Verify each conforms to its own POD spec when given the same input.
subtest 'Reporter vs CostEstimator estimate_savings: distinct return contracts' => sub {
	my @issues = (
		{
			type     => 'performance',
			severity => 'medium',
			message  => 'No dependency caching found - increases build times and costs',
		},
		{
			type     => 'cost',
			severity => 'low',
			message  => 'No concurrency group - old runs continue when superseded',
		},
	);

	# Reporter::estimate_savings: { minutes => Int, cost => Int }
	my $reporter_s = App::GHGen::Reporter::estimate_savings(\@issues);
	ok(defined $reporter_s->{minutes},            'Reporter: minutes key present');
	ok(defined $reporter_s->{cost},               'Reporter: cost key present');
	ok(!exists $reporter_s->{details},            'Reporter: no details key (simpler contract)');
	ok(!exists $reporter_s->{percentage},         'Reporter: no percentage key');
	cmp_ok($reporter_s->{minutes}, '>', 0,        'Reporter: nonzero savings for caching issue');

	# CostEstimator::estimate_savings: { minutes, cost (Str), percentage, details ArrayRef }
	my $estimator_s = App::GHGen::CostEstimator::estimate_savings(\@issues);
	ok(defined $estimator_s->{minutes},              'CostEstimator: minutes key present');
	ok(defined $estimator_s->{cost},                 'CostEstimator: cost key present');
	ok(exists  $estimator_s->{details},              'CostEstimator: details key present');
	ok(ref $estimator_s->{details} eq 'ARRAY',       'CostEstimator: details is an ArrayRef');
	ok(exists  $estimator_s->{percentage},           'CostEstimator: percentage key present');
	cmp_ok($estimator_s->{minutes}, '>', 0,          'CostEstimator: nonzero savings');

	diag("Reporter: $reporter_s->{minutes} min  CostEstimator: $estimator_s->{minutes} min")
		if $ENV{TEST_VERBOSE};
};

# ---------------------------------------------------------------------------
# Subtest 15: get_cache_suggestion per ecosystem (Analyzer cross-module check)
# For each ecosystem the Analyzer understands, build a minimal workflow that
# triggers that detection and verify the cache path in the suggestion.
subtest 'Analyzer::get_cache_suggestion: correct cache path per ecosystem' => sub {
	# These constants come directly from the FORMAL SPECIFICATION in the POD.
	my @cases = (
		{
			ecosystem => 'npm',
			steps     => [{ run => 'npm install' }],
			path_frag => '~/.npm',
		},
		{
			ecosystem => 'pip',
			steps     => [{ run => 'pip install -r requirements.txt' }],
			path_frag => '~/.cache/pip',
		},
		{
			ecosystem => 'cargo',
			steps     => [{ run => 'cargo build' }],
			path_frag => '~/.cargo',
		},
		{
			ecosystem => 'bundler',
			steps     => [{ run => 'bundle install' }],
			path_frag => 'vendor/bundle',
		},
	);

	for my $case (@cases) {
		my $wf         = { jobs => { build => { steps => $case->{steps} } } };
		my $suggestion = get_cache_suggestion($wf);
		like($suggestion, qr/\Q$case->{path_frag}\E/,
			"$case->{ecosystem}: suggestion contains path '$case->{path_frag}'");
		diag("$case->{ecosystem}: $suggestion") if $ENV{TEST_VERBOSE};
	}

	# Unknown ecosystem (make install) must return the generic guidance message.
	my $unk_wf   = { jobs => { build => { steps => [{ run => 'make install' }] } } };
	my $unk_hint = get_cache_suggestion($unk_wf);
	like($unk_hint, qr/dependency manager/i,
		'Unknown ecosystem returns generic guidance per POD');
};

# ---------------------------------------------------------------------------
# Subtest 16: Test::Without::Module -- YAML::XS absence causes load error in Fixer
# Fixer has a hard `use YAML::XS` dependency.  Blocking it in a child process
# must produce a non-zero exit and a recognizable "Can't locate" error.
subtest 'Test::Without::Module: YAML::XS absence causes load error for Fixer' => sub {
	my $script = q(
		use Test::Without::Module 'YAML::XS';
		require App::GHGen::Fixer;
	);
	my ($out, $err);
	run3([$^X, '-Ilib', '-e', $script], \undef, \$out, \$err);
	my $exit = $? >> 8;

	cmp_ok($exit, '!=', 0, 'Child process exits non-zero when YAML::XS is blocked');
	like("$out$err", qr/Can't locate YAML/i,
		'Error output mentions the missing YAML::XS module');
};

# ---------------------------------------------------------------------------
# Subtest 17: Test::Without::Module -- Path::Tiny absence causes load error in Analyzer
# Analyzer has a hard `use Path::Tiny` dependency.  Blocking it must fail.
subtest 'Test::Without::Module: Path::Tiny absence causes load error for Analyzer' => sub {
	my $script = q(
		use Test::Without::Module 'Path::Tiny';
		require App::GHGen::Analyzer;
	);
	my ($out, $err);
	run3([$^X, '-Ilib', '-e', $script], \undef, \$out, \$err);
	my $exit = $? >> 8;

	cmp_ok($exit, '!=', 0, 'Child process exits non-zero when Path::Tiny is blocked');
	like("$out$err", qr/Can't locate Path/i,
		'Error output mentions the missing Path::Tiny module');
};

done_testing();
