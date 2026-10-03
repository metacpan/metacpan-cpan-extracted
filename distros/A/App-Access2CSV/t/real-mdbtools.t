#!perl

# Tests against the REAL mdbtools and real Access databases.
#
# Every other test uses the stand-in programs of t/lib/FakeMDB.pm.  This
# one checks that the program works with what it will meet in use: real
# mdb-tables/mdb-export/mdb-count (including the "--" argument
# separator), real .mdb and .accdb files, table names with spaces and
# non-ASCII letters, and binary columns.
#
# The oracle is mdbtools itself: each CSV must be byte-for-byte what
# "mdb-export -- DB TABLE" prints, each row count what mdb-count prints.
#
# No database ships with this distribution (the usual test files have no
# clear licence).  Point ACCESS2CSV_TEST_DATA at a directory of .mdb/.accdb
# files to run this, e.g. the mdbtools project's test data:
#
#	git clone --depth 1 https://github.com/mdbtools/mdbtestdata
#	ACCESS2CSV_TEST_DATA=mdbtestdata/data prove -l t/real-mdbtools.t
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

use Capture::Tiny qw(capture);
use Encode qw(FB_CROAK);
use File::Spec;
use File::Temp qw(tempdir);
use File::Which qw(which);
use IPC::Run3 qw(run3);
use Readonly;

Readonly::Scalar my $DATA_DIR => $ENV{ACCESS2CSV_TEST_DATA};
Readonly::Hash my %CONFIG => (
	exit_ok      => 0,
	exit_failure => 1,
	utf8_bom     => "\xEF\xBB\xBF",
	system_table => qr/\A(?:MSys|USys|~)/i,
);

BEGIN {
	plan(skip_all => 'set ACCESS2CSV_TEST_DATA to a directory of Access databases to test against real mdbtools')
		unless $ENV{ACCESS2CSV_TEST_DATA} && -d $ENV{ACCESS2CSV_TEST_DATA};
	foreach my $program (qw(mdb-tables mdb-export mdb-count)) {
		plan(skip_all => "$program (mdbtools) is not installed") unless which($program);
	}
}

use App::Access2CSV;

my @DATABASES = sort grep { -f } glob(File::Spec->catfile($DATA_DIR, '*.{mdb,accdb,MDB,ACCDB}'));
plan(skip_all => "no .mdb or .accdb files in $DATA_DIR") unless @DATABASES;

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

# mdbtools(@command): run a real mdbtools program; returns its raw stdout
sub mdbtools {
	my @command = @_;
	my ($stdout, $stderr) = ('', '');
	run3([@command], \undef, \$stdout, \$stderr);
	die "@command failed: $stderr" if $?;
	return $stdout;
}

# The user tables of a database, according to mdb-tables itself
sub user_tables {
	my $db = shift;
	return [ sort grep { length && !/$CONFIG{system_table}/ } split /\r?\n/, mdbtools('mdb-tables', '-1', '--', $db) ];
}

# The file name the exporter gives each table (same rules as a real run)
sub file_names {
	my $tables = shift;
	local $Sub::Protected::BYPASS = 1;
	my $e = App::Access2CSV::Exporter->new(progress => 0);
	return { map { $_ => $e->_csv_filename($_) } @{$tables} };
}

# export(%settings): run a quiet export; returns (status, stdout, stderr)
sub export {
	my ($db, %settings) = @_;
	my $status;
	my ($stdout, $stderr) = capture { $status = App::Access2CSV::Exporter->new(progress => 0, %settings)->run($db) };
	return ($status, $stdout, $stderr);
}

foreach my $db (@DATABASES) {
	my $name = (File::Spec->splitpath($db))[2];
	my $tables = user_tables($db);
	my $files = file_names($tables);
	verbose_diag("$name tables", $tables);

	subtest "$name: every table, byte for byte what mdb-export prints" => sub {
		my $out = tempdir(CLEANUP => 1);
		my ($status, undef, $stderr) = export($db, output_dir => $out);
		is($status, $CONFIG{exit_ok}, 'exit 0') or diag($stderr);
		foreach my $table (@{$tables}) {
			is(slurp("$out/$files->{$table}"), mdbtools('mdb-export', '--', $db, $table), "$table");
		}
		my @made = map { (File::Spec->splitpath($_))[2] } glob("$out/*");
		is(scalar(@made), scalar(@{$tables}), 'one file per user table, nothing else');
	};

	subtest "$name: row counts are mdb-count's" => sub {
		my ($status, $stdout) = export($db, dry_run => 1, show_counts => 1);
		is($status, $CONFIG{exit_ok}, 'dry run exit 0');
		foreach my $table (@{$tables}) {
			my ($count) = mdbtools('mdb-count', '--', $db, $table) =~ /(\d+)/;
			like($stdout, qr/^\Q$table\E\s+$count\s+\Q$files->{$table}\E$/m, "$table: $count rows");
		}
	};

	subtest "$name: utf8-bom is the byte order mark plus the same data" => sub {
		my $out = tempdir(CLEANUP => 1);
		my ($status) = export($db, output_dir => $out, encoding => 'utf8-bom');
		is($status, $CONFIG{exit_ok}, 'exit 0');
		foreach my $table (@{$tables}) {
			is(slurp("$out/$files->{$table}"), $CONFIG{utf8_bom} . mdbtools('mdb-export', '--', $db, $table), "$table");
		}
	};

	subtest "$name: cp1252 converts what can be converted, refuses the rest cleanly" => sub {
		# The test converts mdb-export's output itself to know what to
		# expect: text tables convert; tables with binary or non-Western
		# data cannot, and must fail without leaving a file
		my $out = tempdir(CLEANUP => 1);
		my ($status, undef, $stderr) = export($db, output_dir => $out, encoding => 'cp1252');
		my $failures = 0;
		foreach my $table (@{$tables}) {
			my $utf8 = mdbtools('mdb-export', '--', $db, $table);
			my $expected = eval { Encode::encode('cp1252', Encode::decode('UTF-8', $utf8, FB_CROAK), FB_CROAK) };
			if(defined $expected) {
				is(slurp("$out/$files->{$table}"), $expected, "$table: converted");
			} else {
				$failures++;
				ok(!-e "$out/$files->{$table}", "$table: cannot be converted, so no file");
				like($stderr, qr/^FAILED: \Q$table\E: Table \Q$table\E, line \d+: /m, "$table: reported with a line number");
			}
		}
		is($status, $failures ? $CONFIG{exit_failure} : $CONFIG{exit_ok}, 'status follows the failures');
	};

	subtest "$name: piped in on standard input, the same files" => sub {
		my ($direct, $piped) = (tempdir(CLEANUP => 1), tempdir(CLEANUP => 1));
		export($db, output_dir => $direct);
		my $script = File::Spec->catfile('bin', 'access2csv');
		my ($stdout, $stderr) = ('', '');
		run3([$^X, '-Ilib', $script, '--no-log', '--no-progress', '--output-dir', $piped, '-'], $db, \$stdout, \$stderr);
		is($? >> 8, $CONFIG{exit_ok}, 'exit 0') or diag($stderr);
		foreach my $table (@{$tables}) {
			is(slurp("$piped/$files->{$table}"), slurp("$direct/$files->{$table}"), "$table");
		}
	};
}

done_testing();
