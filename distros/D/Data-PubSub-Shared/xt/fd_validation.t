use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::PubSub::Shared;

# /dev/null rejection
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::PubSub::Shared::Int->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# Corrupt header: magic OK but oversized capacity
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    print $fh pack('V V V V Q< Q< Q< Q<',
        0x50534231, 1, 0, 0, 0x7FFFFFFF, 1024, 128, 0);
    print $fh "\0" x (1024 - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die "open: $!";
    my $r = eval { Data::PubSub::Shared::Int->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'oversized capacity rejected';
    like $@, qr/invalid/i, 'meaningful error';
    close $rfh;
}

# Stored geometry validation
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    my $ps = Data::PubSub::Shared::Str->new($path, 4, 16);
    undef $ps;
    sysseek($fh, 0, 0) // die "seek: $!";
    sysread($fh, my $header, 256) == 256 or die "read: $!";
    for my $case ([48, pack('Q', 32), 'overlapping arena regions'],
                  [40, pack('L', 0x80000000), 'unrepresentable message size'],
                  [12, pack('L', 1), 'one-slot ring']) {
        my $bad = $header;
        substr($bad, $case->[0], length($case->[1])) = $case->[1];
        sysseek($fh, 0, 0) // die "seek: $!";
        syswrite($fh, $bad) == length($bad) or die "write: $!";
        eval { Data::PubSub::Shared::Str->new_from_fd(fileno($fh)) };
        like $@, qr/invalid/, "rejects $case->[2] in stored geometry";
    }
}

# Valid roundtrip
{
    my $ps = Data::PubSub::Shared::Int->new_memfd("t", 16);
    my $ps2 = Data::PubSub::Shared::Int->new_from_fd($ps->memfd);
    my $sub = $ps2->subscribe;
    $ps->publish(99);
    my ($v) = $sub->poll_wait(2);
    is $v, 99, 'valid pubsub accepted, subscriber works';
}

done_testing;
