#!perl

# Destructive, pathological, boundary and security tests.  They try to
# break App::Access2CSV through its public API, one module at a time:
#
#	1. App::Access2CSV::I18N      - i18n
#	2. App::Access2CSV::Exporter  - new, run
#	3. App::Access2CSV            - run
#
# Two harnesses are used:
#	- Real child processes: the stand-in mdbtools of t/lib/FakeMDB.pm,
#	  which parse options exactly like the real (glib-based) mdbtools.
#	  Used for anything that must prove what actually reaches a program:
#	  shell injection, option injection, hostile file names.
#	- Upstream failures: Test::Mockingbird replaces File::Which::which and
#	  IPC::Run3::run3 (as the Exporter sees them), the Log::Abstraction
#	  logger and File::Temp's flush with versions that return undef, 0,
#	  "" or fail mid-flight, to check how failures propagate.
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'needs a Unix-like OS (symlinks, FIFOs, /dev)') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture);
use Errno qw(EACCES EISDIR ENAMETOOLONG ENOENT ENOSPC);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use POSIX qw(mkfifo);
use Readonly;
use Test::Mockingbird;
use Test::Returns;

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

use App::Access2CSV;

delete @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)};

Readonly::Hash my %CONFIG => (
	i18n          => 'App::Access2CSV::I18N',
	exporter      => 'App::Access2CSV::Exporter',
	app           => 'App::Access2CSV',
	exit_ok       => 0,
	exit_failure  => 1,
	exit_usage    => 2,
	exit_fatal    => 3,
	fake_bin      => '/fake/bin',
	huge_length   => 1_000_000,
	long_name     => 300,
	many_tables   => 1000,
	huge_count    => '99999999999999999999',
	bad_status    => 4,
	sentinel      => "sentinel\n",
	private_mode  => oct(700),
	no_access     => 0,
);

# OS error texts, from Perl's own $! in the current locale
Readonly::Hash my %OS => map { my $n = $_; ($n => do { local $! = Errno->can($n)->(); "$!" }) } qw(EACCES EISDIR ENAMETOOLONG ENOENT ENOSPC);

# The real-process stand-ins come first in PATH for the whole file
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

sub cli {
	my @argv = @_;
	my $status;
	my ($stdout, $stderr) = capture { $status = $CONFIG{app}->run(@argv) };
	return ($status, $stdout, $stderr);
}

