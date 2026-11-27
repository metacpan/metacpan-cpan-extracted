use strict;
use warnings;

use Test::More;
use Test::Needs;
use Class::Shared ();
use File::Spec ();
use File::Temp qw(tempdir);
use IO::Socket::INET;
use Time::HiRes ();
use POSIX ();
use lib 't/lib';

# A backend here keeps its lock, pid file and log beside a unix socket path in
# an owner-only directory, so it needs both: the control path is asked for
# before the directory is even looked at.  The module is asked whether it can
# make the socket, and Test::Permissions whether a directory here can really be
# made owner-only, so a perl that cannot provide both is skipped rather than
# failing when a backend starts.
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

use Class::Shared::Frontend;
use Class::Shared::Protocol;

# Fixtures from t/certs; see t/certs/make-certs.sh.  The server certificates
# name localhost and 127.0.0.1, because the tests connect to that address and
# the hostname is checked along with the chain.
my $certs = File::Spec->catdir('t', 'certs');
my %pem = map { $_ => File::Spec->catfile($certs, "$_.pem") }
	qw(ca server server-key client client-key other-ca other-client other-client-key
	other-server);

# The SHA-256 digest of a certificate, which is what a pin is.
sub fingerprint {
	my ($pem) = @_;

	my $bio = Net::SSLeay::BIO_new_file($pem, 'r') or return undef;
	my $cert = Net::SSLeay::PEM_read_bio_X509($bio) or return undef;
	Net::SSLeay::BIO_free($bio);
	my $digest = Net::SSLeay::EVP_get_digestbyname('sha256') or return undef;

	return unpack('H*', Net::SSLeay::X509_digest($cert, $digest));
}

# Whether this file can run at all is settled here, at compile time, before a
# test is output: a skip_all after tests have run is a plan for zero tests,
# which TAP reads as a bad plan, so no test ever added above a skip can be
# allowed to make one.
our ($dir, $probe, $port, $token_file);

BEGIN {
	$dir = tempdir(CLEANUP => 1);

	# Take a free port, and hold it until the refusals below have been checked.
	$probe = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Proto     => 'tcp',
		Listen    => 1,
		ReuseAddr => 1,
	) or plan skip_all => "cannot open a listening TCP socket: $!";

	$port = $probe->sockport;

	$token_file = File::Spec->catfile($dir, 'token');
	open(my $token_fh, '>', $token_file)
		or plan skip_all => "cannot write $token_file: $!";
	print {$token_fh} "s3cret-token\n";
	close $token_fh;
}

my $tls = "--tls-cert $pem{server} --tls-key $pem{'server-key'} --tls-ca $pem{ca}";
my $base = "$^X -Ilib -It/lib bin/class-shared start "
	. "--listen tcp:127.0.0.1:$port --dir $dir -f";

# A port anybody can route to must not be a port where a stranger's bytes reach
# Storable::thaw, and must not be a port where they are readable either, so a
# TCP listener needs both a token and TLS, and refuses to start without either.
#
# The port is still held while those two start: a listener that bound before
# it checked its policy would fail with "address already in use" rather than
# the message that names what is missing, so those messages prove the refusal
# comes first.  The backend below then starts on the port, which proves the
# refusals left it free, without asking the host whether a connect to a free
# port fails.
my $tokenless = `$base $tls 2>&1`;
isnt($?, 0, 'a TCP listener with no token refuses to start');
like($tokenless, qr/needs a token/, 'and says that a token is required');
unlike($tokenless, qr/in use/i, 'and refuses before it binds the port');

my $plaintext = `$base --token-file $token_file 2>&1`;
isnt($?, 0, 'a TCP listener with no TLS refuses to start');
like($plaintext, qr/needs --tls-cert, --tls-key and --tls-ca/,
	'and says which TLS files it needs');
unlike($plaintext, qr/in use/i, 'and refuses before it binds the port');

close $probe;

# Nothing is listening on the port the refusals were given: a listening socket
# cannot be bound where another one already listens, so taking the port again
# says so directly, without asking the host what a connect to a free port does.
my $rebound = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => $port,
	Proto     => 'tcp',
	Listen    => 1,
	ReuseAddr => 1,
);
ok($rebound, 'and left nothing listening on the port')
	or diag "cannot bind 127.0.0.1:$port again: $!";
close $rebound if $rebound;

# The backend cannot be forked above the refusals: it binds the port the probe
# holds, and the probe is released only once they have run.  So a fork that
# fails here is a bail-out rather than a skip, like the three other forks in
# this file: a skip would have to come after tests, which is the bad plan the
# rest of the file's setup is arranged to avoid.
my $pid = fork;
BAIL_OUT("cannot fork: $!") unless defined $pid;

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

END {
	kill 'TERM', $pid if $pid && kill(0, $pid);
}

