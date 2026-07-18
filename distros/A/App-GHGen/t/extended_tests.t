#!/usr/bin/env perl

use v5.36;
use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock spy);
use File::Temp qw(tempdir);
use Path::Tiny;
use Cwd qw(getcwd);
use Readonly;
use lib "$ENV{HOME}/src/njh/Test-Returns/lib";
use Test::Returns;

use App::GHGen::Analyzer       qw(analyze_workflow find_workflows get_cache_suggestion);
use App::GHGen::CostEstimator  qw(estimate_current_usage estimate_workflow_cost estimate_savings);
use App::GHGen::Detector       qw(detect_project_type get_project_indicators);
use App::GHGen::Fixer          qw(apply_fixes can_auto_fix fix_workflow);
use App::GHGen::Generator      qw(generate_workflow list_workflow_types);
use App::GHGen::Interactive    qw(prompt_yes_no prompt_choice prompt_multiselect prompt_text customize_workflow);
use App::GHGen::PerlCustomizer qw(detect_perl_requirements generate_custom_perl_workflow);
use App::GHGen::Reporter       qw(generate_markdown_report generate_github_comment);

# ─── Constants ────────────────────────────────────────────────────────────────
Readonly my %ISSUE_TYPE => (
	PERF  => 'performance',
	SEC   => 'security',
	COST  => 'cost',
	MAINT => 'maintenance',
);

Readonly my %SEVERITY => (
	HIGH => 'high',
	MED  => 'medium',
	LOW  => 'low',
);

Readonly my $CACHE_ACTION  => 'actions/cache';
Readonly my $FREE_TIER_MIN => 2000;
Readonly my $COST_PER_MIN  => 0.008;

# ─── Helpers ──────────────────────────────────────────────────────────────────

# Run a sub with CWD temporarily changed to $dir, then restore CWD.
sub with_dir($dir, $sub) {
	my $orig = getcwd();
	chdir $dir or die "Cannot chdir to $dir: $!";
	my @result = eval { $sub->() };
	my $err = $@;
	chdir $orig;
	die $err if $err;
	return wantarray ? @result : $result[0];
}

# Feed a sequence of lines to STDIN for Interactive prompts.
# Uses local *STDIN to avoid fd-dup issues when the harness has already
# closed or redirected the real STDIN.
sub with_stdin($lines, $sub) {
	my $input = join("\n", @$lines) . "\n";
	open my $fake, '<', \$input or die "Cannot create in-memory STDIN: $!";
	local *STDIN = *$fake;
	return $sub->();
}

