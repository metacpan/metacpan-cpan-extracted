use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Fcntl qw(O_RDWR);
use Errno qw(EAGAIN);
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::Queue::Shared::Int;
use Data::Queue::Shared::Str;

plan skip_all => 'needs /proc/self/ns/pid' unless -e '/proc/self/ns/pid';

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/q.shm";
my $q = Data::Queue::Shared::Str->new($path, 64, 1 << 16);

sub hold_as {    # QueueHeader.mutex is at offset 192
    my ($pid) = @_;
    sysopen my $fh, $path, O_RDWR or die "$path: $!";
    sysseek $fh, 192, 0 or die $!;
    syswrite($fh, pack('L', $pid ? 0x80000000 | $pid : 0)) == 4 or die $!;
}

my @lock_stats = qw(lock_waits lock_wait_time lock_wait_max lock_timeouts last_recovery);
is_deeply [ @{ $q->stats }{@lock_stats} ], [0, 0, 0, 0, 0], 'lock stats start at zero';
ok !Data::Queue::Shared::Int->can('lock_timeout'), 'Int queues have no lock to time out';
ok !exists Data::Queue::Shared::Int->new(undef, 4)->stats->{lock_waits}, '  nor lock stats';
is $q->lock_timeout, undef, 'waits for the lock without limit by default';
$q->push($_) for qw(a b);

my $holder = fork // die "fork: $!";
unless ($holder) { sleep 60; _exit(0) }
hold_as($holder);

my $pusher = fork // die "fork: $!";
unless ($pusher) { _exit($q->push('waited') ? 0 : 1) }
sleep 0.3;
hold_as(0);
waitpid $pusher, 0;
is $?, 0, 'a push waited for the lock';
my $s = $q->stats;
is $s->{lock_waits}, 1, 'lock_waits counts it';
cmp_ok $s->{lock_wait_time}, '>=', 0.25, 'lock_wait_time holds its wait in seconds';
cmp_ok $s->{lock_wait_max}, '>=', 0.25, 'lock_wait_max too';
cmp_ok $s->{lock_wait_max}, '<=', $s->{lock_wait_time}, '  no more than the total';

hold_as($holder);
is $q->lock_timeout(0.05), 0.05, 'lock_timeout set';
my @ops = (
    [push            => sub { $q->push('x') }],
    [push_front      => sub { $q->push_front('x') }],
    [push_multi      => sub { $q->push_multi('x', 'y') }],
    [push_wait       => sub { $q->push_wait('x', 5) }],
    [push_front_wait => sub { $q->push_front_wait('x', 5) }],
    [push_wait_multi => sub { $q->push_wait_multi(5, 'x') }],
    [pop             => sub { $q->pop }],
    [pop_back        => sub { $q->pop_back }],
    [peek            => sub { $q->peek }],
    [pop_multi       => sub { $q->pop_multi(2) }],
    [drain           => sub { $q->drain }],
    [pop_wait        => sub { $q->pop_wait(5) }],
    [pop_back_wait   => sub { $q->pop_back_wait(5) }],
    [pop_wait_multi  => sub { $q->pop_wait_multi(2, 5) }],
    [clear           => sub { $q->clear }],
);
for my $op (@ops) {
    my ($name, $code) = @$op;
    local $! = 0;
    my $t0 = time;
    my @r = $code->();
    my $took = time - $t0;
    my $errno = $! + 0;
    ok !grep({ $_ } @r), "$name: nothing done while the lock is held";
    is $errno, EAGAIN, "$name: \$! is EAGAIN";
    cmp_ok $took, '<', 1, "$name: gives up after lock_timeout";
}
is $q->stats->{lock_timeouts}, scalar @ops, 'lock_timeouts counts each';
{
    $q->lock_timeout(0);
    local $! = 0;
    my $t0 = time;
    ok !$q->push('x'), 'lock_timeout 0: push fails at once';
    cmp_ok time - $t0, '<', 0.5, '  without sleeping';
    is $! + 0, EAGAIN, '  with EAGAIN';
}

hold_as(0);
ok $q->push('c'), 'push succeeds once the lock is free';
{
    my $full = Data::Queue::Shared::Str->new(undef, 2);
    $full->push($_) for 1, 2;
    local $! = EAGAIN;
    ok !$full->push('x'), 'a full queue refuses a push';
    is $! + 0, 0, '  and clears $!, so a stale EAGAIN cannot pass for a timeout';
    $full->clear;
    $! = EAGAIN;
    is $full->pop, undef, 'an empty queue pops nothing';
    is $! + 0, 0, '  and clears $! too';
}

kill KILL => $holder;
waitpid $holder, 0;
hold_as($holder);
my $before = time;
ok $q->push('d'), 'lock_timeout 0 still takes over the lock of a dead holder';
$s = $q->stats;
is $s->{recoveries}, 1, '  counted as a recovery';
cmp_ok $s->{last_recovery}, '>=', int($before), 'last_recovery is when it happened';
cmp_ok $s->{last_recovery}, '<=', time + 1, '  in epoch seconds';

is $q->lock_timeout(undef), undef, 'lock_timeout(undef) waits without limit again';
is_deeply [ $q->drain ], [qw(a b waited c d)], 'timed-out calls changed nothing';

done_testing;
