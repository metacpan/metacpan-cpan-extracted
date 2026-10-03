#!perl

# Simulated penetration tests.
#
# App::Access2CSV is a command-line program, not a CGI script: it reads
# no QUERY_STRING, cookies or POST data and writes no HTML or HTTP
# headers.  Its real attack surface is:
#	- the environment: PATH (to find mdbtools) and the locale variables
#	- a hostile Access database: its table names and data, which reach
#	  command arguments, file names, the terminal and the log
#	- the places it writes: the output directory and the log file
# Each subtest mocks a hostile environment with local %ENV, as a CGI
# test would, and asserts that the program fails safely.
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'uses symbolic links and Unix stand-in programs') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture);
use Cwd qw(getcwd);
use File::Copy qw(copy);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Test::Mockingbird;

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

use App::Access2CSV;

Readonly::Hash my %CONFIG => (
	app          => 'App::Access2CSV',
	exporter     => 'App::Access2CSV::Exporter',
	i18n         => 'App::Access2CSV::I18N',
	exit_ok      => 0,
	exit_failure => 1,
	exit_fatal   => 3,
	huge         => 100_000,
	marker       => 'PWNED',
);

# Payloads a hostile database can use as table names
Readonly::Hash my %TERMINAL_ATTACKS => (
	'OSC set window title'  => "\e]0;PWNED\a",
	'CSI clear screen'      => "\e[2J\e[H",
	'CSI colour and hide'   => "\e[8mhidden\e[0m",
	'carriage return'       => "ok\rFAKE: export complete",
	'C1 CSI as UTF-8 bytes' => "c1\xC2\x9B2J",
	'right-to-left override'=> "cod\xE2\x80\xAEgpj.exe",
);

# Raw bytes that must never reach a terminal or a log from hostile data
Readonly::Scalar my $RAW_CONTROL_RE => qr/[\x00-\x08\x0A-\x1F\x7F]|\xC2[\x80-\x9F]|\xE2\x80[\xAA-\xAE]/;

my $FAKE_BIN = install_fake_mdbtools();
my $CLEAN_PATH = join(':', $FAKE_BIN, '/usr/bin', '/bin');

sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

sub cli {
	my @argv = @_;
	my $status;
	my ($stdout, $stderr) = capture { $status = $CONFIG{app}->run(@argv) };
	return ($status, $stdout, $stderr);
}

sub slurp {
	my $path = shift;
	open my $fh, '<:raw', $path or return '';
	local $/;
	return scalar <$fh>;
}

# Visible form of a string, for test names
sub shown {
	(my $s = shift) =~ s/([^\x20-\x7E])/sprintf('\\x%02X', ord $1)/ge;
	return $s;
}

# plant_programs($dir, $marker): put fake mdb-tables/mdb-export/mdb-count
# in $dir that only create $marker - proof that they were run
sub plant_programs {
	my ($dir, $marker) = @_;
	foreach my $program (qw(mdb-tables mdb-export mdb-count)) {
		open my $fh, '>', "$dir/$program" or die $!;
		print {$fh} "#!/bin/sh\ntouch '$marker'\n";
		close $fh;
		chmod oct(755), "$dir/$program";
	}
	return;
}

#######################################################################
# Environment
#######################################################################

subtest 'PATH hijack: programs planted in the current directory are never run' => sub {
	# Exploit: PATH contains "." (or another relative entry).  The victim
	# runs access2csv in a directory the attacker controls (an unpacked
	# archive, a shared directory) that contains an "mdb-tables" script.
	my $trap = tempdir(CLEANUP => 1);
	my $marker = "$trap/$CONFIG{marker}";
	plant_programs($trap, $marker);
	mkdir "$trap/bin" or die $!;
	plant_programs("$trap/bin", $marker);
	my $db = make_database(tempdir(CLEANUP => 1), 'T');
	my $cwd = getcwd();
	chdir $trap or die $!;

	foreach my $path (".:$CLEAN_PATH", "bin:$CLEAN_PATH", "$CLEAN_PATH:.") {
		local %ENV = (%ENV, PATH => $path);
		my ($status) = cli('--no-log', '--output-dir', tempdir(CLEANUP => 1), $db);
		is($status, $CONFIG{exit_ok}, "PATH=$path: exported with the real programs");
		ok(!-e $marker, "PATH=$path: planted program not run");
	}

	# Only relative entries: nothing trustworthy is found at all
	{
		local %ENV = (%ENV, PATH => '.:bin');
		my ($status, undef, $stderr) = cli('--no-log', $db);
		is($status, $CONFIG{exit_fatal}, 'PATH with only relative entries: refused');
		like($stderr, qr/\Aaccess2csv: Required program not found in PATH: mdb-tables\n\z/, 'as "not found"');
		ok(!-e $marker, 'and nothing was run');
	}
	chdir $cwd or die $!;
};