# Build a minimal workflow hash with optional fields.
sub make_workflow(%args) {
	my $wf = {
		jobs => {
			build => {
				'runs-on' => 'ubuntu-latest',
				steps     => [],
				%{ $args{job_extra} // {} },
			},
		},
		%{ $args{wf_extra} // {} },
	};
	return $wf;
}

# =============================================================================
# 1.  App::GHGen::Analyzer  — uncovered branches
# =============================================================================

subtest 'Analyzer::has_broad_triggers - scalar on (not HASH or ARRAY) is not broad' => sub {
	# LCSAJ: branch where $on is a plain string (not 'push'), not ARRAY, not HASH.
	# POD FORMAL SPEC: only HASH{push} with no filters OR ARRAY containing 'push' → broad.
	my $wf = { on => 'workflow_dispatch', jobs => {} };
	my @issues = analyze_workflow($wf, 'ci.yml');
	my @trigger_issues = grep { $_->{type} eq $ISSUE_TYPE{COST} && $_->{message} =~ /triggers/ } @issues;
	is(scalar @trigger_issues, 0, 'scalar on (workflow_dispatch) is not flagged as broad trigger');
};

subtest 'Analyzer::has_broad_triggers - ARRAY on without push is not broad' => sub {
	# LCSAJ: ARRAY trigger that contains only non-push events.
	my $wf = { on => ['pull_request', 'workflow_dispatch'], jobs => {} };
	my @issues = analyze_workflow($wf, 'ci.yml');
	my @trigger_issues = grep { $_->{type} eq $ISSUE_TYPE{COST} && $_->{message} =~ /triggers/ } @issues;
	is(scalar @trigger_issues, 0, 'ARRAY on without "push" is not flagged as broad trigger');
};

subtest 'Analyzer::has_broad_triggers - HASH on with push having branch filter is not broad' => sub {
	# LCSAJ: HASH trigger where push has a branches key → not broad.
	my $wf = {
		on   => { push => { branches => ['main'] } },
		jobs => { build => { 'runs-on' => 'ubuntu-latest', steps => [] } },
	};
	my @issues = analyze_workflow($wf, 'ci.yml');
	my @trigger_issues = grep { $_->{type} eq $ISSUE_TYPE{COST} && $_->{message} =~ /triggers/ } @issues;
	is(scalar @trigger_issues, 0, 'push with branches filter is not flagged as broad');
};

subtest 'Analyzer::analyze_workflow - job WITH timeout-minutes produces no timeout issue' => sub {
	# Negative test: when timeout is present the POD says no issue for that job.
	my $wf = {
		jobs => {
			build => {
				'runs-on'        => 'ubuntu-latest',
				'timeout-minutes' => 30,
				steps            => [{ uses => "$CACHE_ACTION\@v5" }],
			},
		},
		concurrency => { group => 'x', 'cancel-in-progress' => 'true' },
	};
	my @issues = analyze_workflow($wf, 'ci.yml');
	my @timeout_issues = grep { $_->{message} =~ /timeout-minutes/ } @issues;
	is(scalar @timeout_issues, 0, 'no timeout issue when job has timeout-minutes');
};

subtest 'Analyzer::analyze_workflow - multiple jobs, only missing-timeout jobs flagged' => sub {
	# Ensures the loop over jobs correctly flags only the jobs that lack timeout.
	my $wf = {
		jobs => {
			build  => { 'runs-on' => 'ubuntu-latest', 'timeout-minutes' => 10, steps => [] },
			deploy => { 'runs-on' => 'ubuntu-latest', steps => [] },
		},
		concurrency => { group => 'x', 'cancel-in-progress' => 'true' },
	};
	my @issues = analyze_workflow($wf, 'ci.yml');
	my @timeout_issues = grep { $_->{message} =~ /timeout-minutes/ } @issues;
	is(scalar @timeout_issues, 1,      'exactly one timeout issue for the job missing it');
	like($timeout_issues[0]{message}, qr/deploy/, 'issue names the "deploy" job');
};

subtest 'Analyzer::get_cache_suggestion - bundler ecosystem' => sub {
	# POD: ecosystem = bundler → result contains vendor/bundle path.
	my $wf = {
		jobs => {
			build => {
				steps => [{ run => 'bundle install' }],
			},
		},
	};
	my $suggestion = get_cache_suggestion($wf);
	like($suggestion, qr/vendor\/bundle/, 'bundler suggestion contains vendor/bundle path');
	like($suggestion, qr/Gemfile\.lock/,  'bundler suggestion uses Gemfile.lock as key');
};

subtest 'Analyzer::get_cache_suggestion - unknown ecosystem returns guidance prose' => sub {
	# POD: ecosystem = unknown → generic guidance message.
	my $wf = { jobs => { build => { steps => [{ run => 'echo hello' }] } } };
	my $suggestion = get_cache_suggestion($wf);
	like($suggestion, qr/dependency manager/i, 'unknown ecosystem returns generic guidance');
	unlike($suggestion, qr/actions\/cache/,    'generic guidance does not include a cache action snippet');
};

# DEAD CODE NOTICE:
# Analyzer::has_deployment_steps() is defined in Analyzer.pm but is NOT
# exported in @EXPORT_OK and is NOT called by analyze_workflow(). It is
# unreachable through any public interface.  Flag for review:
# sub has_deployment_steps { ... }  # lines 492-505
# Recommend: either export it, call it from analyze_workflow, or remove it.

subtest 'Analyzer::has_deployment_steps (internal) - deploy action detected' => sub {
	# Call through fully-qualified name to verify the function exists and works,
	# even though it is not reachable via any exported path.
	my $wf_deploy = {
		jobs => {
			deploy => {
				steps => [{ uses => 'my-org/deploy-action@v1' }],
			},
		},
	};
	my $wf_clean = { jobs => { build => { steps => [{ run => 'echo ok' }] } } };
	ok(App::GHGen::Analyzer::has_deployment_steps($wf_deploy), 'deploy action detected');
	ok(!App::GHGen::Analyzer::has_deployment_steps($wf_clean),  'no deploy steps → false');

	diag('NOTE: has_deployment_steps is dead code — not called from analyze_workflow or exported')
		if $ENV{TEST_VERBOSE};
};

# =============================================================================
# 2.  App::GHGen::CostEstimator — uncovered branches
# =============================================================================

subtest 'CostEstimator::estimate_trigger_frequency - paths filter reduces by 70%' => sub {
	# FORMAL SPEC: paths filter → base × 0.3 (70% reduction).
	my $freq = App::GHGen::CostEstimator::estimate_trigger_frequency(
		'push', { paths => ['src/**'] }
	);
	# push base is 100; 100 × 0.3 = 30 → int(30) = 30
	is($freq, 30, 'paths filter reduces push frequency to 30');
};

subtest 'CostEstimator::estimate_trigger_frequency - branches filter reduces by 40%' => sub {
	# FORMAL SPEC: branches filter → base × 0.6 (40% reduction).
	my $freq = App::GHGen::CostEstimator::estimate_trigger_frequency(
		'push', { branches => ['main'] }
	);
	# push base is 100; 100 × 0.6 = 60 → int(60) = 60
	is($freq, 60, 'branches filter reduces push frequency to 60');
};

subtest 'CostEstimator::estimate_trigger_frequency - both branches+paths stacks reductions' => sub {
	# Both filters applied: 100 × 0.6 × 0.3 = 18.
	my $freq = App::GHGen::CostEstimator::estimate_trigger_frequency(
		'push', { branches => ['main'], paths => ['src/**'] }
	);
	is($freq, 18, 'branches+paths stacks to 18');
};

subtest 'CostEstimator::estimate_trigger_frequency - unknown trigger defaults to 20' => sub {
	# FORMAL SPEC: unknown trigger → base 20 (from %frequencies fallback).
	my $freq = App::GHGen::CostEstimator::estimate_trigger_frequency('deployment');
	is($freq, 20, 'unknown trigger defaults to 20 runs/month');
};

subtest 'CostEstimator::estimate_runs_per_month - scalar on string' => sub {
	# Branch: $on is a plain string (not ARRAY or HASH).
	my $wf = { on => 'push', jobs => {} };
	my $runs = App::GHGen::CostEstimator::estimate_runs_per_month($wf);
	ok($runs > 0, 'scalar on returns a positive run estimate');
};

subtest 'CostEstimator::estimate_runs_per_month - no on key returns 50' => sub {
	# No trigger → default estimate of 50.
	my $wf = { jobs => {} };
	my $runs = App::GHGen::CostEstimator::estimate_runs_per_month($wf);
	is($runs, 50, 'missing on key returns default of 50 runs/month');
};

subtest 'CostEstimator::estimate_runs_per_month - trigger sum of zero falls back to 50' => sub {
	# Edge: ARRAY trigger with no recognised entries → sum=0 → fallback 50.
	my $wf = { on => [], jobs => {} };
	my $runs = App::GHGen::CostEstimator::estimate_runs_per_month($wf);
	is($runs, 50, 'zero trigger sum falls back to 50');
};

subtest 'CostEstimator::estimate_duration - sequential jobs (needs dependency)' => sub {
	# LCSAJ: $has_dependencies=1 → durations are summed, not max'd.
	my $wf = {
		jobs => {
			build  => { steps => [{ uses => 'actions/checkout@v7' }] },
			deploy => { needs => 'build', steps => [{ run => 'npm test' }] },
		},
	};
	my $dur = App::GHGen::CostEstimator::estimate_duration($wf);
	# build: checkout=0.5 → job=0.5; deploy: npm test=2 → job=2; sum=2.5 → int=2
	# But estimate_job_duration returns max(duration, 3) when no steps... actually
	# returns $duration || 3. 0.5 is truthy so checkout-only = 0.5, but that's < 3?
	# Actually: checkout gives duration += 0.5, so $duration = 0.5, return 0.5 (truthy).
	# deploy: npm test → $duration += 2, return 2.
	# sequential: total = 0.5 + 2 = 2.5, matrix_factor=1, int(2.5)=2, || 5 → 2.
	# Actually int(2.5 * 1) = 2, which is truthy, so result = 2.
	ok($dur > 0, 'sequential jobs produce positive duration estimate');
	diag("Sequential duration: $dur") if $ENV{TEST_VERBOSE};
};

subtest 'CostEstimator::estimate_job_duration - setup-go action' => sub {
	# Covers the setup-(node|python|go|ruby) branch with go.
	my $job = { steps => [{ uses => 'actions/setup-go@v5' }] };
	my $dur = App::GHGen::CostEstimator::estimate_job_duration($job);
	# setup-go hits elsif ($uses =~ /setup-(node|python|go|ruby)/) → += 1; return 1.
	is($dur, 1, 'setup-go contributes 1 minute');
};

subtest 'CostEstimator::estimate_job_duration - pip install command' => sub {
	my $job = { steps => [{ run => 'pip install -r requirements.txt' }] };
	my $dur = App::GHGen::CostEstimator::estimate_job_duration($job);
	is($dur, 1.5, 'pip install contributes 1.5 minutes');
};

subtest 'CostEstimator::estimate_job_duration - cargo build command' => sub {
	my $job = { steps => [{ run => 'cargo build --release' }] };
	my $dur = App::GHGen::CostEstimator::estimate_job_duration($job);
	is($dur, 5, 'cargo build contributes 5 minutes');
};

subtest 'CostEstimator::estimate_job_duration - go test command' => sub {
	my $job = { steps => [{ run => 'go test ./...' }] };
	my $dur = App::GHGen::CostEstimator::estimate_job_duration($job);
	is($dur, 2, 'go test contributes 2 minutes');
};

subtest 'CostEstimator::estimate_job_duration - generic run command' => sub {
	# The else branch: unknown run command → += 0.5.
	my $job = { steps => [{ run => 'echo hello world' }] };
	my $dur = App::GHGen::CostEstimator::estimate_job_duration($job);
	is($dur, 0.5, 'generic run command contributes 0.5 minutes');
};

subtest 'CostEstimator::estimate_job_duration - no steps returns default 3' => sub {
	# POD: no steps → default 3 minutes.
	my $job = {};
	my $dur = App::GHGen::CostEstimator::estimate_job_duration($job);
	is($dur, 3, 'job with no steps returns 3-minute default');
};

subtest 'CostEstimator::estimate_matrix_factor - include/exclude keys are skipped' => sub {
	# LCSAJ: include/exclude keys in matrix must not multiply the size.
	my $wf = {
		jobs => {
			build => {
				strategy => {
					matrix => {
						os      => ['ubuntu-latest', 'macos-latest'],
						include => [{ os => 'windows-latest', extra => 'x' }],
						exclude => [{ os => 'macos-latest' }],
					},
				},
				steps => [],
			},
		},
	};
	my $factor = App::GHGen::CostEstimator::estimate_matrix_factor($wf);
	# Only 'os' key counts → size=2; include+exclude skipped.
	is($factor, 2, 'include/exclude keys excluded from matrix size calculation');
};

subtest 'CostEstimator::estimate_matrix_factor - multiple jobs takes maximum' => sub {
	# LCSAJ: two jobs with different matrix sizes; result = max.
	my $wf = {
		jobs => {
			small => { strategy => { matrix => { perl => ['5.36', '5.38'] } },     steps => [] },
			large => { strategy => { matrix => { os   => ['a', 'b', 'c', 'd'] } }, steps => [] },
		},
	};
	my $factor = App::GHGen::CostEstimator::estimate_matrix_factor($wf);
	is($factor, 4, 'maximum matrix size across all jobs is returned');
};

subtest 'CostEstimator::estimate_current_usage - within free tier yields zero cost' => sub {
	# FORMAL SPEC: total_minutes ≤ FREE_TIER → billable=0, monthly_cost=0.
	my $tmp = tempdir(CLEANUP => 1);
	path("$tmp/tiny.yml")->spew_utf8(<<'YAML');
---
name: Tiny
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
YAML
	my @wfs   = map { path($_) } glob("$tmp/*.yml");
	my $usage = estimate_current_usage(\@wfs);
	cmp_ok($usage->{total_minutes},    '<=', $FREE_TIER_MIN, 'tiny workflow stays within free tier');
	is($usage->{billable_minutes},  0,  'no billable minutes within free tier');
	is($usage->{monthly_cost},      0,  'zero cost within free tier');
};

subtest 'CostEstimator::estimate_savings - concurrency saving proportional to actual usage' => sub {
	# FORMAL SPEC: cost.concurrency with current_usage → saving = total_minutes × 0.15.
	my $tmp = tempdir(CLEANUP => 1);
	# Write a large-looking workflow so estimate_current_usage returns many minutes.
	path("$tmp/big.yml")->spew_utf8(<<'YAML');
---
name: Big
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        perl:
          - '5.36'
          - '5.38'
          - '5.40'
    steps:
      - uses: actions/checkout@v7
      - run: prove -lr t/
YAML
	my @wfs  = map { path($_) } glob("$tmp/*.yml");
	my @issues = (
		{ type => $ISSUE_TYPE{COST}, message => 'No concurrency group' },
	);
	my $savings = estimate_savings(\@issues, \@wfs);
	ok($savings->{minutes} > 0,    'concurrency saving is non-zero with actual usage');
	ok($savings->{percentage} > 0, 'percentage is positive');
	like($savings->{cost},    qr/^\d+\.\d{2}$/, 'cost formatted as NN.NN');
	is(scalar @{$savings->{details}}, 1, 'one detail entry for concurrency');
};

subtest 'CostEstimator::estimate_savings - triggers saving proportional to actual usage' => sub {
	# FORMAL SPEC: cost.triggers with current_usage → saving = total_minutes × 0.25.
	my $tmp = tempdir(CLEANUP => 1);
	path("$tmp/wf.yml")->spew_utf8(<<'YAML');
---
name: WF
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
YAML
	my @wfs  = map { path($_) } glob("$tmp/*.yml");
	my @issues = (
		{ type => $ISSUE_TYPE{COST}, message => 'triggers on all pushes' },
	);
	my $savings = estimate_savings(\@issues, \@wfs);
	ok($savings->{minutes} > 0, 'triggers saving is non-zero with actual usage');
	my @trig_detail = grep { $_->{description} =~ /trigger/i } @{$savings->{details}};
	ok(@trig_detail, 'trigger detail entry present');
};

# =============================================================================
# 3.  App::GHGen::Detector — per-language _detect_* in isolated temp dirs
# =============================================================================

subtest 'Detector::_detect_node - package.json gives high score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('package.json')->spew_utf8('{"name":"test"}');
		my $score = App::GHGen::Detector::_detect_node();
		cmp_ok($score, '>=', 15, 'package.json alone yields score >= 15');
	});
};

