#!/usr/bin/perl
# Regression: a writer crashing mid-split must not lose an already-committed key.
#
# The split used to truncate the existing child's label (label_off += m) BEFORE
# publishing the new middle node, so a crash in that window left `cur` pointing
# at a child whose label had lost its first m bytes -- silently losing every key
# beneath it. Publishing first instead would count the prefix twice, so neither
# in-place ordering is crash-safe; the split is now copy-on-write and commits
# with a single store, with the displaced node recycled through the free list
# afterwards (so node consumption is unchanged).
#
# The crash point is a test-only hook in a patched COPY of radix.h; the tree is
# a MAP_SHARED file mapping so the parent observes the child's mutations.
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

my $cc = $Config{cc} or plan skip_all => 'no C compiler';
plan skip_all => 'radix.h not found' unless -f 'radix.h';

my $dir = tempdir(CLEANUP => 1);

open my $in, '<', 'radix.h' or die $!;
my $hdr = do { local $/; <$in> };
close $in;
my $hook = "        { extern int rdx_crash_at_commit; if (rdx_crash_at_commit) _exit(99); }\n";
$hdr =~ s/(^\s*\/\* Single-word commit: everything above is unreachable until this store\. \*\/\n)/$1$hook/m
    or BAIL_OUT('could not inject the crash hook (split commit point changed?)');
open my $out, '>', "$dir/radix_patched.h" or die $!;
print $out $hdr;
close $out;

open my $cfh, '>', "$dir/repro.c" or die $!;
print $cfh <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <sys/wait.h>
#include "radix_patched.h"
int rdx_crash_at_commit = 0;
int main(int argc, char **argv) {
    char errbuf[RDX_ERR_BUFLEN];
    unlink(argv[1]);
    RdxHandle *h = rdx_create(argv[1], 1024, 65536, 0600, errbuf);
    if (!h) return 3;
    rdx_insert_locked(h, (const uint8_t *)"abcdef", 6, 111);
    uint64_t v = 0;
    if (!rdx_lookup_locked(h, (const uint8_t *)"abcdef", 6, &v) || v != 111) return 3;
    uint32_t used_before = h->hdr->node_used;
    pid_t pid = fork();
    if (pid == 0) {                       /* splits "abcdef" at m=3, dies at the commit */
        rdx_crash_at_commit = 1;
        rdx_insert_locked(h, (const uint8_t *)"abcxyz", 6, 222);
        _exit(0);
    }
    int st; waitpid(pid, &st, 0);
    if (!(WIFEXITED(st) && WEXITSTATUS(st) == 99)) return 5;   /* hook did not fire */
    v = 0;
    if (!rdx_lookup_locked(h, (const uint8_t *)"abcdef", 6, &v) || v != 111) return 42;
    /* The interrupted split must not have corrupted the tree for later writers. */
    if (!rdx_insert_locked(h, (const uint8_t *)"abcxyz", 6, 222)) return 43;
    v = 0;
    if (!rdx_lookup_locked(h, (const uint8_t *)"abcxyz", 6, &v) || v != 222) return 44;
    v = 0;
    if (!rdx_lookup_locked(h, (const uint8_t *)"abcdef", 6, &v) || v != 111) return 45;
    (void)used_before;
    return 0;
}
C
close $cfh;

my $exe = "$dir/repro";
my $build = `$cc -O1 -g -o $exe $dir/repro.c -I$dir -I. 2>&1`;
is $?, 0, 'repro compiled' or BAIL_OUT("compile failed:\n$build");

system($exe, "$dir/rdx.bin");
my $rc = $? >> 8;
isnt $rc, 42, 'a key committed before the crash survives a crash mid-split';
isnt $rc, 43, 'a later writer can still insert after the interrupted split';
isnt $rc, 44, 'the retried key is readable';
isnt $rc, 45, 'the original key is still readable after the retry';
is    $rc, 0,  'split is crash-consistent';

done_testing;
