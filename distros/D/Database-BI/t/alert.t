#!/usr/bin/env perl
# t/alert.t -- Phase 4.3: bi-alert CLI tests

use strict;
use warnings;

use lib 'lib';

use File::Spec;
use File::Temp	qw(tempdir);
use Mojo::File;
use Mojo::JSON	qw(encode_json decode_json);
use Test::More;

# ---------------------------------------------------------------------------
# Locate the script
# ---------------------------------------------------------------------------

my $script = File::Spec->catfile('script', 'bi-alert');
plan skip_all => 'script/bi-alert not found' unless -f $script && -x $script;
plan skip_all => 'data/sales.csv not found'  unless -f 'data/sales.csv';

my $perl = $^X;

# ---------------------------------------------------------------------------
# Helper: run bi-alert and capture output + exit code
# ---------------------------------------------------------------------------

# The script is started with its arguments as arguments rather than through a
# shell command line, and its STDERR is merged into the pipe by hand.  A
# --notify-cmd value is shell text of its own (quotes, redirections, semicolons),
# so passing it through a shell here would have the test's shell parse it first
# and run the delivery instead of the script.
sub run_alert {
	my (@args) = @_;

	pipe(my $rd, my $wr) or die "pipe: $!";
	my $pid = fork;
	die "fork: $!" unless defined $pid;

	unless ($pid) {
		close $rd;
		open(STDOUT, '>&', $wr) or exit 127;
		open(STDERR, '>&', $wr) or exit 127;
		close $wr;
		exec($perl, $script, @args);
		exit 127;
	}

	close $wr;
	my $out = do { local $/; <$rd> } // '';
	close $rd;
	waitpid($pid, 0);

	return ($out, $? >> 8);
}

# The throttle is a period of time, so a test that had to wait it out would
# either be slow or flaky.  BI_ALERT_NOW replaces the clock for the child
# process instead, which is also how the boundary at the end of a period gets
# tested exactly rather than approximately.
sub run_alert_at {
	my ($now, @args) = @_;
	local $ENV{BI_ALERT_NOW} = $now;
	return run_alert(@args);
}

# ---------------------------------------------------------------------------
# Prepare a model_dir with a minimal saved analysis pointing at sales.csv
# ---------------------------------------------------------------------------

my $model_dir = tempdir(CLEANUP => 1);
my $data_dir  = File::Spec->rel2abs('data');

my $analysis = {
	id       => 'testalert1',
	name     => 'Alert test analysis',
	version  => 1,
	created  => time(),
	updated  => time(),
	datasets => [ { spec => "path:$data_dir/sales.csv" } ],
	visuals  => [],
};

my $analyses = { $analysis->{id} => $analysis };

# ---------------------------------------------------------------------------
# A second analysis, on a file this test owns and rewrites, so that one
# threshold can be seen crossed and then not crossed.  data/sales.csv is shared
# test data and must not be modified to make an alert stop firing.
# ---------------------------------------------------------------------------

my $clear_dir  = tempdir(CLEANUP => 1);
my $clear_csv  = File::Spec->catfile($clear_dir, 'rows.csv');
my $rows_four  = "region,amount\nNorth,10\nSouth,20\nEast,30\nWest,40\n";
my $rows_three = "region,amount\nNorth,10\nSouth,20\nEast,30\n";
Mojo::File->new($clear_csv)->spurt($rows_four);

my $clear_id = 'clearable';
$analyses->{$clear_id} = {
	id       => $clear_id,
	name     => 'Clearable analysis',
	version  => 1,
	created  => time(),
	updated  => time(),
	datasets => [ { spec => "path:$clear_csv" } ],
	visuals  => [],
};

Mojo::File->new($model_dir, 'analyses.json')->spurt(encode_json($analyses));

my $id = $analysis->{id};

# ---------------------------------------------------------------------------
# 1. --help exits 0 and prints usage
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert('--help');
	is($code, 0, '--help exits 0');
	like($out, qr/--analysis/i, '--help mentions --analysis');
}

# ---------------------------------------------------------------------------
# 2. Missing --analysis exits 2
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert('--model-dir', $model_dir, '--data-dir', $data_dir);
	is($code, 2, 'missing --analysis exits 2');
}

