use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::RingBuffer::Shared;

my $MAGIC = 0x524E4731;  # RNG1

SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::RingBuffer::Shared::Int->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.ring');
    my $size = 1024;
    my $bad = ~0;
    # magic(u32) version(u32) elem_size(u32) variant_id(u32) capacity(u64) total_size(u64) data_off(u64)
    print $fh pack('V V V V Q< Q< Q<',
        $MAGIC, 1, 8, 0, 16, $size, $bad);
    print $fh "\0" x ($size - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die;
    my $r = eval { Data::RingBuffer::Shared::Int->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'bad data_off rejected';
    close $rfh;
}

{
    my $r  = Data::RingBuffer::Shared::Int->new_memfd("v", 16);
    my $r2 = Data::RingBuffer::Shared::Int->new_from_fd($r->memfd);
    $r->write(99);
    is $r2->latest, 99, 'genuine valid ring accepted';
}

done_testing;