subtest 'Detector::_detect_node - yarn.lock adds to score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('package.json')->spew_utf8('{}');
		path('yarn.lock')->spew_utf8('');
		my $score = App::GHGen::Detector::_detect_node();
		cmp_ok($score, '>=', 23, 'package.json + yarn.lock yields score >= 23');
	});
};

subtest 'Detector::_detect_python - requirements.txt gives high score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('requirements.txt')->spew_utf8("requests\n");
		my $score = App::GHGen::Detector::_detect_python();
		cmp_ok($score, '>=', 12, 'requirements.txt alone yields score >= 12');
	});
};

subtest 'Detector::_detect_python - pyproject.toml detected' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('pyproject.toml')->spew_utf8("[project]\n");
		my $score = App::GHGen::Detector::_detect_python();
		cmp_ok($score, '>=', 12, 'pyproject.toml alone yields score >= 12');
	});
};

subtest 'Detector::_detect_rust - Cargo.toml gives high score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('Cargo.toml')->spew_utf8("[package]\nname = \"test\"\n");
		my $score = App::GHGen::Detector::_detect_rust();
		cmp_ok($score, '>=', 15, 'Cargo.toml alone yields score >= 15');
	});
};

subtest 'Detector::_detect_go - go.mod gives high score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('go.mod')->spew_utf8("module example.com/m\n");
		my $score = App::GHGen::Detector::_detect_go();
		cmp_ok($score, '>=', 15, 'go.mod alone yields score >= 15');
	});
};