# Run a quiet exporter; return (status, stdout, stderr, exception)
sub export {
	my ($db, %args) = @_;
	my ($status, $error);
	my ($stdout, $stderr) = capture {
		$status = eval { $CONFIG{exporter}->new(progress => 0, %args)->run($db) };
		$error = $@;
	};
	return ($status, $stdout, $stderr, $error);
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

# upstream(%behaviour): replace which/run3 with doubles that fail in
# controlled ways.  Keys: which => coderef, run3 => coderef.  Returns a guard.
sub upstream {
	my %behaviour = @_;
	return mock_scoped(
		"$CONFIG{exporter}::which" => $behaviour{which} || sub { "$CONFIG{fake_bin}/$_[0]" },
		"$CONFIG{exporter}::run3"  => $behaviour{run3},
	);
}

# A run3 double: mdb-tables lists @tables, everything else writes one
# line; $hook->($program, $cmd, $stdout, $stderr) may override
sub fake_run3 {
	my ($tables, $hook) = @_;
	return sub {
		my ($cmd, $stdin, $stdout, $stderr) = @_;
		(my $program = $cmd->[0]) =~ s{.*/}{};
		${$stderr} = '';
		$? = 0;
		return 1 if $hook && $hook->($program, $cmd, $stdout, $stderr);
		if($program eq 'mdb-tables') {
			${$stdout} = join('', map { "$_\n" } @{$tables});
		} elsif(ref($stdout) eq 'SCALAR') {
			${$stdout} = "1\n";
		} else {
			print {$stdout} "a\n";
			$stdout->flush();
		}
		return 1;
	};
}

#######################################################################
# 1. App::Access2CSV::I18N::i18n
#######################################################################

subtest 'i18n: hostile keys and argument types' => sub {
	# Every malformed call must croak cleanly, never print garbage
	my $i18n = $CONFIG{i18n};
	my @cycle;
	push @cycle, \@cycle;

	throws_ok { $i18n->i18n('') } qr/'key'/, 'empty key';
	throws_ok { $i18n->i18n(0) } qr/\AUnknown message key: 0 at /, '0 is a key like any other, and unknown';
	throws_ok { $i18n->i18n([]) } qr/'key'/, 'arrayref as key';
	throws_ok { $i18n->i18n(\*STDOUT) } qr/'key'/, 'glob ref as key';
	throws_ok { $i18n->i18n('summary', []) } qr/'args'/, 'arrayref as args';
	throws_ok { $i18n->i18n('summary', \@cycle) } qr/'args'/, 'circular arrayref as args';
	throws_ok { $i18n->i18n('summary', { context => ['x'] }) } qr/'context'/, 'context must be a string';
	lives_ok { $i18n->i18n('summary', { count => '1e20' }) } 'count in exponent form is still a whole number';
	throws_ok { $i18n->i18n('summary', { count => 'many' }) } qr/'count'/, 'count not a number';
	throws_ok { $i18n->i18n({ key => 'summary', args => { count => 1 }, extra => 1 }) } qr/Unknown parameter 'extra'/, 'extra top-level field';
};

subtest 'i18n: hostile values are data, never format strings' => sub {
	# Format specifiers inside values must be printed, not interpreted
	# (a format-string injection would read arbitrary stack values)
	my $i18n = $CONFIG{i18n};
	my @cycle;
	push @cycle, \@cycle;

	is($i18n->i18n('fatal', { params => ['%s%s%n%x'] }), 'access2csv: %s%s%n%x', 'format specifiers in a value');
	is($i18n->i18n('fatal', { params => ["line1\nline2\x00"] }), "access2csv: line1\nline2\x00", 'newline and NUL kept');
	my $huge = 'x' x $CONFIG{huge_length};
	is(length($i18n->i18n('fatal', { params => [$huge] })), length('access2csv: ') + $CONFIG{huge_length}, 'huge value');
	like($i18n->i18n('fatal', { params => [\@cycle] }), qr/\Aaccess2csv: ARRAY\(0x[0-9a-f]+\)\z/, 'circular ref is just stringified');
	like($i18n->i18n('fatal', { params => [\*STDOUT] }), qr/\Aaccess2csv: GLOB\(/, 'glob ref is just stringified');
	is($i18n->i18n('summary', { params => [0, 0], count => 0 }), 'Processed 0 tables, 0 failed', 'count 0');
};

subtest 'i18n: hostile environment and catalog' => sub {
	# Garbage locale variables must fall back to English, not crash or
	# be used to look up something odd
	my $i18n = $CONFIG{i18n};
	foreach my $value ('', "\n", '../../etc/passwd', 'x' x $CONFIG{huge_length}, "de\x00DE", ':', '::de') {
		local $ENV{LANG} = $value;
		local $ENV{LANGUAGE} = $value;
		# Control characters are escaped so the TAP output stays plain text
		(my $shown = length($value) > 20 ? 'huge' : "'$value'") =~ s/([^\x20-\x7E])/sprintf('\\x%02X', ord $1)/ge;
		is($i18n->i18n('dry_run_title'), 'DRY RUN', "locale $shown falls back");
	}

	# A translation with only some plural forms still works for the
	# forms it has (the POD requires "other" for the rest)
	local $App::Access2CSV::I18N::MESSAGES{de} = { summary => { one => 'eine' } };
	local $ENV{LANG} = 'de';
	lives_ok { $i18n->i18n('summary', { count => 1 }) } 'partial plural hash, matching form';
};

subtest 'i18n: context and $_ abuse' => sub {
	# One value in any context; $_ in the caller's loop is untouched
	my $i18n = $CONFIG{i18n};
	my @list = $i18n->i18n('dry_run_title');
	is(scalar(@list), 1, 'list context: exactly one value');
	returns_ok($list[0], { type => 'string' }, 'a string');

	my @words = ('keep', 'these');
	for (@words) {
		$i18n->i18n('summary', { params => [1, 0], count => 1 });
	}
	is_deeply(\@words, ['keep', 'these'], 'aliased $_ in a foreach loop not modified');
	my @mapped = map { $i18n->i18n('fatal', { params => [$_] }) } qw(a b);
	is_deeply(\@mapped, ['access2csv: a', 'access2csv: b'], 'usable inside map');
};

#######################################################################
# 2. App::Access2CSV::Exporter
#######################################################################

subtest 'new: hostile settings' => sub {
	# Wrong types must be refused at construction, never later mid-export
	my $class = $CONFIG{exporter};
	my @cycle;
	push @cycle, \@cycle;
	my %cyclic;
	$cyclic{self} = \%cyclic;

	throws_ok { $class->new(output_dir => []) } qr/'output_dir'/, 'arrayref directory';
	throws_ok { $class->new(output_dir => \*STDOUT) } qr/'output_dir'/, 'glob directory';
	throws_ok { $class->new(output_dir => '') } qr/'output_dir'/, 'empty directory';
	throws_ok { $class->new(tables => \@cycle) } qr/'tables'|tables can only contain strings/, 'circular table list';
	throws_ok { $class->new(tables => {}) } qr/'tables'/, 'hashref table list';
	throws_ok { $class->new(logger => \%cyclic) } qr/'logger'/, 'unblessed circular hash as logger';
	throws_ok { $class->new(encoding => 'UTF8') } qr/'encoding'/, 'encoding names are exact';
	throws_ok { $class->new(encoding => "utf8\n") } qr/'encoding'/, 'trailing newline in encoding';
	throws_ok { $class->new('output_dir') } qr/./, 'odd number of arguments';

	# Boundary values that are valid
	lives_ok { $class->new(output_dir => '0') } '"0" is a valid folder name';
	lives_ok { $class->new(tables => []) } 'empty table list';
	lives_ok { $class->new(language => "../../etc\n") } 'hostile language is only a catalog key';
	is($class->new(output_dir => 'a', output_dir => 'b')->{output_dir}, 'b', 'duplicate key: the last one wins, as in any Perl hash');
};

subtest 'run: hostile database arguments' => sub {
	my $e = $CONFIG{exporter}->new(progress => 0);
	my $long = '/' . ('x' x ($CONFIG{long_name} * 20));

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	throws_ok { $e->run(undef) } qr/Required parameter 'database' is missing/, 'undef is a missing database';
	is_deeply(\@warnings, [], 'without "uninitialized" warnings');
	throws_ok { $e->run([]) } qr/./, 'arrayref';
	throws_ok { $e->run(\*STDIN) } qr/./, 'glob ref';
	throws_ok { $e->run('0') } qr/\ACannot read database 0: \Q$OS{ENOENT}\E at /, '"0" is looked up as a file';
	throws_ok { $e->run($long) } qr/\ACannot read database .*: \Q$OS{ENAMETOOLONG}\E at /, 'path longer than the OS allows';
	throws_ok { $e->run("/nonexistent\x00/x") } qr/\ACannot read database /, 'embedded NUL';
};

subtest 'run: special files posing as databases' => sub {
	# Devices, FIFOs and folders must be refused before any program runs:
	# a FIFO would otherwise block mdbtools forever
	my $dir = tempdir(CLEANUP => 1);
	my $e = $CONFIG{exporter}->new(progress => 0, output_dir => "$dir/out");
	my $fifo = "$dir/pipe.accdb";
	mkfifo($fifo, $CONFIG{private_mode}) or die "mkfifo: $!";
	symlink("$dir/nowhere", "$dir/dangling.accdb") or die "symlink: $!";
	mkdir "$dir/folder.accdb" or die $!;

	foreach my $path ('/dev/null', '/dev/urandom', $fifo, "$dir/folder.accdb") {
		next unless -e $path;
		throws_ok { $e->run($path) } qr/\ADatabase \Q$path\E is not a regular file at /, "$path refused";
	}
	throws_ok { $e->run("$dir/dangling.accdb") } qr/\ACannot read database \Q$dir\E.dangling\.accdb: \Q$OS{ENOENT}\E at /, 'dangling symlink';
	ok(!-e "$dir/out", 'nothing created');
};

subtest 'run: empty and near-empty databases' => sub {
	# The stand-in mdb-tables prints the file back, so these model
	# "no tables", "one blank line" and "one CRLF line"
	foreach my $case (['0-byte', ''], ['single LF', "\n"], ['single CRLF', "\r\n"], ['only system tables', "MSysObjects\n~TMP\n"]) {
		my ($name, $content) = @{$case};
		my $dir = tempdir(CLEANUP => 1);
		my $db = "$dir/db.accdb";
		open my $fh, '>:raw', $db or die $!;
		print {$fh} $content;
		close $fh;

		my ($status, undef, $stderr, $error) = export($db, output_dir => "$dir/out");
		is($error, '', "$name: no exception");
		is($status, $CONFIG{exit_ok}, "$name: nothing to do is success");
		is_deeply(dir_entries("$dir/out"), [], "$name: no files");
	}
};

subtest 'security: shell metacharacters reach mdbtools as plain data' => sub {
	# Table and file names full of shell syntax.  If any of these went
	# through a shell, the marker file would be created.
	my $dir = tempdir(CLEANUP => 1);
	my $marker = "$dir/PWNED";
	my @hostile = (
		"; touch $marker",
		"| touch $marker",
		"\$(touch $marker)",
		"`touch $marker`",
		"> $marker",
		"a && touch $marker",
		"quote\"s and 'single'",
		' leading and trailing ',
		"tab\there",
	);
	my $db = make_database($dir, @hostile);

	# Database path with spaces, newline and metacharacters as well
	my $hostile_db = "$dir/my db; rm -rf ~ |\n.accdb";
	rename($db, $hostile_db) or die "rename: $!";

	my ($status, undef, $stderr, $error) = export($hostile_db, output_dir => "$dir/out");
	verbose_diag('files', dir_entries("$dir/out"));
	is($error, '', 'no exception');
	is($status, $CONFIG{exit_ok}, 'every table exported');
	ok(!-e $marker, 'no command was executed');
	is(scalar(@{ dir_entries("$dir/out") }), scalar(@hostile), 'one file per table, none lost to collisions');
	ok(!grep({ m{[/<>:"\\|?*\t\n]} } @{ dir_entries("$dir/out") }), 'no unsafe characters in file names');
	like(slurp("$dir/out/leading and trailing.csv"), qr/" leading and trailing "/, 'exact table name was passed to mdb-export');
};

subtest 'security: names starting with "-" are not mdbtools options' => sub {
	# glib-based mdbtools treat any "-x" argument as an option, wherever it
	# appears.  A table called "-H" would silently drop the CSV header;
	# "-I" would turn the CSV into SQL.  Names must be protected by "--".
	my $dir = tempdir(CLEANUP => 1);
	my $argv_log = "$dir/argv.log";
	local $ENV{FAKE_MDB_ARGV_LOG} = $argv_log;
	my $db = make_database($dir, '-H', '-I', '--help', '-');

	# A database path that itself starts with "-", relative to the cwd
	my $cwd = File::Spec->rel2abs(File::Spec->curdir());
	chdir $dir or die $!;
	rename('test.accdb', '-db.accdb') or die $!;
	my ($status, undef, $stderr, $error) = export('-db.accdb', output_dir => 'out', show_counts => 1);
	my $files = dir_entries('out');
	chdir $cwd or die $!;

	verbose_diag('argv seen by mdbtools', slurp($argv_log));
	is($error, '', 'no exception') or diag($error);
	is($status, $CONFIG{exit_ok}, 'all four tables exported');
	is_deeply($files, [sort '-.csv', '--help.csv', '-H.csv', '-I.csv'], 'files named after the tables');
	unlike($stderr, qr/option parsing failed/, 'no name was parsed as an option');
};

subtest 'security: hostile table names cannot escape the output folder' => sub {
	# Path traversal through table names: every file must land inside
	# the output folder, and nothing may be written to its parent
	my $dir = tempdir(CLEANUP => 1);
	my @evil = ('../../escaped', '..', '.', '/etc/passwd', '..\\..\\win', "sub/../../up");
	my $db = make_database($dir, @evil);

	my ($status) = export($db, output_dir => "$dir/out/inner");
	is($status, $CONFIG{exit_ok}, 'exported');
	is_deeply(dir_entries("$dir/out"), ['inner'], 'nothing written beside the output folder');
	is_deeply(dir_entries($dir), [sort 'out', 'test.accdb'], 'nothing written further up');
	is(scalar(@{ dir_entries("$dir/out/inner") }), scalar(@evil), 'every table has its own file inside');
	ok(!grep({ m{/} || /\A\./ } @{ dir_entries("$dir/out/inner") }), 'no slashes, no hidden or dot files');
};

subtest 'security: symlinks planted in the output folder' => sub {
	# Without --overwrite, any existing entry - even a dangling symlink -
	# must count as "already exists".  With --overwrite, the link itself is
	# replaced; the file it points to must never be written through.
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Orders', 'Customers');
	my $out = "$dir/out";
	mkdir $out or die $!;
	my $victim = "$dir/victim.txt";
	open my $fh, '>', $victim or die $!;
	print {$fh} "precious\n";
	close $fh;
	symlink($victim, "$out/Orders.csv") or die $!;
	symlink("$dir/nowhere", "$out/Customers.csv") or die $!;

	my ($status, undef, $stderr) = export($db, output_dir => $out);
	is($status, $CONFIG{exit_failure}, 'both refused without --overwrite');
	like($stderr, qr/FAILED: Customers: Output file already exists: /, 'dangling symlink counts as existing');
	like($stderr, qr/FAILED: Orders: Output file already exists: /, 'symlink to a file counts as existing');
	ok(!-e "$dir/nowhere", 'dangling target not created');

	($status) = export($db, output_dir => $out, overwrite => 1);
	is($status, $CONFIG{exit_ok}, 'replaced with --overwrite');
	ok(!-l "$out/Orders.csv", 'the link was replaced by a real file');
	is(slurp($victim), "precious\n", 'the link target was not written through');
	ok(!-e "$dir/nowhere", 'still not created');
};

subtest 'filesystem: unusable output folders' => sub {
	my ($dir, $db) = new_database('Orders');

	my (undef, undef, undef, $error) = export($db, output_dir => '/dev/null');
	like($error, qr/\ACannot create output directory \/dev\/null: /, '/dev/null as a folder');

	symlink("$dir/loop", "$dir/loop") or die $!;
	(undef, undef, undef, $error) = export($db, output_dir => "$dir/loop/sub");
	like($error, qr/\ACannot create output directory /, 'symlink loop');

	SKIP: {
		skip('root can write anywhere', 3) if $> == 0;
		mkdir "$dir/ro" or die $!;
		chmod oct(555), "$dir/ro";
		my ($status, undef, $stderr) = export($db, output_dir => "$dir/ro");
		chmod oct(755), "$dir/ro";
		is($status, $CONFIG{exit_failure}, 'read-only folder: the table fails');
		like($stderr, qr/FAILED: Orders: .*\Q$OS{EACCES}\E/, 'with the OS reason');
		is_deeply(dir_entries("$dir/ro"), [], 'no temporary files left');
	}
};

subtest 'filesystem: file name longer than the OS allows' => sub {
	# POD LIMITATIONS: names are not shortened.  An over-long one must
	# fail just that table, cleanly, and not the whole run
	my ($dir, $db) = new_database('x' x $CONFIG{long_name}, 'Orders');
	my ($status, undef, $stderr) = export($db, output_dir => "$dir/out");
	is($status, $CONFIG{exit_failure}, 'one table fails');
	like($stderr, qr/\Q$OS{ENAMETOOLONG}\E/, 'OS reason given');
	is_deeply(dir_entries("$dir/out"), ['Orders.csv'], 'other table exported, no temporary files left');
};

subtest 'filesystem: truncated output from mdb-export' => sub {
	# mdb-export dies mid-character (unexpected EOF): utf8 copies bytes as
	# documented; cp1252 must refuse rather than guess
	my ($dir, $db) = new_database('Truncated');

	my ($status) = export($db, output_dir => "$dir/utf8");
	is($status, $CONFIG{exit_ok}, 'utf8: bytes copied as they are');

	my $stderr;
	($status, undef, $stderr) = export($db, output_dir => "$dir/cp1252", encoding => 'cp1252');
	is($status, $CONFIG{exit_failure}, 'cp1252: table fails');
	like($stderr, qr/Table Truncated, line 2: output of mdb-export is not valid UTF-8/, 'reported with the line');
	is_deeply(dir_entries("$dir/cp1252"), [], 'no partial file');
};

subtest 'scale: many colliding names' => sub {
	# Upper/lower-case variants of one name, many times over: every table
	# must still get its own file
	my @tables = map { my $n = $_; join('', map { ($n >> $_) & 1 ? 'A' : 'a' } 0 .. 9) } 0 .. $CONFIG{many_tables} - 1;
	my $guard = upstream(run3 => fake_run3(\@tables));
	my ($dir, $db) = new_database('placeholder');

	my ($status) = export($db, output_dir => "$dir/out");
	is($status, $CONFIG{exit_ok}, 'all exported');
	is(scalar(@{ dir_entries("$dir/out") }), $CONFIG{many_tables}, 'one distinct file each');
};

subtest 'upstream: File::Which returns undef, 0 or ""' => sub {
	# Any false answer means "not installed", with the documented message
	my ($dir, $db) = new_database('Orders');
	foreach my $answer (undef, 0, '') {
		my $guard = upstream(which => sub { $answer }, run3 => fake_run3(['Orders']));
		my (undef, undef, undef, $error) = export($db, output_dir => "$dir/out");
		like($error, qr/\ARequired program not found in PATH: mdb-tables at /, 'which returned ' . (defined $answer ? "'$answer'" : 'undef'));
	}
};

subtest 'upstream: run3 leaves no output at all' => sub {
	# A program that "succeeds" but leaves the output variable undef must be
	# treated as empty output: no warnings, no crash
	my ($dir, $db) = new_database('Orders');
	my $guard = upstream(run3 => fake_run3([], sub {
		my ($program, $cmd, $stdout) = @_;
		${$stdout} = undef if ref($stdout) eq 'SCALAR';
		return 1;
	}));

	my ($status, $stdout, $stderr, $error) = export($db, output_dir => "$dir/out", dry_run => 1, show_counts => 1);
	is($error, '', 'no exception');
	is($status, $CONFIG{exit_ok}, 'no tables is success');
	unlike($stderr, qr/uninitialized/, 'no warnings');
};

subtest 'upstream: mdb-count returns nonsense' => sub {
	# Garbage, negatives and huge numbers from mdb-count must neither crash
	# the dry run nor the export log
	my ($dir, $db) = new_database('Orders');
	foreach my $answer ('', "garbage\n", "-5\n", "$CONFIG{huge_count}\n") {
		my $guard = upstream(run3 => fake_run3(['Orders'], sub {
			my ($program, $cmd, $stdout) = @_;
			return 0 unless $program eq 'mdb-count';
			${$stdout} = $answer;
			return 1;
		}));
		my $out = "$dir/" . length($answer);
		my ($status, undef, $stderr, $error) = export($db, output_dir => $out, show_counts => 1);
		is($error, '', "mdb-count '" . ($answer =~ s/\n//r) . "': no exception");
		is($status, $CONFIG{exit_ok}, 'export succeeded');
		unlike($stderr, qr/FAILED/, 'the table is not blamed for a bad count');
	}
};

subtest 'upstream: a program that cannot be started' => sub {
	# $? == -1 means the program never ran.  That is not "killed by
	# signal 127" and must not be reported as such.
	my ($dir, $db) = new_database('Orders');
	my $guard = upstream(run3 => sub { $! = ENOENT; $? = -1; return 1 });

	my (undef, undef, undef, $error) = export($db, output_dir => "$dir/out");
	like($error, qr/\Amdb-tables could not be run: \Q$OS{ENOENT}\E at /, 'honest message');
	unlike($error, qr/signal/, 'no bogus signal');
};

subtest 'upstream: run3 itself dies mid-flight' => sub {
	# IPC::Run3 croaks on its own I/O errors (e.g. disk full while
	# spooling).  For mdb-export that must fail one table, cleanly.
	my ($dir, $db) = new_database('Orders', 'Customers');
	my $guard = upstream(run3 => fake_run3(['Customers', 'Orders'], sub {
		my ($program, $cmd, $stdout) = @_;
		return 0 unless $program eq 'mdb-export' && $cmd->[-1] eq 'Orders';
		print {$stdout} "partial";
		$! = ENOSPC;
		die "run3(): $!\n";
	}));

	my ($status, undef, $stderr) = export($db, output_dir => "$dir/out");
	is($status, $CONFIG{exit_failure}, 'one table fails');
	like($stderr, qr/FAILED: Orders: run3\(\): \Q$OS{ENOSPC}\E/, 'reason passed on');
	is_deeply(dir_entries("$dir/out"), ['Customers.csv'], 'no partial Orders.csv, no temporary file');
};

subtest 'upstream: disk full while writing the byte order mark' => sub {
	# The BOM is written by Perl and flushed before mdb-export starts.
	# If that flush fails, the table must fail, not be written without it.
	my ($dir, $db) = new_database('Orders');
	# File::Temp inherits flush from IO::Handle.  Mock it there (mocking a
	# method a package only inherits leaves a stub behind on restore that
	# breaks later method calls), and fail only for temporary files.
	my $real_flush = \&IO::Handle::flush;
	my $guard = mock_scoped('IO::Handle::flush' => sub {
		return $real_flush->(@_) unless ref($_[0]) && $_[0]->isa('File::Temp');
		$! = ENOSPC;
		return;
	});

	my ($status, undef, $stderr) = export($db, output_dir => "$dir/out", encoding => 'utf8-bom');
	is($status, $CONFIG{exit_failure}, 'table fails');
	like($stderr, qr/FAILED: Orders: Cannot write .*Orders\.csv: \Q$OS{ENOSPC}\E/, 'disk full reported');
	is_deeply(dir_entries("$dir/out"), [], 'nothing left behind');
};

subtest 'upstream: the logger fails mid-run' => sub {
	# Logging is secondary.  A logger that dies (e.g. its disk is full)
	# must not turn successful exports into failures; it is reported once.
	{
		package Local::DyingLogger;
		sub new { return bless {}, shift }
		sub debug { die "log disk full\n" }
		sub info { die "log disk full\n" }
		sub warn { die "log disk full\n" }
	}
	my ($dir, $db) = new_database('Orders', 'Customers');

	my ($status, undef, $stderr, $error) = export($db, output_dir => "$dir/out", logger => Local::DyingLogger->new());
	verbose_diag('stderr', $stderr);
	is($error, '', 'no exception');
	is($status, $CONFIG{exit_ok}, 'exports still succeed');
	is_deeply(dir_entries("$dir/out"), ['Customers.csv', 'Orders.csv'], 'both written');
	is(scalar(() = $stderr =~ /Cannot write to the log: log disk full/g), 1, 'reported once');
	unlike($stderr, qr/FAILED/, 'no table blamed');
};

subtest 'context: $_ and list context' => sub {
	my ($dir, $db) = new_database('Orders');
	my $e = $CONFIG{exporter}->new(progress => 0, output_dir => "$dir/out", dry_run => 1);

	my @list;
	capture { @list = $e->run($db) };
	is(scalar(@list), 1, 'list context: exactly one status');

	my @dbs = ($db, $db);
	capture { $e->run($_) for @dbs };
	is_deeply(\@dbs, [$db, $db], 'aliased $_ not modified');
};

#######################################################################
# 3. App::Access2CSV::run
#######################################################################

subtest 'app: hostile command lines' => sub {
	my ($dir, $db) = new_database('Orders');

	my ($status, undef, $stderr) = cli(undef);
	is($status, $CONFIG{exit_usage}, 'undef database: usage error');
	like($stderr, qr/^Missing database filename$/m, 'says so');

	($status, undef, $stderr) = cli('');
	is($status, $CONFIG{exit_usage}, 'empty database: usage error');

	# "-" means standard input, even after "--" (as for cat and friends);
	# here standard input is empty, which is reported as such
	{
		open my $saved, '<&', \*STDIN or die $!;
		open STDIN, '<', File::Spec->devnull() or die $!;
		($status, undef, $stderr) = cli('--no-log', '--', '-');
		open STDIN, '<&', $saved or die $!;
	}
	is($status, $CONFIG{exit_fatal}, '"-" after "--" reads standard input');
	like($stderr, qr/Standard input is empty/, '... which is empty here');

	($status, undef, $stderr) = cli('--no-log', '--output-dir', '', $db);
	is($status, $CONFIG{exit_usage}, 'empty --output-dir is refused (usage error)');
	like($stderr, qr/^Invalid setting: .*'output_dir'/m, 'says which setting');

	($status) = cli('--no-log', '--dry-run', ('--table', 'Orders') x $CONFIG{many_tables}, $db);
	is($status, $CONFIG{exit_ok}, 'a thousand repeated --table options');

	($status, undef, $stderr) = cli('--log', $dir, $db);
	is($status, $CONFIG{exit_fatal}, 'log file is a folder');
	like($stderr, qr/\Aaccess2csv: Cannot open log file \Q$dir\E: \Q$OS{EISDIR}\E\n\z/, 'with the OS reason');

	my @list;
	capture { @list = $CONFIG{app}->run('--help') };
	is(scalar(@list), 1, 'list context: exactly one status');
};

subtest 'app: a logger constructor that returns nothing' => sub {
	# Upstream returns undef instead of a logger.  The user asked for a
	# log, so continuing silently without one would break the POD promise.
	my ($dir, $db) = new_database('Orders');
	my $log = "$dir/x.log";
	my $guard = mock_scoped('Log::Abstraction::new' => sub { return });

	my ($status, undef, $stderr) = cli('--log', $log, '--output-dir', "$dir/out", $db);
	is($status, $CONFIG{exit_fatal}, 'fatal');
	like($stderr, qr/\Aaccess2csv: Cannot open log file \Q$log\E: /, 'says why');
	ok(!-e "$dir/out", 'nothing exported without the promised log');
};

#######################################################################
# Regressions: bugs found in earlier reviews must never return
#######################################################################

subtest 'regression: earlier bugs stay fixed' => sub {
	my ($dir, $db) = new_database('A/B', 'A:B', 'A_B_2', 'Orders', 'ORDERS');

	# 1. "A_B_2" overwrote the collision file A_B_2.csv; Orders/ORDERS clashed
	my ($status, undef, $stderr, $error) = export($db, output_dir => "$dir/out");
	verbose_diag('regression export', { status => $status, stderr => $stderr, error => $error });
	is(scalar(@{ dir_entries("$dir/out") }), 5, 'five tables, five files');

	# 2. unknown options were ignored and the export went ahead
	($status) = cli('--no-log', '--bogus', '--output-dir', "$dir/bogus", $db);
	is($status, $CONFIG{exit_usage}, 'unknown option is a usage error');
	ok(!-e "$dir/bogus", 'and nothing was exported');

	# 3. --dry-run created the output folder
	export($db, output_dir => "$dir/dry", dry_run => 1);
	ok(!-e "$dir/dry", 'dry run creates nothing');

	# 4. a second run on the same object renamed files to _2, _3, ...
	my $e = $CONFIG{exporter}->new(progress => 0, output_dir => "$dir/again", overwrite => 1);
	capture { $e->run($db) for 1 .. 2 };
	is(scalar(@{ dir_entries("$dir/again") }), 5, 'same five names on the second run');

	# 5. make_path blamed the parent ("File exists") instead of the folder
	(undef, undef, undef, $error) = export($db, output_dir => "$db/sub");
	unlike($error, qr/File exists/, 'reason is about the folder itself');

	# 6. the caller's $@ was cleared by new() and i18n()
	local $@ = $CONFIG{sentinel};
	$CONFIG{exporter}->new();
	$CONFIG{i18n}->i18n('dry_run_title');
	is($@, $CONFIG{sentinel}, '$@ survives new() and i18n()');
};

restore_all();

done_testing();
