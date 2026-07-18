#!/usr/bin/env perl
# White-box function tests for all App::GHGen modules.
# Each section covers one module, exercising both exported and private functions.
# Private helpers are invoked via fully-qualified package names.

use v5.36;
use strict;
use warnings;

use Cwd           qw(getcwd);
use File::Temp    qw(tempdir);
use Path::Tiny;
use Scalar::Util  qw(looks_like_number);

use Test::Most;

# Test::Memory::Cycle is optional.  When installed it verifies no circular
# references remain in return values; when absent each check trivially passes.
my $HAS_MEMORY_CYCLE = eval { require Test::Memory::Cycle; 1 };
sub memory_cycle_ok {
	my ($ref, $label) = @_;
	if ($HAS_MEMORY_CYCLE) {
		Test::Memory::Cycle::memory_cycle_ok($ref, $label);
	} else {
		pass("$label (Test::Memory::Cycle not installed)");
	}
}

use App::GHGen::Analyzer      qw(analyze_workflow find_workflows get_cache_suggestion);
use App::GHGen::CostEstimator qw(estimate_current_usage estimate_workflow_cost);
use App::GHGen::Detector      qw(detect_project_type get_project_indicators);
use App::GHGen::Fixer         qw(apply_fixes can_auto_fix fix_workflow);
use App::GHGen::Generator     qw(generate_workflow list_workflow_types);
use App::GHGen::Interactive   qw(
	prompt_yes_no prompt_choice prompt_multiselect prompt_text customize_workflow
);
use App::GHGen::PerlCustomizer qw(detect_perl_requirements generate_custom_perl_workflow);
use App::GHGen::Reporter       qw(generate_markdown_report generate_github_comment estimate_savings);

# Snapshot CWD so chdir-based tests can restore it reliably.
my $ORIG_DIR = getcwd();

# Run $code inside a freshly-created temp directory, then restore CWD regardless
# of whether $code succeeded.  Used for tests that inspect the current directory.
sub in_tempdir ($code) {
	my $tmp  = tempdir(CLEANUP => 1);
	my $orig = getcwd();
	chdir($tmp) or die "Cannot chdir to temp: $!";
	my $ok = eval { $code->(); 1 };
	my $err = $@;
	chdir($orig) or die "Cannot restore CWD: $!";
	die $err if $err;
}

# ── Shared fixture data ────────────────────────────────────────────────────

# Named constants for values that appear in multiple tests.
my %C = (
	LATEST_CHECKOUT => 'actions/checkout@v6',
	LATEST_CACHE    => 'actions/cache@v5',
	OLD_CACHE_V3    => 'actions/cache@v3',
	OLD_CHECKOUT_V3 => 'actions/checkout@v3',
	UBUNTU_LATEST   => 'ubuntu-latest',
	UBUNTU_OLD      => 'ubuntu-18.04',
	TIMEOUT_DEFAULT => 30,
	COST_PER_MINUTE => 0.008,
);

# A "perfect" workflow: caching, pinned+current actions, concurrency,
# modern runner, timeout, no broad triggers.  Should produce zero Analyzer issues.
my $GOOD_WORKFLOW = {
	name        => 'Good CI',
	concurrency => {
		group               => '${{ github.workflow }}-${{ github.ref }}',
		'cancel-in-progress' => 'true',
	},
	on   => { push => { branches => ['main'] } },
	jobs => {
		test => {
			'runs-on'         => $C{UBUNTU_LATEST},
			'timeout-minutes' => $C{TIMEOUT_DEFAULT},
			steps => [
				{ uses => $C{LATEST_CHECKOUT} },
				{ uses => $C{LATEST_CACHE}, with => { path => '~/.npm' } },
				{ run  => 'npm ci' },
				{ run  => 'npm test' },
			],
		},
	},
};

# ═══════════════════════════════════════════════════════════════════════
# 1.  App::GHGen::Analyzer
# ═══════════════════════════════════════════════════════════════════════

subtest 'Analyzer::has_caching - detects cache steps' => sub {
	ok(
		App::GHGen::Analyzer::has_caching($GOOD_WORKFLOW),
		'workflow with actions/cache step is recognised as cached',
	);

	my $no_cache = {
		jobs => { test => { steps => [
			{ uses => $C{LATEST_CHECKOUT} },
			{ run  => 'npm ci' },
		]}},
	};
	ok(
		!App::GHGen::Analyzer::has_caching($no_cache),
		'workflow without any cache step returns false',
	);

	# Edge case: missing jobs key must not die.
	ok(
		!App::GHGen::Analyzer::has_caching({}),
		'workflow with no jobs key returns false without dying',
	);
};

subtest 'Analyzer::find_unpinned_actions - detects @master and @main' => sub {
	my $workflow = {
		jobs => { test => { steps => [
			{ uses => 'actions/checkout@main' },
			{ uses => 'some/action@master' },
			{ uses => 'pinned/action@v5' },
		]}},
	};
	my @unpinned = App::GHGen::Analyzer::find_unpinned_actions($workflow);
	is(scalar @unpinned, 2, 'finds two unpinned actions');
	ok(
		(grep { /\@main$/   } @unpinned),
		'@main action included in unpinned list',
	);
	ok(
		(grep { /\@master$/ } @unpinned),
		'@master action included in unpinned list',
	);

	# Pinned action should not appear.
	my @none = App::GHGen::Analyzer::find_unpinned_actions($GOOD_WORKFLOW);
	is(scalar @none, 0, 'good workflow has no unpinned actions');
};

subtest 'Analyzer::has_broad_triggers - detects unfiltered push triggers' => sub {
	# Array-form trigger with 'push' is considered broad.
	my $array_trigger = { on => [qw(push pull_request)] };
	ok(
		App::GHGen::Analyzer::has_broad_triggers($array_trigger),
		'array trigger including push is broad',
	);

	# Hash-form push with no branch/path filter is broad.
	my $hash_no_filter = { on => { push => 1 } };
	ok(
		App::GHGen::Analyzer::has_broad_triggers($hash_no_filter),
		'hash push trigger with scalar value is broad',
	);

	# Push filtered to specific branches is NOT broad.
	ok(
		!App::GHGen::Analyzer::has_broad_triggers($GOOD_WORKFLOW),
		'push with branches filter is not broad',
	);

	# No trigger key at all must return false without dying.
	ok(
		!App::GHGen::Analyzer::has_broad_triggers({}),
		'missing "on" key returns false without dying',
	);
};

