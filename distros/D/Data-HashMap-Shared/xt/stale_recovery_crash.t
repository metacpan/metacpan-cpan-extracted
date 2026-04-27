use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::HashMap::Shared::II;

# Regression: Pass 14 — if the process recovering a stale lock itself
# crashes mid-recovery, the lock must remain recoverable.
# Pre-fix: shm_recover_stale_lock held lock as bare WRITER_BIT (PID=0),
# which shm_pid_alive treated as always alive, causing permanent hang.

# This regression is hard to trigger deterministically — it requires a
# crash in the ~5 instruction window between CAS and seqlock-fix + release.
# Best we can do in a portable test: verify that basic operations succeed
# after a forced SIGKILL during writes, which is the common trigger path.

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";
my $m = Data::HashMap::Shared::II->new($path, 1024);

my $child = fork // die;
if ($child == 0) {
    my $c = Data::HashMap::Shared::II->new($path, 1024);
    # Hammer many writes to maximize chance of being killed mid-lock
    for (1..100_000) { $c->put($_ % 500, $_) }
    _exit(0);
}
select undef, undef, undef, 0.05;
kill 9, $child;
waitpid $child, 0;

# Parent should be able to proceed. If recovery was ever needed and the
# recovering process (parent, on next access) crashed, the lock would be
# stuck at bare WRITER_BIT forever. With Pass 14 fix, recovery uses our
# own PID, making it re-recoverable.
my $t0 = time;
$m->put(999, 42);
my $dt = time - $t0;
is $m->get(999), 42, 'write succeeded after child crash';
ok $dt < 5, sprintf('recovery path completed in %.2fs', $dt);

unlink $path;
done_testing;
