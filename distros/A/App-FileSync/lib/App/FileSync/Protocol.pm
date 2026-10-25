package App::FileSync::Protocol;

# One connection, strictly one request in flight at a time.  Control messages
# are JSON on one line; binary payloads are announced by "len" in a header and
# follow it immediately.

use App::FileSync::Platform;

use strict;
use warnings;
# Not autodie qw(:all): this class has methods named send, recv and close, and
# autodie installs wrappers under those names in the package, then deletes
# them (taking the methods with them) when the file scope ends.  Only the
# builtins this file calls are covered.
use autodie qw(binmode sysread);

use Compress::Raw::Zlib ();
use IO::Handle ();
use Readonly;
use Sub::Private { mode => 'enforce' };

use parent -norequire, 'App::FileSync::Base';
use App::FileSync::Base;

use App::FileSync qw(json_encode json_decode);
use App::FileSync::Args qw(named);
use App::FileSync::I18N qw(os_error strip_location);

use version; our $VERSION = version->declare('0.001.2');

# Payloads are raw-deflated when that makes them smaller.  Small payloads and
# already-compressed data are left alone, so the flag costs more than it saves.
our $COMPRESS_MIN = 256;
our $MAX_WIRE     = 64 * 1024 * 1024;
our $MAX_INFLATED = 64 * 1024 * 1024;

# zlib level: the default trade-off between speed and size.
Readonly my $DEFLATE_LEVEL => 6;

# Bytes asked of the pipe per sysread.
Readonly my $READ_SIZE => 65_536;

=encoding utf8

=head1 NAME

App::FileSync::Protocol - the line-delimited JSON wire protocol

=head1 SYNOPSIS

	my $connection = App::FileSync::Protocol->new(in => $reader, out => $writer);
	$connection->send({ cmd => 'hello', proto => 2 });
	my $reply = $connection->recv();
	$connection->send_data({ cmd => 'chunk', p => $path }, $bytes);

=head1 DESCRIPTION

Each control message is one JSON object on one line.  A message announcing a
payload carries C<len> (the bytes on the wire) and, when the payload was
deflated, C<z>; the payload follows the line directly.  The connection counts
payload bytes in each direction for the transfer report.

When reading or writing fails because the pipe itself failed (the peer exited,
ssh was refused), L</transport_failed> becomes true, so a caller can show the
transport's own diagnostics instead of a protocol error.

=head1 METHODS

=head2 new

Purpose: wrap a pair of handles as a protocol connection.

Args: C<in> and C<out> (handles), optional C<language>.

Returns: the connection.

Side Effects: puts both handles in binary mode and makes C<out> autoflush.

Usage:

	my $connection = App::FileSync::Protocol->new(in => \*STDIN, out => \*STDOUT);

=head3 EXAMPLE

	my $connection = App::FileSync::Protocol->new(in => $transport->reader, out => $transport->writer);

=head3 API SPECIFICATION

=head4 INPUT

	{
		in       => { type => 'handle' },
		out      => { type => 'handle' },
		language => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::FileSync::Protocol' }

=head3 MESSAGES

	Key            Meaning                       Resolution
	args.invalid   a handle is missing           pass in and out

=head3 FORMAL SPECIFICATION

	new(in, out) = ⟨in, out, buffer ↦ ⟨⟩, closed ↦ false, sent ↦ 0, received ↦ 0⟩

=cut

sub new {
	my $class = shift;
	my $args = named(\@_, {
		in       => { type => 'handle' },
		out      => { type => 'handle' },
		language => { type => 'string', optional => 1 },
	}, 'Protocol->new');

	binmode $args->{in};
	binmode $args->{out};
	$args->{out}->autoflush(1);

	return bless {
		in               => $args->{in},
		out              => $args->{out},
		language         => $args->{language},
		buffer           => '',
		closed           => 0,
		transport_failed => 0,
		# Payload bytes as they crossed the wire, headers and control
		# messages excluded: this is the number a transfer report means.
		sent_bytes       => 0,
		received_bytes   => 0,
	}, $class;
}

=head2 send

Purpose: send one control message.

Args: C<\%message>.

Returns: 1.

Side Effects: writes one line.

Usage:

	$connection->send({ cmd => 'plan' });

=head3 EXAMPLE

	$connection->send({ ok => 1, off => $offset });

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',    type => 'object' },
		{ name => 'message', type => 'hashref' },
	]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

	Key                       Meaning                          Resolution
	protocol.closed           the connection was closed        a caller bug
	protocol.write_failed     the pipe would not take it       see the transport's stderr

