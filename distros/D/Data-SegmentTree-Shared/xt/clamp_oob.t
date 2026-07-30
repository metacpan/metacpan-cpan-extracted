use strict;
use warnings;
use Test::More;
use Config;
use Cwd ();
use File::Temp ();

# ----------------------------------------------------------------------------
# I1 regression: the Layer-B size clamp in st_setup (segtree.h) must keep the
# tree size a POWER OF TWO.
#
# st_setup caches n/size from the (peer-writable) header and, if the mapping is
# too small to hold 2*size nodes, clamps size down to what fits.  A bare
# `size = nodes_max/2` can leave a NON-power-of-two size; the mid-split recursion
# over [0, size-1] then indexes a node past 2*size and out of the mapping
# (verified: size=6 walks node index 13 > 2*6=12).  The fix clamps to the largest
# power of two <= nodes_max/2.
#
# The normal t/ suite never hits this path (it only fires on a header rewritten
# in the validate->setup window), so we craft the geometry directly in C: build a
# header that claims a size the mapping cannot hold, call st_setup, and assert the
# clamped size is a power of two (or 0) with 2*size <= nodes_max.  A malloc-backed
# region (not mmap) lets ASAN guard the exact end, so a subsequent
# range_assign(0, n-1, x) that indexed a node past the buffer would be caught as a
# heap-buffer-overflow.  Run under ASAN=1 for that check; the pow2 assertion holds
# either way.
# ----------------------------------------------------------------------------

my $cc = $Config{cc} or plan skip_all => 'no C compiler';
my $root = Cwd::getcwd();
plan skip_all => "segtree.h not found in $root" unless -f "$root/segtree.h";

my $asan = $ENV{ASAN} ? 1 : 0;
my $asan_lib = '';
if ($asan) {
    chomp($asan_lib = `$cc -print-file-name=libasan.so 2>/dev/null`);
    $asan = 0 unless $asan_lib && -f $asan_lib;   # ASAN requested but unavailable -> plain run
}

my $src = <<'C_SRC';
/* _GNU_SOURCE is supplied on the compile line (-D_GNU_SOURCE), as in the XS build */
#include "segtree.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int failures = 0;

/* Craft a mapping whose header claims `claimed_size` (needing 2*claimed_size
 * nodes) but whose real mapping holds only `node_room` nodes, so the Layer-B
 * clamp fires.  Assert the clamped size is a power of two (or 0) and fits, then
 * exercise the tree so ASAN can prove no node index escapes the buffer. */
static void check(uint64_t node_room, uint64_t claimed_size, uint64_t claimed_n,
                  uint64_t expect_size) {
    StLayout L0     = st_layout_for(0);
    uint64_t noff   = L0.nodes;                       /* size-independent prefix */
    size_t map_size = (size_t)(noff + node_room * sizeof(StNode));

    /* malloc-backed (NOT mmap): ASAN guards the exact end, so a node access past
     * index node_room-1 is a heap-buffer-overflow ASAN catches. */
    unsigned char *base = (unsigned char *)calloc(1, map_size);
    if (!base) { fprintf(stderr, "calloc failed\n"); exit(2); }

    StHeader *hdr = (StHeader *)base;
    hdr->magic            = ST_MAGIC;
    hdr->version          = ST_VERSION;
    hdr->reader_slots_off = L0.reader_slots;
    hdr->nodes_off        = noff;
    hdr->n                = claimed_n;
    hdr->size             = claimed_size;             /* the lie the clamp must contain */
    hdr->total_size       = map_size;

    /* st_setup munmaps only on handle-calloc failure (won't happen); we never call
     * st_destroy (which would munmap), so `base` stays a plain malloc region. */
    StHandle *h = st_setup(base, map_size, NULL, -1, NULL);
    if (!h) { fprintf(stderr, "st_setup returned NULL\n"); exit(2); }

    uint64_t nmax = st_nodes_max(h);
    int pow2_ok = (h->size == 0) || ((h->size & (h->size - 1)) == 0);
    int fit_ok  = (2 * h->size <= nmax);
    int n_ok    = (h->n <= h->size);
    int exp_ok  = (h->size == expect_size);

    fprintf(stderr,
        "room=%2llu claimed=%llu -> nodes_max=%2llu fit=%llu size=%llu n=%llu "
        "[pow2=%d fit=%d n<=size=%d expect%llu=%d]\n",
        (unsigned long long)node_room, (unsigned long long)claimed_size,
        (unsigned long long)nmax, (unsigned long long)(nmax / 2),
        (unsigned long long)h->size, (unsigned long long)h->n,
        pow2_ok, fit_ok, n_ok, (unsigned long long)expect_size, exp_ok);

    if (!(pow2_ok && fit_ok && n_ok && exp_ok)) failures++;

    /* Exercise the clamped tree.  POINT updates force a root-to-leaf descent that
     * touches the DEEPEST nodes -- unlike a single full-range op, which stops at
     * the root and never recurses.  With the pow2 clamp the perfect tree has every
     * node index < 2*size <= nodes_max, so no OOB.  Without the fix (size left =
     * fit, e.g. 6) this mid-split descent walks a node past the buffer (size=6
     * reaches node index 13 > 2*6) -> ASAN heap-buffer-overflow right here. */
    if (h->n > 0) {
        int64_t s = 0, mn = 0, mx = 0, want = 0;
        for (uint64_t i = 0; i < h->n; i++) {         /* point-assign pos i := i+1 (descends deep) */
            st_range_assign_locked(h, i, i, (int64_t)(i + 1));
            want += (int64_t)(i + 1);
        }
        st_query_locked(h, 0, h->n - 1, &s, &mn, &mx);
        if (s != want || mn != 1 || mx != (int64_t)h->n) {
            fprintf(stderr, "  point-assign/query mismatch s=%lld mn=%lld mx=%lld want=%lld\n",
                    (long long)s, (long long)mn, (long long)mx, (long long)want);
            failures++;
        }
        st_range_add_locked(h, 0, h->n - 1, 10);      /* then a range_add over the same span */
        st_query_locked(h, 0, h->n - 1, &s, &mn, &mx);
        if (s != want + 10 * (int64_t)h->n) {
            fprintf(stderr, "  range_add mismatch s=%lld\n", (long long)s);
            failures++;
        }
    }

    free(h->path);
    free(h);
    free(base);
}

