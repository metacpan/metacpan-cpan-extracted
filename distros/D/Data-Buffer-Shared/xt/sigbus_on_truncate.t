use strict;
use warnings;
use Test::More;

# Historical scenario: peer with SCM_RIGHTS-shared memfd ftruncate()s the
# backing region, making further mmap reads SIGBUS. With Pass 18's memfd
# sealing (F_SEAL_SHRINK | F_SEAL_GROW), adversarial ftruncate must fail
# rather than succeed-and-SIGBUS. This test verifies that defense.

use Data::Buffer::Shared;
use Data::Buffer::Shared::I64;

my $buf = Data::Buffer::Shared::I64->new_memfd("bus", 16);
$buf->set(0, 42);
my $fd = $buf->fd;

# Fork a child that inherits the fd (MFD_CLOEXEC applies at exec, not fork)
my $pid = fork // die "fork: $!";
if (!$pid) {
    # Child: attempt to shrink the backing file.
    open(my $fh, '+<&=', $fd) or exit 2;
    my $ok = truncate($fh, 0);
    exit($ok ? 1 : 0);  # sealed ⇒ !$ok ⇒ exit 0
}
waitpid $pid, 0;
my $rc = $? >> 8;
is $rc, 0, "adversarial ftruncate on sealed memfd rejected (child exit=$rc)";

# Parent's mmap still reads the original value; no SIGBUS.
is $buf->get(0), 42, "parent mmap still valid after adversarial attempt";

done_testing;
