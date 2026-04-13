use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Heap::Shared;

my $h = Data::Heap::Shared->new(undef, 10);
ok $h, 'created';
is $h->size, 0;
ok $h->is_empty;

# push and pop — min-heap order
ok $h->push(5, 500);
ok $h->push(1, 100);
ok $h->push(3, 300);
ok $h->push(2, 200);
ok $h->push(4, 400);
is $h->size, 5;

my ($p, $v) = $h->pop;
is $p, 1, 'min priority first';
is $v, 100;

($p, $v) = $h->pop;
is $p, 2; is $v, 200;

($p, $v) = $h->pop;
is $p, 3; is $v, 300;

($p, $v) = $h->pop;
is $p, 4; is $v, 400;

($p, $v) = $h->pop;
is $p, 5; is $v, 500;

# empty
my @r = $h->pop;
is scalar @r, 0, 'pop empty returns ()';
ok $h->is_empty;

# peek
$h->push(10, 1000);
$h->push(5, 500);
($p, $v) = $h->peek;
is $p, 5, 'peek returns min';
is $v, 500;
is $h->size, 2, 'peek does not remove';
$h->clear;
is $h->size, 0, 'clear';

# full
ok $h->push($_, $_ * 10) for 1..10;
ok $h->is_full;
ok !$h->push(99, 990), 'push fails when full';
$h->clear;

# pop_wait timeout
my $t0 = time;
@r = $h->pop_wait(0.1);
is scalar @r, 0, 'pop_wait timeout';
ok time - $t0 < 2;

# cross-process
$h->push(7, 700);
my $pid = fork // die;
if ($pid == 0) {
    my ($cp, $cv) = $h->pop;
    _exit($cp == 7 && $cv == 700 ? 0 : 1);
}
waitpid($pid, 0);
is $? >> 8, 0, 'cross-process pop';

# futex wakeup
$pid = fork // die;
if ($pid == 0) {
    select(undef, undef, undef, 0.05);
    $h->push(3, 33);
    _exit(0);
}
($p, $v) = $h->pop_wait(2.0);
is $p, 3, 'blocking pop woke on push';
is $v, 33;
waitpid($pid, 0);

# negative priorities
$h->push(-5, 1);
$h->push(-10, 2);
$h->push(0, 3);
($p, $v) = $h->pop;
is $p, -10, 'negative priority';
is $v, 2;
$h->clear;

# duplicate priorities — stable-ish (both pop, order may vary)
$h->push(1, 10);
$h->push(1, 20);
($p, $v) = $h->pop;
is $p, 1;
($p, $v) = $h->pop;
is $p, 1;

# file-backed persistence
my $path = tmpnam() . '.shm';
{
    my $fh = Data::Heap::Shared->new($path, 10);
    $fh->push(2, 200);
    $fh->push(1, 100);
}
{
    my $fh = Data::Heap::Shared->new($path, 10);
    is $fh->size, 2, 'file persistence';
    ($p, $v) = $fh->pop;
    is $p, 1, 'persisted min';
}
unlink $path;

# memfd
my $mh = Data::Heap::Shared->new_memfd("test", 10);
$mh->push(5, 50);
my $mh2 = Data::Heap::Shared->new_from_fd($mh->memfd);
($p, $v) = $mh2->pop;
is $p, 5, 'memfd fd passing';

# stats
my $s = $h->stats;
ok ref $s eq 'HASH';
ok $s->{pushes} > 0;

# eventfd
my $eh = Data::Heap::Shared->new(undef, 5);
my $efd = $eh->eventfd;
ok $efd >= 0, 'eventfd';
is $eh->fileno, $efd, 'fileno';
ok $eh->notify, 'notify';
my $ec = $eh->eventfd_consume;
is $ec, 1, 'eventfd_consume';

# path
is $eh->path, undef, 'anon path is undef';
my $ppath = tmpnam() . '.shm';
my $ph = Data::Heap::Shared->new($ppath, 5);
is $ph->path, $ppath, 'file path';

# sync / unlink
eval { $ph->sync };
ok !$@, 'sync ok';
$ph->unlink;
ok !-f $ppath, 'unlink removed file';

done_testing;
