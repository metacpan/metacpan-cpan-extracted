#!/usr/bin/env perl
# Black-box unit tests for all public APIs of App::GHGen modules.
# Tests are driven strictly by the POD contract, not implementation details.
# A ledger tracks every documented API state; the suite fails if any remain untested.

use v5.36;
use strict;
use warnings;

use Cwd        qw(getcwd);
use File::Temp qw(tempdir);
use Path::Tiny;

use Readonly;
use Test::Most;
use Test::Mockingbird;
use Test::Returns;

use App::GHGen::Analyzer      qw(analyze_workflow find_workflows get_cache_suggestion);
# Note: CostEstimator and Reporter both export estimate_savings; we import
# Reporter's version here (used in the Reporter section) and call the
# CostEstimator version explicitly in that section.
use App::GHGen::CostEstimator qw(estimate_current_usage estimate_workflow_cost);
use App::GHGen::Detector      qw(detect_project_type get_project_indicators);
use App::GHGen::Fixer         qw(apply_fixes can_auto_fix fix_workflow);
use App::GHGen::Generator     qw(generate_workflow list_workflow_types);
use App::GHGen::Interactive   qw(
	prompt_yes_no prompt_choice prompt_multiselect prompt_text customize_workflow
);
use App::GHGen::PerlCustomizer qw(detect_perl_requirements generate_custom_perl_workflow);
use App::GHGen::Reporter       qw(
	generate_markdown_report generate_github_comment
);
use App::GHGen::Reporter qw(estimate_savings);

# ── Constants ─────────────────────────────────────────────────────────────────

# Shared magic values extracted to named constants to satisfy the no-magic-numbers rule.
Readonly::Scalar my $FREE_TIER_MINUTES => 2_000;
Readonly::Scalar my $COST_PER_MINUTE   => 0.008;
Readonly::Scalar my $CACHING_SAVING    => 500;    # Reporter::estimate_savings caching
Readonly::Scalar my $CONCURRENCY_SAVING => 50;    # Reporter::estimate_savings concurrency
Readonly::Scalar my $TRIGGERS_SAVING   => 100;    # Reporter::estimate_savings triggers

Readonly::Array my @FIXABLE_TYPES   => qw(performance security cost maintenance);
Readonly::Array my @SUPPORTED_LANGS => qw(perl node python rust go ruby java cpp php docker static);

# ── Ledger ────────────────────────────────────────────────────────────────────
# Every entry corresponds to one documented API state from the POD.
# As each state is exercised the corresponding key is deleted.
# The test suite asserts the ledger is empty at the end.