subtest 'Detector::_detect_go - multiple .go files add extra score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('go.mod')->spew_utf8("module m\n");
		path("$_.go")->spew_utf8("package main\n") for qw(main a b c d);
		my $score = App::GHGen::Detector::_detect_go();
		# go.mod=15 + go.sum absent + main.go present +3 files + >3 files bonus
		cmp_ok($score, '>=', 19, '>3 .go files adds extra score');
	});
};

subtest 'Detector::_detect_ruby - Gemfile gives high score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('Gemfile')->spew_utf8("source 'https://rubygems.org'\n");
		my $score = App::GHGen::Detector::_detect_ruby();
		cmp_ok($score, '>=', 15, 'Gemfile alone yields score >= 15');
	});
};

subtest 'Detector::_detect_docker - Dockerfile gives high score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('Dockerfile')->spew_utf8("FROM scratch\n");
		my $score = App::GHGen::Detector::_detect_docker();
		cmp_ok($score, '>=', 12, 'Dockerfile alone yields score >= 12');
	});
};

subtest 'Detector::_detect_docker - docker-compose.yaml (not .yml) detected' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('docker-compose.yaml')->spew_utf8("version: '3'\n");
		my $score = App::GHGen::Detector::_detect_docker();
		cmp_ok($score, '>=', 8, 'docker-compose.yaml detected');
	});
};

subtest 'Detector::_detect_php - composer.json gives high score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('composer.json')->spew_utf8("{}");
		my $score = App::GHGen::Detector::_detect_php();
		cmp_ok($score, '>=', 15, 'composer.json alone yields score >= 15');
	});
};

subtest 'Detector::_detect_java - pom.xml gives high score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('pom.xml')->spew_utf8('<project/>');
		my $score = App::GHGen::Detector::_detect_java();
		cmp_ok($score, '>=', 15, 'pom.xml alone yields score >= 15');
	});
};

subtest 'Detector::_detect_java - build.gradle detected' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('build.gradle')->spew_utf8("apply plugin: 'java'\n");
		my $score = App::GHGen::Detector::_detect_java();
		cmp_ok($score, '>=', 15, 'build.gradle alone yields score >= 15');
	});
};

subtest 'Detector::_detect_cpp - CMakeLists.txt gives high score' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('CMakeLists.txt')->spew_utf8("cmake_minimum_required(VERSION 3.10)\n");
		my $score = App::GHGen::Detector::_detect_cpp();
		cmp_ok($score, '>=', 12, 'CMakeLists.txt alone yields score >= 12');
	});
};

subtest 'Detector::get_project_indicators - unknown type returns undef' => sub {
	# POD FORMAL SPEC: t given ∧ t ∉ KnownTypes → ⊥ (undef).
	my $result = get_project_indicators('cobol');
	is($result, undef, 'unknown type returns undef');
};

subtest 'Detector::detect_project_type - list context returns descending-score array' => sub {
	# POD FORMAL SPEC: list context → ranked by descending score.
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		# Perl project: cpanfile + Makefile.PL
		path('cpanfile')->spew_utf8("requires 'strict';\n");
		path('Makefile.PL')->spew_utf8("use ExtUtils::MakeMaker;\n");
		my @results = detect_project_type();
		ok(@results >= 1, 'list context returns at least one detection');
		is($results[0]->{type}, 'perl', 'top-ranked type is perl');
		for my $i (1 .. $#results) {
			cmp_ok($results[$i]->{score}, '<=', $results[$i-1]->{score},
				"result[$i] score <= result[" . ($i-1) . "] score (descending)");
		}
	});
};

# =============================================================================
# 4.  App::GHGen::Fixer — uncovered helpers
# =============================================================================

subtest 'Fixer::detect_and_create_cache_step - Go (go build) returns correct cache step' => sub {
	# Covers the Go branch in detect_and_create_cache_step.
	my $steps = [{ run => 'go build ./...' }];
	my $step = App::GHGen::Fixer::detect_and_create_cache_step($steps);
	ok(defined $step,                         'cache step created for Go project');
	like($step->{with}{path}, qr|go/pkg/mod|, 'Go cache uses ~/go/pkg/mod path');
	like($step->{with}{key},  qr/go\.sum/,    'Go cache key hashes go.sum');
};

subtest 'Fixer::detect_and_create_cache_step - setup-go action triggers Go cache' => sub {
	my $steps = [{ uses => 'actions/setup-go@v5' }];
	my $step = App::GHGen::Fixer::detect_and_create_cache_step($steps);
	ok(defined $step, 'setup-go action triggers Go cache creation');
	like($step->{with}{path}, qr|go/pkg/mod|, 'correct path for setup-go');
};

subtest 'Fixer::detect_and_create_cache_step - no matching steps returns undef' => sub {
	# Branch: none of the known patterns → return undef.
	my $steps = [{ run => 'echo hello' }];
	my $step = App::GHGen::Fixer::detect_and_create_cache_step($steps);
	is($step, undef, 'unrecognised steps produce no cache step');
};

