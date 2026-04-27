use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::ReqRep::Shared;

my $MAGIC   = 0x52525331;   # RRS1
my $VERSION = 1;
my $MODE_STR = 0;

# Pack the first 64 bytes of ReqRepHeader (cache line 0, immutable fields):
# magic(u32) version(u32) mode(u32) req_cap(u32)
# total_size(u64)
# req_slots_off(u32) req_arena_off(u32) req_arena_cap(u32)
# resp_slots(u32) resp_data_max(u32) resp_off(u32) resp_stride(u32)
# + 12 bytes padding.
my $HDR0_PACK = 'V V V V Q< V V V V V V V x[12]';

# 1. /dev/null rejection
SKIP: {
    open(my $fh, '<', '/dev/null') or skip "no /dev/null", 1;
    my $r = eval { Data::ReqRep::Shared->new_from_fd(fileno($fh)) };
    ok !defined($r), '/dev/null rejected';
    like $@, qr/(too small|invalid|fstat)/i, 'meaningful error';
}

# 2. resp_off inside arena (Pass 6 v0.04 regression) — crafted so
#    resp_slots_end/arena/resp_off all fit within total_size, but
#    resp_off < req_arena_off + req_arena_cap (i.e. overlaps arena).
{
    my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
    my $size = 8192;
    my $req_cap = 4;
    my $req_slots_off = 256;                       # after header
    my $req_arena_off = 512;                       # after slots (req_cap*sizeof(ReqSlot))
    my $req_arena_cap = 4096;                      # arena = [512, 4608)
    my $resp_off      = 1024;                      # INSIDE arena - bug
    my $resp_stride   = 256;
    my $resp_slots    = 4;
    my $resp_data_max = 128;
    print $fh pack($HDR0_PACK,
        $MAGIC, $VERSION, $MODE_STR, $req_cap,
        $size,
        $req_slots_off, $req_arena_off, $req_arena_cap,
        $resp_slots, $resp_data_max, $resp_off, $resp_stride);
    print $fh "\0" x ($size - tell($fh));
    close $fh;
    open(my $rfh, '+<', $path) or die "open: $!";
    my $r = eval { Data::ReqRep::Shared->new_from_fd(fileno($rfh)) };
    ok !defined($r), 'resp_off inside arena rejected (v0.04 regression)';
    close $rfh;
}

# 3. Valid roundtrip
{
    my $s = Data::ReqRep::Shared->new_memfd("t", 8, 4, 128);
    my $s2 = Data::ReqRep::Shared->new_from_fd($s->memfd);
    ok $s2, 'valid reqrep accepted';
}

done_testing;
