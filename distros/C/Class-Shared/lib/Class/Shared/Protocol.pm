package Class::Shared::Protocol;

use strict;
use warnings;

use Scalar::Util ();
use Storable ();

our $VERSION = '0.001.0';

# Requests and responses are a 4 byte network order length followed by a
# Storable image of a hashref.  One frame in flight per connection.
our $MAX_FRAME = 64 * 1024 * 1024;

# When a shared secret is in use the payload is an HMAC-SHA-256 of the body
# followed by the body.  The digest is checked before Storable sees a byte, so
# a peer that does not know the secret cannot make this process thaw -- and so
# run -- code of its choosing.
our $DIGEST_SIZE = 32;

# Storable before 3.05 (perl 5.26 ships 2.62) has no recursion limit: freezing
# data nested some tens of thousands deep overflows the C stack and kills the
# process, which no eval can catch.  There, and only there, the depth is
# checked first.
our $MAX_DEPTH = 10_000;
our $CHECK_DEPTH = !eval { Storable->VERSION('3.05'); 1 };

sub encode_frame {
	my ($message, $secret) = @_;

	return (undef, "cannot serialise message: it is nested more than $MAX_DEPTH deep")
		if $CHECK_DEPTH && _too_deep($message);

	# The caller's $@ is theirs: this eval must not leave a trace in it.
	local $@;
	my $frozen = eval { Storable::nfreeze($message) };
	if (!defined $frozen) {
		my $error = $@ || 'unknown error';
		$error =~ s/\s+\z//;
		return (undef, "cannot serialise message: $error");
	}

	if (length($frozen) > $MAX_FRAME) {
		return (undef, 'message is too large (' . length($frozen)
			. " bytes, limit is $MAX_FRAME)");
	}

	if (defined $secret) {
		my $digest = _digest($secret, $frozen);
		return pack('N', length($digest) + length($frozen)) . $digest . $frozen;
	}

	return pack('N', length($frozen)) . $frozen;
}

sub take_payload {
	my ($body) = @_;

	local $@;
	my $message = eval { Storable::thaw($body) };
	if ($@) {
		my $error = $@;
		$error =~ s/\s+\z//;
		return (undef, "cannot deserialise message: $error");
	}

	# thaw returns undef, without dying, for an image that is cut short.  That
	# must not look like a frame that was read successfully: the caller would
	# get no message and no error to report.
	return (undef, 'cannot deserialise message: the image is incomplete')
		unless defined $message;

	return ($message, undef);
}

# Write every byte, or report why not.
# Returns (1) on success, (0, $error) on failure.
sub write_all {
	my ($fh, $bytes) = @_;

	# A backend that has just died must not take the client with it.
	local $SIG{PIPE} = 'IGNORE';

	my $length = length $bytes;
	my $offset = 0;

	while ($offset < $length) {
		my $written = syswrite($fh, $bytes, $length - $offset, $offset);

		if (!defined $written) {
			# A signal the program handled is not a fault in the connection.  A
			# handler that dies still ends the write.
			next if $!{EINTR};
			return (0, "write failed: $!");
		}
		# TODO: Unreachable code detected during path analysis. Investigate for removal.
		if ($written == 0) {
			return (0, 'write failed: peer closed the connection');
		}

		$offset += $written;
	}

	return (1);
}

# Blocking read of exactly one frame.  Returns ($message) or (undef, $error).
# An optional timeout is in seconds.
sub read_frame {
	my ($fh, $timeout, $secret) = @_;

	my ($header, $error) = _read_exact($fh, 4, $timeout);
	return (undef, $error) unless defined $header;

	my $length = unpack('N', $header);
	my $room = defined $secret ? $MAX_FRAME + $DIGEST_SIZE : $MAX_FRAME;

	return (undef, "frame of $length bytes exceeds the limit of $room")
		if $length > $room;

	my ($payload, $body_error) = _read_exact($fh, $length, $timeout);
	return (undef, $body_error) unless defined $payload;

	return _decode($payload, $secret);
}

