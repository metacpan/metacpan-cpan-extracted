#!perl

# Reading the database from standard input: "access2csv -".
#
# mdbtools can only read a real file, so the program copies standard
# input to a private temporary file, exports from that, and deletes it.
# These tests pipe databases into the real bin/access2csv and check the
# result, that the copy never outlives the run (success, failure,
# interruption), and the guards: a terminal is refused, empty input is
# an error, "./-" still names a file called "-".
#
# TMPDIR points at a folder per test, so a left-over copy would show.
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'uses Unix stand-in programs, pipes and signals') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture);
use Errno;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use IPC::Run3 qw(run3);
use Readonly;
use Test::Mockingbird;
use Time::HiRes qw(sleep);

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

# At compile time (in BEGIN), like t/00-load.t: loading it later is too
# late for the CHECK blocks of Sub::Private/Sub::Protected
BEGIN { use_ok('App::Access2CSV') }

Readonly::Hash my %CONFIG => (
	exit_ok      => 0,
	exit_usage   => 2,
	exit_fatal   => 3,
	copy_glob    => 'access2csv-stdin-*',
	private_mode => oct(600),
	filler_lines => 200_000,
	wait_steps   => 50,
	wait_step    => 0.1,
);

Readonly::Scalar my $SCRIPT => File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'access2csv');
Readonly::Scalar my $LIB => File::Spec->catdir($Bin, File::Spec->updir(), 'lib');
Readonly::Scalar my $FAKE_BIN => install_fake_mdbtools();

local $ENV{PATH} = join(':', $FAKE_BIN, $ENV{PATH});
delete @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)};

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

