#!perl

# Data-flow tests: follow each important piece of data from where it is
# defined (D), through where it is used (U), to where it is killed (K),
# and check that resources are opened, used and closed (O-U-C), even
# when a run fails half-way.
#
# Define-use chains covered:
#	settings     D new()          U run() and helpers     K never (copied in, never leaks out)
#	tables list  D caller         U new() copies it       K caller's changes must not flow in
#	used_names   D _csv_filename  U collisions            K reset at the start of every run()
#	show_counts  D new()          U run()                 K run() when mdb-count is missing
#	table name   D mdb-tables     U file name, mdb-export argument, log message
#	CSV bytes    D mdb-export     U BOM prefix / cp1252 conversion    -> CSV file
#	message      D catalog        U context/plural narrowing, sprintf -> text
#	caller data  hashes and arrays passed in must never be changed
#
# Resources covered: every File::Temp (output and spool), file
# descriptors of the process, and the log file probe.
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'uses /proc/self/fd and Unix stand-in programs') unless $^O eq 'linux' && -d '/proc/self/fd';
}

use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Scalar::Util qw(weaken);
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Returns;

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

use App::Access2CSV;

delete @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)};

Readonly::Hash my %CONFIG => (
	app          => 'App::Access2CSV',
	exporter     => 'App::Access2CSV::Exporter',
	i18n         => 'App::Access2CSV::I18N',
	exit_ok      => 0,
	exit_failure => 1,
	exit_fatal   => 3,
	utf8_bom     => "\xEF\xBB\xBF",
	sentinel     => "sentinel\n",
	fake_rows    => 1,
	temp_prefix  => '.access2csv-',
);

local $ENV{PATH} = join(':', install_fake_mdbtools(), $ENV{PATH});

sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

sub new_database {
	my $dir = tempdir(CLEANUP => 1);
	return ($dir, make_database($dir, @_));
}

sub slurp {
	my $path = shift;
	open my $fh, '<:raw', $path or die "$path: $!";
	local $/;
	return scalar <$fh>;
}

sub dir_entries {
	my $dir = shift;
	opendir my $dh, $dir or return [];
	return [sort grep { !/\A\.\.?\z/ } readdir $dh];
}

# Open file descriptors of this process, by number
sub open_fds {
	opendir my $dh, '/proc/self/fd' or die "/proc/self/fd: $!";
	return [sort { $a <=> $b } grep { /\A\d+\z/ } readdir $dh];
}

# A logger double that records what it is told
{
	package Local::Logger;
	sub new { return bless { lines => [] }, shift }
	foreach my $level (qw(debug info warn)) {
		no strict 'refs';
		*{$level} = sub { push @{ $_[0]{lines} }, [$level, $_[1]]; return };
	}
}

# track_temp_files($code)
# Runs $code while every File::Temp created is recorded: its file name,
# and a weak reference that becomes undef once the object is destroyed
# (which closes its handle).  Also compares the process's open file
# descriptors before and after.  Returns a hashref describing it all.
sub track_temp_files {
	my $code = shift;
	my (@names, @weak);

	around('File::Temp::new', sub {
		my ($orig, @args) = @_;
		my $temp = $orig->(@args);
		push @names, $temp->filename();
		push @weak, $temp;
		weaken($weak[-1]);
		return $temp;
	});

	my $fds_before = open_fds();
	my ($stdout, $stderr, @result) = capture { $code->() };
	my $fds_after = open_fds();
	unmock('File::Temp::new');

	return {
		created   => scalar(@names),
		alive     => scalar(grep { defined } @weak),
		leftovers => [grep { -e $_ } @names],
		fds       => [$fds_before, $fds_after],
		stdout    => $stdout,
		stderr    => $stderr,
		result    => \@result,
	};
}

# Standard lifecycle checks on the result of track_temp_files
sub lifecycle_ok {
	my ($track, $name) = @_;
	verbose_diag("$name lifecycle", { map { $_ => $track->{$_} } qw(created alive leftovers fds) });
	ok($track->{created} > 0, "$name: temporary files were used");
	is($track->{alive}, 0, "$name: every temporary file object destroyed (handles closed)");
	is_deeply($track->{leftovers}, [], "$name: no temporary file left on disk");
	is_deeply($track->{fds}[1], $track->{fds}[0], "$name: no file descriptor left open");
	return;
}

#######################################################################
# Settings and object state
#######################################################################

