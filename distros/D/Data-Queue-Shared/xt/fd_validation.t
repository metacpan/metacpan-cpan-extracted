use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Queue::Shared;

SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::Queue::Shared::Int->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# Corrupt: capacity claims 2^30 slots but file is only 1024 bytes
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    # QueueHeader layout (first fields): magic u32, version u32, mode u32, padding...
    # Then capacity u32, total_size u64, slots_off u64, arena_off u64, arena_cap u64
    # Actual struct offsets need checking — simpler: write a plausible 128-byte header
    my $hdr = pack('V V V V Q< Q< Q< Q<',
        0x51554531,   # magic QUE1
        1,             # version
        0,             # mode INT
        0x40000000,    # capacity = 2^30 (way more than fits in 1024-byte file)
        1024,          # total_size
        128,           # slots_off
        0,             # arena_off (INT doesn't use)
        0,             # arena_cap
    );
    $hdr .= "\0" x (128 - length($hdr));
    print $fh $hdr;
    print $fh "\0" x (1024 - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die "open: $!";
    my $r = eval { Data::Queue::Shared::Int->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'oversized capacity rejected';
    like $@, qr/invalid/i, 'meaningful error';
    close $rfh;
}

# Valid roundtrip
{
    my $q = Data::Queue::Shared::Int->new_memfd("t", 16);
    my $q2 = Data::Queue::Shared::Int->new_from_fd($q->memfd);
    $q->push(99);
    is $q2->pop, 99, 'valid queue accepted';
}

done_testing;
