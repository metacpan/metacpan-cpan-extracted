use strict;
use warnings;
use Test::More;
use Config;
use Cwd ();
use File::Temp ();

my $perl = $Config{perlpath} || $^X;   # real ELF binary: a plenv shim breaks LD_PRELOAD
my $cc = $Config{cc} || 'cc';
my $tsan_lib = `$cc -print-file-name=libtsan.so 2>/dev/null`;
chomp $tsan_lib;

plan skip_all => 'libtsan not found' unless $tsan_lib && -f $tsan_lib;
plan skip_all => 'set TSAN=1 to run' unless $ENV{TSAN};

my $root = Cwd::getcwd();

# ----------------------------------------------------------------------------
# I2 (targeted): add_used is stored by range_add/clear UNDER the write lock, but
# monoids_valid (Shared.xs) reads it with an UNLOCKED __atomic_load.  The store
# MUST therefore be atomic too, or store-vs-load is a C11 data race.
#
# ThreadSanitizer cannot see cross-PROCESS races (each process has its own shadow
# memory), and this module shares state across processes -- so a fork-based test
# would prove nothing.  Instead exercise the exact same C accesses with two
# pthreads in ONE process: a reader thread doing the unlocked atomic load that
# monoids_valid does, and a writer thread storing add_used under the write lock
# via range_add/clear.  With the atomic store the pair is race-free; a plain store
# is a data race TSAN flags right here.
# ----------------------------------------------------------------------------
{
    my $src = <<'TSAN_SRC';
/* _GNU_SOURCE is supplied on the compile line (-D_GNU_SOURCE), as in the XS build */
#include "segtree.h"
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define ST_N 4096
static StHandle *H;
static int stopf = 0;

/* Exactly what monoids_valid does: an UNLOCKED relaxed atomic load of add_used. */
static void *reader(void *arg) {
    (void)arg;
    long seen = 0;
    while (!__atomic_load_n(&stopf, __ATOMIC_RELAXED))
        seen += (int)__atomic_load_n(&H->hdr->add_used, __ATOMIC_RELAXED);
    return (void *)seen;
}

/* Exactly what range_add / clear do: store add_used under the write lock. */
static void *writer(void *arg) {
    long iters = (long)(intptr_t)arg;
    for (long i = 0; i < iters; i++) {
        st_rwlock_wrlock(H);
        st_range_add_locked(H, 0, ST_N - 1, 1);   /* add_used = 1 */
        st_rwlock_wrunlock(H);
        if ((i & 63) == 0) {
            st_rwlock_wrlock(H);
            st_clear_locked(H);                    /* add_used = 0 */
            st_rwlock_wrunlock(H);
        }
    }
    __atomic_store_n(&stopf, 1, __ATOMIC_RELAXED);
    return NULL;
}

int main(void) {
    char err[ST_ERR_BUFLEN];
    H = st_create(NULL, ST_N, 0600, err);          /* anonymous shared mapping */
    if (!H) { fprintf(stderr, "st_create: %s\n", err); return 2; }
    pthread_t rt, wt;
    if (pthread_create(&rt, NULL, reader, NULL)) return 2;
    if (pthread_create(&wt, NULL, writer, (void *)(intptr_t)200000)) return 2;
    pthread_join(wt, NULL);
    pthread_join(rt, NULL);
    st_destroy(H);
    fprintf(stderr, "OK\n");
    return 0;
}
TSAN_SRC

    my $dir = File::Temp->newdir();
    my $cfile = "$dir/tsan_addused.c";
    my $exe = "$dir/tsan_addused";
    open my $fh, '>', $cfile or die "write $cfile: $!";
    print $fh $src;
    close $fh;

    my $compile = "$cc -D_GNU_SOURCE -I\Q$root\E -O1 -g -fsanitize=thread "
                . "-fno-omit-frame-pointer -o \Q$exe\E \Q$cfile\E -lpthread 2>&1";
    my $cout = `$compile`;
    if (-x $exe) {
        my $out = `TSAN_OPTIONS='halt_on_error=1 exitcode=66' \Q$exe\E 2>&1`;
        my $rc = $?;
        diag $out;
        is $rc, 0, 'I2: concurrent add_used store/load harness exited 0';
        unlike $out, qr/ThreadSanitizer:|data race/,
            'I2: ThreadSanitizer reports NO data race on add_used (atomic store)';
        like $out, qr/^OK$/m, 'I2: harness ran to completion';
    } else {
        fail "I2 harness failed to compile";
        diag "$compile\n$cout";
    }
}

# ----------------------------------------------------------------------------
# Broad smoke check: rebuild the XS with TSan and run the whole t/ suite under it.
# (Single-process/single-threaded, so it does not exercise the add_used race
# above -- that is what the pthread harness is for -- but it catches any other
# TSan-visible issue in the XS layer.)
# ----------------------------------------------------------------------------
my $build = `make clean 2>/dev/null; $perl Makefile.PL OPTIMIZE='-O1 -g -fsanitize=thread -fno-omit-frame-pointer' 2>&1 && make 2>&1`;
like $build, qr/Shared\.o/, 'TSan build succeeded'
    or BAIL_OUT("TSan build failed:\n$build");

my @tests = sort glob("t/*.t");
for my $t (@tests) {
    (my $name = $t) =~ s{.*/}{};
    my $out = `LD_PRELOAD=$tsan_lib TSAN_OPTIONS='halt_on_error=1 second_deadlock_stack=1' $perl -Mblib $t 2>&1`;
    my $ok = ($? == 0);
    ok $ok, "tsan: $name" or diag $out;
}

diag "rebuilding without TSan...";
`make clean 2>/dev/null; $perl Makefile.PL 2>&1 && make 2>&1`;

done_testing;