# A frontend with the certificate and CA a working client uses.
sub frontend {
	my (%override) = @_;

	my %opt = (
		host       => '127.0.0.1',
		port       => $port,
		token_file => $token_file,
		tls_ca     => $pem{ca},
		tls_cert   => $pem{client},
		tls_key    => $pem{'client-key'},
	);

	for my $key (keys %override) {
		if (defined $override{$key}) {
			$opt{$key} = $override{$key};
		} else {
			delete $opt{$key};
		}
	}

	return Class::Shared::Frontend->new('Shared::Counter', %opt);
}

my $ready = 0;
for (1 .. 200) {
	my $probe_socket = eval { frontend() };
	if ($probe_socket) {
		$probe_socket->shared_close;
		$ready = 1;
		last;
	}
	select(undef, undef, undef, 0.05);
}

ok($ready, 'the TLS backend came up and a verified client reached it')
	or BAIL_OUT('no backend to test against');

my $frontend = frontend(ctor => [start => 5]);

is($frontend->shared_pid, $pid, 'the frontend talks to the backend we started');
is($frontend->shared_address, "127.0.0.1:$port", 'it knows the address');
is($frontend->value, 5, 'the object was constructed in the backend');
is($frontend->inc, 6, 'a call works over TLS');

my $second = frontend(ctor => [start => 1]);

isnt($second->shared_id, $frontend->shared_id, 'a second client gets its own object');
is($second->value, 1, 'with its own state');
is($frontend->value, 6, 'and neither disturbs the other');
is($second->shared_pid, $frontend->shared_pid, 'both objects share the one backend');

# Verification.  A client that cannot verify the backend, or that the backend
# cannot verify, has to end up with nothing, not with a connection it believes
# in.
my $constructed = $frontend->shared_status->{constructed};

my @refused = (
	[
		'a CA that did not sign the backend',
		{ tls_ca => $pem{'other-ca'} },
		qr/certificate verify|verify|TLS/i,
	],
	[
		'a certificate from a CA the backend does not trust',
		{ tls_cert => $pem{'other-client'}, tls_key => $pem{'other-client-key'} },
		qr/refused this client's certificate.*tls_cert.*tls_ca/s,
	],
);

for my $case (@refused) {
	my ($label, $override, $expected) = @{$case};

	my $object = eval { frontend(%{$override}) };

	ok(!defined $object, "a client with $label gets no object");
	like($@, $expected, 'and is told why');
}

is($frontend->shared_status->{constructed}, $constructed,
	'and the backend constructed nothing for either of them');

# A pin is the other way to verify: the same certificate, named by its digest
# instead of by who signed it, so no CA file is involved at all.
my $server_fp = fingerprint($pem{server});
my $other_fp  = fingerprint($pem{'other-server'});

ok(defined $server_fp && $server_fp =~ /\A[0-9a-f]{64}\z/,
	'the backend certificate has a SHA-256 fingerprint');

is(Class::Shared::normalise_fingerprint(uc join(':', $server_fp =~ /../g)),
	"sha256\$$server_fp",
	'a fingerprint in the form openssl prints is normalised for the TLS layer');

my $pinned = eval {
	frontend(tls_ca => undef, tls_fingerprint => join(':', $server_fp =~ /../g),
		ctor => [start => 7]);
};
ok($pinned, 'a pinned fingerprint connects with no CA file') or diag $@;
is($pinned->value, 7, 'and the pinned object works') if $pinned;
$pinned->shared_close if $pinned;

my $wrong_pin = eval { frontend(tls_ca => undef, tls_fingerprint => $other_fp) };
ok(!defined $wrong_pin, 'a pin the backend does not match gets no object');
like($@, qr/certificate verify|TLS/i, 'and is told the certificate did not verify');

my $both = eval { frontend(tls_fingerprint => $server_fp) };
ok(!defined $both, 'a CA and a pin together are refused');
like($@, qr/not both/, 'because they are alternatives');

my $neither = eval { frontend(tls_ca => undef) };
ok(!defined $neither, 'a TCP frontend with neither a CA nor a pin is refused');
like($@, qr/tls_ca or tls_fingerprint/, 'and says verification needs one of them');

is($frontend->shared_status->{constructed}, $constructed + 1,
	'and only the pin that matched the backend constructed anything');

# The object the pinned client built is real, so it is the new baseline.
$constructed = $frontend->shared_status->{constructed};

# The token still has to be right once TLS is established: the two are separate
# checks, and either one alone is not the whole answer.
my $no_token = eval { frontend(token_file => undef) };
ok(!defined $no_token, 'a TLS client without the token gets no object');
like($@, qr/may require a token|failed authentication/, 'and is told why');

my $wrong_token = eval { frontend(token => 'not-the-token', token_file => undef) };
ok(!defined $wrong_token, 'a TLS client with the wrong token gets no object');
like($@, qr/failed authentication/, 'and is told that its frames do not authenticate');

is($frontend->shared_status->{constructed}, $constructed,
	'and neither of those reached the constructor either');

