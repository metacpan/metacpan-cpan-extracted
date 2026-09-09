# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@dickolsson.com>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

# App::FuguVM::Autoinstall - serve one autoinstall(8) response file.
#
# The module holds the response file and the responder: a small HTTP
# child that answers that one file to one guest. The child binds the
# loopback address only, because a response file can hold the root
# password, and the guest reaches a loopback listener through the QEMU
# gateway. The module is FuguVM policy over generic parts: the file it
# serves is an installer artifact, and the address it serves to is a
# QEMU gateway. Fugu::Proxy stays a proxy, and it gains no
# origin-server mode here.

package App::FuguVM::Autoinstall;
our $VERSION = '0.2.0';

use IO::Socket::INET;
use Fugu::File;
use Fugu::Log;
use Fugu::Process;
use Fugu::Timeout;
use App::FuguVM::Proxy;

use constant {
	RESPONSE_PATH => '/install.conf',

	# One range above the proxy range, so the two children cannot
	# contend for one port.
	PORTS => [ 8181, 8280 ],

	BIND_ADDRESS  => '127.0.0.1',
	PROXY_TOKEN   => '@PROXY_URL@',
	READY_TIMEOUT => 10,

	# The bound on one request line. The guest sends one short GET,
	# so a longer line is not a request from the installer.
	MAX_REQUEST_LINE => 8192,
};

# App::FuguVM::Autoinstall->new(%args):
#	file      => $path	the response file (required)
#	pidfile   => $pidfile	a Fugu::Pidfile for the child (required)
#	store     => $store	a Fugu::StateFile that holds the port (required)
#	proxy_url => $url	replaces each PROXY_TOKEN, or undef
#	logfile   => $path	where the output of the child goes
#	log       => $logger	default: Fugu::Log->default
#
#	The constructor opens nothing.
sub new ( $class, %args )
{
	for my $required (qw(pidfile store)) {
		die "$required parameter required"
		    unless defined $args{$required};
	}

	return bless {
		file      => $args{file},
		pidfile   => $args{pidfile},
		store     => $args{store},
		proxy_url => $args{proxy_url},
		logfile   => $args{logfile} // '/dev/null',
		log       => $args{log}     // Fugu::Log->default,
		error     => undef,
	}, $class;
}

# $self->path:
#	Return the response-file path.
sub path ($self)
{
	return $self->{file};
}

# $self->error:
#	Return the reason of the last failed start, or undef.
sub error ($self)
{
	return $self->{error};
}

# $self->port:
#	Return the recorded port, or undef.
sub port ($self)
{
	return $self->{store}->get('autoinstall_port');
}

# $self->is_running:
#	Report whether the child is alive. The check reaps first, so a
#	child that became a zombie reads as stopped.
sub is_running ($self)
{
	return $self->{pidfile}->is_running ? 1 : 0;
}

# $self->guest_url:
#	Return the response-file URL as the guest reaches it, through
#	the QEMU gateway. The gateway routes the request to the
#	loopback listener of the host, so no port forward is needed.
sub guest_url ($self)
{
	my $port = $self->port;
	return if !defined $port;

	return
	      'http://'
	    . App::FuguVM::Proxy::HOST_GATEWAY()
	    . ":$port"
	    . RESPONSE_PATH;
}

