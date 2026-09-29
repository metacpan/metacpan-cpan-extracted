#!perl

# State transition tests for the two state machines documented under
# =head1 STATE DIAGRAM:
#
#	App::Access2CSV::run          PARSING -> HELP | USAGE ERROR | CHECKING SETTINGS
#	                              CHECKING SETTINGS -> READING STDIN ("-") | OPENING LOG | FATAL
#	                              READING STDIN -> OPENING LOG | FATAL
#	                              OPENING LOG -> EXPORTING | FATAL
#	                              EXPORTING -> return 0 | return 1 | FATAL
#	App::Access2CSV::Exporter     new -> READY -> CHECKING -> LISTING
#	                              LISTING -> DRY RUN | SUMMARY (nothing selected) | PREPARING
#	                              PREPARING -> EXPORTING (per table) -> SUMMARY
#	                              failures -> FATAL; every end -> READY
#
# How states are observed: a Test::Mockingbird "before" hook on the
# method that begins each state appends the state's name to a trace, so a
# run's path through the diagram can be compared with the documented one.
#
# Set TEST_VERBOSE=1 to see each trace.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'uses Unix stand-in programs') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Test::Mockingbird;

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

use App::Access2CSV;

# The hooks call the private methods from Test::Mockingbird's package
$Sub::Private::BYPASS = 1;
$Sub::Protected::BYPASS = 1;

delete @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)};

Readonly::Hash my %CONFIG => (
	app          => 'App::Access2CSV',
	exporter     => 'App::Access2CSV::Exporter',
	exit_ok      => 0,
	exit_failure => 1,
	exit_usage   => 2,
	exit_fatal   => 3,
);

# State names, as in the diagrams
Readonly::Hash my %S => (
	parsing   => 'PARSING',
	settings  => 'CHECKING SETTINGS',
	stdin     => 'READING STDIN',
	help      => 'HELP',
	usage     => 'USAGE ERROR',
	open_log  => 'OPENING LOG',
	exporting => 'EXPORTING',
	fatal     => 'FATAL',
	ready     => 'READY',
	checking  => 'CHECKING',
	listing   => 'LISTING',
	dry_run   => 'DRY RUN',
	preparing => 'PREPARING',
	table     => 'EXPORTING',
	summary   => 'SUMMARY',
);

local $ENV{PATH} = join(':', install_fake_mdbtools(), $ENV{PATH});

my @TRACE;

sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

# trace_exporter(): record the Exporter's states as they are entered
sub trace_exporter {
	@TRACE = ();
	my $e = $CONFIG{exporter};
	before("${e}::_check_database",  sub { push @TRACE, $S{checking} });
	before("${e}::_get_tables",      sub { push @TRACE, $S{listing} });
	before("${e}::_dry_run",         sub { push @TRACE, $S{dry_run} });
	before("${e}::_make_output_dir", sub { push @TRACE, $S{preparing} });
	before("${e}::_export_table",    sub { push @TRACE, $S{table} });
	before("${e}::_log",             sub { push @TRACE, $S{summary} if $_[2] eq 'summary' });
	return;
}