# A client with no certificate at all may finish its own side of a TLS 1.3
# handshake before the backend's refusal arrives, but it never gets a reply.
my $certless = IO::Socket::SSL->new(
	PeerAddr        => '127.0.0.1',
	PeerPort        => $port,
	Proto           => 'tcp',
	Timeout         => 5,
	SSL_ca_file     => $pem{ca},
	SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
);

if ($certless) {
	my ($hello) = Class::Shared::Protocol::encode_frame({
		op    => 'hello',
		proto => $Class::Shared::PROTOCOL_VERSION,
		class => 'Shared::Counter',
	}, 's3cret-token');

	Class::Shared::Protocol::write_all($certless, $hello);

	my ($reply, $read_error) = Class::Shared::Protocol::read_frame($certless, 5, 's3cret-token');
	is($reply, undef, 'a client with no certificate gets no reply');
	like($read_error, qr/closed|read failed|exceeds the limit/i,
		'because the backend dropped it without a frame');

	close $certless;
} else {
	pass('a client with no certificate cannot even connect')
		for 1 .. 1;
	pass('and so gets no reply') for 1 .. 1;
}

# A TLS client whose handshake has finished and which has not greeted yet is in
# AWAITING HELLO: the first frame it sends has to be the hello, and it is told
# so rather than being dropped or served.  The hello then still works on the
# same connection, so the refused request changed nothing.
{
	my $early = IO::Socket::SSL->new(
		PeerAddr        => '127.0.0.1',
		PeerPort        => $port,
		Proto           => 'tcp',
		Timeout         => 5,
		SSL_ca_file     => $pem{ca},
		SSL_cert_file   => $pem{client},
		SSL_key_file    => $pem{'client-key'},
		SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
	) or BAIL_OUT('cannot open a verified TLS connection for the early request');

	my ($request) = Class::Shared::Protocol::encode_frame({ op => 'new', args => [] },
		's3cret-token');
	my ($sent) = Class::Shared::Protocol::write_all($early, $request);
	ok($sent, 'a request before the hello is sent over TLS');

	my ($refused, $refused_error) = Class::Shared::Protocol::read_frame($early, 5, 's3cret-token');
	ok($refused, 'the backend answers it') or diag $refused_error;

	if ($refused) {
		is($refused->{kind}, 'protocol', 'as a protocol failure');
		is($refused->{error}, 'handshake required',
			'because a finished TLS handshake leaves the client AWAITING HELLO');

		my ($hello) = Class::Shared::Protocol::encode_frame({
			op    => 'hello',
			proto => $Class::Shared::PROTOCOL_VERSION,
			class => 'Shared::Counter',
		}, 's3cret-token');
		Class::Shared::Protocol::write_all($early, $hello);

		my ($greeted) = Class::Shared::Protocol::read_frame($early, 5, 's3cret-token');
		ok($greeted && $greeted->{ok},
			'and the hello on the same connection is accepted');
		is($greeted->{class}, 'Shared::Counter', 'so the refused request changed no state')
			if $greeted;
	}

	close $early;
}

# A frame this backend cannot authenticate must be refused before it is thawed.
# The bodies below are valid Storable images, so the digest is the only thing
# between them and the backend's interpreter.
my @forged = (
	[
		'signed with the wrong secret',
		(Class::Shared::Protocol::encode_frame({
			op    => 'hello',
			proto => $Class::Shared::PROTOCOL_VERSION,
			class => 'Shared::Counter',
		}, 'not-the-token'))[0],
	],
	[
		'with no digest at all',
		(Class::Shared::Protocol::encode_frame({
			op    => 'hello',
			proto => $Class::Shared::PROTOCOL_VERSION,
			class => 'Shared::Counter',
		}))[0],
	],
);

for my $case (@forged) {
	my ($label, $frame) = @{$case};

	ok(defined $frame, "a frame $label is built") or next;

	my $raw = IO::Socket::SSL->new(
		PeerAddr        => '127.0.0.1',
		PeerPort        => $port,
		Proto           => 'tcp',
		Timeout         => 5,
		SSL_ca_file     => $pem{ca},
		SSL_cert_file   => $pem{client},
		SSL_key_file    => $pem{'client-key'},
		SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
	) or BAIL_OUT('cannot open a verified TLS connection to the backend');

	my ($sent) = Class::Shared::Protocol::write_all($raw, $frame);
	ok($sent, 'and sent to the backend');

	my ($reply, $read_error) = Class::Shared::Protocol::read_frame($raw, 5, 's3cret-token');
	ok(defined $reply, 'the backend answers') or diag $read_error;
	next unless $reply;

	ok(!$reply->{ok}, "the frame $label is refused");
	like($reply->{error}, qr/failed authentication|too short/,
		'because it could not be authenticated');

	# The connection is dropped rather than kept for another guess.
	my ($after, $after_error) = Class::Shared::Protocol::read_frame($raw, 5, 's3cret-token');
	is($after, undef, 'and the connection is closed');
	like($after_error, qr/closed|read failed/i, 'as a closed stream');

	close $raw;
}

is($frontend->value, 6, 'the real client still works after the forgeries');

