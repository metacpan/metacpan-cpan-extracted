#!/usr/bin/env perl
# PDL interop: shared pool as backing store for PDL computation
#
# Patterns demonstrated:
#   1. Pool → PDL: bulk-read via slot_sv, load into piddle via set_dataref
#   2. PDL → Pool: compute results, write back via typed set or raw bytes
#   3. Multi-dimensional: pool of F64 slots storing 2D vectors
#   4. Image processing: pool of raw slots storing pixel rows, PDL processes
#   5. Cross-process: parallel workers with PDL reduction
#
# Requires: PDL

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

eval { require PDL; PDL->import; 1 }
    or die "PDL required: install with cpanm PDL\n";

use POSIX qw(_exit);
use Data::Pool::Shared;
$| = 1;

# =====================================================================
# 1. Basic: 1D signal → PDL → normalize → pool
# =====================================================================

print "=== 1. Signal processing: pool ↔ PDL round-trip ===\n\n";

my $N = 1000;
my $sig = Data::Pool::Shared::F64->new(undef, $N);

# generate a noisy sine wave
my @slots;
for my $i (0 .. $N - 1) {
    my $s = $sig->alloc;
    $sig->set($s, sin($i * 0.02) * 50 + rand(5));
    push @slots, $s;
}

# pool → PDL (bulk read)
my $pdl = PDL->new_from_specification(PDL::double(), $N);
my $raw = '';
$raw .= $sig->slot_sv($_) for @slots;
${$pdl->get_dataref} = $raw;
$pdl->upd_data;

my @st = $pdl->stats;
printf "  raw signal: min=%.1f max=%.1f mean=%.1f rms=%.1f\n",
    $st[3], $st[4], $st[0], $st[6];

# PDL compute: normalize to 0..1
my $norm = ($pdl - $pdl->min) / ($pdl->max - $pdl->min);

# PDL → pool (write back via list)
my @vals = $norm->list;
$sig->set($slots[$_], $vals[$_]) for 0 .. $#slots;

printf "  normalized: slot[0]=%.4f slot[500]=%.4f slot[999]=%.4f\n",
    $sig->get($slots[0]), $sig->get($slots[500]), $sig->get($slots[999]);

# round-trip verify
my $verify = PDL->new_from_specification(PDL::double(), $N);
my $vraw = '';
$vraw .= $sig->slot_sv($_) for @slots;
${$verify->get_dataref} = $vraw;
$verify->upd_data;
printf "  round-trip: min=%.4f max=%.4f\n\n", $verify->min, $verify->max;

$sig->free($_) for @slots;

# =====================================================================
# 2. Multi-dimensional: pool of 3D vectors
# =====================================================================

print "=== 2. 3D point cloud: pool slots as vec3 ===\n\n";

# each slot stores 3 doubles (x,y,z) = 24 bytes
my $cloud = Data::Pool::Shared->new(undef, 500, 24);

my @pts;
for my $i (0 .. 499) {
    my $s = $cloud->alloc;
    my $theta = $i * 0.1;
    my $r = 10 + $i * 0.02;
    $cloud->set($s, pack('d<3',
        $r * cos($theta),       # x: spiral
        $r * sin($theta),       # y
        $i * 0.05,              # z: rising
    ));
    push @pts, $s;
}

# load all points into a 3×500 PDL matrix
my $points = PDL->new_from_specification(PDL::double(), 3, 500);
my $pt_raw = '';
$pt_raw .= $cloud->slot_sv($_) for @pts;
${$points->get_dataref} = $pt_raw;
$points->upd_data;

# PDL operations on the point cloud
my $centroid = $points->xchg(0,1)->avgover;  # mean of each column → (3)
printf "  centroid: (%.2f, %.2f, %.2f)\n",
    $centroid->at(0), $centroid->at(1), $centroid->at(2);

# compute distances from centroid
my $diffs = $points - $centroid->dummy(1);  # broadcast subtract
my $dists = ($diffs * $diffs)->xchg(0,1)->sumover->sqrt;  # Euclidean distance per point
printf "  distances: min=%.2f max=%.2f mean=%.2f\n",
    $dists->min, $dists->max, $dists->avg;

# translate all points: center at origin
my $centered = $points - $centroid->dummy(1);
my $c_bytes = ${$centered->get_dataref};
for my $i (0 .. $#pts) {
    my @xyz = unpack('d<3', substr($c_bytes, $i * 24, 24));
    $cloud->set($pts[$i], pack('d<3', @xyz));
}

# verify centroid is near zero
my $c2 = PDL->new_from_specification(PDL::double(), 3, 500);
my $c2_raw = '';
$c2_raw .= $cloud->slot_sv($_) for @pts;
${$c2->get_dataref} = $c2_raw;
$c2->upd_data;
my $c2_centroid = $c2->xchg(0,1)->avgover;
printf "  after centering: centroid=(%.4f, %.4f, %.4f)\n\n",
    $c2_centroid->at(0), $c2_centroid->at(1), $c2_centroid->at(2);

$cloud->free($_) for @pts;

# =====================================================================
# 3. Image row processing: pool slots as scanlines
# =====================================================================

