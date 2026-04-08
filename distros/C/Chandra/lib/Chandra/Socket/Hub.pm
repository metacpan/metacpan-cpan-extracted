package Chandra::Socket::Hub;

use strict;
use warnings;

use IO::Select;
use Chandra::Socket::Connection;

our $VERSION = '0.17';

require Chandra;

# All socket helpers implemented as C functions in
# include/chandra/chandra_socket_hub.h
# _xs_generate_token is a C XSUB in socket_hub.xs

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
