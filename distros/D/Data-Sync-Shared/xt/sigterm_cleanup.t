use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Sync::Shared;

# A surviving process must still operate after a peer receives SIGTERM.

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";
my $sem = Data::Sync::Shared::Semaphore->new($path, 2);

my $pid = fork // die;
if ($pid == 0) {
    my $c = Data::Sync::Shared::Semaphore->new($path, 2);
    $c->acquire;
    # Suspend here; parent will SIGTERM us
    sleep 60;
    _exit(0);
}

select undef, undef, undef, 0.2;
kill TERM => $pid;
waitpid $pid, 0;

# Parent should still operate.
my $t0 = time;
my $got = $sem->acquire(2.0);
my $dt = time - $t0;
ok $got, 'acquire succeeded after child SIGTERM';
ok $dt < 3, sprintf('no deadlock (%.2fs)', $dt);

unlink $path;
done_testing;