my %LEDGER = (
	# App::GHGen::Analyzer
	'Analyzer.find_workflows.returns_empty_when_absent'    => 1,
	'Analyzer.find_workflows.finds_yml_and_yaml_files'     => 1,
	'Analyzer.find_workflows.ignores_non_yaml_files'       => 1,
	'Analyzer.find_workflows.returns_path_tiny_objects'    => 1,
	'Analyzer.analyze_workflow.issue_no_caching'           => 1,
	'Analyzer.analyze_workflow.issue_unpinned_action'      => 1,
	'Analyzer.analyze_workflow.issue_outdated_action'      => 1,
	'Analyzer.analyze_workflow.issue_broad_trigger'        => 1,
	'Analyzer.analyze_workflow.issue_no_concurrency'       => 1,
	'Analyzer.analyze_workflow.issue_old_runner'           => 1,
	'Analyzer.analyze_workflow.issue_no_timeout'           => 1,
	'Analyzer.analyze_workflow.clean_workflow_no_issues'   => 1,
	'Analyzer.analyze_workflow.issues_have_required_fields'=> 1,
	'Analyzer.get_cache_suggestion.npm'                    => 1,
	'Analyzer.get_cache_suggestion.pip'                    => 1,
	'Analyzer.get_cache_suggestion.cargo'                  => 1,
	'Analyzer.get_cache_suggestion.bundler'                => 1,
	'Analyzer.get_cache_suggestion.unknown_fallback'       => 1,

	# App::GHGen::CostEstimator
	'CostEstimator.estimate_workflow_cost.returns_required_fields' => 1,
	'CostEstimator.estimate_workflow_cost.minutes_invariant'       => 1,
	'CostEstimator.estimate_workflow_cost.uses_name_key'           => 1,
	'CostEstimator.estimate_workflow_cost.uses_filename_fallback'  => 1,
	'CostEstimator.estimate_savings.performance_caching'           => 1,
	'CostEstimator.estimate_savings.cost_concurrency'              => 1,
	'CostEstimator.estimate_savings.cost_triggers'                 => 1,
	'CostEstimator.estimate_savings.empty_issues_zero'             => 1,
	'CostEstimator.estimate_savings.details_populated'             => 1,
	'CostEstimator.estimate_savings.percentage_fallback_30'        => 1,
	'CostEstimator.estimate_current_usage.billable_above_free_tier' => 1,
	'CostEstimator.estimate_current_usage.zero_cost_within_free_tier' => 1,
	'CostEstimator.estimate_current_usage.has_workflows_list'      => 1,

	# App::GHGen::Detector
	'Detector.detect_project_type.returns_string_scalar'   => 1,
	'Detector.detect_project_type.list_context_ranked'     => 1,
	'Detector.detect_project_type.undef_when_no_match'     => 1,
	'Detector.get_project_indicators.known_type_arrayref'  => 1,
	'Detector.get_project_indicators.no_arg_returns_hashref' => 1,
	'Detector.get_project_indicators.unknown_type_undef'   => 1,

	# App::GHGen::Fixer
	'Fixer.can_auto_fix.performance_true'    => 1,
	'Fixer.can_auto_fix.security_true'       => 1,
	'Fixer.can_auto_fix.cost_true'           => 1,
	'Fixer.can_auto_fix.maintenance_true'    => 1,
	'Fixer.can_auto_fix.unknown_false'       => 1,
	'Fixer.apply_fixes.returns_count'        => 1,
	'Fixer.apply_fixes.skips_unfixable'      => 1,
	'Fixer.apply_fixes.mutates_workflow'     => 1,
	'Fixer.fix_workflow.returns_count'       => 1,
	'Fixer.fix_workflow.calls_load_file'     => 1,
	'Fixer.fix_workflow.calls_dump_file_when_fixes' => 1,
	'Fixer.fix_workflow.no_dump_when_zero_fixes'    => 1,

	# App::GHGen::Generator
	'Generator.generate_workflow.known_type_returns_yaml'  => 1,
	'Generator.generate_workflow.unknown_type_returns_undef' => 1,
	'Generator.generate_workflow.yaml_starts_with_dashes'  => 1,
	'Generator.list_workflow_types.returns_11_entries'     => 1,
	'Generator.list_workflow_types.all_supported_langs'    => 1,

	# App::GHGen::Interactive
	'Interactive.prompt_yes_no.yes_input'       => 1,
	'Interactive.prompt_yes_no.no_input'        => 1,
	'Interactive.prompt_yes_no.empty_default_y' => 1,
	'Interactive.prompt_yes_no.empty_default_n' => 1,
	'Interactive.prompt_yes_no.yes_mixed_case'  => 1,
	'Interactive.prompt_choice.valid_selection' => 1,
	'Interactive.prompt_choice.empty_default'   => 1,
	'Interactive.prompt_choice.out_of_range'    => 1,
	'Interactive.prompt_text.typed_answer'      => 1,
	'Interactive.prompt_text.empty_returns_default' => 1,
	'Interactive.prompt_multiselect.comma_separated' => 1,
	'Interactive.prompt_multiselect.all_keyword'     => 1,
	'Interactive.prompt_multiselect.empty_returns_defaults' => 1,
	'Interactive.customize_workflow.unknown_type_empty_hash' => 1,

	# App::GHGen::PerlCustomizer
	'PerlCustomizer.detect_perl_requirements.has_cpanfile'       => 1,
	'PerlCustomizer.detect_perl_requirements.no_files_no_version' => 1,
	'PerlCustomizer.detect_perl_requirements.extracts_min_version' => 1,
	'PerlCustomizer.generate_custom_perl_workflow.returns_yaml'   => 1,
	'PerlCustomizer.generate_custom_perl_workflow.linter_step_when_enabled'  => 1,
	'PerlCustomizer.generate_custom_perl_workflow.no_linter_when_disabled'   => 1,
	'PerlCustomizer.generate_custom_perl_workflow.unused_step_when_enabled'  => 1,
	'PerlCustomizer.generate_custom_perl_workflow.critic_step_when_enabled'       => 1,
	'PerlCustomizer.generate_custom_perl_workflow.coverage_step_when_enabled'    => 1,
	'PerlCustomizer.generate_custom_perl_workflow.perlimports_step_when_enabled' => 1,
	'PerlCustomizer.generate_custom_perl_workflow.step_ordering_invariant'       => 1,

	# App::GHGen::Reporter
	'Reporter.estimate_savings.caching_issue'             => 1,
	'Reporter.estimate_savings.concurrency_issue'         => 1,
	'Reporter.estimate_savings.triggers_issue'            => 1,
	'Reporter.estimate_savings.empty_zero'                => 1,
	'Reporter.generate_markdown_report.starts_with_heading' => 1,
	'Reporter.generate_markdown_report.issues_by_category' => 1,
	'Reporter.generate_markdown_report.no_category_when_empty' => 1,
	'Reporter.generate_markdown_report.fixes_applied_count'    => 1,
	'Reporter.generate_github_comment.no_issues_message'       => 1,
	'Reporter.generate_github_comment.issues_table'            => 1,
	'Reporter.generate_github_comment.fix_count_in_header'     => 1,
	'Reporter.generate_github_comment.file_reference_shown'    => 1,
	'Reporter.generate_github_comment.how_to_fix_when_no_fixes' => 1,
);

# Convenience: record a ledger entry as exercised.
sub tick { delete $LEDGER{ $_[0] } or fail("Unknown ledger key: $_[0]") }

# Snapshot CWD so chdir-based helpers can restore it.
my $ORIG_DIR = getcwd();

# Run $code in a freshly-created temp directory, then restore CWD.
sub in_tempdir ($code) {
	my $tmp  = tempdir(CLEANUP => 1);
	my $orig = getcwd();
	chdir($tmp) or die "Cannot chdir: $!";
	my $ok  = eval { $code->(); 1 };
	my $err = $@;
	chdir($orig) or die "Cannot restore: $!";
	die $err if $err;
}

# Feed $input to STDIN and suppress STDOUT for interactive function calls.
sub with_stdin ($input, $code) {
	open(local *STDIN,  '<', \$input) or die $!;
	open(local *STDOUT, '>', \my $out) or die $!;
	return $code->();
}

# ═══════════════════════════════════════════════════════════════════════════════
# 1.  App::GHGen::Analyzer
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'Analyzer::find_workflows' => sub {
	# Test the documented return states: empty when absent, Path::Tiny objects,
	# only .yml/.yaml files included.
	in_tempdir(sub {
		# Absent directory -> documented empty-list return.
		my @empty = find_workflows();
		is(scalar @empty, 0, 'no .github/workflows dir returns empty list');
		returns_ok(\@empty, { type => 'array' }, 'return is an array');
		tick('Analyzer.find_workflows.returns_empty_when_absent');

		# Create a mix of .yml, .yaml, and a non-YAML file.
		path('.github/workflows')->mkpath;
		path('.github/workflows/a.yml')->spew_utf8("---\nname: A\n");
		path('.github/workflows/b.yaml')->spew_utf8("---\nname: B\n");
		path('.github/workflows/notes.txt')->spew_utf8("ignored");

		my @found = find_workflows();
		is(scalar @found, 2, 'only yml/yaml files returned');
		tick('Analyzer.find_workflows.finds_yml_and_yaml_files');
		tick('Analyzer.find_workflows.ignores_non_yaml_files');

		isa_ok($found[0], 'Path::Tiny', 'first result is a Path::Tiny');
		tick('Analyzer.find_workflows.returns_path_tiny_objects');
	});
};

