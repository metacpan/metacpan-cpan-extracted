use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::RingBuffer::Shared;

# --- Int ---
my $r = Data::RingBuffer::Shared::Int->new(undef, 5);
ok $r, 'created';
is $r->capacity, 5;
is $r->size, 0;

# write/latest
my $s0 = $r->write(10);
is $s0, 0, 'first write returns seq 0';
is $r->latest, 10, 'latest';
is $r->size, 1;

$r->write(20);
$r->write(30);
is $r->latest, 30;
is $r->latest(0), 30, 'latest(0)';
is $r->latest(1), 20, 'latest(1)';
is $r->latest(2), 10, 'latest(2)';
ok !defined $r->latest(5), 'latest(5) out of range';

# read_seq
is $r->read_seq(0), 10, 'read_seq(0)';
is $r->read_seq(2), 30, 'read_seq(2)';
ok !defined $r->read_seq(99), 'read_seq future';

# overwrite — write more than capacity
$r->write(40);
$r->write(50);
is $r->size, 5, 'size capped at capacity';
$r->write(60);  # overwrites seq=0 (value 10)
is $r->size, 5;
ok !defined $r->read_seq(0), 'seq 0 overwritten';
is $r->read_seq(1), 20, 'seq 1 still valid';
is $r->latest, 60;

# to_list
my @list = $r->to_list;
is_deeply \@list, [20, 30, 40, 50, 60], 'to_list oldest first';

# clear
$r->clear;
is $r->size, 0;
is $r->head, 0;

# wait_for timeout
my $t0 = time;
ok !$r->wait_for(0, 0.1), 'wait_for timeout';
ok time - $t0 < 2;

# cross-process
$r->write(42);
my $pid = fork // die;
if ($pid == 0) {
    _exit($r->latest == 42 ? 0 : 1);
}
waitpid($pid, 0);
is $? >> 8, 0, 'cross-process read';

# child writes, parent reads
$pid = fork // die;
if ($pid == 0) {
    select(undef, undef, undef, 0.05);
    $r->write(77);
    _exit(0);
}
my $cnt = $r->count;
ok $r->wait_for($cnt, 2.0), 'wait_for woke on write';
is $r->latest, 77;
waitpid($pid, 0);

# --- F64 ---
my $f = Data::RingBuffer::Shared::F64->new(undef, 10);
$f->write(3.14);
$f->write(2.72);
ok abs($f->latest - 2.72) < 0.001, 'F64 latest';
ok abs($f->latest(1) - 3.14) < 0.001, 'F64 latest(1)';
is $f->size, 2;

# file persistence
my $path = tmpnam() . '.shm';
{
    my $fr = Data::RingBuffer::Shared::Int->new($path, 10);
    $fr->write(111);
    $fr->write(222);
    is $fr->path, $path;
}
{
    my $fr = Data::RingBuffer::Shared::Int->new($path, 10);
    is $fr->size, 2, 'persistence';
    is $fr->latest, 222;
}
unlink $path;

# memfd
my $mr = Data::RingBuffer::Shared::Int->new_memfd("test", 10);
$mr->write(99);
my $mr2 = Data::RingBuffer::Shared::Int->new_from_fd($mr->memfd);
is $mr2->latest, 99, 'memfd fd passing';

# eventfd
my $er = Data::RingBuffer::Shared::Int->new(undef, 5);
my $efd = $er->eventfd;
ok $efd >= 0;
ok $er->notify;
is $er->eventfd_consume, 1;

# stats
my $st = $r->stats;
ok ref $st eq 'HASH';
ok $st->{writes} > 0;

# sync / unlink
my $upath = tmpnam() . '.shm';
my $ur = Data::RingBuffer::Shared::Int->new($upath, 5);
$ur->write(1);
eval { $ur->sync };
ok !$@, 'sync ok';
$ur->unlink;
ok !-f $upath, 'unlink removed file';

done_testing;
