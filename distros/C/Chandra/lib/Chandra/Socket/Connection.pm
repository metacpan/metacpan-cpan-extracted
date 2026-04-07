package Chandra::Socket::Connection;

use strict;
use warnings;

use Cpanel::JSON::XS ();
use POSIX ();

our $VERSION = '0.15';

# XS methods are registered under the Chandra bootstrap.
# Ensure the shared object is loaded.
require Chandra;

our $_xs_json = Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed;

# _xs_do_send, _xs_do_recv, _xs_json_encode, _xs_json_decode are now XSUBs in socket_connection.xs

# XS methods: new, socket, name, set_name, is_connected,
#   send, reply, recv, close, encode_frame, decode_frames

1;

__END__

=head1 NAME

Chandra::Socket::Connection - Wire protocol and connection wrapper for Chandra IPC

=head1 DESCRIPTION

Handles length-prefixed JSON framing for communication between
L<Chandra::Socket::Hub> and L<Chandra::Socket::Client> processes.

You normally do not create Connection objects directly; the Hub and Client
manage them internally.

=head1 WIRE PROTOCOL

Each frame consists of a 4-byte big-endian length prefix followed by a
UTF-8 JSON payload:

	[ 4-byte length N ][ N bytes of JSON ]

Messages are JSON objects with at least a C<channel> key and a C<data> key.
Additional keys (C<from>, C<_id>, C<_reply_to>) are used internally for
routing and request/response correlation.

=head1 LIMITS

=over 4

=item MAX_FRAME_SIZE

16 MB. Any single frame larger than this causes an immediate disconnect.

=item MAX_BUFFER_SIZE

64 MB. If the internal receive buffer exceeds this, the connection is
dropped to prevent memory exhaustion.

=back

Malformed JSON payloads are logged via C<warn> and discarded.

=head1 METHODS

=head2 new

	my $conn = Chandra::Socket::Connection->new(
	    socket => $sock,
	    name   => 'client-1',   # optional
	);

=head2 send

	$conn->send($channel, \%data);
	$conn->send($channel, \%data, { _id => 1 });

Encode and send a framed message. Returns true on success.

=head2 reply

	$conn->reply($original_msg, \%response_data);

Send a response correlated to a request (uses C<_reply_to>).

=head2 recv

	my @messages = $conn->recv;

Non-blocking read. Returns decoded message hashes, or an empty list if
no complete frames are available. Sets C<is_connected> to false on EOF
or error.

=head2 is_connected

	if ($conn->is_connected) { ... }

=head2 name / set_name

	my $name = $conn->name;
	$conn->set_name('new-name');

=head2 socket

	my $fh = $conn->socket;

Returns the underlying socket filehandle.

=head2 close

	$conn->close;

=head2 encode_frame (class method)

	my $bytes = Chandra::Socket::Connection->encode_frame(\%msg);

Encode a message hash to a wire frame. Useful for testing.

=head2 decode_frames (class method)

	my @msgs = Chandra::Socket::Connection->decode_frames($bytes);

Decode one or more frames from a byte string. Useful for testing.

=head1 SEE ALSO

L<Chandra::Socket::Hub>, L<Chandra::Socket::Client>

=cut
