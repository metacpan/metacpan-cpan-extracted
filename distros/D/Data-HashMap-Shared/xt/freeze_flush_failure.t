use strict;
use warnings;
use Test::More;
use Config;
use Errno ();
use File::Temp qw(tempdir);
use Data::HashMap::Shared::II;

# A freeze whose flush fails part-way must still leave every shard sealed, so
# each shard opens read-only and sync can finish the flush.  An LD_PRELOAD shim
# fails the second msync.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} || 'cc';
system("$cc --version >/dev/null 2>&1") == 0
    or plan skip_all => "no working C compiler ($cc)";

# The failure is forced by launching a child with LD_PRELOAD set to the msync
# shim, which would replace the ASan runtime the ASan job preloads through the
# same variable; the two cannot compose. The freeze-flush behaviour is covered
# in the plain and valgrind jobs.
plan skip_all => 'incompatible with an ASan LD_PRELOAD'
    if ($ENV{LD_PRELOAD} // '') =~ /asan/i;

my $dir = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/failmsync.c" or die $!;
print $fh <<'C';
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <stdlib.h>
static long seen;
int msync(void *addr, size_t len, int flags) {
    static int (*real)(void *, size_t, int);
    if (!real) real = (int (*)(void *, size_t, int))dlsym(RTLD_NEXT, "msync");
    const char *nth = getenv("FAIL_MSYNC_NTH");
    if (nth && ++seen == atol(nth)) { errno = EIO; return -1; }
    return real(addr, len, flags);
}
C
close $fh;
my $log = `$cc -O1 -fPIC -shared -o $dir/failmsync.so $dir/failmsync.c -ldl 2>&1`;
is $?, 0, 'msync shim compiles' or BAIL_OUT($log);

my $prefix = "$dir/set";
open $fh, '>', "$dir/child.pl" or die $!;
print $fh <<'PERL';
use strict; use warnings;
use Data::HashMap::Shared::II;
my ($prefix) = @ARGV;
my $m = Data::HashMap::Shared::II->new_sharded($prefix, 4, 64);
$m->put($_, $_) for 1 .. 100;
$ENV{FAIL_MSYNC_NTH} = 2;              # the second shard's flush fails
my $ok = eval { $m->freeze; 1 };
print $ok ? "froze\n" : "croaked: $@";
print eval { $m->sync; 1 } ? "synced\n" : "sync croaked: $@";
print eval { $m->freeze; 1 } ? "refroze\n" : "refreeze refused\n";
PERL
close $fh;

my $out = `LD_PRELOAD=$dir/failmsync.so $^X -Mblib $dir/child.pl $prefix 2>&1`;
my $eio = do { local $! = Errno::EIO(); "$!" };
like $out, qr/^croaked: .*freeze: msync: \Q$eio\E/m,
    'a failed flush makes freeze croak with the error'
    or diag $out;
like $out, qr/^synced$/m, '  ... and sync then finishes the flush';
like $out, qr/^refreeze refused$/m, '  ... and a second freeze refuses the set, sealed throughout';

for my $i (0 .. 3) {
    my $ro = eval { Data::HashMap::Shared::II->new_readonly("$prefix.$i") };
    ok $ro, "shard $i is sealed, so it opens read-only" or diag $@;
}

done_testing;
