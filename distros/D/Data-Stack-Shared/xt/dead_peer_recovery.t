#!/usr/bin/perl
# Regression: a peer that dies between claiming a slot and publishing it must
# not wedge every other process forever.
#
# stk_try_push commits the top CAS and THEN claims the slot; a crash in that
# window leaves the slot stuck in WRITING. Before the fix, stk_slot_claim_write
# and stk_slot_claim_read spun unbounded, so one SIGKILL turned every later
# push/pop on that stack into an permanent 100%-CPU spin in every process.
# stk_drain already bounded its wait for exactly this reason; push/pop did not.
#
# We do not race a real process: we reproduce the exact post-crash STATE and
# then call the normal API under a watchdog alarm, so the test is deterministic.
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

my $cc = $Config{cc} or plan skip_all => 'no C compiler';
plan skip_all => 'stack.h not found' unless -f 'stack.h';

my $dir = tempdir(CLEANUP => 1);
my $src = "$dir/repro.c";
open my $fh, '>', $src or die $!;
print $fh <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <signal.h>
#include "stack.h"
static void on_alarm(int sig) { (void)sig; _exit(42); }   /* 42 = wedged */
int main(int argc, char **argv) {
    const char *mode = argc > 1 ? argv[1] : "pop";
    char errbuf[STK_ERR_BUFLEN];
    StkHandle *h = stk_create(NULL, 4, 8, 0, 0600, errbuf);
    if (!h) { fprintf(stderr, "create: %s\n", errbuf); return 3; }
    signal(SIGALRM, on_alarm);
    /* Crashed pusher: claimed slot 0, died before publishing. */
    __atomic_store_n(&h->ctl[0], (0ULL << 2) | STK_SLOT_WRITING, __ATOMIC_RELEASE);
    if (!strcmp(mode, "pop")) {
        __atomic_store_n(&h->hdr->top, 1u, __ATOMIC_RELEASE);  /* its top CAS committed */
        alarm(15);
        int64_t out = 0;
        (void)stk_try_pop(h, &out);
    } else {
        __atomic_store_n(&h->hdr->top, 0u, __ATOMIC_RELEASE);
        alarm(15);
        int64_t v = 7;
        if (!stk_try_push(h, &v, sizeof v)) return 4;   /* must succeed after reclaim */
    }
    alarm(0);
    return 0;
}
C
close $fh;

my $exe = "$dir/repro";
my $build = `$cc -O1 -g -o $exe $src -I. 2>&1`;
is $?, 0, 'repro compiled' or BAIL_OUT("compile failed:\n$build");

for my $mode (qw(pop push)) {
    system($exe, $mode);
    my $rc = $? >> 8;
    isnt $rc, 42, "$mode: does not spin forever on a slot abandoned by a dead peer";
    is    $rc, 0,  "$mode: recovered cleanly";
}

done_testing;
