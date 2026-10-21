use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/ownership.c" or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <unistd.h>

static void *pause_cursor, *watch_slot;
static pid_t pause_pid, watch_pid, children[3];
static uint32_t *ready;

/* Stop exactly after the position CAS, before any following slot claim. */
#define __atomic_compare_exchange_n(p,e,d,w,s,f) \
    ({ int ok = __atomic_compare_exchange_n(p,e,d,w,s,f); \
       if (ok && (void *)(p) == pause_cursor && getpid() == pause_pid) { \
           pause_cursor = NULL; raise(SIGSTOP); \
       } ok; })
#define __atomic_load_n(p,m) \
    ({ __typeof__(*(p)) v = __atomic_load_n(p,m); \
       if ((void *)(p) == watch_slot && getpid() == watch_pid) \
           __atomic_store_n(ready, (v & 3u) + 1, __ATOMIC_RELEASE); v; })
#include "deque.h"
#if DEQ_VERSION < 3
#define deq_ctl_at(h, idx) (&(h)->ctl[idx])
#endif

static void timeout(int sig) {
    (void)sig;
    for (int i = 0; i < 3; i++) if (children[i] > 0) kill(children[i], SIGKILL);
    _exit(124);
}
static void reap(int i) {
    int status = 0;
    if (waitpid(children[i], &status, 0) != children[i] || status) {
        fprintf(stderr, "worker %d failed: %d\n", i, status);
        timeout(0);
    }
    children[i] = 0;
}
int main(int argc, char **argv) {
    if (argc != 2) return 2;
    int writing = !strncmp(argv[1], "push", 4);
    int draining = !strcmp(argv[1], "drain");
    int front = draining || strstr(argv[1], "front") != NULL;
    int (*push)(DeqHandle*, const void*, uint32_t) = (front == writing) ? deq_try_push_front : deq_try_push_back;
    int (*pop)(DeqHandle*, void*) = front ? deq_try_pop_front : deq_try_pop_back;
    int (*opposite)(DeqHandle*, void*) = front ? deq_try_pop_back : deq_try_pop_front;
    char err[DEQ_ERR_BUFLEN];
    DeqHandle *h = deq_create(NULL, 2, 8, DEQ_VAR_INT, 0600, err);
    if (!h) return 3;
    ready = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
    if (ready == MAP_FAILED) return 4;
    signal(SIGALRM, timeout);
    alarm(8);
    int64_t a = 11, b = 22, c = 33, d = 44, out = 0;
    if (!writing) {
        deq_try_push_back(h, &a, 8);
        deq_try_push_back(h, &b, 8);
        if (!front) { int64_t tmp = a; a = b; b = tmp; }
    }
    children[0] = fork();
    if (children[0] < 0) timeout(0);
    if (!children[0]) {
        pause_cursor = &h->hdr->cursor;
        pause_pid = getpid();
        int ok = writing ? push(h, &a, 8) : draining ? deq_drain(h) > 0 : pop(h, &out);
        _exit(ok && (writing || draining || out == a) ? 0 : 1);
    }
    int status;
    if (waitpid(children[0], &status, WUNTRACED) != children[0] || !WIFSTOPPED(status)) timeout(0);
    if (writing) {
        if (!push(h, &b, 8)) timeout(0);
    } else {
        if (!pop(h, &out) || out != b) timeout(0);
    }
    uint32_t idx = front ? (writing ? 1 : 0) : (writing ? 0 : 1);
    children[1] = fork();
    if (children[1] < 0) timeout(0);
    if (!children[1]) {
        watch_slot = deq_ctl_at(h, idx);
        watch_pid = getpid();
        int ok = writing ? opposite(h, &out) : push(h, &c, 8);
        _exit(ok && (!writing || out == a) ? 0 : 1);
    }
    while (!__atomic_load_n(ready, __ATOMIC_ACQUIRE)) usleep(100);
    int failed = 0;
    if (writing) {
        if (push(h, &c, 8)) failed = 1;
    } else {
        if (!push(h, &d, 8)) timeout(0);
        children[2] = fork();
        if (children[2] < 0) timeout(0);
        if (!children[2]) {
            uint32_t *flags = ready;
            ready = flags + 1;
            watch_slot = deq_ctl_at(h, idx);
            watch_pid = getpid();
            int ok = pop(h, &out);
            __atomic_store_n(flags + 2, 1, __ATOMIC_RELEASE);
            _exit(ok && (out == c || (draining && out == d)) ? 0 : 1);
        }
        while (!__atomic_load_n(ready + 1, __ATOMIC_ACQUIRE)) usleep(100);
        if (__atomic_load_n(ready + 1, __ATOMIC_ACQUIRE) != DEQ_SLOT_READING + 1)
            while (!__atomic_load_n(ready + 2, __ATOMIC_ACQUIRE)) usleep(100);
    }
    kill(children[0], SIGCONT);
    reap(0);
    reap(1);
    if (writing) {
        if (!opposite(h, &out) || out != b) failed = 1;
    } else {
        reap(2);
        if (!draining && (!pop(h, &out) || out != d)) failed = 1;
    }
    if (!deq_size(h) && h->hdr->stat_recoveries == 0 && !failed) {
        deq_destroy(h);
        munmap(ready, 4096);
        return 0;
    }
    fprintf(stderr, "%s: slot ownership or remaining value changed\n", argv[1]);
    return 1;
}
C
close $fh or die $!;

my @cc = split /\s+/, $Config{cc};
system(@cc, '-O2', '-I.', "$dir/ownership.c", '-o', "$dir/ownership") == 0
    or BAIL_OUT('could not compile slot ownership regression');
for my $mode (qw(pop_front pop_back push_front push_back drain)) {
    system("$dir/ownership", $mode);
    is $?, 0, "$mode preserves FIFO order across a descheduled position CAS";
}
done_testing;
