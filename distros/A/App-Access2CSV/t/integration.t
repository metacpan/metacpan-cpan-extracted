#!perl

# End-to-end integration tests: whole workflows through all three
# modules (App::Access2CSV -> App::Access2CSV::Exporter ->
# App::Access2CSV::I18N), the bin/access2csv script, the real
# Log::Abstraction logger and real files, as described in the POD.
#
# Strategy: nothing inside the distribution is mocked.  mdbtools itself
# is replaced by the stand-in scripts in t/lib/FakeMDB.pm, put first in
# PATH, so the real IPC::Run3 and File::Which code runs.  Test::Mockingbird
# spies (which call through to the real code) confirm that the external
# routines are called with the right arguments.
#
# Optional dependencies: the code has no optional CPAN modules - every
# module it uses is required.  The only optional dependency is the
# external program mdb-count.  So:
#	- every combination of the three mdbtools programs being present or
#	  missing is tested, with and without --show-counts, and
#	- Test::Without::Module checks that a missing *required* module
#	  stops loading with a clear error rather than half-working.
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'the stand-in mdbtools are Unix scripts') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Test::Mockingbird;
use Test::Returns;

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

BEGIN {
	use_ok('App::Access2CSV');
	use_ok('App::Access2CSV::Exporter');
	use_ok('App::Access2CSV::I18N');
}

# Messages must be English unless a test chooses otherwise
delete @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)};

Readonly::Hash my %CONFIG => (
	app          => 'App::Access2CSV',
	exporter     => 'App::Access2CSV::Exporter',
	i18n         => 'App::Access2CSV::I18N',
	exit_ok      => 0,
	exit_failure => 1,
	exit_usage   => 2,
	exit_fatal   => 3,
	fake_rows    => 1,
	utf8_bom     => "\xEF\xBB\xBF",
	log_name     => 'run.log',
);

# The three mdbtools programs; mdb-count is the optional one
Readonly::Array my @PROGRAMS => qw(mdb-count mdb-export mdb-tables);
# In the order the POD says they are checked, so the first missing one is named
Readonly::Array my @REQUIRED => qw(mdb-tables mdb-export);

# The required CPAN modules, for the Test::Without::Module checks
Readonly::Array my @REQUIRED_MODULES => qw(
	File::Which IPC::Run3 Log::Abstraction Params::Get
	Params::Validate::Strict Readonly Return::Set Sub::Private Sub::Protected
);

# A full set of stand-in programs, first in PATH for the whole file
my $FULL_PATH = install_fake_mdbtools();
local $ENV{PATH} = join(':', $FULL_PATH, $ENV{PATH});

sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

# A database listing @tables, in a new directory; returns (dir, db)
sub new_database {
	my $dir = tempdir(CLEANUP => 1);
	return ($dir, make_database($dir, @_));
}

# Run the program in-process; returns (status, stdout, stderr)
sub cli {
	my @argv = @_;
	my $status;
	my ($stdout, $stderr) = capture { $status = $CONFIG{app}->run(@argv) };
	return ($status, $stdout, $stderr);
}

sub slurp {
	my $path = shift;
	open my $fh, '<:raw', $path or die "$path: $!";
	local $/;
	return scalar <$fh>;
}

# CSV file names in a directory, sorted
sub csv_files {
	my $dir = shift;
	opendir my $dh, $dir or return [];
	return [sort grep { /\.csv\z/ } readdir $dh];
}

subtest 'workflow: the installed script exports a database end to end' => sub {
	# bin/access2csv -> App::Access2CSV::run -> Exporter -> I18N -> real
	# Log::Abstraction, in a separate process, as a user would run it
	my ($dir, $db) = new_database(qw(Customers Orders MSysObjects));
	my $out = File::Spec->catdir($dir, 'out');
	my $log = File::Spec->catfile($dir, $CONFIG{log_name});
	my $script = File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'access2csv');
	my $lib = File::Spec->catdir($Bin, File::Spec->updir(), 'lib');

	my ($stdout, $stderr) = capture { system($^X, "-I$lib", $script, '--output-dir', $out, '--log', $log, '--show-counts', $db) };
	my $status = $? >> 8;
	verbose_diag('script stderr', $stderr);

	is($status, $CONFIG{exit_ok}, 'exit status 0');
	is_deeply(csv_files($out), ['Customers.csv', 'Orders.csv'], 'one file per user table');
	is(slurp("$out/Orders.csv"), qq{"id","name"\n1,"Orders"\n}, 'content from mdb-export');
	is($stdout, '', 'nothing on STDOUT');
	like($stderr, qr/\A\[1\/2\] Customers\n\[2\/2\] Orders\n\z/, 'progress on STDERR');

	my $text = slurp($log);
	verbose_diag('log', $text);
	like($text, qr/Exported Orders => \Q$out\E.Orders\.csv \($CONFIG{fake_rows} row\)/, 'export and row count logged');
	like($text, qr/Processed 2 tables, 0 failed/, 'summary logged');
};

