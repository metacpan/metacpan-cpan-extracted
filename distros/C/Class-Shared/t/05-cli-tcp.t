use strict;
use warnings;

use Test::More;
use Test::Needs;
use Class::Shared ();
use File::Spec ();
use File::Temp qw(tempdir);
use IO::Socket::INET;
use POSIX ();
use lib 't/lib';

# The admin commands have to verify the backend, prove themselves and sign
# their frames too, so check them against a TLS, token-protected TCP backend
# rather than the unix socket t/03-cli.t uses.

# That backend keeps its lock, pid file and log beside a unix socket path in an
# owner-only directory, so it needs both: the control path is asked for before
# the directory is even looked at.  The module is asked whether it can make the
# socket, and Test::Permissions whether a directory here can really be made
# owner-only, so a perl that cannot provide both is skipped rather than failing
# when the backend starts.
BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'a backend here keeps its lock, pid file and log beside a '
		. 'unix socket path in an owner-only directory, which this perl '
		. 'cannot provide (Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

BEGIN {
	test_needs 'IO::Socket::SSL';
}

use Net::SSLeay ();

# The certificate paths are filled in by the BEGIN block below, along with the
# rest of the setup, so that they exist before that block runs.
our %pem;

sub fingerprint {
	my ($pem) = @_;

	my $bio = Net::SSLeay::BIO_new_file($pem, 'r') or return undef;
	my $cert = Net::SSLeay::PEM_read_bio_X509($bio) or return undef;
	Net::SSLeay::BIO_free($bio);
	my $digest = Net::SSLeay::EVP_get_digestbyname('sha256') or return undef;

	return unpack('H*', Net::SSLeay::X509_digest($cert, $digest));
}

# Everything that decides whether this file can run, and the backend it runs
# against, is set up here, at compile time, before a test is output: a skip_all
# after tests have run is a plan for zero tests, which TAP reads as a bad plan,
# so no test ever added above a skip can be allowed to make one.  The child
# exec()s inside this block and never returns, so forking here is safe.
our ($dir, $probe, $port, $token_file, $bad_token_file, $pid);

BEGIN {
	my $certs = File::Spec->catdir('t', 'certs');
	%pem = map { $_ => File::Spec->catfile($certs, "$_.pem") }
		qw(ca server server-key client client-key other-ca other-server
		other-client other-client-key);

	$dir = tempdir(CLEANUP => 1);

	# Take a free port by opening one and letting it go again.
	$probe = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Proto     => 'tcp',
		Listen    => 1,
		ReuseAddr => 1,
	) or plan skip_all => "cannot open a listening TCP socket: $!";

	$port = $probe->sockport;
	close $probe;

	$token_file = File::Spec->catfile($dir, 'token');
	open(my $token_fh, '>', $token_file)
		or plan skip_all => "cannot write $token_file: $!";
	print {$token_fh} "cli-s3cret\n";
	close $token_fh;

	$bad_token_file = File::Spec->catfile($dir, 'bad-token');
	open(my $bad_token_fh, '>', $bad_token_file)
		or plan skip_all => "cannot write $bad_token_file: $!";
	print {$bad_token_fh} "not-the-token\n";
	close $bad_token_fh;

	$pid = fork;
	plan skip_all => "cannot fork: $!" unless defined $pid;

	if ($pid == 0) {
		no warnings 'exec';    # exec() does not return when it works
		exec(
			$^X, '-Ilib', '-It/lib', 'bin/class-shared', 'start',
			'--listen', "tcp:127.0.0.1:$port",
			'--token-file', $token_file,
			'--tls-cert', $pem{server},
			'--tls-key', $pem{'server-key'},
			'--tls-ca', $pem{ca},
			'--dir', $dir,
			'-f',
		);
		POSIX::_exit(127);
	}
}

END {
	kill 'TERM', $pid if $pid && kill(0, $pid);
}

my $ready = 0;
for (1 .. 200) {
	my $probe_socket = IO::Socket::SSL->new(
		PeerAddr        => '127.0.0.1',
		PeerPort        => $port,
		Proto           => 'tcp',
		Timeout         => 2,
		SSL_ca_file     => $pem{ca},
		SSL_cert_file   => $pem{client},
		SSL_key_file    => $pem{'client-key'},
		SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
	);
	if ($probe_socket) {
		close $probe_socket;
		$ready = 1;
		last;
	}
	select(undef, undef, undef, 0.05);
}

ok($ready, 'the TLS, token-protected TCP backend came up')
	or BAIL_OUT('no backend to test against');

my $cli = "$^X -Ilib -It/lib bin/class-shared";
my $tls = "--tls-cert $pem{client} --tls-key $pem{'client-key'} --tls-ca $pem{ca}";
my $where = "--host 127.0.0.1 --port $port --token-file $token_file $tls";

