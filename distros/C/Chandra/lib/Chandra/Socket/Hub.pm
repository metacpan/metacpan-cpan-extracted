package Chandra::Socket::Hub;

use strict;
use warnings;

use IO::Select;
use Chandra::Socket::Connection;
use File::Spec ();

our $VERSION = '0.06';

sub new {
	my ($class, %args) = @_;

	my $self = bless {
		name        => $args{name},
		transport   => $args{transport} || 'unix',
		port        => $args{port},
		bind_addr   => $args{bind} || '127.0.0.1',
		tls_cert    => $args{tls_cert},
		tls_key     => $args{tls_key},
		_listener   => undef,
		_select     => IO::Select->new,
		_conns      => {},       # fileno => Connection
		_clients    => {},       # name => Connection
		_handlers   => {},       # channel => coderef
		_on_connect    => undef,
		_on_disconnect => undef,
		_socket_path   => undef,
		_token         => undef,
		_token_path    => undef,
	}, $class;

	$self->{_token} = $self->_generate_token;
	$self->_start_listener;
	return $self;
}

sub _start_listener {
	my ($self) = @_;

	if ($self->{transport} eq 'tcp') {
		if ($self->{tls_cert} && $self->{tls_key}) {
			require IO::Socket::SSL;
			$self->{_listener} = IO::Socket::SSL->new(
				LocalHost     => $self->{bind_addr},
				LocalPort     => $self->{port},
				Proto         => 'tcp',
				Listen        => 16,
				ReuseAddr     => 1,
				SSL_cert_file => $self->{tls_cert},
				SSL_key_file  => $self->{tls_key},
				SSL_server    => 1,
			) or die "Hub: cannot listen on TLS TCP $self->{bind_addr}:$self->{port}: $!\n";
			$self->{_listener}->blocking(0);
		} else {
			require IO::Socket::INET;
			$self->{_listener} = IO::Socket::INET->new(
				LocalHost => $self->{bind_addr},
				LocalPort => $self->{port},
				Proto     => 'tcp',
				Listen    => 16,
				ReuseAddr => 1,
				Blocking  => 0,
			) or die "Hub: cannot listen on TCP $self->{bind_addr}:$self->{port}: $!\n";
		}
	} else {
		require IO::Socket::UNIX;
		my $dir = $ENV{XDG_RUNTIME_DIR} || File::Spec->tmpdir;
		my $path = $self->{_socket_path} = File::Spec->catfile($dir, 'chandra-' . $self->{name} . '.sock');
		unlink $path if -e $path;
		$self->{_listener} = IO::Socket::UNIX->new(
			Local   => $path,
			Type    => IO::Socket::UNIX::SOCK_STREAM(),
			Listen  => 16,
		) or die "Hub: cannot listen on $path: $!\n";
		chmod 0600, $path;
		$self->{_listener}->blocking(0);
		my $token_path = $self->{_token_path} = "$path.token";
		if (open my $tfh, '>', $token_path) {
			print $tfh $self->{_token};
			close $tfh;
			chmod 0600, $token_path;
		}
	}
	$self->{_select}->add($self->{_listener});
}

sub token { $_[0]->{_token} }

sub socket_path {
	my ($class, $name) = @_;
	my $dir = $ENV{XDG_RUNTIME_DIR} || File::Spec->tmpdir;
	return File::Spec->catfile($dir, "chandra-$name.sock");
}

sub _generate_token {
	my $token;
	if (open my $fh, '<:raw', '/dev/urandom') {
		my $bytes;
		read($fh, $bytes, 16);
		close $fh;
		$token = unpack('H*', $bytes);
	} else {
		$token = sprintf '%08x%08x%08x%08x',
		int(rand(0xFFFFFFFF)), int(rand(0xFFFFFFFF)),
		int(rand(0xFFFFFFFF)), int(rand(0xFFFFFFFF));
	}
	return $token;
}

sub on {
	my ($self, $channel, $cb) = @_;
	$self->{_handlers}{$channel} = $cb;
	return $self;
}

sub on_connect {
	my ($self, $cb) = @_;
	$self->{_on_connect} = $cb;
	return $self;
}

