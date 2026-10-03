#!perl

# Transaction-flow tests.
#
# App::Access2CSV has no database writes of its own; its transactions
# are file exports.  Each TABLE is one transaction, and the POD promises
# it is atomic: "a failed export never leaves a half-written CSV file,
# and an old file is only replaced by a complete new one."
#
#	begin     create a hidden temporary file in the output directory
#	write     byte order mark (utf8-bom), then mdb-export's data
#	          (cp1252: spooled, then converted line by line)
#	commit    close, set permissions, rename over the final name
#	after     count rows, log - the file is already committed
#	rollback  delete the temporary file; any old file stays as it was
#
# A whole run is NOT one transaction: each table commits on its own
# (documented), and an interruption stops the run after rolling back
# the table in flight.
#
# Each subtest is one lifecycle phase.  Failures are injected half-way
# with Test::Mockingbird; after each, the tests check that the old data
# is intact, no temporary file is left, and no file handle is left open.
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'uses Unix stand-in programs and signals') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture);
use Errno qw(ENOSPC);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Test::Mockingbird;
use Test::Returns;
use Time::HiRes qw(sleep);

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

use App::Access2CSV;

# The before() hooks below wrap private methods, so the wrapped method is
# called from Test::Mockingbird's package; allow that outside the harness
$Sub::Private::BYPASS = 1;
$Sub::Protected::BYPASS = 1;

delete @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)};

Readonly::Hash my %CONFIG => (
	exporter     => 'App::Access2CSV::Exporter',
	exit_ok      => 0,
	exit_failure => 1,
	exit_fatal   => 3,
	old_content  => "OLD DATA - must survive\n",
	temp_glob    => '.access2csv-*',
	wait_steps   => 50,
	wait_step    => 0.1,
	utf8_bom     => "\xEF\xBB\xBF",
);

Readonly::Scalar my $HAS_PROC_FD => -d '/proc/self/fd';
Readonly::Scalar my $SCRIPT => File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'access2csv');
Readonly::Scalar my $LIB => File::Spec->catdir($Bin, File::Spec->updir(), 'lib');

local $ENV{PATH} = join(':', install_fake_mdbtools(), $ENV{PATH});

# IPC::Run3 keeps one cached temporary file open for the life of the
# process, created on its first use.  Use it once now, so that it does
# not look like a leak in the first descriptor comparison below.
{
	my $warm = tempdir(CLEANUP => 1);
	capture { App::Access2CSV::Exporter->new(progress => 0, dry_run => 1)->run(make_database($warm, 'T')) };
}

sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

sub slurp {
	my $path = shift;
	open my $fh, '<:raw', $path or return;
	local $/;
	return scalar <$fh>;
}

sub spit {
	my ($path, $content) = @_;
	open my $fh, '>:raw', $path or die "$path: $!";
	print {$fh} $content;
	close $fh;
	return;
}

sub temp_files { my $dir = shift; return [ glob("$dir/$CONFIG{temp_glob}") ] }

sub open_fds {
	return [] unless $HAS_PROC_FD;
	opendir my $dh, '/proc/self/fd' or die $!;
	return [sort { $a <=> $b } grep { /\A\d+\z/ } readdir $dh];
}

# export(%settings): one quiet run over $settings{db}; returns a hashref
# describing the outcome, including open descriptors before and after
sub export {
	my (%args) = @_;
	my $db = delete $args{db};
	my $fds = open_fds();
	my ($status, $error);
	my ($stdout, $stderr) = capture {
		$status = eval { $CONFIG{exporter}->new(progress => 0, %args)->run($db) };
		$error = $@;
	};
	return { status => $status, error => $error, stdout => $stdout, stderr => $stderr, fds => [$fds, open_fds()] };
}

# A run3 double that behaves like mdb-export but lets a test decide what
# happens: $script->($cmd, $out, $err) prints and sets $?
sub fake_export {
	my $script = shift;
	my $real = \&App::Access2CSV::Exporter::run3;
	return mock_scoped("$CONFIG{exporter}::run3" => sub {
		my ($cmd, $in, $out, $err) = @_;
		return $real->(@_) unless $cmd->[0] =~ /mdb-export\z/;
		${$err} = '';
		$? = 0;
		$script->($cmd, $out, $err);
		$out->flush() if ref($out) ne 'SCALAR';
		return 1;
	});
}

#######################################################################
# Phase 1: a complete transaction
#######################################################################