print "=== 3. Image processing: pool slots as pixel rows ===\n\n";

my $W = 64;
my $H = 48;
# each slot: one row of RGBA pixels = W * 4 bytes
my $img = Data::Pool::Shared->new(undef, $H, $W * 4);

# generate a gradient image
my @rows;
for my $y (0 .. $H - 1) {
    my $s = $img->alloc;
    my $row = '';
    for my $x (0 .. $W - 1) {
        $row .= pack('C4',
            int(255 * $x / $W),         # R: horizontal gradient
            int(255 * $y / $H),         # G: vertical gradient
            128,                         # B: constant
            255,                         # A
        );
    }
    $img->set($s, $row);
    push @rows, $s;
}

# load entire image into PDL: byte piddle (4, W, H)
my $img_pdl = PDL->new_from_specification(PDL::byte(), 4, $W, $H);
my $img_raw = '';
$img_raw .= $img->slot_sv($_) for @rows;
${$img_pdl->get_dataref} = $img_raw;
$img_pdl->upd_data;

printf "  image: %dx%d RGBA, PDL dims=(%s)\n", $W, $H,
    join(',', $img_pdl->dims);

# PDL: invert colors (255 - pixel), keep alpha
my $rgb = $img_pdl->slice('0:2');    # R,G,B channels
my $inverted = $img_pdl->copy;
$inverted->slice('0:2') .= 255 - $rgb;

# write inverted image back to pool
my $inv_bytes = ${$inverted->get_dataref};
for my $y (0 .. $H - 1) {
    $img->set($rows[$y], substr($inv_bytes, $y * $W * 4, $W * 4));
}

# verify: top-left pixel was (0, 0, 128, 255) → should be (255, 255, 127, 255)
my @px = unpack('C4', substr($img->get($rows[0]), 0, 4));
printf "  inverted top-left: RGBA=(%d,%d,%d,%d)\n", @px;

# verify: bottom-right was (251, 253, 128, 255) → (4, 2, 127, 255)
@px = unpack('C4', substr($img->get($rows[$H-1]), ($W-1)*4, 4));
printf "  inverted bottom-right: RGBA=(%d,%d,%d,%d)\n\n", @px;

$img->free($_) for @rows;

# =====================================================================
# 4. Cross-process parallel reduction
# =====================================================================

print "=== 4. Cross-process: parallel workers → PDL reduction ===\n\n";

my $WORKERS = 4;
my $CHUNK   = 250;

# each worker fills a pool slot with a partial sum array (CHUNK doubles)
my $results = Data::Pool::Shared->new(undef, $WORKERS, $CHUNK * 8);

my @pids;
for my $w (0 .. $WORKERS - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $s = $results->alloc;
        # compute partial: each worker handles a range of the sine table
        my @partial;
        for my $i (0 .. $CHUNK - 1) {
            my $idx = $w * $CHUNK + $i;
            push @partial, sin($idx * 0.01) ** 2;
        }
        $results->set($s, pack("d<$CHUNK", @partial));
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;

# parent: load all worker results into PDL and reduce
my $worker_slots = $results->allocated_slots;
my $all = PDL->new_from_specification(PDL::double(), $CHUNK, $WORKERS);
my $all_raw = '';
$all_raw .= $results->slot_sv($_) for @$worker_slots;
${$all->get_dataref} = $all_raw;
$all->upd_data;

# sum across workers → total array
my $total = $all->xchg(0,1)->sumover;  # sum rows → ($CHUNK)
printf "  %d workers x %d elements each → %d total\n",
    $WORKERS, $CHUNK, $total->nelem;
printf "  global sum=%.4f mean=%.6f\n", $total->sum, $total->avg;

# verify: sum of sin²(x) for x=0..999 * 0.01
my $expected = 0;
$expected += sin($_ * 0.01) ** 2 for 0 .. $WORKERS * $CHUNK - 1;
printf "  expected=%.4f (diff=%.2e)\n\n", $expected, abs($total->sum - $expected);

$results->reset;

# =====================================================================
# 5. data_ptr for direct C/FFI/XS access
# =====================================================================

print "=== 5. Raw pointer access for C/FFI interop ===\n";

my $buf = Data::Pool::Shared::F64->new(undef, 10);
my @bi;
for (1..10) { push @bi, $buf->alloc }
$buf->set($bi[$_], $_ * 1.1) for 0 .. 9;

printf "\n  data_ptr=0x%x (contiguous %d doubles)\n", $buf->data_ptr, $buf->capacity;
printf "  ptr(slot 0)=0x%x  ptr(slot 5)=0x%x  (delta=%d bytes = %d doubles)\n",
    $buf->ptr($bi[0]), $buf->ptr($bi[5]),
    $buf->ptr($bi[5]) - $buf->ptr($bi[0]),
    ($buf->ptr($bi[5]) - $buf->ptr($bi[0])) / 8;

# FFI pattern:
#   $ffi->function('dgemv', ['opaque','int','int','opaque','opaque'] => 'void')
#       ->call($pool->data_ptr, $rows, $cols, $vec_ptr, $out_ptr);

$buf->free($_) for @bi;

printf "\ndone.\n";