# Plaintext never reaches the frame parser: the listener is the TLS endpoint, so
# a hello sent in the clear is not a message, it is a protocol violation.
my $plain = IO::Socket::INET->new(
	PeerAddr => '127.0.0.1',
	PeerPort => $port,
	Proto    => 'tcp',
	Timeout  => 5,
) or BAIL_OUT("cannot open a plain connection to the backend: $!");

my ($plain_hello) = Class::Shared::Protocol::encode_frame({
	op    => 'hello',
	proto => $Class::Shared::PROTOCOL_VERSION,
	class => 'Shared::Counter',
}, 's3cret-token');

Class::Shared::Protocol::write_all($plain, $plain_hello);

my ($plain_reply, $plain_error) = Class::Shared::Protocol::read_frame($plain, 5, 's3cret-token');
is($plain_reply, undef, 'a plaintext frame gets no reply');
like($plain_error, qr/closed|read failed|reset|exceeds the limit/i,
	'and nothing Storable comes back');
close $plain;

is($frontend->shared_status->{constructed}, $constructed,
	'and none of those attempts constructed an object');

# A connection that opens and then says nothing must not stall the backend:
# the handshake is carried on from the select loop, not inside accept().
my @silent;
for (1 .. 3) {
	my $quiet = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		PeerPort => $port,
		Proto    => 'tcp',
		Timeout  => 5,
	) or BAIL_OUT("cannot open a silent connection: $!");
	push @silent, $quiet;
}

# Let the backend accept them and start handshakes that will never finish, so
# the real client below is the one that has to wait if the loop is blocked.
select(undef, undef, undef, 0.3);

my $started = Time::HiRes::time();
my $during = eval { frontend(ctor => [start => 11]) };
my $elapsed = Time::HiRes::time() - $started;

ok($during, 'a real client connects while silent clients are mid-handshake')
	or diag $@;
is($during->value, 11, 'and its object works') if $during;
cmp_ok($elapsed, '<', 3,
	"and is served at once, not after a handshake timeout ($elapsed s)");
$during->shared_close if $during;

close $_ for @silent;

# A frame that arrives in two pieces is kept in that client's buffer until the
# second piece lands, and then understood.  This covers the incremental parser,
# not the non-blocking read: a whole TLS record arrives here either way, so a
# blocking read would return the first piece and wait only for the next one.
# The half-record test below is the one that covers reads that must not wait.
my $dribbler = IO::Socket::SSL->new(
	PeerAddr        => '127.0.0.1',
	PeerPort        => $port,
	Proto           => 'tcp',
	Timeout         => 5,
	SSL_ca_file     => $pem{ca},
	SSL_cert_file   => $pem{client},
	SSL_key_file    => $pem{'client-key'},
	SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
) or BAIL_OUT('cannot open a TLS connection for the dribbling client');

my ($hello_bytes) = Class::Shared::Protocol::encode_frame({
	op    => 'hello',
	proto => $Class::Shared::PROTOCOL_VERSION,
	class => 'Shared::Counter',
}, 's3cret-token');

my ($sent_half) = Class::Shared::Protocol::write_all($dribbler, substr($hello_bytes, 0, 2));
ok($sent_half, 'half a frame is sent');

my $dribble_started = Time::HiRes::time();
my $bystander = eval { frontend(ctor => [start => 13]) };
my $dribble_elapsed = Time::HiRes::time() - $dribble_started;

ok($bystander, 'a client dribbling half a frame does not stop another') or diag $@;
is($bystander->value, 13, 'the other client has its object') if $bystander;
cmp_ok($dribble_elapsed, '<', 3,
	"and is served at once, not when the frame completes ($dribble_elapsed s)");
$bystander->shared_close if $bystander;

my ($sent_rest) = Class::Shared::Protocol::write_all($dribbler, substr($hello_bytes, 2));
ok($sent_rest, 'the rest of the frame is sent');

my ($greeting, $greeting_error)
	= Class::Shared::Protocol::read_frame($dribbler, 5, 's3cret-token');
ok($greeting, 'and the buffered frame is understood once it is complete')
	or diag $greeting_error;
is($greeting->{class}, 'Shared::Counter', 'as the frame that was sent') if $greeting;

close $dribbler;

# The harsher version: a client whose bytes are not even a whole TLS record.
# A blocking read would sit inside the TLS layer waiting for the rest of it.
my $partial = IO::Socket::SSL->new(
	PeerAddr        => '127.0.0.1',
	PeerPort        => $port,
	Proto           => 'tcp',
	Timeout         => 5,
	SSL_ca_file     => $pem{ca},
	SSL_cert_file   => $pem{client},
	SSL_key_file    => $pem{'client-key'},
	SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
) or BAIL_OUT('cannot open a TLS connection for the partial record');

