use strict;
use warnings;
use Config;
use FindBin;
use lib "$FindBin::Bin/lib";
use Instrumented;
use Test::More;
use File::Temp qw(tempdir);
use Text::ParseWords qw(shellwords);

my $tmp = tempdir(CLEANUP => 1);
open my $fh, '>', "$tmp/io.c" or die $!;
print {$fh} <<'C';
#include "phash.h"
static ssize_t fault_write(int, const void *, size_t);
static int fault_close(int);
static int fault_rename(const char *, const char *);
#define write fault_write
#define close fault_close
#define rename fault_rename
#define croak(...) abort()
#include "chd.h"
#undef write
#undef close
#undef rename

static const char *fault;
static ssize_t fault_write(int fd, const void *p, size_t n) {
    if (!strcmp(fault, "eintr")) {
        fault = "normal"; errno = EINTR; return -1;
    }
    if (!strcmp(fault, "write")) { errno = EIO; return -1; }
    if (!strcmp(fault, "zero")) { errno = 0; return 0; }
    if (!strcmp(fault, "short") && n > 1) n /= 2;
    return write(fd, p, n);
}
static int fault_close(int fd) {
    int rc = close(fd);
    if (!strcmp(fault, "close")) { errno = EIO; return -1; }
    return rc;
}
static int fault_rename(const char *from, const char *to) {
    if (!strcmp(fault, "rename")) { errno = EACCES; return -1; }
    return rename(from, to);
}
int main(int argc, char **argv) {
    if (argc != 3) return 2;
    char err[256] = {0};
    PhBuilder *b = ph_builder_new(PH_TYPE_INT);
    ph_builder_add_int(b, 42);
    fault = "normal";
    if (ph_build(b, argv[1], 0600, err, sizeof err)) return 3;
    PhSet *old = ph_open(argv[1], err, sizeof err);
    if (!old) return 4;
    ph_builder_add_int(b, 43);
    fault = argv[2];
    int rc = ph_build(b, argv[1], 0600, err, sizeof err);
    int success = !strcmp(argv[2], "normal") || !strcmp(argv[2], "eintr") || !strcmp(argv[2], "short");
    if ((rc == 0) != success) { fprintf(stderr, "unexpected rc=%d: %s\n", rc, err); return 5; }
    if (!success && !strstr(err, argv[2][0] == 'z' ? "write:" : argv[2])) return 6;
    if (!strcmp(argv[2], "zero") && strstr(err, "Success")) return 7;
    PhSet *fresh = ph_open(argv[1], err, sizeof err);
    if (!fresh) return 8;
    int ok = fresh->hdr->n == (success ? 2u : 1u) && ph_has_int(fresh, 42)
          && ph_has_int(fresh, 43) == success
          && old->hdr->n == 1 && ph_has_int(old, 42) && !ph_has_int(old, 43);
    ph_close(fresh); ph_close(old); ph_builder_free(b);
    return ok ? 0 : 9;
}
C
close $fh or die $!;

my ($status, $output) = Instrumented::capture(
    shellwords($Config{cc}), '-std=gnu11', '-O2', "-I$FindBin::Bin/..",
    "$tmp/io.c", '-o', "$tmp/io",
);
is $status, 0, 'build I/O fault harness' or BAIL_OUT($output);
for my $fault (qw(normal eintr short write zero close rename)) {
    my $path = "$tmp/$fault.phs";
    ($status, $output) = Instrumented::capture("$tmp/io", $path, $fault);
    is $status, 0, "$fault: correct result and atomic replacement" or diag $output;
    is_deeply [glob "$path.tmp*"], [], "$fault: no temporary image left";
}
done_testing;
