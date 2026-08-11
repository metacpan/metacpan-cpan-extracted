use v5.36;
use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock unmock);
use File::Temp        qw(tempdir);
use Cwd               qw(getcwd);

use Path::Tiny;

use App::GHGen::Analyzer    qw(analyze_workflow find_workflows get_cache_suggestion);
use App::GHGen::Fixer       qw(apply_fixes can_auto_fix);
use App::GHGen::CostEstimator qw(estimate_savings estimate_workflow_cost estimate_current_usage);
use App::GHGen::Detector    qw(detect_project_type get_project_indicators);

# ============================================================
# Path-coverage test suite — t/path.t
#
# Strategy: enumerate every distinct execution path (branch taken /
# not taken) across Analyzer, Fixer, CostEstimator, and Detector.
# Only paths NOT already exercised in function.t / extended_tests.t /
# unit.t are added here; this file is purely additive.
#
# Dead code flagged inline with:
#   # TODO: Unreachable code detected during path analysis.
# ============================================================

# Shared constants
use Readonly;
Readonly::Scalar my $CI_YML          => 'ci.yml';
Readonly::Scalar my $UBUNTU_LATEST   => 'ubuntu-latest';
Readonly::Scalar my $CACHE_ACTION    => 'actions/cache';
Readonly::Scalar my $CHECKOUT_ACTION => 'actions/checkout@v6';
Readonly::Scalar my $FREE_TIER       => 2_000;   # GitHub free-tier minutes/month

# Minimal "clean" workflow that passes all Analyzer checks.
my %CLEAN_WORKFLOW = (
	on          => { push => { branches => ['main'] } },
	concurrency => { group => 'x', 'cancel-in-progress' => 'true' },
	jobs        => {
		build => {
			'runs-on'        => $UBUNTU_LATEST,
			'timeout-minutes' => 30,
			steps            => [
				{ uses => "$CACHE_ACTION\@v5" },
			],
		},
	},
);

# ============================================================
# SECTION 1 — Analyzer
# ============================================================

# ---- Analyzer::has_broad_triggers ---------------------------

subtest 'Analyzer::has_broad_triggers - push as truthy scalar string → broad (line 417: ref eq empty-string)' => sub {
	# CFG path: on is HASH, $on->{push} is truthy, ref $push eq '' is TRUE.
	# This covers the first branch in the return-1 compound condition.
	# (distinct from the HASH-with-filters path which tests the second part)
	my $wf = {
		on   => { push => 'enabled' },   # truthy scalar, not a reference
		jobs => { build => { 'runs-on' => $UBUNTU_LATEST, steps => [] } },
	};
	my @issues = analyze_workflow($wf, $CI_YML);
	my @cost   = grep { $_->{type} eq 'cost' && $_->{message} =~ /triggers/ } @issues;
	is(scalar @cost, 1, 'truthy scalar push is flagged as a broad trigger');
	diag("trigger message: $cost[0]{message}") if @cost && $ENV{TEST_VERBOSE};
};

subtest 'Analyzer::has_broad_triggers - push key exists but is falsy (undef) → NOT broad' => sub {
	# CFG path: on is HASH, $on->{push} is undef (falsy) → outer if is skipped entirely.
	# This is the path where `on: {push: ~}` appears in YAML.
	my $wf = {
		on   => { push => undef, pull_request => { branches => ['main'] } },
		jobs => { build => { 'runs-on' => $UBUNTU_LATEST, steps => [] } },
	};
	my @issues = analyze_workflow($wf, $CI_YML);
	my @cost   = grep { $_->{type} eq 'cost' && $_->{message} =~ /triggers/ } @issues;
	is(scalar @cost, 0, 'falsy push value does not trigger broad-trigger flag');
};

