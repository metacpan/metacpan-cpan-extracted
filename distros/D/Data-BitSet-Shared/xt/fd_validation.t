use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::BitSet::Shared;

my $MAGIC = 0x42535431;    # BST1

# /dev/null rejection
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::BitSet::Shared->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# Corrupted offsets
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.bs');
    my $size = 1024;
    my $bad = ~0;
    # magic(u32) version(u32) capacity(u64) total_size(u64) data_off(u64) num_words(u32) _pad(28)
    print $fh pack('V V Q< Q< Q< V',
        $MAGIC, 1, 128, $size, $bad, 2);
    print $fh "\0" x ($size - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die;
    my $r = eval { Data::BitSet::Shared->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'bad data_off rejected';
    close $rfh;
}

# Valid roundtrip
{
    my $b = Data::BitSet::Shared->new_memfd("v", 64);
    my $b2 = Data::BitSet::Shared->new_from_fd($b->memfd);
    $b->set(7);
    ok $b2->test(7), 'genuine valid bitset accepted';
}

done_testing;