subtest 'Phase: begin -> write -> commit -> after, for one table' => sub {
	# Watch the boundaries from inside: just before the commit the data is
	# complete in the temporary file and the final name does not exist
	# yet; just after, the final file holds it and the temporary is gone.
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Orders');
	my $out = "$dir/out";
	my %before_commit;
	before("$CONFIG{exporter}::_install_file", sub {
		my (undef, $tmp, $final) = @_;
		$tmp->flush();
		%before_commit = (temp => slurp($tmp->filename()), final_exists => -e $final ? 1 : 0, temps => scalar(@{ temp_files($out) }));
	});
	my $result = export(db => $db, output_dir => $out, encoding => 'utf8-bom');
	restore_all();
	verbose_diag('before commit', \%before_commit);

	is($before_commit{temp}, $CONFIG{utf8_bom} . qq{"id","name"\n1,"Orders"\n}, 'before commit: complete data in the temporary file');
	is($before_commit{final_exists}, 0, 'before commit: final name not yet there');
	is($before_commit{temps}, 1, 'before commit: exactly one temporary file');
	is($result->{status}, $CONFIG{exit_ok}, 'committed');
	returns_ok($result->{status}, { type => 'integer', min => 0, max => 1 }, 'documented status');
	is(slurp("$out/Orders.csv"), $before_commit{temp}, 'after commit: the final file holds exactly what was prepared');
	is_deeply(temp_files($out), [], 'after commit: no temporary file');
	is_deeply($result->{fds}[1], $result->{fds}[0], 'no file handle left open') if $HAS_PROC_FD;
};

#######################################################################
# Phase 2: rollback at every step before the commit
#######################################################################

subtest 'Phase: failure before the commit -> rollback, old file untouched' => sub {
	# For each injection point: an OLD Orders.csv exists and --overwrite
	# is on, so a broken rollback would show up as a damaged old file.
	my $real_flush = \&IO::Handle::flush;
	my $real_new = \&File::Temp::new;
	my %faults = (
		# Only the exporter's own temporary files fail (Capture::Tiny, used
		# by these tests, makes temporary files too)
		'begin: temporary file cannot be created' => [{}, sub {
			mock_scoped('File::Temp::new' => sub {
				my ($class, %args) = @_;
				return $real_new->(@_) unless ($args{TEMPLATE} // '') =~ /access2csv/;
				$! = ENOSPC;
				die "Error in tempfile(): $!\n";
			});
		}],
		'write: byte order mark cannot be flushed' => [{ encoding => 'utf8-bom' }, sub {
			mock_scoped('IO::Handle::flush' => sub { return $real_flush->(@_) unless ref($_[0]) && $_[0]->isa('File::Temp'); $! = ENOSPC; return });
		}],
		'write: mdb-export dies after partial output' => [{}, sub {
			fake_export(sub { print { $_[1] } "\"id\"\n1\n"; die "run3(): broken pipe\n" });
		}],
		'write: mdb-export exits non-zero after partial output' => [{}, sub {
			fake_export(sub { print { $_[1] } "\"id\"\n1\n"; ${ $_[2] } = 'corrupt'; $? = 1 << 8 });
		}],
		'write: cp1252 conversion fails on line 3' => [{ encoding => 'cp1252' }, sub {
			fake_export(sub { print { $_[1] } "\"id\"\nok\n\xE6\x97\xA5\n" });
		}],
	);
	foreach my $fault (sort keys %faults) {
		my ($settings, $inject) = @{ $faults{$fault} };
		my $dir = tempdir(CLEANUP => 1);
		my $db = make_database($dir, 'Orders');
		my $out = "$dir/out";
		mkdir $out or die $!;
		spit("$out/Orders.csv", $CONFIG{old_content});

		my $result = do {
			my $guard = $inject->();
			export(db => $db, output_dir => $out, overwrite => 1, %{$settings});
		};
		verbose_diag($fault, $result->{stderr});
		is($result->{status}, $CONFIG{exit_failure}, "$fault: the table failed");
		like($result->{stderr}, qr/FAILED: Orders: /, "$fault: reported");
		is(slurp("$out/Orders.csv"), $CONFIG{old_content}, "$fault: old file byte for byte intact");
		is_deeply(temp_files($out), [], "$fault: temporary file rolled back");
		is_deeply($result->{fds}[1], $result->{fds}[0], "$fault: no file handle left open") if $HAS_PROC_FD;
	}
};

subtest 'Phase: the commit itself fails -> rollback' => sub {
	# The rename cannot happen (a non-empty directory has the final name).
	# Whatever was there before must stay exactly as it was.
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Orders');
	my $out = "$dir/out";
	mkdir "$out" or die $!;
	mkdir "$out/Orders.csv" or die $!;
	spit("$out/Orders.csv/keep", $CONFIG{old_content});

	my $result = export(db => $db, output_dir => $out, overwrite => 1);
	is($result->{status}, $CONFIG{exit_failure}, 'failed');
	like($result->{stderr}, qr/FAILED: Orders: Cannot write /, 'reported');
	is(slurp("$out/Orders.csv/keep"), $CONFIG{old_content}, 'what was there is intact');
	is_deeply(temp_files($out), [], 'temporary file rolled back');
};

#######################################################################
# Phase 3: after the commit
#######################################################################

subtest 'Phase: after the commit -> a later failure cannot un-commit' => sub {
	# Row counting runs after the rename.  If it fails, the committed file
	# must still be complete and correct, and the table still counts as
	# exported: a row count is an optional extra (a warning, not a failure)
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Orders');
	my $real = \&App::Access2CSV::Exporter::run3;
	my $guard = mock_scoped("$CONFIG{exporter}::run3" => sub {
		return $real->(@_) unless $_[0][0] =~ /mdb-count\z/;
		${ $_[3] } = 'count failed';
		$? = 1 << 8;
		return 1;
	});
	my $result = export(db => $db, output_dir => "$dir/out", show_counts => 1);
	is(slurp("$dir/out/Orders.csv"), qq{"id","name"\n1,"Orders"\n}, 'committed file complete and correct');
	is_deeply(temp_files("$dir/out"), [], 'no temporary file');
	is($result->{status}, $CONFIG{exit_ok}, 'the table still counts as exported');
	like($result->{stderr}, qr/Cannot count the rows of Orders/, 'the count failure is a warning');
};

#######################################################################
# Phase 4: the run as a whole
#######################################################################

subtest 'Phase: run with a failing table -> other tables stay committed' => sub {
	# Each table is its own transaction (documented): a failure in the
	# middle neither rolls back the tables before it nor stops those after
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'A', 'Broken', 'C');
	my $result = export(db => $db, output_dir => "$dir/out");
	is($result->{status}, $CONFIG{exit_failure}, 'status 1');
	ok(-e "$dir/out/A.csv" && -e "$dir/out/C.csv", 'tables before and after the failure committed');
	ok(!-e "$dir/out/Broken.csv", 'the failed table left nothing');
	is_deeply(temp_files("$dir/out"), [], 'no temporary files');
};