# trace_app(): record the command-line program's states
sub trace_app {
	@TRACE = ();
	my $a = $CONFIG{app};
	before("${a}::_parse_options", sub { push @TRACE, $S{parsing} });
	before("${a}::_usage",         sub { push @TRACE, $_[1] == $CONFIG{exit_ok} ? $S{help} : $S{usage} });
	# Exporter->new is called twice (to check, then to build); the state
	# is entered once
	before("$CONFIG{exporter}::new", sub { push @TRACE, $S{settings} unless grep { $_ eq $S{settings} } @TRACE });
	before("${a}::_read_stdin",    sub { push @TRACE, $S{stdin} });
	before("${a}::_make_logger",   sub { push @TRACE, $S{open_log} if length($_[1]{log} // '') });
	before("$CONFIG{exporter}::run", sub { push @TRACE, $S{exporting} });
	before("${a}::_report_fatal",  sub { push @TRACE, $S{fatal} });
	return;
}

# A logger that keeps the info messages, to check what was logged
{
	package Local::Recorder;
	sub new { return bless { info => [] }, shift }
	sub info { push @{ $_[0]{info} }, $_[1]; return }
	sub debug { return }
	sub warn { return }
}

# Run an exporter; returns (status or undef, error, stdout, stderr)
sub run_exporter {
	my ($e, $db) = @_;
	my ($status, $error);
	my ($stdout, $stderr) = capture { $status = eval { $e->run($db) }; $error = $@ };
	return ($status, $error, $stdout, $stderr);
}

sub cli {
	my @argv = @_;
	my $status;
	my ($stdout, $stderr) = capture { local $SIG{__WARN__} = sub { }; $status = $CONFIG{app}->run(@argv) };
	return ($status, $stdout, $stderr);
}

sub new_database {
	my $dir = tempdir(CLEANUP => 1);
	return ($dir, make_database($dir, @_));
}

#######################################################################
# App::Access2CSV::run
#######################################################################

subtest 'State: PARSING -> Trigger: --help / --man -> State: HELP -> return 0' => sub {
	foreach my $option ('--help', '--man') {
		trace_app();
		my ($status, $stdout, $stderr) = cli($option);
		is_deeply(\@TRACE, [$S{parsing}, $S{help}], "$option: path");
		is($status, $CONFIG{exit_ok}, "$option: return 0");
		ok(length($stdout) && !length($stderr), "$option: action - documentation to STDOUT");
		restore_all();
	}
};

subtest 'State: PARSING -> Trigger: bad option / missing value / not one database -> State: USAGE ERROR -> return 2' => sub {
	my %triggers = ('bad option' => ['--bogus', 'db'], 'missing value' => ['--log'], 'no database' => [], 'two databases' => ['a', 'b']);
	foreach my $trigger (sort keys %triggers) {
		trace_app();
		my ($status, $stdout, $stderr) = cli(@{ $triggers{$trigger} });
		is_deeply(\@TRACE, [$S{parsing}, $S{usage}], "$trigger: path (never opens the log)");
		is($status, $CONFIG{exit_usage}, "$trigger: return 2");
		ok(!length($stdout) && length($stderr), "$trigger: action - usage to STDERR");
		restore_all();
	}
};

subtest 'State: PARSING -> CHECKING SETTINGS -> Trigger: valid -> State: OPENING LOG -> Trigger: log writable -> State: EXPORTING -> return 0' => sub {
	my ($dir, $db) = new_database('T');
	trace_app();
	my ($status) = cli('--log', "$dir/x.log", '--output-dir', "$dir/out", $db);
	verbose_diag('trace', \@TRACE);
	is_deeply(\@TRACE, [$S{parsing}, $S{settings}, $S{open_log}, $S{exporting}], 'path');
	is($status, $CONFIG{exit_ok}, 'all tables OK: return 0');
	ok(-e "$dir/x.log", 'log opened');
	restore_all();
};

subtest 'State: CHECKING SETTINGS -> Trigger: --no-log -> (OPENING LOG skipped) -> State: EXPORTING' => sub {
	my ($dir, $db) = new_database('T');
	trace_app();
	my ($status) = cli('--no-log', '--dry-run', $db);
	is_deeply(\@TRACE, [$S{parsing}, $S{settings}, $S{exporting}], 'OPENING LOG skipped');
	is($status, $CONFIG{exit_ok}, 'dry run: return 0');
	restore_all();
};

subtest 'State: EXPORTING -> Trigger: some table failed -> return 1' => sub {
	my ($dir, $db) = new_database('T', 'Broken');
	trace_app();
	my ($status) = cli('--no-log', '--no-progress', '--output-dir', "$dir/out", $db);
	is_deeply(\@TRACE, [$S{parsing}, $S{settings}, $S{exporting}], 'path');
	is($status, $CONFIG{exit_failure}, 'return 1');
	restore_all();
};

subtest 'State: OPENING LOG -> Trigger: log cannot be opened -> State: FATAL -> return 3' => sub {
	my ($dir, $db) = new_database('T');
	trace_app();
	my ($status, undef, $stderr) = cli('--log', "$dir/no/such/x.log", $db);
	is_deeply(\@TRACE, [$S{parsing}, $S{settings}, $S{open_log}, $S{fatal}], 'path (EXPORTING never entered)');
	is($status, $CONFIG{exit_fatal}, 'return 3');
	like($stderr, qr/\Aaccess2csv: /, 'action - "access2csv: <reason>" to STDERR');
	restore_all();
};

subtest 'State: EXPORTING -> Trigger: fatal error -> State: FATAL -> return 3' => sub {
	my ($dir) = new_database('T');
	trace_app();
	my ($status) = cli('--no-log', "$dir/missing.accdb");
	is_deeply(\@TRACE, [$S{parsing}, $S{settings}, $S{exporting}, $S{fatal}], 'path');
	is($status, $CONFIG{exit_fatal}, 'return 3');
	restore_all();
};

subtest 'State: CHECKING SETTINGS -> Trigger: invalid value -> State: USAGE ERROR -> return 2 (nothing created)' => sub {
	# A bad option value is a command-line mistake.  Settings are checked
	# before anything with a side effect: no copy of standard input is
	# made and no log file is created
	my ($dir, $db) = new_database('T');
	trace_app();
	my ($status, undef, $stderr) = cli('--log', "$dir/x.log", '--encoding', 'latin1', $db);
	is_deeply(\@TRACE, [$S{parsing}, $S{settings}, $S{usage}], 'path: CHECKING SETTINGS -> USAGE ERROR');
	is($status, $CONFIG{exit_usage}, 'return 2');
	like($stderr, qr/^Invalid setting: Parameter 'encoding' \(latin1\)/m, 'says why');
	ok(!-e "$dir/x.log", 'the log file was never created');
	restore_all();
};

# with_stdin($source, @argv): run the program with STDIN read from $source
sub with_stdin {
	my ($source, @argv) = @_;
	open my $saved, '<&', \*STDIN or die $!;
	open STDIN, '<', $source or die "$source: $!";
	my @result = cli(@argv);
	open STDIN, '<&', $saved or die $!;
	return @result;
}

subtest 'State: CHECKING SETTINGS -> Trigger: "-" -> State: READING STDIN -> OPENING LOG -> EXPORTING' => sub {
	my ($dir, $db) = new_database('T');
	trace_app();
	my ($status) = with_stdin($db, '--log', "$dir/x.log", '--output-dir', "$dir/out", '-');
	is_deeply(\@TRACE, [$S{parsing}, $S{settings}, $S{stdin}, $S{open_log}, $S{exporting}], 'path');
	is($status, $CONFIG{exit_ok}, 'return 0');
	ok(-e "$dir/out/T.csv", 'exported from the piped copy');
	restore_all();
};

subtest 'State: READING STDIN -> Trigger: empty input -> State: FATAL (log never opened)' => sub {
	my ($dir) = new_database('T');
	trace_app();
	my ($status, undef, $stderr) = with_stdin(File::Spec->devnull(), '--log', "$dir/x.log", '-');
	is_deeply(\@TRACE, [$S{parsing}, $S{settings}, $S{stdin}, $S{fatal}], 'path');
	is($status, $CONFIG{exit_fatal}, 'return 3');
	ok(!-e "$dir/x.log", 'the log file was never created');
	restore_all();
};

#######################################################################
# App::Access2CSV::Exporter
#######################################################################

subtest 'Trigger: new -> State: READY (and no READY for invalid settings)' => sub {
	my $e = $CONFIG{exporter}->new(progress => 0);
	isa_ok($e, $CONFIG{exporter}, 'READY');
	throws_ok { $CONFIG{exporter}->new(encoding => 'latin1') } qr/'encoding'/, 'invalid settings: no object, so no READY state';
};

subtest 'State: READY -> run -> CHECKING -> LISTING -> PREPARING -> EXPORTING x N -> SUMMARY -> READY (return 0)' => sub {
	my ($dir, $db) = new_database('A', 'B', 'C');
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, logger => bless({}, 'Local::Quiet'));
	{ package Local::Quiet; sub debug { } sub info { } sub warn { } }
	trace_exporter();
	my ($status) = run_exporter($e, $db);
	verbose_diag('trace', \@TRACE);
	is_deeply(\@TRACE, [$S{checking}, $S{listing}, $S{preparing}, ($S{table}) x 3, $S{summary}], 'path, one EXPORTING per table');
	is($status, $CONFIG{exit_ok}, 'return 0');
	restore_all();

	# Back in READY: the same object runs again, from the start
	trace_exporter();
	$e->{overwrite} = 1;
	($status) = run_exporter($e, $db);
	is($TRACE[0], $S{checking}, 'READY again: a second run starts at CHECKING');
	is($status, $CONFIG{exit_ok}, 'and succeeds');
	restore_all();
};

subtest 'State: EXPORTING -> Trigger: table failure -> EXPORTING (next table) -> SUMMARY -> return 1' => sub {
	my ($dir, $db) = new_database('A', 'Broken', 'C');
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, logger => bless({}, 'Local::Quiet'));
	trace_exporter();
	my ($status, undef, undef, $stderr) = run_exporter($e, $db);
	is_deeply(\@TRACE, [$S{checking}, $S{listing}, $S{preparing}, ($S{table}) x 3, $S{summary}], 'the loop continues after a failure');
	is($status, $CONFIG{exit_failure}, 'return 1');
	like($stderr, qr/FAILED: Broken/, 'action - carp');
	ok(!-e "$dir/out/Broken.csv", 'action - no file for the failed table');
	opendir my $dh, "$dir/out" or die $!;
	ok(!grep({ /\A\.access2csv-/ } readdir $dh), 'action - temporary file deleted');
	restore_all();
};

subtest 'State: LISTING -> Trigger: dry_run -> State: DRY RUN -> return 0 -> READY' => sub {
	my ($dir, $db) = new_database('A');
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, dry_run => 1);
	trace_exporter();
	my ($status, undef, $stdout) = run_exporter($e, $db);
	is_deeply(\@TRACE, [$S{checking}, $S{listing}, $S{dry_run}], 'path (no PREPARING, no SUMMARY)');
	is($status, $CONFIG{exit_ok}, 'return 0');
	like($stdout, qr/DRY RUN/, 'action - list to STDOUT');
	ok(!-e "$dir/out", 'nothing created');
	restore_all();
};

