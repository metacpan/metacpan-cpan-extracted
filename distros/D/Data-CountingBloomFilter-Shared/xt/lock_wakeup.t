use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/wakeup.c" or die $!;
print {$fh} <<'C';
#include "cbf.h"
#include <sys/wait.h>

struct payload { uint64_t value, mirror; uint32_t start, bad; };
static pid_t kids[4];
static void timed_out(int sig) {
    (void)sig;
    for (int i = 0; i < 4; i++) if (kids[i] > 0) kill(kids[i], SIGKILL);
    for (int i = 0; i < 4; i++) if (kids[i] > 0) waitpid(kids[i], NULL, 0);
    _exit(2);
}
int main(void) {
    char err[CBF_ERR_BUFLEN];
    CbfHandle *h = cbf_create(NULL, 1000, 0.01, 0600, err);
    if (!h) { fprintf(stderr, "%s\n", err); return 1; }
    struct payload *p = mmap(NULL, sizeof *p, PROT_READ|PROT_WRITE,
                            MAP_SHARED|MAP_ANONYMOUS, -1, 0);
    if (p == MAP_FAILED) return 1;
    memset(p, 0, sizeof *p);
    p->mirror = ~p->value;
    signal(SIGALRM, timed_out);
    for (int k = 0; k < 4; k++) {
        kids[k] = fork();
        if (kids[k] < 0) timed_out(0);
        if (kids[k] == 0) {
            while (!__atomic_load_n(&p->start, __ATOMIC_ACQUIRE)) cbf_rwlock_spin_pause();
            for (int i = 0; i < 5000; i++) {
                if (k < 2) {
                    cbf_rwlock_wrlock(h);
                    if (p->mirror != ~p->value) __atomic_store_n(&p->bad, 1, __ATOMIC_RELAXED);
                    p->value++;
                    if (i % 500 == 0) usleep(1000);
                    p->mirror = ~p->value;
                    cbf_rwlock_wrunlock(h);
                } else {
                    cbf_rwlock_rdlock(h);
                    uint64_t value = p->value;
                    if (i % 500 == 0) usleep(1000);
                    if (p->value != value || p->mirror != ~value)
                        __atomic_store_n(&p->bad, 1, __ATOMIC_RELAXED);
                    cbf_rwlock_rdunlock(h);
                }
            }
            cbf_destroy(h);
            _exit(0);
        }
    }
    alarm(20);
    __atomic_store_n(&p->start, 1, __ATOMIC_RELEASE);
    int bad = 0;
    for (int k = 0; k < 4; k++) {
        int status = 0;
        if (waitpid(kids[k], &status, 0) != kids[k] || status) bad = 1;
        kids[k] = 0;
    }
    alarm(0);
    bad |= __atomic_load_n(&p->bad, __ATOMIC_RELAXED) || p->value != 10000;
    printf("writes=%llu, exclusion=%s\n", (unsigned long long)p->value, bad ? "failed" : "ok");
    cbf_destroy(h);
    munmap(p, sizeof *p);
    return bad;
}
C
close $fh or die $!;
my @cc = split /\s+/, $Config{cc};
is system(@cc, '-O2', '-D_GNU_SOURCE', '-I.', "$dir/wakeup.c", '-o', "$dir/wakeup", '-pthread', '-lm'),
   0, 'mixed reader/writer harness compiles' or BAIL_OUT('compile failed');
is system("$dir/wakeup"), 0, 'parked readers and draining writers wake and retain exclusion';
done_testing;