sub on_disconnect {
	my ($self, $cb) = @_;
	$self->{_on_disconnect} = $cb;
	return $self;
}

sub broadcast {
	my ($self, $channel, $data) = @_;
	for my $conn (values %{$self->{_conns}}) {
		$conn->send($channel, $data);
	}
	return $self;
}

sub send_to {
	my ($self, $name, $channel, $data) = @_;
	my $conn = $self->{_clients}{$name};
	return 0 unless $conn;
	return $conn->send($channel, $data);
}

sub clients {
	return keys %{$_[0]->{_clients}};
}

sub poll {
	my ($self) = @_;

	my @ready = $self->{_select}->can_read(0);
	for my $fh (@ready) {
		if ($fh == $self->{_listener}) {
			$self->_accept;
		} else {
			$self->_read_from($fh);
		}
	}
	return $self;
}

sub _accept {
	my ($self) = @_;
	my $client = $self->{_listener}->accept;
	return unless $client;
	$client->blocking(0);

	my $conn = Chandra::Socket::Connection->new(socket => $client);
	$self->{_conns}{$client->fileno} = $conn;
	$self->{_select}->add($client);
}

sub _read_from {
	my ($self, $fh) = @_;
	my $fileno = $fh->fileno;
	my $conn = $self->{_conns}{$fileno};
	return unless $conn;

	my @messages = $conn->recv;

	# Detect disconnection (recv returns empty + socket is disconnected)
	unless (@messages || $conn->is_connected) {
		$self->_remove_conn($fileno, $fh);
		return;
	}

	for my $msg (@messages) {
		if ($msg->{channel} && $msg->{channel} eq '__handshake') {
			# Verify authentication token
			unless (defined $msg->{data}{token} && $msg->{data}{token} eq $self->{_token}) {
				warn "Hub: rejected unauthenticated connection\n";
				$self->_remove_conn($fileno, $fh);
				return;
			}
			my $name = $msg->{data}{name};
			# Reject duplicate client names — close the old connection
			if ($self->{_clients}{$name}) {
				my $old = $self->{_clients}{$name};
				my $old_fileno = $old->socket ? $old->socket->fileno : undef;
				if ($old_fileno && $self->{_conns}{$old_fileno}) {
					$self->_remove_conn($old_fileno, $old->socket);
				}
			}
			$conn->set_name($name);
			$self->{_clients}{$name} = $conn;
			$self->{_on_connect}->($conn) if $self->{_on_connect};
		} elsif ($msg->{channel} && $self->{_handlers}{$msg->{channel}}) {
			$self->{_handlers}{$msg->{channel}}->($msg->{data}, $conn);
		}
	}
}

sub _remove_conn {
	my ($self, $fileno, $fh) = @_;
	my $conn = delete $self->{_conns}{$fileno};
	$self->{_select}->remove($fh);
	if ($conn && $conn->name) {
		delete $self->{_clients}{$conn->name};
		$self->{_on_disconnect}->($conn) if $self->{_on_disconnect};
	}
	$conn->close if $conn;
}

sub run {
	my ($self) = @_;
	while (1) {
		$self->poll;
		select(undef, undef, undef, 0.01);
	}
}

sub close {
	my ($self) = @_;
	for my $conn (values %{$self->{_conns}}) {
		$conn->send('__shutdown', {});
		$conn->close;
	}
	$self->{_conns} = {};
	$self->{_clients} = {};
	if ($self->{_listener}) {
		$self->{_select}->remove($self->{_listener});
		$self->{_listener}->close;
		$self->{_listener} = undef;
	}
	if ($self->{_token_path} && -e $self->{_token_path}) {
		unlink $self->{_token_path};
	}
	if ($self->{_socket_path} && -e $self->{_socket_path}) {
		unlink $self->{_socket_path};
	}
}

sub DESTROY {
	my ($self) = @_;
	$self->close;
}

1;

__END__

=head1 NAME

Chandra::Socket::Hub - IPC server for coordinating Chandra instances

