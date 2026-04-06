use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Queue::Shared;

my $p = tmpnam() . '.shm';
my $q = Data::Queue::Shared::Str->new($p, 16);

# pop_back on empty
is $q->pop_back, undef, 'pop_back on empty returns undef';

# Basic pop_back (removes from tail)
$q->push("first");
$q->push("second");
$q->push("third");

is $q->pop_back, "third", 'pop_back returns tail element';
is $q->pop_back, "second", 'pop_back returns next tail';
is $q->pop_back, "first", 'pop_back returns last';
is $q->pop_back, undef, 'pop_back on now-empty returns undef';
ok $q->is_empty, 'empty after pop_back drain';

# pop_back vs pop (front vs back)
$q->push("a");
$q->push("b");
$q->push("c");
is $q->pop, "a", 'pop returns front';
is $q->pop_back, "c", 'pop_back returns back';
is $q->pop, "b", 'remaining middle element';
ok $q->is_empty, 'empty';

# pop_back preserves UTF-8
my $utf = "\x{2603}";
$q->push($utf);
my $got = $q->pop_back;
ok utf8::is_utf8($got), 'pop_back preserves UTF-8 flag';
is $got, $utf, 'pop_back UTF-8 content correct';

# pop_back after push_front
$q->push("base");
$q->push_front("front");
is $q->pop_back, "base", 'pop_back gets tail (not push_front item)';
is $q->pop, "front", 'pop gets front (push_front item)';

# Arena: push, pop_back, push again (arena_wpos rollback)
$q->clear;
my $big = "X" x 500;
$q->push($big);
$q->push($big);
is $q->pop_back, $big, 'pop_back large string';
# Push should work — arena space was reclaimed
ok $q->push($big), 'push after pop_back (arena space reclaimed)';
my @rest = $q->drain;
is scalar @rest, 2, 'drain gets remaining 2 items';
is $rest[0], $big, 'first item intact';
is $rest[1], $big, 'second item intact';

# Interleave push/pop_back
for my $round (1..3) {
    $q->push("round${round}_a");
    $q->push("round${round}_b");
    is $q->pop_back, "round${round}_b", "round $round: pop_back gets latest";
    is $q->pop, "round${round}_a", "round $round: pop gets first";
}

# push_front + pop_back interleaving (arena corruption regression test)
$q->clear;
$q->push("A_tail");
$q->push_front("B_head");
is $q->pop_back, "A_tail", 'pop_back after push_front: tail correct';
is $q->pop, "B_head", 'push_front data not corrupted by pop_back';

# More complex interleaving
$q->clear;
$q->push("x1");
$q->push("x2");
$q->push_front("f1");
$q->push_front("f2");
# Queue order: f2, f1, x1, x2
is $q->pop_back, "x2", 'complex interleave: pop_back gets tail';
is $q->peek, "f2", 'complex interleave: head intact';
is $q->pop, "f2", 'complex interleave: pop f2';
is $q->pop, "f1", 'complex interleave: pop f1';
is $q->pop, "x1", 'complex interleave: pop x1';
ok $q->is_empty, 'complex interleave: empty';

# pop_back of wrap-triggered slot must not corrupt arena (regression test)
{
    # arena_cap=4096 (min), use strings that force a wrap
    my $pw = tmpnam() . '.shm';
    my $qw = Data::Queue::Shared::Str->new($pw, 64, 4096);
    my $big = "Z" x 2000;   # alloc = 2000 (aligned to 8)

    $qw->push($big);         # C at arena_off=0, arena_wpos=2000
    $qw->push($big);         # D at arena_off=2000, arena_wpos=4000
    $qw->pop;                # pop C, arena_used=2000
    # Now: only D at arena_off=2000, arena_wpos=4000

    $qw->push($big);         # E wraps: arena_off=0, arena_wpos=2000, skip=2000+96=2096
    # Queue: [D at 2000, E at 0]

    $qw->pop_back;           # pop_back E (wrapped slot)
    # D at arena_off=2000 must be intact

    $qw->push("safe");       # push small item — must not overwrite D
    is $qw->pop, $big, 'pop_back of wrapped slot: D data intact';
    is $qw->pop, "safe", 'subsequent push data intact';

    unlink $pw;
}

# Full queue, pop_back frees slot
$q->push("x") for 1..16;
ok $q->is_full, 'full';
$q->pop_back;
ok !$q->is_full, 'not full after pop_back';
ok $q->push("y"), 'push succeeds after pop_back freed slot';
$q->clear;

# pop_back_wait: blocking
{
    use POSIX ();
    my $p2 = tmpnam() . '.shm';
    my $q2 = Data::Queue::Shared::Str->new($p2, 16);

    # Timeout on empty queue
    my $t0 = time;
    is $q2->pop_back_wait(0.1), undef, 'pop_back_wait timeout returns undef';
    ok time - $t0 < 2, 'pop_back_wait did not hang';

    # Blocking: producer pushes, consumer pop_back_waits
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Str->new($p2, 16);
        select(undef, undef, undef, 0.1);
        $cq->push("delayed_back");
        POSIX::_exit(0);
    }
    my $val = $q2->pop_back_wait(5);
    waitpid($pid, 0);
    is $val, "delayed_back", 'pop_back_wait received value';

    # Non-blocking (data already present)
    $q2->push("instant");
    is $q2->pop_back_wait(0), "instant", 'pop_back_wait(0) returns immediately';

    unlink $p2;
}

# push_wait_multi with timeout on full queue
{
    my $p3 = tmpnam() . '.shm';
    my $q3 = Data::Queue::Shared::Str->new($p3, 4, 4096);
    $q3->push("x") for 1..4;  # fill
    my $t0 = time;
    my $n = $q3->push_wait_multi(0.1, "a", "b");
    is $n, 0, 'push_wait_multi timeout on full queue returns 0';
    ok time - $t0 < 2, 'push_wait_multi did not hang';
    unlink $p3;
}

# push_front_wait: blocking requeue
{
    my $p4 = tmpnam() . '.shm';
    my $q4 = Data::Queue::Shared::Str->new($p4, 4, 4096);

    # Non-blocking success
    ok $q4->push_front_wait("a"), 'push_front_wait on empty succeeds';
    is $q4->pop, "a", 'value correct';

    # Timeout on full queue
    $q4->push("x") for 1..4;
    my $t0 = time;
    ok !$q4->push_front_wait("overflow", 0.1), 'push_front_wait timeout when full';
    ok time - $t0 < 2, 'did not hang';

    # Blocking: consumer frees slot
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Str->new($p4, 4, 4096);
        select(undef, undef, undef, 0.1);
        $cq->pop;  # free a slot
        POSIX::_exit(0);
    }
    $t0 = time;
    ok $q4->push_front_wait("requeued", 5), 'push_front_wait succeeded after consumer freed slot';
    ok time - $t0 < 4, 'did not wait full timeout';
    waitpid($pid, 0);

    # Verify it went to the front
    is $q4->pop, "requeued", 'push_front_wait item is at front';

    unlink $p4;
}

unlink $p;
done_testing;
