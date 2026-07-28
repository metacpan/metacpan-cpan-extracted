#!/usr/bin/perl
# Regression: a writer displaced by dead-writer recovery must not clobber the
# recovered slot or roll its seq back.
#
# Writer A claims a slot (seq even->odd) then stalls. Writer B waits past
# RING_WRITER_RECOVERY_SEC, CAS-recovers the slot, writes and commits. Before
# the fix, A then (a) memcpy'd its stale value over B's committed data and
# (b) BLIND-stored its own stale done-mark, rolling seq back to a superseded
# epoch -- losing B's write and leaving readers unable to match the slot
# (ring_read_latest returned failure).
#
# The stall is a test-only hook injected into a COPY of ring.h; every other
# line exercised is the shipped code path. capacity == 1 so both writers
# contend for the same slot.
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

my $cc = $Config{cc} or plan skip_all => 'no C compiler';
plan skip_all => 'ring.h not found' unless -f 'ring.h';

my $dir = tempdir(CLEANUP => 1);

# Copy ring.h and inject the stall hook right after the write is claimed.
open my $in, '<', 'ring.h' or die $!;
my $hdr = do { local $/; <$in> };
close $in;
my $hook = "        { extern int ring_test_slow_writer; if (ring_test_slow_writer) sleep(6); }\n";
$hdr =~ s/(    if \(wrote\) \{\n)/$1$hook/
    or BAIL_OUT('could not inject the stall hook into ring.h (write path changed?)');
open my $out, '>', "$dir/ring_patched.h" or die $!;
print $out $hdr;
close $out;

open my $cfh, '>', "$dir/repro.c" or die $!;
print $cfh <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <sys/wait.h>
#include "ring_patched.h"
int ring_test_slow_writer = 0;
#define A_VAL 0xAAAAAAAAAAAAAAAAULL
#define B_VAL 0xBBBBBBBBBBBBBBBBULL
int main(int argc, char **argv) {
    char errbuf[RING_ERR_BUFLEN];
    const char *path = argv[1];
    unlink(path);
    RingHandle *h = ring_create(path, 1, sizeof(uint64_t), RING_VAR_INT, 0600, errbuf);
    if (!h) { fprintf(stderr, "create: %s\n", errbuf); return 3; }
    pid_t pid = fork();
    if (pid == 0) { ring_test_slow_writer = 1; uint64_t v = A_VAL;
                    ring_write(h, &v, sizeof v); _exit(0); }
    sleep(1);                                   /* let A claim the slot */
    uint64_t b = B_VAL;
    ring_write(h, &b, sizeof b);                /* blocks until it recovers the slot */
    uint64_t seq_after_b = __atomic_load_n(&h->seq[0], __ATOMIC_ACQUIRE);
    int st; waitpid(pid, &st, 0);               /* A resumes and completes */
    uint64_t seq_final = __atomic_load_n(&h->seq[0], __ATOMIC_ACQUIRE);
    uint64_t got = 0;
    int ok = ring_read_latest(h, 0, &got);
    if (seq_final < seq_after_b) return 42;     /* epoch rolled backwards */
    if (!ok || got != B_VAL)     return 42;     /* committed write lost */
    return 0;
}
C
close $cfh;

my $exe  = "$dir/repro";
my $build = `$cc -O1 -g -o $exe $dir/repro.c -I$dir -I. 2>&1`;
is $?, 0, 'repro compiled' or BAIL_OUT("compile failed:\n$build");

system($exe, "$dir/ring.bin");
my $rc = $? >> 8;
isnt $rc, 42, 'displaced writer does not clobber the recovered slot or regress its seq';
is    $rc, 0,  'recovered write is still readable afterwards';

done_testing;