subtest 'Fixer::add_caching - job already with cache step is skipped' => sub {
	# LCSAJ: $has_cache is true → next → $modified stays 0.
	my $wf = {
		jobs => {
			build => {
				steps => [
					{ uses => "$CACHE_ACTION\@v5" },
					{ run  => 'npm ci'             },
				],
			},
		},
	};
	my $result = App::GHGen::Fixer::add_caching($wf);
	is($result, 0, 'job already with cache skipped; count stays 0');
};

subtest 'Fixer::add_trigger_filters - HASH on with push as bare string (truthy scalar)' => sub {
	# Branch: ref $on->{push} eq '' with a truthy value → expand push to branches filter.
	# Note: the implementation tests $on->{push} && ref $on->{push} eq '', so the
	# scalar must be truthy (empty string is falsy and falls through).
	my $wf = { on => { push => '*' }, jobs => {} };
	my $n = App::GHGen::Fixer::add_trigger_filters($wf);
	is($n, 1, 'truthy scalar push value gets expanded');
	is(ref $wf->{on}{push}, 'HASH', 'push is now a HASH with filters');
	is_deeply($wf->{on}{push}{branches}, ['main', 'master'], 'default branches added');
};

subtest 'Fixer::add_trigger_filters - no on key returns 0' => sub {
	my $wf = { jobs => {} };
	my $n = App::GHGen::Fixer::add_trigger_filters($wf);
	is($n, 0, 'missing on key returns 0 modifications');
};

subtest 'Fixer::update_runners - windows-2016 upgraded to windows-latest' => sub {
	my $wf = {
		jobs => {
			build => { 'runs-on' => 'windows-2016', steps => [] },
		},
	};
	my $n = App::GHGen::Fixer::update_runners($wf);
	is($n, 1,                'one runner updated');
	is($wf->{jobs}{build}{'runs-on'}, 'windows-latest', 'windows-2016 → windows-latest');
};

subtest 'Fixer::update_runners - runner not in update table is unchanged' => sub {
	my $wf = { jobs => { build => { 'runs-on' => 'ubuntu-latest', steps => [] } } };
	my $n = App::GHGen::Fixer::update_runners($wf);
	is($n, 0, 'current runner string produces no modifications');
};

subtest 'Fixer::get_latest_version - unknown action returns fallback v4' => sub {
	# POD: unknown action → 'v4' fallback.
	my $ver = App::GHGen::Fixer::get_latest_version('some/unknown-action');
	is($ver, 'v4', 'unknown action returns v4 fallback');
};

subtest 'Fixer::apply_fixes - security/permissions branch fires add_permissions' => sub {
	# Route to add_permissions via apply_fixes.
	my $wf     = { jobs => { build => { steps => [] } } };
	my @issues = ({ type => $ISSUE_TYPE{SEC}, message => 'Missing permissions block' });
	my $n      = apply_fixes($wf, \@issues);
	is($n, 1,                      'one fix applied');
	ok(exists $wf->{permissions},  'permissions key inserted');
	is($wf->{permissions}{contents}, 'read', 'contents: read set');
};

subtest 'Fixer::apply_fixes - maintenance/outdated action branch fires update_actions' => sub {
	my $wf = {
		jobs => {
			build => {
				steps => [{ uses => 'actions/cache@v3' }],
			},
		},
	};
	my @issues = ({ type => $ISSUE_TYPE{MAINT}, message => '1 outdated action(s)' });
	my $n = apply_fixes($wf, \@issues);
	is($n, 1, 'one action updated');
	is($wf->{jobs}{build}{steps}[0]{uses}, 'actions/cache@v5', 'cache upgraded to v5');
};

subtest 'Fixer::apply_fixes - performance/missing timeout fires add_missing_timeout' => sub {
	my $wf = {
		jobs => {
			build => { 'runs-on' => 'ubuntu-latest', steps => [] },
		},
	};
	my @issues = ({
		type    => $ISSUE_TYPE{PERF},
		message => "Job 'build' is missing timeout-minutes",
	});
	my $n = apply_fixes($wf, \@issues);
	is($n, 1,  'timeout fix applied');
	is($wf->{jobs}{build}{'timeout-minutes'}, 30, 'default 30-minute timeout inserted');
};

subtest 'Fixer::apply_fixes - unfixable issue type is skipped silently' => sub {
	# can_auto_fix returns 0 for unknown types; apply_fixes skips them.
	my $wf     = { jobs => {} };
	my @issues = ({ type => 'unknown_type', message => 'something weird' });
	my $n      = apply_fixes($wf, \@issues);
	is($n, 0, 'unfixable issue produces zero fixes');
};

# =============================================================================
# 5.  App::GHGen::Generator — content of non-Perl workflow generators
# =============================================================================

subtest 'Generator::generate_workflow - node workflow has expected structure' => sub {
	my $yaml = generate_workflow('node');
	ok(defined $yaml,                      'node workflow generated');
	like($yaml, qr/^---/m,                 'starts with YAML header');
	like($yaml, qr/Node\.js CI/,           'contains workflow name');
	like($yaml, qr/node-version/,          'uses node-version matrix');
	like($yaml, qr/actions\/setup-node/,   'includes setup-node action');
	like($yaml, qr/npm/,                   'includes npm commands');
};

subtest 'Generator::generate_workflow - python workflow has expected structure' => sub {
	my $yaml = generate_workflow('python');
	like($yaml, qr/Python CI/,             'python workflow named correctly');
	like($yaml, qr/python-version/,        'uses python-version matrix');
	like($yaml, qr/setup-python/,          'includes setup-python action');
	like($yaml, qr/pytest/,               'includes pytest command');
};

subtest 'Generator::generate_workflow - rust workflow has expected structure' => sub {
	my $yaml = generate_workflow('rust');
	like($yaml, qr/Rust CI/,              'rust workflow named correctly');
	like($yaml, qr/cargo/,               'includes cargo commands');
	like($yaml, qr/clippy/,              'includes clippy linting');
};

subtest 'Generator::generate_workflow - go workflow has expected structure' => sub {
	my $yaml = generate_workflow('go');
	like($yaml, qr/Go CI/,               'go workflow named correctly');
	like($yaml, qr/setup-go/,            'includes setup-go action');
	like($yaml, qr/go test/,             'includes go test command');
};

subtest 'Generator::generate_workflow - ruby workflow has expected structure' => sub {
	my $yaml = generate_workflow('ruby');
	like($yaml, qr/Ruby CI/,             'ruby workflow named correctly');
	like($yaml, qr/ruby-version/,        'uses ruby-version matrix');
	like($yaml, qr/bundle exec/,         'includes bundler execution');
};