# ---------------------------------------------------------------------------
# 3. Unknown analysis id exits 2
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir,
		'--data-dir',  $data_dir,
		'--analysis',  'nosuchid',
		'--dry-run',
	);
	is($code, 2, 'unknown analysis id exits 2');
}

# ---------------------------------------------------------------------------
# 4. --dry-run prints a digest and exits 0 (no threshold) or 1 (threshold crossed)
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir,
		'--data-dir',  $data_dir,
		'--analysis',  $id,
		'--dry-run',
	);
	ok($code == 0 || $code == 1, "--dry-run exits 0 or 1 (got $code)");
	like($out, qr/\S/, '--dry-run produces output');
}

# ---------------------------------------------------------------------------
# 5. --dry-run with a threshold certainly crossed (count > 0; sales.csv has rows)
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir,
		'--data-dir',  $data_dir,
		'--analysis',  $id,
		'--threshold', 'count:gt:0',
		'--dry-run',
	);
	is($code, 1, '--dry-run with crossed threshold (count > 0) exits 1');
}

# ---------------------------------------------------------------------------
# 6. --dry-run with a threshold certainly NOT crossed (count > 1 000 000)
# ---------------------------------------------------------------------------

{
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir,
		'--data-dir',  $data_dir,
		'--analysis',  $id,
		'--threshold', 'count:gt:1000000',
		'--dry-run',
	);
	is($code, 0, '--dry-run with uncrossed threshold (count > 1M) exits 0');
}

# ---------------------------------------------------------------------------
# 7. --suppress: a crossing that stays crossed is announced once per period
# ---------------------------------------------------------------------------

# The state file is named explicitly here, so the test can read what the
# throttle remembered rather than guess at the default location.
my $state_file = File::Spec->catfile($model_dir, 'throttle.json');
my @throttled  = (
	'--model-dir', $model_dir,
	'--data-dir',  $data_dir,
	'--analysis',  $id,
	'--threshold', 'count:gt:0',
	'--suppress',  '1h',
	'--state-file', $state_file,
);

my $key = $id . '|count:gt:0';
my $at  = 1_800_000_000;

sub state_of {
	my $path = shift;
	return () unless -f $path;
	my $state = eval { decode_json(Mojo::File->new($path)->slurp) };
	return ref $state eq 'HASH' ? $state : ();
}

