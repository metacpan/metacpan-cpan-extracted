package Chandra::Socket::Connection;

use strict;
use warnings;

use Cpanel::JSON::XS ();
use POSIX qw(EAGAIN EWOULDBLOCK);

our $VERSION = '0.06';

my $json = Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed;

use constant MAX_FRAME_SIZE  => 16 * 1024 * 1024;   # 16 MB
use constant MAX_BUFFER_SIZE => 64 * 1024 * 1024;   # 64 MB

sub new {
	my ($class, %args) = @_;
	return bless {
		socket     => $args{socket},
		name       => $args{name},
		_buf       => '',
		_connected => $args{socket} ? 1 : 0,
	}, $class;
}

sub socket    { $_[0]->{socket} }
sub name      { $_[0]->{name} }
sub set_name  { $_[0]->{name} = $_[1] }

sub is_connected {
	my ($self) = @_;
	return $self->{_connected} && $self->{socket} ? 1 : 0;
}

sub send {
	my ($self, $channel, $data, $extra) = @_;
	return 0 unless $self->is_connected;

	my $msg = {
		channel => $channel,
		data    => $data,
		($self->{name} ? (from => $self->{name}) : ()),
	};
	if ($extra && ref $extra eq 'HASH') {
		$msg->{$_} = $extra->{$_} for keys %$extra;
	}

	my $payload = $json->encode($msg);
	my $frame = pack('N', length($payload)) . $payload;

	local $SIG{PIPE} = 'IGNORE';
	my $written = $self->{socket}->syswrite($frame);
	return (defined $written && $written == length($frame)) ? 1 : 0;
}

sub reply {
	my ($self, $orig_msg, $data) = @_;
	return 0 unless $orig_msg && defined $orig_msg->{_id};
	return $self->send($orig_msg->{channel}, $data, { _reply_to => $orig_msg->{_id} });
}

sub recv {
	my ($self) = @_;
	return () unless $self->is_connected;

	my $buf;
	my $read = $self->{socket}->sysread($buf, 65536);
	if ($read) {
		$self->{_buf} .= $buf;
		if (length($self->{_buf}) > MAX_BUFFER_SIZE) {
			warn "Chandra::Socket::Connection: buffer overflow, disconnecting\n";
			$self->{_connected} = 0;
			$self->{_buf} = '';
			return ();
		}
	} elsif (!defined $read && $! != EAGAIN && $! != EWOULDBLOCK) {
		$self->{_connected} = 0;
		return ();
	} elsif (defined $read && $read == 0) {
		$self->{_connected} = 0;
		return ();
	}

	return $self->_decode_frames;
}

sub _decode_frames {
	my ($self) = @_;
	my @messages;

	while (length($self->{_buf}) >= 4) {
		my $len = unpack('N', substr($self->{_buf}, 0, 4));
		if ($len > MAX_FRAME_SIZE) {
			warn "Chandra::Socket::Connection: frame too large ($len bytes), disconnecting\n";
			$self->{_connected} = 0;
			$self->{_buf} = '';
			return @messages;
		}
		last if length($self->{_buf}) < 4 + $len;

		my $payload = substr($self->{_buf}, 4, $len);
		$self->{_buf} = substr($self->{_buf}, 4 + $len);

		my $msg = eval { $json->decode($payload) };
		if ($msg) {
			push @messages, $msg;
		} else {
			warn "Chandra::Socket::Connection: malformed JSON frame: $@\n";
		}
	}

	return @messages;
}

sub close {
	my ($self) = @_;
	$self->{_connected} = 0;
	if ($self->{socket}) {
		$self->{socket}->close;
		$self->{socket} = undef;
	}
}

# Encode/decode helpers for testing
sub encode_frame {
	my ($class, $msg) = @_;
	my $payload = $json->encode($msg);
	return pack('N', length($payload)) . $payload;
}

sub decode_frames {
	my ($class, $data) = @_;
	my @messages;
	my $buf = $data;
	while (length($buf) >= 4) {
		my $len = unpack('N', substr($buf, 0, 4));
		last if length($buf) < 4 + $len;
		my $payload = substr($buf, 4, $len);
		$buf = substr($buf, 4 + $len);
		my $msg = eval { $json->decode($payload) };
		push @messages, $msg if $msg;
	}
	return @messages;
}

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
