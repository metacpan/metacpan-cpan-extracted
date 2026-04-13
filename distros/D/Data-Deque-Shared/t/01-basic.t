use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Deque::Shared;

my $dq = Data::Deque::Shared::Int->new(undef, 10);
ok $dq, 'created';
is $dq->size, 0;
ok $dq->is_empty;

# push_back / pop_front (FIFO)
$dq->push_back(1);
$dq->push_back(2);
$dq->push_back(3);
is $dq->size, 3;
is $dq->pop_front, 1, 'FIFO front';
is $dq->pop_front, 2;
is $dq->pop_front, 3;
ok $dq->is_empty;

# push_front / pop_back (FIFO other direction)
$dq->push_front(10);
$dq->push_front(20);
$dq->push_front(30);
is $dq->pop_back, 10, 'FIFO back';
is $dq->pop_back, 20;
is $dq->pop_back, 30;

# push_back / pop_back (LIFO)
$dq->push_back(1);
$dq->push_back(2);
$dq->push_back(3);
is $dq->pop_back, 3, 'LIFO back';
is $dq->pop_back, 2;
is $dq->pop_back, 1;

# push_front / pop_front (LIFO other direction)
$dq->push_front(10);
$dq->push_front(20);
is $dq->pop_front, 20, 'LIFO front';
is $dq->pop_front, 10;

# mixed
$dq->push_back(1);
$dq->push_back(2);
$dq->push_front(0);
$dq->push_front(-1);
is $dq->pop_front, -1;
is $dq->pop_back, 2;
is $dq->pop_front, 0;
is $dq->pop_back, 1;
ok $dq->is_empty;

# full
ok $dq->push_back($_), "push $_" for 1..10;
ok $dq->is_full;
ok !$dq->push_back(99), 'push_back fails when full';
ok !$dq->push_front(99), 'push_front fails when full';
$dq->clear;
is $dq->size, 0, 'clear';

# empty pop
ok !defined $dq->pop_front, 'pop_front empty';
ok !defined $dq->pop_back, 'pop_back empty';

# timeout
my $t0 = time;
ok !defined $dq->pop_front_wait(0.1), 'pop_front_wait timeout';
ok time - $t0 < 2;

$dq->push_back($_) for 1..10;
$t0 = time;
ok !$dq->push_back_wait(99, 0.1), 'push_back_wait timeout when full';
ok time - $t0 < 2;
$dq->clear;

# pop_back_wait timeout
$t0 = time;
ok !defined $dq->pop_back_wait(0.1), 'pop_back_wait timeout';
ok time - $t0 < 2;

# push_front_wait timeout
$dq->push_back($_) for 1..10;
$t0 = time;
ok !$dq->push_front_wait(99, 0.1), 'push_front_wait timeout when full';
ok time - $t0 < 2;
$dq->clear;

# cross-process
$dq->push_back(42);
my $pid = fork // die;
if ($pid == 0) {
    _exit($dq->pop_front == 42 ? 0 : 1);
}
waitpid($pid, 0);
is $? >> 8, 0, 'cross-process';

# futex wakeup: child pushes, parent pops
$pid = fork // die;
if ($pid == 0) {
    select(undef, undef, undef, 0.05);
    $dq->push_back(77);
    _exit(0);
}
my $val = $dq->pop_front_wait(2.0);
is $val, 77, 'blocking pop woke on push';
waitpid($pid, 0);

# stats
my $s = $dq->stats;
ok ref $s eq 'HASH';
ok $s->{pushes} > 0;
ok $s->{pops} > 0;
is $s->{capacity}, 10;

# --- file-backed persistence ---

my $path = tmpnam() . '.shm';
{
    my $fd = Data::Deque::Shared::Int->new($path, 5);
    $fd->push_back(111);
    $fd->push_back(222);
    is $fd->path, $path;
}
{
    my $fd = Data::Deque::Shared::Int->new($path, 5);
    is $fd->size, 2, 'file persistence';
    is $fd->pop_front, 111, 'persisted FIFO';
    is $fd->pop_front, 222;
}
unlink $path;

# --- memfd / new_from_fd ---

my $md = Data::Deque::Shared::Int->new_memfd("test_dq", 10);
ok $md, 'memfd created';
my $mfd = $md->memfd;
ok $mfd >= 0;
$md->push_back(42);

my $md2 = Data::Deque::Shared::Int->new_from_fd($mfd);
is $md2->pop_front, 42, 'data via new_from_fd';

# --- eventfd ---

my $ed = Data::Deque::Shared::Int->new(undef, 5);
my $efd = $ed->eventfd;
ok $efd >= 0, 'eventfd';
ok $ed->notify;
my $ec = $ed->eventfd_consume;
is $ec, 1, 'eventfd_consume';

# --- sync / unlink ---

my $upath = tmpnam() . '.shm';
my $ud = Data::Deque::Shared::Int->new($upath, 5);
$ud->push_back(1);
eval { $ud->sync };
ok !$@, 'sync ok';
$ud->unlink;
ok !-f $upath, 'unlink removed file';

done_testing;