subtest 'PATH entries containing shell syntax are never interpreted' => sub {
	# Exploit: a PATH directory named with shell syntax; if the program
	# were ever started through a shell, the name would run a command
	# The name has no "/", so it is one directory; run from $root, where an
	# executed "touch" would create the marker
	my $root = tempdir(CLEANUP => 1);
	my $marker = "$root/$CONFIG{marker}";
	my $evil = "$root/bin; touch $CONFIG{marker} #";
	mkdir $evil or die "$evil: $!";
	my $cwd = getcwd();
	chdir $root or die $!;
	foreach my $program (qw(mdb-tables mdb-export mdb-count)) {
		copy("$FAKE_BIN/$program", "$evil/$program") or die $!;
		chmod oct(755), "$evil/$program";
	}
	local %ENV = (%ENV, PATH => "$evil:/usr/bin:/bin");
	my $db = make_database(tempdir(CLEANUP => 1), 'T');
	my ($status) = cli('--no-log', '--output-dir', "$root/out", $db);
	is($status, $CONFIG{exit_ok}, 'programs found and run');
	ok(!-e $marker, 'the directory name was not executed');
	chdir $cwd or die $!;
};

subtest 'locale variables carrying payloads' => sub {
	# Exploit: attacker-influenced locale variables (e.g. passed through
	# ssh or a wrapper) used as file names, format strings or output
	my @payloads = ('../../../../etc/passwd', '%n%n%s%s', "\e]0;PWNED\a", "de\x00DE", 'x' x $CONFIG{huge}, "\$(touch /tmp/$CONFIG{marker})");
	my $db = make_database(tempdir(CLEANUP => 1), 'T');
	foreach my $payload (@payloads) {
		local %ENV = (%ENV, PATH => $CLEAN_PATH, map { $_ => $payload } qw(LANGUAGE LC_ALL LC_MESSAGES LANG));
		my ($status, undef, $stderr) = cli('--no-log', '/nonexistent/db.accdb');
		my $name = length($payload) > 40 ? 'huge value' : shown($payload);
		is($status, $CONFIG{exit_fatal}, "$name: normal fatal exit");
		like($stderr, qr/\Aaccess2csv: Cannot read database /, "$name: plain English message");
		# Newlines that end lines are ours; only look inside lines
		ok(!grep({ /$RAW_CONTROL_RE/ } map { s/\n\z//r } split /^/, $stderr), "$name: nothing raw on the terminal");
	}
};

#######################################################################
# Hostile database content
#######################################################################

subtest 'terminal escape injection through table names' => sub {
	# Exploit: table names containing terminal control sequences.  Printed
	# raw, they retitle or clear the victim's terminal, hide text, or
	# overwrite a line with a fake message.  Every channel must escape them.
	my $dir = tempdir(CLEANUP => 1);
	my @names = values %TERMINAL_ATTACKS;
	my $db = make_database($dir, @names);
	my $log = "$dir/run.log";
	local %ENV = (%ENV, PATH => $CLEAN_PATH);

	my (undef, undef, $stderr) = cli('--log', $log, '--show-counts', '--output-dir', "$dir/out", $db);
	my (undef, $dry) = cli('--no-log', '--dry-run', '--show-counts', $db);
	my (undef, undef, $warned) = cli('--no-log', '--dry-run', '--table', $TERMINAL_ATTACKS{'OSC set window title'}, '--table', "\e[2Jmissing", $db);
	my (undef, undef, $fatal) = cli('--no-log', "/nonexistent/\e]0;PWNED\a.accdb");
	verbose_diag('escaped stderr', $stderr);

	my %channels = (
		'progress (STDERR)'        => $stderr,
		'dry-run listing (STDOUT)' => $dry,
		'warnings (STDERR)'        => $warned,
		'fatal message (STDERR)'   => $fatal,
		'log file'                 => slurp($log),
	);
	foreach my $channel (sort keys %channels) {
		my $text = $channels{$channel};
		ok(length($text), "$channel: produced output");
		# Newlines that end lines are ours; only look inside lines
		my @raw = grep { /$RAW_CONTROL_RE/ } map { s/\n\z//r } split /^/, $text;
		is_deeply(\@raw, [], "$channel: no raw control characters");
	}
	like($stderr, qr/\\x1B\]0;PWNED\\x07/, 'the attack is shown, harmlessly, as escapes');
	is(scalar(@{ [ glob("$dir/out/*.csv") ] }), scalar(@names), 'and every table was still exported');
};

subtest 'log forging with a carriage return' => sub {
	# Exploit: "\r" in a name makes a log viewer overwrite the start of the
	# line, so an entry can be made to look like something else
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, "x\rINFO> all tables verified");
	local %ENV = (%ENV, PATH => $CLEAN_PATH);
	cli('--log', "$dir/run.log", '--output-dir', "$dir/out", $db);
	my $log = slurp("$dir/run.log");
	verbose_diag('log', $log);
	unlike($log, qr/\r/, 'no raw carriage return in the log');
	like($log, qr/x\\x0DINFO> all tables verified/, 'the attempt is visible in the log');
};

subtest 'escape sequences in mdbtools error output' => sub {
	# Exploit: a crafted database makes mdb-export print an error that
	# contains escape sequences; the error is shown to the user
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'T');
	local %ENV = (%ENV, PATH => $CLEAN_PATH);
	my $real = \&App::Access2CSV::Exporter::run3;
	my $guard = mock_scoped("$CONFIG{exporter}::run3" => sub {
		my ($cmd, $in, $out, $err) = @_;
		return $real->(@_) unless $cmd->[0] =~ /mdb-export\z/;
		${$err} = "\e[2J\e]0;PWNED\acorrupt";
		$? = 1 << 8;
		return 1;
	});
	my ($status, undef, $stderr) = cli('--no-log', '--output-dir', "$dir/out", $db);
	is($status, $CONFIG{exit_failure}, 'the table fails');
	like($stderr, qr/FAILED: T: mdb-export failed with exit status 1: \\x1B\[2J\\x1B\]0;PWNED\\x07corrupt/, 'error shown escaped');
	unlike($stderr, qr/\e/, 'no raw escape reached the terminal');
};

subtest 'command and option injection through names' => sub {
	# Exploit: shell syntax, or a leading "-", in a table name or path.
	# (Covered in depth by t/edge_cases.t; repeated here as a pen-test.)
	# Commands use a bare marker name (a file name may not contain "/"),
	# and the test runs in $dir, where an executed "touch" would create it
	my $dir = tempdir(CLEANUP => 1);
	my $marker = "$dir/$CONFIG{marker}";
	my $touch = "touch $CONFIG{marker}";
	my $db = make_database($dir, "; $touch", "\$($touch)", "`$touch`", '| sh', '-I', '--help');
	my $hostile_db = "-x; $touch.accdb";
	rename($db, "$dir/$hostile_db") or die $!;
	local %ENV = (%ENV, PATH => $CLEAN_PATH);
	my $cwd = getcwd();
	chdir $dir or die $!;
	my ($status, undef, $stderr) = cli('--no-log', '--output-dir', 'out', '--', $hostile_db);
	chdir $cwd or die $!;
	is($status, $CONFIG{exit_ok}, 'all exported');
	ok(!-e $marker, 'no command ran');
	unlike($stderr, qr/option parsing failed/, 'no name was read as an mdbtools option');
};

subtest 'path traversal and NUL bytes' => sub {
	# Exploit 1: table names that climb out of the output directory.
	# Exploit 2: a NUL byte that a C library would treat as the end of the
	# path, so "safe.accdb\0../../secret" could open "safe.accdb".
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, '../../../../tmp/escaped', "..\\..\\win", "a\x00b");
	local %ENV = (%ENV, PATH => $CLEAN_PATH);

	my ($status) = cli('--no-log', '--output-dir', "$dir/out/in", $db);
	is($status, $CONFIG{exit_ok}, 'exported');
	opendir my $dh, "$dir/out" or die $!;
	is_deeply([grep { !/\A\.\.?\z/ } readdir $dh], ['in'], 'nothing written outside the output directory');
	ok(!grep({ m{/|\x00} } map { (File::Spec->splitpath($_))[2] } glob("$dir/out/in/*")), 'no slash or NUL in any file name');

	($status, undef, my $stderr) = cli('--no-log', '--output-dir', "$dir/nul", "$db\x00../../etc/passwd");
	is($status, $CONFIG{exit_fatal}, 'database path with NUL: refused');
	ok(!-e "$dir/nul", 'the part before the NUL was not opened and exported');
	unlike($stderr, qr/\x00/, 'and no NUL was echoed');
};