# interrupt($signal, $to_group): run the real program on [Slow, Zebra],
# send $signal once the Slow table is being written, and report
sub interrupt {
	my ($signal, $to_group) = @_;
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Slow', 'Zebra');
	my $out = "$dir/out";
	mkdir $out or die $!;
	spit("$out/Slow.csv", $CONFIG{old_content});
	my $pid = fork // die "fork: $!";
	if(!$pid) {
		setpgrp(0, 0);
		open STDERR, '>', "$dir/stderr" or die $!;
		open STDOUT, '>', File::Spec->devnull() or die $!;
		exec($^X, "-I$LIB", $SCRIPT, '--no-log', '--overwrite', '--output-dir', $out, $db) or die "exec: $!";
	}
	for (1 .. $CONFIG{wait_steps}) {
		last if @{ temp_files($out) };
		sleep $CONFIG{wait_step};
	}
	kill $signal, $to_group ? -$pid : $pid;
	waitpid($pid, 0);
	my $status = $? >> 8;
	kill 'KILL', -$pid;   # tidy away the stand-in mdb-export if it lingers
	return { status => $status, stderr => slurp("$dir/stderr") // '', out => $out };
}

subtest 'Phase: interrupted mid-transaction -> rollback and stop' => sub {
	# Ctrl-C reaches the whole process group; kill/service managers send
	# TERM to the program.  Either way the table in flight is rolled back
	# and no further table is started.
	foreach my $case (['INT', 1, 'Ctrl-C (SIGINT to the group)'], ['TERM', 0, 'SIGTERM to the program']) {
		my ($signal, $group, $name) = @{$case};
		my $result = interrupt($signal, $group);
		verbose_diag($name, $result);
		is($result->{status}, $CONFIG{exit_fatal}, "$name: stopped (exit 3)");
		like($result->{stderr}, qr/access2csv: Interrupted by SIG$signal: stopped, and the table being exported was discarded/, "$name: says so");
		is(slurp("$result->{out}/Slow.csv"), $CONFIG{old_content}, "$name: old file intact");
		is_deeply(temp_files($result->{out}), [], "$name: temporary file rolled back");
		ok(!-e "$result->{out}/Zebra.csv", "$name: the next table was not started");
	}
};

subtest 'Phase: a caller\'s own signal handlers are respected' => sub {
	# The exporter only takes over signals nobody else is handling, and
	# gives them back afterwards
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'A');
	my $mine = sub { };
	local $SIG{TERM} = $mine;
	local $SIG{HUP};
	my %during;
	before("$CONFIG{exporter}::_export_table", sub { %during = (TERM => $SIG{TERM}, HUP => $SIG{HUP}) });
	export(db => $db, output_dir => "$dir/out");
	restore_all();
	is($during{TERM}, $mine, 'during: the caller\'s TERM handler untouched');
	is(ref($during{HUP}), 'CODE', 'during: HUP handled by the exporter');
	is($SIG{TERM}, $mine, 'after: TERM as before');
	ok(!defined($SIG{HUP}) || $SIG{HUP} eq 'DEFAULT' || $SIG{HUP} eq '', 'after: HUP restored');
};

