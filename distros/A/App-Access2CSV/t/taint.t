#!perl

# Taint-mode tests.  Perl's taint mode (-T) refuses to let data from
# outside the program (command line, environment, file contents) reach
# the operating system until the program has validated it.  These tests
# run the real bin/access2csv under "perl -T" and check that:
#	- every normal workflow works (each input is validated, then untainted)
#	- failures still give the true reason, not a taint message or a stale $!
#	- taint mode's own protections still bite where they should, e.g. a
#	  program in a directory that anyone can write to is not run
#
# Set TEST_VERBOSE=1 to see internal state.

use strict;
use warnings;

use Test::Most;

BEGIN {
	plan(skip_all => 'uses Unix stand-in programs and permissions') if $^O eq 'MSWin32';
}

use Capture::Tiny qw(capture);
use Errno qw(ENOENT);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Readonly;
use Test::Mockingbird;

use lib File::Spec->catdir($Bin, 'lib');
use FakeMDB qw(install_fake_mdbtools make_database);

use App::Access2CSV;

Readonly::Hash my %CONFIG => (
	exit_ok        => 0,
	exit_failure   => 1,
	exit_fatal     => 3,
	world_writable => oct(777),
	marker         => 'RAN',
	utf8_bom       => "\xEF\xBB\xBF",
);

Readonly::Scalar my $ENOENT_TEXT => do { local $! = ENOENT; "$!" };
Readonly::Scalar my $SCRIPT => File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'access2csv');
Readonly::Scalar my $LIB => File::Spec->catdir($Bin, File::Spec->updir(), 'lib');

# Taint mode ignores PERL5LIB, so pass the current @INC explicitly;
# otherwise modules installed with local::lib (as on CI) are not found
Readonly::Array my @INC_FLAGS => map { "-I$_" } ($LIB, grep { !ref } @INC);

my $FAKE_BIN = install_fake_mdbtools();

sub verbose_diag {
	my ($label, $data) = @_;
	diag("$label: ", Test::More::explain($data)) if $ENV{TEST_VERBOSE};
	return;
}

# tainted(%env, @argv): run bin/access2csv under perl -T in a child;
# returns (exit status, stdout, stderr)
sub tainted {
	my ($path, @argv) = @_;
	local %ENV = (%ENV, PATH => $path);
	delete @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)};
	my ($stdout, $stderr, $status) = capture { system($^X, '-T', @INC_FLAGS, $SCRIPT, @argv); $? >> 8 };
	return ($status, $stdout, $stderr);
}

sub slurp {
	my $path = shift;
	open my $fh, '<:raw', $path or return;
	local $/;
	return scalar <$fh>;
}

Readonly::Scalar my $SAFE_PATH => "$FAKE_BIN:/usr/bin:/bin";

subtest 'help and dry run work under -T' => sub {
	my $db = make_database(tempdir(CLEANUP => 1), 'Orders', 'Customers');
	my ($status, $stdout, $stderr) = tainted($SAFE_PATH, '--help');
	is($status, $CONFIG{exit_ok}, '--help');
	like($stdout, qr/--output-dir/, 'help text');

	($status, $stdout, $stderr) = tainted($SAFE_PATH, '--no-log', '--dry-run', '--show-counts', $db);
	verbose_diag('dry run', { stdout => $stdout, stderr => $stderr });
	is($status, $CONFIG{exit_ok}, 'dry run');
	like($stdout, qr/^Orders\s+1\s+Orders\.csv$/m, 'tables listed with counts');
	unlike($stderr, qr/Insecure/, 'no taint failure');
};

subtest 'exports in every encoding, with a log, under -T' => sub {
	# Same bytes as without -T: untainting changes nothing but permission
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'Unicode');
	my %expected = (
		'utf8'     => qq{"id","name"\n1,"Caf\xC3\xA9 \xE2\x82\xAC"\n},
		'utf8-bom' => qq{$CONFIG{utf8_bom}"id","name"\n1,"Caf\xC3\xA9 \xE2\x82\xAC"\n},
		'cp1252'   => qq{"id","name"\n1,"Caf\xE9 \x80"\n},
	);
	foreach my $encoding (sort keys %expected) {
		my ($status, undef, $stderr) = tainted($SAFE_PATH, '--log', "$dir/$encoding.log", '--encoding', $encoding, '--show-counts', '--output-dir', "$dir/$encoding", $db);
		is($status, $CONFIG{exit_ok}, "$encoding: exit 0") or diag($stderr);
		is(slurp("$dir/$encoding/Unicode.csv"), $expected{$encoding}, "$encoding: exact bytes");
		like(slurp("$dir/$encoding.log") // '', qr/Exported Unicode => .* \(1 row\)/, "$encoding: logged");
	}
};

