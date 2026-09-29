#!perl

# End-to-end tests of the command-line front end, App::Access2CSV->run,
# using fake mdbtools (see t/lib/FakeMDB.pm)

use strict;
use warnings;

use Test::Most;

use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use lib File::Spec->catdir($Bin, 'lib');

use App::Access2CSV;
use FakeMDB qw(install_fake_mdbtools make_database fake_path);

local $ENV{PATH} = fake_path();
local @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)} = (undef) x 4;

# cli(@argv): run the program and return (status, stdout, stderr)
sub cli {
	my @argv = @_;
	my $status;
	my ($stdout, $stderr) = capture { $status = App::Access2CSV->run(@argv) };
	return ($status, $stdout, $stderr);
}

my $dir = tempdir(CLEANUP => 1);
my $db = make_database($dir, qw(Customers Orders));
my $log = File::Spec->catfile($dir, 'test.log');

subtest 'help and manual' => sub {
	my ($status, $stdout) = cli('--help');
	is($status, 0, '--help exits 0');
	like($stdout, qr/--output-dir/, 'lists options');

	($status, $stdout) = cli('-h');
	is($status, 0, '-h is an alias');

	($status, $stdout) = cli('--man');
	is($status, 0, '--man exits 0');
	like($stdout, qr/EXIT STATUS/, 'full manual');
};

subtest 'usage errors' => sub {
	my ($status, undef, $stderr) = cli();
	is($status, 2, 'no database');
	like($stderr, qr/Missing database filename/, 'says why');

	($status, undef, $stderr) = cli('a.accdb', 'b.accdb');
	is($status, 2, 'two databases');

	($status, undef, $stderr) = cli('--bogus', $db);
	is($status, 2, 'unknown option is no longer ignored');
	like($stderr, qr/Unknown option: bogus/, 'says why');

	($status, undef, $stderr) = cli('--output-dir');
	is($status, 2, 'option missing its value');
};

subtest 'fatal errors' => sub {
	my ($status, undef, $stderr) = cli('--no-log', File::Spec->catfile($dir, 'nope.accdb'));
	is($status, 3, 'missing database');
	like($stderr, qr/\Aaccess2csv: Cannot read database .*nope\.accdb: [^\n]+\n\z/, 'one clean line');
	unlike($stderr, qr/ line \d+\.$/m, 'no Perl file/line without --verbose');

	($status, undef, $stderr) = cli('--no-log', '--verbose', File::Spec->catfile($dir, 'nope.accdb'));
	like($stderr, qr/ at \S+ line \d+/, 'file/line with --verbose');

	($status, undef, $stderr) = cli('--no-log', '--encoding', 'ebcdic', $db);
	is($status, 2, 'bad encoding: a command-line mistake (usage error)');
	like($stderr, qr/^Invalid setting: Parameter 'encoding' \(ebcdic\) must be one of utf8, utf8-bom, cp1252$/m, 'says why, in plain words');
	unlike($stderr, qr/Params::Validate::Strict|validate_strict| line \d+/, 'no module internals or Perl location');

	($status, undef, $stderr) = cli('--log', File::Spec->catfile($dir, 'no', 'such', 'dir.log'), $db);
	is($status, 3, 'log cannot be opened');
	like($stderr, qr/Cannot open log file .*dir\.log: /, 'says why');
};

subtest 'successful export with a log' => sub {
	my $out = File::Spec->catdir($dir, 'out');
	my ($status, $stdout, $stderr) = cli('--output-dir', $out, '--log', $log, '--show-counts', $db);

	is($status, 0, 'exit 0');
	is($stdout, '', 'nothing on STDOUT');
	like($stderr, qr/\[1\/2\] Customers\n\[2\/2\] Orders\n/, 'progress on STDERR');
	ok(-f File::Spec->catfile($out, 'Customers.csv'), 'file written');

	open my $fh, '<', $log or die "$log: $!";
	my $text = do { local $/; <$fh> };
	like($text, qr/Exported Orders => .*Orders\.csv \(1 row\)/, 'export logged');
	like($text, qr/Processed 2 tables, 0 failed/, 'summary logged');

	($status) = cli('--output-dir', $out, '--no-log', '--no-progress', $db);
	is($status, 1, 'files exist: exit 1');
	($status) = cli('--output-dir', $out, '--no-log', '--no-progress', '--overwrite', $db);
	is($status, 0, '--overwrite: exit 0');
};

subtest '--no-log writes no log' => sub {
	my $work = tempdir(CLEANUP => 1);
	my ($status, $stdout) = cli('--no-log', '--dry-run', '--output-dir', File::Spec->catdir($work, 'out'), $db);
	is($status, 0, 'exit 0');
	like($stdout, qr/DRY RUN/, 'dry-run listing');
	ok(!-e 'access2csv.log' || -M 'access2csv.log' > 0, 'default log not created by this run');
	ok(!-e File::Spec->catdir($work, 'out'), 'dry run created nothing');
};

subtest 'caller @ARGV is not modified' => sub {
	my @argv = ('--no-log', '--dry-run', $db);
	cli(@argv);
	is_deeply(\@argv, ['--no-log', '--dry-run', $db], 'unchanged');
};

subtest 'bin/access2csv' => sub {
	my $script = File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'access2csv');
	my $lib = File::Spec->catdir($Bin, File::Spec->updir(), 'lib');
	# Standard error is shown if the status is wrong, so a failure (for
	# example a module the child cannot load) says why
	my ($stdout, $stderr) = capture { system($^X, "-I$lib", $script, '--help') };
	is($? >> 8, 0, 'exit status passed through') or diag("child stderr: $stderr");
	like($stdout, qr/--output-dir/, 'help printed');

	(undef, $stderr) = capture { system($^X, "-I$lib", $script) };
	is($? >> 8, 2, 'usage error status passed through') or diag("child stderr: $stderr");
};

done_testing();
