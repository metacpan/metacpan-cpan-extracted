#!/usr/bin/env perl
# Pool + Buffer bridge: Pool manages typed records, Buffer stores bulk arrays
#
# Pattern: Pool allocates fixed-size "descriptor" records containing metadata
# and an offset into a shared Buffer for variable-length payload.
# Workers alloc a descriptor from Pool, write payload to Buffer at the offset,
# readers look up the descriptor and read the payload.
#
# Use case: message broker, packet processing, mixed fixed+variable data
#
# Requires: Data::Buffer::Shared (sibling)

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use lib "$FindBin::Bin/../../Data-Buffer-Shared/blib/lib",
        "$FindBin::Bin/../../Data-Buffer-Shared/blib/arch";

use POSIX qw(_exit);
use Time::HiRes qw(time);
$| = 1;

eval { require Data::Pool::Shared;    1 } or die "Data::Pool::Shared required\n";
eval { require Data::Buffer::Shared;  1 } or die "Data::Buffer::Shared required (sibling module)\n";

# Descriptor record layout (I64 pool, 8 bytes per slot):
# We store a packed i32 offset + i16 length + i16 flags in one I64
#   bits  0-31: buffer offset (byte position in payload buffer)
#   bits 32-47: payload length
#   bits 48-63: flags (e.g., message type)

sub pack_descriptor { my ($off, $len, $flags) = @_; $off | ($len << 32) | ($flags << 48) }
sub unpack_descriptor { my $v = shift; ($v & 0xFFFFFFFF, ($v >> 32) & 0xFFFF, ($v >> 48) & 0xFFFF) }

my $N = shift || 50;

# Pool: message descriptors
my $descs = Data::Pool::Shared::I64->new(undef, $N + 8);

# Buffer: payload storage (U8, one byte per element, acts as byte array)
my $payload_size = $N * 128;  # 128 bytes avg per message
my $payload = Data::Buffer::Shared::U8->new_anon($payload_size);

# Shared write cursor (use pool slot 0 as atomic counter for buffer offset)
my $cursor_slot = $descs->alloc;
$descs->set($cursor_slot, 0);

printf "bridge: %d descriptor slots, %d byte payload buffer\n",
    $descs->capacity, $payload_size;

# --- Producer: create messages ---
my @msg_slots;
for my $i (1 .. $N) {
    my $msg = sprintf "message-%04d: %s", $i, "data" x (4 + int(rand(12)));
    my $len = length $msg;

    # atomically reserve space in payload buffer
    my $offset = $descs->add($cursor_slot, $len) - $len;  # add returns new value

    # write payload to buffer
    for my $j (0 .. $len - 1) {
        $payload->set($offset + $j, ord(substr($msg, $j, 1)));
    }

    # create descriptor
    my $slot = $descs->alloc;
    $descs->set($slot, pack_descriptor($offset, $len, $i & 0xFFFF));
    push @msg_slots, $slot;
}

printf "produced %d messages, cursor at %d bytes\n",
    scalar @msg_slots, $descs->get($cursor_slot);

# --- Consumer (child process): read messages via descriptors ---
my $pid = fork // die "fork: $!";
if ($pid == 0) {
    my $count = 0;
    for my $slot (@msg_slots) {
        my ($offset, $len, $flags) = unpack_descriptor($descs->get($slot));

        # read payload from buffer
        my $msg = '';
        for my $j (0 .. $len - 1) {
            $msg .= chr($payload->get($offset + $j));
        }
        $count++;
        printf "  [%04d] off=%d len=%d: %.40s%s\n",
            $flags, $offset, $len, $msg, length($msg) > 40 ? "..." : ""
            if $count <= 5 || $count == $N;
        printf "  ... (%d more) ...\n", $N - 6 if $count == 6 && $N > 6;
    }
    printf "child consumed %d messages\n", $count;
    _exit(0);
}
waitpid($pid, 0);

# cleanup
$descs->free($_) for @msg_slots;
$descs->free($cursor_slot);
printf "cleanup: pool used=%d\n", $descs->used;