subtest 'Analyzer::has_outdated_runners - recognises old runner strings' => sub {
	my $old_runner = {
		jobs => { test => { 'runs-on' => $C{UBUNTU_OLD} } },
	};
	ok(
		App::GHGen::Analyzer::has_outdated_runners($old_runner),
		'ubuntu-18.04 is an outdated runner',
	);

	ok(
		!App::GHGen::Analyzer::has_outdated_runners($GOOD_WORKFLOW),
		'ubuntu-latest is not outdated',
	);
};

subtest 'Analyzer::detect_project_type (local) - classifies by run commands' => sub {
	# Analyzer's own detect_project_type works on a workflow hash, not the filesystem.
	my $npm_wf = {
		jobs => { test => { steps => [{ run => 'npm ci' }] } },
	};
	is(
		App::GHGen::Analyzer::detect_project_type($npm_wf),
		'npm',
		'npm ci command detected as npm project',
	);

	my $pip_wf = {
		jobs => { test => { steps => [{ run => 'pip install -r requirements.txt' }] } },
	};
	is(
		App::GHGen::Analyzer::detect_project_type($pip_wf),
		'pip',
		'pip install command detected as pip project',
	);

	my $cargo_wf = {
		jobs => { test => { steps => [{ run => 'cargo build' }] } },
	};
	is(
		App::GHGen::Analyzer::detect_project_type($cargo_wf),
		'cargo',
		'cargo build command detected as cargo project',
	);

	my $bundler_wf = {
		jobs => { test => { steps => [{ run => 'bundle install' }] } },
	};
	is(
		App::GHGen::Analyzer::detect_project_type($bundler_wf),
		'bundler',
		'bundle install command detected as bundler project',
	);

	is(
		App::GHGen::Analyzer::detect_project_type({}),
		'unknown',
		'empty workflow hash returns "unknown"',
	);
};

subtest 'Analyzer::min - returns smaller of two numbers' => sub {
	is(App::GHGen::Analyzer::min(3, 7),  3, 'min(3,7) returns 3');
	is(App::GHGen::Analyzer::min(9, 2),  2, 'min(9,2) returns 2');
	is(App::GHGen::Analyzer::min(5, 5),  5, 'min(5,5) returns 5');
};

subtest 'Analyzer::find_outdated_actions - flags old action versions' => sub {
	my $wf = {
		jobs => { test => { steps => [
			{ uses => $C{OLD_CHECKOUT_V3} },
			{ uses => $C{OLD_CACHE_V3} },
			{ uses => $C{LATEST_CHECKOUT} },  # current - must not appear
		]}},
	};
	my @outdated = App::GHGen::Analyzer::find_outdated_actions($wf);
	is(scalar @outdated, 2, 'two outdated actions found');

	# Good workflow uses current versions only.
	my @none = App::GHGen::Analyzer::find_outdated_actions($GOOD_WORKFLOW);
	is(scalar @none, 0, 'good workflow has no outdated actions');
};

subtest 'Analyzer::has_deployment_steps - recognises deploy actions and commands' => sub {
	my $deploy_action = {
		jobs => { test => { steps => [
			{ uses => 'some/deploy-action@v1' },
		]}},
	};
	ok(
		App::GHGen::Analyzer::has_deployment_steps($deploy_action),
		'step with "deploy" in uses is a deployment step',
	);

	my $git_push = {
		jobs => { test => { steps => [
			{ run => 'git push origin main' },
		]}},
	};
	ok(
		App::GHGen::Analyzer::has_deployment_steps($git_push),
		'"git push" run command is a deployment step',
	);

	ok(
		!App::GHGen::Analyzer::has_deployment_steps($GOOD_WORKFLOW),
		'good workflow has no deployment steps',
	);
};

subtest 'Analyzer::get_cache_suggestion - returns per-ecosystem YAML snippet' => sub {
	my $npm_wf = {
		jobs => { test => { steps => [{ run => 'npm ci' }] } },
	};
	my $suggestion = get_cache_suggestion($npm_wf);
	like($suggestion, qr/actions\/cache/,  'npm suggestion references actions/cache');
	like($suggestion, qr/\.npm/,           'npm suggestion mentions npm cache path');

	my $pip_wf = {
		jobs => { test => { steps => [{ run => 'pip install -r requirements.txt' }] } },
	};
	like(
		get_cache_suggestion($pip_wf),
		qr/\.cache\/pip/,
		'pip suggestion mentions pip cache path',
	);

	# Unknown project type falls through to the generic guidance message.
	like(
		get_cache_suggestion({}),
		qr/dependency manager/i,
		'unknown project type returns generic guidance',
	);
};

subtest 'Analyzer::analyze_workflow - good workflow produces zero issues' => sub {
	my @issues = analyze_workflow($GOOD_WORKFLOW, 'good.yml');
	is(scalar @issues, 0, 'good workflow has no issues');
	memory_cycle_ok(\@issues, 'issue list has no circular references');
};