subtest 'State: CHECKING -> Trigger: database missing / program missing -> State: FATAL -> READY' => sub {
	my ($dir, $db) = new_database('A');
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0);
	trace_exporter();
	my ($status, $error) = run_exporter($e, "$dir/missing");
	is_deeply(\@TRACE, [$S{checking}], 'database missing: stops in CHECKING');
	like($error, qr/\ACannot read database /, 'action - croak');
	restore_all();

	{
		local $ENV{PATH} = install_fake_mdbtools('mdb-tables');
		trace_exporter();
		($status, $error) = run_exporter($e, $db);
		is_deeply(\@TRACE, [$S{checking}], 'program missing: stops in CHECKING');
		like($error, qr/\ARequired program not found in PATH: mdb-export /, 'action - croak');
		restore_all();
	}

	ok(!-e "$dir/out", 'no file or folder written');
	($status) = run_exporter($e, $db);
	is($status, $CONFIG{exit_ok}, 'FATAL -> READY: the object still works');
};

subtest 'State: CHECKING -> Trigger: mdb-count missing -> action: warn, switch show_counts off -> LISTING' => sub {
	my ($dir, $db) = new_database('A');
	local $ENV{PATH} = install_fake_mdbtools(qw(mdb-tables mdb-export));
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, show_counts => 1, dry_run => 1);
	trace_exporter();
	my ($status, undef, undef, $stderr) = run_exporter($e, $db);
	is_deeply(\@TRACE, [$S{checking}, $S{listing}, $S{dry_run}], 'the run goes on');
	like($stderr, qr/mdb-count not found/, 'action - warning');
	is($e->{show_counts}, 0, 'action - show_counts switched off');
	restore_all();
};

