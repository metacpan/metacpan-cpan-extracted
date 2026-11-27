use strict;
use warnings;

use File::Temp ();
use Test::More;
use File::Spec ();
# The unix socket constants are asked for at run time, not imported: a perl
# whose Socket has none of them should skip the socket pair tests, not fail to
# compile.
use Socket ();
use lib 't/lib';

use Class::Shared::Protocol;

# A connected pair of unix sockets, or an empty list where the platform cannot
# make one.
sub unix_socket_pair {
	my $af_unix = eval { Socket::AF_UNIX() };
	return unless defined $af_unix;

	return unless socketpair(my $reader, my $writer, $af_unix, Socket::SOCK_STREAM(), 0);

	return ($writer, $reader);
}

my $message = {
	op     => 'call',
	method => 'do_something',
	args   => [1, [2, 3], { four => 5 }, undef, 'six'],
	want   => 'list',
};

my ($bytes, $encode_error) = Class::Shared::Protocol::encode_frame($message);
ok(defined $bytes, 'a message encodes');
is($encode_error, undef, 'no encoding error');

is(length($bytes), 4 + length($bytes) - 4, 'frame carries a header');
is(unpack('N', substr($bytes, 0, 4)), length($bytes) - 4, 'the header is the body length');

my ($decoded, $decode_error) = Class::Shared::Protocol::take_payload(substr($bytes, 4));
is($decode_error, undef, 'the body decodes');
is_deeply($decoded, $message, 'the message survives a round trip');

# Incremental parsing.
{
	my $buffer = $bytes;
	my @first = Class::Shared::Protocol::take_frame(\$buffer);
	is($first[0], 1, 'a whole frame in the buffer is taken');
	is_deeply($first[1], $message, 'and it is the right message');
	is($buffer, '', 'the buffer is empty afterwards');

	$buffer = substr($bytes, 0, 2);
	my @partial = Class::Shared::Protocol::take_frame(\$buffer);
	is($partial[0], 0, 'a partial header asks for more bytes');
	is($buffer, substr($bytes, 0, 2), 'and the partial header is kept');

	$buffer = substr($bytes, 0, 6);
	@partial = Class::Shared::Protocol::take_frame(\$buffer);
	is($partial[0], 0, 'a partial body asks for more bytes');
}

# Oversized frames are refused before anything is allocated.
{
	my $buffer = pack('N', $Class::Shared::Protocol::MAX_FRAME + 1) . 'x' x 8;
	my @huge = Class::Shared::Protocol::take_frame(\$buffer);
	is($huge[0], -1, 'an oversized frame is refused');
	like($huge[2], qr/exceeds the limit/, 'with an explanation');

	SKIP: {
		my $empty;

		skip "cannot open the null device: $!", 1
			unless open($empty, '<', File::Spec->devnull);

		my (undef, $error) = Class::Shared::Protocol::read_frame($empty);
		like($error, qr/closed/, 'read_frame reports a stream with nothing to read');
	}
}

# Real socket pair, where the platform can make one.  Windows cannot make an
# AF_UNIX pair, and this has to skip in place: a skip_all after tests have
# already run is a plan for zero tests, which TAP reads as a failure.
SKIP: {
	my ($writer, $reader) = unix_socket_pair();

	skip 'this platform cannot make an AF_UNIX socket pair', 3 unless $writer;

	my ($written, $write_error) = Class::Shared::Protocol::write_all($writer, $bytes);
	ok($written, 'write_all writes the frame') or diag $write_error;

	my ($got, $read_error) = Class::Shared::Protocol::read_frame($reader);
	is($read_error, undef, 'read_frame reads it back');
	is_deeply($got, $message, 'over a real socket');
}

# A reply that cannot be serialised is reported, not fatal.
{
	my ($frame, $error) = Class::Shared::Protocol::encode_frame({ code => sub { 1 } });
	is($frame, undef, 'a code reference cannot be sent');
	like($error, qr/cannot serialise/, 'and the caller is told why');
}

