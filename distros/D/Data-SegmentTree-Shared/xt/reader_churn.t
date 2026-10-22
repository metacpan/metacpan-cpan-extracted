use strict;
use warnings;
use Test::More;
use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use ExtUtils::CBuilder;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

my $dir = tempdir(CLEANUP => 1);
my $src = "$dir/slots.c";
open my $fh, '>', $src or die $!;
print {$fh} <<'C';
#include "segtree.h"
#include <sys/wait.h>

static unsigned occupied(StHandle *h) {
    unsigned n = 0;
    for (unsigned i = 0; i < ST_OCC_WORDS; i++) n += __builtin_popcountll(h->occ[i]);
    return n;
}
static int reaped(pid_t pid) {
    int status;
    return waitpid(pid, &status, 0) == pid && status == 0;
}
static int fill(StHandle *h, int count, int abandon) {
    for (int i = 0; i < count; i++) {
        pid_t pid = fork();
        if (pid < 0) return 0;
        if (!pid) {
            st_rwlock_rdlock(h);
            if (!abandon) st_rwlock_rdunlock(h);
            _exit(0);
        }
        if (!reaped(pid)) return 0;
    }
    return occupied(h) == ST_READER_SLOTS;
}

int main(void) {
    alarm(30);
    char err[ST_ERR_BUFLEN];
    StHandle *h = st_create_memfd("slots", 64, err);
    if (!h) return 2;
    st_rwlock_rdlock(h); st_rwlock_rdunlock(h);
    for (int pass = 0; pass < 3; pass++) {
        if (!fill(h, ST_READER_SLOTS - 1, pass == 2)) return 3;
        StHandle *other = st_open_fd(h->backing_fd, err);
        if (!other) return 2;
        st_rwlock_rdlock(other); st_rwlock_rdunlock(other);
        if (occupied(h) != 2) return 4;
        st_destroy(other);
        if (occupied(h) != 1) return 5;
    }

    int ready[2], go[2], done[2];
    if (pipe(ready) || pipe(go) || pipe(done)) return 2;
    pid_t reader = fork();
    if (reader < 0) return 2;
    if (!reader) {
        close(go[1]);
        st_rwlock_rdlock(h);
        char c = 'r';
        if (write(ready[1], &c, 1) != 1 || read(go[0], &c, 1) != 1) _exit(2);
        st_rwlock_rdunlock(h);
        _exit(0);
    }
    close(go[0]);
    char c;
    if (read(ready[0], &c, 1) != 1 || !fill(h, ST_READER_SLOTS - 2, 0)) return 6;
    StHandle *other = st_open_fd(h->backing_fd, err);
    if (!other) return 2;
    st_rwlock_rdlock(other); st_rwlock_rdunlock(other);
    if (occupied(h) != 3) return 7;
    st_destroy(other);

    pid_t writer = fork();
    if (writer < 0) return 2;
    if (!writer) {
        st_rwlock_wrlock(h);
        st_range_add_locked(h, 0, 63, 1);
        st_rwlock_wrunlock(h);
        if (write(done[1], "w", 1) != 1) _exit(2);
        _exit(0);
    }
    while (!__atomic_load_n(&h->hdr->wlock, __ATOMIC_ACQUIRE)) usleep(1000);
    if (fcntl(done[0], F_SETFL, O_NONBLOCK) < 0) return 2;
    if (read(done[0], &c, 1) != -1 || errno != EAGAIN) return 8;
    if (write(go[1], "g", 1) != 1 || !reaped(reader) || !reaped(writer)) return 9;
    st_rwlock_rdlock(h);
    int64_t sum, mn, mx;
    st_query_locked(h, 0, 63, &sum, &mn, &mx);
    st_rwlock_rdunlock(h);
    if (sum != 64 || mn != 1 || mx != 1) return 10;
    st_destroy(h);
    return 0;
}
C
close $fh or die $!;

my $builder = ExtUtils::CBuilder->new(quiet => 1);
my $exe = eval {
    my $obj = $builder->compile(source => $src, include_dirs => [getcwd()],
        extra_compiler_flags => '-D_GNU_SOURCE -DST_READER_SLOTS=8 -O2 -fwrapv -pthread');
    $builder->link_executable(objects => $obj, extra_linker_flags => '-pthread');
};
ok $exe, 'reader-slot harness compiles' or BAIL_OUT($@);
is system($exe), 0, 'exited slots reclaimed; live readers preserved and writers wake';
done_testing;
