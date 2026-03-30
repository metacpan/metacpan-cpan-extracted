package Chandra::Socket::Client;

use strict;
use warnings;

use Chandra::Socket::Connection;
use File::Spec ();

our $VERSION = '0.06';

sub new {
	my ($class, %args) = @_;

	my $self = bless {
		name      => $args{name},
		hub_name  => $args{hub},
		transport => $args{transport} || 'unix',
		host        => $args{host} || '127.0.0.1',
		port        => $args{port},
		tls         => $args{tls},
		tls_ca      => $args{tls_ca},
		_conn       => undef,
		_handlers => {},
		_pending  => {},    # _id => callback for request/response
		_next_id  => 0,
		_retry_delay    => 0.1,
		_max_retry      => 5,
		_token          => $args{token},
		_explicit_token => defined $args{token},
	}, $class;

	$self->_connect;
	return $self;
}

sub _connect {
	my ($self) = @_;

	my $sock;
	if ($self->{transport} eq 'tcp') {
		if ($self->{tls}) {
			require IO::Socket::SSL;
			$sock = IO::Socket::SSL->new(
				PeerHost        => $self->{host},
				PeerPort        => $self->{port},
				SSL_verify_mode => $self->{tls_ca}
				? IO::Socket::SSL::SSL_VERIFY_PEER()
				: IO::Socket::SSL::SSL_VERIFY_NONE(),
				($self->{tls_ca} ? (SSL_ca_file => $self->{tls_ca}) : ()),
			);
		} else {
			require IO::Socket::INET;
			$sock = IO::Socket::INET->new(
				PeerHost => $self->{host},
				PeerPort => $self->{port},
				Proto    => 'tcp',
			);
		}
		$sock->blocking(0) if $sock;
	} else {
		require IO::Socket::UNIX;
		my $dir = $ENV{XDG_RUNTIME_DIR} || File::Spec->tmpdir;
		my $path = File::Spec->catfile($dir, 'chandra-' . $self->{hub_name} . '.sock');
		$sock = IO::Socket::UNIX->new(
			Peer => $path,
			Type => IO::Socket::UNIX::SOCK_STREAM(),
		);
		$sock->blocking(0) if $sock;
		if ($sock && !$self->{_explicit_token}) {
			my $token_path = "$path.token";
			if (open my $fh, '<', $token_path) {
				$self->{_token} = do { local $/; <$fh> };
				close $fh;
			}
		}
	}

	return 0 unless $sock;

	$self->{_conn} = Chandra::Socket::Connection->new(
		socket => $sock,
		name   => $self->{name},
	);

	# Send handshake with authentication token
	$self->{_conn}->send('__handshake', { name => $self->{name}, token => $self->{_token} });
	$self->{_retry_delay} = 0.1;
	return 1;
}

sub is_connected {
	my ($self) = @_;
	return $self->{_conn} && $self->{_conn}->is_connected ? 1 : 0;
}

sub on {
	my ($self, $channel, $cb) = @_;
	$self->{_handlers}{$channel} = $cb;
	return $self;
}

sub send {
	my ($self, $channel, $data) = @_;
	return 0 unless $self->{_conn};
	return $self->{_conn}->send($channel, $data);
}

sub request {
	my ($self, $channel, $data, $cb) = @_;
	return 0 unless $self->{_conn};

	my $id = ++$self->{_next_id};
	$self->{_pending}{$id} = $cb;
	return $self->{_conn}->send($channel, $data, { _id => $id });
}

sub poll {
	my ($self) = @_;

	unless ($self->is_connected) {
		$self->reconnect;
		return $self;
	}

	my @messages = $self->{_conn}->recv;

	unless (@messages || $self->is_connected) {
		$self->reconnect;
		return $self;
	}

	for my $msg (@messages) {
		# Check if this is a reply to a pending request
		if (defined $msg->{_reply_to} && $self->{_pending}{$msg->{_reply_to}}) {
			my $cb = delete $self->{_pending}{$msg->{_reply_to}};
			$cb->($msg->{data});
		} elsif ($msg->{channel} && $self->{_handlers}{$msg->{channel}}) {
			$self->{_handlers}{$msg->{channel}}->($msg->{data});
		}
	}

	return $self;
}