subtest 'settings: copied in by new(), never flowing back out' => sub {
	# D: the caller's hash and list.  They must be copied, so later changes
	# by the caller cannot reach the object, and the object's work can
	# never change the caller's data.
	my ($dir, $db) = new_database(qw(A B C));
	my @tables = ('A', 'C');
	my %settings = (output_dir => "$dir/out", tables => \@tables, progress => 0, overwrite => 'true');
	my %snapshot = (%settings, tables => [@tables]);

	my $e = $CONFIG{exporter}->new(\%settings);
	push @tables, 'B';
	$settings{output_dir} = "$dir/elsewhere";

	capture { $e->run($db) };
	is_deeply(dir_entries("$dir/out"), ['A.csv', 'C.csv'], 'the copies were used, not the changed originals');
	ok(!-e "$dir/elsewhere", 'a later change to the caller hash did not flow in');
	is_deeply($e->{tables}, ['A', 'C'], 'run() did not change its own copy of the list');
	is($settings{overwrite}, 'true', 'validation did not rewrite the caller hash');
	is_deeply([sort keys %settings], [sort keys %snapshot], 'no keys added to or removed from the caller hash');
	memory_cycle_ok($e, 'no reference cycles after a run');
};

subtest 'used_names: killed and redefined at the start of every run' => sub {
	# D in _csv_filename, U for collision checks, K at the next run.  If the
	# K were missing, the second run would produce A_B_3.csv, A_B_4.csv
	my ($dir, $db) = new_database('A/B', 'A:B');
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, overwrite => 1);

	capture { $e->run($db) };
	my %first = %{ $e->{used_names} };
	capture { $e->run($db) };
	verbose_diag('used_names', $e->{used_names});

	is_deeply(\%first, { 'a_b.csv' => 1, 'a_b_2.csv' => 1 }, 'first run defined two names');
	is_deeply($e->{used_names}, \%first, 'second run started from nothing and defined the same two');
	is_deeply(dir_entries("$dir/out"), ['A_B.csv', 'A_B_2.csv'], 'so the files are the same');
};

subtest 'show_counts: killed by run() when mdb-count is missing, for good' => sub {
	# POD: run() switches show_counts off "for this exporter".  The kill
	# must stick even if mdb-count appears later, and must not affect a
	# different object.
	my ($dir, $db) = new_database('Orders');
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, show_counts => 1, dry_run => 1);
	my $other = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, show_counts => 1, dry_run => 1);

	{
		local $ENV{PATH} = install_fake_mdbtools(qw(mdb-tables mdb-export));
		capture { $e->run($db) };
	}
	is($e->{show_counts}, 0, 'killed');
	my ($stdout) = capture { $e->run($db) };
	unlike($stdout, qr/ROWS/, 'stays killed once mdb-count is back');
	($stdout) = capture { $other->run($db) };
	like($stdout, qr/ROWS/, 'the other exporter still counts');
};

#######################################################################
# Data moving through the pipeline
#######################################################################

subtest 'table name: from mdb-tables to argument, file name and log' => sub {
	# One value (D: printed by mdb-tables) followed to all of its uses
	my ($dir, $db) = new_database('Sales/2026');
	my $argv_log = "$dir/argv.log";
	local $ENV{FAKE_MDB_ARGV_LOG} = $argv_log;
	my $logger = Local::Logger->new();
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, logger => $logger, show_counts => 1);

	my $status;
	capture { $status = $e->run($db) };
	my $outfile = File::Spec->catfile("$dir/out", 'Sales_2026.csv');
	verbose_diag('argv', slurp($argv_log));

	is($status, $CONFIG{exit_ok}, 'exported');
	like(slurp($argv_log), qr/^mdb-export\n--\n\Q$db\E\nSales\/2026\n$/m, 'U1: the exact name reached mdb-export');
	like(slurp($argv_log), qr/^mdb-count\n--\n\Q$db\E\nSales\/2026\n$/m, 'U2: and mdb-count');
	ok(-f $outfile, 'U3: file name made safe');
	like(slurp($outfile), qr/"Sales\/2026"/, 'U4: the data mdb-export printed is in the file');
	is_deeply(
		[grep { $_->[1] =~ /\AExported/ } @{ $logger->{lines} }],
		[['info', "Exported Sales/2026 => $outfile ($CONFIG{fake_rows} row)"]],
		'U5: original name, final path and row count in the log',
	);
};

subtest 'CSV bytes: from mdb-export to file, per encoding' => sub {
	# D: bytes printed by mdb-export.  U: copied, prefixed or converted.
	my ($dir, $db) = new_database('Unicode');
	my $source = qq{"id","name"\n1,"Caf\xC3\xA9 \xE2\x82\xAC"\n};
	my %expected = (
		'utf8'     => $source,
		'utf8-bom' => $CONFIG{utf8_bom} . $source,
		'cp1252'   => qq{"id","name"\n1,"Caf\xE9 \x80"\n},
	);

	foreach my $encoding (sort keys %expected) {
		my $e = $CONFIG{exporter}->new(output_dir => "$dir/$encoding", progress => 0, encoding => $encoding);
		capture { $e->run($db) };
		is(slurp("$dir/$encoding/Unicode.csv"), $expected{$encoding}, "$encoding: exact bytes");
	}
};