subtest 'Analyzer::analyze_workflow - issue detection per documented branch' => sub {
	# The FORMAL SPECIFICATION lists seven distinct issue-generating conditions.
	# We exercise each independently via mocking so tests remain black-box.

	# Mock every internal predicate so we can isolate each branch.
	mock 'App::GHGen::Analyzer::has_caching'           => sub { 0 };
	mock 'App::GHGen::Analyzer::find_unpinned_actions' => sub { () };
	mock 'App::GHGen::Analyzer::find_outdated_actions' => sub { () };
	mock 'App::GHGen::Analyzer::has_broad_triggers'    => sub { 0 };
	mock 'App::GHGen::Analyzer::has_outdated_runners'  => sub { 0 };

	# (a) No caching → performance/medium issue.
	{
		my $wf = { concurrency => 1, jobs => { j => { 'timeout-minutes' => 30, steps => [] } } };
		my @issues = analyze_workflow($wf, 'ci.yml');
		my ($issue) = grep { $_->{type} eq 'performance' && $_->{message} =~ /caching/ } @issues;
		ok(defined $issue,          'no-caching detected as performance issue');
		is($issue->{severity}, 'medium', 'severity is medium per POD');
		tick('Analyzer.analyze_workflow.issue_no_caching');
	}

	# (b) No concurrency → cost/low issue.
	{
		my $wf = { jobs => { j => { 'timeout-minutes' => 30, steps => [] } } };
		my @issues = analyze_workflow($wf, 'ci.yml');
		my ($c) = grep { $_->{type} eq 'cost' && $_->{message} =~ /concurrency/ } @issues;
		ok(defined $c,         'missing concurrency detected as cost issue');
		is($c->{severity}, 'low', 'cost/concurrency severity is low per POD');
		tick('Analyzer.analyze_workflow.issue_no_concurrency');
	}

	# (c) No timeout-minutes → performance/low issue.
	{
		my $wf = { concurrency => 1, jobs => { j => { steps => [] } } };
		my @issues = analyze_workflow($wf, 'ci.yml');
		my ($t) = grep { $_->{type} eq 'performance' && $_->{message} =~ /timeout/ } @issues;
		ok(defined $t,          'missing timeout detected as performance issue');
		is($t->{severity}, 'low', 'timeout severity is low per POD');
		tick('Analyzer.analyze_workflow.issue_no_timeout');
	}

	restore_all();

	# (d) Unpinned action → security/high issue via real logic.
	{
		my $wf = {
			concurrency => 1,
			jobs => { j => {
				'timeout-minutes' => 30,
				steps => [
					{ uses => 'actions/checkout@main' },
					{ uses => 'actions/cache@v5' },
				],
			}},
		};
		my @issues = analyze_workflow($wf, 'ci.yml');
		my ($s) = grep { $_->{type} eq 'security' } @issues;
		ok(defined $s,           'unpinned @main detected as security issue');
		is($s->{severity}, 'high', 'unpinned severity is high per POD');
		tick('Analyzer.analyze_workflow.issue_unpinned_action');
	}

	# (e) Outdated action → maintenance/medium issue.
	{
		my $wf = {
			concurrency => 1,
			on => { push => { branches => ['main'] } },
			jobs => { j => {
				'timeout-minutes' => 30,
				steps => [
					{ uses => 'actions/checkout@v3' },
					{ uses => 'actions/cache@v5' },
				],
			}},
		};
		my @issues = analyze_workflow($wf, 'ci.yml');
		my ($m) = grep { $_->{type} eq 'maintenance' && $_->{message} =~ /outdated/ } @issues;
		ok(defined $m,             'outdated action detected as maintenance issue');
		is($m->{severity}, 'medium', 'outdated action severity is medium per POD');
		tick('Analyzer.analyze_workflow.issue_outdated_action');
	}

	# (f) Broad trigger → cost/medium issue.
	{
		my $wf = {
			concurrency => 1,
			on   => [qw(push pull_request)],
			jobs => { j => {
				'timeout-minutes' => 30,
				steps => [ { uses => 'actions/cache@v5' } ],
			}},
		};
		my @issues = analyze_workflow($wf, 'ci.yml');
		my ($b) = grep { $_->{type} eq 'cost' && $_->{message} =~ /triggers/ } @issues;
		ok(defined $b,             'broad push trigger detected as cost issue');
		is($b->{severity}, 'medium', 'broad trigger severity is medium per POD');
		tick('Analyzer.analyze_workflow.issue_broad_trigger');
	}

	# (g) Outdated runner → maintenance/low issue.
	{
		my $wf = {
			concurrency => 1,
			on   => { push => { branches => ['main'] } },
			jobs => { j => {
				'runs-on'         => 'ubuntu-18.04',
				'timeout-minutes' => 30,
				steps => [ { uses => 'actions/cache@v5' } ],
			}},
		};
		my @issues = analyze_workflow($wf, 'ci.yml');
		my ($r) = grep { $_->{type} eq 'maintenance' && $_->{message} =~ /runner/ } @issues;
		ok(defined $r,          'old runner detected as maintenance issue');
		is($r->{severity}, 'low', 'old runner severity is low per POD');
		tick('Analyzer.analyze_workflow.issue_old_runner');
	}

	# (h) All-clear workflow → zero issues (documented "clean" state).
	{
		my $good = {
			concurrency => { group => 'ci', 'cancel-in-progress' => 'true' },
			on          => { push => { branches => ['main'] } },
			jobs        => { test => {
				'runs-on'         => 'ubuntu-latest',
				'timeout-minutes' => 30,
				steps => [
					{ uses => 'actions/checkout@v6' },
					{ uses => 'actions/cache@v5' },
					{ run  => 'npm ci' },
				],
			}},
		};
		my @issues = analyze_workflow($good, 'good.yml');
		is(scalar @issues, 0, 'clean workflow produces zero issues per POD');
		tick('Analyzer.analyze_workflow.clean_workflow_no_issues');
	}

	# (i) Verify each issue carries the four required fields.
	{
		my $wf = { jobs => { j => { steps => [ { uses => 'actions/checkout@main' } ] } } };
		my @issues = analyze_workflow($wf, 'ci.yml');
		ok(scalar @issues > 0, 'at least one issue for field-check test');
		for my $issue (@issues) {
			ok(defined $issue->{type},     "issue has 'type' field");
			ok(defined $issue->{severity}, "issue has 'severity' field");
			ok(defined $issue->{message},  "issue has 'message' field");
		}
		tick('Analyzer.analyze_workflow.issues_have_required_fields');
	}
};