subtest 'Generator::generate_workflow - java workflow has expected structure' => sub {
	my $yaml = generate_workflow('java');
	like($yaml, qr/Java CI/,             'java workflow named correctly');
	like($yaml, qr/java-version/,        'uses java-version matrix');
	like($yaml, qr/actions\/setup-java/, 'includes setup-java action');
	like($yaml, qr/mvn/,                 'includes Maven commands');
};

subtest 'Generator::generate_workflow - cpp workflow has expected structure' => sub {
	my $yaml = generate_workflow('cpp');
	like($yaml, qr/C\+\+ CI/,            'cpp workflow named correctly');
	like($yaml, qr/cmake/i,              'includes cmake commands');
	like($yaml, qr/ctest/i,              'includes ctest invocation');
};

subtest 'Generator::generate_workflow - php workflow has expected structure' => sub {
	my $yaml = generate_workflow('php');
	like($yaml, qr/PHP CI/,              'php workflow named correctly');
	like($yaml, qr/php-version/,         'uses php-version matrix');
	like($yaml, qr/composer/,            'includes composer');
	like($yaml, qr/phpunit/i,            'includes phpunit');
};

subtest 'Generator::generate_workflow - docker workflow has expected structure' => sub {
	my $yaml = generate_workflow('docker');
	like($yaml, qr/Docker Build/,        'docker workflow named correctly');
	like($yaml, qr/build-push-action/,   'includes build-push action');
	like($yaml, qr/login-action/,        'includes docker login');
};

subtest 'Generator::generate_workflow - static workflow has expected structure' => sub {
	my $yaml = generate_workflow('static');
	like($yaml, qr/Deploy Static Site/,  'static workflow named correctly');
	like($yaml, qr/deploy-pages/,        'includes deploy-pages action');
	like($yaml, qr/upload-pages-artifact/, 'includes artifact upload');
};

# =============================================================================
# 6.  App::GHGen::Interactive — _customize_* via mocked STDIN
# =============================================================================

subtest 'Interactive::customize_workflow - perl: collects all expected keys' => sub {
	# Feed answers for all prompts in _customize_perl.
	# Sequence: perl_versions, os, linter, unused, critic, coverage, branches.
	my @answers = (
		'1,2,3',         # perl_versions: 5.40,5.38,5.36
		'1,2',           # os: ubuntu+macos
		'y',             # enable_linter
		'n',             # enable_linter_unused
		'y',             # enable_critic
		'y',             # enable_coverage
		'main',          # branches
	);
	my $config = with_stdin(\@answers, sub { customize_workflow('perl') });
	ok(exists $config->{perl_versions},      'perl_versions key present');
	ok(exists $config->{enable_linter},      'enable_linter key present');
	ok(exists $config->{enable_critic},      'enable_critic key present');
	ok(exists $config->{enable_coverage},    'enable_coverage key present');
	ok(exists $config->{branches},           'branches key present');
	is($config->{enable_linter},    1,       'linter enabled (y)');
	is($config->{enable_linter_unused}, 0,   'unused disabled (n)');
	is_deeply($config->{branches}, ['main'], 'branches parsed correctly');
};

subtest 'Interactive::customize_workflow - node: collects expected keys' => sub {
	my @answers = (
		'1,2',     # node_versions
		'1',       # package_manager (npm)
		'y',       # enable_lint
		'y',       # enable_build
		'main',    # branches
	);
	my $config = with_stdin(\@answers, sub { customize_workflow('node') });
	ok(exists $config->{node_versions},   'node_versions key present');
	ok(exists $config->{package_manager}, 'package_manager key present');
	is($config->{package_manager}, 'npm', 'npm selected (index 0)');
};

subtest 'Interactive::customize_workflow - python: collects expected keys' => sub {
	my @answers = (
		'1,2',  # python_versions
		'y',    # enable_flake8
		'n',    # enable_black
		'y',    # enable_coverage
		'main', # branches
	);
	my $config = with_stdin(\@answers, sub { customize_workflow('python') });
	ok(exists $config->{python_versions}, 'python_versions key present');
	is($config->{enable_flake8},   1,     'flake8 enabled');
	is($config->{enable_black},    0,     'black disabled');
	is($config->{enable_coverage}, 1,     'coverage enabled');
};

subtest 'Interactive::customize_workflow - rust: collects expected keys' => sub {
	my @answers = ('y', 'y', 'y', 'main');
	my $config = with_stdin(\@answers, sub { customize_workflow('rust') });
	is($config->{enable_fmt},     1, 'fmt enabled');
	is($config->{enable_clippy},  1, 'clippy enabled');
	is($config->{enable_release}, 1, 'release enabled');
};

subtest 'Interactive::customize_workflow - go: collects expected keys' => sub {
	my @answers = ('1.22', 'y', 'y', 'y', 'main');
	my $config = with_stdin(\@answers, sub { customize_workflow('go') });
	is($config->{go_version},     '1.22', 'go version captured');
	is($config->{enable_vet},     1,       'vet enabled');
	is($config->{enable_race},    1,       'race detector enabled');
	is($config->{enable_coverage}, 1,      'coverage enabled');
};

subtest 'Interactive::customize_workflow - ruby: collects expected keys' => sub {
	my @answers = ('1,2', 'main');
	my $config = with_stdin(\@answers, sub { customize_workflow('ruby') });
	ok(exists $config->{ruby_versions}, 'ruby_versions key present');
	is_deeply($config->{branches}, ['main'], 'branches captured');
};

subtest 'Interactive::customize_workflow - docker: collects expected keys' => sub {
	my @answers = ('myuser/myimage', 'n', 'main');
	my $config = with_stdin(\@answers, sub { customize_workflow('docker') });
	is($config->{image_name}, 'myuser/myimage', 'image name captured');
	is($config->{push_on_pr}, 0,                'push_on_pr disabled (n)');
};

subtest 'Interactive::customize_workflow - static: collects expected keys' => sub {
	my @answers = ('./dist', 'npm run build');
	my $config = with_stdin(\@answers, sub { customize_workflow('static') });
	is($config->{build_dir},     './dist',       'build_dir captured');
	is($config->{build_command}, 'npm run build', 'build_command captured');
};