sub _read_exact {
	my ($fh, $length, $timeout) = @_;

	my $buffer = '';

	while (length($buffer) < $length) {
		# A TLS socket can be holding decrypted bytes that select cannot
		# see, because they arrived in a record already read from the kernel.
		# Take those before waiting for more.
		# Only an object (a TLS socket) can say what it is holding.  Calling a
		# method on a plain handle would make Perl load IO::File to answer.
		if (Scalar::Util::blessed($fh) && $fh->can('pending') && $fh->pending) {
			my $pending = sysread($fh, $buffer, $length - length($buffer),
				length($buffer));

			next if !defined $pending && $!{EINTR};
			return (undef, "read failed: $!") if !defined $pending;
			return (undef, 'connection closed by peer') if $pending == 0;

			next;
		}

		if (defined $timeout) {
			if (_can_select($fh)) {
				return (undef, 'timed out waiting for a reply')
					unless _wait_readable($fh, $timeout);
			} elsif (!-f $fh) {
				# A plain file never makes a read wait; anything else might
				# wait for ever.
				return (undef, 'cannot apply a timeout: on Windows only a socket '
					. 'or a plain file can be waited for');
			}
		}

		my $got = sysread($fh, $buffer, $length - length($buffer), length($buffer));

		if (!defined $got) {
			next if $!{EINTR};
			return (undef, "read failed: $!");
		}
		if ($got == 0) {
			return (undef, 'connection closed by peer');
		}
	}

	return ($buffer);
}

# Purpose:       say whether select can wait on $fh.
# Entry:         $fh is an open handle.
# Exit status:   1 if it can, 0 if not.
# Side effects:  on Windows, loads Socket.
# Why:           Windows select takes sockets and nothing else.
sub _can_select {
	my ($fh) = @_;

	return 1 unless $^O eq 'MSWin32';

	require Socket;

	return defined getsockopt($fh, Socket::SOL_SOCKET(), Socket::SO_TYPE()) ? 1 : 0;
}

# Purpose:       wait up to $timeout seconds for $fh to have something to read.
# Entry:         $fh is an open handle; $timeout is in seconds.
# Exit status:   1 if it has, 0 if the time ran out or select failed.
# Side effects:  loads Time::HiRes.
# Why:           a signal ends select early.  The wait goes on for what is left
#                of the time, so repeated signals cannot stretch it.
sub _wait_readable {
	my ($fh, $timeout) = @_;

	require Time::HiRes;

	my $rin = '';
	vec($rin, fileno($fh), 1) = 1;

	my $deadline = Time::HiRes::time() + $timeout;
	my $left = $timeout;

	while (1) {
		my $ready = select(my $rout = $rin, undef, undef, $left);
		return 1 if $ready > 0;
		return 0 unless $ready < 0 && $!{EINTR};

		$left = $deadline - Time::HiRes::time();
		$left = 0 if $left < 0;
	}
}

# Incremental parser for the backend's select loop.  With a secret, a frame
# whose digest does not verify is reported as unusable without being thawed.
# Returns ( 1, $message, undef) when a whole frame was taken out of the buffer,
#         ( 0, undef,    undef) when more bytes are needed,
#         (-1, undef,    $error) when the stream is unusable.
sub take_frame {
	my ($buffer_ref, $secret, $check) = @_;

	return (0, undef, undef) if length($$buffer_ref) < 4;

	my $length = unpack('N', substr($$buffer_ref, 0, 4));
	my $room = defined $secret ? $MAX_FRAME + $DIGEST_SIZE : $MAX_FRAME;

	return (-1, undef, "frame of $length bytes exceeds the limit of $room")
		if $length > $room;

	return (0, undef, undef) if length($$buffer_ref) < 4 + $length;

	my $payload = substr($$buffer_ref, 4, $length);
	substr($$buffer_ref, 0, 4 + $length) = '';

	my ($message, $error) = _decode($payload, $secret, $check);
	return (-1, undef, $error) if defined $error;

	return (1, $message, undef);
}

# Purpose:       say whether data is nested more than $MAX_DEPTH deep.
# Entry:         $data is anything.
# Exit status:   1 if it is, 0 if not.
# Side effects:  none.  It keeps its own list of what is left to visit rather
#                than calling itself, and visits each thing once, so cycles
#                end.
sub _too_deep {
	my @todo = ([$_[0], 0]);
	my %seen;

	while (@todo) {
		my ($item, $depth) = @{ pop @todo };

		my $type = Scalar::Util::reftype($item) or next;
		next if $seen{ Scalar::Util::refaddr($item) }++;
		return 1 if ++$depth > $MAX_DEPTH;

		if ($type eq 'ARRAY') {
			push @todo, map { [$_, $depth] } grep { ref } @{$item};
		} elsif ($type eq 'HASH') {
			push @todo, map { [$_, $depth] } grep { ref } values %{$item};
		} elsif ($type eq 'REF') {
			push @todo, [${$item}, $depth];
		}
	}

	return 0;
}