int main(void) {
    /* claimed_size = 8 (needs 16 nodes) exceeds every fit below, so the clamp
     * fires; expected clamped size = largest power of two <= (node_room / 2). */
    check(13, 8, 8, 4);   /* fit=6  -> 4  (the non-pow2 fit that motivates the fix) */
    check(11, 8, 8, 4);   /* fit=5  -> 4  */
    check( 7, 8, 8, 2);   /* fit=3  -> 2  */
    check( 5, 8, 8, 2);   /* fit=2  -> 2  (already pow2) */
    check( 3, 8, 8, 1);   /* fit=1  -> 1  */
    check( 2, 8, 8, 1);   /* fit=1  -> 1  */
    check( 1, 8, 8, 0);   /* fit=0  -> 0  (size 0: ops are safe no-ops) */
    /* clamp does NOT fire (claimed 8 <= fit): size passes through unchanged. */
    check(20, 8, 8, 8);   /* fit=10 -> size stays 8, 2*8=16 <= 20 */

    if (failures) { fprintf(stderr, "FAIL: %d assertion(s)\n", failures); return 1; }
    fprintf(stderr, "OK\n");
    return 0;
}
C_SRC

my $dir = File::Temp->newdir();
my $cfile = "$dir/clamp_oob.c";
my $exe   = "$dir/clamp_oob";
open my $fh, '>', $cfile or die "write $cfile: $!";
print $fh $src;
close $fh;

my @flags = ('-D_GNU_SOURCE', "-I$root", '-O2');
@flags = ('-D_GNU_SOURCE', "-I$root", '-O1', '-g', '-fsanitize=address',
          '-fno-omit-frame-pointer') if $asan;

my $compile = "$cc @flags -o \Q$exe\E \Q$cfile\E -lpthread 2>&1";
my $cout = `$compile`;
unless (-x $exe) {
    plan skip_all => "harness failed to compile:\n$compile\n$cout";
}
diag "compiled clamp harness" . ($asan ? ' (ASAN)' : '');

my $run = $asan
    ? "ASAN_OPTIONS=detect_leaks=0 \Q$exe\E 2>&1"
    : "\Q$exe\E 2>&1";
my $out = `$run`;
my $rc  = $?;
diag $out;

is $rc, 0, 'clamp harness exited 0 (pow2 clamp holds; no OOB)';
like $out, qr/^OK$/m, 'clamp harness reported OK';
unlike $out, qr/AddressSanitizer|heap-buffer-overflow|runtime error/,
    'no sanitizer / OOB report';

done_testing;
