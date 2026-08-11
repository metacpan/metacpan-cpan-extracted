use v5.36;
use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock unmock restore_all);
use Capture::Tiny     qw(capture_stdout);
use File::Temp        qw(tempdir);
use Cwd               qw(getcwd);
use Path::Tiny;
use Readonly;

use App::GHGen::CostEstimator qw(estimate_savings);
use App::GHGen::Fixer         qw(apply_fixes can_auto_fix);
use App::GHGen::Reporter      qw(generate_markdown_report generate_github_comment);
use App::GHGen::Interactive;
use App::GHGen::Detector;

# ============================================================
# Mutant-killer test suite — t/mutant_killers.t
#
# Each subtest targets a surviving mutant from the most recent
# xt/mutant_20260810_160920.t stub.  The comment before each
# subtest names the mutant ID, the mutated source line, and
# explains precisely how the assertion kills the mutation.
# ============================================================

# ============================================================
# Constants — no magic literals
# ============================================================
Readonly::Scalar my $CACHING_MSG     => 'missing caching for dependencies';
Readonly::Scalar my $CONCURRENCY_MSG => 'no concurrency controls configured';
Readonly::Scalar my $SECURITY_MSG    => 'action pinned to an unhashed commit';
Readonly::Scalar my $CHECKOUT_ACTION => 'actions/checkout@v6';
Readonly::Scalar my $SETUPNODE_ACT   => 'actions/setup-node@v4';
Readonly::Scalar my $CACHE_ACTION    => 'actions/cache@v5';

# Pre-built issue hashrefs used across multiple tests.
Readonly::Scalar my $CACHING_ISSUE => {
	type => 'performance', severity => 'high', message => $CACHING_MSG,
};
Readonly::Scalar my $CONCURRENCY_ISSUE => {
	type => 'cost', severity => 'medium', message => $CONCURRENCY_MSG,
};
Readonly::Scalar my $SECURITY_ISSUE => {
	type => 'security', severity => 'high', message => $SECURITY_MSG,
};

# ============================================================
# Helper: run $code in a fresh tempdir, restore CWD after.
# Detector tests use this to isolate filesystem state.
# ============================================================
sub in_tempdir($code) {
	my $dir  = tempdir(CLEANUP => 1);
	my $orig = getcwd();
	chdir $dir or die "Cannot chdir to $dir: $!";
	my $result = eval { $code->() };
	my $err = $@;
	chdir $orig or die "Cannot chdir back to $orig: $!";
	die $err if $err;
	return $result;
}

########################################################################
# SECTION 1 — CostEstimator::estimate_savings line 389
#   Source:  if ($current_usage && $current_usage->{total_minutes} > 0) {
#   Mutant:  NUM_BOUNDARY_389_59_< (HIGH) — > flipped to <, >=, or <=
########################################################################

subtest 'NUM_BOUNDARY_389_59_< — proportional percentage when total_minutes=1 (kills < mutant)' => sub {
	# Strategy: total_minutes=1, savings=75 min → real percentage = int(75/1*100) = 7500.
	# With > → <: 1 < 0 → false → falls to elsif → percentage = 30.
	# Asserting percentage = 7500 (not 30) kills the < and <= mutations.
	mock 'App::GHGen::CostEstimator::estimate_current_usage'
		=> sub { return { total_minutes => 1 } };
	my $result = estimate_savings([$CACHING_ISSUE], ['dummy']);
	unmock 'App::GHGen::CostEstimator::estimate_current_usage';

	is($result->{percentage}, 7500,
		'percentage = int(75/1*100) = 7500, NOT the 30-fallback');
	diag("percentage=$result->{percentage}") if $ENV{TEST_VERBOSE};
};

subtest 'NUM_BOUNDARY_389_59_< — no crash when total_minutes=0 and percentage=30 (kills >= mutant)' => sub {
	# Strategy: total_minutes=0 → real: 0 not > 0 → falls to elsif → percentage=30, no crash.
	# With > → >=: 0 >= 0 → true → int(75/0*100) → "Illegal division by zero".
	# lives_ok catches the mutation crash; is() confirms correct fallback.
	mock 'App::GHGen::CostEstimator::estimate_current_usage'
		=> sub { return { total_minutes => 0 } };
	my $result;
	lives_ok(
		sub { $result = estimate_savings([$CACHING_ISSUE], ['dummy']) },
		'no crash when total_minutes = 0'
	);
	unmock 'App::GHGen::CostEstimator::estimate_current_usage';

	is($result->{percentage}, 30,
		'percentage falls back to 30 via elsif when total_minutes = 0');
};