subtest 'status: one definition per path' => sub {
	# The returned status is defined once on each path (the DD anomaly
	# that was removed): dry run -> 0, all good -> 0, any failure -> 1
	my ($dir, $db) = new_database(qw(Orders Broken));
	my %paths = (
		'dry run'     => [{ dry_run => 1 }, $CONFIG{exit_ok}],
		'all good'    => [{ tables => ['Orders'] }, $CONFIG{exit_ok}],
		'one failure' => [{}, $CONFIG{exit_failure}],
	);
	foreach my $path (sort keys %paths) {
		my ($args, $expected) = @{ $paths{$path} };
		my $status;
		capture { $status = $CONFIG{exporter}->new(output_dir => "$dir/$path", progress => 0, %{$args})->run($db) };
		is($status, $expected, $path);
		returns_ok($status, { type => 'integer', min => 0, max => 1 }, "$path: documented range");
	}
};

subtest 'run(): caller hash is not changed' => sub {
	# get_params hands back the caller's own hash; run() must not delete
	# or change keys in it, even for an undef database
	my ($dir, $db) = new_database('Orders');
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, dry_run => 1);

	my %args = (database => $db);
	capture { $e->run(\%args) };
	is_deeply(\%args, { database => $db }, 'valid call');

	my %empty = (database => undef);
	eval { $e->run(\%empty) };
	ok(exists $empty{database}, 'undef database: key still there after the error');
};

#######################################################################
# Resource lifecycles
#######################################################################

subtest 'lifecycle: successful exports' => sub {
	# Output temp files are renamed into place (so they are not
	# leftovers), spool files are deleted; nothing stays open
	my ($dir, $db) = new_database(qw(Orders Unicode));
	foreach my $encoding (qw(utf8 utf8-bom cp1252)) {
		my $e = $CONFIG{exporter}->new(output_dir => "$dir/$encoding", progress => 0, encoding => $encoding);
		my $track = track_temp_files(sub { $e->run($db) });
		lifecycle_ok($track, $encoding);
		is_deeply(dir_entries("$dir/$encoding"), ['Orders.csv', 'Unicode.csv'], "$encoding: only the CSV files");
	}
};

subtest 'lifecycle: failures half-way through' => sub {
	# Each table fails at a different point: program exit, signal, bad
	# data during conversion, truncated data, file already there.  In
	# every case the temporary files must be closed and deleted.
	my ($dir, $db) = new_database(qw(Broken Killed Japanese Truncated Orders));
	my $out = "$dir/out";
	mkdir $out or die $!;
	open my $fh, '>', "$out/Orders.csv" or die $!;
	close $fh;

	my $e = $CONFIG{exporter}->new(output_dir => $out, progress => 0, encoding => 'cp1252');
	my $track = track_temp_files(sub { $e->run($db) });
	verbose_diag('stderr', $track->{stderr});
	is($track->{result}[0], $CONFIG{exit_failure}, 'every table failed');
	is(scalar(() = $track->{stderr} =~ /^FAILED: /mg), 5, 'five failures reported');
	lifecycle_ok($track, 'failures');
	is_deeply(dir_entries($out), ['Orders.csv'], 'only the file that was there before');
};

subtest 'lifecycle: exceptions thrown inside the external call' => sub {
	# run3 dies after mdb-export has written part of the data (e.g. a pipe
	# error).  The exception passes through our code; the handle and the
	# temporary file must still be released.
	my ($dir, $db) = new_database(qw(Orders));
	around("$CONFIG{exporter}::run3", sub {
		my ($orig, $cmd, @rest) = @_;
		return $orig->($cmd, @rest) unless $cmd->[0] =~ /mdb-export\z/;
		print {$rest[1]} "partial";
		die "run3(): broken pipe\n";
	});

	foreach my $encoding (qw(utf8 cp1252)) {
		my $e = $CONFIG{exporter}->new(output_dir => "$dir/$encoding", progress => 0, encoding => $encoding);
		my $track = track_temp_files(sub { $e->run($db) });
		like($track->{stderr}, qr/FAILED: Orders: run3\(\): broken pipe/, "$encoding: failure reported");
		lifecycle_ok($track, "$encoding with a dying run3");
		is_deeply(dir_entries("$dir/$encoding"), [], "$encoding: no partial file");
	}
	unmock("$CONFIG{exporter}::run3");
};