sub reconnect {
	my ($self) = @_;
	$self->{_conn}->close if $self->{_conn};
	$self->{_conn} = undef;

	unless ($self->_connect) {
		$self->{_retry_delay} *= 2 if $self->{_retry_delay} < $self->{_max_retry};
	}
	return $self;
}

sub close {
	my ($self) = @_;
	if ($self->{_conn}) {
		$self->{_conn}->close;
		$self->{_conn} = undef;
	}
}

sub DESTROY {
	my ($self) = @_;
	$self->close;
}

1;

__END__

=head1 NAME

Chandra::Socket::Client - IPC client for connecting to a Chandra Hub

=head1 SYNOPSIS

	use Chandra::Socket::Client;

	# Unix socket — token is read automatically from the token file
	my $client = Chandra::Socket::Client->new(
	    name => 'window-1',
	    hub  => 'myapp',
	);

	# TCP — token must be passed explicitly
	my $client = Chandra::Socket::Client->new(
	    name      => 'remote-1',
	    transport => 'tcp',
	    host      => '10.0.0.5',
	    port      => 9000,
	    token     => $token,
	);

	# TCP with TLS (requires IO::Socket::SSL)
	my $client = Chandra::Socket::Client->new(
	    name      => 'remote-1',
	    transport => 'tcp',
	    host      => '10.0.0.5',
	    port      => 9000,
	    token     => $token,
	    tls       => 1,
	    tls_ca    => '/path/to/ca.pem',   # optional cert verification
	);

	# Via Chandra::App helper
	my $client = $app->client(name => 'window-1', hub => 'myapp');

	$client->on('navigate', sub {
	    my ($data) = @_;
	    $app->navigate($data->{path});
	});

	$client->send('status_update', { status => 'ready' });

	$app->run;

=head1 DESCRIPTION

Client connects to a L<Chandra::Socket::Hub> server via Unix domain socket
(default) or TCP. It authenticates via a token-based handshake and can
send/receive messages on named channels.

For Unix sockets the authentication token is read automatically from the
token file created by the Hub. For TCP, pass the token explicitly.

=head1 CONSTRUCTOR

=head2 new

	my $client = Chandra::Socket::Client->new(%args);

=over 4

=item name

(Required) Client name sent during the handshake. Must be unique per Hub.

=item hub

(Required for Unix transport) Name of the Hub to connect to (matches the
Hub's C<name> parameter).

=item transport

C<'unix'> (default) or C<'tcp'>.

=item host

Hub host for TCP. Defaults to C<'127.0.0.1'>.

=item port

(Required for TCP) Hub port number.

=item token

Authentication token. For Unix sockets this is read from the token file
automatically. For TCP it must be provided (see C<< $hub->token >>).

=item tls

Set to a true value to connect via TLS. Requires L<IO::Socket::SSL>.

=item tls_ca

Path to a CA certificate file for server verification. When omitted, peer
verification is disabled.

=back

=head1 METHODS

=head2 on

	$client->on($channel => sub { my ($data) = @_; ... });

Register a handler for messages on C<$channel>.

=head2 send

	$client->send($channel, \%data);

Send a message to the Hub.

=head2 request

	$client->request($channel, \%data, sub { my ($reply) = @_; ... });

Send a request and register a callback for the correlated reply.

=head2 is_connected

	if ($client->is_connected) { ... }

Returns true if the underlying connection is alive.

=head2 poll

	$client->poll;

Non-blocking check for incoming messages. Triggers auto-reconnect if
the connection has dropped.

=head2 reconnect

	$client->reconnect;

Close the current connection (if any) and attempt to reconnect with
exponential back-off.

=head2 close

	$client->close;

Close the connection.

=head1 SEE ALSO

L<Chandra::Socket::Hub>, L<Chandra::Socket::Connection>, L<Chandra::App>

=cut