#######################################################################
# Phase 5: repeating the same transaction
#######################################################################

subtest 'Phase: repeat without --overwrite -> refused, existing data untouched' => sub {
	# Documented: a second run refuses to replace files.  That refusal
	# must not damage what the first run committed, however often it runs.
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'A', 'B');
	my $first = export(db => $db, output_dir => "$dir/out");
	is($first->{status}, $CONFIG{exit_ok}, 'first run commits');
	my %committed = map { $_ => [slurp("$dir/out/$_"), (stat("$dir/out/$_"))[9]] } qw(A.csv B.csv);

	foreach my $repeat (1 .. 2) {
		my $again = export(db => $db, output_dir => "$dir/out");
		is($again->{status}, $CONFIG{exit_failure}, "repeat $repeat: refused");
		is(scalar(() = $again->{stderr} =~ /Output file already exists/g), 2, "repeat $repeat: both tables refused");
		foreach my $file (sort keys %committed) {
			is(slurp("$dir/out/$file"), $committed{$file}[0], "repeat $repeat: $file content unchanged");
			is((stat("$dir/out/$file"))[9], $committed{$file}[1], "repeat $repeat: $file not even rewritten");
		}
		is_deeply(temp_files("$dir/out"), [], "repeat $repeat: no temporary files");
	}
};

subtest 'Phase: repeat with --overwrite -> the same result every time' => sub {
	# With overwrite the transaction is idempotent: same names (even for
	# colliding tables), same bytes; the log grows but earlier lines stay
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'A/B', 'A:B', 'Unicode');
	my $log = "$dir/run.log";
	my (@snapshots, @log_sizes);
	foreach my $run (1 .. 3) {
		my ($status);
		capture { $status = App::Access2CSV->run('--log', $log, '--overwrite', '--no-progress', '--output-dir', "$dir/out", $db) };
		is($status, $CONFIG{exit_ok}, "run $run: status 0");
		opendir my $dh, "$dir/out" or die $!;
		push @snapshots, { map { $_ => slurp("$dir/out/$_") } grep { !/\A\./ } readdir $dh };
		push @log_sizes, -s $log;
	}
	is_deeply($snapshots[1], $snapshots[0], 'run 2 identical to run 1');
	is_deeply($snapshots[2], $snapshots[0], 'run 3 identical to run 1');
	is_deeply([sort keys %{ $snapshots[0] }], ['A_B.csv', 'A_B_2.csv', 'Unicode.csv'], 'same names each time');
	ok($log_sizes[0] < $log_sizes[1] && $log_sizes[1] < $log_sizes[2], 'log appended, never truncated');
};

subtest 'Phase: repeated dry runs -> identical, and nothing written' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'A/B', 'A:B');
	my @outputs = map { export(db => $db, output_dir => "$dir/out", dry_run => 1)->{stdout} } 1 .. 3;
	is($outputs[1], $outputs[0], 'second listing identical');
	is($outputs[2], $outputs[0], 'third listing identical');
	ok(!-e "$dir/out", 'nothing created');
};

subtest 'Phase: fail, then retry -> same final state as a clean run' => sub {
	# A fault in the first attempt must not leave anything that makes the
	# retry differ from a run that never failed
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'A', 'B');
	{
		my $guard = fake_export(sub { die "run3(): transient failure\n" if $_[0][-1] eq 'B'; print { $_[1] } "\"id\",\"name\"\n1,\"$_[0][-1]\"\n" });
		my $first = export(db => $db, output_dir => "$dir/retry");
		is($first->{status}, $CONFIG{exit_failure}, 'first attempt: B failed');
	}
	my $retry = export(db => $db, output_dir => "$dir/retry", overwrite => 1);
	is($retry->{status}, $CONFIG{exit_ok}, 'retry succeeds');
	export(db => $db, output_dir => "$dir/clean");
	foreach my $file (qw(A.csv B.csv)) {
		is(slurp("$dir/retry/$file"), slurp("$dir/clean/$file"), "$file: same as a clean run");
	}
	is_deeply(temp_files("$dir/retry"), [], 'no temporary files');
};

restore_all();

done_testing();