=head3 FORMAL SPECIFICATION

	pre ¬closed
	out' = out ⁀ json(message) ⁀ "\n"

=cut

sub send {	## no critic (Subroutines::ProhibitBuiltinHomonyms)
	my ($self, $message) = @_;

	$self->_write(json_encode($message) . "\n");
	return 1;
}

=head2 recv

Purpose: read one control message.

Args: none.

Returns: the decoded message hashref.

Side Effects: reads from C<in>; blocks until a whole line arrives.

Usage:

	my $reply = $connection->recv();

=head3 EXAMPLE

	my $hello = $connection->recv();
	die unless $hello->{ok};

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key                   Meaning                        Resolution
	protocol.malformed    the line is not JSON           version mismatch or corrupt stream
	protocol.not_object   the JSON is not an object      version mismatch
	protocol.eof          the peer closed the connection see the peer's log
	protocol.read_failed  the pipe failed                see the transport's stderr

=head3 FORMAL SPECIFICATION

	in = line ⁀ "\n" ⁀ rest ⇒ recv = json⁻¹(line) ∧ in' = rest
	pre json⁻¹(line) ∈ OBJECT

=cut

sub recv {	## no critic (Subroutines::ProhibitBuiltinHomonyms)
	my ($self) = @_;

	my $line = $self->read_line();
	my $message = eval { json_decode($line) };
	$self->_throw('protocol.malformed', { error => strip_location($@) }) if $@;
	$self->_throw('protocol.not_object') unless ref($message) eq 'HASH';

	return $message;
}

=head2 send_bytes

Purpose: write raw bytes (the payload after a header).

Args: C<$bytes>; empty or undef writes nothing.

Returns: 1.

Side Effects: writes to C<out>.  Not counted in L</bytes_sent>; use
L</send_data> for counted payloads.

Usage:

	$connection->send_bytes($payload);

=head3 EXAMPLE

	$connection->send({ len => length $bytes });
	$connection->send_bytes($bytes);

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',  type => 'object' },
		{ name => 'bytes', type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

	Key                       Meaning                          Resolution
	protocol.closed           the connection was closed        a caller bug
	protocol.write_failed     the pipe would not take it       see the transport's stderr

=head3 FORMAL SPECIFICATION

	out' = out ⁀ bytes

=cut

sub send_bytes {
	my ($self, $bytes) = @_;

	$self->_write($bytes) if defined $bytes && length $bytes;
	return 1;
}

=head2 send_data

Purpose: send a header and its payload, compressing when worthwhile.

Args: C<\%header>, C<$bytes>.

Returns: 1.

Side Effects: writes the header (with C<len> and, if compressed, C<z>) and the
payload; adds the wire length to L</bytes_sent>.

Usage:

	$connection->send_data({ cmd => 'chunk', p => $path }, $bytes);

=head3 EXAMPLE

	$connection->send_data({ ok => 1, eof => 1 }, $last_chunk);

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',    type => 'object' },
		{ name => 'message', type => 'hashref', optional => 1 },
		{ name => 'bytes',   type => 'string', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

As for L</send>.

=head3 FORMAL SPECIFICATION

	let (w, z) = deflate(bytes)
	out' = out ⁀ json(header ⊕ {len ↦ #w} ⊕ (z ⇒ {z ↦ 1})) ⁀ "\n" ⁀ w
	sent' = sent + #w

=cut

sub send_data {
	my ($self, $message, $bytes) = @_;

	my ($wire, $compressed) = @{ _deflate(defined $bytes ? $bytes : '') };

	# The header carries the wire length and a "z" flag, so a peer that does
	# not know the flag rejects the frame rather than misreading it.
	my %header = %{ $message || {} };
	$header{len} = length $wire;
	$header{z}   = 1 if $compressed;

	$self->send(\%header);
	$self->send_bytes($wire);
	$self->{sent_bytes} += length $wire;

	return 1;
}

=head2 read_data

Purpose: read the payload a header announced.

Args: C<\%header> as returned by L</recv>.

Returns: the payload, decompressed if it was sent compressed.

Side Effects: reads C<len> bytes; adds them to L</bytes_received>.

Usage:

	my $bytes = $connection->read_data($header);

=head3 EXAMPLE

	my $reply = $connection->recv();
	my $bytes = $connection->read_data($reply);

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',    type => 'object' },
		{ name => 'message', type => 'hashref' },
	]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

	Key                      Meaning                                 Resolution
	protocol.bad_length      len is not a number or exceeds 64 MiB   a peer bug
	protocol.inflate         the payload cannot be decompressed      a corrupt stream
	protocol.corrupt         the compressed payload is corrupt       a corrupt stream
	protocol.too_large       it would inflate beyond 64 MiB          a hostile or buggy peer

=head3 FORMAL SPECIFICATION

	pre header.len ∈ 0 .. MAX_WIRE
	read_data(h) = inflate(take(h.len, in))   if h.z
	             = take(h.len, in)            otherwise
	received' = received + h.len

=cut

sub read_data {
	my ($self, $message) = @_;

	my $length = defined $message->{len} ? $message->{len} : 0;
	$self->_throw('protocol.bad_length')
		unless $length =~ /\A\d+\z/ && $length <= $MAX_WIRE;

	my $wire = $length ? $self->read_bytes($length) : '';
	$self->{received_bytes} += length $wire;

	return $message->{z} ? $self->_inflate($wire) : $wire;
}

=head2 read_line

Documented with L</read_bytes> below.

=head2 read_bytes

Purpose: read up to the next newline, or exactly C<$length> bytes.

Args: C<read_bytes($length)>.

Returns: the line (without its newline) or the bytes.

Side Effects: consumes them from the buffer, reading from C<in> as needed.

Usage:

	my $line = $connection->read_line();
	my $bytes = $connection->read_bytes(1024);

=head3 EXAMPLE

	my $payload = $connection->read_bytes($header->{len});

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',   type => 'object' },
		{ name => 'length', type => 'integer', min => 0 },
	]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

	Key                       Meaning                          Resolution
	protocol.negative         a negative length was asked for  a caller bug
	protocol.eof              the peer closed the connection   see the peer's log
	protocol.read_failed      the pipe failed                  see the transport's stderr