#######################################################################
# Where the program writes
#######################################################################

subtest 'symbolic-link attack on the log file' => sub {
	# Exploit: in a shared directory such as /tmp, another user plants
	# "access2csv.log" as a link to a file of the victim's (~/.profile).
	# Appending the log to it would corrupt, or inject into, that file.
	my $shared = tempdir(CLEANUP => 1);
	my $victim = "$shared/victim";
	open my $fh, '>', $victim or die $!;
	print {$fh} "precious\n";
	close $fh;
	my $db = make_database(tempdir(CLEANUP => 1), 'T');
	local %ENV = (%ENV, PATH => $CLEAN_PATH);
	my $cwd = getcwd();
	chdir $shared or die $!;

	symlink($victim, 'access2csv.log') or die $!;
	my ($status, undef, $stderr) = cli('--output-dir', "$shared/out", $db);
	is($status, $CONFIG{exit_fatal}, 'default log is a link: refused');
	is($stderr, "access2csv: Cannot open log file access2csv.log: it is a symbolic link\n", 'exact message');
	is(slurp($victim), "precious\n", 'victim file untouched');
	ok(!-e "$shared/out", 'nothing exported without a safe log');

	symlink("$shared/created-by-us", "$shared/dangling.log") or die $!;
	($status) = cli('--log', "$shared/dangling.log", '--output-dir', "$shared/out", $db);
	is($status, $CONFIG{exit_fatal}, 'dangling link: refused');
	ok(!-e "$shared/created-by-us", 'its target was not created');

	chdir $cwd or die $!;
};

