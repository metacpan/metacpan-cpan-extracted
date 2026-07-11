use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

# Regression for the slotless-reader force-reset race: when the per-process
# reader-slot table is full a reader holds the rwlock word with no slot and is
# invisible to dead-reader recovery, which could then force-reset the lock out
# from under it and admit a writer (writer-exclusion violation). Reproduced by
# compiling radix.h with RDX_READER_SLOTS=1 so the 2nd reader goes slotless.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} || 'cc';
system("$cc --version >/dev/null 2>&1") == 0
    or plan skip_all => "no working C compiler ($cc)";
-f 'radix.h' or plan skip_all => 'run from the distribution root (radix.h not found)';

my $dir = tempdir(CLEANUP => 1);
my $src = "$dir/repro.c";
open my $fh, '>', $src or die $!;
print $fh <<'C';
#include <stdio.h>
#include <string.h>
#include <signal.h>
#include <sys/wait.h>
#include <sys/mman.h>
#include <time.h>
#include "radix.h"
struct flags { int reader_active, writer_active, violation, b_holds, a_holds; };
static struct flags *F; static RdxHandle *L;
int main(void) {
    char eb[256];
    L = rdx_create(NULL, 1024, 65536, 0600, eb);   /* anonymous: mode unused but signature requires it */
    if (!L) { fprintf(stderr, "create: %s\n", eb); return 2; }
    F = mmap(NULL, sizeof *F, PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
    memset(F, 0, sizeof *F);
    pid_t a = fork();
    if (a == 0) { rdx_rwlock_rdlock(L);
        __atomic_store_n(&F->a_holds, 1, __ATOMIC_RELEASE);
        for (;;) { struct timespec t={1,0}; nanosleep(&t,0); } }
    while (!__atomic_load_n(&F->a_holds, __ATOMIC_ACQUIRE)) { struct timespec t={0,1000000}; nanosleep(&t,0); }
    pid_t b = fork();
    if (b == 0) { rdx_rwlock_rdlock(L);
        __atomic_add_fetch(&F->reader_active, 1, __ATOMIC_RELEASE);
        __atomic_store_n(&F->b_holds, 1, __ATOMIC_RELEASE);
        for (int i=0;i<700;i++){ if(__atomic_load_n(&F->writer_active,__ATOMIC_ACQUIRE)) __atomic_store_n(&F->violation,1,__ATOMIC_RELEASE);
            struct timespec t={0,10000000}; nanosleep(&t,0); }
        __atomic_sub_fetch(&F->reader_active,1,__ATOMIC_RELEASE); rdx_rwlock_rdunlock(L); _exit(0); }
    while (!__atomic_load_n(&F->b_holds, __ATOMIC_ACQUIRE)) { struct timespec t={0,1000000}; nanosleep(&t,0); }
    kill(a, SIGKILL); waitpid(a, NULL, 0);
    pid_t c = fork();
    if (c == 0) { rdx_rwlock_wrlock(L);
        __atomic_store_n(&F->writer_active,1,__ATOMIC_RELEASE);
        if (__atomic_load_n(&F->reader_active,__ATOMIC_ACQUIRE) > 0) __atomic_store_n(&F->violation,1,__ATOMIC_RELEASE);
        struct timespec t={0,200000000}; nanosleep(&t,0);
        __atomic_store_n(&F->writer_active,0,__ATOMIC_RELEASE); rdx_rwlock_wrunlock(L); _exit(0); }
    waitpid(c, NULL, 0); kill(b, SIGKILL); waitpid(b, NULL, 0);
    int v = __atomic_load_n(&F->violation, __ATOMIC_ACQUIRE);
    printf("violation=%d -> %s\n", v, v ? "VIOLATION" : "ok");
    return v ? 1 : 0;
}
C
close $fh;

my $bin = "$dir/repro";
my $log = `$cc -O2 -D_GNU_SOURCE -DRDX_READER_SLOTS=1 -I. -o $bin $src -lpthread  2>&1`;
is($?, 0, 'reduced-slot harness compiles') or BAIL_OUT("compile failed:\n$log");

for my $run (1 .. 4) {
    my $rc = -1;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 40;
        $rc = system($bin);
        alarm 0;
    };
    is($rc, 0, "run $run: no writer-exclusion violation under a slotless reader")
        or diag("harness exit=$rc ($@)");
}
done_testing;
