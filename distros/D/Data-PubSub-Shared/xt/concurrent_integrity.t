use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use ExtUtils::CBuilder;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);

my $root = dirname(dirname(abs_path(__FILE__)));
my $dir = tempdir(CLEANUP => 1);
my $source = "$dir/integrity.c";
open my $fh, '>', $source or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#include <stdio.h>
#include <stdint.h>
#include <sys/wait.h>

/* Reproduce a publisher overtaking the reader's write_pos snapshot. */
static void *snapshot_ptr, *deferred_ptr;
static uint64_t deferred_seq;
static void overtake(void);
#define __atomic_load_n(p, order) ({ \
    __typeof__(*(p)) saved = __atomic_load_n(p, order); \
    if ((void *)(p) == snapshot_ptr) { snapshot_ptr = NULL; overtake(); } \
    saved; \
})
#define __atomic_store_n(p, value, order) do { \
    if ((void *)(p) != deferred_ptr || (uint64_t)(value) != deferred_seq) \
        __atomic_store_n(p, value, order); \
} while (0)
#include "pubsub.h"

static PubSubHandle *writer;
static unsigned next_value, last_value;

static void publish(unsigned n) {
    if (writer->mode == PUBSUB_MODE_INT) pubsub_int_publish(writer, n);
    else if (writer->mode == PUBSUB_MODE_INT32) pubsub_int32_publish(writer, n);
    else if (writer->mode == PUBSUB_MODE_INT16) pubsub_int16_publish(writer, (int16_t)n);
    else {
        char msg[128];
        memset(msg, 'A' + n % 26, sizeof msg);
        memcpy(msg, &n, sizeof n);
        pubsub_str_publish(writer, msg, sizeof msg, false);
    }
}

static void overtake(void) {
    for (unsigned n = next_value; n <= last_value; n++) publish(n);
}

static int poll_value(PubSubSub *s) {
    int r;
    int64_t got = 0, expected = s->cursor;
    if (writer->mode == PUBSUB_MODE_INT) r = pubsub_int_poll(s, &got);
    else if (writer->mode == PUBSUB_MODE_INT32) {
        int32_t n = 0; r = pubsub_int32_poll(s, &n); got = n;
    } else if (writer->mode == PUBSUB_MODE_INT16) {
        int16_t n = 0; r = pubsub_int16_poll(s, &n); got = n;
    } else {
        const char *msg; uint32_t len; bool utf8;
        r = pubsub_str_poll(s, &msg, &len, &utf8);
        if (r) {
            unsigned n;
            if (len != 128 || utf8) return -1;
            memcpy(&n, msg, sizeof n); got = n;
            for (unsigned j = sizeof n; j < len; j++)
                if (msg[j] != 'A' + n % 26) return -1;
        }
    }
    if (!r) return 0;
    if (s->cursor <= (uint64_t)expected) return -1;
    expected = writer->mode == PUBSUB_MODE_INT16 ? (int16_t)s->cursor : (int64_t)s->cursor;
    return got == expected ? 1 : -1;
}

static int run_mode(unsigned mode) {
    char err[PUBSUB_ERR_BUFLEN];
    writer = pubsub_create(NULL, 8, mode, 128, 0600, err);
    if (!writer) { fprintf(stderr, "%s\n", err); return 1; }
    PubSubSub *s = pubsub_subscribe(writer, 0);
    if (!s) return 1;
    for (unsigned n = 1; n <= 8; n++) publish(n);
    s->cursor = 5;
    next_value = 9; last_value = 16;
    snapshot_ptr = &writer->hdr->write_pos;
    if (poll_value(s) != 1 || s->cursor != 9 || s->overflow_count != 3) {
        fprintf(stderr, "mode %u: stale snapshot changed the lost-message count\n", mode);
        return 1;
    }
    pubsub_sub_destroy(s);
    pubsub_clear(writer);
    s = pubsub_subscribe(writer, 0);
    if (!s) return 1;
    for (unsigned n = 1; n <= 8; n++) publish(n);
    /* Pause a fallback writer after its value store, before its final sequence. */
    deferred_ptr = writer->slots; deferred_seq = 9;
    next_value = last_value = 9;
    snapshot_ptr = &writer->hdr->write_pos;
    if (poll_value(s) < 0) {
        fprintf(stderr, "mode %u: uncommitted overwrite was delivered\n", mode);
        return 1;
    }
    deferred_ptr = NULL;
    pubsub_sub_destroy(s);
    pubsub_clear(writer);
    s = pubsub_subscribe(writer, 0);
    if (!s) return 1;
    pid_t pid = fork();
    if (pid < 0) return 1;
    if (!pid) {
        for (unsigned n = 1; n <= 500000; n++) publish(n);
        _exit(0);
    }
    unsigned received = 0, bad = 0;
    uint64_t previous = 0;
    while (s->cursor < 500000) {
        int r = poll_value(s);
        if (s->cursor < previous) bad++;
        previous = s->cursor;
        if (r) { received++; if (r < 0) bad++; }
    }
    int status;
    waitpid(pid, &status, 0);
    if (received + s->overflow_count != 500000) bad++;
    printf("mode=%u received=%u lost=%llu errors=%u\n", mode, received,
        (unsigned long long)s->overflow_count, bad);
    pubsub_sub_destroy(s);
    pubsub_destroy(writer);
    return bad || status;
}

int main(void) {
    alarm(20);
    for (unsigned mode = 0; mode < 4; mode++)
        if (run_mode(mode)) return 1;
    return 0;
}
C
close $fh or die $!;
my $builder = ExtUtils::CBuilder->new(quiet => 1);
my $flags = '-O2 -fno-strict-aliasing';
$flags .= ' -mcx16' if $Config{archname} =~ /(?:x86_64|amd64)/i;
for my $mutex (0, 1) {
    my $object = $builder->compile(source => $source, include_dirs => [$root],
        extra_compiler_flags => "$flags " . ($mutex ? '-DPUBSUB_INT_FORCE_MUTEX' : ''));
    my $exe = $builder->link_executable(objects => $object, exe_file => "$dir/check");
    is system($exe), 0, $mutex ? 'mutex fallback preserves concurrent messages and counts'
        : 'atomic publishers preserve concurrent messages and counts';
}
done_testing;
