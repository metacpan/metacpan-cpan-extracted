use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX ();
use Data::Queue::Shared;

my $main_pid = $$;

# ---- Int: peek ----
subtest 'int peek' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 16);

    is $q->peek, undef, 'peek on empty returns undef';

    $q->push(42);
    is $q->peek, 42, 'peek returns front value';
    is $q->peek, 42, 'peek is non-destructive';
    is $q->size, 1, 'size unchanged after peek';

    $q->push(99);
    is $q->peek, 42, 'peek still returns front (FIFO)';
    is $q->pop, 42, 'pop returns same as peek';
    is $q->peek, 99, 'peek returns next after pop';

    unlink $p;
};

# ---- Int: drain ----
subtest 'int drain' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 16);

    my @empty = $q->drain;
    is_deeply \@empty, [], 'drain on empty returns empty list';

    $q->push($_) for 1..5;
    my @all = $q->drain;
    is_deeply \@all, [1,2,3,4,5], 'drain returns all in FIFO order';
    ok $q->is_empty, 'empty after drain';

    # drain with limit
    $q->push($_) for 10..19;
    my @partial = $q->drain(3);
    is_deeply \@partial, [10,11,12], 'drain(3) returns first 3';
    is $q->size, 7, '7 remaining after partial drain';
    $q->drain;  # cleanup

    unlink $p;
};

# ---- Int: pop_wait_multi ----
subtest 'int pop_wait_multi' => sub {
    my $p = tmpnam() . '.shm';

    my $q = Data::Queue::Shared::Int->new($p, 64);

    # Non-blocking: items already available
    $q->push($_) for 1..5;
    my @got = $q->pop_wait_multi(10, 1.0);
    is scalar @got, 5, 'got all 5 available';
    is_deeply \@got, [1..5], 'correct values';

    # Blocking: wait for producer
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Int->new($p, 64);
        select(undef, undef, undef, 0.1);
        $cq->push(100);
        $cq->push(200);
        $cq->push(300);
        POSIX::_exit(0);
    }
    @got = $q->pop_wait_multi(10, 5.0);
    ok scalar @got >= 1, 'pop_wait_multi got at least 1';
    is $got[0], 100, 'first value correct';
    waitpid($pid, 0);
    # drain remaining
    $q->drain;

    # Timeout with no data
    my $t0 = time;
    @got = $q->pop_wait_multi(5, 0.1);
    is scalar @got, 0, 'pop_wait_multi timeout returns empty';
    ok time - $t0 < 2, 'did not hang';

    unlink $p;
};

# ---- Int: push_wait_multi ----
subtest 'int push_wait_multi' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 16);

    my $n = $q->push_wait_multi(-1, 10, 20, 30, 40, 50);
    is $n, 5, 'push_wait_multi pushed 5';
    my @got = $q->drain;
    is_deeply \@got, [10,20,30,40,50], 'values correct';

    # With timeout on a non-full queue (should succeed immediately)
    $n = $q->push_wait_multi(1.0, 7, 8, 9);
    is $n, 3, 'push_wait_multi with timeout pushed 3';
    $q->drain;

    unlink $p;
};

# ---- Int: sync ----
subtest 'int sync' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 16);
    $q->push(42);
    eval { $q->sync };
    is $@, '', 'sync does not croak';
    unlink $p;
};

# ---- Int: waiters in stats ----
subtest 'int stats waiters' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 16);
    my $s = $q->stats;
    ok exists $s->{push_waiters}, 'stats has push_waiters';
    ok exists $s->{pop_waiters}, 'stats has pop_waiters';
    is $s->{push_waiters}, 0, 'no push waiters';
    is $s->{pop_waiters}, 0, 'no pop waiters';
    unlink $p;
};

# ---- Str: peek ----
subtest 'str peek' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Str->new($p, 16);

    is $q->peek, undef, 'peek on empty';

    $q->push("hello");
    is $q->peek, "hello", 'peek returns front';
    is $q->peek, "hello", 'peek non-destructive';
    is $q->size, 1, 'size unchanged';

    $q->push("world");
    is $q->peek, "hello", 'peek still front';
    $q->pop;
    is $q->peek, "world", 'peek advances after pop';

    # UTF-8
    my $utf = "\x{2603}";  # snowman
    $q->clear;
    $q->push($utf);
    my $peeked = $q->peek;
    ok utf8::is_utf8($peeked), 'peek preserves UTF-8';
    is $peeked, $utf, 'peek UTF-8 content correct';

    unlink $p;
};