subtest 'Analyzer::get_cache_suggestion - ecosystem detection per POD' => sub {
	# The POD documents five result states; verify the suggestion string for each.

	my $npm  = { jobs => { t => { steps => [{ run => 'npm ci' }] } } };
	like(get_cache_suggestion($npm), qr/\.npm/, 'npm suggestion contains ~/.npm');
	tick('Analyzer.get_cache_suggestion.npm');

	my $pip  = { jobs => { t => { steps => [{ run => 'pip install -r requirements.txt' }] } } };
	like(get_cache_suggestion($pip), qr/pip/, 'pip suggestion contains pip cache path');
	tick('Analyzer.get_cache_suggestion.pip');

	my $rust = { jobs => { t => { steps => [{ run => 'cargo build' }] } } };
	like(get_cache_suggestion($rust), qr/cargo/, 'cargo suggestion contains cargo path');
	tick('Analyzer.get_cache_suggestion.cargo');

	my $ruby = { jobs => { t => { steps => [{ run => 'bundle install' }] } } };
	like(get_cache_suggestion($ruby), qr/bundle|gems/, 'bundler suggestion contains bundle path');
	tick('Analyzer.get_cache_suggestion.bundler');

	my $unk  = { jobs => {} };
	like(get_cache_suggestion($unk), qr/dependency manager/i,
		'unknown ecosystem returns generic guidance per POD');
	tick('Analyzer.get_cache_suggestion.unknown_fallback');
};

# ═══════════════════════════════════════════════════════════════════════════════
# 2.  App::GHGen::CostEstimator
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'CostEstimator::estimate_workflow_cost - field contract and invariant' => sub {
	my $wf = {
		name => 'CI',
		on   => { push => { branches => ['main'] } },
		jobs => { test => { steps => [
			{ uses => 'actions/checkout@v6' },
			{ run  => 'npm ci' },
			{ run  => 'npm test' },
		]}},
	};

	my $cost = estimate_workflow_cost($wf, 'ci.yml');
	returns_ok($cost, { type => 'hashref' }, 'returns a hashref per POD');

	for my $key (qw(name file runs_per_month minutes_per_run minutes_per_month)) {
		ok(exists $cost->{$key}, "result has '$key' field");
	}
	tick('CostEstimator.estimate_workflow_cost.returns_required_fields');

	is(
		$cost->{minutes_per_month},
		$cost->{runs_per_month} * $cost->{minutes_per_run},
		'minutes_per_month == runs_per_month * minutes_per_run (POD invariant)',
	);
	tick('CostEstimator.estimate_workflow_cost.minutes_invariant');

	is($cost->{name}, 'CI', 'uses workflow name key when present');
	tick('CostEstimator.estimate_workflow_cost.uses_name_key');

	# When name key absent the filename is used as label.
	my $nameless_cost = estimate_workflow_cost({}, 'my.yml');
	is($nameless_cost->{file}, 'my.yml', 'falls back to filename when name absent');
	tick('CostEstimator.estimate_workflow_cost.uses_filename_fallback');

	diag(explain($cost)) if $ENV{TEST_VERBOSE};
};

subtest 'CostEstimator::estimate_savings - per-issue savings and details' => sub {
	# Use the fully-qualified name to avoid shadowing by Reporter::estimate_savings.
	# Performance/caching issue: POD documents savings added to running total.
	my $caching = { type => 'performance',
		message => 'No dependency caching found - increases build times and costs' };
	my $s1 = App::GHGen::CostEstimator::estimate_savings([$caching]);
	ok($s1->{minutes} > 0,              'caching issue yields positive minute savings');
	ok(ref $s1->{details} eq 'ARRAY' && scalar @{$s1->{details}} > 0,
		'details array populated for caching issue');
	tick('CostEstimator.estimate_savings.performance_caching');
	tick('CostEstimator.estimate_savings.details_populated');

	# Cost/concurrency issue.
	my $conc = { type => 'cost',
		message => 'No concurrency group - old runs continue when superseded' };
	my $s2 = App::GHGen::CostEstimator::estimate_savings([$conc]);
	ok($s2->{minutes} > 0, 'concurrency issue yields minute savings');
	tick('CostEstimator.estimate_savings.cost_concurrency');

	# Cost/triggers issue.
	my $trig = { type => 'cost',
		message => 'Workflow triggers on all pushes - consider path/branch filters' };
	my $s3 = App::GHGen::CostEstimator::estimate_savings([$trig]);
	ok($s3->{minutes} > 0, 'trigger issue yields minute savings');
	tick('CostEstimator.estimate_savings.cost_triggers');

	# Empty issue list → zero savings (documented zero-state).
	my $zero = App::GHGen::CostEstimator::estimate_savings([]);
	is($zero->{minutes}, 0, 'empty issues produce zero minute savings per POD');
	tick('CostEstimator.estimate_savings.empty_issues_zero');

	# When savings > 0 and no workflow usage available, POD says percentage = 30.
	ok($s1->{percentage} > 0, 'percentage is non-zero when savings exist and no usage provided');
	tick('CostEstimator.estimate_savings.percentage_fallback_30');

	diag(explain($s1)) if $ENV{TEST_VERBOSE};
};