# Payload to message.  With a secret the digest is checked first, and the body
# is not handed to Storable unless it matches: thaw() runs whatever the sender
# put in the image, so the authentication has to happen before it, not after.
sub _decode {
	my ($payload, $secret, $check) = @_;

	# TODO: Data Flow Anomaly - DD: when there is a secret, body is redefined below before it is read
	my $body = $payload;

	if (defined $secret) {
		return (undef, 'frame is too short to be authenticated')
			if length($payload) < $DIGEST_SIZE;

		my $digest = substr($payload, 0, $DIGEST_SIZE);
		$body = substr($payload, $DIGEST_SIZE);

		return (undef, 'frame failed authentication')
			unless _authentic($secret, $body, $digest);
	}

	return (undef, 'cannot deserialise message: reading it would crash the process')
		if $check && !$check->($body);

	return take_payload($body);
}

# Loaded on demand: a client that only talks to a local unix socket without a
# token never pays to load Digest::SHA.
sub _digest {
	my ($secret, $body) = @_;

	require Digest::SHA;

	return Digest::SHA::hmac_sha256($body, $secret);
}

# Compared without an early exit, so that the time taken says nothing about
# how much of a guessed digest was right.
sub _authentic {
	my ($secret, $body, $digest) = @_;

	my $expected = _digest($secret, $body);

	return 0 unless length($expected) == length($digest);

	my $difference = 0;
	for my $offset (0 .. length($expected) - 1) {
		$difference |= ord(substr($expected, $offset, 1))
			^ ord(substr($digest, $offset, 1));
	}

	return $difference == 0 ? 1 : 0;
}

1;

__END__

=encoding utf8

=head1 NAME

Class::Shared::Protocol - framing for Class::Shared's socket protocol

=head1 SYNOPSIS

    use Class::Shared::Protocol;

    # 1. Send one request and read one reply (blocking).
    #    $socket is a connected socket to a backend.
    my $socket;

    my ($bytes, $error) = Class::Shared::Protocol::encode_frame({ op => 'ping' });
    die $error unless defined $bytes;

    my ($sent, $write_error) = Class::Shared::Protocol::write_all($socket, $bytes);
    die $write_error unless $sent;

    my ($message, $read_error) = Class::Shared::Protocol::read_frame($socket);
    die $read_error unless defined $message;

    # 2. The same, with a shared secret so that every frame is authenticated,
    #    and with a 5 second limit on each wait for data.
    my $secret = 'the secret both ends were given';

    ($bytes, $error) = Class::Shared::Protocol::encode_frame({ op => 'ping' }, $secret);
    Class::Shared::Protocol::write_all($socket, $bytes);

    ($message, $read_error) = Class::Shared::Protocol::read_frame($socket, 5, $secret);

    # 3. Read from a non-blocking socket in a loop, as the backend does.
    my $buffer = '';
    while (sysread($socket, my $chunk, 65536)) {
        $buffer .= $chunk;

        while (1) {
            my ($status, $frame, $problem)
                = Class::Shared::Protocol::take_frame(\$buffer, $secret);

            last if $status == 0;                  # need more bytes
            die $problem if $status < 0;           # bad stream: close it
            handle($frame);                        # status == 1: a whole frame
        }
    }

=head1 DESCRIPTION