subtest 'workflow: dry run, export, repeat, overwrite' => sub {
	# The state that links the runs is the file system and the names
	# chosen for colliding tables; each step must agree with the last
	my ($dir, $db) = new_database('A/B', 'A:B', 'A_B_2', 'Orders');
	my $out = File::Spec->catdir($dir, 'out');
	my @common = ('--no-log', '--no-progress', '--output-dir', $out);

	my ($status, $stdout) = cli(@common, '--dry-run', $db);
	is($status, $CONFIG{exit_ok}, 'dry run: 0');
	ok(!-e $out, 'dry run created nothing');
	my @planned = sort map { (split)[-1] } grep { /\.csv$/ } split /\n/, $stdout;
	verbose_diag('planned', \@planned);

	($status) = cli(@common, $db);
	is($status, $CONFIG{exit_ok}, 'export: 0');
	is_deeply(csv_files($out), \@planned, 'files are exactly the dry-run plan');
	is_deeply(csv_files($out), [sort qw(A_B.csv A_B_2.csv A_B_2_2.csv Orders.csv)], 'collisions resolved, nothing overwritten');

	my $stderr;
	($status, undef, $stderr) = cli(@common, $db);
	is($status, $CONFIG{exit_failure}, 'repeat without --overwrite: 1');
	is(scalar(() = $stderr =~ /Output file already exists/g), 4, 'every table refused');

	($status) = cli(@common, '--overwrite', $db);
	is($status, $CONFIG{exit_ok}, 'repeat with --overwrite: 0');
	is_deeply(csv_files($out), \@planned, 'same names again');
};

subtest 'workflow: failures are isolated and recoverable' => sub {
	# Some tables fail; the rest are exported; a later run with a working
	# encoding completes the job without disturbing the good files
	my ($dir, $db) = new_database(qw(Broken Japanese Orders));
	my $out = File::Spec->catdir($dir, 'out');

	my ($status, undef, $stderr) = cli('--no-log', '--no-progress', '--encoding', 'cp1252', '--output-dir', $out, $db);
	verbose_diag('first run', $stderr);
	is($status, $CONFIG{exit_failure}, 'partial failure: 1');
	returns_ok($status, { type => 'integer', min => 0, max => 3 }, 'documented status range');
	is_deeply(csv_files($out), ['Orders.csv'], 'only the good table written, no partial files');
	like($stderr, qr/FAILED: Broken: mdb-export failed with exit status 1: corrupt table/, 'Broken reported');
	like($stderr, qr/FAILED: Japanese: Table Japanese, line 2: cannot be represented in cp1252/, 'Japanese reported');

	my $orders = slurp("$out/Orders.csv");
	($status) = cli('--no-log', '--no-progress', '--table', 'Japanese', '--output-dir', $out, $db);
	is($status, $CONFIG{exit_ok}, 'retry of one table in UTF-8: 0');
	is_deeply(csv_files($out), ['Japanese.csv', 'Orders.csv'], 'now exported');
	is(slurp("$out/Orders.csv"), $orders, 'earlier file untouched');
};

subtest 'workflow: encodings through the whole stack' => sub {
	my ($dir, $db) = new_database('Unicode');
	my %expected = (
		'utf8'     => qq{"id","name"\n1,"Caf\xC3\xA9 \xE2\x82\xAC"\n},
		'utf8-bom' => qq{$CONFIG{utf8_bom}"id","name"\n1,"Caf\xC3\xA9 \xE2\x82\xAC"\n},
		'cp1252'   => qq{"id","name"\n1,"Caf\xE9 \x80"\n},
	);

	foreach my $encoding (sort keys %expected) {
		my $out = File::Spec->catdir($dir, $encoding);
		my ($status) = cli('--no-log', '--no-progress', '--encoding', $encoding, '--output-dir', $out, $db);
		is($status, $CONFIG{exit_ok}, "$encoding: 0");
		is(slurp("$out/Unicode.csv"), $expected{$encoding}, "$encoding: bytes");
	}
};