# Authenticated frames: an HMAC goes over the raw body and is checked before
# Storable is allowed to look at that body.
{
	package Shared::Trap;

	our $THAWED = 0;

	# A body that does something when it is thawed.  Nothing here is an
	# exploit by itself; it is the hook that a crafted Storable image would
	# use, and it stands in for arbitrary code chosen by a remote peer.
	sub STORABLE_freeze { return '' }
	sub STORABLE_thaw   { $THAWED++; return bless {}, 'Shared::Trap' }

	package main;

	my $secret = 'a-shared-secret';

	my ($signed, $sign_error) = Class::Shared::Protocol::encode_frame($message, $secret);
	ok(defined $signed, 'a message signs') or diag $sign_error;
	is(unpack('N', substr($signed, 0, 4)), length($signed) - 4,
		'the header counts the digest and the body');

	my $buffer = $signed;
	my @taken = Class::Shared::Protocol::take_frame(\$buffer, $secret);
	is($taken[0], 1, 'a signed frame is taken');
	is_deeply($taken[1], $message, 'and decodes to the message that was signed');
	is($buffer, '', 'leaving nothing in the buffer');

	my ($trap_frame) = Class::Shared::Protocol::encode_frame(
		{ op => 'call', object => bless({}, 'Shared::Trap') },
		$secret,
	);
	ok(defined $trap_frame, 'a body with a thaw hook can be framed');

	$buffer = $trap_frame;
	@taken = Class::Shared::Protocol::take_frame(\$buffer, $secret);
	is($taken[0], 1, 'a correctly signed frame is taken');
	is($Shared::Trap::THAWED, 1, 'and only then is its thaw hook run');

	my $thawed = $Shared::Trap::THAWED;

	# One bit of the digest, body untouched: only the digest can reject this.
	my $broken_digest = $trap_frame;
	substr($broken_digest, 4, 1) = chr(ord(substr($broken_digest, 4, 1)) ^ 0x80);
	$buffer = $broken_digest;
	@taken = Class::Shared::Protocol::take_frame(\$buffer, $secret);
	is($taken[0], -1, 'a frame with a bad digest is refused');
	like($taken[2], qr/failed authentication/, 'as an authentication failure');
	is($Shared::Trap::THAWED, $thawed, 'and its body was never deserialised');

	# One bit of the body, digest untouched.
	my $broken_body = $trap_frame;
	my $last = length($broken_body) - 1;
	substr($broken_body, $last, 1) = chr(ord(substr($broken_body, $last, 1)) ^ 0x01);
	$buffer = $broken_body;
	@taken = Class::Shared::Protocol::take_frame(\$buffer, $secret);
	is($taken[0], -1, 'a frame whose body was altered is refused');
	is($Shared::Trap::THAWED, $thawed, 'and that body was not deserialised either');

	$buffer = $trap_frame;
	@taken = Class::Shared::Protocol::take_frame(\$buffer, 'not-the-secret');
	is($taken[0], -1, 'a frame signed with another secret is refused');
	is($Shared::Trap::THAWED, $thawed, 'and not deserialised');

	$buffer = $bytes;
	@taken = Class::Shared::Protocol::take_frame(\$buffer, $secret);
	is($taken[0], -1, 'an unsigned frame is refused where one is expected');
	is($Shared::Trap::THAWED, $thawed, 'and not deserialised');

	$buffer = pack('N', 8) . 'xxxxxxxx';
	@taken = Class::Shared::Protocol::take_frame(\$buffer, $secret);
	is($taken[0], -1, 'a frame with no room for a digest is refused');
	like($taken[2], qr/too short/, 'and named as too short');

	$buffer = pack('N', $Class::Shared::Protocol::MAX_FRAME + 100) . 'x' x 8;
	@taken = Class::Shared::Protocol::take_frame(\$buffer, $secret);
	is($taken[0], -1, 'a frame larger than a digest plus the limit is refused');

	# read_frame authenticates the same way, before it thaws.
	SKIP: {
		my ($writer, $reader) = unix_socket_pair();

		skip 'this platform cannot make an AF_UNIX socket pair', 4 unless $writer;

		my ($sent) = Class::Shared::Protocol::write_all($writer, $broken_body);
		ok($sent, 'a tampered frame is written to it');

		my ($got, $read_error)
			= Class::Shared::Protocol::read_frame($reader, undef, $secret);
		is($got, undef, 'read_frame refuses a tampered frame');
		like($read_error, qr/failed authentication/, 'for the same reason');
		is($Shared::Trap::THAWED, $thawed, 'without deserialising it');
	}
}

# Windows can wait only on sockets, so a timed read of anything else must not
# claim that it timed out.  $^O is set to take that path on every platform.
{
	my ($bytes) = Class::Shared::Protocol::encode_frame({ op => 'ping' });

	my $file = File::Temp->new;
	binmode $file;
	print {$file} $bytes or die "cannot write: $!";
	close($file) or die "cannot write: $!";
	open(my $fh, '<:raw', "$file") or die "cannot read: $!";

	pipe(my $reader, my $writer) or die "cannot make a pipe: $!";
	binmode $reader;
	binmode $writer;
	Class::Shared::Protocol::write_all($writer, $bytes);

	local $^O = 'MSWin32';

	my ($message, $error) = Class::Shared::Protocol::read_frame($fh, 0);
	is_deeply($message, { op => 'ping' }, 'Windows: a timed read of a file reads it')
		or diag $error;
	close($fh);

	($message, $error) = Class::Shared::Protocol::read_frame($reader, 0);
	is($message, undef, 'Windows: a pipe cannot be given a timeout');
	like($error, qr/\Acannot apply a timeout/, 'and the reason says so');

	($message, $error) = Class::Shared::Protocol::read_frame($reader);
	is_deeply($message, { op => 'ping' }, 'Windows: without a timeout the pipe is read');
}

done_testing();
