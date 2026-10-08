use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::HashMap::Shared::II;

# A process crashing while recovering a stale lock must leave it recoverable:
# shm_recover_stale_lock takes it as our own pid, since a bare WRITER_BIT reads
# as always alive to shm_pid_alive and would hang forever. The true window is a
# few instructions wide, so this runs the common trigger path: SIGKILL during
# writes.

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";
my $m = Data::HashMap::Shared::II->new($path, 1024);

my $child = fork // die;
if ($child == 0) {
    my $c = Data::HashMap::Shared::II->new($path, 1024);
    for (1..100_000) { $c->put($_ % 500, $_) }   # be under the lock when killed
    _exit(0);
}
select undef, undef, undef, 0.05;
kill 9, $child;
waitpid $child, 0;

my $t0 = time;
$m->put(999, 42);
my $dt = time - $t0;
is $m->get(999), 42, 'write succeeded after child crash';
ok $dt < 5, sprintf('recovery path completed in %.2fs', $dt);

unlink $path;
done_testing;