# A record header claiming 8192 bytes, and two of them.  These bytes have to
# reach the wire unencrypted to be half a record at all, so they go to a
# duplicate of the socket's own descriptor: CORE::syswrite on the TLS handle
# still goes through the TLS layer, where they would be seven bytes of
# plaintext application data and prove nothing.
#
# A TLS 1.3 handshake also leaves the server's session tickets in the socket,
# so serve this client once first: its TLS layer then reads them, and whatever
# is readable on the descriptor afterwards is a reaction to the half record.
my ($partial_hello) = Class::Shared::Protocol::encode_frame({
	op    => 'hello',
	proto => $Class::Shared::PROTOCOL_VERSION,
	class => 'Shared::Counter',
}, 's3cret-token');
Class::Shared::Protocol::write_all($partial, $partial_hello);
my ($partial_greeting)
	= Class::Shared::Protocol::read_frame($partial, 5, 's3cret-token');
ok($partial_greeting, 'the client that will dribble is served first');

my $raw;
open($raw, '>&=', fileno($partial))
	or BAIL_OUT("cannot duplicate the TLS socket's descriptor: $!");

my $ragged = syswrite($raw, "\x17\x03\x03\x20\x00ab");
ok(defined $ragged, 'half a TLS record is sent');

# Give the backend time to read it, then check it is waiting rather than gone:
# a read that cannot complete is not a reason to drop the client.  A close, or
# a TLS alert, is the backend giving up; further session tickets are not, so
# they are taken off and ignored.
select(undef, undef, undef, 0.2);

my $dropped = 0;
my $give_up = Time::HiRes::time() + 0.5;
while (Time::HiRes::time() < $give_up) {
	my $readable = '';
	vec($readable, fileno($raw), 1) = 1;
	last unless select(my $rout = $readable, undef, undef, 0.1);

	my $got = sysread($raw, my $data, 4096);
	last unless defined $got;    # nothing there after all
	if ($got == 0) {
		$dropped = 1;    # the backend closed the connection
		last;
	}
	$dropped = 1 if substr($data, 0, 1) eq "\x15";    # a TLS alert
}
ok(!$dropped, 'and the backend keeps waiting for the rest of the record');

my $record_started = Time::HiRes::time();
my $observer = eval { frontend(ctor => [start => 19]) };
my $record_elapsed = Time::HiRes::time() - $record_started;

ok($observer, 'a client with half a TLS record does not stop another') or diag $@;
is($observer->value, 19, 'the other client has its object') if $observer;
cmp_ok($record_elapsed, '<', 3,
	"and is served at once, not at the end of the record ($record_elapsed s)");
$observer->shared_close if $observer;

close $raw;
close $partial;

# The handshake deadline is a constructor option, so a backend with a short one
# can be started here: a client that connects and says nothing has to lose its
# slot when its time is up, and the real client has to keep working.
my $deadline_probe = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Proto     => 'tcp',
	Listen    => 1,
	ReuseAddr => 1,
) or BAIL_OUT("cannot reserve a port for the deadline backend: $!");
my $deadline_port = $deadline_probe->sockport;
close $deadline_probe;

my $deadline_dir = File::Spec->catdir($dir, 'deadline');

my $short_pid = fork;
BAIL_OUT("cannot fork: $!") unless defined $short_pid;

if (!$short_pid) {
	no warnings 'exec';    # exec() does not return when it works
	exec(
		$^X, '-Ilib', '-It/lib', '-MClass::Shared::Backend', '-e',
		'Class::Shared::Backend->new(' . join(', ',
			'host => shift', 'port => shift',
			'token => shift', 'tls_cert => shift', 'tls_key => shift',
			'tls_ca => shift', 'dir => shift', 'log => shift',
			'handshake_timeout => shift') . ')->run()',
		'127.0.0.1', $deadline_port, 's3cret-token',
		$pem{server}, $pem{'server-key'}, $pem{ca},
		$deadline_dir, File::Spec->catfile($deadline_dir, 'log'), 1,
	);
	POSIX::_exit(127);
}

END {
	kill 'TERM', $short_pid if $short_pid && kill(0, $short_pid);
}

my $real;
for (1 .. 100) {
	$real = eval { frontend(port => $deadline_port, ctor => [start => 3]) };
	last if $real;
	select(undef, undef, undef, 0.05);
}

ok($real, 'a backend with a short handshake deadline came up') or diag $@;

if ($real) {
	is($real->value, 3, 'the real client has its object');

	my $baseline = $real->shared_status->{clients};

	my $lonely = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		PeerPort => $deadline_port,
		Proto    => 'tcp',
		Timeout  => 5,
	) or BAIL_OUT("cannot open a silent connection: $!");

	my $holding = 0;
	for (1 .. 40) {
		if ($real->shared_status->{clients} > $baseline) {
			$holding = 1;
			last;
		}
		select(undef, undef, undef, 0.05);
	}
	ok($holding, 'a silent client holds a slot while its handshake is pending');

	my $freed = 0;
	for (1 .. 60) {
		if ($real->shared_status->{clients} <= $baseline) {
			$freed = 1;
			last;
		}
		select(undef, undef, undef, 0.1);
	}
	ok($freed, 'and loses it once its handshake deadline passes');

	is($real->value, 3, 'while the real client carries on working');

	close $lonely;

	ok($real->shared_shutdown, 'the deadline backend can be stopped');
	waitpid($short_pid, 0);
	is($?, 0, 'and it exited cleanly');
	undef $short_pid;
}