subtest 'regression: a symbolic link planted after the log is opened' => sub {
	# Exploit: the attacker waits until the log has passed the link check,
	# then replaces it with a link to the victim's file.  0.001.0 gave
	# Log::Abstraction the file name, and it reopened the name for every
	# message, so every line after the swap went into the victim's file.
	# The log is now opened once and written through that handle.
	my $shared = tempdir(CLEANUP => 1);
	my $victim = "$shared/victim";
	open my $fh, '>', $victim or die $!;
	print {$fh} "precious\n";
	close $fh;
	my $db = make_database(tempdir(CLEANUP => 1), 'T');
	local %ENV = (%ENV, PATH => $CLEAN_PATH);

	my $log = "$shared/access2csv.log";
	my $moved = "$shared/moved.log";
	my $real = \&App::Access2CSV::Exporter::run;
	my $guard = mock_scoped("$CONFIG{exporter}::run" => sub {
		# The log is open by now: swap it before anything is written
		rename($log, $moved) or die "$log: $!";
		symlink($victim, $log) or die "$log: $!";
		return $real->(@_);
	});
	my ($status) = cli('--no-progress', '--log', $log, '--output-dir', "$shared/out", $db);
	undef $guard;

	is($status, $CONFIG{exit_ok}, 'export: 0');
	is(slurp($victim), "precious\n", 'victim file untouched');
	like(slurp($moved), qr/Processed 1 table, 0 failed/, 'messages went to the file that was checked');
};

subtest 'spreadsheet formula injection is documented, not altered' => sub {
	# Risk: a cell such as =cmd|' /C calc'!A0 can run when the CSV is opened
	# in a spreadsheet.  An exporter must copy data exactly, so it is not
	# changed; the POD warns users instead.  This proves the data is copied
	# byte for byte (no half-way "fix" that corrupts real data).
	my $dir = tempdir(CLEANUP => 1);
	my $formula = q{=cmd|' /C calc'!A0};
	my $db = make_database($dir, 'Evil');
	my $real = \&App::Access2CSV::Exporter::run3;
	my $guard = mock_scoped("$CONFIG{exporter}::run3" => sub {
		my ($cmd, $in, $out) = @_;
		return $real->(@_) unless $cmd->[0] =~ /mdb-export\z/;
		print {$out} qq{"a"\n"$formula"\n};
		$out->flush();
		${ $_[3] } = '';
		$? = 0;
		return 1;
	});
	local %ENV = (%ENV, PATH => $CLEAN_PATH);
	cli('--no-log', '--output-dir', "$dir/out", $db);
	is(slurp("$dir/out/Evil.csv"), qq{"a"\n"$formula"\n}, 'copied exactly');
	like(slurp($INC{'App/Access2CSV.pm'}), qr/formula/i, 'and the POD warns about it');
};

done_testing();