subtest 'State: LISTING -> Trigger: mdb-tables fails -> State: FATAL' => sub {
	my ($dir, $db) = new_database('FAIL');
	trace_exporter();
	my ($status, $error) = run_exporter($CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0), $db);
	is_deeply(\@TRACE, [$S{checking}, $S{listing}], 'stops in LISTING');
	like($error, qr/\Amdb-tables failed /, 'action - croak');
	ok(!-e "$dir/out", 'no folder made');
	restore_all();
};

subtest 'State: PREPARING -> Trigger: mkdir fails -> State: FATAL' => sub {
	my ($dir, $db) = new_database('A');
	trace_exporter();
	my ($status, $error) = run_exporter($CONFIG{exporter}->new(output_dir => "$db/sub", progress => 0), $db);
	is_deeply(\@TRACE, [$S{checking}, $S{listing}, $S{preparing}], 'stops in PREPARING');
	like($error, qr/\ACannot create output directory /, 'action - croak');
	restore_all();
};

#######################################################################
# Row counts and empty selections
#######################################################################

# A run3 double that makes mdb-count fail and passes everything else on
sub failing_count {
	my $real = \&App::Access2CSV::Exporter::run3;
	return mock_scoped("$CONFIG{exporter}::run3" => sub {
		my ($cmd) = @_;
		return $real->(@_) unless $cmd->[0] =~ /mdb-count\z/;
		${ $_[3] } = 'count failed';
		$? = 1 << 8;
		return 1;
	});
}

