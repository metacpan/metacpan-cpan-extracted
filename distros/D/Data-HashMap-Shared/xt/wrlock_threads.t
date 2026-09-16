use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

# Threads of one process share a pid, so only the process-local hold counts say
# which of them holds a map.  Threads with their own handles onto one map bump a
# plain counter under the write lock: an overlap or a lost update means two were
# inside at once, and a recovery with no dead process means a live lock was read
# as a stale one.  Also: threads contending on an own-pid ghost repair it once, a
# stale own-pid lock on a second map is repaired while the first is held, and a
# handle that reads without repairing anything takes no registry entry.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} || 'cc';
system("$cc --version >/dev/null 2>&1") == 0
    or plan skip_all => "no working C compiler ($cc)";
-f 'shm_generic.h' or plan skip_all => 'run from the distribution root (shm_generic.h not found)';

my $dir = tempdir(CLEANUP => 1);
my $src = "$dir/harness.c";
open my $fh, '>', $src or die $!;
print $fh <<'C';
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
typedef struct SV SV;
#include "shm_ii.h"

static long cycles;
static int unlocked;
static volatile long plain;
static int inside, overlap;

static ShmHandle *open_map(const char *p) {
    char eb[256];
    ShmHandle *h = shm_ii_create(p, 64, 0, 0, 0, 0, 0600, eb);
    if (!h) { fprintf(stderr, "open %s: %s\n", p, eb); exit(2); }
    return h;
}

static void *worker(void *arg) {
    ShmHandle *h = arg;
    for (long i = 0; i < cycles; i++) {
        if (!unlocked) shm_rwlock_wrlock(h);
        if (__atomic_add_fetch(&inside, 1, __ATOMIC_SEQ_CST) > 1)
            __atomic_store_n(&overlap, 1, __ATOMIC_SEQ_CST);
        plain = plain + 1;
        __atomic_sub_fetch(&inside, 1, __ATOMIC_SEQ_CST);
        if (!unlocked) shm_rwlock_wrunlock(h);
    }
    return NULL;
}

int main(int argc, char **argv) {
    if (argc >= 5 && !strcmp(argv[1], "race")) {
        const char *path = argv[2];
        const char *mode = argc > 5 ? argv[5] : "";
        int n = atoi(argv[3]);
        cycles = atol(argv[4]);
        unlocked = !strcmp(mode, "unlocked");
        unlink(path);
        ShmHandle *probe = open_map(path);
        pthread_t t[16];
        ShmHandle *hs[16];
        for (int i = 0; i < n; i++) hs[i] = open_map(path);
        if (!strcmp(mode, "ghost"))
            __atomic_store_n(&probe->hdr->wlock, SHM_RWLOCK_WR((uint32_t)getpid()), __ATOMIC_SEQ_CST);
        alarm(60);
        for (int i = 0; i < n; i++) pthread_create(&t[i], NULL, worker, hs[i]);
        for (int i = 0; i < n; i++) pthread_join(t[i], NULL);
        printf("lost=%ld overlap=%d recoveries=%u\n",
               (long)n * cycles - plain, overlap, probe->hdr->stat_recoveries);
        return 0;
    }
    if (argc == 4 && !strcmp(argv[1], "cross")) {
        unlink(argv[2]); unlink(argv[3]);
        ShmHandle *a = open_map(argv[2]), *b = open_map(argv[3]);
        __atomic_store_n(&b->hdr->wlock, SHM_RWLOCK_WR((uint32_t)getpid()), __ATOMIC_SEQ_CST);
        alarm(10);
        shm_rwlock_wrlock(a);
        int ok = shm_ii_put(b, 1, 42);
        shm_rwlock_wrunlock(a);
        printf("stored=%d recoveries=%u\n", ok, b->hdr->stat_recoveries);
        return 0;
    }
    if (argc == 3 && !strcmp(argv[1], "lazy")) {
        unlink(argv[2]);
        ShmHandle *w = open_map(argv[2]), *r = open_map(argv[2]);
        shm_ii_put(w, 1, 1);
        int64_t v = 0;
        shm_ii_get(r, 1, &v);
        shm_rwlock_rdlock(r); shm_rwlock_rdunlock(r);
        printf("reader_unresolved=%d writer_resolved=%d\n",
               r->wrlock_ent == SHM_WRLOCK_UNRESOLVED, w->wrlock_ent >= 0);
        return 0;
    }
    fprintf(stderr, "usage\n");
    return 2;
}
C
close $fh;

my $bin = "$dir/harness";
my $log = `$cc -O2 -D_GNU_SOURCE -I. -o $bin $src -lpthread 2>&1`;
is $?, 0, 'harness compiles' or BAIL_OUT("compile failed:\n$log");

sub run_harness {
    my @args = @_;
    my $out = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 60;
        $out = `$bin @args 2>&1`;
        alarm 0;
    };
    return $@ ? "timeout" : $out;
}

# A repairer once took a live lock of ours for a dead one in about a third of
# eight-thread runs, so twenty runs miss such a race about once in a thousand.
my $clean = 0;
for my $run (1 .. 20) {
    my $out = run_harness('race', "$dir/race.shm", 8, 500_000);
    if ($out =~ /^lost=0 overlap=0 recoveries=0$/m) { $clean++ } else { diag "run $run: $out" }
}
is $clean, 20, "eight threads never hold one map's write lock at once, nor repair a live one";

like run_harness('race', "$dir/ctl.shm", 4, 1_000_000, 'unlocked'), qr/lost=[1-9]|overlap=1/,
    'the oracle sees two threads inside at once when nothing locks';

like run_harness('race', "$dir/ghost.shm", 16, 20_000, 'ghost'), qr/^lost=0 overlap=0 recoveries=1$/m,
    'sixteen threads meeting an own-pid ghost repair it once, and only once';

like run_harness('cross', "$dir/a.shm", "$dir/b.shm"), qr/^stored=1 recoveries=1$/m,
    'a stale own-pid lock on a second map is repaired while the first is held';

like run_harness('lazy', "$dir/lazy.shm"), qr/^reader_unresolved=1 writer_resolved=1$/m,
    'a handle that only reads takes no registry entry; one that writes does';

done_testing;
