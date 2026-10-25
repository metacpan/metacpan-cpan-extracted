use strict;
use warnings;
use Test::Most;

use File::Spec;
use FindBin qw($Bin);

use lib 't/lib';
use TestSync;

use App::FileSync::Server;

my $pinned = { repo => 'docs', client => 'test-1', role => 'client', root => '/srv/filesync' };

sub check {
	my ($original) = @_;
	return App::FileSync::Server::validate_forced_command($original, $pinned);
}

for my $ok (undef, '', '   ',
			'filesync-server',
			'filesync-server --repo docs --client test-1 --role client --proto 2',
			'filesync-server --repo=docs --client=test-1 --role=client --proto=2',
			'/usr/local/bin/filesync-server --repo docs --client test-1 --role client --proto 2',
			'--repo docs --client test-1 --role client --proto 2') {
	my ($good, $reason) = check($ok);
	ok($good, 'accepts ' . (defined $ok ? "'$ok'" : 'no command')) or diag($reason);
}

my @refused = (
	['filesync-server --repo other --client test-1 --role client', qr/pinned to 'docs'/],
	['filesync-server --repo docs --client other --role client', qr/pinned to 'test-1'/],
	['filesync-server --repo docs --client test-1 --role replica', qr/pinned to 'client'/],
	['filesync-server --repo docs --client test-1 --role client --root /etc', qr/may not set --root/],
	['filesync-server --repo docs --client test-1 --role client --proto 1', qr/protocol '1'/],
	['filesync-server --repo docs extra', qr/unexpected argument 'extra'/],
	['filesync-server --repo', qr/without a value/],
	['bash -c "cat /etc/shadow"', qr/unexpected program 'bash'/],
	['filesync-server --repo docs --client test-1 --role client --root=/etc', qr/may not set --root/],
);

for my $case (@refused) {
	my ($original, $pattern) = @{$case};
	my ($good, $reason) = check($original);
	ok(!$good, "refuses '$original'") or diag('accepted it');
	like($reason || '', $pattern, '  with a useful reason');
}

# --- through the server binary -------------------------------------------

my $env = TestSync->new_env();
my $perl = $^X;
my $server = File::Spec->catfile($Bin, '..', 'bin', 'filesync-server');

sub run_server_with {
	my ($original) = @_;

	local $ENV{SSH_ORIGINAL_COMMAND} = $original;
	local $ENV{FILESYNC_ALLOW_TTY} = 1;

	my $command = join ' ',
		$perl, $server,
		'--root', $env->{server},
		'--repo', 'docs',
		'--client', 'test-1',
		'--role', 'client',
		'--proto', '2';

	my $devnull = File::Spec->devnull;
	my $output = qx{$command <$devnull 2>&1};
	return ($? >> 8, $output);
}

my ($code, $output) = run_server_with('filesync-server --repo other --client test-1 --role client');
isnt($code, 0, 'a session asking for another repo is refused');
like($output, qr/pinned to 'docs'/, 'the refusal explains the pinning');
unlike($output, qr/Hash mismatch|Manifest/, 'the session never reaches the protocol');

($code, $output) = run_server_with(
	'filesync-server --repo docs --client test-1 --role client --proto 2');
isnt($code, 0, 'a matching command is let through to the protocol');
unlike($output, qr/pinned to|may not set/,
	'a matching command is not refused by the forced-command check');

($code, $output) = run_server_with(
	'filesync-server --repo docs --client test-1 --role client --root /tmp');
like($output, qr/may not set --root/, 'the client cannot choose its own root');

done_testing();