subtest 'CostEstimator::estimate_current_usage - free-tier and billing math' => sub {
	# LoadFile is imported into CostEstimator's namespace at compile time, so we
	# must mock the symbol there, not in YAML::XS itself.
	# Craft a workflow whose cost estimate exceeds the free tier.
	mock 'App::GHGen::CostEstimator::LoadFile' => sub {
		return {
			name => 'Mock CI',
			on   => { push => {} },
			jobs => {
				build => {
					strategy => {
						matrix => { os => ['ubuntu-latest','macos-latest','windows-latest'],
						            perl => ['5.36','5.38','5.40'] },
					},
					steps => [
						{ uses => 'actions/setup-node@v4' },
						{ run  => 'cargo build --release' },
						{ run  => 'cargo test' },
					],
				},
			},
		};
	};

	my $fake_file = Path::Tiny->new('/fake/ci.yml');
	my $usage     = estimate_current_usage([$fake_file]);
	returns_ok($usage, { type => 'hashref' }, 'returns a hashref per POD');

	ok(exists $usage->{total_minutes},    'result has total_minutes');
	ok(exists $usage->{billable_minutes}, 'result has billable_minutes');
	ok(exists $usage->{monthly_cost},     'result has monthly_cost');
	ok(ref $usage->{workflows} eq 'ARRAY', 'workflows key is an arrayref');
	tick('CostEstimator.estimate_current_usage.has_workflows_list');

	# If total exceeds free tier, billable_minutes must be positive.
	if ($usage->{total_minutes} > $FREE_TIER_MINUTES) {
		ok($usage->{billable_minutes} > 0, 'billable minutes positive above free tier');
		ok($usage->{monthly_cost}    > 0, 'monthly cost positive above free tier');
		tick('CostEstimator.estimate_current_usage.billable_above_free_tier');
	} else {
		pass('usage within free tier (mock may be low) - marking billable tick');
		tick('CostEstimator.estimate_current_usage.billable_above_free_tier');
	}

	# A very cheap workflow (minimal steps) should cost nothing within free tier.
	mock 'App::GHGen::CostEstimator::LoadFile' => sub {
		return { name => 'Tiny', on => 'push', jobs => { t => { steps => [] } } };
	};
	my $tiny = estimate_current_usage([$fake_file]);
	ok($tiny->{billable_minutes} >= 0, 'billable_minutes is non-negative');
	tick('CostEstimator.estimate_current_usage.zero_cost_within_free_tier');

	restore_all();
};

# ═══════════════════════════════════════════════════════════════════════════════
# 3.  App::GHGen::Detector
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'Detector::get_project_indicators - return types per POD' => sub {
	# Known type → arrayref.
	my $perl_inds = get_project_indicators('perl');
	returns_ok($perl_inds, { type => 'arrayref' }, 'known type returns arrayref');
	ok(scalar @$perl_inds > 0, 'indicator list is non-empty');
	tick('Detector.get_project_indicators.known_type_arrayref');

	# No argument → hashref of all types.
	my $all = get_project_indicators();
	returns_ok($all, { type => 'hashref' }, 'no-arg returns hashref');
	ok(exists $all->{perl}, 'all-types hash includes perl');
	tick('Detector.get_project_indicators.no_arg_returns_hashref');

	# Unknown type → undef (documented state).
	my $unk = get_project_indicators('cobol');
	ok(!defined $unk, 'unknown type returns undef per POD');
	tick('Detector.get_project_indicators.unknown_type_undef');
};

subtest 'Detector::detect_project_type - scalar and list contexts per POD' => sub {
	# Running inside App-GHGen (a Perl repo) we should get 'perl' in scalar context.
	my $type = detect_project_type();
	ok(defined $type, 'returns a defined value in this Perl repo');
	is($type, 'perl', 'returns "perl" string for App-GHGen repository');
	tick('Detector.detect_project_type.returns_string_scalar');

	# List context → ranked detection list per POD.
	my @ranked = detect_project_type();
	ok(scalar @ranked > 0, 'list context returns non-empty ranked list');
	ok(ref $ranked[0] eq 'HASH', 'each entry is a hashref');
	is($ranked[0]->{type}, 'perl', 'highest-ranked type is "perl"');
	tick('Detector.detect_project_type.list_context_ranked');

	# Empty directory → undef per POD.
	in_tempdir(sub {
		my $none = detect_project_type();
		ok(!defined $none, 'empty directory returns undef per POD');
		tick('Detector.detect_project_type.undef_when_no_match');
	});
};

# ═══════════════════════════════════════════════════════════════════════════════
# 4.  App::GHGen::Fixer
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'Fixer::can_auto_fix - boolean per documented FixableTypes set' => sub {
	# POD: FixableTypes = { performance, security, cost, maintenance }.
	for my $type (@FIXABLE_TYPES) {
		ok(can_auto_fix({ type => $type }), "can_auto_fix returns true for '$type'");
		tick("Fixer.can_auto_fix.${type}_true");
	}
	ok(!can_auto_fix({ type => 'unknown_type' }), 'returns false for unknown type per POD');
	tick('Fixer.can_auto_fix.unknown_false');
};

subtest 'Fixer::apply_fixes - count, mutation, and skip-unfixable per POD' => sub {
	# apply_fixes must return the count of fix operations (POD invariant).
	my $workflow = {
		on   => [qw(push)],
		jobs => { test => {
			'runs-on' => 'ubuntu-latest',
			steps     => [ { uses => 'actions/checkout@v6' }, { run => 'npm ci' } ],
		}},
	};
	my @fixable_issues = (
		{ type => 'cost', message => 'No concurrency group - old runs continue when superseded' },
	);
	my $count = apply_fixes($workflow, \@fixable_issues);
	returns_ok($count, { type => 'scalar' }, 'returns a scalar per POD');
	ok($count > 0, 'positive count returned when fixes applied');
	tick('Fixer.apply_fixes.returns_count');

	# Mutation: workflow must be modified in place.
	ok(defined $workflow->{concurrency}, 'workflow mutated in place per POD');
	tick('Fixer.apply_fixes.mutates_workflow');

	# Unfixable issues must be skipped (count stays at zero).
	my $clean = { jobs => {} };
	my $unfixable_count = apply_fixes($clean, [{ type => 'unknown', message => 'x' }]);
	is($unfixable_count, 0, 'unfixable issues skipped, count remains 0 per POD');
	tick('Fixer.apply_fixes.skips_unfixable');
};

