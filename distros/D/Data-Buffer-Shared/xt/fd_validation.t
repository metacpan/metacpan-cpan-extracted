use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Buffer::Shared::I64;

my $BUF_MAGIC   = 0x42554631;   # BUF1
my $BUF_VERSION = 1;
my $BUF_VAR_I64 = 7;            # matches buf_i64.h BUF_VARIANT_ID

# BufHeader cache-line 0 (immutable fields):
# magic(u32) version(u32) variant_id(u32) elem_size(u32)
# capacity(u64) total_size(u64) data_off(u64) _reserved0[24]
# Total header = 128 bytes.

# 1. /dev/null rejection
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::Buffer::Shared::I64->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# 2. Correct magic but wrong data_off
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    my $size = 1024;
    my $bad_data_off = 0xDEADBEEF;
    # magic version variant_id elem_size | capacity total_size data_off
    print $fh pack('V V V V Q< Q< Q<',
        $BUF_MAGIC, $BUF_VERSION, $BUF_VAR_I64, 8,
        100, $size, $bad_data_off);
    print $fh "\0" x ($size - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die "open: $!";
    my $r = eval { Data::Buffer::Shared::I64->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'bogus data_off rejected';
    close $rfh;
}

# 3. Roundtrip
{
    my $b = Data::Buffer::Shared::I64->new_memfd("t", 16);
    my $b2 = Data::Buffer::Shared::I64->new_from_fd($b->fd);
    $b->set(0, 42);
    is $b2->get(0), 42, 'genuine valid buffer still accepted';
}

done_testing;
