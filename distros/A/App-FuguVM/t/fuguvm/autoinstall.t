#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The autoinstall responder: the pure rendering, the guest URL, and
# one live child over a loopback socket.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use IO::Socket::INET;
use Fugu::Log;
use Fugu::Pidfile;
use Fugu::StateFile;

use_ok('App::FuguVM::Autoinstall');

Fugu::Log->set_default( Fugu::Log->new( mode => 'quiet' ) );

# The constants of the contract
{
	is( App::FuguVM::Autoinstall::RESPONSE_PATH(),
		'/install.conf', 'RESPONSE_PATH is /install.conf' );
	is_deeply( App::FuguVM::Autoinstall::PORTS(),
		[ 8181, 8280 ], 'PORTS is one range above the proxy' );
	is( App::FuguVM::Autoinstall::BIND_ADDRESS(),
		'127.0.0.1', 'BIND_ADDRESS is the loopback address' );
	is( App::FuguVM::Autoinstall::PROXY_TOKEN(),
		'@PROXY_URL@', 'PROXY_TOKEN is @PROXY_URL@' );
}

# render is pure, so no socket is needed to prove it
{
	my $render = sub (@args) {
		return App::FuguVM::Autoinstall->render(@args);
	};

	is(
		$render->(
			"HTTP proxy URL = \@PROXY_URL\@\nkeep = this\n",
			'http://10.0.2.2:8080'
		),
		"HTTP proxy URL = http://10.0.2.2:8080\nkeep = this\n",
		'render replaces the token and changes nothing else'
	);

	is(
		$render->(
			"a = \@PROXY_URL\@\nb = \@PROXY_URL\@\n",
			'http://10.0.2.2:8080'
		),
		"a = http://10.0.2.2:8080\nb = http://10.0.2.2:8080\n",
		'render replaces every occurrence'
	);

	my $plain = "System hostname = image\n";
	is( $render->( $plain, 'http://10.0.2.2:8080' ),
		$plain, 'a file with no token returns unchanged' );
	is( $render->( "a = \@PROXY_URL\@\n", '' ),
		"a = \@PROXY_URL\@\n",
		'an empty proxy URL leaves the token visible' );
	is( $render->( "a = \@PROXY_URL\@\n", undef ),
		"a = \@PROXY_URL\@\n", 'an undef proxy URL does the same' );
}

# The guest URL names the gateway, the recorded port and the path
{
	my $dir       = tempdir( CLEANUP => 1 );
	my $store     = Fugu::StateFile->new( path => "$dir/status" )->load;
	my $responder = App::FuguVM::Autoinstall->new(
		file    => "$dir/install.conf",
		pidfile => Fugu::Pidfile->new( path => "$dir/autoinstall.pid" ),
		store   => $store,
	);

	is( $responder->path, "$dir/install.conf",
		'path returns the response file' );
	is( $responder->guest_url, undef, 'no URL before the child runs' );

	$store->set( autoinstall_port => 8181 );
	is( $responder->guest_url, 'http://10.0.2.2:8181/install.conf',
		'the guest URL names the gateway, the port and the path' );
}

# start refuses an unreadable response file
{
	my $dir       = tempdir( CLEANUP => 1 );
	my $store     = Fugu::StateFile->new( path => "$dir/status" )->load;
	my $responder = App::FuguVM::Autoinstall->new(
		file    => "$dir/absent.conf",
		pidfile => Fugu::Pidfile->new( path => "$dir/autoinstall.pid" ),
		store   => $store,
	);

	is( $responder->start, undef, 'start returns undef' );
	like( $responder->error, qr/absent\.conf/,
		'and error names the file' );
}

