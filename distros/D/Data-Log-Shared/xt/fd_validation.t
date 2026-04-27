use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Log::Shared;

my $MAGIC = 0x4C4F4731;  # LOG1

SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::Log::Shared->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.log');
    my $size = 4096;
    my $bad = ~0;
    # magic(u32) version(u32) data_size(u64) total_size(u64) data_off(u64)
    print $fh pack('V V Q< Q< Q<', $MAGIC, 1, 100, $size, $bad);
    print $fh "\0" x ($size - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die;
    my $r = eval { Data::Log::Shared->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'bad data_off rejected';
    close $rfh;
}

{
    my $l = Data::Log::Shared->new_memfd("v", 1024);
    my $l2 = Data::Log::Shared->new_from_fd($l->memfd);
    $l->append("hi");
    is $l2->entry_count, 1, 'genuine valid log accepted';
}

done_testing;