subtest 'Analyzer::has_broad_triggers - HASH with push having paths filter only → NOT broad' => sub {
	# CFG path: on is HASH, push is HASH, ref ne '', second condition:
	# !$push->{paths}=false → compound AND is false → no return 1.
	my $wf = {
		on   => { push => { paths => ['src/**'] } },
		jobs => { build => { 'runs-on' => $UBUNTU_LATEST, steps => [] } },
	};
	my @issues = analyze_workflow($wf, $CI_YML);
	my @cost   = grep { $_->{type} eq 'cost' && $_->{message} =~ /triggers/ } @issues;
	is(scalar @cost, 0, 'push with paths filter is NOT flagged as broad');
};

# ---- Analyzer::analyze_workflow — unpinned actions cap ------

subtest 'Analyzer::analyze_workflow - 4 unpinned actions: fix message capped at 3 lines' => sub {
	# CFG path: @unpinned has 4 elements.
	# min(2, $#unpinned) = min(2, 3) = 2, so slice is 0..2 (3 items) — capped.
	my $wf = {
		on   => { push => { branches => ['main'] } },
		concurrency => { group => 'x', 'cancel-in-progress' => 'true' },
		jobs => {
			build => {
				'runs-on'        => $UBUNTU_LATEST,
				'timeout-minutes' => 30,
				steps => [
					{ uses => "$CACHE_ACTION\@v5" },
					{ uses => 'org/a@master' },
					{ uses => 'org/b@master' },
					{ uses => 'org/c@master' },
					{ uses => 'org/d@master' },   # 4th unpinned — must be excluded from cap
				],
			},
		},
	};
	my @issues   = analyze_workflow($wf, $CI_YML);
	my @security = grep { $_->{type} eq 'security' } @issues;
	is(scalar @security, 1, 'exactly one security issue emitted');

	my $fix_lines = scalar( () = $security[0]{fix} =~ /org\//g );
	is($fix_lines, 3, 'fix message contains exactly 3 action lines (capped slice)');
	diag("fix text: $security[0]{fix}") if $ENV{TEST_VERBOSE};
};

subtest 'Analyzer::analyze_workflow - 4 outdated actions: fix message capped at 3 lines' => sub {
	# CFG path: @outdated has 4 elements. min(2, $#outdated) = 2 → 3-item slice.
	my $wf = {
		on   => { push => { branches => ['main'] } },
		concurrency => { group => 'x', 'cancel-in-progress' => 'true' },
		jobs => {
			build => {
				'runs-on'        => $UBUNTU_LATEST,
				'timeout-minutes' => 30,
				steps => [
					{ uses => "$CACHE_ACTION\@v5" },
					{ uses => 'actions/checkout@v3'     },
					{ uses => 'actions/checkout@v4'     },
					{ uses => 'actions/checkout@v5'     },
					{ uses => 'actions/cache@v3'        },
				],
			},
		},
	};
	my @issues   = analyze_workflow($wf, $CI_YML);
	my @maint    = grep { $_->{type} eq 'maintenance' && $_->{message} =~ /outdated/ } @issues;
	is(scalar @maint, 1, 'exactly one maintenance/outdated issue emitted');

	# Each outdated-action line contains exactly one "→" arrow.
	# With 4 outdated actions and min(2, $#outdated)=2, the slice is 0..2 (3 items).
	my $arrow_count = scalar( () = $maint[0]{fix} =~ /→/g );
	cmp_ok($arrow_count, '<=', 3, 'fix message lists at most 3 outdated actions (≤3 arrows)');
	diag("outdated fix: $maint[0]{fix}") if $ENV{TEST_VERBOSE};
};

subtest 'Analyzer::analyze_workflow - all 7 checks fire simultaneously (worst case)' => sub {
	# CFG path: every branch in analyze_workflow is taken.
	# No caching, unpinned, outdated, broad trigger, no concurrency, old runner, no timeout.
	my $wf = {
		on   => [qw(push)],                        # broad trigger
		jobs => {
			build => {
				'runs-on' => 'ubuntu-18.04',       # outdated runner
				steps => [
					{ uses => 'actions/checkout@master' },      # unpinned + also not outdated-format
					{ uses => 'actions/cache@v3'        },      # outdated action
				],
			},
		},
		# no concurrency, no timeout-minutes
	};
	my @issues = analyze_workflow($wf, $CI_YML);

	my %by_type;
	for my $i (@issues) { push @{ $by_type{$i->{type}} }, $i }

	ok(scalar(@{ $by_type{performance} // [] }) >= 1, 'at least one performance issue (caching + timeout)');
	ok(scalar(@{ $by_type{security}    // [] }) >= 1, 'at least one security issue (unpinned)');
	ok(scalar(@{ $by_type{cost}        // [] }) >= 1, 'at least one cost issue (concurrency + triggers)');
	ok(scalar(@{ $by_type{maintenance} // [] }) >= 1, 'at least one maintenance issue (outdated + runner)');
	cmp_ok(scalar @issues, '>=', 6, 'at least 6 issues in the worst-case workflow');
	diag("issue count: " . scalar(@issues)) if $ENV{TEST_VERBOSE};
};

subtest 'Analyzer::analyze_workflow - all 7 checks pass (best case, 0 issues)' => sub {
	# CFG path: every unless/if check in analyze_workflow takes the false branch.
	my @issues = analyze_workflow(\%CLEAN_WORKFLOW, $CI_YML);
	is(scalar @issues, 0, 'clean workflow produces no issues');
};

# ---- Analyzer::min ------------------------------------------

subtest 'Analyzer::min - boundary: equal values returns second argument (b)' => sub {
	# CFG path: $a == $b → condition `$a < $b` is FALSE → return $b.
	my $result = App::GHGen::Analyzer::min(5, 5);
	is($result, 5, 'min(5,5) returns 5');
};

# ============================================================
# SECTION 2 — Fixer
# ============================================================

# ---- Fixer::detect_and_create_cache_step --------------------

subtest 'Fixer::detect_and_create_cache_step - setup-node in uses (not run) triggers npm cache' => sub {
	# CFG path: $run = '' (no run field), $step->{uses} has setup-node → first OR branch taken.
	my $steps = [ { uses => 'actions/setup-node@v4' } ];
	my $step  = App::GHGen::Fixer::detect_and_create_cache_step($steps);
	ok(defined $step, 'cache step created from setup-node uses');
	is($step->{name}, 'Cache dependencies', 'npm cache step name');
	like($step->{with}{path}, qr{\.npm}, 'npm cache path');
	diag("cache step: $step->{uses}") if $ENV{TEST_VERBOSE};
};

subtest 'Fixer::detect_and_create_cache_step - setup-python in uses triggers pip cache' => sub {
	# CFG path: $run = '' (no run field), $step->{uses} has setup-python.
	my $steps = [ { uses => 'actions/setup-python@v5' } ];
	my $step  = App::GHGen::Fixer::detect_and_create_cache_step($steps);
	ok(defined $step, 'cache step created from setup-python uses');
	is($step->{name}, 'Cache pip packages', 'pip cache step name');
	like($step->{with}{path}, qr{\.cache/pip}, 'pip cache path');
};

# ---- Fixer::add_caching — insertion position ---------------

subtest 'Fixer::add_caching - no checkout step: cache inserted at position 0' => sub {
	# CFG path: the inner for loop over steps completes without finding /actions\/checkout/,
	# so $insert_at stays 0. The cache step is spliced in at index 0.
	my $wf = {
		jobs => {
			build => {
				steps => [
					{ run => 'npm ci' },
					{ run => 'npm test' },
				],
			},
		},
	};
	my $count = App::GHGen::Fixer::add_caching($wf);
	is($count, 1, 'one cache step inserted');
	is($wf->{jobs}{build}{steps}[0]{name}, 'Cache dependencies', 'cache step is at index 0');
	diag("first step name: $wf->{jobs}{build}{steps}[0]{name}") if $ENV{TEST_VERBOSE};
};

subtest 'Fixer::add_caching - checkout at index 1: cache inserted at index 2' => sub {
	# CFG path: checkout found at position 1, $insert_at = 2, `last` exits the loop.
	my $wf = {
		jobs => {
			build => {
				steps => [
					{ name => 'Setup env', run  => 'echo hi' },
					{ uses => $CHECKOUT_ACTION },
					{ run  => 'npm ci'         },
				],
			},
		},
	};
	my $count = App::GHGen::Fixer::add_caching($wf);
	is($count, 1, 'one cache step inserted');
	is($wf->{jobs}{build}{steps}[2]{name}, 'Cache dependencies', 'cache step at index 2 (after checkout at 1)');
};

subtest 'Fixer::add_caching - unrecognised project type: next unless $cache_step fires' => sub {
	# CFG path: detect_and_create_cache_step returns undef for a step with no recognizable
	# package-manager commands → the `next unless $cache_step` guard fires, 0 is returned.
	my $wf = {
		jobs => {
			build => {
				steps => [
					{ uses => $CHECKOUT_ACTION },
					{ run  => 'make all'        },   # not npm/pip/cargo/go
				],
			},
		},
	};
	my $count = App::GHGen::Fixer::add_caching($wf);
	is($count, 0, 'no cache step added for unrecognised project type');
	is(scalar @{ $wf->{jobs}{build}{steps} }, 2, 'step count unchanged');
};

# ---- Fixer::update_runners — no runs-on path ---------------

subtest 'Fixer::update_runners - job with no runs-on key: or-next guard fires' => sub {
	# CFG path: $job->{'runs-on'} is undef → `or next` fires → job skipped → 0 returned.
	my $wf = { jobs => { build => { steps => [] } } };   # no runs-on key
	my $count = App::GHGen::Fixer::update_runners($wf);
	is($count, 0, 'job without runs-on does not cause error and returns 0');
};

# ---- Fixer::add_trigger_filters — HASH push as HASH (elsif false) -

subtest 'Fixer::add_trigger_filters - HASH on with push already a HASH (not scalar): no change' => sub {
	# CFG path: on is HASH (first `if` fails — not ARRAY), push is a HASH ref
	# → `ref $on->{push} eq ''` is FALSE → elsif body skipped → $modified stays 0.
	my $wf = { on => { push => { branches => ['main'] } } };
	my $n  = App::GHGen::Fixer::add_trigger_filters($wf);
	is($n, 0, 'push with branch filter (HASH push value) produces 0 modifications');
};

subtest 'Fixer::add_trigger_filters - ARRAY on without push: grep is false, returns 0' => sub {
	# CFG path: on is ARRAY, grep finds no 'push' element → condition false → return 0.
	my $wf = { on => [qw(pull_request workflow_dispatch)] };
	my $n  = App::GHGen::Fixer::add_trigger_filters($wf);
	is($n, 0, 'array on without push element returns 0');
};

# ============================================================
# SECTION 3 — CostEstimator
# ============================================================

# ---- CostEstimator::estimate_savings — zero-saving paths ---

subtest 'CostEstimator::estimate_savings - performance issue NOT caching: $saving stays 0' => sub {
	# CFG path: $issue->{type} eq 'performance', inner if /caching/ is FALSE.
	# $saving remains 0, the `if ($saving > 0)` block is skipped.
	my $issue   = { type => 'performance', message => 'missing timeout-minutes', severity => 'low' };
	my $savings = App::GHGen::CostEstimator::estimate_savings([$issue]);
	is($savings->{minutes}, 0, 'performance/non-caching contributes 0 minutes');
	is(scalar @{ $savings->{details} }, 0, 'no detail entry for zero-saving issue');
};

subtest 'CostEstimator::estimate_savings - cost issue NOT concurrency AND NOT triggers: $saving=0' => sub {
	# CFG path: $issue->{type} eq 'cost', /concurrency/ is FALSE, /triggers/ is FALSE.
	# $saving remains 0.
	my $issue   = { type => 'cost', message => 'generic cost problem', severity => 'low' };
	my $savings = App::GHGen::CostEstimator::estimate_savings([$issue]);
	is($savings->{minutes}, 0, 'cost/other contributes 0 minutes');
	is(scalar @{ $savings->{details} }, 0, 'no detail entry');
};

subtest 'CostEstimator::estimate_savings - current_usage with total_minutes=0 → elif branch (30%)' => sub {
	# CFG path: current_usage is undef (no workflows passed), $savings{minutes} > 0
	# → first `if` false (current_usage undef), elsif ($savings{minutes} > 0) TRUE → 30%.
	# Verified by not passing $workflows so $current_usage stays undef.
	my $caching = { type => 'performance', message => 'caching', severity => 'medium' };
	my $savings  = App::GHGen::CostEstimator::estimate_savings([$caching]);   # no workflows
	is($savings->{percentage}, 30, 'fallback 30% when no current usage available');
	cmp_ok($savings->{minutes}, '>', 0, 'minutes > 0 to trigger the elif');
};

subtest 'CostEstimator::estimate_savings - all savings=0, percentage stays 0' => sub {
	# CFG path: $savings{minutes} = 0 → neither the if nor the elsif fires.
	my $issue   = { type => 'maintenance', message => 'outdated runner', severity => 'low' };
	my $savings = App::GHGen::CostEstimator::estimate_savings([$issue]);
	is($savings->{minutes},    0, 'zero minutes');
	is($savings->{percentage}, 0, 'percentage stays 0 when no savings');
};

# ---- CostEstimator::estimate_savings — with current_usage --

subtest 'CostEstimator::estimate_savings - cost/concurrency WITH current_usage: proportional saving' => sub {
	# CFG path: $current_usage is defined (workflows passed), concurrency branch.
	# saving = total_minutes * 0.15.
	my $wf_file = do {
		my $tmp = File::Temp->new(SUFFIX => '.yml');
		print $tmp "name: test\non:\n  push:\n    branches:\n      - main\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - run: 'sleep 1'\n";
		$tmp;
	};
	my $concurrency = { type => 'cost', message => 'concurrency', severity => 'low' };
	# We need real workflow files. Use a mock instead.
	mock 'App::GHGen::CostEstimator::estimate_current_usage' => sub {
		return { total_minutes => 1000, billable_minutes => 0, monthly_cost => 0, workflows => [] };
	};
	my $savings = App::GHGen::CostEstimator::estimate_savings([$concurrency], ['fake.yml']);
	unmock 'App::GHGen::CostEstimator::estimate_current_usage';
	is($savings->{minutes}, 150, 'concurrency saving = 1000 * 0.15 = 150 min');
	cmp_ok($savings->{percentage}, '>', 0, 'percentage is non-zero');
	diag("concurrency saving: $savings->{minutes} min") if $ENV{TEST_VERBOSE};
};

subtest 'CostEstimator::estimate_savings - cost/triggers WITH current_usage: proportional saving' => sub {
	# CFG path: $current_usage is defined, triggers branch. saving = total_minutes * 0.25.
	mock 'App::GHGen::CostEstimator::estimate_current_usage' => sub {
		return { total_minutes => 400, billable_minutes => 0, monthly_cost => 0, workflows => [] };
	};
	my $triggers = { type => 'cost', message => 'triggers', severity => 'medium' };
	my $savings  = App::GHGen::CostEstimator::estimate_savings([$triggers], ['fake.yml']);
	unmock 'App::GHGen::CostEstimator::estimate_current_usage';
	is($savings->{minutes}, 100, 'triggers saving = 400 * 0.25 = 100 min');
};

subtest 'CostEstimator::estimate_savings - current_usage total>0: proportional percentage' => sub {
	# CFG path: current_usage defined AND total_minutes > 0 → first `if` in percentage block fires.
	mock 'App::GHGen::CostEstimator::estimate_current_usage' => sub {
		return { total_minutes => 200, billable_minutes => 0, monthly_cost => 0, workflows => [] };
	};
	my $caching = { type => 'performance', message => 'caching', severity => 'medium' };
	my $savings = App::GHGen::CostEstimator::estimate_savings([$caching], ['fake.yml']);
	unmock 'App::GHGen::CostEstimator::estimate_current_usage';
	# saving = 75, total = 200 → percentage = int(75/200 * 100) = 37
	is($savings->{percentage}, 37, 'proportional percentage: int(75/200*100)=37');
};

# ---- CostEstimator::estimate_job_duration — unrecognised uses -

subtest 'CostEstimator::estimate_job_duration - uses not matching any pattern: +0 for that step' => sub {
	# CFG path: $step->{uses} is set but doesn't match checkout, setup-*, or cache.
	# The step's `uses` block exits without incrementing $duration.
	my $job = {
		steps => [
			{ uses => 'some-org/custom-action@v2' },   # no match
			{ uses => $CHECKOUT_ACTION             },   # match: +0.5
		],
	};
	my $dur = App::GHGen::CostEstimator::estimate_job_duration($job);
	# Only checkout contributes: 0.5. || 3 guard does not fire.
	cmp_ok($dur, '>=', 0.5, 'at least checkout duration counted');
	cmp_ok($dur, '<', 1.0,  'unrecognised action adds 0 so total < 1.0');
};

subtest 'CostEstimator::estimate_job_duration - step has neither uses nor run: +0 for that step' => sub {
	# CFG path: step has only {name: ...} — neither $step->{uses} nor $step->{run} is set.
	# Neither branch of the outer if/elsif fires → duration unchanged by that step.
	my $job = {
		steps => [
			{ name => 'Noop step' },           # contributes 0
			{ run  => 'npm ci'    },            # contributes 2
		],
	};
	my $dur = App::GHGen::CostEstimator::estimate_job_duration($job);
	is($dur, 2, 'noop step contributes 0; npm ci contributes 2');
};

subtest 'CostEstimator::estimate_job_duration - zero total falls back to 3' => sub {
	# CFG path: all steps have neither uses nor run → $duration stays 0 → `|| 3` fires.
	my $job = { steps => [ { name => 'noop' }, { name => 'also noop' } ] };
	my $dur  = App::GHGen::CostEstimator::estimate_job_duration($job);
	is($dur, 3, 'zero computed duration returns fallback 3');
};

# ---- CostEstimator::estimate_matrix_factor — scalar value --

subtest 'CostEstimator::estimate_matrix_factor - matrix key with scalar value: skipped (not ARRAY)' => sub {
	# CFG path: `ref $values eq 'ARRAY'` is FALSE → size stays 1 (no multiplication).
	my $wf = {
		jobs => {
			build => {
				strategy => {
					matrix => { os => 'ubuntu-latest' },   # scalar, not array
				},
				steps => [],
			},
		},
	};
	my $factor = App::GHGen::CostEstimator::estimate_matrix_factor($wf);
	is($factor, 1, 'scalar matrix value not counted — factor stays 1');
};

# ---- CostEstimator::estimate_current_usage — free tier boundary -

subtest 'CostEstimator::estimate_current_usage - total exactly at free tier: billable=0' => sub {
	# CFG path: $total_minutes == $free_tier → condition `> $free_tier` is FALSE → billable=0.
	# Strategy: write a minimal valid YAML file so LoadFile succeeds, then mock
	# estimate_workflow_cost so the return value is under our control.
	my $dir = tempdir(CLEANUP => 1);
	my $yml = path($dir)->child('ci.yml');
	$yml->spew("on:\n  push:\n    branches:\n      - main\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps: []\n");

	mock 'App::GHGen::CostEstimator::estimate_workflow_cost' => sub {
		return {
			name              => 'test',
			file              => 'ci.yml',
			runs_per_month    => 1,
			minutes_per_run   => $FREE_TIER,
			minutes_per_month => $FREE_TIER,
		};
	};
	my $usage = App::GHGen::CostEstimator::estimate_current_usage([$yml]);
	unmock 'App::GHGen::CostEstimator::estimate_workflow_cost';
	is($usage->{billable_minutes}, 0,   'total at free tier → billable_minutes = 0');
	is($usage->{monthly_cost},     '0', 'total at free tier → monthly_cost = 0');
};

subtest 'CostEstimator::estimate_current_usage - total above free tier: billable > 0' => sub {
	# CFG path: $total_minutes > $free_tier → billable = total - FREE_TIER → cost > 0.
	my $excess = 500;
	my $dir = tempdir(CLEANUP => 1);
	my $yml = path($dir)->child('ci.yml');
	$yml->spew("on:\n  push:\n    branches:\n      - main\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps: []\n");

	mock 'App::GHGen::CostEstimator::estimate_workflow_cost' => sub {
		return {
			name              => 'test',
			file              => 'ci.yml',
			runs_per_month    => 1,
			minutes_per_run   => $FREE_TIER + $excess,
			minutes_per_month => $FREE_TIER + $excess,
		};
	};
	my $usage = App::GHGen::CostEstimator::estimate_current_usage([$yml]);
	unmock 'App::GHGen::CostEstimator::estimate_workflow_cost';
	is($usage->{billable_minutes}, $excess, "billable = total - $FREE_TIER = $excess");
	cmp_ok($usage->{monthly_cost}, '>', 0,  'monthly cost > 0 above free tier');
};

# ============================================================
# SECTION 4 — Detector
# ============================================================

subtest 'Detector::detect_project_type - scalar context with no project files: returns undef' => sub {
	# CFG path: @detections is empty after scoring → `return undef unless @detections` fires.
	my $dir = tempdir(CLEANUP => 1);
	my $cwd = getcwd();
	chdir $dir;
	my $type = detect_project_type();
	chdir $cwd;
	ok(!defined $type, 'empty directory returns undef in scalar context');
};

subtest 'Detector::detect_project_type - list context with no project files: returns empty list' => sub {
	# CFG path: @detections is empty → wantarray true → returns @detections (empty).
	my $dir = tempdir(CLEANUP => 1);
	my $cwd = getcwd();
	chdir $dir;
	my @types = detect_project_type();
	chdir $cwd;
	is(scalar @types, 0, 'empty directory returns empty list in list context');
};

subtest 'Detector::get_project_indicators - known type returns arrayref' => sub {
	# CFG path: $type given and in %indicators → return $indicators{$type} (arrayref).
	my $perl_indicators = get_project_indicators('perl');
	ok(ref $perl_indicators eq 'ARRAY', 'known type returns arrayref');
	ok(grep { $_ eq 'cpanfile' } @$perl_indicators, 'cpanfile in perl indicators');
};

subtest 'Detector::get_project_indicators - unknown type returns undef' => sub {
	# CFG path: $type given but not in %indicators → $indicators{$type} is undef → return undef.
	my $result = get_project_indicators('cobol');
	ok(!defined $result, 'unknown type returns undef');
};

subtest 'Detector::get_project_indicators - no argument returns hashref of all types' => sub {
	# CFG path: $type is undef (default) → return \%indicators.
	my $all = get_project_indicators();
	ok(ref $all eq 'HASH', 'no argument returns hashref');
	ok(exists $all->{perl}, 'perl key present');
	ok(exists $all->{node}, 'node key present');
	ok(exists $all->{rust}, 'rust key present');
};

# ============================================================
# SECTION 5 — Dead code annotation
# ============================================================

# Analyzer::has_deployment_steps is defined but:
#  1. Not exported in @EXPORT_OK.
#  2. Not called from analyze_workflow or any other public function.
#  3. Cannot be reached through the public API.
# It is confirmed dead code; see t/extended_tests.t:167 for prior annotation.
# The function itself is still callable via its fully-qualified name, so
# the paths inside it are exercised only through direct internal calls.
#
# TODO: Unreachable code detected during path analysis. Investigate for removal.
# Candidate: App::GHGen::Analyzer::has_deployment_steps (lib/App/GHGen/Analyzer.pm:524)

done_testing();