# status.
my $status = `$cli status $where 2>&1`;
is($?, 0, 'status exits successfully over TCP') or diag $status;
like($status, qr/^pid $pid\b/m, 'status names the backend we started');
like($status, qr/address: 127\.0\.0\.1:$port/, 'and the TCP address');
like($status, qr/0 object\(s\)/, 'with no objects, since status makes none');
like($status, qr/\d+ call\(s\)/, 'and its call counter');
like($status, qr/clients: \d+/, 'and its client count');

# The CLI signs its frames, so a secret it does not have gets it nowhere.
my $wrong = `$cli status --host 127.0.0.1 --port $port --token-file $bad_token_file $tls 2>&1`;
isnt($?, 0, 'status with the wrong token fails');
like($wrong, qr/failed authentication/, 'and says the frames did not authenticate');

# A client certificate the backend will not accept closes the connection during
# the handshake, before any frame: say that, rather than reporting a closed
# stream that suggests nothing in particular.
my $bad_cert = `$cli status --host 127.0.0.1 --port $port --token-file $token_file --tls-cert $pem{'other-client'} --tls-key $pem{'other-client-key'} --tls-ca $pem{ca} 2>&1`;
isnt($?, 0, 'status with a client certificate the backend refuses fails');
like($bad_cert, qr/refused this client's certificate/,
	'and says the certificate was refused');
like($bad_cert, qr/--tls-cert.*--tls-ca/, 'naming the options worth checking');

# The CLI verifies the backend before it sends a frame, so a CA that did not
# sign it is the end of the attempt.
my $untrusted = `$cli status --host 127.0.0.1 --port $port --token-file $token_file --tls-cert $pem{client} --tls-key $pem{'client-key'} --tls-ca $pem{'other-ca'} 2>&1`;
isnt($?, 0, 'status with a CA that did not sign the backend fails');
like($untrusted, qr/TLS failed|certificate verify/i, 'and says the certificate did not verify');

# And it will not talk in the clear to a backend that speaks TLS.
my $no_tls = `$cli status --host 127.0.0.1 --port $port --token-file $token_file 2>&1`;
isnt($?, 0, 'status without TLS options fails');
like($no_tls, qr/--tls-cert/, 'and names the options it needs');

my $unsigned = `$cli status --host 127.0.0.1 --port $port $tls 2>&1`;
isnt($?, 0, 'status with no token fails');

my ($unsigned_first) = split /\n/, $unsigned;
like($unsigned_first,
	qr/\Aclass-shared: handshake failed: this backend may require a token/,
	'and leads with the hint instead of a Storable complaint');
like($unsigned, qr/^detail: .*(?:deserialise|read the response)/m,
	'keeping the underlying complaint on a detail line');

my $unsigned_stop = `$cli stop --host 127.0.0.1 --port $port $tls 2>&1`;
isnt($?, 0, 'stop with no token fails');
like($unsigned_stop, qr/may require a token/, 'and gives stop the same hint');

# A pin replaces the CA on the client side: the command still proves who it is
# with --tls-cert/--tls-key, and checks the backend by digest alone.
my $pin = fingerprint($pem{server});
my $pinned = "--tls-cert $pem{client} --tls-key $pem{'client-key'} --tls-fingerprint $pin";

my $pinned_status = `$cli status --host 127.0.0.1 --port $port --token-file $token_file $pinned 2>&1`;
is($?, 0, 'status works with a pinned fingerprint instead of a CA')
	or diag $pinned_status;
like($pinned_status, qr/^pid $pid\b/m, 'and reaches the right backend');

my $bad_pin = fingerprint($pem{'other-server'});
my $wrong_pin = `$cli status --host 127.0.0.1 --port $port --token-file $token_file --tls-cert $pem{client} --tls-key $pem{'client-key'} --tls-fingerprint $bad_pin 2>&1`;
isnt($?, 0, 'status with a pin that does not match the backend fails');
like($wrong_pin, qr/TLS failed|certificate verify/i,
	'and says the certificate did not verify');

my $both = `$cli status --host 127.0.0.1 --port $port --token-file $token_file $tls --tls-fingerprint $pin 2>&1`;
isnt($?, 0, 'status with both a CA and a pin fails');
like($both, qr/not both/, 'because they are alternatives');

# A backend that survived the refusals still answers the real thing.
my $again = `$cli status $where 2>&1`;
is($?, 0, 'status still works after the refusals') or diag $again;

# stop.
my $stopped = `$cli stop $where 2>&1`;
is($?, 0, 'stop exits successfully over TCP') or diag $stopped;
like($stopped, qr/^stopped$/m, 'stop says it stopped');

waitpid($pid, 0);
is($?, 0, 'the backend we stopped exited cleanly');
undef $pid;

done_testing();
