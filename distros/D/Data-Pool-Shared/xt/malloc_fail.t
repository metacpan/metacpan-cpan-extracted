use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use Data::Pool::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'requires gcc' unless `which gcc` =~ /\S/;

# Inject malloc() failure via LD_PRELOAD and verify OOM paths croak
# cleanly instead of crashing.

my $dir = tempdir(CLEANUP => 1);
my $src = "$dir/fail_malloc.c";
my $lib = "$dir/fail_malloc.so";

open my $fh, '>', $src or die;
print $fh <<'END';
#define _GNU_SOURCE
#include <stdlib.h>
#include <stdatomic.h>
#include <dlfcn.h>

/* Fail every Nth malloc where N = $ENV{MALLOC_FAIL_EVERY}, if set. */
static atomic_long counter;
static long threshold = 0;

__attribute__((constructor))
static void init(void) {
    const char *s = getenv("MALLOC_FAIL_EVERY");
    if (s) threshold = atol(s);
}

void *malloc(size_t sz) {
    static void *(*real)(size_t) = NULL;
    if (!real) real = dlsym(RTLD_NEXT, "malloc");
    if (threshold > 0) {
        long c = atomic_fetch_add(&counter, 1);
        if ((c % threshold) == (threshold - 1)) return NULL;
    }
    return real(sz);
}
END
close $fh;

my $rc = system("gcc -O2 -fPIC -shared -o $lib $src -ldl 2>$dir/build.log");
if ($rc != 0) {
    diag `cat $dir/build.log`;
    plan skip_all => 'failed to build LD_PRELOAD lib';
}

# Invoke a child Perl that opens a Pool and pushes enough to trigger
# malloc failures. The module should croak instead of crash.
my $testprog = <<'END';
use Data::Pool::Shared;
my $p = Data::Pool::Shared->new(undef, 100, 64);
eval {
    for (1..50) {
        my $s = $p->alloc_set("x" x 60, 1.0);
    }
};
# Either all ops succeeded (malloc never failed at a sensitive point)
# or we got a croak. Both are fine — crash would be an abort signal.
print $@ ? "croak: $@\n" : "ok\n";
END

# Fail 1-in-1000: high enough to hit alloc_set internals, low enough
# to let Perl boot. Perl handles OOM via its own safesysmalloc wrapper
# (prints "Out of memory" and exits non-zero — not a crash).
my $result = `LD_PRELOAD=$lib MALLOC_FAIL_EVERY=1000 $^X -Mblib -e '$testprog' 2>&1`;
my $exit = $? >> 8;
my $signaled = $? & 127;

is $signaled, 0, "child did not crash on signal (got exit=$exit, signal=$signaled)";
ok $result =~ /(ok|croak:|Out of memory|EXCEPTION)/,
    "child produced recognised output (ok / croak / Perl OOM abort)";
diag $result if $signaled != 0;

done_testing;
