use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $dir = tempdir(CLEANUP => 1);
open my $src, '>', "$dir/wakeup.c" or die $!;
print {$src} <<'C';
#include "topk.h"
#include <stdarg.h>

static TkHeader hdr;
static TkHandle h = { .hdr = &hdr };
static pthread_barrier_t start, end;
static unsigned woke, held;
static const unsigned loops = 300000;

long __wrap_syscall(long number, ...) {
    va_list args;
    va_start(args, number);
    uint32_t *addr = va_arg(args, uint32_t *);
    int op = va_arg(args, int);
    va_end(args);
    if (number != SYS_futex || addr != &hdr.wlock || op != FUTEX_WAKE) abort();
    woke = 1;
    return 0;
}

static void *unlocker(void *unused) {
    for (unsigned i = 0; i < loops; i++) {
        pthread_barrier_wait(&start);
        tk_rwlock_wrunlock(&h);
        pthread_barrier_wait(&end);
    }
    return NULL;
}

static void *waiter(void *unused) {
    for (unsigned i = 0; i < loops; i++) {
        pthread_barrier_wait(&start);
        tk_park(&h);
        held = __atomic_load_n(&hdr.wlock, __ATOMIC_RELAXED);
        pthread_barrier_wait(&end);
    }
    return NULL;
}

int main(void) {
    alarm(45);
    pthread_t a, b;
    if (pthread_barrier_init(&start, NULL, 3) || pthread_barrier_init(&end, NULL, 3)) return 2;
    if (pthread_create(&a, NULL, unlocker, NULL) || pthread_create(&b, NULL, waiter, NULL)) return 2;
    unsigned missed = 0;
    for (unsigned i = 0; i < loops; i++) {
        hdr.wlock = TK_RWLOCK_WR(1);
        hdr.rwait = woke = held = 0;
        pthread_barrier_wait(&start);
        pthread_barrier_wait(&end);
        if (held && !woke) missed++;
    }
    pthread_join(a, NULL);
    pthread_join(b, NULL);
    printf("%u missed wakes in %u races\n", missed, loops);
    return missed != 0;
}
C
close $src or die $!;
my @cc = shellwords($Config{cc});
my @flags = shellwords($Config{ccflags});
my $built = system(@cc, @flags, '-D_GNU_SOURCE', '-O2', '-pthread', '-I' . abs_path('.'),
    "$dir/wakeup.c", '-o', "$dir/wakeup", '-Wl,--wrap=syscall', '-lm') == 0;
ok $built, 'build lock wake-up race test';
if ($built) {
    my $out = `"$dir/wakeup" 2>&1`;
    my $status = $?;
    is $status, 0, 'every waiter sees an unlocked gate or receives a wake' or diag $out;
}
done_testing;