# ---- Str: push_front ----
subtest 'str push_front' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Str->new($p, 16);

    # size/is_empty correct after push_front on empty queue
    ok $q->push_front("only"), 'push_front on empty';
    is $q->size, 1, 'size is 1 after push_front on empty';
    ok !$q->is_empty, 'not empty after push_front';
    is $q->pop, "only", 'pop returns push_front item';

    $q->push("second");
    $q->push("third");
    ok $q->push_front("first"), 'push_front succeeds';

    is $q->pop, "first", 'pop returns push_front item first';
    is $q->pop, "second", 'then original front';
    is $q->pop, "third", 'then original second';

    # push_front on empty queue
    ok $q->push_front("only"), 'push_front on empty';
    is $q->pop, "only", 'pop returns it';

    # push_front when full
    $q->push("x") for 1..16;
    ok !$q->push_front("overflow"), 'push_front fails when full';

    # push_front with UTF-8
    $q->clear;
    my $utf = "\x{1F600}";  # grinning face
    ok $q->push_front($utf), 'push_front UTF-8';
    my $got = $q->pop;
    ok utf8::is_utf8($got), 'push_front preserves UTF-8';
    is $got, $utf, 'push_front UTF-8 content correct';

    # Multiple push_fronts maintain stack-like order at front
    $q->push("base");
    $q->push_front("b");
    $q->push_front("a");
    my @order = $q->drain;
    is_deeply \@order, ["a", "b", "base"], 'multiple push_fronts: LIFO at head';

    unlink $p;
};

# ---- Str: drain ----
subtest 'str drain' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Str->new($p, 16);

    my @empty = $q->drain;
    is_deeply \@empty, [], 'drain empty';

    $q->push("a$_") for 1..5;
    my @all = $q->drain;
    is_deeply \@all, [map { "a$_" } 1..5], 'drain all';
    ok $q->is_empty, 'empty after drain';

    # drain with limit
    $q->push("b$_") for 1..8;
    my @partial = $q->drain(3);
    is_deeply \@partial, ["b1","b2","b3"], 'drain(3)';
    is $q->size, 5, '5 remaining';

    unlink $p;
};

# ---- Str: pop_wait_multi ----
subtest 'str pop_wait_multi' => sub {
    my $p = tmpnam() . '.shm';

    my $q = Data::Queue::Shared::Str->new($p, 64, 16384);

    $q->push("m$_") for 1..5;
    my @got = $q->pop_wait_multi(10, 1.0);
    is scalar @got, 5, 'got all 5';
    is_deeply \@got, [map { "m$_" } 1..5], 'correct';

    # Blocking
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Str->new($p, 64, 16384);
        select(undef, undef, undef, 0.1);
        $cq->push("delayed");
        POSIX::_exit(0);
    }
    @got = $q->pop_wait_multi(5, 5.0);
    ok scalar @got >= 1, 'got at least 1 after blocking';
    is $got[0], "delayed", 'value correct';
    waitpid($pid, 0);

    # Timeout
    my $t0 = time;
    @got = $q->pop_wait_multi(5, 0.1);
    is scalar @got, 0, 'timeout returns empty';
    ok time - $t0 < 2, 'did not hang';

    unlink $p;
};

# ---- Str: push_wait_multi ----
subtest 'str push_wait_multi' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Str->new($p, 16);

    my $n = $q->push_wait_multi(-1, "x", "y", "z");
    is $n, 3, 'push_wait_multi pushed 3';
    my @got = $q->drain;
    is_deeply \@got, ["x","y","z"], 'values correct';

    $n = $q->push_wait_multi(1.0, "a", "b");
    is $n, 2, 'str push_wait_multi with timeout pushed 2';
    $q->drain;

    unlink $p;
};

# ---- Str: sync ----
subtest 'str sync' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Str->new($p, 16);
    $q->push("persist");
    eval { $q->sync };
    is $@, '', 'sync does not croak';
    unlink $p;
};

# ---- Str: waiters in stats ----
subtest 'str stats waiters' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Str->new($p, 16);
    my $s = $q->stats;
    ok exists $s->{push_waiters}, 'stats has push_waiters';
    ok exists $s->{pop_waiters}, 'stats has pop_waiters';
    unlink $p;
};

done_testing;