########################################################################
# SECTION 2 — CostEstimator::estimate_duration line 467
#   Source:  if ($has_dependencies) {
#   Mutant:  COND_INV_467_9 (MEDIUM) — if flipped to unless
########################################################################

subtest 'COND_INV_467_9 — sequential workflow gives sum of durations (kills unless mutant)' => sub {
	# job build: 1 npm step → 2 min. job test: 2 npm steps → 4 min, needs build.
	# Real (if has_dependencies): sequential → 2+4 = 6 → int(6*1) = 6.
	# Unless mutation: sequential treated as parallel → max(2,4) = 4 (wrong).
	my $wf = {
		jobs => {
			build => { steps => [{ run => 'npm install' }] },
			test  => { needs => ['build'],
			           steps => [{ run => 'npm install' }, { run => 'npm install' }] },
		},
	};
	my $result = App::GHGen::CostEstimator::estimate_duration($wf);
	is($result, 6, 'sequential (needs): duration = sum 2+4 = 6');
	diag("sequential duration=$result") if $ENV{TEST_VERBOSE};
};

subtest 'COND_INV_467_9 — parallel workflow gives max of durations (kills unless mutant)' => sub {
	# Both jobs have no needs → parallel.
	# Real: parallel → max(2,4) = 4.  Unless mutant: sequential → 2+4 = 6 (wrong).
	my $wf = {
		jobs => {
			lint  => { steps => [{ run => 'npm install' }] },
			build => { steps => [{ run => 'npm install' }, { run => 'npm install' }] },
		},
	};
	my $result = App::GHGen::CostEstimator::estimate_duration($wf);
	is($result, 4, 'parallel (no needs): duration = max(2,4) = 4');
	diag("parallel duration=$result") if $ENV{TEST_VERBOSE};
};

########################################################################
# SECTION 3 — CostEstimator::estimate_duration line 472
#   Source:  $max_parallel_duration = $duration if $duration > $max_parallel_duration;
#   Mutant:  NUM_BOUNDARY_472_61_< (HIGH) — > flipped to <, <=
#   Note:    >= mutation is semantically equivalent to > when accumulating a
#            max starting from 0 with non-negative durations (updating the
#            max with an equal value is a no-op).  This is a known equivalent
#            mutant — no semantic test can distinguish it.
########################################################################

subtest 'NUM_BOUNDARY_472_61_< — parallel max uses correct > comparison (kills < and <= mutants)' => sub {
	# Job lint: 1 cargo step → 5 min. Job build: 2 cargo steps → 10 min.
	# Real (>): max(5,10) = 10 → int(10*1) = 10.
	# < mutant: neither 5 < 0 nor 10 < 0 → max stays 0 → 0||5 = 5 (wrong).
	# <= mutant: same, max stays 0 → fallback 5 (wrong).
	my $wf = {
		jobs => {
			lint  => { steps => [{ run => 'cargo build' }] },
			build => { steps => [{ run => 'cargo build' }, { run => 'cargo build' }] },
		},
	};
	my $result = App::GHGen::CostEstimator::estimate_duration($wf);
	is($result, 10, 'parallel max: largest job wins (10 not fallback 5)');
	diag("max parallel duration=$result") if $ENV{TEST_VERBOSE};
};

########################################################################
# SECTION 4 — Detector: per-language @files > 0 boundaries
#   Mutants: NUM_BOUNDARY_246/252/298/333/353/390/415/435 (all HIGH)
#   Pattern: $score += N if @files > 0
#   Mutations: > flipped to <, >=, <=
#
#   Two tests per detector kill all three variants:
#     Test A (0 files): asserts score=base; >= mutation adds N → fails.
#     Test B (1 file):  asserts score=base+N; < and <= mutations give base → fails.
########################################################################

subtest 'NUM_BOUNDARY_246_28_< — Detector::_detect_perl pm_files boundary (line 246, +2)' => sub {
	# lib/ dir alone scores 3 (dir exists); +2 from pm_files > 0 with one .pm.
	my $empty = in_tempdir(sub {
		path('lib')->mkpath;
		App::GHGen::Detector::_detect_perl();
	});
	is($empty, 3, 'empty lib/ scores 3 (dir only)');

	my $one_pm = in_tempdir(sub {
		path('lib')->mkpath;
		path('lib/Foo.pm')->touch;
		App::GHGen::Detector::_detect_perl();
	});
	is($one_pm, 5, '1 .pm in lib/ scores 5 (3 dir + 2 pm_files)');
	diag("pm scores: empty=$empty one=$one_pm") if $ENV{TEST_VERBOSE};
};

