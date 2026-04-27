use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::HashMap::Shared::II;

my $SHM_MAGIC   = 0x53484D31;   # SHM1
my $SHM_VERSION = 7;
my $SHM_VAR_II  = 3;            # shm_ii.h SHM_VARIANT_ID

# 1. /dev/null rejection
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::HashMap::Shared::II->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# 2. Valid magic but bogus nodes_off/states_off
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    my $size = 8192;
    # ShmHeader cache line 0 (first 64 bytes):
    # magic(u32) version(u32) variant_id(u32) node_size(u32)
    # max_table_cap(u32) table_cap(u32) max_size(u32) default_ttl(u32)
    # total_size(u64) nodes_off(u64) states_off(u64) arena_off(u64)
    my $bad = ~0;
    print $fh pack('V V V V V V V V Q< Q< Q< Q<',
        $SHM_MAGIC, $SHM_VERSION, $SHM_VAR_II, 24,
        64, 64, 0, 0,
        $size, $bad, $bad, $bad);
    print $fh "\0" x ($size - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die "open: $!";
    my $r = eval { Data::HashMap::Shared::II->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'corrupted offsets rejected';
    close $rfh;
}

# 3. Roundtrip
{
    my $m = Data::HashMap::Shared::II->new_memfd("t", 64);
    my $m2 = Data::HashMap::Shared::II->new_from_fd($m->memfd);
    $m->put(1, 100);
    is $m2->get(1), 100, 'genuine valid hashmap still accepted';
}

done_testing;