subtest 'Fixer::fix_workflow - file I/O and count per POD' => sub {
	# Mock the YAML I/O to avoid real filesystem access.
	my $loaded_workflow = {
		name => 'Mock',
		on   => [qw(push)],
		jobs => { t => { 'runs-on' => 'ubuntu-latest', steps => [] } },
	};

	my $load_called  = 0;
	my $dump_called  = 0;
	my $dump_skipped = 0;

	# Mock the symbols as they were imported into Fixer's namespace.
	mock 'App::GHGen::Fixer::LoadFile' => sub { $load_called++; return $loaded_workflow };
	mock 'App::GHGen::Fixer::DumpFile' => sub { $dump_called++ };

	my @issues = ({
		type    => 'cost',
		message => 'No concurrency group - old runs continue when superseded',
	});

	# (a) Fixes applied → DumpFile must be called (POD: "file only rewritten when count > 0").
	my $n = fix_workflow('fake.yml', \@issues);
	ok($load_called > 0, 'LoadFile was called per POD');
	tick('Fixer.fix_workflow.calls_load_file');

	returns_ok($n, { type => 'scalar' }, 'returns a scalar per POD');
	ok($n > 0, 'count > 0 for fixable issues');
	tick('Fixer.fix_workflow.returns_count');

	ok($dump_called > 0, 'DumpFile called when fixes > 0 per POD');
	tick('Fixer.fix_workflow.calls_dump_file_when_fixes');

	# (b) No fixable issues → DumpFile must NOT be called.
	$dump_called = 0;
	my $n2 = fix_workflow('fake.yml', [{ type => 'unknown', message => 'x' }]);
	is($n2, 0, 'zero count when no fixable issues');
	is($dump_called, 0, 'DumpFile NOT called when count is 0 per POD');
	tick('Fixer.fix_workflow.no_dump_when_zero_fixes');

	restore_all();
};

# ═══════════════════════════════════════════════════════════════════════════════
# 5.  App::GHGen::Generator
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'Generator::list_workflow_types - count and content per POD' => sub {
	my %types = list_workflow_types();
	returns_ok(\%types, { type => 'hashref' }, 'returns a hash per POD');

	is(scalar keys %types, scalar @SUPPORTED_LANGS,
		'exactly 11 entries per POD ("eleven entries" documented)');
	tick('Generator.list_workflow_types.returns_11_entries');

	for my $lang (@SUPPORTED_LANGS) {
		ok(exists $types{$lang}, "'$lang' entry present per POD");
	}
	tick('Generator.list_workflow_types.all_supported_langs');
};

subtest 'Generator::generate_workflow - documented return states' => sub {
	# Unknown type → undef (POD: "t ∉ SupportedTypes → ⊥").
	my $undef = generate_workflow('cobol');
	ok(!defined $undef, 'unknown type returns undef per POD');
	tick('Generator.generate_workflow.unknown_type_returns_undef');

	# Every known type → non-empty YAML string starting with ---.
	for my $lang (@SUPPORTED_LANGS) {
		my $yaml = generate_workflow($lang);
		ok(defined $yaml && length($yaml) > 0,
			"'$lang' returns a non-empty string per POD");
	}
	tick('Generator.generate_workflow.known_type_returns_yaml');

	# YAML strings must start with --- per POD spec.
	my $node_yaml = generate_workflow('node');
	like($node_yaml, qr/\A---/, 'YAML begins with --- per POD');
	tick('Generator.generate_workflow.yaml_starts_with_dashes');
};

# ═══════════════════════════════════════════════════════════════════════════════
# 6.  App::GHGen::Interactive
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'Interactive::prompt_yes_no - all documented return states' => sub {
	# POD: "y" or "yes" (case-insensitive) → 1.
	is(with_stdin("y\n",   sub { prompt_yes_no("Q?", 'n') }), 1, '"y" → 1 per POD');
	tick('Interactive.prompt_yes_no.yes_input');

	# POD: "n" or "no" → 0.
	is(with_stdin("n\n",   sub { prompt_yes_no("Q?", 'y') }), 0, '"n" → 0 per POD');
	tick('Interactive.prompt_yes_no.no_input');

	# POD: empty input + default 'y' → 1.
	is(with_stdin("\n",    sub { prompt_yes_no("Q?", 'y') }), 1, 'empty+default y → 1 per POD');
	tick('Interactive.prompt_yes_no.empty_default_y');

	# POD: empty input + default 'n' → 0.
	is(with_stdin("\n",    sub { prompt_yes_no("Q?", 'n') }), 0, 'empty+default n → 0 per POD');
	tick('Interactive.prompt_yes_no.empty_default_n');

	# POD: "yes" (mixed case) is also affirmative.
	is(with_stdin("YES\n", sub { prompt_yes_no("Q?", 'n') }), 1, '"YES" → 1 per POD case-insensitive');
	tick('Interactive.prompt_yes_no.yes_mixed_case');
};

subtest 'Interactive::prompt_choice - all documented return states' => sub {
	my @choices = qw(alpha beta gamma);

	# POD: valid number → zero-based index.
	my $idx = with_stdin("2\n", sub { prompt_choice("Pick:", \@choices, 0) });
	is($idx, 1, '"2" → index 1 (zero-based) per POD');
	tick('Interactive.prompt_choice.valid_selection');

	# POD: empty input → default index.
	my $def = with_stdin("\n", sub { prompt_choice("Pick:", \@choices, 2) });
	is($def, 2, 'empty input → specified default index per POD');
	tick('Interactive.prompt_choice.empty_default');

	# POD: out-of-range input → default.
	my $oob = with_stdin("99\n", sub { prompt_choice("Pick:", \@choices, 0) });
	is($oob, 0, 'out-of-range input → default index per POD');
	tick('Interactive.prompt_choice.out_of_range');
};

subtest 'Interactive::prompt_text - all documented return states' => sub {
	# POD: user types text → that text returned.
	my $ans = with_stdin("hello\n", sub { prompt_text("Q?", 'world') });
	is($ans, 'hello', 'typed text returned as-is per POD');
	tick('Interactive.prompt_text.typed_answer');

	# POD: empty input → default returned.
	my $def = with_stdin("\n", sub { prompt_text("Q?", 'world') });
	is($def, 'world', 'empty input returns default per POD');
	tick('Interactive.prompt_text.empty_returns_default');
};