subtest 'NUM_BOUNDARY_252_27_< — Detector::_detect_perl t_files boundary (line 252, +1)' => sub {
	# t/ dir alone scores 2 (dir exists); +1 from t_files > 0 with one .t.
	my $empty = in_tempdir(sub {
		path('t')->mkpath;
		App::GHGen::Detector::_detect_perl();
	});
	is($empty, 2, 'empty t/ scores 2 (dir only)');

	my $one_t = in_tempdir(sub {
		path('t')->mkpath;
		path('t/foo.t')->touch;
		App::GHGen::Detector::_detect_perl();
	});
	is($one_t, 3, '1 .t in t/ scores 3 (2 dir + 1 t_files)');
};

subtest 'NUM_BOUNDARY_298_27_< — Detector::_detect_python py_files boundary (line 298, +2)' => sub {
	my $empty = in_tempdir(sub { App::GHGen::Detector::_detect_python() });
	is($empty, 0, 'empty dir: python score = 0');

	my $one = in_tempdir(sub {
		path('app.py')->touch;
		App::GHGen::Detector::_detect_python();
	});
	is($one, 2, '1 .py file: python score = 2');
};

subtest 'NUM_BOUNDARY_333_27_< — Detector::_detect_go go_files boundary (line 333, +3)' => sub {
	# Use utils.go (not main.go) to avoid the +5 medium-indicator bonus from path('main.go').
	my $empty = in_tempdir(sub { App::GHGen::Detector::_detect_go() });
	is($empty, 0, 'empty dir: go score = 0');

	my $one = in_tempdir(sub {
		path('utils.go')->touch;
		App::GHGen::Detector::_detect_go();
	});
	is($one, 3, '1 non-main .go file: go score = 3 (go_files bonus only)');
};

subtest 'NUM_BOUNDARY_353_27_< — Detector::_detect_ruby rb_files boundary (line 353, +2)' => sub {
	my $empty = in_tempdir(sub { App::GHGen::Detector::_detect_ruby() });
	is($empty, 0, 'empty dir: ruby score = 0');

	my $one = in_tempdir(sub {
		path('app.rb')->touch;
		App::GHGen::Detector::_detect_ruby();
	});
	is($one, 2, '1 .rb file: ruby score = 2');
};

subtest 'NUM_BOUNDARY_390_28_< — Detector::_detect_php php_files boundary (line 390, +2)' => sub {
	my $empty = in_tempdir(sub { App::GHGen::Detector::_detect_php() });
	is($empty, 0, 'empty dir: php score = 0');

	my $one = in_tempdir(sub {
		path('index.php')->touch;
		App::GHGen::Detector::_detect_php();
	});
	is($one, 2, '1 .php file: php score = 2');
};

subtest 'NUM_BOUNDARY_415_29_< — Detector::_detect_java java_files boundary (line 415, +2)' => sub {
	my $empty = in_tempdir(sub { App::GHGen::Detector::_detect_java() });
	is($empty, 0, 'empty dir: java score = 0');

	my $one = in_tempdir(sub {
		path('Main.java')->touch;
		App::GHGen::Detector::_detect_java();
	});
	is($one, 2, '1 .java file: java score = 2');
};

subtest 'NUM_BOUNDARY_435_28_< — Detector::_detect_cpp cpp_files boundary (line 435, +3)' => sub {
	# cpp_files > 0 → +3; cpp_files > 5 → +2 extra.  With 1 file: +3 only.
	my $empty = in_tempdir(sub { App::GHGen::Detector::_detect_cpp() });
	is($empty, 0, 'empty dir: cpp score = 0');

	my $one = in_tempdir(sub {
		path('main.cpp')->touch;
		App::GHGen::Detector::_detect_cpp();
	});
	is($one, 3, '1 .cpp file: cpp score = 3 (> 0 bonus only, not > 5 bonus)');
};

########################################################################
# SECTION 5 — Fixer::add_caching line 318
#   Source:  if ($steps->[$i]->{uses} && $steps->[$i]->{uses} =~ /actions\/checkout/)
#   Mutant:  COND_INV_318_13 (MEDIUM) — if flipped to unless
########################################################################

