#!/usr/bin/env perl
# Zero-copy PDL interop via shared buffer
#
# PDL can create ndarrays from raw memory pointers or packed strings.
# Data::Buffer::Shared provides both: ptr() for C-level and
# as_scalar() for Perl-level zero-copy access.
#
# Requires: PDL
use strict;
use warnings;

use Data::Buffer::Shared::F64;
use Data::Buffer::Shared::I32;

# --- Method 1: as_scalar → PDL from packed bytes ---
{
    my $buf = Data::Buffer::Shared::F64->new_anon(100);
    # fill with a sine wave
    for my $i (0..99) {
        $buf->set($i, sin($i * 0.1));
    }

    my $ref = $buf->as_scalar;
    printf "shared buffer: %d doubles, %d bytes\n", $buf->capacity, length($$ref);

    # --- With PDL ---
    # use PDL;
    # use PDL::IO::Misc;
    #
    # # Create PDL from packed binary (copies data)
    # my $pdl = PDL->new_from_specification(double, 100);
    # ${$pdl->get_dataref} = $$ref;
    # $pdl->upd_data;
    #
    # print "mean: ", $pdl->avg, "\n";
    # print "min:  ", $pdl->min, "\n";
    # print "max:  ", $pdl->max, "\n";

    # verify data
    my @vals = unpack("d<100", $$ref);
    printf "first 5 values: %s\n", join(', ', map { sprintf("%.4f", $_) } @vals[0..4]);
}

# --- Method 2: get_raw/set_raw for bulk transfer ---
{
    my $buf = Data::Buffer::Shared::I32->new_anon(256);

    # fill with incrementing values
    my $packed = pack("l<256", 0..255);
    $buf->set_raw(0, $packed);

    # read back as packed binary (single memcpy, seqlock-guarded)
    my $raw = $buf->get_raw(0, 1024);  # 256 * 4 bytes

    # --- With PDL ---
    # my $pdl = PDL->new_from_specification(long, 256);
    # ${$pdl->get_dataref} = $raw;
    # $pdl->upd_data;
    # print "sum 0..255: ", $pdl->sum, "\n";  # 32640

    my @vals = unpack("l<256", $raw);
    printf "sum 0..255: %d (expected 32640)\n", eval { my $s=0; $s+=$_ for @vals; $s };
}

# --- Method 3: ptr() for XS-level zero-copy ---
{
    my $buf = Data::Buffer::Shared::F64->new_anon(10);
    $buf->fill(3.14);

    my $ptr = $buf->ptr;
    my $ptr5 = $buf->ptr_at(5);
    printf "\nptr()    = 0x%x\n", $ptr;
    printf "ptr_at(5)= 0x%x (offset: %d bytes)\n", $ptr5, $ptr5 - $ptr;

    # In XS code:
    #   double *data = INT2PTR(double*, SvUV(ptr_sv));
    #   // data[0..9] are the shared doubles — zero-copy, no locking overhead
    #   // for single reads. Use lock_rd/lock_wr for batch consistency.
}

# --- Pattern: PDL compute process + GL render process ---
#
# Process A (PDL compute):
#   use PDL;
#   my $buf = Data::Buffer::Shared::F32->new('/tmp/particles.shm', 30000);
#   $buf->create_eventfd;
#   while (1) {
#       my $ref = $buf->as_scalar;
#       my $pos = PDL->new_from_specification(float, 3, 10000);
#       ${$pos->get_dataref} = $$ref;  # read current state
#       $pos->upd_data;
#       $pos += $velocity * $dt;       # physics step
#       $buf->set_raw(0, ${$pos->get_dataref});  # write back
#       $buf->notify;
#   }
#
# Process B (OpenGL render):
#   my $buf = Data::Buffer::Shared::F32->new('/tmp/particles.shm', 30000);
#   my $ref = $buf->as_scalar;
#   while (1) {
#       if (defined $buf->wait_notify) {
#           glBufferSubData(GL_ARRAY_BUFFER, 0, length($$ref), $$ref);
#       }
#       render();
#   }

print "\ndone.\n";