subtest 'lifecycle: rename fails at the very end' => sub {
	# The data is complete but cannot be moved into place (a directory is in
	# the way).  The finished temporary file must not be left behind.
	my ($dir, $db) = new_database(qw(Orders));
	my $out = "$dir/out";
	mkdir $out or die $!;
	mkdir "$out/Orders.csv" or die $!;
	open my $fh, '>', "$out/Orders.csv/keep" or die $!;
	close $fh;

	my $e = $CONFIG{exporter}->new(output_dir => $out, progress => 0, overwrite => 1);
	my $track = track_temp_files(sub { $e->run($db) });
	like($track->{stderr}, qr/FAILED: Orders: Cannot write /, 'reported');
	lifecycle_ok($track, 'failed rename');
	is_deeply(dir_entries($out), ['Orders.csv'], 'only the directory that was in the way');
};

subtest 'lifecycle: the log file probe' => sub {
	# App::Access2CSV opens the log once to prove it is writable, then
	# closes it.  Neither success nor failure may leave it open.
	my ($dir, $db) = new_database(qw(Orders));

	my $before = open_fds();
	capture { $CONFIG{app}->run('--log', "$dir/ok.log", '--output-dir', "$dir/out", $db) };
	is_deeply(open_fds(), $before, 'good log: no descriptor left open');
	ok(-s "$dir/ok.log", 'and the log was written');

	capture { $CONFIG{app}->run('--log', "$dir/no/such/dir.log", $db) };
	is_deeply(open_fds(), $before, 'bad log: no descriptor left open');
};

subtest 'lifecycle: exporter objects are freed' => sub {
	# After a run nothing (closures, loggers, caches) keeps the object alive
	my ($dir, $db) = new_database(qw(Orders));
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, logger => Local::Logger->new());
	capture { $e->run($db) };
	my $weak = $e;
	weaken($weak);
	undef $e;
	ok(!defined $weak, 'freed as soon as the last reference went');
};

#######################################################################
# Messages
#######################################################################

subtest 'i18n: caller data flows in, but is never changed' => sub {
	my @params = ('7', '5');
	my %args = (params => \@params, count => '7');
	my $text = $CONFIG{i18n}->i18n('summary', \%args);

	is($text, 'Processed 7 tables, 5 failed', 'values used in order');
	is_deeply(\@params, ['7', '5'], 'params array unchanged');
	is_deeply(\%args, { params => ['7', '5'], count => '7' }, 'args hash unchanged (no coercion written back)');
	is(ref($args{params}), 'ARRAY', 'same array still referenced');
};

subtest 'i18n: a translation with gaps never produces undefined text' => sub {
	# The ~U anomaly that was fixed: a plural or context hash with no form
	# for this case (and no "other") used to leave the template undefined
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	local $App::Access2CSV::I18N::MESSAGES{de} = {
		summary        => { one => '%d Tabelle, %d Fehler' },
		unknown_tables => { female => 'nur weiblich: %s' },
	};
	local $ENV{LANG} = 'de_DE.UTF-8';
	my $i18n = $CONFIG{i18n};

	is($i18n->i18n('summary', { params => [1, 0], count => 1 }), '1 Tabelle, 0 Fehler', 'the form that exists is used');
	is($i18n->i18n('summary', { params => [2, 0], count => 2 }), 'Processed 2 tables, 0 failed', 'missing form: English for this key');
	is($i18n->i18n('unknown_tables', { params => ['X'], count => 1 }), 'Table not found in database: X', 'no usable form at all: English');
	is_deeply(\@warnings, [], 'no "uninitialized" warnings');

	# The English catalog itself is not allowed gaps: that is a bug in the code
	local $App::Access2CSV::I18N::MESSAGES{en}{broken} = { one => 'x' };
	throws_ok { $i18n->i18n('broken', { count => 2 }) } qr/\AUnknown message key: broken at /, 'English gap is a programming error';
};

subtest 'globals survive every transformation' => sub {
	# $_, $@ and $. of the caller must come out of a full run unchanged
	my ($dir, $db) = new_database(qw(Orders Unicode));
	my $e = $CONFIG{exporter}->new(output_dir => "$dir/out", progress => 0, encoding => 'cp1252');

	# No capture here: Capture::Tiny itself resets $., and a quiet
	# successful run prints nothing anyway
	open my $in, '<', \"a\nb\nc\n" or die $!;
	<$in> for 1 .. 2;
	my %after;
	{
		local $_ = $CONFIG{sentinel};
		local $@ = $CONFIG{sentinel};
		my $status = $e->run($db);
		$CONFIG{i18n}->i18n('summary', { params => [1, 0], count => 1 });
		%after = (status => $status, underscore => $_, eval_error => $@, line => $.);
	}
	is($after{status}, $CONFIG{exit_ok}, 'quiet run succeeded');
	is($after{underscore}, $CONFIG{sentinel}, '$_');
	is($after{eval_error}, $CONFIG{sentinel}, '$@');
	is($after{line}, 2, '$. still counts the caller\'s handle');
};

restore_all();

done_testing();
