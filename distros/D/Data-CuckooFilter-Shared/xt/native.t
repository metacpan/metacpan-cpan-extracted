use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $dir = tempdir(CLEANUP => 1);
my $root = dirname(dirname(abs_path(__FILE__)));
open my $source, '>', "$dir/native.c" or die $!;
print {$source} do { local $/; <DATA> };
close $source or die $!;
my @sanitize = $ENV{CF_NATIVE_SANITIZE} ? ("-fsanitize=$ENV{CF_NATIVE_SANITIZE}") : ();
is system(shellwords($Config{cc}), '-D_GNU_SOURCE', '-std=c11', '-O2', '-g',
          "-I$root", @sanitize, "$dir/native.c", '-pthread', '-lm', '-o', "$dir/native"),
   0, 'compile native lock and rollback checks' or BAIL_OUT('native build failed');
is system("$dir/native"), 0, 'native lock and rollback checks';
done_testing;

__DATA__
#include "cuckoo.h"
#include <assert.h>
#include <sys/wait.h>

static CfHandle *make_filter(uint64_t capacity) {
    char err[CF_ERR_BUFLEN];
    CfHandle *h = cf_create(NULL, capacity, 0600, err);
    assert(h);
    return h;
}

static void reap(pid_t pid) {
    int status;
    assert(waitpid(pid, &status, 0) == pid);
    assert(status == 0);
}

static pid_t dead_pid(void) {
    pid_t pid = fork();
    assert(pid >= 0);
    if (!pid) _exit(0);
    reap(pid);
    return pid;
}

static void recovery(void) {
    CfHandle *h = make_filter(1000);
    uint32_t stale = CF_RWLOCK_WR(dead_pid());
    for (int interrupted = 0; interrupted < 2; interrupted++) {
        cf_rwlock_rdlock(h);
        h->hdr->count = 1;
        __atomic_store_n(&h->hdr->wlock, stale, __ATOMIC_SEQ_CST);
        pid_t pid = fork();
        assert(pid >= 0);
        if (!pid) {
            cf_recover_stale_lock(h, stale);
            _exit(0);
        }
        while (__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != CF_RWLOCK_WR(pid)) {
            assert(__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE) != 0);
            usleep(100);
        }
        assert(h->hdr->count == 1);   /* recovery must wait for the live reader */
        if (interrupted) {
            assert(kill(pid, SIGKILL) == 0);
            int status;
            assert(waitpid(pid, &status, 0) == pid);
            assert(WIFSIGNALED(status) && WTERMSIG(status) == SIGKILL);
        }
        cf_rwlock_rdunlock(h);
        if (!interrupted) reap(pid);
        cf_rwlock_wrlock(h);
        assert(h->hdr->count == 0);
        cf_rwlock_wrunlock(h);
    }
    pid_t reader = fork();
    assert(reader >= 0);
    if (!reader) { cf_rwlock_rdlock(h); _exit(0); }
    reap(reader);
    cf_rwlock_wrlock(h);
    assert(cf_add_locked(h, "after-reader", 12));
    cf_rwlock_wrunlock(h);
    cf_destroy(h);
}

static void rollback(void) {
    CfHandle *h = make_filter(1000);
    uint64_t bytes = cf_phys_buckets(h) * CF_SLOTS * sizeof(uint16_t);
    uint16_t *before = malloc(bytes);
    assert(before);
    cf_rwlock_wrlock(h);
    char key[32];
    unsigned failures = 0;
    for (int i = 0; i < 5000; i++) {
        int len = snprintf(key, sizeof key, "fill-%d", i);
        memcpy(before, cf_slots(h), bytes);
        uint64_t count = h->hdr->count;
        if (!cf_add_locked(h, key, len)) {
            failures++;
            assert(memcmp(before, cf_slots(h), bytes) == 0);
            assert(count == h->hdr->count);
        }
    }
    assert(failures > 0);
    cf_rwlock_wrunlock(h);
    free(before);
    cf_destroy(h);
}

static void contention(void) {
    CfHandle *h = make_filter(20000);
    cf_rwlock_wrlock(h);
    assert(cf_add_locked(h, "sentinel", 8));
    cf_rwlock_wrunlock(h);
    pid_t children[6];
    for (int k = 0; k < 6; k++) {
        children[k] = fork();
        assert(children[k] >= 0);
        if (!children[k]) {
            char key[32];
            for (int i = 0; i < 4000; i++) {
                if (k < 3) {
                    int len = snprintf(key, sizeof key, "writer-%d-%d", k, i);
                    cf_rwlock_wrlock(h);
                    assert(cf_add_locked(h, key, len));
                    cf_rwlock_wrunlock(h);
                } else {
                    cf_rwlock_rdlock(h);
                    assert(cf_contains_locked(h, "sentinel", 8));
                    cf_rwlock_rdunlock(h);
                }
            }
            _exit(0);
        }
    }
    for (int k = 0; k < 6; k++) reap(children[k]);
    cf_rwlock_rdlock(h);
    assert(h->hdr->count == 12001);
    for (int k = 0; k < 3; k++) {
        for (int i = 0; i < 4000; i++) {
            char key[32];
            int len = snprintf(key, sizeof key, "writer-%d-%d", k, i);
            assert(cf_contains_locked(h, key, len));
        }
    }
    cf_rwlock_rdunlock(h);
    cf_destroy(h);
}

int main(void) {
    alarm(30);
    recovery();
    rollback();
    contention();
    return 0;
}
