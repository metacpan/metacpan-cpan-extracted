#!perl

# Tests for App::Access2CSV::Exporter, driven through fake mdbtools
# programs (see t/lib/FakeMDB.pm) so no real Access database is needed

use strict;
use warnings;

use Test::Most;

use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use lib File::Spec->catdir($Bin, 'lib');

use App::Access2CSV::Exporter;
use FakeMDB qw(install_fake_mdbtools make_database fake_path);

# Only the fake programs may be found, so the real mdbtools cannot interfere
local $ENV{PATH} = fake_path();
local @ENV{qw(LANGUAGE LC_ALL LC_MESSAGES LANG)} = (undef) x 4;

# A logger that remembers what it was told, standing in for Log::Abstraction
{
	package Local::Logger;
	sub new { return bless { lines => [] }, shift }
	sub debug { my $self = shift; push @{ $self->{lines} }, "DEBUG @_"; return }
	sub info  { my $self = shift; push @{ $self->{lines} }, "INFO @_"; return }
	sub warn  { my $self = shift; push @{ $self->{lines} }, "WARN @_"; return }
}

# slurp($path): raw file contents
sub slurp {
	my $path = shift;
	open my $fh, '<:raw', $path or die "$path: $!";
	local $/;
	return scalar <$fh>;
}

# export(%args): run an exporter over @tables in a fresh directory and
# return (status, output dir, stdout, stderr, logger)
sub export {
	my ($tables, %args) = @_;

	my $dir = tempdir(CLEANUP => 1);
	my $db = make_database($dir, @{$tables});
	my $out = File::Spec->catdir($dir, 'out');
	my $logger = Local::Logger->new();

	my $e = App::Access2CSV::Exporter->new(output_dir => $out, progress => 0, logger => $logger, %args);
	my $status;
	my ($stdout, $stderr) = capture { $status = $e->run($db) };
	return ($status, $out, $stdout, $stderr, $logger, $e, $db);
}

subtest 'constructor validation' => sub {
	isa_ok(App::Access2CSV::Exporter->new(), 'App::Access2CSV::Exporter');
	isa_ok(App::Access2CSV::Exporter->new({ encoding => 'cp1252' }), 'App::Access2CSV::Exporter', 'hashref form');
	lives_ok { App::Access2CSV::Exporter->new(tables => undef) } 'undef means default';
	throws_ok { App::Access2CSV::Exporter->new(encoding => 'latin1') } qr/encoding/, 'bad encoding';
	throws_ok { App::Access2CSV::Exporter->new(bogus => 1) } qr/Unknown parameter 'bogus'/, 'unknown setting';
	throws_ok { App::Access2CSV::Exporter->new(logger => 'file.log') } qr/logger/, 'logger must be an object';
	throws_ok { App::Access2CSV::Exporter->new(logger => bless({}, 'Local::NoMethods')) } qr/logger.*debug/, 'logger must have debug/info/warn';
	throws_ok { App::Access2CSV::Exporter->new(tables => [['nested']]) } qr/'?tables'? can only contain strings/, 'tables must be strings';

	my @tables = ('A');
	my $e = App::Access2CSV::Exporter->new(tables => \@tables);
	push @tables, 'B';
	is_deeply($e->{tables}, ['A'], 'table list is copied');
};

subtest 'exports user tables and skips system tables' => sub {
	my ($status, $out, $stdout, $stderr, $logger) = export([qw(Orders Customers MSysObjects USysRibbons ~TMPCLP1)]);

	is($status, 0, 'success');
	ok(-f File::Spec->catfile($out, 'Customers.csv'), 'Customers.csv');
	ok(-f File::Spec->catfile($out, 'Orders.csv'), 'Orders.csv');
	ok(!-e File::Spec->catfile($out, 'MSysObjects.csv'), 'MSys* skipped');
	ok(!-e File::Spec->catfile($out, 'USysRibbons.csv'), 'USys* skipped');
	is(slurp(File::Spec->catfile($out, 'Orders.csv')), qq{"id","name"\n1,"Orders"\n}, 'content');

	opendir(my $dh, $out);
	is_deeply([sort grep { !/^\.\.?$/ } readdir $dh], ['Customers.csv', 'Orders.csv'], 'no temporary files left');
	is($stderr, '', 'no warnings');
	like($logger->{lines}[-1], qr/INFO Processed 2 tables, 0 failed/, 'summary logged');
	like($logger->{lines}[0], qr/INFO Exported Customers => /, 'export logged');
};

subtest 'new files get normal permissions, not File::Temp 0600' => sub {
	plan(skip_all => 'Windows has no Unix permission bits') if $^O eq 'MSWin32';
	my $old = umask(022);
	my (undef, $out) = export(['Orders']);
	umask($old);
	is((stat(File::Spec->catfile($out, 'Orders.csv')))[2] & oct(777), oct(644), 'mode 0644 under umask 022');
};