subtest 'Analyzer::analyze_workflow - bad workflow produces expected issues' => sub {
	# Broad triggers, no concurrency, no cache, unpinned action, outdated runner,
	# no timeout -> multiple issues expected.
	my $bad = {
		name => 'Bad CI',
		on   => [qw(push pull_request)],
		jobs => {
			test => {
				'runs-on' => $C{UBUNTU_OLD},
				steps => [
					{ uses => 'actions/checkout@main' },
					{ run  => 'npm ci' },
					{ run  => 'npm test' },
				],
			},
		},
	};
	my @issues = analyze_workflow($bad, 'bad.yml');
	ok(scalar @issues > 0, 'bad workflow produces at least one issue');

	my %by_type = map { $_->{type} => 1 } @issues;
	ok($by_type{performance}, 'performance issue present (no caching)');
	ok($by_type{security},    'security issue present (unpinned action)');
	ok($by_type{cost},        'cost issue present (broad trigger or concurrency)');
	ok($by_type{maintenance}, 'maintenance issue present (outdated runner)');

	# Every issue must carry the mandatory fields.
	for my $issue (@issues) {
		ok(defined $issue->{type},    "issue has type field");
		ok(defined $issue->{severity}, "issue has severity field");
		ok(defined $issue->{message}, "issue has message field");
	}

	diag(explain(\@issues)) if $ENV{TEST_VERBOSE};
};

subtest 'Analyzer::find_workflows - discovers .yml files in .github/workflows' => sub {
	in_tempdir(sub {
		# No .github/workflows directory yet -> returns empty list.
		my @found = find_workflows();
		is(scalar @found, 0, 'returns empty list when directory absent');

		# Create the directory and some files.
		path('.github/workflows')->mkpath;
		path('.github/workflows/ci.yml')->spew_utf8("---\nname: CI\n");
		path('.github/workflows/release.yaml')->spew_utf8("---\nname: Release\n");
		path('.github/workflows/ignored.txt')->spew_utf8("not a workflow");

		my @workflows = find_workflows();
		is(scalar @workflows, 2, 'finds exactly the two YAML files');
	});
};

# ═══════════════════════════════════════════════════════════════════════
# 2.  App::GHGen::CostEstimator
# ═══════════════════════════════════════════════════════════════════════

subtest 'CostEstimator::estimate_trigger_frequency - returns realistic estimates' => sub {
	my $push_freq = App::GHGen::CostEstimator::estimate_trigger_frequency('push');
	ok($push_freq > 0, 'push trigger has a positive frequency');

	my $pr_freq = App::GHGen::CostEstimator::estimate_trigger_frequency('pull_request');
	ok($pr_freq > 0, 'pull_request trigger has a positive frequency');

	my $unknown_freq = App::GHGen::CostEstimator::estimate_trigger_frequency('nonexistent_trigger');
	ok($unknown_freq > 0, 'unknown trigger still returns a positive default');

	# Branch filter should reduce the base frequency.
	my $filtered = App::GHGen::CostEstimator::estimate_trigger_frequency(
		'push', { branches => ['main'] }
	);
	ok($filtered < $push_freq, 'branch filter reduces trigger frequency');

	# Path filter should reduce frequency even further.
	my $path_filtered = App::GHGen::CostEstimator::estimate_trigger_frequency(
		'push', { paths => ['src/**'] }
	);
	ok($path_filtered < $push_freq, 'path filter reduces trigger frequency');

	diag("push=$push_freq pr=$pr_freq filtered=$filtered") if $ENV{TEST_VERBOSE};
};

subtest 'CostEstimator::estimate_job_duration - sums step durations' => sub {
	my $job_with_steps = {
		steps => [
			{ uses => 'actions/checkout@v6' },
			{ uses => 'actions/setup-node@v4' },
			{ run  => 'npm ci' },
			{ run  => 'npm test' },
		],
	};
	my $duration = App::GHGen::CostEstimator::estimate_job_duration($job_with_steps);
	ok($duration > 0, 'job with steps has positive duration');

	# A job with no steps should still return a non-negative default.
	my $empty_job = {};
	my $empty_dur = App::GHGen::CostEstimator::estimate_job_duration($empty_job);
	ok($empty_dur >= 0, 'empty job returns non-negative duration');

	# A rust job with both build and test steps should exceed the npm job duration.
	my $rust_job = {
		steps => [
			{ uses => 'actions/checkout@v6' },
			{ run  => 'cargo build --release' },  # +5 min
			{ run  => 'cargo test' },             # +2 min
		],
	};
	my $rust_dur = App::GHGen::CostEstimator::estimate_job_duration($rust_job);
	ok($rust_dur > $duration, 'rust build+test job is estimated slower than npm ci+test');
};

subtest 'CostEstimator::estimate_matrix_factor - computes matrix size multiplier' => sub {
	# No matrix -> factor of 1.
	my $no_matrix_wf = { jobs => { test => {} } };
	is(
		App::GHGen::CostEstimator::estimate_matrix_factor($no_matrix_wf),
		1,
		'workflow without matrix has factor 1',
	);

	# 3 OS x 3 Perl versions = 9.
	my $matrix_wf = {
		jobs => {
			test => {
				strategy => {
					matrix => {
						os   => [qw(ubuntu-latest macos-latest windows-latest)],
						perl => [qw(5.36 5.38 5.40)],
					},
				},
			},
		},
	};
	is(
		App::GHGen::CostEstimator::estimate_matrix_factor($matrix_wf),
		9,
		'3x3 matrix produces factor of 9',
	);

	# include/exclude keys must be ignored when computing size.
	my $matrix_with_include = {
		jobs => {
			test => {
				strategy => {
					matrix => {
						os      => [qw(ubuntu-latest macos-latest)],
						include => [{ extra => 'val' }],  # must not multiply
					},
				},
			},
		},
	};
	is(
		App::GHGen::CostEstimator::estimate_matrix_factor($matrix_with_include),
		2,
		'include key is not counted in matrix size',
	);
};

subtest 'CostEstimator::estimate_runs_per_month - handles trigger formats' => sub {
	# Array trigger form.
	my $array_on = { on => [qw(push pull_request)] };
	my $runs = App::GHGen::CostEstimator::estimate_runs_per_month($array_on);
	ok($runs > 0, 'array trigger form returns positive run count');

	# Hash trigger form.
	my $hash_on = { on => { push => {}, schedule => {} } };
	my $runs2 = App::GHGen::CostEstimator::estimate_runs_per_month($hash_on);
	ok($runs2 > 0, 'hash trigger form returns positive run count');

	# String trigger form.
	my $str_on = { on => 'push' };
	ok(
		App::GHGen::CostEstimator::estimate_runs_per_month($str_on) > 0,
		'string trigger form returns positive run count',
	);

	# Missing 'on' key falls back to the default estimate.
	ok(
		App::GHGen::CostEstimator::estimate_runs_per_month({}) > 0,
		'missing "on" key falls back to non-zero default',
	);
};

