use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use ExtUtils::CBuilder;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
my $dir = tempdir(CLEANUP => 1);
my $root = dirname(dirname(abs_path(__FILE__)));
my $src = "$dir/reserve.c";
open my $fh, '>', $src or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE 1
#include <fcntl.h>
#include <errno.h>
static int failure, calls;
static int test_fallocate(int fd, off_t off, off_t len) {
    (void)fd; (void)off; (void)len;
    calls++;
    return failure;
}
#define posix_fallocate test_fallocate
#include "fenwick2d.h"
#define CHECK(test) do { if (!(test)) { fprintf(stderr, "line %d: %s\n", __LINE__, #test); return 1; } } while (0)

int main(int argc, char **argv) {
    char path[PATH_MAX], err[F2D_ERR_BUFLEN];
    CHECK(argc == 2);
    snprintf(path, sizeof path, "%s/grid", argv[1]);
    CHECK(setenv("DATA_FENWICK2D_SHARED_SPARSE", "0", 1) == 0);
    int errors[] = { ENOSPC, EOPNOTSUPP, EINVAL };
    for (unsigned i = 0; i < sizeof errors / sizeof errors[0]; i++) {
        failure = errors[i];
        F2dHandle *h = f2d_create(path, 8, 8, 0600, err);
        CHECK(!h && strstr(err, strerror(failure)));
        struct stat st;
        CHECK(stat(path, &st) == 0 && st.st_size == 0);
        h = f2d_create_memfd("reserve-test", 8, 8, err);
        CHECK(!h && strstr(err, strerror(failure)));
    }
    CHECK(calls == 6);
    CHECK(unsetenv("DATA_FENWICK2D_SHARED_SPARSE") == 0);
    F2dHandle *h = f2d_create(path, 8, 8, 0600, err);
    CHECK(h && calls == 6);
    f2d_destroy(h);
    CHECK(unlink(path) == 0);
    failure = 0;
    CHECK(setenv("DATA_FENWICK2D_SHARED_SPARSE", "0", 1) == 0);
    h = f2d_create(path, 8, 8, 0600, err);
    CHECK(h && calls == 7 && f2d_prefix_locked(h, 8, 8) == 0);
    f2d_destroy(h);
    CHECK(unlink(path) == 0);
    h = f2d_create_memfd("reserve-test", 8, 8, err);
    CHECK(h && calls == 8);
    f2d_destroy(h);
    return 0;
}
C
close $fh or die $!;
my $builder = ExtUtils::CBuilder->new(quiet => 1);
my $obj = $builder->compile(source => $src, include_dirs => [$root]);
my $exe = $builder->link_executable(objects => $obj, extra_linker_flags => '-pthread');
is system($exe, $dir), 0, 'reservation failures, cleanup, and sparse default';
done_testing;
