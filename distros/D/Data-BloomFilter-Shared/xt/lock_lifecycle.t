use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'requires Linux /proc' unless $^O eq 'linux' && -r '/proc/self/stat';

my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/lock.c" or die $!;
print {$fh} <<'C';
#include <sys/wait.h>
#include "bloom.h"

static int reaped(pid_t pid) {
    int status;
    return waitpid(pid, &status, 0) == pid && status == 0;
}

static int dead_owner(BfHandle *h, int reader) {
    int ready[2];
    if (pipe(ready)) return 1;
    pid_t pid = fork();
    if (pid < 0) return 1;
    if (!pid) {
        alarm(10);
        close(ready[0]);
        if (reader) bf_rwlock_rdlock(h); else bf_rwlock_wrlock(h);
        if (write(ready[1], "x", 1) != 1) _exit(1);
        for (;;) pause();
    }
    close(ready[1]);
    char byte;
    int notified = read(ready[0], &byte, 1) == 1;
    close(ready[0]);
    kill(pid, SIGKILL);
    for (int i = 0; i < 1000 && !bf_pid_is_zombie((uint32_t)pid); i++) usleep(1000);
    int zombie = bf_pid_is_zombie((uint32_t)pid);
    if (notified && zombie) {
        bf_rwlock_wrlock(h);
        bf_add_locked(h, "recovered", 9);
        bf_rwlock_wrunlock(h);
    }
    waitpid(pid, NULL, 0);
    return !notified || !zombie || !bf_contains_locked(h, "recovered", 9);
}

static int mixed(BfHandle *h) {
    pid_t kids[6];
    uint64_t *bits = bf_bits(h);
    bits[0] = bits[1] = 0;
    for (int k = 0; k < 6; k++) {
        kids[k] = fork();
        if (kids[k] < 0) return 1;
        if (!kids[k]) {
            alarm(15);
            for (int i = 0; i < 20000; i++) {
                if (k < 3) {
                    bf_rwlock_wrlock(h);
                    bits[0]++;
                    bits[1] = bits[0];
                    bf_rwlock_wrunlock(h);
                } else {
                    bf_rwlock_rdlock(h);
                    int mismatch = bits[0] != bits[1];
                    bf_rwlock_rdunlock(h);
                    if (mismatch) _exit(1);
                }
            }
            _exit(0);
        }
    }
    int ok = 1;
    for (int k = 0; k < 6; k++) ok &= reaped(kids[k]);
    return !ok || bits[0] != 60000 || bits[1] != bits[0];
}

int main(int argc, char **argv) {
    alarm(25);
    char err[BF_ERR_BUFLEN];
    BfHandle *h = bf_create(NULL, 1000, 0.01, 0600, err);
    if (!h || argc != 2) return 2;
    bf_rwlock_rdlock(h);
    bf_rwlock_rdunlock(h);
    int failed;
    if (!strcmp(argv[1], "fork-destroy")) {
        uint32_t slot = h->my_slot_idx;
        pid_t pid = fork();
        if (!pid) { bf_destroy(h); _exit(0); }
        failed = pid < 0 || !reaped(pid) || h->reader_slots[slot].pid != (uint32_t)getpid()
            || !(h->occ[slot >> 6] & (1ULL << (slot & 63)));
    } else if (!strcmp(argv[1], "dead-reader")) failed = dead_owner(h, 1);
    else if (!strcmp(argv[1], "dead-writer")) failed = dead_owner(h, 0);
    else failed = mixed(h);
    bf_destroy(h);
    return failed;
}
C
close $fh or die $!;
my @cc = shellwords($Config{cc} || 'cc');
is system(@cc, '-O2', '-D_GNU_SOURCE', '-I.', "$dir/lock.c", '-o', "$dir/lock", '-lm', '-lpthread'),
    0, 'lock lifecycle harness compiles' or BAIL_OUT('compile failed');
for my $case (qw(fork-destroy dead-reader dead-writer mixed)) {
    is system("$dir/lock", $case), 0, "$case preserves lock ownership and exclusion";
}
done_testing;