subtest 'CostEstimator::estimate_workflow_cost - returns expected fields' => sub {
	my $cost = estimate_workflow_cost($GOOD_WORKFLOW, 'good.yml');

	ok(defined $cost->{name},              'cost has name field');
	ok(defined $cost->{file},              'cost has file field');
	ok($cost->{runs_per_month} > 0,        'runs_per_month is positive');
	ok($cost->{minutes_per_run} > 0,       'minutes_per_run is positive');
	ok($cost->{minutes_per_month} > 0,     'minutes_per_month is positive');

	is(
		$cost->{minutes_per_month},
		$cost->{runs_per_month} * $cost->{minutes_per_run},
		'minutes_per_month equals runs x minutes_per_run',
	);

	memory_cycle_ok($cost, 'workflow cost result has no circular references');
	diag(explain($cost)) if $ENV{TEST_VERBOSE};
};

subtest 'CostEstimator::estimate_savings - quantifies potential reductions' => sub {
	# Caching issue saves CI minutes.
	my @caching_issues = ({
		type    => 'performance',
		message => 'No dependency caching found - increases build times and costs',
	});
	my $savings = App::GHGen::CostEstimator::estimate_savings(\@caching_issues);
	ok($savings->{minutes} > 0,  'caching fix yields positive minute savings');
	ok($savings->{cost} >= 0,    'savings cost field is non-negative');
	ok(defined $savings->{details}, 'savings includes details array');

	# No issues -> no savings.
	my $zero = App::GHGen::CostEstimator::estimate_savings([]);
	is($zero->{minutes}, 0, 'no issues produces zero minute savings');

	memory_cycle_ok($savings, 'savings result has no circular references');
};

# ═══════════════════════════════════════════════════════════════════════
# 3.  App::GHGen::Detector
# ═══════════════════════════════════════════════════════════════════════

subtest 'Detector::get_project_indicators - returns structured indicator lists' => sub {
	my $perl_indicators = get_project_indicators('perl');
	ok(ref $perl_indicators eq 'ARRAY', 'perl indicators are an arrayref');
	ok(scalar @$perl_indicators > 0,   'perl indicator list is non-empty');
	ok((grep { /cpanfile/ } @$perl_indicators), 'cpanfile listed as perl indicator');

	# Requesting all indicators returns a hashref keyed by language.
	my $all = get_project_indicators();
	ok(ref $all eq 'HASH', 'no-arg call returns a hashref');
	ok(exists $all->{perl}, 'all-indicators hash includes perl');
	ok(exists $all->{node}, 'all-indicators hash includes node');

	# Unknown type returns undef.
	my $unknown = get_project_indicators('cobol');
	ok(!defined $unknown, 'unknown type returns undef');
};

subtest 'Detector::_detect_perl - scores current repo as a Perl project' => sub {
	# We are running inside App-GHGen which is a Perl project (has cpanfile,
	# Makefile.PL, lib/, t/).  The detector should give a positive score.
	my $score = App::GHGen::Detector::_detect_perl();
	ok($score > 0, "Perl repo scores positively ($score)");
	diag("_detect_perl score: $score") if $ENV{TEST_VERBOSE};
};

subtest 'Detector::_detect_node - scores zero in a Perl-only repo' => sub {
	my $score = App::GHGen::Detector::_detect_node();
	# The App-GHGen repo has no package.json, so the score must be zero (or low).
	# We cannot assert zero because the repo may contain incidental node files,
	# but we can assert it is lower than the Perl score.
	my $perl_score = App::GHGen::Detector::_detect_perl();
	ok($score < $perl_score, 'node score is lower than perl score in a Perl repo');
};

subtest 'Detector::detect_project_type - returns "perl" for this repository' => sub {
	# Running from the App-GHGen directory, which is definitively a Perl project.
	my $type = detect_project_type();
	is($type, 'perl', 'detect_project_type returns "perl" for App-GHGen repo');

	# In wantarray context it returns a ranked list of detections.
	my @ranked = detect_project_type();
	ok(scalar @ranked > 0, 'wantarray context returns non-empty list');
	is($ranked[0]->{type}, 'perl', 'highest-ranked type is still perl');
};

subtest 'Detector::detect_project_type - returns undef in an empty directory' => sub {
	in_tempdir(sub {
		my $type = detect_project_type();
		ok(!defined $type, 'empty directory returns undef');
	});
};

# ═══════════════════════════════════════════════════════════════════════
# 4.  App::GHGen::Fixer
# ═══════════════════════════════════════════════════════════════════════

subtest 'Fixer::can_auto_fix - accepts all four fixable types' => sub {
	for my $type (qw(performance security cost maintenance)) {
		ok(
			can_auto_fix({ type => $type }),
			"can_auto_fix returns true for '$type'",
		);
	}
	ok(
		!can_auto_fix({ type => 'unknown_type' }),
		'can_auto_fix returns false for unknown type',
	);
};

subtest 'Fixer::get_latest_version - maps known actions to current versions' => sub {
	is(
		App::GHGen::Fixer::get_latest_version('actions/checkout'),
		'v6',
		'actions/checkout maps to v6',
	);
	is(
		App::GHGen::Fixer::get_latest_version('actions/cache'),
		'v5',
		'actions/cache maps to v5',
	);
	# Unknown action falls back to a sensible default rather than dying.
	my $fallback = App::GHGen::Fixer::get_latest_version('unknown/action');
	ok(defined $fallback, 'unknown action returns a defined fallback version');
};