# One live child: the answers, the loopback bind, and the stop
SKIP: {
	my $dir   = tempdir( CLEANUP => 1 );
	my $store = Fugu::StateFile->new( path => "$dir/status" )->load;

	my $file = "$dir/install.conf";
	open my $fh, '>', $file or die "Cannot write $file: $!";
	print $fh "System hostname = image\n";
	print $fh "HTTP proxy URL = \@PROXY_URL\@\n";
	close $fh;

	my $responder = App::FuguVM::Autoinstall->new(
		file      => $file,
		pidfile   => Fugu::Pidfile->new( path => "$dir/autoinstall.pid" ),
		store     => $store,
		proxy_url => 'http://10.0.2.2:8080',
		logfile   => "$dir/autoinstall.log",
	);

	my $port = $responder->start;
	skip 'no free port in the responder range', 16 if !defined $port;

	ok( $port >= 8181 && $port <= 8280, 'start returns a port of the range' );
	ok( $responder->is_running, 'the child is alive' );
	is( $responder->port, $port, 'port returns the recorded port' );
	is( $responder->start, $port,
		'a second start returns the port and starts nothing' );

	my $expected = "System hostname = image\n"
	    . "HTTP proxy URL = http://10.0.2.2:8080\n";

	my ( $head, $body ) = _request( $port, "GET /install.conf HTTP/1.1" );
	like( $head, qr{^HTTP/1\.1 200 }, 'GET /install.conf answers 200' );
	like( $head, qr{^Content-Type: text/plain\r?$}m,
		'with Content-Type: text/plain' );
	like( $head, qr{^Content-Length: @{[length $expected]}\r?$}m,
		'with the Content-Length of the rendered bytes' );
	is( $body, $expected, 'and the rendered bytes as the body' );

	( $head, $body ) = _request( $port, "HEAD /install.conf HTTP/1.1" );
	like( $head, qr{^HTTP/1\.1 200 }, 'HEAD answers 200' );
	is( $body, '', 'with the headers only' );

	($head) = _request( $port, "GET /elsewhere HTTP/1.1" );
	like( $head, qr{^HTTP/1\.1 404 }, 'another path answers 404' );

	($head) = _request( $port, "POST /install.conf HTTP/1.1" );
	like( $head, qr{^HTTP/1\.1 405 }, 'another method answers 405' );

	# The child binds the loopback address only, because the file
	# can hold a secret. The probe connects to the outbound address
	# of this host, and it skips when the host has none. Some
	# networks intercept and accept each connection. A refusal
	# cannot occur there, and the probe also skips.
	my $outbound = _outbound_address();
	if ( !defined $outbound || $outbound eq '127.0.0.1' ) {
		pass('no outbound address to probe, loopback bind unproven');
	}
	elsif ( _network_intercepts($outbound) ) {
		pass('the network accepts each connection, loopback bind unproven');
	}
	else {
		my $reached = IO::Socket::INET->new(
			PeerAddr => $outbound,
			PeerPort => $port,
			Proto    => 'tcp',
			Timeout  => 2,
		);
		is( $reached, undef,
			"a connection to $outbound:$port fails" );
	}

	ok( $responder->stop, 'stop returns 1' );
	ok( !$responder->is_running, 'the child is gone' );
	is( $responder->port, undef, 'port returns undef after stop' );
}

done_testing();

# _request($port, $line):
#	Send one request and return the head and the body.
sub _request ( $port, $line )
{
	my $sock = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		PeerPort => $port,
		Proto    => 'tcp',
		Timeout  => 5,
	) or die "Cannot connect to 127.0.0.1:$port: $!";

	print $sock "$line\r\nHost: 127.0.0.1\r\n\r\n";
	my $answer = do { local $/; <$sock> };
	close $sock;

	my ( $head, $body ) = split /\r\n\r\n/, $answer, 2;
	return ( $head, $body // '' );
}

# _outbound_address():
#	Return the local address of an outbound socket, or undef. The
#	datagram never leaves the host: connect on UDP only records
#	the route.
sub _outbound_address ()
{
	my $sock = IO::Socket::INET->new(
		PeerAddr => '203.0.113.1',
		PeerPort => 53,
		Proto    => 'udp',
	) or return;

	my $address = $sock->sockhost;
	close $sock;

	return $address;
}

# _network_intercepts($address):
#	Return 1 when a connection to a closed port on $address
#	succeeds. That network intercepts each connection, and a
#	bind probe proves nothing there.
sub _network_intercepts ($address)
{
	my $listener = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Proto     => 'tcp',
		Listen    => 1,
	) or return 0;

	my $closed = $listener->sockport;
	close $listener;

	my $sock = IO::Socket::INET->new(
		PeerAddr => $address,
		PeerPort => $closed,
		Proto    => 'tcp',
		Timeout  => 2,
	) or return 0;

	close $sock;

	return 1;
}