subtest 'Interactive::prompt_multiselect - out-of-range numbers silently ignored' => sub {
	# FORMAL SPEC: n < 1 or n > |options| → ignored; falls back to defaults when result empty.
	my @opts     = ('a', 'b', 'c');
	my @defaults = ('a');
	my $result = with_stdin(['99'], sub {
		prompt_multiselect('Pick', \@opts, \@defaults)
	});
	is_deeply($result, \@defaults, 'out-of-range input falls back to defaults');
};

subtest 'Interactive::prompt_multiselect - mixed valid and invalid numbers' => sub {
	# Valid numbers are kept; out-of-range are dropped.
	my @opts = ('alpha', 'beta', 'gamma');
	my $result = with_stdin(['1,99,3'], sub {
		prompt_multiselect('Pick', \@opts, [])
	});
	is_deeply($result, ['alpha', 'gamma'], 'only valid indices included');
};

# =============================================================================
# 7.  App::GHGen::PerlCustomizer — private helpers and version parsing
# =============================================================================

subtest 'PerlCustomizer::_normalize_version - short form 5.36' => sub {
	my $n = App::GHGen::PerlCustomizer::_normalize_version('5.36');
	is($n, '5.036', 'short form normalised to 5.036');
};

subtest 'PerlCustomizer::_normalize_version - long form 5.036' => sub {
	my $n = App::GHGen::PerlCustomizer::_normalize_version('5.036');
	is($n, '5.036', 'long form normalised identically');
};

subtest 'PerlCustomizer::_normalize_version - v-prefix stripped' => sub {
	my $n = App::GHGen::PerlCustomizer::_normalize_version('v5.36');
	is($n, '5.036', 'v-prefix stripped before normalisation');
};

subtest 'PerlCustomizer::_get_perl_versions - range 5.36..5.40 returns ascending list' => sub {
	my @versions = App::GHGen::PerlCustomizer::_get_perl_versions('5.36', '5.40');
	ok(@versions >= 3, 'at least 3 versions in 5.36..5.40 range');
	is($versions[0],  '5.36', 'lowest version first');
	is($versions[-1], '5.40', 'highest version last');
	# Verify strictly ascending
	for my $i (1 .. $#versions) {
		cmp_ok($versions[$i], 'gt', $versions[$i-1], "version[$i] > version[" . ($i-1) . "]");
	}
};

subtest 'PerlCustomizer::_get_perl_versions - single-version range' => sub {
	my @versions = App::GHGen::PerlCustomizer::_get_perl_versions('5.38', '5.38');
	is(scalar @versions, 1,      'single-version range returns one element');
	is($versions[0],     '5.38', 'that element is the specified version');
};

subtest 'PerlCustomizer::_get_perl_versions - range with no matching versions returns empty' => sub {
	# A range beyond the known version list.
	my @versions = App::GHGen::PerlCustomizer::_get_perl_versions('5.98', '5.99');
	is(scalar @versions, 0, 'out-of-range min/max returns empty list');
};

subtest 'PerlCustomizer::detect_perl_requirements - Makefile.PL MIN_PERL_VERSION' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('Makefile.PL')->spew_utf8(
			"WriteMakefile(MIN_PERL_VERSION => '5.030');\n"
		);
		my $reqs = detect_perl_requirements();
		is($reqs->{has_makefile_pl}, 1,       'has_makefile_pl set');
		is($reqs->{min_version},     '5.030', 'min_version extracted from Makefile.PL');
	});
};

subtest 'PerlCustomizer::detect_perl_requirements - dist.ini and Build.PL flags' => sub {
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('dist.ini')->spew_utf8("[Dist::Zilla]\n");
		path('Build.PL')->spew_utf8("use Module::Build;\n");
		my $reqs = detect_perl_requirements();
		is($reqs->{has_dist_ini},  1, 'has_dist_ini set');
		is($reqs->{has_build_pl},  1, 'has_build_pl set');
		is($reqs->{min_version}, undef, 'no version without cpanfile/Makefile.PL pattern');
	});
};

subtest 'PerlCustomizer::detect_perl_requirements - cpanfile version takes precedence over Makefile.PL' => sub {
	# When both cpanfile and Makefile.PL are present, cpanfile wins.
	my $tmp = tempdir(CLEANUP => 1);
	with_dir($tmp, sub {
		path('cpanfile')->spew_utf8("requires 'perl', '5.036';\n");
		path('Makefile.PL')->spew_utf8("WriteMakefile(MIN_PERL_VERSION => '5.020');\n");
		my $reqs = detect_perl_requirements();
		is($reqs->{min_version}, '5.036', 'cpanfile version takes precedence');
	});
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - custom os list respected' => sub {
	my $yaml = generate_custom_perl_workflow({
		os => ['ubuntu-latest'],
	});
	like($yaml,   qr/ubuntu-latest/, 'custom OS present');
	unlike($yaml, qr/windows-latest/, 'default windows-latest absent with custom os');
	unlike($yaml, qr/macos-latest/,   'default macos-latest absent with custom os');
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - explicit perl_versions overrides min/max' => sub {
	my $yaml = generate_custom_perl_workflow({
		perl_versions => ['5.36', '5.38'],
	});
	like($yaml,   qr/'5\.36'/, '5.36 present');
	like($yaml,   qr/'5\.38'/, '5.38 present');
	unlike($yaml, qr/'5\.40'/, '5.40 absent when not in explicit list');
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - enable_perlimports=0 omits step' => sub {
	my $yaml = generate_custom_perl_workflow({ enable_perlimports => 0 });
	unlike($yaml, qr/perlimports/, 'perlimports absent when disabled');
};

subtest 'PerlCustomizer::generate_custom_perl_workflow - all options disabled produces minimal YAML' => sub {
	my $yaml = generate_custom_perl_workflow({
		enable_linter        => 0,
		enable_linter_unused => 0,
		enable_critic        => 0,
		enable_perlimports   => 0,
		enable_coverage      => 0,
	});
	unlike($yaml, qr/Lint and syntax check/,           'no lint step');
	unlike($yaml, qr/warnings::unused/,                'no unused check');
	unlike($yaml, qr/Perl::Critic/,                    'no critic step');
	unlike($yaml, qr/App::perlimports/,                'no perlimports step');
	unlike($yaml, qr/Devel::Cover/,                    'no coverage step');
	like($yaml,   qr/Run tests/,                       'test step still present');
};

# =============================================================================
# 8.  App::GHGen::Reporter — uncovered helpers and branches
# =============================================================================