subtest 'Fixer::detect_and_create_cache_step - creates ecosystem-correct steps' => sub {
	my $npm_steps  = [{ run => 'npm ci' }];
	my $npm_step   = App::GHGen::Fixer::detect_and_create_cache_step($npm_steps);
	ok(defined $npm_step, 'npm step detected');
	like($npm_step->{uses}, qr/actions\/cache/, 'npm cache step uses actions/cache');
	like($npm_step->{with}{path}, qr/npm/, 'npm cache path references npm');

	my $pip_steps  = [{ run => 'pip install -r requirements.txt' }];
	my $pip_step   = App::GHGen::Fixer::detect_and_create_cache_step($pip_steps);
	ok(defined $pip_step, 'pip step detected');
	like($pip_step->{with}{path}, qr/pip/, 'pip cache path references pip');

	my $cargo_steps = [{ run => 'cargo build --release' }];
	my $cargo_step  = App::GHGen::Fixer::detect_and_create_cache_step($cargo_steps);
	ok(defined $cargo_step, 'cargo step detected');
	like($cargo_step->{with}{path}, qr/cargo/, 'cargo cache path references cargo');

	# No recognisable package manager -> no cache step created.
	my $unknown = App::GHGen::Fixer::detect_and_create_cache_step([{ run => 'make all' }]);
	ok(!defined $unknown, 'unrecognised step returns undef');
};

subtest 'Fixer::add_permissions - idempotent permission insertion' => sub {
	my $workflow = { name => 'Test' };
	my $added = App::GHGen::Fixer::add_permissions($workflow);
	is($added, 1, 'returns 1 when permissions were added');
	is($workflow->{permissions}{contents}, 'read', 'sets contents: read permission');

	# Calling again must not double-apply.
	my $added2 = App::GHGen::Fixer::add_permissions($workflow);
	is($added2, 0, 'returns 0 when permissions already present');
};

subtest 'Fixer::add_concurrency - idempotent concurrency insertion' => sub {
	my $workflow = { name => 'Test' };
	is(App::GHGen::Fixer::add_concurrency($workflow), 1, 'adds concurrency, returns 1');
	ok(defined $workflow->{concurrency}, 'concurrency key now present');

	is(App::GHGen::Fixer::add_concurrency($workflow), 0, 'no-ops when already present');
};

subtest 'Fixer::add_trigger_filters - restricts broad push triggers' => sub {
	# Array-form broad trigger.
	my $array_wf = { on => [qw(push pull_request)] };
	my $changed = App::GHGen::Fixer::add_trigger_filters($array_wf);
	is($changed, 1, 'array push trigger was modified');
	ok(ref $array_wf->{on} eq 'HASH', 'on key converted to hash form after fix');

	# Already-filtered workflow must not be modified.
	my $filtered_wf = { on => { push => { branches => ['main'] } } };
	is(
		App::GHGen::Fixer::add_trigger_filters($filtered_wf),
		0,
		'already-filtered trigger is not modified',
	);
};

subtest 'Fixer::add_missing_timeout - inserts timeout on jobs lacking it' => sub {
	my $workflow = {
		jobs => {
			a => { 'runs-on' => 'ubuntu-latest' },  # no timeout
			b => { 'runs-on' => 'ubuntu-latest', 'timeout-minutes' => 60 },  # already set
		},
	};
	my $count = App::GHGen::Fixer::add_missing_timeout($workflow);
	is($count, 1, 'exactly one job received a timeout');
	ok(exists $workflow->{jobs}{a}{'timeout-minutes'}, 'job a now has timeout-minutes');
	is($workflow->{jobs}{b}{'timeout-minutes'}, 60, 'job b timeout unchanged');
};

subtest 'Fixer::update_runners - upgrades known outdated runner strings' => sub {
	my $workflow = {
		jobs => {
			test => { 'runs-on' => 'ubuntu-18.04' },
		},
	};
	my $count = App::GHGen::Fixer::update_runners($workflow);
	is($count, 1, 'one runner was updated');
	is(
		$workflow->{jobs}{test}{'runs-on'},
		'ubuntu-latest',
		'ubuntu-18.04 was updated to ubuntu-latest',
	);

	# Current runner must not be changed.
	my $current = { jobs => { test => { 'runs-on' => 'ubuntu-latest' } } };
	is(App::GHGen::Fixer::update_runners($current), 0, 'current runner not touched');
};

subtest 'Fixer::fix_unpinned_actions - replaces @master and @main with versions' => sub {
	my $workflow = {
		jobs => { test => { steps => [
			{ uses => 'actions/checkout@main' },
			{ uses => 'some-other/action@master' },
			{ uses => 'pinned/action@v5' },
		]}},
	};
	my $count = App::GHGen::Fixer::fix_unpinned_actions($workflow);
	is($count, 2, 'two unpinned actions were fixed');

	for my $step (@{$workflow->{jobs}{test}{steps}}) {
		unlike($step->{uses}, qr/\@(master|main)$/, "step $step->{uses} is now pinned");
	}
};

subtest 'Fixer::update_actions - upgrades outdated action versions' => sub {
	my $workflow = {
		jobs => { test => { steps => [
			{ uses => $C{OLD_CHECKOUT_V3} },
			{ uses => $C{OLD_CACHE_V3} },
			{ uses => $C{LATEST_CHECKOUT} },  # already current
		]}},
	};
	my $count = App::GHGen::Fixer::update_actions($workflow);
	is($count, 2, 'two outdated actions were upgraded');
	is(
		$workflow->{jobs}{test}{steps}[0]{uses},
		$C{LATEST_CHECKOUT},
		'checkout@v3 upgraded to checkout@v6',
	);
};

subtest 'Fixer::add_caching - inserts cache step after checkout' => sub {
	my $workflow = {
		jobs => { test => { steps => [
			{ uses => 'actions/checkout@v6' },
			{ run  => 'npm ci' },
			{ run  => 'npm test' },
		]}},
	};
	my $count = App::GHGen::Fixer::add_caching($workflow);
	is($count, 1, 'one cache step was inserted');

	my @steps = @{$workflow->{jobs}{test}{steps}};
	ok(
		(grep { $_->{uses} && $_->{uses} =~ /actions\/cache/ } @steps),
		'workflow now contains a cache step',
	);

	# Second call must be a no-op because caching is already present.
	is(App::GHGen::Fixer::add_caching($workflow), 0, 'second add_caching call is a no-op');
};