subtest 'hostile table names still work (validated, then untainted)' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, '-I', '; touch RAN', 'a/b', "tab\there");
	my ($status, undef, $stderr) = tainted($SAFE_PATH, '--no-log', '--no-progress', '--output-dir', "$dir/out", $db);
	is($status, $CONFIG{exit_ok}, 'exported') or diag($stderr);
	opendir my $dh, "$dir/out" or die $!;
	is(scalar(grep { /\.csv\z/ } readdir $dh), 4, 'one file per table');
	ok(!-e "$dir/$CONFIG{marker}" && !-e $CONFIG{marker}, 'nothing executed');
};

subtest 'failures give the true reason, not a taint or stale error' => sub {
	# Before the fix, a failed log open under -T was reported with a
	# leftover $! ("No such file or directory") instead of the real cause
	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, 'T');

	my ($status, undef, $stderr) = tainted($SAFE_PATH, '--no-log', "$dir/missing.accdb");
	is($status, $CONFIG{exit_fatal}, 'missing database: fatal');
	is($stderr, "access2csv: Cannot read database $dir/missing.accdb: $ENOENT_TEXT\n", 'true reason');

	($status, undef, $stderr) = tainted($SAFE_PATH, '--log', "$dir/no/such/x.log", $db);
	is($status, $CONFIG{exit_fatal}, 'log in a missing directory: fatal');
	is($stderr, "access2csv: Cannot open log file $dir/no/such/x.log: $ENOENT_TEXT\n", 'true reason');
	unlike($stderr, qr/Insecure/, 'not a taint failure');
};

subtest 'taint protection: programs in a directory anyone can write to are not run' => sub {
	# Taint mode refuses to start programs while PATH contains a directory
	# that other users can write to (they could replace the program).  The
	# refusal must be a clean fatal error, and the planted program must
	# not run.
	my $shared = tempdir(CLEANUP => 1);
	chmod $CONFIG{world_writable}, $shared or die $!;
	my $marker = "$shared/$CONFIG{marker}";
	foreach my $program (qw(mdb-tables mdb-export mdb-count)) {
		open my $fh, '>', "$shared/$program" or die $!;
		print {$fh} "#!/bin/sh\ntouch '$marker'\n";
		close $fh;
		chmod oct(755), "$shared/$program";
	}
	my $db = make_database(tempdir(CLEANUP => 1), 'T');
	my ($status, undef, $stderr) = tainted("$shared:$SAFE_PATH", '--no-log', '--dry-run', $db);
	verbose_diag('stderr', $stderr);
	is($status, $CONFIG{exit_fatal}, 'fatal');
	like($stderr, qr/\Aaccess2csv: Insecure directory in \$ENV\{PATH\}/, 'says why');
	ok(!-e $marker, 'the program was not run');
};

subtest 'mdbtools run in a clean environment (with or without -T)' => sub {
	# perlsec: IFS, CDPATH, ENV and BASH_ENV can change how programs start,
	# and relative PATH entries point at the current directory.  None of them
	# may reach the mdbtools processes.
	my %seen;
	my $real = \&App::Access2CSV::Exporter::run3;
	my $guard = mock_scoped('App::Access2CSV::Exporter::run3' => sub {
		%seen = (path => $ENV{PATH}, map { $_ => exists $ENV{$_} ? 1 : 0 } qw(IFS CDPATH ENV BASH_ENV));
		return $real->(@_);
	});
	my $db = make_database(tempdir(CLEANUP => 1), 'T');
	{
		local %ENV = (%ENV, PATH => ".:rel/bin:$SAFE_PATH", IFS => ';', CDPATH => '/tmp', ENV => '/tmp/x', BASH_ENV => '/tmp/y');
		capture { App::Access2CSV->run('--no-log', '--dry-run', $db) };
		is($ENV{IFS}, ';', 'the caller\'s own environment is left alone');
	}
	verbose_diag('child environment', \%seen);
	is($seen{path}, $SAFE_PATH, 'only absolute PATH directories are passed on');
	is($seen{$_}, 0, "$_ removed") foreach qw(IFS CDPATH ENV BASH_ENV);
};

subtest '_failure_reason: autodie errno, or the real message' => sub {
	# White-box: the helper behind "true reason" above
	local $Sub::Private::BYPASS = 1;
	my $reason = \&App::Access2CSV::_failure_reason;
	eval { use autodie qw(open); open my $fh, '<', '/nonexistent/x' };
	is($reason->($@), $ENOENT_TEXT, 'autodie exception: its errno');
	is($reason->("Insecure dependency in sysopen while running with -T switch at x.pm line 3.\n"), 'Insecure dependency in sysopen while running with -T switch', 'plain error: itself, without the location');
	like($reason->({ unblessed => 1 }), qr/\AHASH\(/, 'unblessed reference: does not die');
};

done_testing();
