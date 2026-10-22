use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

my $root = dirname(dirname(abs_path(__FILE__)));
my $dir = tempdir(CLEANUP => 1);
open my $in, '<', "$root/queue.h" or die $!;
my $header = do { local $/; <$in> };
close $in;
# Pause a worker after reservation so its peer publishes/releases first.
$header =~ s/slot->value = value;/if (value == 41) reserve_gate(0); slot->value = value;/
    or die 'cannot locate push reservation';
$header =~ s/\*value = slot->value;/if (slot->value == 41) reserve_gate(1); *value = slot->value;/
    or die 'cannot locate pop reservation';
$header =~ s/(SLOT \*slot = &\(\(SLOT \*\)h->slots\)\[pos & h->cap_mask\];)/reserve_gate(2); $1/;
open my $out, '>', "$dir/queue.h" or die $!;
print {$out} $header;
close $out;
open $out, '>', "$dir/wakeup.c" or die $!;
print {$out} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <poll.h>
#include <sys/wait.h>
static int reserve_ready[2], reserve_go[2], gate_kind;
static pid_t children[3], parent;
static unsigned nchildren;
static void cleanup_children(void) {
    if (getpid() != parent) return;
    for (unsigned i = 0; i < nchildren; i++) {
        if (waitpid(children[i], NULL, WNOHANG) == 0) {
            kill(children[i], SIGKILL);
            waitpid(children[i], NULL, 0);
        }
    }
}
static void reserve_gate(int kind) {
    if (kind != gate_kind) return;
    char c = 'G';
    if (write(reserve_ready[1], &c, 1) != 1 || read(reserve_go[0], &c, 1) != 1) _exit(88);
}
#include "queue.h"
#define JOIN_(a,b) a##b
#define JOIN(a,b) JOIN_(a,b)
#define QOP(op) JOIN(TEST_PREFIX,op)
static int wait_count(uint32_t *count, uint32_t want) {
    struct timespec nap = {0, 1000000L};
    for (unsigned i = 0; i < 1000; i++) {
        if (__atomic_load_n(count, __ATOMIC_RELAXED) == want) {
            struct timespec settle = {0, 10000000L};
            nanosleep(&settle, NULL);
            return 1;
        }
        nanosleep(&nap, NULL);
    }
    return 0;
}
int main(void) {
    int failed = 0;
    parent = getpid();
    atexit(cleanup_children);
    const uint64_t starts[] = {0, 0x7ffffffeULL, 0xfffffffeULL};
    for (unsigned boundary = 0; boundary < sizeof starts / sizeof starts[0]; boundary++) {
    for (int mixed = 0; mixed < 2; mixed++) {
    for (int producer = 0; producer < 2; producer++) {
        char err[QUEUE_ERR_BUFLEN];
        QueueHandle *q = queue_create(NULL, mixed ? 4 : 2, TEST_MODE, 0, 0600, err);
        if (!q) return 2;
        nchildren = 0;
        q->hdr->head = q->hdr->tail = starts[boundary];
        for (unsigned i = 0; i < q->capacity; i++) {
            uint64_t pos = starts[boundary] + i;
            ((TEST_SLOT *)q->slots)[pos & q->cap_mask].sequence = (TEST_SEQ)pos;
        }
        gate_kind = -1;
        if (producer) for (unsigned i = 0; i < q->capacity; i++) QOP(_try_push)(q, 41 + i);
        int report[2]; if (pipe(report) || pipe(reserve_ready) || pipe(reserve_go)) return 2;
        pid_t waiters[2];
        gate_kind = mixed ? 2 : -1;
        for (unsigned i = 0; i < 2; i++) {
            waiters[i] = fork(); if (waiters[i] < 0) return 2;
            if (!waiters[i]) {
                close(report[0]); TEST_VALUE value;
                int ok = producer ? QOP(_push_wait)(q, 61 + i, 3)
                                  : QOP(_pop_wait)(q, &value, 3);
                char c = ok == 1 ? 'S' : 'F'; write(report[1], &c, 1); _exit(ok == 1 ? 0 : 1);
            }
            children[nchildren++] = waiters[i];
        }
        close(report[1]);
        if (!wait_count(producer ? &q->hdr->push_waiters : &q->hdr->pop_waiters, 2)) return 2;
        gate_kind = producer ? 1 : 0;
        pid_t slow = fork(); if (slow < 0) return 2;
        if (!slow) {
            TEST_VALUE value;
            int ok = producer ? QOP(_try_pop)(q, &value) : QOP(_try_push)(q, 41);
            _exit(ok == 1 ? 0 : 1);
        }
        children[nchildren++] = slow;
        struct pollfd reserved = {reserve_ready[0], POLLIN, 0};
        char c;
        if (poll(&reserved, 1, 1000) <= 0 || read(reserve_ready[0], &c, 1) != 1) return 2;
        gate_kind = -1;
        uint64_t *retries = producer ? &q->hdr->stat_push_full : &q->hdr->stat_pop_empty;
        uint64_t before = __atomic_load_n(retries, __ATOMIC_RELAXED);
        TEST_VALUE value;
        int ok = producer ? QOP(_try_pop)(q, &value) : QOP(_try_push)(q, 42);
        if (ok != 1) return 2;
        if (mixed) {
            ok = producer ? QOP(_try_pop)(q, &value) : QOP(_try_push)(q, 43);
            if (ok != 1) return 2;
        }
        struct timespec nap = {0, 1000000L};
        unsigned spins;
        for (spins = 0; spins < 1000; spins++) {
            uint64_t current = __atomic_load_n(retries, __ATOMIC_RELAXED);
            if (current >= before + (mixed ? 4 : 2)) break;
            nanosleep(&nap, NULL);
        }
        if (spins == 1000 || !wait_count(producer ? &q->hdr->push_waiters : &q->hdr->pop_waiters, 2)) return 2;
        if (write(reserve_go[1], "G", 1) != 1) return 2;
        int status; waitpid(slow, &status, 0);
        if (!WIFEXITED(status) || WEXITSTATUS(status)) return 2;
        if (mixed) {
            if (poll(&reserved, 1, 1000) <= 0 || read(reserve_ready[0], &c, 1) != 1) return 2;
            ok = producer ? QOP(_try_push)(q, 99) : QOP(_try_pop)(q, &value);
            if (ok != 1 || write(reserve_go[1], "G", 1) != 1) return 2;
        }
        unsigned got = 0;
        struct pollfd pfd = {report[0], POLLIN, 0};
        while (got < 2 && poll(&pfd, 1, 500) > 0) {
            if (read(report[0], &c, 1) != 1) break;
            if (c != 'S') break;
            got++;
        }
        if (got != 2) fprintf(stderr, "%s completed: %u/2 at position %llu (mixed=%d)\n",
            producer ? "producers" : "consumers", got, (unsigned long long)starts[boundary], mixed);
        if (got != 2) failed = 1;
        for (unsigned i = 0; i < 2; i++) {
            if (got != 2) kill(waiters[i], SIGKILL);
            waitpid(waiters[i], &status, 0);
            if (got == 2 && (!WIFEXITED(status) || WEXITSTATUS(status))) failed = 1;
        }
        close(report[0]);
        close(reserve_ready[0]); close(reserve_ready[1]); close(reserve_go[0]); close(reserve_go[1]);
        queue_destroy(q);
    }
    }
    }
    return failed;
}
C
close $out;

my @cc = shellwords($Config{cc});
my @flags = shellwords($ENV{QUEUE_TEST_CFLAGS} // '-O2');
for my $variant (
    [Int => 'int', 'int64_t', 'QUEUE_MODE_INT', 'QueueIntSlot', 'uint64_t'],
    [Int32 => 'int32', 'int32_t', 'QUEUE_MODE_INT32', 'QueueInt32Slot', 'uint32_t'],
    [Int16 => 'int16', 'int16_t', 'QUEUE_MODE_INT16', 'QueueInt16Slot', 'uint32_t'],
) {
    my ($name, $prefix, $type, $mode, $slot, $seq) = @$variant;
    my $bin = "$dir/$prefix";
    is system(@cc, @flags, "-DTEST_PREFIX=queue_$prefix", "-DTEST_VALUE=$type",
        "-DTEST_MODE=$mode", "-DTEST_SLOT=$slot", "-DTEST_SEQ=$seq",
        '-I', $dir, '-o', $bin, "$dir/wakeup.c"),
        0, "$name reservation harness builds";
    SKIP: {
        skip 'compile failed', 1 unless -x $bin;
        is system($bin), 0, "$name waiters progress after out-of-order reservations";
    }
}
done_testing;