# A client that asks for an answer and then never reads it must not hold the
# loop: replies are queued per connection and written as the socket takes them.
# The queue is bounded too, so such a client is dropped rather than allowed to
# sit on the backend's memory.  Two ways of passing the bound are covered: one
# reply larger than it, and moderate replies that add up to more than it.
my $queue_probe = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Proto     => 'tcp',
	Listen    => 1,
	ReuseAddr => 1,
) or BAIL_OUT("cannot reserve a port for the queue backend: $!");
my $queue_port = $queue_probe->sockport;
close $queue_probe;

my $queue_dir = File::Spec->catdir($dir, 'queue');
mkdir $queue_dir, 0700 or BAIL_OUT("cannot make $queue_dir: $!");

my $queue_pid = fork;
BAIL_OUT("cannot fork: $!") unless defined $queue_pid;

if (!$queue_pid) {
	no warnings 'exec';    # exec() does not return when it works
	exec(
		$^X, '-Ilib', '-It/lib', '-MClass::Shared::Backend', '-e',
		'Class::Shared::Backend->new(' . join(', ',
			'host => shift', 'port => shift',
			'token => shift', 'tls_cert => shift', 'tls_key => shift',
			'tls_ca => shift', 'dir => shift', 'log => shift',
			'max_queued => shift') . ')->run()',
		'127.0.0.1', $queue_port, 's3cret-token',
		$pem{server}, $pem{'server-key'}, $pem{ca},
		$queue_dir, File::Spec->catfile($queue_dir, 'log'), 8 * 1024 * 1024,
	);
	POSIX::_exit(127);
}

END {
	kill 'TERM', $queue_pid if $queue_pid && kill(0, $queue_pid);
}

my $queue_ready;
for (1 .. 100) {
	$queue_ready = eval { frontend(port => $queue_port, ctor => [start => 23]) };
	last if $queue_ready;
	select(undef, undef, undef, 0.05);
}

ok($queue_ready, 'a backend with a small reply queue came up') or diag $@;
$queue_ready->shared_close if $queue_ready;

# A raw client, so the test can ask for an answer and then simply not read it.
sub tls_client_with_object {
	my ($port) = @_;

	my $sock = IO::Socket::SSL->new(
		PeerAddr        => '127.0.0.1',
		PeerPort        => $port,
		Proto           => 'tcp',
		Timeout         => 5,
		SSL_ca_file     => $pem{ca},
		SSL_cert_file   => $pem{client},
		SSL_key_file    => $pem{'client-key'},
		SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER(),
	) or BAIL_OUT("cannot open a TLS connection to the queue backend: $!");

	for my $request (
		{ op => 'hello', proto => $Class::Shared::PROTOCOL_VERSION,
			class => 'Shared::Counter' },
		{ op => 'new', args => [] },
	) {
		my ($bytes) = Class::Shared::Protocol::encode_frame($request, 's3cret-token');
		BAIL_OUT('cannot encode a request for the queue backend') unless defined $bytes;
		Class::Shared::Protocol::write_all($sock, $bytes);

		my ($response) = Class::Shared::Protocol::read_frame($sock, 5, 's3cret-token');
		BAIL_OUT('the queue backend refused the client') unless $response && $response->{ok};

		return ($sock, $response->{id}) if $request->{op} eq 'new';
	}
}

# Reads until the backend closes the connection: a reply it would not queue
# means the client is finished, so what is left is a closed stream.
sub drain_until_closed {
	my ($sock) = @_;

	my $give_up = Time::HiRes::time() + 5;
	while (Time::HiRes::time() < $give_up) {
		my $rin = '';
		vec($rin, fileno($sock), 1) = 1;
		return 0 unless select(my $rout = $rin, undef, undef, 0.2);

		my $got = sysread($sock, my $data, 65536);
		return 1 if !defined $got || $got == 0;
	}

	return 0;
}

my ($hog, $hog_id) = tls_client_with_object($queue_port);
ok($hog, 'a client that will not read has a connection and an object');

# 16 MiB back against an 8 MiB queue: more than any socket buffer, so a writer
# that waited for the socket would sit there, and more than this client may
# hold unwritten, so the backend has to give up on it instead.
my ($hog_call) = Class::Shared::Protocol::encode_frame({
	op     => 'call',
	id     => $hog_id,
	method => 'blob',
	args   => [16 * 1024 * 1024],
	want   => 'scalar',
}, 's3cret-token');
BAIL_OUT('cannot encode the 16 MiB request') unless defined $hog_call;
Class::Shared::Protocol::write_all($hog, $hog_call);