subtest 'Fixer::apply_fixes - routes issues to the correct fixers' => sub {
	my $workflow = {
		on   => [qw(push)],
		jobs => {
			test => {
				'runs-on' => 'ubuntu-latest',
				steps => [
					{ uses => 'actions/checkout@v6' },
					{ run  => 'npm ci' },
				],
			},
		},
	};
	my @issues = (
		{ type => 'cost',        message => 'No concurrency group - old runs continue when superseded' },
		{ type => 'performance', message => 'No dependency caching found - increases build times and costs' },
	);
	my $count = apply_fixes($workflow, \@issues);
	ok($count > 0, 'at least one fix was applied');
	ok(defined $workflow->{concurrency}, 'concurrency was added');
};

subtest 'Fixer::fix_workflow - applies fixes to a YAML file on disk' => sub {
	in_tempdir(sub {
		my $yaml = <<'YAML';
---
name: Bare CI
on:
  push:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - run: npm ci
YAML
		path('workflow.yml')->spew_utf8($yaml);

		my @issues = ({
			type    => 'cost',
			message => 'No concurrency group - old runs continue when superseded',
		});
		my $fixes = fix_workflow('workflow.yml', \@issues);
		ok($fixes > 0, 'fix_workflow reports at least one fix applied');

		# The file should have been rewritten.
		ok(-e 'workflow.yml', 'workflow file still exists after fix');
	});
};

# ═══════════════════════════════════════════════════════════════════════
# 5.  App::GHGen::Generator
# ═══════════════════════════════════════════════════════════════════════

subtest 'Generator::list_workflow_types - returns expected language set' => sub {
	my %types = list_workflow_types();
	my @expected = qw(perl node python rust go ruby java cpp php docker static);
	for my $lang (@expected) {
		ok(exists $types{$lang}, "list includes '$lang'");
		ok(length $types{$lang} > 0, "'$lang' has a non-empty description");
	}
};

subtest 'Generator::generate_workflow - returns YAML for each supported type' => sub {
	my %types = list_workflow_types();
	for my $type (sort keys %types) {
		my $yaml = generate_workflow($type);
		ok(defined $yaml, "'$type' workflow generated without error");
		like($yaml, qr/^---/m, "'$type' YAML begins with ---");
		like($yaml, qr/name:/,  "'$type' YAML contains a name field");
	}
};

subtest 'Generator::generate_workflow - returns undef for unknown type' => sub {
	my $yaml = generate_workflow('cobol');
	ok(!defined $yaml, 'unknown workflow type returns undef');
};

subtest 'Generator::_generate_perl_workflow - includes Perl-specific scaffolding' => sub {
	# Call the private generator directly.
	my $yaml = App::GHGen::Generator::_generate_perl_workflow();
	ok(defined $yaml, 'Perl workflow generated');
	like($yaml, qr/shogo82148\/actions-setup-perl/, 'includes setup-perl action');
	like($yaml, qr/prove/,                          'includes prove test runner');
	like($yaml, qr/cpanm/,                          'includes cpanm');
	like($yaml, qr/matrix/,                         'uses a matrix strategy');
};

# ═══════════════════════════════════════════════════════════════════════
# 6.  App::GHGen::Interactive
# ═══════════════════════════════════════════════════════════════════════

# Helper: open a string as a fake STDIN and capture STDOUT noise.
sub with_stdin_stdout ($input, $code) {
	open(my $in, '<', \$input) or die "Cannot open string ref: $!";
	open(local *STDIN,  '<', \$input)  or die "Cannot redirect STDIN: $!";
	open(local *STDOUT, '>', \my $out) or die "Cannot redirect STDOUT: $!";
	return $code->();
}

subtest 'Interactive::prompt_yes_no - interprets yes/no/default correctly' => sub {
	is(with_stdin_stdout("y\n",   sub { prompt_yes_no("Q?", 'y') }), 1, '"y" returns 1');
	is(with_stdin_stdout("yes\n", sub { prompt_yes_no("Q?", 'y') }), 1, '"yes" returns 1');
	is(with_stdin_stdout("n\n",   sub { prompt_yes_no("Q?", 'y') }), 0, '"n" returns 0');
	is(with_stdin_stdout("no\n",  sub { prompt_yes_no("Q?", 'y') }), 0, '"no" returns 0');

	# Empty answer uses the default.
	is(with_stdin_stdout("\n", sub { prompt_yes_no("Q?", 'y') }), 1, 'empty + default y -> 1');
	is(with_stdin_stdout("\n", sub { prompt_yes_no("Q?", 'n') }), 0, 'empty + default n -> 0');
};

subtest 'Interactive::prompt_choice - returns selected index' => sub {
	my @choices = qw(alpha beta gamma);

	# Selecting choice 2 ("beta") should return index 1.
	my $idx = with_stdin_stdout("2\n", sub {
		prompt_choice("Pick one:", \@choices, 0);
	});
	is($idx, 1, 'selecting "2" returns index 1');

	# Empty answer uses the default index.
	my $default = with_stdin_stdout("\n", sub {
		prompt_choice("Pick one:", \@choices, 2);
	});
	is($default, 2, 'empty answer returns the specified default index');

	# Out-of-range answer falls back to default.
	my $fallback = with_stdin_stdout("99\n", sub {
		prompt_choice("Pick one:", \@choices, 0);
	});
	is($fallback, 0, 'out-of-range answer falls back to default');
};

subtest 'Interactive::prompt_text - returns input or default' => sub {
	my $ans = with_stdin_stdout("hello\n", sub { prompt_text("Q?", 'world') });
	is($ans, 'hello', 'typed answer returned as-is');

	my $def = with_stdin_stdout("\n", sub { prompt_text("Q?", 'world') });
	is($def, 'world', 'empty answer returns the default');
};

