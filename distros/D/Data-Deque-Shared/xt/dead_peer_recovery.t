#!/usr/bin/perl
# Regression: a peer that dies between claiming a slot and publishing it must
# not wedge every other process forever.
#
# deq_drain bounded its wait and force-recovered abandoned slots, but the
# push/pop fast paths (deq_slot_claim_write / deq_slot_claim_read) spun
# unbounded. One SIGKILL in the claim->publish window -- or a drain that
# force-recovered a slot and orphaned a later publish -- turned every
# subsequent push/pop into a permanent 100%-CPU spin in every attached process.
#
# We reproduce the post-crash STATE and call the normal API under a watchdog
# alarm, so the test is deterministic rather than racing a real process.
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

my $cc = $Config{cc} or plan skip_all => 'no C compiler';
plan skip_all => 'deque.h not found' unless -f 'deque.h';

my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/repro.c" or die $!;
print $fh <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <signal.h>
#include "deque.h"
static void on_alarm(int sig) { (void)sig; _exit(42); }   /* 42 = wedged */
int main(int argc, char **argv) {
    const char *mode = argc > 1 ? argv[1] : "pop";
    char errbuf[DEQ_ERR_BUFLEN];
    DeqHandle *h = deq_create(NULL, 4, 8, 0, 0600, errbuf);
    if (!h) { fprintf(stderr, "create: %s\n", errbuf); return 3; }
    signal(SIGALRM, on_alarm);
    if (!strcmp(mode, "pop")) {
        /* Crashed pusher: took the cursor slot, claimed it, died before publish. */
        __atomic_store_n(&h->ctl[0], (0ULL << 2) | DEQ_SLOT_WRITING, __ATOMIC_RELEASE);
        __atomic_store_n(&h->hdr->cursor, DEQ_CURSOR(0, 1), __ATOMIC_RELEASE);
        alarm(20);
        int64_t out = 0;
        (void)deq_try_pop_front(h, &out);
    } else {
        /* Orphaned WRITING slot blocks the next pusher's claim. */
        __atomic_store_n(&h->ctl[0], (1ULL << 2) | DEQ_SLOT_WRITING, __ATOMIC_RELEASE);
        __atomic_store_n(&h->hdr->cursor, DEQ_CURSOR(0, 0), __ATOMIC_RELEASE);
        alarm(20);
        int64_t v = 7;
        if (!deq_try_push_back(h, &v, sizeof v)) return 4;   /* must succeed after reclaim */
    }
    alarm(0);
    return 0;
}
C
close $fh;

my $exe = "$dir/repro";
my $build = `$cc -O1 -g -o $exe $dir/repro.c -I. 2>&1`;
is $?, 0, 'repro compiled' or BAIL_OUT("compile failed:\n$build");

for my $mode (qw(pop push)) {
    system($exe, $mode);
    my $rc = $? >> 8;
    isnt $rc, 42, "$mode: does not spin forever on a slot abandoned by a dead peer";
    is    $rc, 0,  "$mode: recovered cleanly";
}

done_testing;
