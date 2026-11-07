use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use File::Temp qw(tempdir);
use JSON::PP ();
use Test::More;

use App::WebPerimeterScan;

# Black-box: bin/webperimeter is run as a separate process, as a user would.
my $SCRIPT = "$FindBin::Bin/../bin/webperimeter";
my $TMP    = tempdir(CLEANUP => 1);

# Run the script and return its exit status, standard output and standard
# error.  STDERR is redirected to a file rather than read through a second
# pipe, so a large report on one stream cannot deadlock the other.
sub run_cli {
	my @args = @_;
	my $err_file = "$TMP/stderr";

	open my $saved, '>&', \*STDERR or die "dup STDERR: $!";
	open STDERR, '>', $err_file or die "$err_file: $!";
	my $out = do {
		open my $pipe, '-|', $^X, "-I$FindBin::Bin/../lib", $SCRIPT, @args or die "run $SCRIPT: $!";
		local $/;
		my $text = <$pipe> // '';
		close $pipe;
		$text;
	};
	my $status = $? >> 8;
	open STDERR, '>&', $saved or die "restore STDERR: $!";

	open my $fh, '<', $err_file or die "$err_file: $!";
	my $err = do { local $/; <$fh> } // '';
	close $fh;
	return { status => $status, out => $out, err => $err };
}

sub write_file {
	my ($name, $text) = @_;
	my $path = "$TMP/$name";
	open my $fh, '>', $path or die "$path: $!";
	print {$fh} $text;
	close $fh;
	return $path;
}

# An address literal, so that the dry run, which checks whether each host
# is private, never needs DNS.  203.0.113.0/24 is reserved for documentation.
my $scope = write_file('scope.txt', "# a comment\n203.0.113.10\n");

subtest 'information' => sub {
	my $r = run_cli('--version');
	is($r->{status}, 0, '--version exits 0');
	like($r->{out}, qr/\Q$App::WebPerimeterScan::VERSION\E/, '... and prints the version');

	$r = run_cli('-V');
	is($r->{status}, 0, '-V is the same');

	$r = run_cli('--help');
	is($r->{status}, 0, '--help exits 0');
	like($r->{out} . $r->{err}, qr/--authorized/, '... and describes --authorized');
};

subtest 'nothing is sent without authorisation or a valid command line' => sub {
	my $r = run_cli('--scope', $scope);
	is($r->{status}, 2, 'no --authorized: usage error');
	like($r->{err}, qr/authori[sz]/i, '... saying why');

	$r = run_cli('--authorized');
	is($r->{status}, 2, 'no --scope: usage error');

	$r = run_cli('--authorized', '--scope', "$TMP/missing.txt");
	is($r->{status}, 2, 'a missing scope file is a usage error');
	unlike($r->{err}, qr/ line \d+\.?$/m, '... with no Perl file/line in the message');

	for my $bad (
		[ [ '--format', 'xml' ],        'an unknown format' ],
		[ [ '--fail-on', 'severe' ],    'an unknown --fail-on level' ],
		[ [ '--ports', '80,http' ],     'a non-numeric port' ],
		[ [ '--ports', '0' ],           'port 0' ],
		[ [ '--ports', '65536' ],       'a port above 65535' ],
		[ [ '--docroot', "$TMP/nope" ], 'a missing docroot' ],
		[ [ '--source', $scope ],       'a source path that is a file' ],
		[ [ '--bogus' ],                'an unknown option' ],
	) {
		my ($args, $what) = @{$bad};
		$r = run_cli('--authorized', '--scope', $scope, '--dry-run', @{$args});
		is($r->{status}, 2, "$what is refused before any traffic");
	}
};

subtest 'dry run' => sub {
	my $r = run_cli('--authorized', '--scope', $scope, '--dry-run', '--ports', '80,443', '-f', 'json');
	is($r->{status}, 0, '--dry-run exits 0');
	like($r->{out} . $r->{err}, qr/203\.0\.113\.10/, '... and lists the host it would scan');
	like($r->{out} . $r->{err}, qr/\b443\b/, '... and the ports');
};

SKIP: {
	skip 'the loopback test server needs fork', 1 if $^O eq 'MSWin32';
	require TestServer;

	my $server = TestServer->start(
		'/' => [ 200, [ 'Content-Type: text/html', 'Server: Apache/2.4.1' ], '<html><title>t</title></html>' ],
	) or skip 'cannot start the test server', 1;
	my $port = $server->port;
	my $local = write_file('local.txt', "127.0.0.1:$port\n");
	my @scan = ('--authorized', '--scope', $local, '--allow-private', '--ports', $port,
		'--delay', 0, '--timeout', 5, '--no-path-probes');

	subtest 'a real scan' => sub {
		my $r = run_cli(@scan, '-f', 'json', '--fail-on', 'never');
		is($r->{status}, 0, '--fail-on never exits 0 whatever is found');
		my $report = eval { JSON::PP->new->decode($r->{out}) };
		ok($report, 'JSON output parses') or diag $r->{out}, $r->{err};
		ok((grep { $_->{id} eq 'csp-missing' } @{ $report->{findings} || [] }), '... and contains the findings');

		$r = run_cli(@scan, '--fail-on', 'info', '--no-color');
		is($r->{status}, 1, '--fail-on info exits 1 when anything is found');
		like($r->{out}, qr/csp-missing|Content-Security-Policy/, 'text output names the finding');
		unlike($r->{out}, qr/\e\[/, '--no-color writes no escape codes');

		# The British spelling is accepted for both forms of the option.
		$r = run_cli(@scan, '--fail-on', 'never', '--no-colour');
		is($r->{status}, 0, '--no-colour is accepted');
		unlike($r->{out}, qr/\e\[/, '... and writes no escape codes');

		# Standard output is a pipe here, so colour appears only if forced.
		$r = run_cli(@scan, '--fail-on', 'never', '--colour');
		is($r->{status}, 0, '--colour is accepted');
		like($r->{out}, qr/\e\[/, '... and forces colour even into a pipe');

		my $file = "$TMP/report.html";
		$r = run_cli(@scan, '-f', 'html', '-o', $file, '--fail-on', 'never');
		is($r->{status}, 0, '--output exits 0');
		like($r->{out}, qr/\AReport written to \Q$file\E\n\z/, '... and says only where the report went');
		ok(-s $file, '... but the report file');

		$r = run_cli('--authorized', '--scope', $local, '--ports', $port, '--delay', 0, '--fail-on', 'high', '-f', 'json');
		is($r->{status}, 1, 'a private target without --allow-private fails the high gate');
		like($r->{out}, qr/scan-error/, '... as a scan error');
	};

	$server->stop;
}

done_testing();
