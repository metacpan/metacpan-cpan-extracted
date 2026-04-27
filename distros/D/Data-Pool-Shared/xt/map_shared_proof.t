use strict;
use warnings;
use Test::More;
use Time::HiRes qw(usleep time);
use POSIX qw(_exit);

# MAP_SHARED proof: fork, parent writes V, child reads V via polling;
# child writes W, parent reads W. Catches a regression that would
# silently make IPC non-functional (MAP_PRIVATE instead of MAP_SHARED).

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("shared", 4);
my $sentinel = $p->alloc;
$p->set($sentinel, -1);

my $pid = fork // die;
if (!$pid) {
    my $p2 = Data::Pool::Shared::I64->new_from_fd($p->memfd);

    # Wait for parent to write 100
    my $deadline = time + 3;
    while (time < $deadline) {
        last if $p2->get($sentinel) == 100;
        usleep 1000;
    }
    _exit(10) unless $p2->get($sentinel) == 100;

    # Write 200 — parent will see this
    $p2->set($sentinel, 200);

    # Wait for parent to write 300 (handshake)
    $deadline = time + 3;
    while (time < $deadline) {
        last if $p2->get($sentinel) == 300;
        usleep 1000;
    }
    _exit(11) unless $p2->get($sentinel) == 300;
    _exit(0);
}

# Parent writes 100
$p->set($sentinel, 100);

# Wait for child to write 200
my $deadline = time + 3;
while (time < $deadline) {
    last if $p->get($sentinel) == 200;
    usleep 1000;
}
is $p->get($sentinel), 200, "parent sees child's write (MAP_SHARED bidirectional)";

# Parent writes 300
$p->set($sentinel, 300);

waitpid $pid, 0;
is $? >> 8, 0, "child exited cleanly after handshake";

done_testing;
