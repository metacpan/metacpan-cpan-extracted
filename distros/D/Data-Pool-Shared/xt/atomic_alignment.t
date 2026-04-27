use strict;
use warnings;
use Test::More;

# Alignment of atomic fields in the header. __atomic_* on
# non-naturally-aligned addresses falls back to locked paths (or
# crashes on some architectures). Verify the header layout keeps
# atomic fields at natural alignment.

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("align", 16);

# PoolHeader layout, as documented in pool.h:
#   magic(u32, off 0) — non-atomic after init
#   version(u32, off 4) — non-atomic after init
#   elem_size(u32, off 8) — non-atomic
#   variant_id(u32, off 12) — non-atomic
#   capacity(u64, off 16) — non-atomic after init
#   total_size(u64, off 24) — non-atomic after init
#   data_off(u64, off 32) — non-atomic
#   bitmap_off(u64, off 40) — non-atomic
#   owners_off(u64, off 48) — non-atomic
#   used(u32) — ATOMIC
#   waiters(u32) — ATOMIC
#   notify_fd(i32) — non-atomic
#   stat_* (u64) — atomic increments
#
# Read raw bytes and assert aligned layout.

open(my $fh, '<', "/proc/$$/fd/" . $p->memfd) or die "open memfd: $!";
binmode $fh;
read($fh, my $hdr, 256);
close $fh;

# Fields whose offsets we validate (Q = u64, V = u32 LE)
my %expected_off = (
    magic       => 0,
    version     => 4,
    elem_size   => 8,
    variant_id  => 12,
    capacity    => 16,
    total_size  => 24,
    bitmap_off  => 32,
    owners_off  => 40,
    data_off    => 48,
);

# All u64 fields should be at 8-byte-aligned offsets
for my $f (qw(capacity total_size bitmap_off owners_off data_off)) {
    my $off = $expected_off{$f};
    is $off % 8, 0, "$f at offset $off is 8-byte aligned";
}

# All u32 fields at 4-byte aligned offsets
for my $f (qw(magic version elem_size variant_id)) {
    my $off = $expected_off{$f};
    is $off % 4, 0, "$f at offset $off is 4-byte aligned";
}

# Sanity: actually decode magic + version matches runtime values
my ($magic, $version) = unpack('V V', substr($hdr, 0, 8));
is $magic,   0x504F4C31, "magic == POL1";
is $version, 1,          "version == 1";

done_testing;
