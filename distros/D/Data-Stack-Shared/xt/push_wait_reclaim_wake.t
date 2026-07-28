#!/usr/bin/perl
# Regression: a pop that reclaims a slot abandoned by a crashed pusher must
# still wake pushers blocked in push_wait().
#
# stk_try_pop() commits the top-- CAS and THEN discovers the slot was never
# published (peer SIGKILLed between the top CAS and publish). The reclaim
# path used to `continue` without the waiters_push/push_wake_seq wake that a
# successful pop performs. With capacity reached, a pusher parked in
# FUTEX_WAIT on push_wake_seq has no other waker on this path -- it hangs
# forever even though the reclaim just freed the whole stack.
#
# Setup reproduces the exact post-crash STATE (slot WRITING, top committed),
# then forks a real child that blocks in an infinite push-wait. The parent
# pops (which reclaims after the ~2s abandon deadline) and reaps the child
# under a bounded timeout: without the fix the child never wakes, the
# watchdog fires, and the test FAILS instead of hanging the suite.
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
#include <string.h>
#include <signal.h>
#include <sys/wait.h>
#include "stack.h"

static void on_alarm(int sig) { (void)sig; _exit(42); }   /* 42 = watchdog */

int main(void) {
    char errbuf[STK_ERR_BUFLEN];
    /* capacity 1: the crashed pusher's committed top CAS fills the stack. */
    StkHandle *h = stk_create(NULL, 1, 8, 0, 0600, errbuf);
    if (!h) { fprintf(stderr, "create: %s\n", errbuf); return 3; }

    signal(SIGALRM, on_alarm);
    alarm(30);   /* absolute backstop: never hang the suite */

    /* Crashed pusher: won the top CAS (0->1), died before publishing, so
     * slot 0 is stuck WRITING@0 and the stack reads full. */
    __atomic_store_n(&h->ctl[0], (0ULL << 2) | STK_SLOT_WRITING, __ATOMIC_RELEASE);
    __atomic_store_n(&h->hdr->top, 1u, __ATOMIC_RELEASE);

    pid_t pid = fork();
    if (pid < 0) { perror("fork"); return 3; }
    if (pid == 0) {
        /* Blocked pusher: infinite push-wait on a full stack. Released only
         * if the popper's reclaim path wakes push_wait sleepers. */
        int64_t v = 42;
        _exit(stk_push(h, &v, sizeof v, -1) == 1 ? 0 : 5);
    }

    /* Deterministic ordering: the child must be registered in waiters_push
     * before the pop runs, or it would observe top==0 by itself and never
     * sleep (masking the bug). Registration is what the wake checks; the
     * extra 50ms parks it inside FUTEX_WAIT well before the ~2s reclaim
     * below completes. */
    while (__atomic_load_n(&h->hdr->waiters_push, __ATOMIC_ACQUIRE) == 0) {
        struct timespec ts = { 0, 1000000L };   /* 1ms */
        nanosleep(&ts, NULL);
    }
    {
        struct timespec ts = { 0, 50000000L };  /* 50ms */
        nanosleep(&ts, NULL);
    }

    /* Pop: commits top 1->0, waits ~2s on the abandoned WRITING slot,
     * reclaims it, finds the stack empty. The bug: returns without waking
     * the parked pusher. */
    int64_t out = 0;
    (void)stk_try_pop(h, &out);

    /* Bounded reap: fixed code releases the child within milliseconds of the
     * reclaim; buggy code strands it in FUTEX_WAIT forever. */
    int status = 0, done = 0;
    for (int i = 0; i < 100; i++) {             /* 100 x 100ms = 10s */
        if (waitpid(pid, &status, WNOHANG) == pid) { done = 1; break; }
        struct timespec ts = { 0, 100000000L };
        nanosleep(&ts, NULL);
    }
    if (!done) {
        kill(pid, SIGKILL);
        waitpid(pid, &status, 0);
        fprintf(stderr, "pusher still blocked 10s after the reclaim pop\n");
        return 1;                               /* the F1 symptom */
    }
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
        fprintf(stderr, "pusher exit status 0x%x\n", status);
        return 2;
    }

    /* The released push must actually have landed: pop returns its value. */
    if (!stk_try_pop(h, &out) || out != 42) {
        fprintf(stderr, "pushed value missing after release\n");
        return 4;
    }
    return 0;
}
C
close $fh;

my $exe = "$dir/repro";
my $err = "$dir/stderr";
my $build = `$cc -O1 -g -o $exe $src -I. 2>&1`;
is $?, 0, 'repro compiled' or BAIL_OUT("compile failed:\n$build");

system("$exe 2>$err");
my $rc = $? >> 8;
my $stderr = do { open my $ef, '<', $err; local $/; <$ef> // '' };
diag $stderr if length $stderr;

isnt $rc, 42, 'watchdog did not fire (no hang)';
isnt $rc, 1,  'blocked push_wait() pusher was released by the reclaim pop';
is   $rc, 0,  'released push landed and popped back';

done_testing;
