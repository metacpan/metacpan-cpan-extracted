package Chandra::Socket::Client;

use strict;
use warnings;

use Chandra::Socket::Connection;

our $VERSION = '0.14';

require Chandra;

# All socket helpers implemented as C functions in
# include/chandra/chandra_socket_client.h

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