subtest 'Interactive::prompt_multiselect - handles comma-separated, all, and empty' => sub {
	my @opts = qw(a b c d);
	my @defs = qw(a b);

	# Choosing specific items.
	my $sel = with_stdin_stdout("1,3\n", sub {
		prompt_multiselect("Pick:", \@opts, \@defs);
	});
	is_deeply($sel, [qw(a c)], 'comma-separated input selects correct items');

	# "all" returns the full options list.
	my $all = with_stdin_stdout("all\n", sub {
		prompt_multiselect("Pick:", \@opts, \@defs);
	});
	is_deeply($all, \@opts, '"all" returns all options');

	# Empty answer returns the defaults.
	my $def = with_stdin_stdout("\n", sub {
		prompt_multiselect("Pick:", \@opts, \@defs);
	});
	is_deeply($def, \@defs, 'empty input returns the defaults');
};

subtest 'Interactive::customize_workflow - unknown type returns empty hash' => sub {
	my $config = with_stdin_stdout("", sub { customize_workflow('unknown_language') });
	is_deeply($config, {}, 'unknown workflow type returns empty hashref');
};

# ═══════════════════════════════════════════════════════════════════════
# 7.  App::GHGen::PerlCustomizer
# ═══════════════════════════════════════════════════════════════════════

subtest 'PerlCustomizer::_normalize_version - converts version strings to numbers' => sub {
	my $v36   = App::GHGen::PerlCustomizer::_normalize_version('5.36');
	my $v036  = App::GHGen::PerlCustomizer::_normalize_version('5.036');
	my $v40   = App::GHGen::PerlCustomizer::_normalize_version('5.40');

	is($v36, $v036, '5.36 and 5.036 normalise to the same value');
	ok($v40 > $v36, '5.40 normalises greater than 5.36');
	ok(looks_like_number($v36), 'normalised value is numeric');
};

subtest 'PerlCustomizer::_get_perl_versions - filters correctly for a min/max range' => sub {
	my @vers = App::GHGen::PerlCustomizer::_get_perl_versions('5.36', '5.40');
	ok(scalar @vers > 0,       'version list is non-empty');
	ok((grep { $_ eq '5.36' } @vers), '5.36 included');
	ok((grep { $_ eq '5.40' } @vers), '5.40 included');
	ok(!(grep { $_ eq '5.34' } @vers), '5.34 excluded (below min)');

	# Versions should be returned in ascending order.
	my @sorted = sort { $a <=> $b } @vers;
	is_deeply(\@vers, \@sorted, 'versions returned in ascending order');
};

subtest 'PerlCustomizer::detect_perl_requirements - reads from cpanfile and Makefile.PL' => sub {
	# This repo has a cpanfile and Makefile.PL with a Perl version requirement.
	my $reqs = detect_perl_requirements();
	ok(defined $reqs,                    'detect_perl_requirements returns a defined value');
	ok($reqs->{has_cpanfile},            'cpanfile detected in App-GHGen repo');
	ok($reqs->{has_makefile_pl},         'Makefile.PL detected');
	ok(defined $reqs->{min_version},     'min_version extracted from cpanfile or Makefile.PL');
	like($reqs->{min_version}, qr/5\./,  'min_version looks like a Perl version');

	# In an empty directory none of the files exist.
	in_tempdir(sub {
		my $empty = detect_perl_requirements();
		ok(!$empty->{has_cpanfile},    'no cpanfile in empty dir');
		ok(!$empty->{has_makefile_pl}, 'no Makefile.PL in empty dir');
		ok(!defined $empty->{min_version}, 'min_version undef in empty dir');
	});

	memory_cycle_ok($reqs, 'requirements hash has no circular references');
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - produces valid YAML skeleton' => sub {
	my $yaml = generate_custom_perl_workflow({
		min_perl_version => '5.36',
		max_perl_version => '5.40',
		os               => ['ubuntu-latest'],
		enable_linter    => 1,
		enable_critic    => 0,
		enable_coverage  => 0,
	});

	ok(defined $yaml,                           'workflow YAML was generated');
	like($yaml, qr/^---/m,                      'YAML starts with ---');
	like($yaml, qr/Perl CI/,                    'workflow is named "Perl CI"');
	like($yaml, qr/shogo82148\/actions-setup-perl/, 'includes setup-perl action');
	like($yaml, qr/actions\/cache/,             'includes caching step');
	like($yaml, qr/Lint and syntax check/,      'lint step present when enable_linter=1');
	like($yaml, qr/shell: perl \{0\}/,          'lint step uses shell: perl {0}');
	like($yaml, qr/File::Find/,                 'lint step uses File::Find for discovery');
	unlike($yaml, qr/Perl::Critic/,             'critic step absent when enable_critic=0');
	unlike($yaml, qr/Devel::Cover/,             'coverage step absent when enable_coverage=0');

	diag(substr($yaml, 0, 500)) if $ENV{TEST_VERBOSE};
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - enable_linter=0 omits lint step' => sub {
	my $yaml = generate_custom_perl_workflow({ enable_linter => 0 });
	unlike($yaml, qr/Lint and syntax check/, 'no lint step when enable_linter=0');
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - enable_linter_unused=1 adds unused step' => sub {
	my $yaml = generate_custom_perl_workflow({
		enable_linter_unused => 1,
		enable_critic        => 0,
		enable_coverage      => 0,
	});
	# warnings::unused is now embedded inside the lint step (before Run tests),
	# run via PERL5OPT so it applies to the entire test suite execution.
	like($yaml,  qr/PERL5OPT=-Mwarnings::unused/, 'unused-var check present in lint step');
	like($yaml,  qr/warnings::unused/,            'installs warnings::unused');
	like($yaml,  qr/\|\| echo/,                   'check is non-blocking');

	# Check appears before "Run tests" (it lives inside the lint step).
	my $pos_tests  = index($yaml, 'Run tests');
	my $pos_unused = index($yaml, 'PERL5OPT=-Mwarnings::unused');
	ok($pos_unused < $pos_tests, 'unused-var check comes before test step (inside lint step)');
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - enable_perlimports=1 adds perlimports step' => sub {
	my $yaml = generate_custom_perl_workflow({
		enable_perlimports => 1,
		enable_critic      => 0,
		enable_coverage    => 0,
	});
	like($yaml, qr/Check imports with perlimports/, 'perlimports step present');
	like($yaml, qr/App::perlimports/,               'installs App::perlimports');
	like($yaml, qr/perlimports --lint/,             'runs perlimports in lint mode');
	like($yaml, qr/continue-on-error: true/,        'perlimports is non-blocking');

	# perlimports step must appear after Run tests.
	my $pos_tests       = index($yaml, 'Run tests');
	my $pos_perlimports = index($yaml, 'App::perlimports');
	ok($pos_perlimports > $pos_tests, 'perlimports step comes after Run tests');
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - enable_perlimports=0 omits step' => sub {
	my $yaml = generate_custom_perl_workflow({ enable_perlimports => 0 });
	unlike($yaml, qr/Check imports with perlimports/, 'perlimports step absent when disabled');
	unlike($yaml, qr/App::perlimports/,               'App::perlimports not installed when disabled');
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - explicit perl_versions list' => sub {
	my $yaml = generate_custom_perl_workflow({
		perl_versions => ['5.36', '5.38'],
	});
	like($yaml, qr/'5\.36'/, 'explicit version 5.36 appears in YAML');
	like($yaml, qr/'5\.38'/, 'explicit version 5.38 appears in YAML');
	unlike($yaml, qr/'5\.40'/, 'version 5.40 absent when not in explicit list');
};