=head3 FORMAL SPECIFICATION

	read_line: in = l ⁀ "\n" ⁀ r ∧ "\n" ∉ ran l ⇒ result = l ∧ in' = r
	read_bytes(n): in = b ⁀ r ∧ #b = n ⇒ result = b ∧ in' = r

=cut

sub read_line {
	my ($self) = @_;

	my $position;
	$self->_fill() while ($position = index($self->{buffer}, "\n")) < 0;

	my $line = substr($self->{buffer}, 0, $position);
	substr($self->{buffer}, 0, $position + 1, '');

	return $line;
}

sub read_bytes {
	my ($self, $length) = @_;

	$self->_throw('protocol.negative') if $length < 0;
	$self->_fill() while length($self->{buffer}) < $length;

	return substr($self->{buffer}, 0, $length, '');
}

=head2 bytes_sent

Documented with L</bytes_received> below.

=head2 bytes_received

Purpose: payload bytes that crossed the wire in each direction.

Args: none.

Returns: a byte count (headers and control messages excluded).

Side Effects: none.

Usage:

	printf "sent %d bytes\n", $connection->bytes_sent;

=head3 EXAMPLE

	my %summary = (bytes_sent => $connection->bytes_sent, bytes_received => $connection->bytes_received);

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'integer', min => 0 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	bytes_sent = sent ; bytes_received = received

=cut

sub bytes_sent {
	my ($self) = @_;

	return $self->{sent_bytes} || 0;
}

sub bytes_received {
	my ($self) = @_;

	return $self->{received_bytes} || 0;
}

=head2 transport_failed

Purpose: whether the last failure was the pipe rather than the protocol.

Args: none.

Returns: 1 after a read or write on the underlying handles failed, or the peer
closed the connection; otherwise 0.

Side Effects: none.

Usage:

	my $detail = $connection->transport_failed ? $transport->error_text : undef;

=head3 EXAMPLE

	eval { $connection->recv() } or print "pipe failed\n" if $connection->transport_failed;

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'integer', min => 0, max => 1 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	transport_failed ⇔ ∃ an I/O failure or end of file on in or out

=cut

sub transport_failed {
	my ($self) = @_;

	return $self->{transport_failed} ? 1 : 0;
}

=head2 close

Purpose: close both handles.

Args: none.

Returns: 1, or nothing if already closed.

Side Effects: closes C<in> and C<out>; later sends raise C<protocol.closed>.

Usage:

	$connection->close;

=head3 EXAMPLE

	$connection->send({ cmd => 'done' });
	$connection->close;

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'integer', optional => 1 }