{
	my ($out, $code) = run_alert_at($at, @throttled);
	is($code, 1, 'the first crossing is announced');
	like($out, qr/THRESHOLD CROSSED/, 'and says so in the digest');
	like($out, qr/suppressed for 1h/, 'and says how long repeats wait');
	ok(-f $state_file, 'the throttle keeps its memory in the state file');

	my $state = state_of($state_file);
	is($state->{alerts}{$key}{last_alert}, $at, 'recording when the alert was announced');
	is($state->{alerts}{$key}{since},      $at, 'and since when the threshold has been crossed');
	ok(($state->{alerts}{$key}{value} // 0) > 0, 'and the value it was announced with');
}

{
	my ($out, $code) = run_alert_at($at + 600, @throttled);
	is($code, 0, 'a repeat ten minutes later exits 0: nothing is announced');
	like($out, qr/THRESHOLD SUPPRESSED/, 'the run says the alert is suppressed');
	unlike($out, qr/THRESHOLD CROSSED/, 'and emits no alert line for a wrapper to key on');
	like($out, qr/next alert after/, 'and says when it will speak again');

	is(state_of($state_file)->{alerts}{$key}{last_alert}, $at,
		'a suppressed run does not move the recorded alert time on');
}

{
	# The boundary itself: elapsed time is compared with the period, so at
	# exactly one hour the crossing is news again.
	my ($out, $code) = run_alert_at($at + 3_600, @throttled);
	is($code, 1, 'the period is over at its end, not a second after it');
	like($out, qr/THRESHOLD CROSSED/, 'and the crossing is announced again');

	my $state = state_of($state_file);
	is($state->{alerts}{$key}{last_alert}, $at + 3_600, 'with the new alert time recorded');
	is($state->{alerts}{$key}{since}, $at,
		'while one continuous crossing is still dated from where it started');
}

{
	# A second threshold is a second alert, whatever the first one is doing.
	my ($out, $code) = run_alert_at($at + 3_600,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $id,
		'--threshold', 'count:gt:1', '--suppress', '1h', '--state-file', $state_file);
	is($code, 1, 'another threshold on the same analysis is throttled separately');
	like($out, qr/THRESHOLD CROSSED/, 'and is announced while the first is inside its period');
}

# ---------------------------------------------------------------------------
# 8. --suppress: a crossing that ends is forgotten, so the next one is news
# ---------------------------------------------------------------------------

{
	my @throttled = (
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--suppress', '1h', '--state-file', $state_file,
	);
	my $key = $clear_id . '|count:gt:3';

	my ($out, $code) = run_alert_at($at, @throttled);
	is($code, 1, 'four rows cross count > 3');
	ok(-f $state_file && state_of($state_file)->{alerts}{$key}, 'and the crossing is remembered');

	# The same threshold, the same analysis, three rows: no longer crossed.
	Mojo::File->new($clear_csv)->spurt($rows_three);
	($out, $code) = run_alert_at($at + 60, @throttled);
	is($code, 0, 'three rows do not cross it');
	like($out, qr/THRESHOLD CLEARED/, 'and the run says the crossing has ended');
	ok(!state_of($state_file)->{alerts}{$key}, 'the entry is dropped from the state file');

	# Which is what makes the next crossing alert straight away, rather than
	# sitting out a period that belonged to an incident that is over.
	Mojo::File->new($clear_csv)->spurt($rows_four);
	($out, $code) = run_alert_at($at + 120, @throttled);
	is($code, 1, 'so the next crossing is announced at once, inside the period');
	like($out, qr/THRESHOLD CROSSED/, 'as a fresh alert');
	is(state_of($state_file)->{alerts}{$key}{since}, $at + 120,
		'and is dated from where this crossing started, not the last one');
}

# ---------------------------------------------------------------------------
# 9. --suppress: what is not throttled, and what does not throttle
# ---------------------------------------------------------------------------

{
	my $untouched = File::Spec->catfile($model_dir, 'alerts-state.json');
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $id,
		'--threshold', 'count:gt:0');
	is($code, 1, 'without --suppress every crossing is announced');
	ok(!-f $untouched, 'and no state file is created: the script is stateless unless asked');
}

{
	my $zero = File::Spec->catfile($model_dir, 'zero.json');
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $id,
		'--threshold', 'count:gt:0', '--suppress', '0', '--state-file', $zero);
	is($code, 1, 'a period of zero means no throttling');
	ok(!-f $zero, 'and keeps no state either');
}

{
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $id,
		'--threshold', 'count:gt:0', '--suppress', 'banana');
	is($code, 2, 'an unreadable period is an error, not a silent default');
	like($out, qr/--suppress must be a duration/, 'and the message names the option');
}