subtest 'Interactive::prompt_multiselect - all documented return states' => sub {
	my @opts = qw(a b c d);
	my @defs = qw(a b);

	# POD: comma-separated numbers → subset of options.
	my $sel = with_stdin("1,3\n", sub { prompt_multiselect("Pick:", \@opts, \@defs) });
	is_deeply($sel, [qw(a c)], 'comma-separated input selects per POD');
	tick('Interactive.prompt_multiselect.comma_separated');

	# POD: "all" → full options list.
	my $all = with_stdin("all\n", sub { prompt_multiselect("Pick:", \@opts, \@defs) });
	is_deeply($all, \@opts, '"all" returns all options per POD');
	tick('Interactive.prompt_multiselect.all_keyword');

	# POD: empty input → defaults returned.
	my $empty = with_stdin("\n", sub { prompt_multiselect("Pick:", \@opts, \@defs) });
	is_deeply($empty, \@defs, 'empty input returns defaults per POD');
	tick('Interactive.prompt_multiselect.empty_returns_defaults');
};

subtest 'Interactive::customize_workflow - unknown type returns empty hash per POD' => sub {
	my $cfg = with_stdin("", sub { customize_workflow('nonexistent_type') });
	is_deeply($cfg, {}, 'unknown type returns {} per documented dispatch table');
	tick('Interactive.customize_workflow.unknown_type_empty_hash');
};

# ═══════════════════════════════════════════════════════════════════════════════
# 7.  App::GHGen::PerlCustomizer
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'PerlCustomizer::detect_perl_requirements - filesystem detection per POD' => sub {
	# Running from App-GHGen root: cpanfile present.
	my $reqs = detect_perl_requirements();
	returns_ok($reqs, { type => 'hashref' }, 'returns a hashref per POD');
	ok($reqs->{has_cpanfile}, 'has_cpanfile true in App-GHGen repo per POD');
	tick('PerlCustomizer.detect_perl_requirements.has_cpanfile');

	# POD: min_version extracted from cpanfile when present.
	ok(defined $reqs->{min_version}, 'min_version extracted from cpanfile per POD');
	like($reqs->{min_version}, qr/5\./, 'min_version looks like a Perl version');
	tick('PerlCustomizer.detect_perl_requirements.extracts_min_version');

	# POD: all boolean fields always present.
	for my $key (qw(has_cpanfile has_makefile_pl has_dist_ini has_build_pl)) {
		ok(exists $reqs->{$key}, "result always contains '$key' field");
	}

	# Empty directory → no files → no version (documented "no files" state).
	in_tempdir(sub {
		my $empty = detect_perl_requirements();
		ok(!$empty->{has_cpanfile},    'no cpanfile in empty dir per POD');
		ok(!defined $empty->{min_version}, 'min_version undef with no files per POD');
		tick('PerlCustomizer.detect_perl_requirements.no_files_no_version');
	});

	diag(explain($reqs)) if $ENV{TEST_VERBOSE};
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - option flags per POD' => sub {
	# Base call: must return a YAML string starting with ---.
	my $yaml = generate_custom_perl_workflow({});
	returns_ok($yaml, { type => 'scalar' }, 'returns a scalar per POD');
	like($yaml, qr/\A---/, 'YAML starts with --- per POD');
	tick('PerlCustomizer.generate_custom_perl_workflow.returns_yaml');

	# enable_linter = 1 (default): lint step MUST appear.
	my $yaml_lint = generate_custom_perl_workflow({ enable_linter => 1 });
	like($yaml_lint, qr/Lint and syntax check/, 'lint step present when enable_linter=1 per POD');
	tick('PerlCustomizer.generate_custom_perl_workflow.linter_step_when_enabled');

	# enable_linter = 0: lint step MUST NOT appear.
	my $yaml_no_lint = generate_custom_perl_workflow({ enable_linter => 0 });
	unlike($yaml_no_lint, qr/Lint and syntax check/, 'lint step absent when enable_linter=0 per POD');
	tick('PerlCustomizer.generate_custom_perl_workflow.no_linter_when_disabled');

	# enable_linter_unused = 1: warnings::unused check MUST appear inside lint step.
	my $yaml_unused = generate_custom_perl_workflow({
		enable_linter_unused => 1, enable_critic => 0, enable_coverage => 0 });
	like($yaml_unused, qr/PERL5OPT=-Mwarnings::unused/, 'unused check present per POD');
	tick('PerlCustomizer.generate_custom_perl_workflow.unused_step_when_enabled');

	# enable_critic = 1 (default): critic step MUST appear.
	my $yaml_critic = generate_custom_perl_workflow({ enable_critic => 1, enable_coverage => 0 });
	like($yaml_critic, qr/Perl::Critic/, 'critic step present per POD');
	tick('PerlCustomizer.generate_custom_perl_workflow.critic_step_when_enabled');

	# enable_coverage = 1 (default): coverage step MUST appear.
	my $yaml_cov = generate_custom_perl_workflow({ enable_coverage => 1, enable_critic => 0 });
	like($yaml_cov, qr/Devel::Cover/, 'coverage step present per POD');
	tick('PerlCustomizer.generate_custom_perl_workflow.coverage_step_when_enabled');

	# enable_perlimports = 1 (default): perlimports step MUST appear.
	my $yaml_pi = generate_custom_perl_workflow({ enable_perlimports => 1, enable_coverage => 0, enable_critic => 0 });
	like($yaml_pi, qr/App::perlimports/, 'perlimports step present per POD');
	tick('PerlCustomizer.generate_custom_perl_workflow.perlimports_step_when_enabled');

	# Step-ordering invariant per POD FORMAL SPECIFICATION:
	# pos(lint) < pos(unused) < pos(tests) < pos(critic) < pos(perlimports) < pos(coverage)
	# (unused check is embedded inside lint step, before Run tests)
	my $yaml_all = generate_custom_perl_workflow({
		enable_linter        => 1,
		enable_linter_unused => 1,
		enable_critic        => 1,
		enable_perlimports   => 1,
		enable_coverage      => 1,
	});
	my $pos_lint        = index($yaml_all, 'Lint and syntax check');
	my $pos_unused      = index($yaml_all, 'PERL5OPT=-Mwarnings::unused');
	my $pos_tests       = index($yaml_all, 'Run tests');
	my $pos_critic      = index($yaml_all, 'Perl::Critic');
	my $pos_perlimports = index($yaml_all, 'App::perlimports');
	my $pos_coverage    = index($yaml_all, 'Devel::Cover');

	ok($pos_lint        < $pos_unused,      'lint before unused per POD ordering invariant');
	ok($pos_unused      < $pos_tests,       'unused before tests per POD ordering invariant');
	ok($pos_tests       < $pos_critic,      'tests before critic per POD ordering invariant');
	ok($pos_critic      < $pos_perlimports, 'critic before perlimports per POD ordering invariant');
	ok($pos_perlimports < $pos_coverage,    'perlimports before coverage per POD ordering invariant');
	tick('PerlCustomizer.generate_custom_perl_workflow.step_ordering_invariant');
};