my $queue_started = Time::HiRes::time();
my $waiting = eval { frontend(port => $queue_port, ctor => [start => 29]) };
my $queue_elapsed = Time::HiRes::time() - $queue_started;

ok($waiting, 'a client that never reads its reply does not stop another') or diag $@;
is($waiting->value, 29, 'the other client has its object') if $waiting;
cmp_ok($queue_elapsed, '<', 3,
	"and is served at once, not when the reply goes out ($queue_elapsed s)");
$waiting->shared_close if $waiting;

# The reply could not be queued, so that connection is finished: what is left
# to read is a closed stream, not a megabyte of answer.
ok(drain_until_closed($hog),
	'and a client that will not read is dropped when its queue passes the bound');
close $hog;

# The bound is not only about one oversized reply: a client that asks for
# moderate answers, each of which fits, is dropped once enough of them are
# waiting.  Twelve replies of 2 MiB are 24 MiB against an 8 MiB bound, and this
# client reads none of it.
my ($piler, $piler_id) = tls_client_with_object($queue_port);
ok($piler, 'a second client that will not read has a connection and an object');

for (1 .. 12) {
	my ($call) = Class::Shared::Protocol::encode_frame({
		op     => 'call',
		id     => $piler_id,
		method => 'blob',
		args   => [2 * 1024 * 1024],
		want   => 'scalar',
	}, 's3cret-token');
	last unless defined $call;

	# The backend may drop this client part way through, so a failed write is
	# the test's cue to stop asking, not a failure of its own.
	my ($written) = Class::Shared::Protocol::write_all($piler, $call);
	last unless $written;
}

ok(drain_until_closed($piler),
	'and is dropped when replies that each fit add up past the bound');
close $piler;

# The queue's deadline is not a unix-socket thing either.  Over TLS a write that
# stops making progress is an SSL would-block, which is a different call on the
# stream from a plain one, and it has to start the same clock.  A reply that
# fits the queue is queued and never read, and is dropped once write_timeout
# passes -- while another client is served, so what expires is the queue and not
# the loop.
my $stall_probe = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Proto     => 'tcp',
	Listen    => 1,
	ReuseAddr => 1,
) or BAIL_OUT("cannot reserve a port for the stall backend: $!");
my $stall_port = $stall_probe->sockport;
close $stall_probe;

my $stall_dir = File::Spec->catdir($dir, 'stall');
mkdir $stall_dir, 0700 or BAIL_OUT("cannot make $stall_dir: $!");
my $stall_log = File::Spec->catfile($stall_dir, 'log');

my $stall_pid = fork;
BAIL_OUT("cannot fork: $!") unless defined $stall_pid;

if (!$stall_pid) {
	no warnings 'exec';
	exec(
		$^X, '-Ilib', '-It/lib', '-MClass::Shared::Backend', '-e',
		'Class::Shared::Backend->new(' . join(', ',
			'host => shift', 'port => shift',
			'token => shift', 'tls_cert => shift', 'tls_key => shift',
			'tls_ca => shift', 'dir => shift', 'log => shift',
			'max_queued => shift', 'write_timeout => shift') . ')->run()',
		'127.0.0.1', $stall_port, 's3cret-token',
		$pem{server}, $pem{'server-key'}, $pem{ca},
		$stall_dir, $stall_log, 32 * 1024 * 1024, 1,
	);
	POSIX::_exit(127);
}

END {
	kill 'TERM', $stall_pid if $stall_pid && kill(0, $stall_pid);
}

my $stall_ready;
for (1 .. 100) {
	$stall_ready = eval { frontend(port => $stall_port, ctor => [start => 41]) };
	last if $stall_ready;
	select(undef, undef, undef, 0.05);
}

ok($stall_ready, 'a TLS backend with a one second write timeout came up')
	or diag $@;

