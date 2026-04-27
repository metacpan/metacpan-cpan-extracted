use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Sync::Shared;

# eventfd created in parent, inherited by fork; child notifies, parent sees
# the level transition. Verifies MAP_SHARED + eventfd inheritance semantics.

my $sem = Data::Sync::Shared::Semaphore->new(undef, 1);
$sem->acquire;  # drain to 0
my $efd = $sem->eventfd;

my $pid = fork // die;
if ($pid == 0) {
    select undef, undef, undef, 0.1;
    $sem->release;
    $sem->notify;
    _exit(0);
}

# Parent reads eventfd directly (as any event loop would)
vec(my $rfds = '', $efd, 1) = 1;
my $t0 = time;
my $n = select $rfds, undef, undef, 3.0;
my $dt = time - $t0;

waitpid $pid, 0;
ok $n > 0, 'parent saw eventfd readable from child notify';
ok $dt < 1.0, sprintf('event delivered in %.2fs', $dt);
is $sem->value, 1, 'semaphore incremented by child';

done_testing;
