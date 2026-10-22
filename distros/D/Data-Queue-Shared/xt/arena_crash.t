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

# Kill at every arena/index store, including between the old separate counters.
my ($before, $str, $after) = $header =~ /\A(.*?)(\/\* Push one item while mutex.*?)(\/\* msync.*)\z/s;
die 'cannot locate string operations' unless defined $str;
$str =~ s{(hdr->(?:arena_wpos|arena_used|head|tail)\s*(?:[+\-]=[^;]*|=(?!=)[^;]*|\+\+|--);|queue_set_arena\([^;]*;|__atomic_store_n\(&hdr->(?:arena_used|head|tail),[^;]*;)}{$1 crash_point();}g;
$header = $before . $str . $after;
open my $out, '>', "$dir/queue.h" or die $!;
print {$out} $header;
close $out;
open $out, '>', "$dir/crash.c" or die $!;
print {$out} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <poll.h>
#include <sys/wait.h>
static unsigned crash_at, stores;
static uint64_t *commit, old_commit;
static void crash_point(void) {
    if ((crash_at && ++stores == crash_at) || (commit && *commit != old_commit)) _exit(77);
}
#include "queue.h"

typedef struct { char data[1024]; uint32_t len; } Item;
static Item model[32];
static unsigned count;

static void insert(unsigned at, char byte, unsigned len) {
    memmove(model + at + 1, model + at, (count - at) * sizeof(Item));
    memset(model[at].data, byte, len); model[at].len = len; count++;
}
static void remove_at(unsigned at) {
    count--; memmove(model + at, model + at + 1, (count - at) * sizeof(Item));
}
static int push(QueueHandle *q, int front, char byte, unsigned len) {
    char data[1024]; memset(data, byte, len);
    int ok = front ? queue_str_push_front(q, data, len, 0) : queue_str_try_push(q, data, len, 0);
    if (ok == 1) insert(front ? 0 : count, byte, len);
    return ok;
}
static int pop(QueueHandle *q, int back) {
    const char *data; uint32_t len; bool utf8;
    int ok = back ? queue_str_pop_back(q, &data, &len, &utf8) : queue_str_try_pop(q, &data, &len, &utf8);
    if (!count) return ok == 0;
    unsigned at = back ? count - 1 : 0;
    if (ok != 1 || len != model[at].len || memcmp(data, model[at].data, len)) return 0;
    remove_at(at); return 1;
}

int main(void) {
    unsigned checked = 0;
    for (unsigned op = 0; op < 5; op++) {
        for (unsigned point = 1; point < 12; point++) {
            char err[QUEUE_ERR_BUFLEN];
            QueueHandle *q = queue_create(NULL, 16, QUEUE_MODE_STR, 4096, 0600, err);
            if (!q) { fprintf(stderr, "%s\n", err); return 2; }
            count = 0;
            push(q, 0, 'K', 512); push(q, 0, 'B', 256); push(q, 0, 'C', 768);
            uint64_t head = q->hdr->head, tail = q->hdr->tail;
            pid_t pid = fork(); if (pid < 0) return 2;
            if (!pid) {
                crash_at = point; stores = 0;
                const char *data; uint32_t len; bool utf8;
                char value[128]; memset(value, 'N', sizeof value);
                if (op == 0) queue_str_try_push(q, value, sizeof value, 0);
                if (op == 1) queue_str_push_front(q, value, sizeof value, 0);
                if (op == 2) queue_str_try_pop(q, &data, &len, &utf8);
                if (op == 3) queue_str_pop_back(q, &data, &len, &utf8);
                if (op == 4) queue_str_clear(q);
                _exit(0);
            }
            int status; if (waitpid(pid, &status, 0) != pid || !WIFEXITED(status)) return 2;
            uint32_t owner = __atomic_load_n(&q->hdr->mutex, __ATOMIC_RELAXED);
            if (owner) queue_recover_stale_mutex(q->hdr, owner);
            if (op == 0 && q->hdr->tail != tail) insert(count, 'N', 128);
            if (op == 1 && q->hdr->head != head) insert(0, 'N', 128);
            if (op == 2 && q->hdr->head != head) remove_at(0);
            if (op == 3 && q->hdr->tail != tail) remove_at(count - 1);
            if (op == 4 && q->hdr->head == q->hdr->tail) count = 0;

            for (unsigned i = 0; i < 200; i++) {
                int front = i % 2;
                int ok = push(q, front, 'P', 128 + (i % 5) * 32);
                if (ok == 1 && !pop(q, !front)) goto broken;
                if (ok == 0 && !pop(q, i % 2)) goto broken;
            }
            while (count) if (!pop(q, 0)) goto broken;
            if (q->hdr->arena_used != 0) goto broken;
            queue_destroy(q); checked++;
            if (WEXITSTATUS(status) == 0) break;
            continue;
broken:
            fprintf(stderr, "message corruption: operation=%u store=%u\n", op, point);
            queue_destroy(q); return 1;
        }
    }
    printf("%u crash boundaries checked\n", checked);
    for (unsigned producer = 0; producer < 2; producer++) {
        char err[QUEUE_ERR_BUFLEN];
        QueueHandle *q = queue_create(NULL, 2, QUEUE_MODE_STR, 4096, 0600, err);
        if (!q) return 2;
        if (producer) { queue_str_try_push(q, "A", 1, 0); queue_str_try_push(q, "B", 1, 0); }
        int channel[2]; if (pipe(channel)) return 2;
        pid_t waiter = fork(); if (waiter < 0) return 2;
        if (!waiter) {
            close(channel[0]);
            const char *data; uint32_t len; bool utf8;
            int ok = producer ? queue_str_push_wait(q, "N", 1, 0, -1)
                              : queue_str_pop_wait(q, &data, &len, &utf8, -1);
            char result = ok == 1 ? 'S' : 'F';
            write(channel[1], &result, 1); _exit(ok == 1 ? 0 : 1);
        }
        close(channel[1]);
        uint32_t *waiters = producer ? &q->hdr->push_waiters : &q->hdr->pop_waiters;
        struct timespec nap = {0, 1000000L};
        unsigned spins = 0;
        while (!__atomic_load_n(waiters, __ATOMIC_RELAXED) && spins++ < 1000) nanosleep(&nap, NULL);
        if (!__atomic_load_n(waiters, __ATOMIC_RELAXED)) {
            kill(waiter, SIGKILL); waitpid(waiter, NULL, 0); return 2;
        }
        pid_t peer = fork(); if (peer < 0) return 2;
        if (!peer) {
            commit = producer ? &q->hdr->head : &q->hdr->tail; old_commit = *commit;
            const char *data; uint32_t len; bool utf8;
            if (producer) queue_str_try_pop(q, &data, &len, &utf8);
            else queue_str_try_push(q, "N", 1, 0);
            _exit(99);
        }
        int status; waitpid(peer, &status, 0);
        if (!WIFEXITED(status) || WEXITSTATUS(status) != 77) {
            kill(waiter, SIGKILL); waitpid(waiter, NULL, 0); return 2;
        }
        struct pollfd readable = {channel[0], POLLIN, 0};
        int ready = poll(&readable, 1, 6000);
        char result = 'F'; if (ready > 0) read(channel[0], &result, 1);
        if (ready <= 0) kill(waiter, SIGKILL);
        waitpid(waiter, NULL, 0); close(channel[0]); queue_destroy(q);
        if (result != 'S') {
            fprintf(stderr, "%s stayed asleep after a committed peer crash\n", producer ? "producer" : "consumer");
            return 1;
        }
    }
    puts("blocked producers and consumers recover missed crash wakeups");
    return 0;
}
C
close $out;

my @cc = shellwords($Config{cc});
my @flags = shellwords($ENV{QUEUE_TEST_CFLAGS} // '-O2');
is system(@cc, @flags, '-I', $dir, '-o', "$dir/crash", "$dir/crash.c"), 0, 'crash harness builds';
SKIP: {
    skip 'compile failed', 1 unless -x "$dir/crash";
    is system("$dir/crash"), 0, 'surviving messages stay intact after every interrupted string operation';
}
done_testing;
