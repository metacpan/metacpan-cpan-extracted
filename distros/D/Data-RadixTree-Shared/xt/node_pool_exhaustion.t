#!/usr/bin/perl
# Regression: rdx_alloc_node returns 0 when the node pool is exhausted, and 0 is
# the NIL sentinel. All three call sites in rdx_insert_locked used the result
# unchecked, so a full tree would:
#   - write through nodes[0], corrupting NIL (every read path treats 0 as
#     "not found", and root is documented as always >= 1), and
#   - link children[b] = 0, silently dropping the key while insert still
#     reported success (a tiny pool "accepted" every one of 200 keys).
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

my $cc = $Config{cc} or plan skip_all => 'no C compiler';
plan skip_all => 'radix.h not found' unless -f 'radix.h';

my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/repro.c" or die $!;
print $fh <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include "radix.h"
int main(int argc, char **argv) {
    char errbuf[RDX_ERR_BUFLEN];
    unlink(argv[1]);
    RdxHandle *h = rdx_create(argv[1], 8, 65536, 0600, errbuf);   /* tiny pool */
    if (!h) { fprintf(stderr, "create: %s\n", errbuf); return 3; }
    RdxNode *nodes = rdx_nodes(h);
    char key[32];
    int inserted = 0;
    for (int i = 0; i < 200; i++) {
        snprintf(key, sizeof key, "key%03d", i);
        if (rdx_insert_locked(h, (const uint8_t *)key, (uint32_t)strlen(key), 1000 + i))
            inserted++;
    }
    if (inserted >= 200) return 43;                       /* claimed success for every key */
    if (nodes[0].label_len != 0 || nodes[0].has_value != 0) return 42;  /* NIL corrupted */
    for (int i = 0; i < 200; i++) {
        snprintf(key, sizeof key, "key%03d", i);
        uint64_t v = 0;
        if (rdx_lookup_locked(h, (const uint8_t *)key, (uint32_t)strlen(key), &v)
            && v != (uint64_t)(1000 + i)) return 44;       /* wrong value */
    }
    return 0;
}
C
close $fh;

my $exe = "$dir/repro";
my $build = `$cc -O1 -g -o $exe $dir/repro.c -I. 2>&1`;
is $?, 0, 'repro compiled' or BAIL_OUT("compile failed:\n$build");

system($exe, "$dir/rdx.bin");
my $rc = $? >> 8;
isnt $rc, 42, 'NIL sentinel is not corrupted when the node pool is exhausted';
isnt $rc, 43, 'insert reports failure once the pool is full (not false success)';
isnt $rc, 44, 'no key returns a wrong value after exhaustion';
is    $rc, 0,  'node-pool exhaustion handled cleanly';

done_testing;