subtest 'interactions: external routines are called with the right arguments' => sub {
	# Spies call through to the real routines, so this is still a real
	# run; they only record what the Exporter asked for
	my ($dir, $db) = new_database(qw(Orders));
	my $out = File::Spec->catdir($dir, 'out');
	my $log = File::Spec->catfile($dir, $CONFIG{log_name});

	my $which = spy("$CONFIG{exporter}::which");
	my $run3 = spy("$CONFIG{exporter}::run3");
	my $logger = spy('Log::Abstraction::new');

	my ($status) = cli('--no-progress', '--verbose', '--show-counts', '--log', $log, '--output-dir', $out, $db);
	is($status, $CONFIG{exit_ok}, 'export: 0');

	my @which = map { $_->[1] } $which->();
	is_deeply([sort @which], [@PROGRAMS], 'all three programs looked up');

	my @commands = map { my (undef, $cmd, $stdin) = @{$_}; [(File::Spec->splitpath($cmd->[0]))[2], @{$cmd}[1 .. $#{$cmd}], ${$stdin}] } $run3->();
	verbose_diag('run3 commands', \@commands);
	is_deeply(\@commands, [
		['mdb-tables', '-1', '--', $db, undef],
		['mdb-export', '--', $db, 'Orders', undef],
		['mdb-count', '--', $db, 'Orders', undef],
	], 'each program run once, as a list, options ended by --, with no input');

	my ($created) = $logger->();
	my (undef, undef, %args) = @{$created};
	is_deeply(\%args, { logger => $log, level => 'debug' }, 'logger: the --log file, debug with --verbose');
	like(slurp($log), qr/Found mdb-export at \Q$FULL_PATH\E/, 'debug message reached the file');

	restore_all();
};

subtest 'optional dependency: every combination of mdbtools programs' => sub {
	# mdb-count is optional: without it, --show-counts degrades to a
	# warning.  mdb-tables and mdb-export are required: without either,
	# the run is fatal (exit 3) and writes nothing
	my ($dir, $db) = new_database(qw(Orders));

	foreach my $mask (0 .. 2**@PROGRAMS - 1) {
		my @present = map { $PROGRAMS[$_] } grep { $mask & (1 << $_) } 0 .. $#PROGRAMS;
		my %have = map { $_ => 1 } @present;
		my $label = @present ? join('+', @present) : 'none';

		# Only the chosen stand-ins, and nothing else, are in PATH
		local $ENV{PATH} = @present ? install_fake_mdbtools(@present) : tempdir(CLEANUP => 1);

		foreach my $counts (0, 1) {
			my $out = File::Spec->catdir($dir, "$mask-$counts");
			my @args = ('--no-log', '--no-progress', '--output-dir', $out, ($counts ? '--show-counts' : ()), $db);
			my ($status, undef, $stderr) = cli(@args);
			verbose_diag("$label counts=$counts", { status => $status, stderr => $stderr });

			my @missing = grep { !$have{$_} } @REQUIRED;
			if(@missing) {
				is($status, $CONFIG{exit_fatal}, "$label, counts=$counts: fatal");
				like($stderr, qr/\Aaccess2csv: Required program not found in PATH: $missing[0]\n\z/, "$label: names the missing program");
				ok(!-e $out, "$label: nothing created");
			} else {
				is($status, $CONFIG{exit_ok}, "$label, counts=$counts: success");
				ok(-e "$out/Orders.csv", "$label: exported");
				my $warned = $stderr =~ /mdb-count not found in PATH; row counts are unavailable/ ? 1 : 0;
				is($warned, ($counts && !$have{'mdb-count'}) ? 1 : 0, "$label, counts=$counts: warning only when counts are wanted but unavailable");
			}
		}
	}
};

subtest 'optional dependency: a missing required module fails loudly' => sub {
	# Every CPAN module is required.  Hiding one must stop the program
	# from loading with a clear error, not produce a half-working tool.
	# Each case runs in a child process, since the modules are loaded here.
	my $lib = File::Spec->catdir($Bin, File::Spec->updir(), 'lib');

	foreach my $module (@REQUIRED_MODULES) {
		my ($stdout, $stderr) = capture {
			system($^X, "-I$lib", "-MTest::Without::Module=$module", '-e', 'require App::Access2CSV; print "loaded\n"');
		};
		my $status = $? >> 8;
		verbose_diag("without $module", $stderr);
		isnt($status, 0, "without $module: loading fails");
		is($stdout, '', "without $module: never reports success");
		(my $file = "$module.pm") =~ s{::}{/}g;
		like($stderr, qr/\Q$file\E/, "without $module: the error names it");
	}

	# And with all of them available, the same command succeeds
	my ($stdout) = capture { system($^X, "-I$lib", '-e', 'require App::Access2CSV; print "loaded\n"') };
	is($stdout, "loaded\n", 'all modules available: loads');
};

subtest 'concurrency: independent exporters do not interfere' => sub {
	# Two objects, created together and run in interleaved order, with
	# different settings.  Each must keep its own names, settings and
	# language, and write only to its own folder.
	my ($dir, $db) = new_database('A/B', 'A:B', 'Unicode');
	local $App::Access2CSV::I18N::MESSAGES{de} = { progress => '[%d von %d] %s' };
	local $ENV{LANG} = 'de_DE.UTF-8';

	my $first = new_ok($CONFIG{exporter} => [
		output_dir => "$dir/first", encoding => 'utf8-bom', language => 'en', show_counts => 1,
	]);
	my $second = new_ok($CONFIG{exporter} => [{
		output_dir => "$dir/second", encoding => 'cp1252', tables => ['Unicode'],
	}]);

	my ($status1, $status2, $err1, $err2);
	(undef, $err1) = capture { $status1 = $first->run($db) };
	(undef, $err2) = capture { $status2 = $second->run($db) };
	verbose_diag('progress', { first => $err1, second => $err2 });

	is($status1, $CONFIG{exit_ok}, 'first: 0');
	is($status2, $CONFIG{exit_ok}, 'second: 0');
	is_deeply(csv_files("$dir/first"), ['A_B.csv', 'A_B_2.csv', 'Unicode.csv'], 'first: its own names');
	is_deeply(csv_files("$dir/second"), ['Unicode.csv'], 'second: its own table list');
	like(slurp("$dir/first/Unicode.csv"), qr/\A\Q$CONFIG{utf8_bom}\E/, 'first: its own encoding');
	like(slurp("$dir/second/Unicode.csv"), qr/Caf\xE9 \x80/, 'second: its own encoding');
	like($err1, qr/^\[1\/3\] A\/B$/m, 'first: English, as configured');
	like($err2, qr/^\[1 von 1\] Unicode$/m, 'second: German, from the locale');

	# A problem in one object must not change the other
	local $ENV{PATH} = install_fake_mdbtools(qw(mdb-tables mdb-export));
	my $third = $CONFIG{exporter}->new(output_dir => "$dir/third", show_counts => 1, dry_run => 1, progress => 0);
	capture { $third->run($db) };
	is($third->{show_counts}, 0, 'third: row counts switched off (mdb-count missing)');
	is($first->{show_counts}, 1, 'first: unaffected');

	# Running the first again gives the same names: no state leaks between runs
	$first->{overwrite} = 1;
	capture { $first->run($db) };
	is_deeply(csv_files("$dir/first"), ['A_B.csv', 'A_B_2.csv', 'Unicode.csv'], 'first: same names on a second run');
};

subtest 'cross-module: translations reach every layer' => sub {
	# A translation added to the I18N catalog must appear in messages from
	# App (fatal line), Exporter (progress, warnings) and Log::Abstraction
	my ($dir, $db) = new_database(qw(Orders));
	my $log = File::Spec->catfile($dir, $CONFIG{log_name});
	local $App::Access2CSV::I18N::MESSAGES{de} = {
		fatal          => 'access2csv: FEHLER: %s',
		progress       => '[%d von %d] %s',
		unknown_tables => { one => 'Tabelle fehlt: %s', other => 'Tabellen fehlen: %s' },
		summary        => { one => '%d Tabelle, %d Fehler', other => '%d Tabellen, %d Fehler' },
	};
	local $ENV{LANG} = 'de_DE.UTF-8';

	my ($status, undef, $stderr) = cli('--log', $log, '--output-dir', "$dir/out", '--table', 'Orders', '--table', 'Nope', $db);
	verbose_diag('German run', $stderr);
	is($status, $CONFIG{exit_ok}, 'export: 0');
	like($stderr, qr/^\[1 von 1\] Orders$/m, 'Exporter progress translated');
	like($stderr, qr/^Tabelle fehlt: Nope at /m, 'Exporter warning translated (singular)');
	like(slurp($log), qr/1 Tabelle, 0 Fehler/, 'log entry translated');

	($status, undef, $stderr) = cli('--no-log', File::Spec->catfile($dir, 'missing.accdb'));
	is($status, $CONFIG{exit_fatal}, 'fatal: 3');
	like($stderr, qr/\Aaccess2csv: FEHLER: Cannot read database /, 'App wrapper translated; untranslated key falls back to English');
};

subtest 'cross-module: a logger object is shared, not copied' => sub {
	# One Log::Abstraction object passed to two exporters collects both
	# runs, in order, in one file
	my ($dir, $db) = new_database(qw(Orders));
	my $log = File::Spec->catfile($dir, $CONFIG{log_name});
	my $logger = Log::Abstraction->new(logger => $log, level => 'info');

	foreach my $name (qw(one two)) {
		capture { $CONFIG{exporter}->new(output_dir => "$dir/$name", logger => $logger, progress => 0)->run($db) };
	}
	my @lines = grep { /Exported Orders/ } split /\n/, slurp($log);
	verbose_diag('shared log', \@lines);
	is(scalar(@lines), 2, 'both runs logged');
	like($lines[0], qr{/one/Orders\.csv}, 'first run first');
	like($lines[1], qr{/two/Orders\.csv}, 'second run second');
};

done_testing();
