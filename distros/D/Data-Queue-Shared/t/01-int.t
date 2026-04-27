use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Queue::Shared;

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

# Basic create
my $q = Data::Queue::Shared::Int->new($path, 16);
ok $q, 'created int queue';
is $q->capacity, 16, 'capacity is power of 2';
is $q->size, 0, 'starts empty';
ok $q->is_empty, 'is_empty';
ok !$q->is_full, 'not full';

# Push/pop
ok $q->push(42), 'push 42';
is $q->size, 1, 'size 1';
ok !$q->is_empty, 'not empty after push';

my $val = $q->pop;
is $val, 42, 'pop returns 42';
is $q->size, 0, 'size 0 after pop';

# Pop empty
is $q->pop, undef, 'pop on empty returns undef';

# FIFO ordering
$q->push($_) for 1..5;
my @got;
push @got, $q->pop for 1..5;
is_deeply \@got, [1,2,3,4,5], 'FIFO order preserved';

# Fill to capacity
ok $q->push($_), "push $_" for 1..16;
ok $q->is_full, 'full after 16 pushes';
ok !$q->push(99), 'push fails when full';
is $q->size, 16, 'size 16';

# Drain
@got = ();
push @got, $q->pop for 1..16;
is_deeply \@got, [1..16], 'drained all 16 in order';
ok $q->is_empty, 'empty after drain';

# Batch push/pop
my $n = $q->push_multi(10, 20, 30, 40, 50);
is $n, 5, 'push_multi returned 5';
my @batch = $q->pop_multi(3);
is_deeply \@batch, [10, 20, 30], 'pop_multi got first 3';
@batch = $q->pop_multi(100);
is_deeply \@batch, [40, 50], 'pop_multi got remaining 2';

# Clear
$q->push($_) for 1..8;
$q->clear;
is $q->size, 0, 'clear empties queue';
is $q->pop, undef, 'pop after clear returns undef';

# Push after clear works
ok $q->push(77), 'push after clear';
is $q->pop, 77, 'pop after clear push';

# Negative values
ok $q->push(-123), 'push negative';
is $q->pop, -123, 'pop negative';

# Stats
$q->clear;
$q->push(1);
$q->pop;
my $s = $q->stats;
ok $s->{push_ok} > 0, 'stats push_ok';
ok $s->{pop_ok} > 0, 'stats pop_ok';
is $s->{capacity}, 16, 'stats capacity';

# Path
is $q->path, $path, 'path returns correct path';

# Reopen existing file
my $q2 = Data::Queue::Shared::Int->new($path, 16);
ok $q2, 'reopened existing queue';
$q->push(555);
is $q2->pop, 555, 'cross-handle visibility';

# pop_wait with timeout (should return undef quickly)
my $t0 = time;
my $r = $q->pop_wait(0.1);
is $r, undef, 'pop_wait timeout returns undef';
cmp_ok time - $t0, '<', 30, 'pop_wait returned (not hung)';

# push_wait with timeout when full
$q->push($_) for 1..16;
$t0 = time;
ok !$q->push_wait(99, 0.1), 'push_wait timeout when full';
cmp_ok time - $t0, '<', 30, 'push_wait returned (not hung)';
$q->clear;

# Stats: push_full and pop_empty are tracked
{
    my $p3 = tmpnam() . '.shm';
    my $q3 = Data::Queue::Shared::Int->new($p3, 4);
    $q3->push(1) for 1..4;
    $q3->push(99);  # should fail, full
    my $s3 = $q3->stats;
    ok $s3->{push_full} > 0, 'stats push_full counted';
    $q3->clear;
    $q3->pop;  # should fail, empty
    $s3 = $q3->stats;
    ok $s3->{pop_empty} > 0, 'stats pop_empty counted';
    unlink $p3;
}

# Unlink
$q->unlink;
ok !-f $path, 'unlink removed file';

done_testing;