subtest 'progress goes to STDERR' => sub {
	my ($status, undef, $stdout, $stderr) = export([qw(A B)], progress => 1);
	is($stdout, '', 'nothing on STDOUT');
	like($stderr, qr/^\[1\/2\] A\n\[2\/2\] B\n\z/, 'numbered progress');
};

subtest 'encodings' => sub {
	my (undef, $out) = export(['Unicode'], encoding => 'utf8');
	is(slurp("$out/Unicode.csv"), qq{"id","name"\n1,"Caf\xC3\xA9 \xE2\x82\xAC"\n}, 'utf8 is passed through');

	(undef, $out) = export(['Unicode'], encoding => 'utf8-bom');
	is(slurp("$out/Unicode.csv"), qq{\xEF\xBB\xBF"id","name"\n1,"Caf\xC3\xA9 \xE2\x82\xAC"\n}, 'utf8-bom adds a BOM, once');

	(undef, $out) = export(['Unicode'], encoding => 'cp1252');
	is(slurp("$out/Unicode.csv"), qq{"id","name"\n1,"Caf\xE9 \x80"\n}, 'cp1252 is converted');
};

subtest 'cp1252 refuses characters it cannot represent' => sub {
	my ($status, $out, undef, $stderr, $logger) = export([qw(Japanese Orders)], encoding => 'cp1252');
	is($status, 1, 'failure status');
	like($stderr, qr/FAILED: Japanese: Table Japanese, line 2: cannot be represented in cp1252/, 'warned');
	ok(!-e "$out/Japanese.csv", 'no partial file');
	ok(-e "$out/Orders.csv", 'other tables still exported');
	ok((grep { /^WARN FAILED: Japanese/ } @{ $logger->{lines} }), 'failure logged');
};

subtest 'cp1252 reports invalid UTF-8 from mdb-export' => sub {
	my ($status, undef, undef, $stderr) = export(['Latin1'], encoding => 'cp1252');
	is($status, 1, 'failure status');
	like($stderr, qr/Table Latin1, line 2: output of mdb-export is not valid UTF-8/, 'warned');
};

subtest 'mdb-export failures are per table' => sub {
	# "Killed" kills itself with a signal, which only Unix has
	my @tables = $^O eq 'MSWin32' ? qw(Broken Orders) : qw(Broken Killed Orders);
	my ($status, $out, undef, $stderr, $logger) = export(\@tables);
	is($status, 1, 'failure status');
	like($stderr, qr/FAILED: Broken: mdb-export failed with exit status 1: corrupt table/, 'exit status');
	SKIP: {
		skip('Windows has no signals', 1) if $^O eq 'MSWin32';
		like($stderr, qr/FAILED: Killed: mdb-export was killed by signal \d+/, 'signal');
	}
	ok(!-e "$out/Broken.csv", 'no partial file');
	ok(-e "$out/Orders.csv", 'good table exported');
	my ($total, $failed) = (scalar(@tables), scalar(@tables) - 1);
	like($logger->{lines}[-1], qr/Processed $total tables, $failed failed/, 'summary');
};

