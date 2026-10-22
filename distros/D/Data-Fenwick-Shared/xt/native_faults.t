use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $root = dirname(dirname(abs_path(__FILE__)));
my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/faults.c" or die $!;
print {$fh} <<'C';
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <errno.h>
static int fail_path, fail_handle, reserve_error, reserve_calls;
static char *fault_strdup(const char *p) {
    if (fail_path) { errno = ENOMEM; return NULL; }
    return strdup(p);
}
static void *fault_calloc(size_t n, size_t size) {
    if (fail_handle) { errno = ENOMEM; return NULL; }
    return calloc(n, size);
}
static int fault_fallocate(int fd, off_t off, off_t len) {
    (void)fd; (void)off; (void)len;
    reserve_calls++;
    return reserve_error == EINTR && reserve_calls > 1 ? 0 : reserve_error;
}
#define strdup fault_strdup
#define calloc fault_calloc
#define posix_fallocate fault_fallocate
#include "fenwick.h"
#define CHECK(x) do { if (!(x)) { printf("failed: %s (line %d)\n", #x, __LINE__); return 1; } } while (0)
int main(int argc, char **argv) {
    CHECK(argc == 3);
    char err[FEN_ERR_BUFLEN], path[PATH_MAX];
    snprintf(path, sizeof path, "%s/%s.fen", argv[2], argv[1]);
    if (!strcmp(argv[1], "allocation")) {
        for (int kind = 0; kind < 2; kind++) {
            uint64_t size = fen_total_size(8, FEN_MODE_POINT);
            int fd = memfd_create("faults", MFD_CLOEXEC);
            CHECK(fd >= 0 && ftruncate(fd, size) == 0);
            void *base = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
            CHECK(base != MAP_FAILED);
            fen_init_header(base, 8, FEN_MODE_POINT, size);
            fail_path = kind == 0; fail_handle = kind == 1;
            FenHandle *h = fen_setup(base, size, path, fd);
            if (h) fen_destroy(h);
            CHECK(h == NULL);
            CHECK(fcntl(fd, F_GETFD) == -1 && errno == EBADF);
            unsigned char vec;
            CHECK(mincore(base, 1, &vec) == -1 && errno == ENOMEM);
            fail_path = fail_handle = 0;
        }
        return 0;
    }
    reserve_error = !strcmp(argv[1], "unsupported") ? EOPNOTSUPP :
                    !strcmp(argv[1], "invalid") ? EINVAL :
                    !strcmp(argv[1], "full") ? ENOSPC : EINTR;
    unsetenv("DATA_FENWICK_SHARED_SPARSE");
    CHECK(fen_reserve(-1, 4096) == 0 && reserve_calls == 0);
    setenv("DATA_FENWICK_SHARED_SPARSE", "0", 1);
    sigset_t before, after;
    CHECK(sigprocmask(SIG_BLOCK, NULL, &before) == 0);
    int rc = fen_reserve(-1, 4096);
    if (reserve_error == EINTR) {
        CHECK(rc == 0 && reserve_calls == 2);
    } else {
        CHECK(rc == -1 && errno == reserve_error);
        for (uint32_t mode = FEN_MODE_POINT; mode <= FEN_MODE_RANGE; mode++) {
            FenHandle *h = fen_create(path, 8, mode, 0600, err);
            if (h) fen_destroy(h);
            CHECK(h == NULL && strstr(err, strerror(reserve_error)));
            struct stat st;
            CHECK(stat(path, &st) == 0 && st.st_size == 0);
            h = fen_create_memfd("faults", 8, mode, err);
            if (h) fen_destroy(h);
            CHECK(h == NULL && strstr(err, strerror(reserve_error)));
        }
        reserve_error = 0;
        FenHandle *h = fen_create(path, 8, FEN_MODE_POINT, 0600, err);
        CHECK(h != NULL);
        fen_destroy(h);
    }
    CHECK(sigprocmask(SIG_BLOCK, NULL, &after) == 0);
    for (int sig = 1; sig < NSIG; sig++)
        CHECK(sigismember(&before, sig) == sigismember(&after, sig));
    return 0;
}
C
close $fh or die $!;
my @cc = (shellwords($Config{cc}), shellwords($Config{ccflags}),
          shellwords($Config{optimize}),
          shellwords($ENV{FEN_NATIVE_CCFLAGS} || ''),
          '-pthread', "-I$root", "$dir/faults.c", '-o', "$dir/faults");
system(@cc) == 0 or BAIL_OUT('native fault fixture did not compile');
for my $case (qw(allocation unsupported invalid full interrupted)) {
    open my $out, '-|', "$dir/faults", $case, $dir or die $!;
    my $text = do { local $/; <$out> };
    close $out;
    is $?, 0, "native failure handling: $case" or diag $text;
}
done_testing;
