use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

# A waiter that gives up on lock_timeout after being woken must pass the wake on.

my $root = dirname(dirname(abs_path(__FILE__)));
my $dir = tempdir(CLEANUP => 1);
open my $out, '>', "$dir/handoff.c" or die $!;
print {$out} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <sys/wait.h>
#include "queue.h"

static double now(void) {
    struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec / 1e9;
}
static void wait_waiters(QueueHeader *hdr, uint32_t n) {
    while (__atomic_load_n(&hdr->pop_waiters, __ATOMIC_RELAXED) < n) usleep(1000);
    usleep(20000);
}

int main(void) {
    char err[QUEUE_ERR_BUFLEN];
    QueueHandle *q = queue_create(NULL, 16, QUEUE_MODE_STR, 4096, 0600, err);
    if (!q) { fprintf(stderr, "%s\n", err); return 2; }
    int pipes[2][2];
    pid_t kids[2];
    for (int i = 0; i < 2; i++) {
        if (pipe(pipes[i])) return 2;
        kids[i] = fork();
        if (kids[i] < 0) return 2;
        if (!kids[i]) {
            if (i == 0) q->lock_timeout = 0.001;
            const char *s; uint32_t len; bool utf8;
            int r = queue_str_pop_wait(q, &s, &len, &utf8, 10);
            double t = now();
            dprintf(pipes[i][1], "%d %.6f\n", r, t);
            _exit(0);
        }
        wait_waiters(q->hdr, i + 1);
    }
    queue_str_lock(q);
    queue_str_push_locked(q, "X", 1, 0);
    queue_wake_consumers(q->hdr);
    usleep(200000);
    double released = now();
    queue_mutex_unlock(q->hdr);
    for (int i = 0; i < 2; i++) {
        char buf[64] = {0};
        if (read(pipes[i][0], buf, sizeof buf - 1) <= 0) return 2;
        int r; double t;
        sscanf(buf, "%d %lf", &r, &t);
        printf("consumer %d: result %d after %.3f s\n", i + 1, r, t - released);
        waitpid(kids[i], NULL, 0);
    }
    return 0;
}
C
close $out;

my @cc = shellwords($Config{cc});
is system(@cc, '-O2', "-I$root", '-o', "$dir/handoff", "$dir/handoff.c"), 0, 'harness builds';
my $report = qx{$dir/handoff};
like $report, qr/^consumer 1: result -3 /m, 'the first consumer woken gives up on its lock timeout';
my ($r, $after) = $report =~ /^consumer 2: result (-?\d+) after (-?[\d.]+) s$/m;
is $r, 1, 'the second consumer gets the value';
cmp_ok $after, '<', 1, '  soon after the lock is released, not at its 2 s recheck';
diag $report;

done_testing;
