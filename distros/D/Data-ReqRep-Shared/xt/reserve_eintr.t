use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

# Before Linux 6.11, fallocate on tmpfs and memfd fails with EINTR whenever a
# signal is pending and undoes what it allocated. A preloaded posix_fallocate
# acts that way.

plan skip_all => 'Linux only' unless $^O eq 'linux';
my $cc = $Config{cc} or plan skip_all => 'no C compiler';
system('timeout 1 true') == 0 or plan skip_all => 'needs timeout(1)';

my $root = dirname(dirname(abs_path(__FILE__)));
my $dir  = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/shim.c" or die $!;
print {$fh} <<'C';
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <signal.h>
#include <stddef.h>
#include <stdlib.h>
#include <sys/types.h>
static int stops = 1;
static int failure(void) {
    if (getenv("SHIM_ERR")) return atoi(getenv("SHIM_ERR"));
    sigset_t cur;
    sigprocmask(SIG_BLOCK, NULL, &cur);
    if (!sigismember(&cur, SIGALRM)) return EINTR;
    return stops-- > 0 ? EINTR : 0;
}
int posix_fallocate(int fd, off_t off, off_t len) {
    int e = failure();
    return e ? e : ((int (*)(int, off_t, off_t))dlsym(RTLD_NEXT, "posix_fallocate"))(fd, off, len);
}
int posix_fallocate64(int fd, long long off, long long len) {
    int e = failure();
    return e ? e : ((int (*)(int, long long, long long))dlsym(RTLD_NEXT, "posix_fallocate64"))(fd, off, len);
}
C
close $fh;
system($cc, '-shared', '-fPIC', '-o', "$dir/shim.so", "$dir/shim.c", '-ldl') == 0
    or plan skip_all => "cannot compile the shim with $cc";

open $fh, '>', "$dir/child.pl" or die $!;
print {$fh} <<'P';
use strict; use warnings;
use Data::ReqRep::Shared; use Data::ReqRep::Shared::Int;
my ($path, $class) = @ARGV;
$path = undef if $path eq q{memfd};
my $h = eval { $class eq q{Int} ? Data::ReqRep::Shared::Int->new($path, 16, 4)
                                : Data::ReqRep::Shared->new($path, 16, 4, 64) };
print $h ? "created\n" : "refused: $@";
P
close $fh;

my $ctl = qx{SHIM_ERR=28 LD_PRELOAD=$dir/shim.so timeout 20 $^X -I$root/blib/lib -I$root/blib/arch $dir/child.pl memfd Str 2>&1};
like $ctl, qr/No space left on device/, 'the shim reaches the reservation';

for my $case (["$dir/s.shm", 'Str'], ['memfd', 'Str'], ["$dir/i.shm", 'Int'], ['memfd', 'Int']) {
    my ($path, $class) = @$case;
    my $out = qx{LD_PRELOAD=$dir/shim.so timeout 20 $^X -I$root/blib/lib -I$root/blib/arch $dir/child.pl $path $class 2>&1};
    my $name = $path eq 'memfd' ? "$class memfd" : "$class file";
    like $out, qr/^created/, "$name: created while signals keep interrupting the reservation";
    diag $out unless $out =~ /^created/;
}

done_testing;