subtest 'State: EXPORTING -> Trigger: success, then row count fails -> warning only -> SUMMARY -> return 0' => sub {
	# The file is in place, so the success edge has been taken; a count
	# is an optional extra and cannot turn it into a failure
	my ($dir, $db) = new_database('A');
	my $guard = failing_count();
	my $logger = Local::Recorder->new();
	trace_exporter();
	my ($status, undef, undef, $stderr) = run_exporter($CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, show_counts => 1, logger => $logger), $db);
	is_deeply(\@TRACE, [$S{checking}, $S{listing}, $S{preparing}, $S{table}, $S{summary}], 'path');
	is($status, $CONFIG{exit_ok}, 'return 0');
	ok(-e "$dir/out/A.csv", 'the file is in place');
	like($stderr, qr/^Cannot count the rows of A: mdb-count failed/m, 'action - warning');
	unlike($stderr, qr/FAILED/, 'not reported as a failed table');
	ok((grep { /\AExported A => .*A\.csv\z/ } @{ $logger->{info} }), 'logged as exported, without a count');
	ok((grep { /\AProcessed 1 table, 0 failed\z/ } @{ $logger->{info} }), 'summary: no failures');
	restore_all();
};

subtest 'State: DRY RUN -> Trigger: row count fails -> warning, "?" shown -> return 0' => sub {
	my ($dir, $db) = new_database('A');
	my $guard = failing_count();
	trace_exporter();
	my ($status, $error, $stdout, $stderr) = run_exporter($CONFIG{exporter}->new(progress => 0, show_counts => 1, dry_run => 1), $db);
	is_deeply(\@TRACE, [$S{checking}, $S{listing}, $S{dry_run}], 'path');
	is($status, $CONFIG{exit_ok}, 'return 0');
	is($error, '', 'no exception');
	like($stdout, qr/^A\s+\?\s+A\.csv$/m, 'count shown as "?"');
	like($stderr, qr/^Cannot count the rows of A: /m, 'action - warning');
	restore_all();
};

subtest 'State: LISTING -> Trigger: no tables selected -> State: SUMMARY (no PREPARING) -> return 0' => sub {
	# Nothing to export: no output folder is made, and the summary says so
	my ($dir, $db) = new_database('A');
	my $logger = Local::Recorder->new();
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, tables => [], logger => $logger);
	trace_exporter();
	my ($status) = run_exporter($e, $db);
	is_deeply(\@TRACE, [$S{checking}, $S{listing}, $S{summary}], 'path: LISTING -> SUMMARY');
	is($status, $CONFIG{exit_ok}, 'return 0');
	ok(!-e "$dir/out", 'no output folder made');
	ok((grep { /\AProcessed 0 tables, 0 failed\z/ } @{ $logger->{info} }), 'action - summary logged');
	restore_all();
};

subtest 'State: LISTING -> Trigger: only unknown names selected -> SUMMARY, with a warning' => sub {
	my ($dir, $db) = new_database('A');
	trace_exporter();
	my ($status, undef, undef, $stderr) = run_exporter($CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, tables => ['Nope']), $db);
	is_deeply(\@TRACE, [$S{checking}, $S{listing}, $S{summary}], 'path');
	like($stderr, qr/Table not found in database: Nope/, 'action - warning');
	ok(!-e "$dir/out", 'no output folder made');
	restore_all();
};

#######################################################################
# Illegal transitions
#######################################################################

subtest 'Illegal: run without new (no READY state) is refused at once' => sub {
	my ($dir, $db) = new_database('A');
	trace_exporter();
	throws_ok { $CONFIG{exporter}->run($db) } qr/\Arun\(\) must be called on an object created by new\(\) at /, 'class method refused';
	throws_ok { App::Access2CSV::Exporter::run({}, $db) } qr/\Arun\(\) must be called on an object created by new\(\) at /, 'plain hash refused';
	is_deeply(\@TRACE, [], 'no state was entered');
	restore_all();
};

subtest 'Illegal: jumping straight into an internal state is blocked' => sub {
	# Only new() and run() are transitions a caller may trigger.  The steps
	# inside run() are private, so no caller can start in the middle
	# (e.g. EXPORTING without CHECKING).
	local $Sub::Private::BYPASS = 0;
	local $Sub::Protected::BYPASS = 0;
	local $Sub::Private::config{harness_bypass} = 0;
	local $Sub::Protected::config{harness_bypass} = 0;
	my $e = $CONFIG{exporter}->new(progress => 0);
	throws_ok { $e->_export_all('db', ['A']) } qr/is a private subroutine/, 'EXPORTING without CHECKING';
	throws_ok { $e->_make_output_dir() } qr/is a private subroutine/, 'PREPARING without LISTING';
	throws_ok { $e->_dry_run('db', ['A']) } qr/is a private subroutine/, 'DRY RUN without LISTING';
	throws_ok { $e->_export_table('db', 'A') } qr/is a protected method/, 'one table without PREPARING';
};

done_testing();