subtest 'existing files' => sub {
	my ($status, $out, undef, undef, undef, $e, $db) = export(['Orders']);
	is($status, 0, 'first run');

	my $stderr;
	(undef, $stderr) = capture { $status = $e->run($db) };
	is($status, 1, 'second run fails without --overwrite');
	like($stderr, qr/Output file already exists: .*Orders\.csv \(use --overwrite/, 'explains why');

	$e->{overwrite} = 1;
	(undef, $stderr) = capture { $status = $e->run($db) };
	is($status, 0, 'succeeds with overwrite');
	ok(-f "$out/Orders.csv", 'file is still there');
};

subtest 'names are the same on every run' => sub {
	my ($status, $out, undef, undef, undef, $e, $db) = export(['A/B', 'A:B'], overwrite => 1);
	capture { $status = $e->run($db) };
	is($status, 0, 'second run');
	opendir(my $dh, $out);
	is_deeply([sort grep { /\.csv$/ } readdir $dh], ['A_B.csv', 'A_B_2.csv'], 'no A_B_3.csv on the second run');
};

subtest 'table filter' => sub {
	my ($status, $out, undef, $stderr, $logger) = export([qw(A B C)], tables => [qw(C A Nope Nada)]);
	is($status, 0, 'success');
	ok(-e "$out/A.csv" && -e "$out/C.csv" && !-e "$out/B.csv", 'only the wanted tables');
	like($stderr, qr/Tables not found in database: Nada, Nope/, 'unknown tables reported (plural)');

	(undef, undef, undef, $stderr) = export([qw(A)], tables => [qw(Zed)]);
	like($stderr, qr/Table not found in database: Zed/, 'singular form');
};

subtest 'an empty table list exports nothing (documented pitfall)' => sub {
	my ($status, $out, undef, undef, $logger) = export([qw(A B)], tables => []);
	is($status, 0, 'success');
	ok(!-e "$out/A.csv" && !-e "$out/B.csv", 'no files');
	like($logger->{lines}[-1], qr/Processed 0 tables, 0 failed/, 'summary');
};

subtest 'undef settings mean "use the default"' => sub {
	my $e = App::Access2CSV::Exporter->new(progress => undef, encoding => undef);
	is($e->{progress}, 1, 'progress default');
	is($e->{encoding}, 'utf8', 'encoding default');
};

subtest 'dry run writes nothing' => sub {
	my ($status, $out, $stdout) = export([qw(Orders Customers)], dry_run => 1);
	is($status, 0, 'success');
	ok(!-e $out, 'output directory not created');
	like($stdout, qr/DRY RUN\n=======\n/, 'title');
	like($stdout, qr/^TABLE\s+OUTPUT FILE$/m, 'header');
	like($stdout, qr/^Customers\s+Customers\.csv$/m, 'row');
	unlike($stdout, qr/ROWS/, 'no ROWS column without --show-counts');
};

subtest 'row counts' => sub {
	my ($status, $out, $stdout) = export(['Orders'], dry_run => 1, show_counts => 1);
	like($stdout, qr/^TABLE\s+ROWS\s+OUTPUT FILE$/m, 'ROWS column');
	like($stdout, qr/^Orders\s+1\s+Orders\.csv$/m, 'count shown');

	my $logger;
	($status, $out, undef, undef, $logger) = export(['Orders'], show_counts => 1);
	ok((grep { /Exported Orders => .* \(1 row\)/ } @{ $logger->{lines} }), 'count logged, singular');
};

subtest 'missing mdb-count is not fatal' => sub {
	local $ENV{PATH} = fake_path(qw(mdb-tables mdb-export));
	my ($status, undef, $stdout, $stderr) = export(['Orders'], dry_run => 1, show_counts => 1);
	is($status, 0, 'still succeeds');
	like($stderr, qr/mdb-count not found in PATH; row counts are unavailable/, 'warned');
	unlike($stdout, qr/ROWS/, 'no ROWS column');
};

subtest 'verbose logs where programs were found' => sub {
	my (undef, undef, undef, undef, $logger) = export(['Orders'], verbose => 1);
	ok((grep { /^DEBUG Found mdb-export at / } @{ $logger->{lines} }), 'debug message');
};

subtest 'fatal errors' => sub {
	my $e = App::Access2CSV::Exporter->new(progress => 0);
	my $dir = tempdir(CLEANUP => 1);

	throws_ok { $e->run(File::Spec->catfile($dir, 'missing.accdb')) } qr/Cannot read database .*missing\.accdb: /, 'missing database';
	throws_ok { $e->run($dir) } qr/is not a regular file/, 'directory';
	throws_ok { $e->run() } qr/database/, 'no argument';

	SKIP: {
		skip('root can read anything', 1) if $> == 0;
		skip('chmod cannot make a file unreadable on Windows', 1) if $^O eq 'MSWin32';
		my $db = make_database($dir, 'A');
		chmod 0, $db;
		throws_ok { $e->run($db) } qr/is not readable/, 'unreadable';
		chmod 0644, $db;
	}

	my $bad = File::Spec->catfile($dir, 'bad');
	mkdir $bad;
	my $db = make_database($bad, 'FAIL');
	throws_ok { $e->run($db) } qr/mdb-tables failed with exit status 2: not an Access database/, 'mdb-tables failure';

	local $ENV{PATH} = fake_path('mdb-tables');
	throws_ok { $e->run($db) } qr/Required program not found in PATH: mdb-export/, 'missing program';
};

subtest 'output directory cannot be created' => sub {
	SKIP: {
		skip('root can write anywhere', 2) if $> == 0;
		skip('Windows has no Unix permission bits', 2) if $^O eq 'MSWin32';
		my $dir = tempdir(CLEANUP => 1);
		my $db = make_database($dir, 'A');
		my $blocker = File::Spec->catfile($dir, 'file');
		open my $fh, '>', $blocker;
		close $fh;
		my $e = App::Access2CSV::Exporter->new(progress => 0, output_dir => File::Spec->catdir($blocker, 'sub'));
		throws_ok { $e->run($db) } qr/Cannot create output directory .*sub: /, 'croaks';
		ok(!-d File::Spec->catdir($blocker, 'sub'), 'nothing created');
	}
};

subtest 'private and protected methods are enforced' => sub {
	local $Sub::Private::config{harness_bypass} = 0;
	local $Sub::Protected::config{harness_bypass} = 0;
	local $Sub::Private::BYPASS = 0;
	local $Sub::Protected::BYPASS = 0;

	my $e = App::Access2CSV::Exporter->new();
	throws_ok { $e->_run_program('mdb-tables', [], \my $x) } qr/private/, 'private';
	throws_ok { $e->_csv_filename('x') } qr/protected/, 'protected';
};

done_testing();