{
	# A dry run reports, and is expected not to count: recording it would use up
	# the alert a later real run depends on.
	my $dry = File::Spec->catfile($model_dir, 'dry.json');
	my @args = (
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $id,
		'--threshold', 'count:gt:0', '--suppress', '1h', '--state-file', $dry, '--dry-run',
	);

	my ($out, $code) = run_alert_at($at, @args);
	is($code, 1, 'a dry run still reports a crossed threshold');
	ok(!-f $dry, 'but records nothing against the throttle');

	($out, $code) = run_alert_at($at, @args[0 .. $#args - 1]);
	is($code, 1, 'so the next real run, at the same moment, still announces it');
	like($out, qr/THRESHOLD CROSSED/, 'as an alert rather than a suppressed repeat');
}

# ---------------------------------------------------------------------------
# 10. --suppress: a damaged state file costs a repeat, never a silence
# ---------------------------------------------------------------------------

{
	my $damaged = File::Spec->catfile($model_dir, 'damaged.json');
	Mojo::File->new($damaged)->spurt("not a state file\n");

	my ($out, $code) = run_alert_at($at,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $id,
		'--threshold', 'count:gt:0', '--suppress', '1h', '--state-file', $damaged);
	is($code, 1, 'an unreadable state file still lets the alert through');
	like($out, qr/THRESHOLD CROSSED/, 'the alert is announced');
	like($out, qr/not a throttle state file/, 'and the state file is reported as unusable');

	my $state = state_of($damaged);
	ok(ref $state eq 'HASH' && ref $state->{alerts} eq 'HASH',
		'and a readable state file replaces it');
	ok($state->{alerts}{$key}, 'holding this alert');

	# And it is a throttle again from then on.
	($out, $code) = run_alert_at($at + 60,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $id,
		'--threshold', 'count:gt:0', '--suppress', '1h', '--state-file', $damaged);
	is($code, 0, 'so the next run inside the period is suppressed');
	like($out, qr/THRESHOLD SUPPRESSED/, 'as a suppressed repeat');
}	# ---------------------------------------------------------------------------
# 11. --recovery: the end of a crossing is announced, once, as exit 3
# ---------------------------------------------------------------------------

{
	my $rec_state = File::Spec->catfile($model_dir, 'recovery.json');
	my $key       = $clear_id . '|count:gt:3';
	my @recovery  = (
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--suppress', '1h',
		'--state-file', $rec_state, '--recovery',
	);

	Mojo::File->new($clear_csv)->spurt($rows_four);
	my ($out, $code) = run_alert_at($at, @recovery);
	is($code, 1, '--recovery announces the crossing first, as an alert');
	like($out, qr/THRESHOLD CROSSED/, 'with the alert line');
	unlike($out, qr/THRESHOLD RECOVERED/, 'and no recovery while the crossing stands');

	# Still crossed and inside the period: quiet.  A suppressed repeat must not
	# read as a recovery, which is why the recorded entry is what decides.
	($out, $code) = run_alert_at($at + 600, @recovery);
	is($code, 0, 'a suppressed repeat is quiet');
	like($out, qr/THRESHOLD SUPPRESSED/, 'as a suppressed repeat');
	unlike($out, qr/THRESHOLD RECOVERED/, 'and is not a recovery');

	Mojo::File->new($clear_csv)->spurt($rows_three);
	($out, $code) = run_alert_at($at + 900, @recovery);
	is($code, 3, 'the end of the crossing exits 3, so a wrapper can mail the all-clear');
	like($out, qr/THRESHOLD RECOVERED/, 'and says the threshold has recovered');
	like($out, qr/crossed since \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/,
		'naming when the crossing began');
	like($out, qr/cleared \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/, 'and when it ended');
	ok(!state_of($rec_state)->{alerts}{$key},
		'the entry is dropped, so the next crossing alerts at once as before');

	# Which is also why it is said once: nothing remembers a crossing that is
	# over, so the next run over the same uncrossed data has nothing to report.
	($out, $code) = run_alert_at($at + 1_200, @recovery);
	is($code, 0, 'the recovery is not repeated on the next run');
	unlike($out, qr/THRESHOLD RECOVERED/, 'because nothing remembers a crossing that is over');
}

# ---------------------------------------------------------------------------
# 12. --recovery: what it needs, and what it refuses to invent
# ---------------------------------------------------------------------------

{
	# A threshold nobody was told about cannot have recovered from anything: with
	# no crossing recorded there is no entry, so there is no incident to end.
	my $never = File::Spec->catfile($model_dir, 'recovery-never.json');
	Mojo::File->new($clear_csv)->spurt($rows_three);

	my ($out, $code) = run_alert_at($at,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--state-file', $never, '--recovery');
	is($code, 0, 'an uncrossed threshold recovers nothing');
	unlike($out, qr/THRESHOLD RECOVERED/, 'no recovery without a crossing to have ended');
	ok(!-f $never, 'and no state file is written for a threshold that never crossed');
}

{
	# --recovery keeps the state file by itself: the entry is the record of the
	# crossing, and without it the end of one cannot be detected at all.  No
	# --suppress here, so every crossing is announced exactly as it always was.
	my $plain = File::Spec->catfile($model_dir, 'recovery-no-suppress.json');
	my @plain = (
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--state-file', $plain, '--recovery',
	);

	Mojo::File->new($clear_csv)->spurt($rows_four);
	my ($out, $code) = run_alert_at($at, @plain);
	is($code, 1, 'without --suppress a crossing is announced as it always was');
	ok(-f $plain, 'but --recovery alone keeps the state a recovery needs');

	Mojo::File->new($clear_csv)->spurt($rows_three);
	($out, $code) = run_alert_at($at + 60, @plain);
	is($code, 3, 'and the end of that crossing is announced too');
	like($out, qr/THRESHOLD RECOVERED/, 'as a recovery');
}

{
	# A rehearsal reports the recovery it would announce and leaves the crossing
	# on record, so running one cannot use up the all-clear a later real run
	# depends on: the same rule the throttle's own --dry-run test states.
	my $dry  = File::Spec->catfile($model_dir, 'recovery-dry.json');
	my $key  = $clear_id . '|count:gt:3';
	my @args = (
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--state-file', $dry, '--recovery',
	);

	Mojo::File->new($clear_csv)->spurt($rows_four);
	run_alert_at($at, @args);
	Mojo::File->new($clear_csv)->spurt($rows_three);

	my ($out, $code) = run_alert_at($at + 60, @args, '--dry-run');
	is($code, 3, 'a dry run reports the recovery it would announce');
	like($out, qr/THRESHOLD RECOVERED/, 'in the same words');
	ok(state_of($dry)->{alerts}{$key}, 'and leaves the crossing on record');

	($out, $code) = run_alert_at($at + 60, @args);
	is($code, 3, 'so the real run announces it');
	like($out, qr/THRESHOLD RECOVERED/, 'as the recovery');
	ok(!state_of($dry)->{alerts}{$key}, 'and only then drops the entry');
}

{
	# Without --recovery the ending is reported exactly as it always was: the
	# option adds a notification, it does not change what the default says.
	my $def  = File::Spec->catfile($model_dir, 'no-recovery.json');
	my @args = (
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--suppress', '1h', '--state-file', $def,
	);

	Mojo::File->new($clear_csv)->spurt($rows_four);
	run_alert_at($at, @args);
	Mojo::File->new($clear_csv)->spurt($rows_three);

	my ($out, $code) = run_alert_at($at + 60, @args);
	is($code, 0, 'without --recovery the end of a crossing still exits 0');
	like($out, qr/THRESHOLD CLEARED/, 'and is reported as a clear');
	unlike($out, qr/THRESHOLD RECOVERED/, 'not as a recovery');
}

# ---------------------------------------------------------------------------
# 13. --notify-cmd: the run does its own delivery, and only when it has
#     something to say
# ---------------------------------------------------------------------------

sub file_text {
	my $path = shift;
	return '' unless -f $path;
	return Mojo::File->new($path)->slurp;
}

# --notify-cmd is shell text: bi-alert hands it to /bin/sh on Unix and to
# cmd.exe on Windows, so the recorder used below is a POSIX shell script.
# Reading the environment, copying STDIN to a file and appending one byte have
# no one-line equivalent in cmd.exe, and a batch recorder would be a second
# implementation this test cannot run where it is written -- so Windows skips
# those subtests with this reason rather than failing on them.  "exit 7" is a
# builtin in both shells, which is why the failure path is asserted there.
my $RECORDER_SKIP = '--notify-cmd is shell text for /bin/sh; cmd.exe has no'
	. ' equivalent one-liner, so the shell recorder is not run here';

# The failure path needs no recorder: a command both shells read the same way
# is enough.  Asserted on every platform, so Windows still checks that a
# delivery that fails is reported and stops the crossing being recorded.
subtest 'a delivery that fails is reported and records nothing' => sub {
	my $dir   = tempdir(CLEANUP => 1);
	my $state = File::Spec->catfile($dir, 'retry.json');

	Mojo::File->new($clear_csv)->spurt($rows_four);

	my ($out, $code) = run_alert_at($at,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--suppress', '1h', '--state-file', $state,
		'--notify-cmd', 'exit 7');

	is($code, 1, 'a failed delivery leaves the exit status alone');
	like($out, qr/--notify-cmd failed \(exit 7\)/, 'and says the command failed');
	like($out, qr/not recorded/, 'and says the crossing was not recorded');
	ok(!-f $state, 'so no state file is written');
};

subtest 'notify-cmd records what the run hands it' => sub {
	plan skip_all => $RECORDER_SKIP if $^O eq 'MSWin32';

	my $dir   = tempdir(CLEANUP => 1);
	my $body  = File::Spec->catfile($dir, 'message.txt');
	my $env   = File::Spec->catfile($dir, 'env.txt');
	my $calls = File::Spec->catfile($dir, 'calls.txt');
	my $state = File::Spec->catfile($dir, 'state.json');

	# The command records what it was given -- the two variables, the run's text
	# from STDIN, and one byte per invocation, so the test can count deliveries
	# rather than infer them.  One printenv per name: macOS's takes a single
	# name, so asking it for two there records only the first and the subject
	# looks unset.  A variable that really is missing still leaves no line.
	my $cmd = qq{printenv BI_ALERT_EVENT > '$env'; }
		. qq{printenv BI_ALERT_SUBJECT >> '$env'; }
		. qq{cat > '$body'; printf x >> '$calls'; echo child-stdout};

	my @args = (
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--suppress', '1h', '--state-file', $state,
		'--notify-cmd', $cmd,
	);
	my $key = $clear_id . '|count:gt:3';

	Mojo::File->new($clear_csv)->spurt($rows_four);

	my ($out, $code) = run_alert_at($at, @args);
	is($code, 1, 'a crossing with --notify-cmd still exits 1');
	like($out, qr/^Analysis: /m, 'and prints the digest it always printed');
	like($out, qr/THRESHOLD CROSSED: count \(4\) gt 3/, 'and the verdict');

	my @env = split /\n/, file_text($env);
	is($env[0], 'crossed', 'the command is told this is a crossing');
	is($env[1], 'THRESHOLD CROSSED: count (4) gt 3',
		'and is handed the verdict line as a subject');
	like(file_text($body), qr/^Analysis: /m, 'the run text arrives on STDIN');
	like(file_text($body), qr/THRESHOLD CROSSED/, 'through to and including the verdict');
	like($out, qr/child-stdout/, 'the command\'s own output goes to STDOUT');
	unlike(file_text($body), qr/child-stdout/, 'and not into the text it was handed');
	is(file_text($calls), 'x', 'the command ran exactly once');
	ok(state_of($state)->{alerts}{$key}, 'and the delivered crossing is on record');

	# Nothing to announce, nothing delivered: a repeat inside the period.
	($out, $code) = run_alert_at($at + 600, @args);
	is($code, 0, 'a suppressed repeat is quiet');
	like($out, qr/THRESHOLD SUPPRESSED/, 'and says it is suppressed');
	is(file_text($calls), 'x', 'and delivers nothing');

	# Nor for a threshold that is not crossed at all.
	($out, $code) = run_alert_at($at + 600,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:99', '--state-file', $state, '--notify-cmd', $cmd);
	is($code, 0, 'an uncrossed threshold with --notify-cmd exits 0');
	is(file_text($calls), 'x', 'and delivers nothing either');

	# A rehearsal says what it would run, and runs nothing.
	my $dry_state = File::Spec->catfile($dir, 'dry.json');
	($out, $code) = run_alert_at($at,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--state-file', $dry_state,
		'--notify-cmd', $cmd, '--dry-run');
	is($code, 1, 'a dry run still reports the crossing');
	like($out, qr/Notify: would run/, 'and says what it would have run');
	is(file_text($calls), 'x', 'but runs nothing');

	# A failed delivery leaves the crossing unrecorded, so the next run announces
	# it again rather than the alert being lost for the whole period.  How the
	# failure reads is asserted above, on every platform; what is checked here is
	# the delivery that follows it.
	my $retry_state = File::Spec->catfile($dir, 'retry.json');
	my @retry = (
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--suppress', '1h', '--state-file', $retry_state,
	);
	($out, $code) = run_alert_at($at, @retry, '--notify-cmd', 'exit 7');
	ok(!-f $retry_state, 'a failed delivery records nothing to suppress the next run');

	($out, $code) = run_alert_at($at, @retry, '--notify-cmd', $cmd);
	is($code, 1, 'which is what lets the next run deliver it');
	is(file_text($calls), 'xx', 'as a second delivery');
	ok(state_of($retry_state)->{alerts}{$key}, 'and only then is it on record');

	# The recovery goes out the same way, saying which it is.
	Mojo::File->new($clear_csv)->spurt($rows_three);
	($out, $code) = run_alert_at($at + 60,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--suppress', '1h', '--state-file', $state,
		'--recovery', '--notify-cmd', $cmd);
	is($code, 3, 'the recovery is delivered as well as printed');
	@env = split /\n/, file_text($env);
	is($env[0], 'recovery', 'the command is told this is a recovery');
	like($env[1], qr/\ATHRESHOLD RECOVERED: count \(3\) gt 3/, 'with the verdict as its subject');
	like(file_text($body), qr/THRESHOLD RECOVERED/, 'and the text carries the recovery');
	is(file_text($calls), 'xxx', 'delivered once, as the crossing was');
};

{
	# An empty command is a mistake, not a way of saying "deliver nowhere".
	my ($out, $code) = run_alert(
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--notify-cmd', '   ');
	is($code, 2, 'an empty --notify-cmd exits 2');
	like($out, qr/--notify-cmd must name a command/, 'and the message names the option');
}

# ---------------------------------------------------------------------------
# 14. Several checks in one run: each is reported, throttled and recovered on
#     its own
# ---------------------------------------------------------------------------

{
	# A second saved analysis on a file of its own, so the two groups in a run
	# hold different numbers and cannot be mistaken for each other.
	my $other_dir = tempdir(CLEANUP => 1);
	my $other_csv = File::Spec->catfile($other_dir, 'other.csv');
	my @other_rows = ("region,amount\n");
	push @other_rows, "R$_,$_\n" for 1 .. 7;
	Mojo::File->new($other_csv)->spurt(join '', @other_rows);

	my $other_id = 'otherops';
	my $store    = decode_json(Mojo::File->new($model_dir, 'analyses.json')->slurp);
	$store->{$other_id} = {
		id       => $other_id,
		name     => 'Other analysis',
		version  => 1,
		created  => time(),
		updated  => time(),
		datasets => [ { spec => "path:$other_csv" } ],
		visuals  => [],
	};
	Mojo::File->new($model_dir, 'analyses.json')->spurt(encode_json($store));

	# 14a. Two analyses, one threshold each, and only one of them crossed.
	my $state = File::Spec->catfile($model_dir, 'many.json');
	my @both = (
		'--model-dir', $model_dir, '--data-dir', $data_dir,
		'--analysis',  $clear_id, '--analysis', $other_id,
		'--threshold', 'count:gt:3',
		'--threshold', "$other_id:count:gt:99",
		'--suppress',  '1h', '--state-file', $state, '--recovery',
	);

	Mojo::File->new($clear_csv)->spurt($rows_four);

	my ($out, $code) = run_alert_at($at, @both);
	is($code, 1, 'a run watching two analyses exits 1 when one crosses');
	like($out, qr/^Analysis: .*? \($clear_id\)$/m, 'both analyses are reported in full');
	like($out, qr/^Analysis: .*? \($other_id\)$/m, 'including the second one');
	like($out, qr/THRESHOLD CROSSED: \[$clear_id\] count \(4\) gt 3/,
		'and the crossing says which analysis it belongs to');
	like($out, qr/Threshold not crossed: \[$other_id\] count \(7\) gt 99/,
		'while the other check says it did not cross');
	is(scalar(() = $out =~ /THRESHOLD CROSSED:/g), 1, 'only one crossing is announced');

	my $saved = state_of($state);
	ok($saved->{alerts}{"$clear_id|count:gt:3"}, 'the crossing is on record under its own key');
	ok(!$saved->{alerts}{"$other_id|count:gt:99"},
		'and a threshold that did not cross records nothing');

	# 14b. Two thresholds on one analysis: neither silences nor recovers the
	# other, because each has its own entry in the state file.
	my $pair = File::Spec->catfile($model_dir, 'pair.json');
	my @pair = (
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:3', '--threshold', 'count:gt:2',
		'--suppress',  '1h', '--state-file', $pair, '--recovery',
	);

	Mojo::File->new($clear_csv)->spurt($rows_four);
	($out, $code) = run_alert_at($at, @pair);
	is($code, 1, 'both thresholds cross four rows');
	is(scalar(() = $out =~ /THRESHOLD CROSSED:/g), 2, 'and both are announced');

	# Three rows: the higher threshold clears, the lower one is still crossed.
	Mojo::File->new($clear_csv)->spurt($rows_three);
	($out, $code) = run_alert_at($at + 60, @pair);
	is($code, 3, 'three rows recover only the higher threshold');
	like($out, qr/THRESHOLD RECOVERED: count \(3\) gt 3/, 'and it is named');
	like($out, qr/THRESHOLD SUPPRESSED: count \(3\) gt 2/,
		'while the one still crossed stays inside its period');
	is(scalar(() = $out =~ /THRESHOLD RECOVERED:/g), 1, 'exactly one recovery is announced');

	$saved = state_of($pair);
	ok(!$saved->{alerts}{"$clear_id|count:gt:3"}, 'the recovered threshold is forgotten');
	ok($saved->{alerts}{"$clear_id|count:gt:2"},
		'and the one that is still crossed keeps its entry');

	($out, $code) = run_alert_at($at + 120, @pair);
	is($code, 0, 'the next run over the same data stays quiet');
	unlike($out, qr/THRESHOLD RECOVERED/, 'and does not recover anything twice');

	# 14c. One run is one delivery, however many checks it announced.
	subtest 'one run is one delivery' => sub {
		plan skip_all => $RECORDER_SKIP if $^O eq 'MSWin32';

		my $dir   = tempdir(CLEANUP => 1);
		my $body  = File::Spec->catfile($dir, 'message.txt');
		my $env   = File::Spec->catfile($dir, 'env.txt');
		my $calls = File::Spec->catfile($dir, 'calls.txt');
		my $cmd   = qq{printenv BI_ALERT_EVENT > '$env'; }
			. qq{printenv BI_ALERT_SUBJECT >> '$env'; }
			. qq{cat > '$body'; printf x >> '$calls'};

		Mojo::File->new($clear_csv)->spurt($rows_four);
		($out, $code) = run_alert_at($at + 120,
			'--model-dir', $model_dir, '--data-dir', $data_dir,
			'--analysis', $clear_id, '--analysis', $other_id,
			'--threshold', 'count:gt:3', '--threshold', "$other_id:count:gt:0",
			'--suppress', '1h', '--state-file', File::Spec->catfile($dir, 'state.json'),
			'--notify-cmd', $cmd);
		is($code, 1, 'a run announcing two crossings exits 1');
		my @env = split /\n/, file_text($env);
		is($env[0], 'crossed', 'the delivery is a crossing');
		is($env[1], '2 threshold crossings', 'and its subject counts both');
		is(file_text($calls), 'x', 'the command ran once for the whole run');
		like(file_text($body), qr/THRESHOLD CROSSED: \[$clear_id\]/,
			'and its text carries both announcements');
		like(file_text($body), qr/THRESHOLD CROSSED: \[$other_id\]/, 'in one message');
	};

	# 14d. A run with one analysis is the run it always was.
	($out, $code) = run_alert_at($at + 120,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:0');
	is($code, 1, 'a single analysis still exits 1 on a crossing');
	like($out, qr/^Analysis: Clearable analysis$/m, 'with the header it always had');
	like($out, qr/^THRESHOLD CROSSED: count \(4\) gt 0$/m,
		'and an unqualified verdict line, so existing greps still match');

	# 14e. Repeating an option is not a request to be told twice.
	($out, $code) = run_alert_at($at + 120,
		'--model-dir', $model_dir, '--data-dir', $data_dir,
		'--analysis', $clear_id, '--analysis', $clear_id,
		'--threshold', 'count:gt:0', '--threshold', 'count:gt:0');
	is($code, 1, 'a repeated analysis and threshold still exit 1');
	is(scalar(() = $out =~ /^Analysis: /gm), 1, 'the analysis is reported once');
	is(scalar(() = $out =~ /THRESHOLD CROSSED:/g), 1, 'and the crossing is announced once');

	# 14f. What a run refuses.
	($out, $code) = run_alert_at($at,
		'--model-dir', $model_dir, '--data-dir', $data_dir,
		'--analysis', $clear_id, '--threshold', "$other_id:count:gt:0");
	is($code, 2, 'a threshold for an analysis not given with --analysis is an error');
	like($out, qr/not given with --analysis/, 'and the message says what is missing');

	($out, $code) = run_alert_at($at,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt:0', '--threshold', 'nosuch:gt:1');
	is($code, 2, 'a bad alias on the second check fails the run');
	like($out, qr/measure alias 'nosuch' not found/, 'naming the alias');

	($out, $code) = run_alert_at($at,
		'--model-dir', $model_dir, '--data-dir', $data_dir, '--analysis', $clear_id,
		'--threshold', 'count:gt');
	is($code, 2, 'a threshold with no value is still an error');
	like($out, qr/<analysis>:<measure>:<op>:<value>/, 'and the message shows both forms');
}

done_testing;