=head3 MESSAGES

None; close errors are ignored, as the session is over.

=head3 FORMAL SPECIFICATION

	closed' = true

=cut

sub close {	## no critic (Subroutines::ProhibitBuiltinHomonyms, Subroutines::ProhibitAmbiguousNames)
	my ($self) = @_;

	return if $self->{closed};
	$self->{closed} = 1;

	# The session is over; a pipe that reports an error on close has nothing
	# left to say that a caller could act on, so the result is not checked.
	CORE::close($self->{in});
	CORE::close($self->{out});

	return 1;
}

# _write
# Purpose:     put bytes on the wire.
# Entry:       the connection is open.
# Exit:        returns 1.
# Side effects: writes to out; on failure marks the transport as failed and
#              raises protocol.write_failed.  print is outside autodie.
sub _write :Private {
	my ($self, $bytes) = @_;

	$self->_throw('protocol.closed') if $self->{closed};
	unless (print { $self->{out} } $bytes) {
		my $error = "$!";
		$self->{transport_failed} = 1;
		$self->_throw('protocol.write_failed', { error => $error });
	}

	return 1;
}

# _fill
# Purpose:     read more bytes from the peer into the buffer.
# Entry:       the caller needs more than the buffer holds.
# Exit:        returns 1 after appending at least one byte.
# Side effects: on end of file or a read error marks the transport as failed
#              (and closed, for end of file) and raises.
sub _fill :Private {
	my ($self) = @_;

	my $chunk;
	my $read = eval { sysread($self->{in}, $chunk, $READ_SIZE) };
	unless (defined $read) {
		my $error = os_error($@);
		$self->{transport_failed} = 1;
		$self->_throw('protocol.read_failed', { error => $error });
	}
	if ($read == 0) {
		@{$self}{qw(closed transport_failed)} = (1, 1);
		$self->_throw('protocol.eof');
	}

	$self->{buffer} .= $chunk;
	return 1;
}

# _deflate
# Purpose:     compress a payload when that makes it smaller.
# Entry:       $bytes may be empty.
# Exit:        returns [ $wire_bytes, $compressed_flag ].
# Side effects: none.  Any zlib failure just sends the bytes as they are.
sub _deflate :Private {
	my ($bytes) = @_;

	return [ $bytes, 0 ] if length($bytes) < $COMPRESS_MIN;

	my ($deflater, $status) = Compress::Raw::Zlib::Deflate->new(
		-WindowBits => -Compress::Raw::Zlib::MAX_WBITS(),
		-Level      => $DEFLATE_LEVEL,
	);
	my $ok = $deflater && $status == Compress::Raw::Zlib::Z_OK();

	my ($out, $tail) = ('', '');
	$ok &&= $deflater->deflate($bytes, $out) == Compress::Raw::Zlib::Z_OK();
	$ok &&= $deflater->flush($tail) == Compress::Raw::Zlib::Z_OK();
	$out .= $tail;

	return ($ok && length($out) < length($bytes)) ? [ $out, 1 ] : [ $bytes, 0 ];
}

# _inflate
# Purpose:     decompress a payload sent with "z".
# Entry:       $wire is raw deflate data.
# Exit:        returns the original bytes.
# Side effects: raises protocol.inflate, protocol.corrupt or protocol.too_large.
sub _inflate :Private {
	my ($self, $wire) = @_;

	my ($inflater, $status) = Compress::Raw::Zlib::Inflate->new(
		-WindowBits => -Compress::Raw::Zlib::MAX_WBITS(),
	);
	$self->_throw('protocol.inflate')
		unless $inflater && $status == Compress::Raw::Zlib::Z_OK();

	my $out = '';
	$status = $inflater->inflate($wire, $out);
	$self->_throw('protocol.corrupt')
		unless $status == Compress::Raw::Zlib::Z_OK() || $status == Compress::Raw::Zlib::Z_STREAM_END();
	$self->_throw('protocol.too_large') if length($out) > $MAX_INFLATED;

	return $out;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * There is no cap on the length of a control line, because the plan for
a large tree is one line; see L<App::FileSync/LIMITATIONS>.

=item * The size check on a compressed payload happens after inflating it, so
a hostile peer can make the receiver allocate a large buffer once.  The peer
is authenticated by ssh before it can send anything.

=item * The method names C<send>, C<recv> and C<close> shadow Perl builtins;
call them as methods only.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