=head1 SYNOPSIS

	use Chandra::Socket::Hub;

	# Unix socket (default)
	my $hub = Chandra::Socket::Hub->new(name => 'myapp');

	# TCP
	my $hub = Chandra::Socket::Hub->new(
	    transport => 'tcp',
	    port      => 9000,
	    bind      => '0.0.0.0',
	);

	# TCP with TLS (requires IO::Socket::SSL)
	my $hub = Chandra::Socket::Hub->new(
	    transport => 'tcp',
	    port      => 9000,
	    tls_cert  => '/path/to/cert.pem',
	    tls_key   => '/path/to/key.pem',
	);

	$hub->on('status', sub {
	    my ($data, $client) = @_;
	    print "Got status from ${\$client->name}\n";
	});

	$hub->on_connect(sub {
	    my ($client) = @_;
	    $client->send('welcome', { version => '1.0' });
	});

	$hub->broadcast('config', { theme => 'dark' });
	$hub->send_to('window-1', 'navigate', { path => '/' });

	$hub->run;  # standalone event loop

=head1 DESCRIPTION

Hub acts as the server in a hub/client IPC topology. It listens on a Unix
domain socket (default) or TCP socket, accepts connections from
L<Chandra::Socket::Client> instances, and dispatches messages by channel
name.

=head1 CONSTRUCTOR

=head2 new

	my $hub = Chandra::Socket::Hub->new(%args);

=over 4

=item name

(Required for Unix transport) Logical name used to derive the socket path.

=item transport

C<'unix'> (default) or C<'tcp'>.

=item port

(Required for TCP) Port number to listen on.

=item bind

Bind address for TCP. Defaults to C<'127.0.0.1'>.

=item tls_cert

Path to a PEM certificate file. Enables TLS when paired with C<tls_key>.
Requires L<IO::Socket::SSL>.

=item tls_key

Path to a PEM private key file for TLS.

=back

=head1 METHODS

=head2 on

	$hub->on($channel => sub { my ($data, $conn) = @_; ... });

Register a handler for messages on C<$channel>. The callback receives
the decoded data hash and the sender's L<Chandra::Socket::Connection>.

=head2 on_connect

	$hub->on_connect(sub { my ($conn) = @_; ... });

Called when a client completes the authenticated handshake.

=head2 on_disconnect

	$hub->on_disconnect(sub { my ($conn) = @_; ... });

Called when a client disconnects.

=head2 broadcast

	$hub->broadcast($channel, \%data);

Send a message to all connected clients.

=head2 send_to

	$hub->send_to($client_name, $channel, \%data);

Send a message to a specific client by name. Returns false if the client
is not connected.

=head2 clients

	my @names = $hub->clients;

Returns the names of all connected clients.

=head2 token

	my $token = $hub->token;

Returns the authentication token. Pass this to TCP clients that cannot
read the token file.

=head2 socket_path

	my $path = Chandra::Socket::Hub->socket_path($name);

Class method. Returns the socket file path for a given hub name, using
the same C<$XDG_RUNTIME_DIR> / C<tmpdir> logic as the constructor.

=head2 poll

	$hub->poll;

Non-blocking check for new connections and incoming messages.
Call this in your own event loop, or use C<run()> for a standalone loop.

=head2 run

	$hub->run;

Blocking event loop that calls C<poll()> continuously. Useful for
standalone hub processes.

=head2 close

	$hub->close;

Sends C<__shutdown> to all clients, closes all connections, removes the
socket and token files.

=head1 SECURITY

The Unix socket is created with 0600 permissions and placed in
C<$XDG_RUNTIME_DIR> (or the system temp directory) to limit access.

Hub generates a random authentication token on startup and writes it to a
token file (C<.token> beside the socket) with 0600 permissions. Clients
must present the correct token during the handshake or the connection is
rejected. For TCP transport, pass the token explicitly via the C<token>
parameter to L<Chandra::Socket::Client>.

For TCP transport over a network, enable TLS by passing C<tls_cert> and
C<tls_key> to the Hub, and C<< tls => 1 >> to the Client. This requires
L<IO::Socket::SSL>. Without TLS, TCP traffic (including the auth token)
is sent in plaintext.

=head1 SEE ALSO

L<Chandra::Socket::Client>, L<Chandra::Socket::Connection>, L<Chandra::App>

=cut
