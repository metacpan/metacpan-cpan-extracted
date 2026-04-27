use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Deque::Shared;

# Feed new_from_fd various malformed fds; verify clean rejection.

# 1. /dev/null — zero-size → "too small"
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::Deque::Shared::Int->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# 2. File with correct magic but corrupted offsets
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    my $bad = ~0;  # all-ones 64-bit
    print $fh pack('V V V V Q< Q< Q< Q<',
        0x44455132, 2, 8, 0, 16, 1024, $bad, $bad);
    print $fh "\0" x (1024 - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die "open: $!";
    my $r = eval { Data::Deque::Shared::Int->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'corrupted offsets rejected';
    like $@, qr/invalid/i, 'meaningful error for corrupt layout';
    close $rfh;
}

# 3. Genuine valid deque → roundtrip still works
{
    my $d = Data::Deque::Shared::Int->new_memfd("t", 16);
    my $d2 = Data::Deque::Shared::Int->new_from_fd($d->memfd);
    $d->push_back(42);
    is $d2->pop_front, 42, 'genuine valid deque still accepted';
}

done_testing;