# ═══════════════════════════════════════════════════════════════════════
# 8.  App::GHGen::Reporter
# ═══════════════════════════════════════════════════════════════════════

subtest 'Reporter::get_type_emoji - returns non-empty string for each type' => sub {
	my %C_emojis = (
		performance => 1,
		security    => 1,
		cost        => 1,
		maintenance => 1,
	);
	for my $type (keys %C_emojis) {
		my $e = App::GHGen::Reporter::get_type_emoji($type);
		ok(defined $e && length $e > 0, "get_type_emoji('$type') returns non-empty string");
	}
	# Unknown type should return a fallback, not undef.
	ok(
		defined App::GHGen::Reporter::get_type_emoji('unknown_type'),
		'unknown type returns a defined fallback emoji',
	);
};

subtest 'Reporter::get_severity_badge - returns non-empty string for each level' => sub {
	for my $sev (qw(high medium low)) {
		my $badge = App::GHGen::Reporter::get_severity_badge($sev);
		ok(defined $badge && length $badge > 0, "get_severity_badge('$sev') returns non-empty string");
	}
	ok(
		defined App::GHGen::Reporter::get_severity_badge('unknown'),
		'unknown severity returns a defined fallback badge',
	);
};

subtest 'Reporter::estimate_savings - aggregates CI minutes per issue type' => sub {
	my @caching = ({
		type    => 'performance',
		message => 'No dependency caching found - increases build times and costs',
	});
	my $s = estimate_savings(\@caching);
	ok($s->{minutes} > 0, 'caching issue yields minute savings');
	ok($s->{cost} >= 0,   'cost field is non-negative');

	my @cost_issues = (
		{ type => 'cost', message => 'No concurrency group - old runs continue when superseded' },
		{ type => 'cost', message => 'Workflow triggers on all pushes - consider path/branch filters' },
	);
	my $s2 = estimate_savings(\@cost_issues);
	ok($s2->{minutes} > 0, 'concurrency + trigger issues yield savings');

	# No issues -> zero savings.
	my $zero = estimate_savings([]);
	is($zero->{minutes}, 0, 'empty issue list yields zero savings');

	memory_cycle_ok($s, 'savings result has no circular references');
};

subtest 'Reporter::generate_markdown_report - structure and content' => sub {
	my @issues = (
		{ type => 'performance', severity => 'medium',
		  message => 'No caching', fix => 'Add caching' },
		{ type => 'security',    severity => 'high',
		  message => 'Unpinned action', fix => 'Pin it' },
	);
	my $report = generate_markdown_report(\@issues);

	ok(defined $report,               'report generated without error');
	like($report, qr/# GHGen/,        'report has main heading');
	like($report, qr/Issues found/i,  'report mentions issue count');
	like($report, qr/performance/i,   'report includes performance section');
	like($report, qr/security/i,      'report includes security section');
	like($report, qr/No caching/,     'report contains first issue message');
	like($report, qr/Unpinned action/,'report contains second issue message');

	# With fixes applied the summary should mention them.
	my $with_fixes = generate_markdown_report(\@issues, ['fix1', 'fix2']);
	like($with_fixes, qr/Fixes applied/i, 'fix count appears when fixes provided');

	# No issues -> no "Issues by Category" section needed.
	my $empty = generate_markdown_report([]);
	unlike($empty, qr/Issues by Category/, 'no-issue report omits category section');

	memory_cycle_ok(\$report, 'report string has no circular references');
};

subtest 'Reporter::generate_github_comment - produces GitHub-ready comment' => sub {
	# Zero issues -> celebration message.
	my $empty_comment = generate_github_comment([]);
	like($empty_comment, qr/No issues found/i, 'zero-issue comment says no issues found');

	my @issues = ({
		type     => 'performance',
		severity => 'medium',
		message  => 'No caching',
		file     => 'ci.yml',
	});
	my $comment = generate_github_comment(\@issues);

	ok(defined $comment,              'comment generated');
	like($comment, qr/GHGen/,         'comment references GHGen');
	like($comment, qr/Performance/i,  'comment includes Performance section');
	like($comment, qr/No caching/,    'comment includes issue message');
	like($comment, qr/ci\.yml/,       'comment shows file name from issue hash');

	# With auto-fixes applied the comment should acknowledge them.
	my $fixed_comment = generate_github_comment(\@issues, ['some_fix']);
	like($fixed_comment, qr/fix/i, 'comment with fixes applied mentions fixes');

	memory_cycle_ok(\$comment, 'comment string has no circular references');
};

done_testing();