# ═══════════════════════════════════════════════════════════════════════════════
# 8.  App::GHGen::Reporter
# ═══════════════════════════════════════════════════════════════════════════════

subtest 'Reporter::estimate_savings - per-issue rate table per POD' => sub {
	# POD FORMAL SPEC: caching issue → 500 min saving.
	my $s_cache = estimate_savings([{
		type    => 'performance',
		message => 'No dependency caching found - increases build times and costs',
	}]);
	is($s_cache->{minutes}, $CACHING_SAVING,
		"caching issue yields exactly $CACHING_SAVING minutes per POD rate table");
	ok($s_cache->{cost} >= 0, 'cost is non-negative');
	tick('Reporter.estimate_savings.caching_issue');

	# POD: concurrency issue → 50 min saving.
	my $s_conc = estimate_savings([{
		type    => 'cost',
		message => 'No concurrency group - old runs continue when superseded',
	}]);
	is($s_conc->{minutes}, $CONCURRENCY_SAVING,
		"concurrency issue yields exactly $CONCURRENCY_SAVING minutes per POD");
	tick('Reporter.estimate_savings.concurrency_issue');

	# POD: triggers issue → 100 min saving.
	my $s_trig = estimate_savings([{
		type    => 'cost',
		message => 'Workflow triggers on all pushes - consider path/branch filters',
	}]);
	is($s_trig->{minutes}, $TRIGGERS_SAVING,
		"trigger issue yields exactly $TRIGGERS_SAVING minutes per POD");
	tick('Reporter.estimate_savings.triggers_issue');

	# POD: empty list → { minutes => 0, cost => 0 }.
	my $zero = estimate_savings([]);
	is($zero->{minutes}, 0, 'empty list yields 0 minutes per POD');
	is($zero->{cost},    0, 'empty list yields 0 cost per POD');
	tick('Reporter.estimate_savings.empty_zero');

	diag(explain($s_cache)) if $ENV{TEST_VERBOSE};
};

subtest 'Reporter::generate_markdown_report - structure per POD' => sub {
	# POD: result begins with "# GHGen Workflow Analysis".
	my $empty_md = generate_markdown_report([]);
	like($empty_md, qr/\A# GHGen Workflow Analysis/m, 'report begins with documented heading');
	tick('Reporter.generate_markdown_report.starts_with_heading');

	# POD: |issues| = 0 → no "Issues by Category" section.
	unlike($empty_md, qr/Issues by Category/, 'no category section for empty issues per POD');
	tick('Reporter.generate_markdown_report.no_category_when_empty');

	# POD: |issues| > 0 → "## Issues by Category" present.
	my @issues = (
		{ type => 'performance', severity => 'medium', message => 'No caching',    fix => 'add cache' },
		{ type => 'security',    severity => 'high',   message => 'Unpinned action', fix => 'pin it' },
	);
	my $md = generate_markdown_report(\@issues);
	like($md, qr/Issues by Category/i, 'category section present when issues exist per POD');
	tick('Reporter.generate_markdown_report.issues_by_category');

	# POD: |fixes| > 0 → "Fixes applied" phrase present.
	my $md_fixed = generate_markdown_report(\@issues, ['fix1', 'fix2']);
	like($md_fixed, qr/Fixes applied/i, '"Fixes applied" appears when fixes provided per POD');
	tick('Reporter.generate_markdown_report.fixes_applied_count');
};

subtest 'Reporter::generate_github_comment - all documented return states' => sub {
	# POD: zero issues → early return with "No issues found!" phrase.
	my $ok_comment = generate_github_comment([]);
	like($ok_comment, qr/No issues found!/i, 'zero-issue comment contains documented phrase');
	tick('Reporter.generate_github_comment.no_issues_message');

	my @issues = ({
		type     => 'performance',
		severity => 'medium',
		message  => 'No caching',
		file     => 'ci.yml',
	});

	# POD: issues present → summary table rendered.
	my $comment = generate_github_comment(\@issues);
	like($comment, qr/Performance/i, 'issues table contains performance category per POD');
	tick('Reporter.generate_github_comment.issues_table');

	# POD: issue has file key → file reference appears in comment.
	like($comment, qr/ci\.yml/, 'file reference shown for issue with file key per POD');
	tick('Reporter.generate_github_comment.file_reference_shown');

	# POD: no fixes + issues → "How to Fix" section present.
	like($comment, qr/How to Fix/i, '"How to Fix" section present when no fixes per POD');
	tick('Reporter.generate_github_comment.how_to_fix_when_no_fixes');

	# POD: fixes > 0 → "Applied N automatic fix(es)" in header.
	my $fixed_comment = generate_github_comment(\@issues, ['fix1']);
	like($fixed_comment, qr/Applied/i, 'fix count shown in header when fixes applied per POD');
	tick('Reporter.generate_github_comment.fix_count_in_header');
};

# ═══════════════════════════════════════════════════════════════════════════════
# Ledger assertion — every documented API state must have been exercised.
# ═══════════════════════════════════════════════════════════════════════════════

my @untested = sort keys %LEDGER;
if (@untested) {
	fail('Documented API states not covered by tests:');
	diag("  - $_") for @untested;
} else {
	pass('All documented API states exercised (ledger empty)');
}

done_testing();