A I<frame> is one message on the wire.  It is a four byte length (in "network
order", the most significant byte first) followed by a L<Storable> image of a
hash reference.  One request or one reply is in flight on a connection at a
time.

When a shared secret is in use, the data after the length is instead a 32 byte
HMAC-SHA-256 of the body followed by the body.  (An HMAC is a short code that
only somebody who knows the secret can calculate.  It shows that the body was
not changed and that it came from somebody who has the secret.)

    length | hmac-sha256(secret, body) | storable image of the request

The digest is verified before the body is thawed (turned back into Perl data).
That ordering is the point: L<Storable::thaw> builds whatever the image
describes, and so runs the sender's choice of code, so a frame from somebody who
does not know the secret must be rejected before it reaches Storable.

Nothing here knows what the messages mean; that lives in
L<Class::Shared::Backend>.

Every function in this module reports a problem by returning a pair, C<(undef,
$error)> or C<(0, $error)>, and never by dying (except for a mistake such as a
bad argument that Perl itself rejects).  Always call them in list context, as
the examples do.  See L</COMMON PITFALLS>.

=head1 FUNCTIONS

The schemas in each B<API SPECIFICATION> follow the conventions of
L<Params::Validate::Strict> (for input) and L<Return::Set> (for output).  They
describe the function for people and for tools.  The code does not call those
modules, and this distribution does not depend on them.

=head2 encode_frame

    my ($bytes, $error) = Class::Shared::Protocol::encode_frame($message, $secret);

Turns a message into the bytes to send.  C<$message> must be a reference to
data that Storable can freeze (normally a hash reference).  Pass C<$secret> to
add the HMAC digest.

Returns the framed bytes as one value, or C<(undef, $error)> if the message
cannot be serialised (for example it holds a code reference) or if it is larger
than C<$Class::Shared::Protocol::MAX_FRAME> (64 MiB).

A secret is "given" when it is defined, so even an empty string turns
authentication on.  Do not use an empty secret.

B<Side effects:> none.  If a secret is given, L<Digest::SHA> is loaded the first
time.

=head3 API SPECIFICATION

=head4 Input

    {
        message => { type => 'hashref', position => 0, optional => 0 },
        secret  => { type => 'string',  position => 1, optional => 1 },
    }

=head4 Domains

    valid    a reference that L<Storable> can freeze, and an optional secret
             of any length (defined means authentication is on, and that
             includes the empty string)
    invalid  a non-reference, a reference holding code or a filehandle, data
             nested deeper than 10000 where Storable has no recursion limit,
             and a body larger than MAX_FRAME (67,108,864 bytes)

    partition              representative        result
    ----------------------------------------------------------
    small hash             { op => "ping" }      framed bytes
    full Unicode text      U+00FC, U+1F600        framed, as bytes
    code reference         { cb => sub {} }      (undef, cannot serialise)
    plain string           "text"                (undef, cannot serialise)
    undef                  undef                 (undef, cannot serialise)
    body at MAX_FRAME      exactly the limit     accepted
    body at MAX_FRAME + 1  one byte more         (undef, too large)

    With a secret the frame is 32 bytes longer, the digest being in front of
    the body; the limit applies to the body.  A message of 64 MiB is the
    largest that can be sent, and the error names the size and the limit.

=head4 Output

    {
        type        => 'string',
        description => 'the framed bytes; on failure the list (undef, $error) instead',
    }

=head2 take_payload

    my ($message, $error) = Class::Shared::Protocol::take_payload($body);

Turns the body of a frame back into Perl data.  It does B<no> authentication.
Use L</take_frame> or L</read_frame> for bytes that came from a network, because
they check the digest first.

Returns C<($message, undef)>, or C<(undef, $error)> if the bytes are not a valid
Storable image.

B<Side effects:> none.

=head3 API SPECIFICATION

=head4 Input

    { body => { type => 'string', position => 0, optional => 0 } }

=head4 Domains

    valid    the body of a frame: a Storable image of any reference
    invalid  the empty string, a truncated image, and anything that is not a
             Storable image

    partition          representative          result
    ------------------------------------------------------
    a whole image      from encode_frame       (message, undef)
    one byte missing   image minus its last    (undef, incomplete)
    empty body         ""                      (undef, cannot deserialise)
    text               "not an image"          (undef, cannot deserialise)

    A truncated image is refused with "the image is incomplete" rather than
    being returned as an undef message.  This function does no
    authentication: use L</take_frame> or L</read_frame> for bytes from a
    network.

=head4 Output

    {
        type   => 'arrayref',
        min    => 2,
        max    => 2,
        schema => [
            { type => 'hashref', optional => 1, description => 'the message, or undef on error' },
            { type => 'string',  optional => 1, description => 'the error, or undef on success' },
        ],
    }

=head2 write_all

    my ($ok, $error) = Class::Shared::Protocol::write_all($filehandle, $bytes);

Writes every byte, even if the system accepts only part of them at a time.
Returns C<(1)> on success, or C<(0, $error)>.  While it runs, a broken pipe is
ignored, so a backend that has just died does not kill the client with a signal;
you get an error instead.

It is meant for blocking handles.  On a non-blocking handle that cannot take
more data right now, it returns an error and does not wait.

B<Side effects:> writes to the handle.

=head3 API SPECIFICATION

=head4 Input

    {
        filehandle => { type => 'object', position => 0, optional => 0, can => 'syswrite' },
        bytes      => { type => 'string', position => 1, optional => 0 },
    }

=head4 Domains

    valid    any handle that can be written to, and bytes of length 0 or more
    invalid  a handle whose peer has closed, which returns
             C<(0, "write failed: ...")> rather than raising SIGPIPE

    partition            representative   result
    -------------------------------------------------
    bytes of length 0    ""               (1), a write of nothing
    a few bytes          "hello"          (1)
    peer closed          after close      (0, "write failed: ...")

    Zero bytes is the smallest accepted message and is a success, not a
    failure: the loop has nothing to do.  The value of the bytes is not
    inspected, so a binary frame and a multibyte string are written as given.

=head4 Output

    {
        type   => 'arrayref',
        min    => 1,
        max    => 2,
        schema => [
            { type => 'boolean', description => '1 on success, 0 on failure' },
            { type => 'string',  optional => 1, description => 'the error, on failure' },
        ],
    }

=head2 read_frame

    my ($message, $error) = Class::Shared::Protocol::read_frame($filehandle, $timeout, $secret);

Reads exactly one frame, checks its digest if a secret is given, and returns the
message.  It waits for ever unless you give C<$timeout> in seconds.  The timeout
applies to each wait for more data, so a peer that keeps sending slowly can take
longer than C<$timeout> in total.

Returns C<($message)>, or C<(undef, $error)> if the connection closes, the wait
times out, the frame is too large, the digest is wrong, or the data is not a
valid image.

It understands TLS handles: it takes data that TLS has already decrypted before
it waits for more.

On Windows only a socket can be waited for.  A plain file never makes a read
wait, so it is read whatever C<$timeout> says.  Any other handle, such as a
pipe, cannot be given a timeout: C<read_frame> returns C<(undef, $error)> with
an error that begins C<cannot apply a timeout>, without reading.  Give no
timeout to read such a handle.

B<Side effects:> reads from the handle.  After an error the handle may be half
way through a frame, so close it.

=head3 API SPECIFICATION

=head4 Input

    {
        filehandle => { type => 'object', position => 0, optional => 0, can => 'sysread' },
        timeout    => { type => 'number', position => 1, optional => 1, min => 0 },
        secret     => { type => 'string', position => 2, optional => 1 },
    }

=head4 Domains

    valid    a handle and an optional timeout of 0 or more seconds (undef
             waits for ever); a body of 0 to MAX_FRAME bytes, plus 32 when a
             secret is given
    invalid  a header above the limit, a digest that does not verify, a body
             that is not a Storable image, a peer that closes, and a wait that
             runs out

    partition                representative        result
    ------------------------------------------------------------
    a whole frame            encode_frame output   (message, undef)
    header at MAX_FRAME      no body follows       (undef, closed by peer)
    header at MAX_FRAME + 1  any                   (undef, exceeds the limit)
    timeout 0, no data       empty pipe            (undef, timed out)
    peer closed              empty pipe            (undef, closed by peer)
    Windows, timeout, file   a whole frame         (message, undef)
    Windows, timeout, pipe   anything              (undef, cannot apply ...)

    The "empty pipe" rows with a timeout do not apply on Windows.

    Boundary values: a header of exactly MAX_FRAME is accepted as a length and
    fails only when the body cannot be read; MAX_FRAME + 1 is refused before
    any body is read.  A timeout of 0 means "do not wait" and is the minimum.

=head4 Output

    {
        type   => 'arrayref',
        min    => 1,
        max    => 2,
        schema => [
            { type => 'hashref', optional => 1, description => 'the message, or undef on error' },
            { type => 'string',  optional => 1, description => 'the error, on failure' },
        ],
    }

=head2 take_frame

    my ($status, $message, $error)
        = Class::Shared::Protocol::take_frame(\$buffer, $secret);

The non-blocking reader used by the backend's select loop.  You append bytes to
C<$buffer> as they arrive and call this each time.  It looks at the start of
the buffer:

=over 4

=item C<(1, $message, undef)>

A whole frame was there.  It has been cut out of the buffer, so call again in
case another one follows.

=item C<(0, undef, undef)>

Not enough bytes yet.  The buffer is not changed.

=item C<(-1, undef, $error)>

The stream cannot be used: the frame is too large, the digest is wrong, or the
data is not a valid image.  A frame that fails its digest is discarded without
being thawed.  Close the connection.

=back

A third argument, C<$check>, may be a code reference.  It is called with the
serialised message, after the digest has been checked and before the message is
thawed; if it returns false the frame is refused with C<cannot deserialise
message: reading it would crash the process>.

B<Side effects:> removes the bytes of one complete frame from C<$buffer>.

=head3 API SPECIFICATION

=head4 Input

    {
        buffer => { type => 'scalarref', position => 0, optional => 0 },
        secret => { type => 'string',    position => 1, optional => 1 },
    }

=head4 Domains

    valid    a buffer reference holding 0 or more bytes, and a length field of
             0 to MAX_FRAME (plus 32 when a secret is given)
    invalid  a length field above that limit, a payload shorter than the 32
             byte digest, a digest that does not verify, and a body that is
             not a Storable image

    partition                 representative      result
    ----------------------------------------------------------
    buffer of 0 to 3 bytes    any               (0, need more bytes)
    header at the limit       no body yet       (0, need more bytes)
    header at the limit + 1   any               (-1, exceeds the limit)
    payload under 32 bytes    with a secret     (-1, too short to authenticate)
    wrong digest              with a secret     (-1, failed authentication)
    a whole valid frame       encode_frame      (1, message, undef)

    The status values are 1, 0 and -1 only.  A partial buffer is never
    changed; a complete frame is cut out of the buffer before it is decoded,
    so a frame that fails authentication is discarded rather than left to be
    tried again.

=head4 Output

    {
        type   => 'arrayref',
        min    => 3,
        max    => 3,
        schema => [
            { type => 'integer', memberof => [-1, 0, 1], description => 'status' },
            { type => 'hashref', optional => 1, description => 'the message, when status is 1' },
            { type => 'string',  optional => 1, description => 'the error, when status is -1' },
        ],
    }

=head1 PACKAGE VARIABLES

=over 4

=item C<$Class::Shared::Protocol::MAX_FRAME>

The largest body that will be sent or accepted: 64 MiB (67,108,864 bytes).  A
frame with a digest may be 32 bytes longer.

=item C<$Class::Shared::Protocol::DIGEST_SIZE>

The size of the digest: 32 bytes.

=back

=head1 ENCODING

=over 4

=item The message: any Perl data, including full Unicode.

Storable keeps strings exactly as they are.  Accented letters, any alphabet and
emoji pass through unchanged, and so does the difference between a byte string
and a character string.  Hash keys keep their characters too.  Decode your
input before you send it and encode it when you print it.

=item The frame itself: bytes.

The length, the digest and the Storable image are binary.  Use a handle without
an encoding layer (the default for a socket).  An C<:encoding(UTF-8)> layer on
the socket would corrupt the frame.

=item The secret: ASCII only.

The digest is calculated by L<Digest::SHA>, which works on bytes.  A secret with
a character above code point 255 makes the calculation die with "Wide
character".  A secret with characters from 128 to 255 gives a different digest
as bytes (for example read from a file) than as characters (for example typed in
your program), so the two ends will not agree.  Use ASCII.

=back

=head1 COMMON PITFALLS

=over 4

=item Call the functions in list context.

On failure they return a pair, and in scalar context Perl gives you only the
last value of that pair: the error text.  That is a true value.  So
C<my $bytes = encode_frame($message)> followed by C<if ($bytes)> treats a failure
as success.  Write C<my ($bytes, $error) = ...> and test that C<$bytes> is
defined.

=item An undef secret means "no authentication".

If your secret variable is accidentally undef, frames are sent and accepted
without a digest and without any warning from this module.  The backend refuses
this on TCP, but check your own code.

=item Both ends must agree about the secret.

If one side uses a secret and the other does not, every frame fails with "frame
failed authentication" or "cannot deserialise message".

=item C<take_payload> trusts its input.

It does not check a digest.  Thawing data from a stranger can run code.  Use it
only on bytes you have already authenticated.

=item C<read_frame> has no total time limit.

The timeout restarts for each wait.  If you need a hard limit, wrap the call in
your own alarm.

=item A failed C<read_frame> leaves the handle in an unknown place.

Close the handle; do not try to read the next frame from it.

=item Do not send a code reference, a file handle or a tied object.

Storable cannot store them, and C<encode_frame> returns an error.

=back

=head1 NOTES

L<Storable::thaw> trusts its input: it instantiates classes and runs their
C<STORABLE_thaw> hooks, which is remote code execution for anyone who can
write to the socket.  Pass a secret and the digest is checked first.  A backend
with no secret -- the default for a unix socket -- still trusts whatever it is
sent, which is why the unix socket is mode 0600 in a directory only its owner
can write to; a TCP listener always has one.

=head1 SEE ALSO

L<Class::Shared>, L<Class::Shared::Frontend>, L<Class::Shared::Backend>.

=head1 AUTHOR

Nigel Horne

=head1 FORMAL SPECIFICATION

This section describes what each function does in the Z notation, a way of
writing exactly what a program promises using sets and logic.  You do not need
it to use the module.  Read the plain text above first.

Z uses mathematical symbols, so this is the only part of the file that is not
plain ASCII.  A short key:

    x? input      x! output      x' the value of x after the operation
    =>  implies   /\  and        \/  or        ~  not
    seq  a sequence (an ordered list)      #  the length of a sequence

=head2 Basic types

    BYTE     == 0 .. 255
    BYTES    == seq BYTE
    MSG      == the data Storable can freeze (hash references and what they hold)
    SECRET   == BYTES ∪ {⊥}                  ⊥ means "no secret"
    MAXFRAME == 67108864        DIGEST == 32
    be32 : ℕ → BYTES             the four byte big-endian form of a number
    freeze : MSG ⇸ BYTES         thaw = freeze⁻¹ (defined only for valid images)
    hmac : SECRET × BYTES → BYTES    always 32 bytes long
    PAIR[A, B] == A × B

=head2 encode_frame

    ┌─ EncodeFrame ───────────────────────────────────────────
    │ m? : MSG ; k? : SECRET ; out! : BYTES ∪ {⊥} × STRING⊥
    ├─────────────────────────────────────────────────────────
    │ m? ∉ dom freeze ∨ #freeze(m?) > MAXFRAME
    │     ⇒ out! = (⊥, e)  for some error text e
    │ k? = ⊥ ∧ m? ∈ dom freeze ∧ #freeze(m?) ≤ MAXFRAME
    │     ⇒ out! = (be32(#freeze(m?)) ⌢ freeze(m?), ⊥)
    │ k? ≠ ⊥ ∧ m? ∈ dom freeze ∧ #freeze(m?) ≤ MAXFRAME
    │     ⇒ out! = (be32(32 + #freeze(m?)) ⌢ hmac(k?, freeze(m?)) ⌢ freeze(m?), ⊥)
    └─────────────────────────────────────────────────────────

=head2 take_payload

    ┌─ TakePayload ───────────────────────────────────────────
    │ body? : BYTES ; out! : MSG⊥ × STRING⊥
    ├─────────────────────────────────────────────────────────
    │ body? ∈ ran freeze ⇒ out! = (thaw(body?), ⊥)
    │ body? ∉ ran freeze ⇒ out! = (⊥, e)
    └─────────────────────────────────────────────────────────

=head2 write_all

    ┌─ WriteAll ──────────────────────────────────────────────
    │ fh? : HANDLE ; bytes? : BYTES ; sent, sent' : BYTES ; out! : 𝔹 × STRING⊥
    ├─────────────────────────────────────────────────────────
    │ every write succeeds ⇒ sent' = sent ⌢ bytes? ∧ out! = (true, ⊥)
    │ a write fails or returns 0 ⇒ ∃ p : BYTES • p prefix_of bytes? ∧ sent' = sent ⌢ p
    │                              ∧ out! = (false, e)
    │ SIGPIPE is ignored for the duration, and restored afterwards
    └─────────────────────────────────────────────────────────

=head2 read_frame

    ┌─ ReadFrame ─────────────────────────────────────────────
    │ stream, stream' : BYTES ; k? : SECRET ; t? : ℝ⊥ ; out! : MSG⊥ × STRING⊥
    ├─────────────────────────────────────────────────────────
    │ let n = from_be32(head 4 stream), room = MAXFRAME + (32 if k? ≠ ⊥ else 0)
    │ n ≤ room ∧ #stream ≥ 4 + n ∧ digest_ok(k?, body)
    │     ⇒ out! = (thaw(body), ⊥) ∧ stream' = drop (4 + n) stream
    │ n > room                       ⇒ out! = (⊥, "frame exceeds the limit")
    │ k? ≠ ⊥ ∧ ¬ digest_ok(k?, body) ⇒ out! = (⊥, "frame failed authentication")
    │ end of stream before 4 + n bytes ⇒ out! = (⊥, "connection closed by peer")
    │ no data within t? seconds        ⇒ out! = (⊥, "timed out waiting for a reply")
    │ Windows ∧ t? ≠ ⊥ ∧ the handle is neither a socket nor a plain file
    │                                  ⇒ out! = (⊥, "cannot apply a timeout")
    │ digest_ok is checked BEFORE thaw is applied
    └─────────────────────────────────────────────────────────

=head2 take_frame

    ┌─ TakeFrame ─────────────────────────────────────────────
    │ buf, buf' : BYTES ; k? : SECRET ; out! : {-1,0,1} × MSG⊥ × STRING⊥
    ├─────────────────────────────────────────────────────────
    │ #buf < 4                          ⇒ out! = (0, ⊥, ⊥)  ∧ buf' = buf
    │ n > room                          ⇒ out! = (-1, ⊥, e) ∧ buf' = buf
    │ #buf < 4 + n                      ⇒ out! = (0, ⊥, ⊥)  ∧ buf' = buf
    │ #buf ≥ 4 + n ∧ valid(frame)       ⇒ out! = (1, thaw(body), ⊥) ∧ buf' = drop (4 + n) buf
    │ #buf ≥ 4 + n ∧ ¬ valid(frame)     ⇒ out! = (-1, ⊥, e)         ∧ buf' = drop (4 + n) buf
    └─────────────────────────────────────────────────────────

=head1 STATE DIAGRAM

C<take_frame> works on a buffer that fills up a little at a time.  The buffer is
the only state in this module.

                        bytes arrive (you append to the buffer)
                     +--------------------------------------------+
                     |                                            |
                     v                                            |
    +----------+   < 4 bytes   +-----------+   length known,   +--------------+
    |  EMPTY   | ------------> |  HEADER   | ----------------> |   PARTIAL    |
    |  (0 B)   |   returns 0   | (1-3 B)   |   body not all    | (waiting for |
    +----------+               +-----------+   here, returns 0 |  the body)   |
        ^                                                       +--------------+
        |                                                              |
        |  whole frame present and valid                               | the last byte of
        |  returns (1, $message, undef)                                | the body arrives
        |  frame is removed from the buffer                            v
        |                                                      +----------------+
        +------------------------------------------------------|   COMPLETE     |
                                                               +----------------+
                                                                  |
                         length too large, bad digest, or         |
                         not a valid image: returns -1            v
                                                         +----------------+
                                                         |   CORRUPT      |
                                                         | (close the     |
                                                         |  connection)   |
                                                         +----------------+

=over 4

=item EMPTY to HEADER

Trigger: one to three bytes arrive.  Action: C<take_frame> returns C<(0, undef,
undef)> and leaves the buffer alone.

=item HEADER to PARTIAL

Trigger: four bytes have arrived, so the length is known, but the body is not
all there.  Action: C<take_frame> returns C<(0, undef, undef)>.  If the length is
larger than the limit it returns C<(-1, undef, $error)> at once, without waiting
for the body.

=item PARTIAL to COMPLETE

Trigger: the rest of the body arrives.  Action: the digest is checked (if there
is a secret), then the body is thawed.

=item COMPLETE to EMPTY

Trigger: the frame is valid.  Action: return C<(1, $message, undef)>.  The frame
is removed from the buffer; any bytes after it stay, and may already be the
start of the next frame (so the state may be HEADER or PARTIAL instead).

=item COMPLETE to CORRUPT

Trigger: the digest is wrong, or the body is not a valid image.  Action: return
C<(-1, undef, $error)>.  The frame is removed from the buffer without being
thawed (if the digest was wrong).  Because the frame has been consumed, any
bytes after it are still buffered and another call would parse them; close the
connection instead of calling again.

=back

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2, as published by the
Free Software Foundation.

This module is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the F<LICENSE> file for the full text.

=cut
