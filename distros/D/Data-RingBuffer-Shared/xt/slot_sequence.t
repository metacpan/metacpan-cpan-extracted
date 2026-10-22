use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

plan skip_all => 'ring.h not found' unless -f 'ring.h';
my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/slots.c" or die $!;
print {$fh} <<'C';
#include "ring.h"
#include <pthread.h>

static RingHandle *h;
static int done, bad;
static uint64_t samples;

static uint64_t value(uint64_t seq) {
    return (seq + 1) * UINT64_C(0x9e3779b97f4a7c15);
}

static void *reader(void *arg) {
    (void)arg;
    do {
        uint64_t head = ring_head(h), got;
        if (!head) continue;
        uint64_t seq = head - 1;
        if (ring_read_seq(h, seq, &got)) {
            samples++;
            if (got != value(seq)) bad = 1;
        }
    } while (!__atomic_load_n(&done, __ATOMIC_ACQUIRE));
    return NULL;
}

int main(void) {
    const uint64_t caps[] = {1, 17, 64};
    for (uint32_t variant = RING_VAR_INT; variant <= RING_VAR_F64; variant++) {
        for (unsigned c = 0; c < sizeof(caps) / sizeof(caps[0]); c++) {
            char err[RING_ERR_BUFLEN];
            h = ring_create(NULL, caps[c], 8, variant, 0600, err);
            if (!h) { fprintf(stderr, "%s\n", err); return 2; }
            done = bad = 0;
            samples = 0;
            uint64_t v = value(0);
            ring_write(h, &v, sizeof(v));
            pthread_t thread;
            if (pthread_create(&thread, NULL, reader, NULL)) return 3;
            for (uint64_t seq = 1; seq < 200000; seq++) {
                v = value(seq);
                if (ring_write(h, &v, sizeof(v)) != seq) return 4;
            }
            __atomic_store_n(&done, 1, __ATOMIC_RELEASE);
            pthread_join(thread, NULL);
            if (bad || !samples) return 5;
            for (uint64_t seq = ring_head(h) - caps[c]; seq < ring_head(h); seq++) {
                uint64_t got;
                if (!ring_read_seq(h, seq, &got) || got != value(seq)) return 6;
            }
            ring_destroy(h);
        }
    }
    return 0;
}
C
close $fh or die $!;
system shellwords($Config{cc}), '-D_GNU_SOURCE', '-O2', '-pthread', '-I.',
    '-o', "$dir/slots", "$dir/slots.c";
is $?, 0, 'slot sequence harness compiled' or BAIL_OUT('compile failed');
system { "$dir/slots" } "$dir/slots";
is $?, 0, 'concurrent reads match their exact publication sequence for both variants';
done_testing;
