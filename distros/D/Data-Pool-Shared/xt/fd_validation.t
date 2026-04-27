use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Pool::Shared;

my $POOL_MAGIC   = 0x504F4C31;   # POL1
my $POOL_VERSION = 1;
my $POOL_VAR_I64 = 1;

# PoolHeader layout: magic(u32) version(u32) elem_size(u32) variant_id(u32)
# capacity(u64) total_size(u64) bitmap_off(u64) owners_off(u64) data_off(u64)
my $HDR_PACK = 'V V V V Q< Q< Q< Q< Q<';

# 1. /dev/null — zero-size → "too small"
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::Pool::Shared::I64->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# 2. Correct magic/version/variant but bogus offsets
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    my $size = 4096;
    my $bad  = ~0;
    print $fh pack($HDR_PACK,
        $POOL_MAGIC, $POOL_VERSION, 8, $POOL_VAR_I64,
        4, $size, $bad, $bad, $bad);
    print $fh "\0" x ($size - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die "open: $!";
    my $r = eval { Data::Pool::Shared::I64->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'corrupted offsets rejected';
    like $@, qr/invalid/i, 'meaningful error for corrupt layout';
    close $rfh;
}

# 3. elem_size = 0 — would divide by zero in pool_calc_layout
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    my $size = 4096;
    print $fh pack($HDR_PACK,
        $POOL_MAGIC, $POOL_VERSION, 0, $POOL_VAR_I64,
        4, $size, 40, 72, 96);
    print $fh "\0" x ($size - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die "open: $!";
    my $r = eval { Data::Pool::Shared::I64->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'elem_size=0 rejected';
    close $rfh;
}

# 4. Genuine roundtrip
{
    my $p = Data::Pool::Shared::I64->new_memfd("t", 4);
    my $p2 = Data::Pool::Shared::I64->new_from_fd($p->memfd);
    my $s = $p2->alloc;
    $p->set($s, 1234);
    is $p2->get($s), 1234, 'genuine valid pool still accepted';
}

done_testing;
