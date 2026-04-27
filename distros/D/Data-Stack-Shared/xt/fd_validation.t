use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Stack::Shared;

# /dev/null rejection
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::Stack::Shared::Int->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# Corrupt offsets
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    my $bad = ~0;
    print $fh pack('V V V V Q< Q< Q< Q<',
        0x53544B32, 2, 8, 0, 16, 1024, $bad, $bad);
    print $fh "\0" x (1024 - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die "open: $!";
    my $r = eval { Data::Stack::Shared::Int->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'corrupted offsets rejected';
    like $@, qr/invalid/i, 'meaningful error';
    close $rfh;
}

# Valid roundtrip
{
    my $s = Data::Stack::Shared::Int->new_memfd("t", 16);
    my $s2 = Data::Stack::Shared::Int->new_from_fd($s->memfd);
    $s->push(77);
    is $s2->pop, 77, 'valid stack accepted';
}

done_testing;