subtest 'COND_INV_318_13 — cache inserted at index 1 (after checkout), not elsewhere (kills unless mutant)' => sub {
	# Steps: [checkout, setup-node].  detect_and_create_cache_step sees setup-node → npm cache.
	# Real (if): checkout at i=0 → insert_at=1 → [checkout, CACHE, setup-node].
	# Unless mutant: i=0 checkout → condition true → unless false → SKIP.
	#   i=1 setup-node: uses present, not checkout → condition false → unless true → insert_at=2.
	#   Result: [checkout, setup-node, CACHE] — CACHE is at index 2, not 1.
	my $workflow = {
		jobs => {
			test => {
				steps => [
					{ uses => $CHECKOUT_ACTION },
					{ uses => $SETUPNODE_ACT  },
				],
			},
		},
	};
	my $count = App::GHGen::Fixer::add_caching($workflow);
	is($count, 1, 'one caching fix applied');

	my $steps = $workflow->{jobs}{test}{steps};
	diag('steps: ' . join(', ', map { $_->{uses} // $_->{name} // '?' } @$steps))
		if $ENV{TEST_VERBOSE};

	is($steps->[0]{uses}, $CHECKOUT_ACTION,
		'checkout remains at index 0');
	is($steps->[1]{uses}, $CACHE_ACTION,
		'cache step inserted at index 1 (immediately after checkout)');
	is($steps->[2]{uses}, $SETUPNODE_ACT,
		'setup-node displaced to index 2');
};

########################################################################
# SECTION 6 — Interactive::prompt_choice line 180
#   Source:  my $marker = $i == $default ? colored(['green'], '→') : ' ';
#   Mutant:  NUM_BOUNDARY_180_25_!= (HIGH) — == flipped to !=
########################################################################

subtest 'NUM_BOUNDARY_180_25_!= — arrow marker on correct default choice (kills != mutant)' => sub {
	# With default=1, choice at index 1 ("Option B") should show '→'.
	# != mutant: marker applied when i != 1 → Option A and Option C get '→' instead.
	# Capture stdout; assert '→' appears on exactly one line and it is choice 2.
	open(local *STDIN, '<', \"\n") or die "Cannot redirect STDIN: $!";
	my $out = capture_stdout {
		App::GHGen::Interactive::prompt_choice(
			'Pick an option:',
			['Option A', 'Option B', 'Option C'],
			1,    # 0-indexed default → "Option B"
		);
	};

	my @arrow_lines = grep { /→/ } split /\n/, $out;
	is(scalar @arrow_lines, 1, 'exactly one displayed line has the arrow marker');
	like($arrow_lines[0], qr/2\.\s*Option B/,
		'arrow is on choice 2 (Option B), not 1 or 3');
	diag("marked line: $arrow_lines[0]") if $ENV{TEST_VERBOSE};
};

########################################################################
# SECTION 7 — Interactive::prompt_choice line 188
#   Source:  return $answer - 1 if $answer =~ /^\d+$/ && $answer >= 1 && $answer <= @$choices;
#   Mutant:  NUM_BOUNDARY_188_57_> (HIGH)
#   Mutations: >= → >, >= → <, >= → <=   AND   <= → <, <= → >, <= → >=
#
#   Four boundary probes kill all six variants:
#     answer=1: lower inclusive; >= → > rejects → returns default.
#     answer=0: below lower; >= → <= accepts → returns -1 instead of default.
#     answer=3: upper inclusive (N=3 choices); <= → < rejects → returns default.
#     answer=4: above upper; <= → >= accepts → returns 3 instead of default.
########################################################################

Readonly::Scalar my $CHOICES  => ['Alpha', 'Beta', 'Gamma'];  # 3 choices
Readonly::Scalar my $DEF_IDX  => 1;                           # 0-indexed default = Beta

# Helper: redirect STDIN to $answer\n, call prompt_choice, return result.
sub _prompt($answer) {
	open(local *STDIN, '<', \"$answer\n") or die "Cannot redirect STDIN: $!";
	return App::GHGen::Interactive::prompt_choice('Pick:', $CHOICES, $DEF_IDX);
}

subtest 'NUM_BOUNDARY_188_57_> — answer=1 returns 0 (kills >= → > mutation)' => sub {
	# >= 1: answer=1 valid → returns 0. >= → > mutant: 1 > 1 = false → returns default (1).
	is(_prompt(1), 0, 'answer=1 (lower bound): returns index 0');
};

subtest 'NUM_BOUNDARY_188_57_> — answer=0 returns default (kills >= → <= mutation)' => sub {
	# >= 1: 0 >= 1 = false → returns default. >= → <= mutant: 0 <= 1 = true → returns -1.
	is(_prompt(0), $DEF_IDX, 'answer=0 (below lower): returns default index');
};

subtest 'NUM_BOUNDARY_188_57_> — answer=3 returns 2 (kills <= → < mutation)' => sub {
	# <= 3: answer=3 valid → returns 2. <= → < mutant: 3 < 3 = false → returns default (1).
	is(_prompt(3), 2, 'answer=3 (upper bound): returns index 2');
};

subtest 'NUM_BOUNDARY_188_57_> — answer=4 returns default (kills <= → >= mutation)' => sub {
	# <= 3: 4 <= 3 = false → returns default. <= → >= mutant: 4 >= 3 = true → returns 3.
	is(_prompt(4), $DEF_IDX, 'answer=4 (above upper): returns default index');
};

########################################################################
# SECTION 8 — Reporter::generate_markdown_report line 136
#   Source:  if ($savings->{cost} > 0) {
#   Mutants: NUM_BOUNDARY_136_30_< (HIGH) — > to <, >=, <=, if to unless
#
#   Reporter::estimate_savings rates:
#     performance/caching → 500 min → cost = int(500*0.008) = 4  (> 0)
#     cost/concurrency    →  50 min → cost = int( 50*0.008) = 0  (NOT > 0)
########################################################################

subtest 'NUM_BOUNDARY_136_30_< — cost line present when cost=4 (kills < and unless mutants)' => sub {
	# Caching issue: cost=4 > 0 → cost line included.
	# < mutant: 4 < 0 → false → excluded.  unless mutant: condition true → unless false → excluded.
	my $report = generate_markdown_report([$CACHING_ISSUE]);
	like($report, qr/private repos/,
		'cost > 0 (=4): private-repos cost line present in markdown report');
	diag(substr($report, -200)) if $ENV{TEST_VERBOSE};
};

subtest 'NUM_BOUNDARY_136_30_< — cost line absent when cost=0 (kills >= mutant)' => sub {
	# Concurrency issue: minutes=50 > 0 (savings section shown), but cost=0 → cost line absent.
	# >= mutant: 0 >= 0 = true → includes cost line (wrong).
	my $report = generate_markdown_report([$CONCURRENCY_ISSUE]);
	like($report,   qr/💰 Estimated Savings/, 'minutes section present (50 > 0)');
	unlike($report, qr/private repos/,
		'cost=0: private-repos cost line absent from markdown report');
};

########################################################################
# SECTION 9 — Reporter::generate_github_comment lines 291 and 296
#   Line 291: if ($savings->{minutes} > 0) {
#   Mutants:  NUM_BOUNDARY_291_29_< (HIGH) — > to <, >=, <=
#
#   Line 296: if ($savings->{cost} > 0) {
#   Mutants:  NUM_BOUNDARY_296_30_< (HIGH) — > to <, >=, <=, if to unless
#
#   A security issue produces 0 savings but is still an issue (avoids the
#   early-return for |issues|=0 so execution reaches lines 291/296).
########################################################################

subtest 'NUM_BOUNDARY_291_29_< — no savings section when minutes=0 (kills >= mutant)' => sub {
	# Security issue → 0 minutes. Real: 0 not > 0 → savings block skipped.
	# >= mutant: 0 >= 0 → savings block shown (wrong).
	my $comment = generate_github_comment([$SECURITY_ISSUE]);
	unlike($comment, qr/Potential Savings/,
		'minutes=0 (security issue): no Potential Savings section');
};

subtest 'NUM_BOUNDARY_291_29_< — savings section present when minutes=500 (kills < and <= mutants)' => sub {
	# Caching issue → 500 minutes > 0 → savings block shown.
	# < or <= mutant: 500 < 0 or 500 <= 0 → false → block hidden (wrong).
	my $comment = generate_github_comment([$CACHING_ISSUE]);
	like($comment, qr/Potential Savings/,
		'minutes=500 (caching): Potential Savings section present');
};

subtest 'NUM_BOUNDARY_296_30_< — cost line present when cost=4 (kills < and unless mutants at line 296)' => sub {
	# Caching issue: cost = int(500*0.008) = 4 > 0 → cost line included.
	my $comment = generate_github_comment([$CACHING_ISSUE]);
	like($comment, qr/private repos/,
		'cost > 0 (=4): private-repos cost line present in github comment');
};

subtest 'NUM_BOUNDARY_296_30_< — cost line absent when cost=0 (kills >= mutant at line 296)' => sub {
	# Concurrency issue: cost=0. Real: 0 not > 0 → cost line absent.
	# >= mutant: 0 >= 0 → cost line included (wrong).
	my $comment = generate_github_comment([$CONCURRENCY_ISSUE]);
	like($comment,   qr/Potential Savings/, 'minutes section present (50 > 0)');
	unlike($comment, qr/private repos/,
		'cost=0 (concurrency): no private-repos cost line in github comment');
};

restore_all();
done_testing();