if ($stall_ready) {
	my $baseline = $stall_ready->shared_status->{objects};

	my ($quiet, $quiet_id) = tls_client_with_object($stall_port);
	ok($quiet, 'a client that will not read has a connection and an object');

	# 16 MiB fits the queue and cannot fit the TLS stream or its buffering, so
	# the rest waits -- unread, and so on a deadline.
	my ($quiet_call) = Class::Shared::Protocol::encode_frame({
		op     => 'call',
		id     => $quiet_id,
		method => 'blob',
		args   => [16 * 1024 * 1024],
		want   => 'scalar',
	}, 's3cret-token');
	BAIL_OUT('cannot encode the 16 MiB request for the stall backend')
		unless defined $quiet_call;
	Class::Shared::Protocol::write_all($quiet, $quiet_call);

	my $stall_started = Time::HiRes::time();

	my $during = eval { frontend(port => $stall_port, ctor => [start => 43]) };
	ok($during && $during->value == 43,
		'another client is served while the TLS reply makes no progress');
	$during->shared_close if $during;

	my $stalled = '';
	my $give_up = $stall_started + 8;
	while (Time::HiRes::time() < $give_up) {
		if (-e $stall_log) {
			open(my $log_fh, '<', $stall_log) or BAIL_OUT("cannot read $stall_log: $!");
			$stalled = do { local $/; <$log_fh> };
			close $log_fh;
		}
		last if $stalled =~ /made no progress/;
		select(undef, undef, undef, 0.05);
	}

	my $stall_elapsed = Time::HiRes::time() - $stall_started;

	like($stalled,
		qr/a queued reply of \d+ bytes made no progress for 1 second/,
		'and the SSL queue that stops moving is dropped when write_timeout passes');
	cmp_ok($stall_elapsed, '>=', 0.9,
		"not before its deadline ($stall_elapsed s)");

	ok(drain_until_closed($quiet), 'and that connection is closed');
	close $quiet;

	my $left = '?';
	for (1 .. 50) {
		$left = $stall_ready->shared_status->{objects};
		last if $left == $baseline;
		select(undef, undef, undef, 0.1);
	}

	is($left, $baseline, 'and the object of the client that timed out is destroyed');

	# The other side of the same clock over TLS: an SSL write that takes part of
	# the queue is progress, so a reader that keeps taking it across several
	# deadlines is kept and gets the whole reply.
	my ($reader, $reader_id) = tls_client_with_object($stall_port);
	ok($reader, 'a TCP client that will read slowly has a connection and an object');

	my ($reader_call) = Class::Shared::Protocol::encode_frame({
		op     => 'call',
		id     => $reader_id,
		method => 'blob',
		args   => [16 * 1024 * 1024],
		want   => 'scalar',
	}, 's3cret-token');
	BAIL_OUT('cannot encode the 16 MiB request for the slow reader')
		unless defined $reader_call;
	Class::Shared::Protocol::write_all($reader, $reader_call);

	# 256 KiB at a time, then a pause worth the same at 5 MiB/s: about three
	# seconds to drain the reply, three times the deadline, but the queue is
	# never left a whole deadline without the socket taking some of it.
	my $reader_started = Time::HiRes::time();
	my $reader_give_up = $reader_started + 60;
	my $reader_buffer  = '';
	my $reader_chunk   = 256 * 1024;
	my $reader_pause   = 0.05;

	while (length($reader_buffer) < 4
		|| length($reader_buffer) < 4 + unpack('N', substr($reader_buffer, 0, 4))) {

		my $rin = '';
		vec($rin, fileno($reader), 1) = 1;
		BAIL_OUT('the TLS backend stopped writing before the reply was all there')
			unless select(my $rout = $rin, undef, undef, 5);

		my $got = sysread($reader, my $data, $reader_chunk);
		BAIL_OUT('the TLS connection was closed while the reply was still coming')
			unless defined $got && $got > 0;

		$reader_buffer .= $data;
		select(undef, undef, undef, $reader_pause * $got / $reader_chunk);

		BAIL_OUT('the slow TLS reply took far longer than it should')
			if Time::HiRes::time() > $reader_give_up;
	}

	# The frame carries the token's digest, so it is taken with the same secret.
	my ($reader_frame, $reader_reply, $reader_error)
		= Class::Shared::Protocol::take_frame(\$reader_buffer, 's3cret-token');
	my $reader_elapsed = Time::HiRes::time() - $reader_started;

	ok($reader_frame == 1
			&& length($reader_reply->{result}[0] // '') == 16 * 1024 * 1024,
		'the whole TLS reply arrived'
			. ($reader_error ? " ($reader_error)" : ''));

	cmp_ok($reader_elapsed, '>', 2,
		"and reading it took longer than write_timeout ($reader_elapsed s)");

	my $stall_text = '';
	if (-e $stall_log) {
		open(my $log_fh, '<', $stall_log) or BAIL_OUT("cannot read $stall_log: $!");
		$stall_text = do { local $/; <$log_fh> };
		close $log_fh;
	}

	my $drops = () = $stall_text =~ /made no progress/g;
	is($drops, 1, 'and no second deadline fired for the client that kept reading');

	is($stall_ready->shared_status->{objects}, $baseline + 1,
		'and that client keeps its object');

	close $reader;

	ok($stall_ready->shared_shutdown, 'the stall backend can be stopped');
	$stall_ready->shared_close;

	waitpid($stall_pid, 0);
	is($?, 0, 'and it exited cleanly');
	undef $stall_pid;
}

# Nothing can be autostarted over TCP: a closed port is an error.
my $closed = IO::Socket::INET->new(
	LocalAddr => '127.0.0.1',
	LocalPort => 0,
	Proto     => 'tcp',
	Listen    => 1,
	ReuseAddr => 1,
);
my $closed_port = $closed->sockport;
close $closed;

eval {
	frontend(port => $closed_port);
};
like($@, qr/cannot reach a backend/, 'a closed TCP endpoint is an error, not a spawn');

ok($frontend->shared_shutdown, 'the TCP backend can be stopped');
waitpid($pid, 0);
is($?, 0, 'and it exited cleanly');

undef $pid;

done_testing();
