use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Heap::Shared;

my $MAGIC = 0x48455031;  # HEP1

SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::Heap::Shared->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.heap');
    my $size = 1024;
    my $bad = ~0;
    # magic(u32) version(u32) capacity(u64) total_size(u64) data_off(u64)
    print $fh pack('V V Q< Q< Q<', $MAGIC, 1, 16, $size, $bad);
    print $fh "\0" x ($size - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die;
    my $r = eval { Data::Heap::Shared->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'bad data_off rejected';
    close $rfh;
}

{
    my $h = Data::Heap::Shared->new_memfd("v", 16);
    my $h2 = Data::Heap::Shared->new_from_fd($h->memfd);
    $h->push(1, 100);
    my @r = $h2->pop;
    is $r[0], 1, 'genuine valid heap accepted';
}

done_testing;
