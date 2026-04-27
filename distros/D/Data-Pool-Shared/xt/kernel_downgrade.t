use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Graceful kernel-feature downgrade: if memfd_create or MFD_ALLOW_SEALING
# is unavailable, the module should error cleanly (not segfault).
# We simulate via a child process with a restricted environment or by
# examining behavior on an old-kernel emulation.

plan skip_all => "set KERNEL_DOWNGRADE=1 and LD_PRELOAD to run"
    unless $ENV{KERNEL_DOWNGRADE};

use Data::Pool::Shared;

# Real test: LD_PRELOAD a stub that returns -ENOSYS for memfd_create.
# Build the stub on-demand for this test.

my $dir = tempdir(CLEANUP => 1);
my $stub_c = "$dir/stub.c";
open my $fh, '>', $stub_c or die;
print $fh <<'C_END';
#include <errno.h>
#include <sys/syscall.h>
long syscall(long num, ...) { errno = ENOSYS; return -1; }
int memfd_create(const char *name, unsigned int flags) { errno = ENOSYS; return -1; }
C_END
close $fh;

system("cc -shared -fPIC $stub_c -o $dir/stub.so") == 0
    or plan skip_all => "can't compile stub";

# Re-run this script with LD_PRELOAD=stub.so
my $pid = fork // die;
if (!$pid) {
    local $ENV{LD_PRELOAD} = "$dir/stub.so";
    my $rc = eval { Data::Pool::Shared->new_memfd("x", 1, 8) };
    exit(defined $rc ? 1 : 0);
}
waitpid $pid, 0;
is $? >> 8, 0, "graceful error under ENOSYS memfd_create";

done_testing;
