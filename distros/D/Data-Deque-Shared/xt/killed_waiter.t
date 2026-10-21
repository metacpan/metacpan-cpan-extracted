use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/waiter.c" or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <linux/futex.h>
static unsigned wakes;
static pid_t child;
#define syscall(n,p,op,v,ts,p2,v3) \
    ({ if ((n) == SYS_futex && (op) == FUTEX_WAKE) wakes++; \
       syscall(n,p,op,v,ts,p2,v3); })
#include "deque.h"

static void timeout(int sig) {
    (void)sig;
    if (child > 0) kill(child, SIGKILL);
    _exit(124);
}
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    int push = !strncmp(argv[1], "push", 4);
    int front = strstr(argv[1], "front") != NULL;
    char err[DEQ_ERR_BUFLEN];
    DeqHandle *h = deq_create(NULL, 1, 8, DEQ_VAR_INT, 0600, err);
    if (!h) return 3;
    uint32_t *count = push ? &h->hdr->waiters_push : &h->hdr->waiters_pop;
    int64_t v = 17, next = 23, out;
    signal(SIGALRM, timeout);
    alarm(8);
    if (push) deq_try_push_back(h, &v, 8);
    for (int live = 0; live < 2; live++) {
        child = fork();
        if (child < 0) timeout(0);
        if (!child) {
            int ok = push ? deq_push_wait(h, &next, 8, front, 3.0)
                          : deq_pop_wait(h, &out, !front, 3.0);
            _exit(ok && (push || out == next) ? 0 : 1);
        }
        while (__atomic_load_n(count, __ATOMIC_ACQUIRE) != (uint32_t)(live + 1)) usleep(100);
        int status;
        if (!live) {
            kill(child, SIGKILL);
            waitpid(child, &status, 0);
            child = 0;
        }
        if (push) {
            if (!deq_try_pop_front(h, &out) || out != v) return 4;
        } else {
            if (!deq_try_push_back(h, live ? &next : &v, 8)) return 5;
        }
        if (live) {
            waitpid(child, &status, 0);
            child = 0;
            if (status) return 6;
        }
        if (push && live) {
            if (!deq_try_pop_front(h, &out) || out != next) return 7;
        } else if (!push && !live) {
            if (!deq_try_pop_front(h, &out) || out != v) return 8;
        }
        for (int i = 0; i < 1000; i++) {
            if (!deq_try_push_back(h, &v, 8) || !deq_try_pop_front(h, &out) || out != v) return 9;
        }
        if (!live && push) deq_try_push_back(h, &v, 8);
    }
    deq_destroy(h);
    if (wakes > 3) {
        fprintf(stderr, "%s: %u futile wakes after a waiter died\n", argv[1], wakes);
        return 1;
    }
    return 0;
}
C
close $fh or die $!;
my @cc = split /\s+/, $Config{cc};
system(@cc, '-O2', '-I.', "$dir/waiter.c", '-o', "$dir/waiter") == 0
    or BAIL_OUT('could not compile killed waiter regression');
for my $mode (qw(push_front push_back pop_front pop_back)) {
    system("$dir/waiter", $mode);
    is $?, 0, "$mode survives a killed waiter without permanent wake overhead";
}
done_testing;