subtest 'Reporter::get_type_emoji - unknown type returns a non-empty default' => sub {
	# Reporter.pm has no 'use utf8', so emoji strings are byte sequences.
	# Avoid encoding-sensitive is() comparisons; verify contract: unknown type
	# returns the same fallback character for any unknown key, and that fallback
	# is distinct from any of the four known-type values.
	my $unknown = App::GHGen::Reporter::get_type_emoji('unknown_category');
	ok(defined $unknown && length($unknown) > 0, 'unknown type returns a non-empty fallback');
	my $known_perf = App::GHGen::Reporter::get_type_emoji('performance');
	isnt($unknown, $known_perf, 'unknown fallback differs from known "performance" emoji');
	is(App::GHGen::Reporter::get_type_emoji('also_unknown'), $unknown,
		'two unknown types return the same fallback');
};

subtest 'Reporter::get_severity_badge - unknown severity returns a non-empty default' => sub {
	# Same byte-string caution as get_type_emoji above.
	my $unknown = App::GHGen::Reporter::get_severity_badge('critical');
	ok(defined $unknown && length($unknown) > 0, 'unknown severity returns a non-empty fallback');
	my $known_high = App::GHGen::Reporter::get_severity_badge('high');
	isnt($unknown, $known_high, 'unknown fallback differs from known "high" badge');
	is(App::GHGen::Reporter::get_severity_badge('also_unknown'), $unknown,
		'two unknown severities return the same fallback');
};

subtest 'Reporter::generate_github_comment - file field renders in output' => sub {
	# POD FORMAL SPEC: ∃ i.file defined ⇒ result contains i.file.
	my @issues = ({
		type     => $ISSUE_TYPE{PERF},
		severity => $SEVERITY{MED},
		message  => 'No caching',
		file     => 'ci.yml',
	});
	my $comment = generate_github_comment(\@issues, []);
	like($comment, qr/ci\.yml/, 'file reference appears in comment');
};

subtest 'Reporter::generate_github_comment - applied fixes appear in header' => sub {
	# POD FORMAL SPEC: |fixes| > 0 ⇒ result contains "Applied" ∧ fix count.
	my @issues = ({ type => $ISSUE_TYPE{PERF}, severity => $SEVERITY{LOW}, message => 'slow' });
	my @fixes  = ('fix1', 'fix2');
	my $comment = generate_github_comment(\@issues, \@fixes);
	like($comment, qr/Applied 2/, 'applied fix count visible in comment header');
};

subtest 'Reporter::generate_github_comment - savings omitted when zero' => sub {
	# When no caching/concurrency/trigger issues, savings=0, section absent.
	my @issues = ({
		type     => $ISSUE_TYPE{MAINT},
		severity => $SEVERITY{LOW},
		message  => 'Update runner',
	});
	my $comment = generate_github_comment(\@issues, []);
	unlike($comment, qr/Potential Savings/, 'no savings section when savings=0');
};

subtest 'Reporter::generate_markdown_report - fixes-applied count in summary' => sub {
	# POD FORMAL SPEC: |fixes| > 0 ⇒ result contains "Fixes applied".
	my @fixes = ('f1', 'f2', 'f3');
	my $md = generate_markdown_report([], \@fixes);
	like($md, qr/Fixes applied.*3/s, 'fix count in markdown summary');
};

subtest 'Reporter::generate_markdown_report - no savings section when savings=0' => sub {
	my @issues = ({
		type    => $ISSUE_TYPE{MAINT},
		severity => $SEVERITY{LOW},
		message  => 'Old runner',
	});
	my $md = generate_markdown_report(\@issues, []);
	unlike($md, qr/Estimated Savings/, 'savings section absent when savings=0');
};

subtest 'Reporter::generate_markdown_report - fix block in details when issue has fix key' => sub {
	my @issues = ({
		type     => $ISSUE_TYPE{PERF},
		severity => $SEVERITY{MED},
		message  => 'No caching',
		fix      => "- uses: actions/cache\@v5\n",
	});
	my $md = generate_markdown_report(\@issues, []);
	like($md, qr/<details>/,       'details block present');
	like($md, qr/Suggested Fix/,   'suggested fix label present');
	like($md, qr/actions\/cache/,  'fix YAML included in details block');
};

# =============================================================================
# 9.  Cross-module: timeout issue detected and auto-fixed end-to-end
# =============================================================================

subtest 'End-to-end: timeout missing → detected → auto-fixed' => sub {
	# Exercises analyze_workflow timeout detection + apply_fixes timeout path.
	my $wf = {
		jobs => {
			test => { 'runs-on' => 'ubuntu-latest', steps => [] },
		},
		concurrency => { group => 'x', 'cancel-in-progress' => 'true' },
		on          => { push => { branches => ['main'] } },
	};

	# 1. Detect the missing-timeout issue.
	my @issues = analyze_workflow($wf, 'ci.yml');
	my @timeout_issues = grep { $_->{message} =~ /timeout-minutes/ } @issues;
	is(scalar @timeout_issues, 1, 'one timeout issue detected');

	# 2. Fix it.
	my $n = apply_fixes($wf, \@timeout_issues);
	is($n, 1, 'one fix applied');
	is($wf->{jobs}{test}{'timeout-minutes'}, 30, 'timeout-minutes set to 30');

	# 3. Re-analyse: no more timeout issue.
	my @after = analyze_workflow($wf, 'ci.yml');
	my @remaining = grep { $_->{message} =~ /timeout-minutes/ } @after;
	is(scalar @remaining, 0, 'no timeout issue after fix');
};

# =============================================================================
# 10. Cross-module: Reporter + CostEstimator savings formatting
# =============================================================================

subtest 'Reporter::estimate_savings cost field is always a non-negative integer' => sub {
	# POD FORMAL SPEC: cost ↦ floor(total × RATE) — returns Int, not a formatted float.
	my @test_cases = (
		[{ type => $ISSUE_TYPE{PERF}, message => 'No caching' }],
		[{ type => $ISSUE_TYPE{COST}, message => 'No concurrency group' }],
		[{ type => $ISSUE_TYPE{COST}, message => 'triggers on all pushes' }],
		[
			{ type => $ISSUE_TYPE{PERF}, message => 'No caching' },
			{ type => $ISSUE_TYPE{COST}, message => 'No concurrency group' },
		],
	);
	for my $issues (@test_cases) {
		my $s = App::GHGen::Reporter::estimate_savings($issues);
		like($s->{cost}, qr/^\d+$/, "cost is a non-negative integer for " . scalar(@$issues) . " issues");
		cmp_ok($s->{cost}, '>=', 0, "cost is non-negative");
	}
};

done_testing();