# $self->start:
#	Take a free port, spawn the child, record the PID and the
#	port, and wait until the port answers. Return the port, or
#	undef with the reason in error(). A responder that already
#	runs returns its port and starts nothing.
sub start ($self)
{
	$self->{error} = undef;

	return $self->port if $self->is_running;

	if ( !defined $self->{file} || !-r $self->{file} ) {
		$self->{error} = 'the response file is not readable: '
		    . ( $self->path // '(none)' );
		return;
	}

	my $port = $self->_find_free_port;
	unless ( defined $port ) {
		$self->{error} = sprintf 'no free port in %d-%d', @{ +PORTS };
		return;
	}

	my $child  = ref $self;
	my $result = Fugu::Process->spawn_perl(
		code      => "use $child; $child->run_child(\@ARGV)",
		args      => [ $port, $self->{file}, $self->{proxy_url} // '' ],
		daemonize => 1,
		stdout    => $self->{logfile},
		stderr    => $self->{logfile},
	);
	unless ( $result->{success} ) {
		$self->{error} = "cannot start the responder: $result->{error}";
		return;
	}

	$self->{pidfile}->write_pid( $result->{pid} );
	$self->{store}->set( autoinstall_port => $port );

	unless ( $self->_wait_ready ) {
		$self->{error} = 'the responder did not take connections';
		$self->stop;
		return;
	}

	return $port;
}

# $self->stop:
#	Stop the child and forget the port. The method returns 1.
sub stop ($self)
{
	my $pid = $self->{pidfile}->read_pid;
	Fugu::Process->terminate( $pid, grace_period => 5 )
	    if defined $pid;

	$self->{pidfile}->remove;
	$self->{store}->delete('autoinstall_port');

	return 1;
}

# $class->run_child($port, $file, $proxy_url):
#	The entry point of the spawned child. The child reads the
#	response file, renders it, and serves it until a SIGTERM. It
#	logs each request line, and it never logs the file content.
sub run_child ( $class, $port, $file, $proxy_url )
{
	my $log = Fugu::Log->new( mode => 'stderr', level => 'debug' );

	my $bytes = Fugu::File->read($file);
	die "Cannot read the response file: $file\n" if !defined $bytes;

	my $body = $class->render( $bytes, $proxy_url );

	my $listener = IO::Socket::INET->new(
		LocalAddr => BIND_ADDRESS,
		LocalPort => $port,
		Proto     => 'tcp',
		ReuseAddr => 1,
		Listen    => 5,
	) or die 'Cannot listen on ' . BIND_ADDRESS . ":$port: $!\n";

	$log->info( 'Responder listening on %s:%d', BIND_ADDRESS, $port );

	# A client can disconnect in the middle of an answer
	local $SIG{PIPE} = 'IGNORE';

	# The self-pipe makes the signal safe: the handler writes one
	# byte, and the select loop notices it between requests instead
	# of inside one.
	require IO::Select;
	pipe my $sig_read, my $sig_write or die "pipe: $!";
	$sig_read->blocking(0);
	$sig_write->blocking(0);

	my $running = 1;
	local $SIG{TERM} = sub {
		$running = 0;
		syswrite $sig_write, 'x', 1;
	};

	my $select = IO::Select->new( $listener, $sig_read );

	while ($running) {
		my @ready = $select->can_read;
		last if !$running;

		for my $fh (@ready) {
			if ( $fh == $sig_read ) {
				sysread $sig_read, my $drain, 100;
				next;
			}

			my $client = $listener->accept or next;
			_answer( $client, $body, $log );
			close $client;
		}
	}

	$log->info('Responder shutting down');
	close $sig_read;
	close $sig_write;
	close $listener;

	return 1;
}

# $class->render($bytes, $proxy_url):
#	Return the bytes with every PROXY_TOKEN replaced by
#	$proxy_url. The method is pure, so a test proves it with no
#	socket. With an empty proxy URL the bytes return unchanged: a
#	token that nothing replaces stays visible, and the installer
#	then diagnoses it.
sub render ( $, $bytes, $proxy_url )
{
	return $bytes if !defined $proxy_url || $proxy_url eq '';

	my $token = PROXY_TOKEN;
	$bytes =~ s/\Q$token\E/$proxy_url/g;

	return $bytes;
}

# _answer($client, $body, $log):
#	Read one request, answer it, and log the request line with the
#	status code. The child parses the request line and nothing
#	else: the headers carry nothing the answer depends on. It
#	still reads to the end of the request head. Without that
#	drain, the close after the answer can reset the connection
#	before the guest reads it.
sub _answer ( $client, $body, $log )
{
	my $line = _request_line($client);

	# A connection that sends nothing is the readiness probe of
	# start, not a request. It gets no answer and no log line.
	return if defined $line && $line eq '';

	if ( !defined $line ) {
		$log->warning('400 (request line too long or unreadable)');
		_respond( $client, 400, 'Bad Request', '' );
		return;
	}

	my ( $method, $path ) = split ' ', $line;
	$method //= '';
	$path   //= '';

	my ( $code, $text, $answer ) =
	       $method ne 'GET'
	    && $method ne 'HEAD'     ? ( 405, 'Method Not Allowed', '' )
	    : $path ne RESPONSE_PATH ? ( 404, 'Not Found', '' )
	    :                          ( 200, 'OK', $body );

	$log->info( '%s %s -> %d', $method, $path, $code );
	_respond( $client, $code, $text, $answer, $method eq 'HEAD' );

	return;
}

# _request_line($client):
#	Return the request line, without its line ending. The read
#	continues to the blank line that ends the request head, under
#	one bound for the whole head. Return the empty string for a
#	peer that sent nothing. Return undef for a head above the
#	bound, and for a read failure before the first line ends.
sub _request_line ($client)
{
	my $head = '';
	while ( length($head) < MAX_REQUEST_LINE ) {
		my $read = sysread( $client, my $chunk, 1024 );
		last if !$read;
		$head .= $chunk;
		last if index( $head, "\r\n\r\n" ) >= 0;
		last if index( $head, "\n\n" ) >= 0;
	}
	return '' if $head eq '';
	return    if length($head) >= MAX_REQUEST_LINE;

	my $end = index( $head, "\n" );
	return if $end < 0;

	my $line = substr( $head, 0, $end );
	$line =~ s/\r\z//;

	return $line;
}

# _respond($client, $code, $text, $body, $head_only):
#	Write one complete answer. Every answer carries Content-Length
#	and Connection: close, and a HEAD answer carries the headers
#	only.
sub _respond ( $client, $code, $text, $body, $head_only = 0 )
{
	my $head =
	      "HTTP/1.1 $code $text\r\n"
	    . "Content-Type: text/plain\r\n"
	    . 'Content-Length: '
	    . length($body) . "\r\n"
	    . "Connection: close\r\n\r\n";
	$head .= $body unless $head_only;

	return Fugu::File->_write_all( $client, $head, 'client socket' );
}

# $self->_find_free_port:
#	Return the first port of the range that binds on the loopback
#	address, or undef.
sub _find_free_port ($self)
{
	my ( $first, $last ) = @{ +PORTS };

	for my $port ( $first .. $last ) {
		my $sock = IO::Socket::INET->new(
			LocalAddr => BIND_ADDRESS,
			LocalPort => $port,
			Proto     => 'tcp',
			ReuseAddr => 1,
			Listen    => 1,
		) or next;
		close $sock;
		return $port;
	}

	return;
}

# $self->_wait_ready:
#	Wait until the responder takes a connection.
sub _wait_ready ($self)
{
	my $port = $self->port;
	return 0 if !defined $port;

	my $ready = Fugu::Timeout::wait_until(
		READY_TIMEOUT,
		0.2,
		sub {
			my $sock = IO::Socket::INET->new(
				PeerAddr => BIND_ADDRESS,
				PeerPort => $port,
				Proto    => 'tcp',
				Timeout  => 1,
			) or return 0;
			close $sock;
			return 1;
		} );

	return $ready ? 1 : 0;
}

1;