sub list_dir {
	my ($dir, $glob) = @_;
	return [ map { (File::Spec->splitpath($_))[2] } glob("$dir/" . ($glob // '*')) ];
}

# piped(\$input, @argv): run bin/access2csv with $input on standard input
# and TMPDIR set to a fresh folder; returns a hashref of the outcome
sub piped {
	my ($input, @argv) = @_;
	my $tmp = tempdir(CLEANUP => 1);
	local $ENV{TMPDIR} = $tmp;
	my ($stdout, $stderr) = ('', '');
	run3([$^X, "-I$LIB", $SCRIPT, @argv], $input, \$stdout, \$stderr);
	return { status => $? >> 8, stdout => $stdout, stderr => $stderr, left => list_dir($tmp, $CONFIG{copy_glob}) };
}

subtest 'a piped database is exported, and its copy removed' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Orders', 'Customers');
	my $result = piped(\slurp($db), '--no-log', '--no-progress', '--output-dir', "$dir/out", '-');
	verbose_diag('result', $result);
	is($result->{status}, $CONFIG{exit_ok}, 'exit 0');
	is_deeply([sort @{ list_dir("$dir/out") }], ['Customers.csv', 'Orders.csv'], 'both tables exported');
	is(slurp("$dir/out/Orders.csv"), qq{"id","name"\n1,"Orders"\n}, 'content');
	is_deeply($result->{left}, [], 'the temporary copy was deleted');
};

subtest '"-" after "--" also means standard input; dry run works' => sub {
	my $db = make_database(tempdir(CLEANUP => 1), 'Orders');
	my $result = piped(\slurp($db), '--no-log', '--dry-run', '--', '-');
	is($result->{status}, $CONFIG{exit_ok}, 'exit 0');
	like($result->{stdout}, qr/^Orders\s+Orders\.csv$/m, 'listed');
	is_deeply($result->{left}, [], 'copy deleted');
};

subtest 'a large database is streamed, not held in memory, and matches a file run' => sub {
	# 200,000 system-table lines (skipped by the exporter) around two real
	# tables: several megabytes that must arrive intact
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Orders', ('MSysFiller') x $CONFIG{filler_lines}, 'Customers');
	my $result = piped(\slurp($db), '--no-log', '--dry-run', '-');
	my ($from_file) = capture { App::Access2CSV->run('--no-log', '--dry-run', $db) };
	is($result->{status}, $CONFIG{exit_ok}, 'exit 0');
	is($result->{stdout}, $from_file, 'same listing as reading the file directly');
};

subtest 'the copy is private while it exists' => sub {
	# In-process, with STDIN reopened on the database, so a hook can look
	# at the copy the moment the export starts
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Orders');
	local $ENV{TMPDIR} = tempdir(CLEANUP => 1);
	my %seen;
	before('App::Access2CSV::Exporter::run', sub { my $path = $_[1]; %seen = (path => $path, mode => (stat $path)[2] & oct(777)) });
	open my $saved, '<&', \*STDIN or die $!;
	open STDIN, '<', $db or die $!;
	my $status;
	capture { $status = App::Access2CSV->run('--no-log', '--dry-run', '-') };
	open STDIN, '<&', $saved or die $!;
	restore_all();
	verbose_diag('copy', \%seen);
	is($status, $CONFIG{exit_ok}, 'exit 0');
	like($seen{path}, qr/access2csv-stdin-/, 'the exporter read the copy');
	is($seen{mode}, $CONFIG{private_mode}, 'readable by the owner only');
	ok(!-e $seen{path}, 'and it is gone afterwards');
};

subtest 'empty standard input is an error, not a confusing mdbtools failure' => sub {
	my $result = piped(\'', '--no-log', '-');
	is($result->{status}, $CONFIG{exit_fatal}, 'exit 3');
	is($result->{stderr}, "access2csv: Standard input is empty: no database was piped in\n", 'exact message');
	is_deeply($result->{left}, [], 'copy deleted');
};

subtest 'a read error gives the real reason' => sub {
	# A folder as standard input: open succeeds, read fails (EISDIR)
	my $folder = tempdir(CLEANUP => 1);
	my $eisdir = do { local $! = Errno::EISDIR(); "$!" };
	my $tmp = tempdir(CLEANUP => 1);
	local $ENV{TMPDIR} = $tmp;
	my ($stdout, $stderr);
	run3([$^X, "-I$LIB", $SCRIPT, '--no-log', '-'], $folder, \$stdout, \$stderr);
	is($? >> 8, $CONFIG{exit_fatal}, 'exit 3');
	is($stderr, "access2csv: Cannot read standard input: $eisdir\n", 'exact message');
	is_deeply(list_dir($tmp, $CONFIG{copy_glob}), [], 'copy deleted');
};

subtest 'a terminal on standard input is refused' => sub {
	# Reading a database from a keyboard would just wait forever
	eval { require IO::Pty; 1 } or plan(skip_all => 'IO::Pty is needed to provide a terminal');
	my $pty = IO::Pty->new();
	my $tmp = tempdir(CLEANUP => 1);
	my $pid = fork // die "fork: $!";
	if(!$pid) {
		$ENV{TMPDIR} = $tmp;
		open STDIN, '<&', $pty->slave() or die $!;
		open STDERR, '>', "$tmp/stderr" or die $!;
		open STDOUT, '>', File::Spec->devnull() or die $!;
		exec($^X, "-I$LIB", $SCRIPT, '--no-log', '-') or die "exec: $!";
	}
	# The parent keeps the terminal's master side open while the child runs
	$pty->close_slave();
	waitpid($pid, 0);
	is($? >> 8, $CONFIG{exit_usage}, 'exit 2 (usage), without reading anything');
	like(slurp("$tmp/stderr"), qr/\AStandard input is a terminal: pipe the database in, or give its file name\n/, 'says why');
	is_deeply(list_dir($tmp, $CONFIG{copy_glob}), [], 'no copy made');
};

subtest 'interrupted while waiting for input: stopped, copy removed' => sub {
	# A slow pipe: part of the data arrives, then the writer stalls.
	# Ctrl-C (INT to the process group) or SIGTERM must stop the program
	# and must not leave the partial copy in the temporary folder.
	foreach my $case (['INT', 1], ['TERM', 0]) {
		my ($signal, $group) = @{$case};
		my $tmp = tempdir(CLEANUP => 1);
		pipe(my $reader, my $writer) or die "pipe: $!";
		my $pid = fork // die "fork: $!";
		if(!$pid) {
			setpgrp(0, 0);
			close $writer;
			$ENV{TMPDIR} = $tmp;
			open STDIN, '<&', $reader or die $!;
			open STDERR, '>', "$tmp/stderr" or die $!;
			exec($^X, "-I$LIB", $SCRIPT, '--no-log', '-') or die "exec: $!";
		}
		close $reader;
		syswrite($writer, "Orders\n");
		for (1 .. $CONFIG{wait_steps}) {
			last if @{ list_dir($tmp, $CONFIG{copy_glob}) };
			sleep $CONFIG{wait_step};
		}
		ok(scalar(@{ list_dir($tmp, $CONFIG{copy_glob}) }), "$signal: the copy was being written");
		kill $signal, $group ? -$pid : $pid;
		waitpid($pid, 0);
		close $writer;
		is($? >> 8, $CONFIG{exit_fatal}, "$signal: stopped with exit 3");
		like(slurp("$tmp/stderr"), qr/\Aaccess2csv: Interrupted by SIG$signal while reading the database from standard input\n\z/, "$signal: says so");
		is_deeply(list_dir($tmp, $CONFIG{copy_glob}), [], "$signal: partial copy deleted");
	}
};

subtest '"./-" is still a file called "-"; the exporter API is unchanged' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Orders');
	rename($db, "$dir/-") or die $!;
	my $result = do {
		my $cwd = File::Spec->rel2abs(File::Spec->curdir());
		chdir $dir or die $!;
		my $r = piped(\'', '--no-log', '--dry-run', './-');
		chdir $cwd or die $!;
		$r;
	};
	is($result->{status}, $CONFIG{exit_ok}, './- reads the file');
	like($result->{stdout}, qr/Orders/, 'listed');

	# "-" is a command-line convention; the module takes names literally
	throws_ok { App::Access2CSV::Exporter->new(progress => 0)->run('-') } qr/\ACannot read database -: /, 'Exporter->run("-") looks for a file called "-"';
};

subtest 'taint mode: piped input works under perl -T' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Orders');
	my @inc = map { "-I$_" } ($LIB, grep { !ref } @INC);
	my ($stdout, $stderr) = ('', '');
	local $ENV{PATH} = "$FAKE_BIN:/usr/bin:/bin";
	run3([$^X, '-T', @inc, $SCRIPT, '--no-log', '--no-progress', '--output-dir', "$dir/out", '-'], \slurp($db), \$stdout, \$stderr);
	is($? >> 8, $CONFIG{exit_ok}, 'exit 0') or diag($stderr);
	ok(-e "$dir/out/Orders.csv", 'exported');
};

done_testing();
