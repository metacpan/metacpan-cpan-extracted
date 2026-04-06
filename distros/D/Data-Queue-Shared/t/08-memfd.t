use strict;
use warnings;
use Test::More;
use POSIX ();
use Data::Queue::Shared;

# ---- Int: memfd basic ----
subtest 'int memfd basic' => sub {
    my $q = Data::Queue::Shared::Int->new_memfd("test_int_q", 16);
    ok $q, 'created memfd int queue';
    is $q->path, undef, 'path is undef for memfd';

    my $fd = $q->memfd;
    ok $fd >= 0, "memfd returned valid fd ($fd)";

    $q->push(42);
    is $q->pop, 42, 'push/pop works';
    is $q->capacity, 16, 'capacity correct';

    $q->push($_) for 1..10;
    my @got = $q->drain;
    is_deeply \@got, [1..10], 'drain works';
};

# ---- Str: memfd basic ----
subtest 'str memfd basic' => sub {
    my $q = Data::Queue::Shared::Str->new_memfd("test_str_q", 16);
    ok $q, 'created memfd str queue';

    my $fd = $q->memfd;
    ok $fd >= 0, 'memfd valid';

    $q->push("hello");
    is $q->pop, "hello", 'push/pop works';

    $q->push_front("front");
    is $q->pop, "front", 'push_front works';

    $q->push("back");
    is $q->pop_back, "back", 'pop_back works';
};

# ---- Str: memfd with explicit arena ----
subtest 'str memfd arena' => sub {
    my $q = Data::Queue::Shared::Str->new_memfd("arena_q", 8, 8192);
    ok $q, 'memfd with explicit arena';
    my $s = $q->stats;
    is $s->{arena_cap}, 8192, 'arena_cap correct';
};

# ---- Cross-fork via memfd ----
subtest 'memfd cross-fork' => sub {
    my $q = Data::Queue::Shared::Int->new_memfd("fork_q", 64);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        $q->push(9999);
        POSIX::_exit(0);
    }

    waitpid($pid, 0);
    is $q->pop, 9999, 'child push visible via inherited memfd mmap';
};

# ---- new_from_fd: share memfd across handles ----
subtest 'int new_from_fd' => sub {
    my $q1 = Data::Queue::Shared::Int->new_memfd("fd_share", 32);
    my $fd = $q1->memfd;

    my $q2 = Data::Queue::Shared::Int->new_from_fd($fd);
    ok $q2, 'opened queue from fd';
    is $q2->capacity, 32, 'capacity matches';

    $q1->push(123);
    is $q2->pop, 123, 'cross-handle via fd works';

    $q2->push(456);
    is $q1->pop, 456, 'reverse direction works';
};

subtest 'str new_from_fd' => sub {
    my $q1 = Data::Queue::Shared::Str->new_memfd("fd_share_str", 32);
    my $fd = $q1->memfd;

    my $q2 = Data::Queue::Shared::Str->new_from_fd($fd);
    ok $q2, 'opened str queue from fd';

    $q1->push("from_q1");
    is $q2->pop, "from_q1", 'cross-handle str works';
};

# ---- new_from_fd cross-process via fork ----
subtest 'memfd fd passing via fork' => sub {
    my $q = Data::Queue::Shared::Str->new_memfd("pass_q", 64);
    my $fd = $q->memfd;

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        # Child opens from inherited fd
        my $cq = Data::Queue::Shared::Str->new_from_fd($fd);
        select(undef, undef, undef, 0.1);
        $cq->push("via_fd");
        POSIX::_exit(0);
    }

    my $val = $q->pop_wait(5);
    waitpid($pid, 0);
    is $val, "via_fd", 'child opened from fd and pushed';
};

# ---- memfd + eventfd ----
subtest 'memfd with eventfd' => sub {
    my $q = Data::Queue::Shared::Int->new_memfd("efd_q", 16);
    my $efd = $q->eventfd;
    ok $efd >= 0, 'eventfd on memfd queue';

    $q->push(1);
    $q->notify;

    require IO::Select;
    require IO::Handle;
    my $sel = IO::Select->new;
    $sel->add(IO::Handle->new_from_fd($efd, 'r'));
    my @ready = $sel->can_read(1);
    ok scalar @ready, 'eventfd readable after notify';
    $q->eventfd_consume;
    is $q->pop, 1, 'pop works';
};

# ---- memfd + blocking ----
subtest 'memfd blocking' => sub {
    my $q = Data::Queue::Shared::Int->new_memfd("block_q", 64);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        select(undef, undef, undef, 0.1);
        $q->push(777);
        POSIX::_exit(0);
    }

    my $val = $q->pop_wait(5);
    waitpid($pid, 0);
    is $val, 777, 'blocking pop on memfd queue';
};

# ---- unlink on memfd croaks ----
subtest 'memfd unlink croaks' => sub {
    my $q = Data::Queue::Shared::Int->new_memfd("unlink_test", 8);
    eval { $q->unlink };
    like $@, qr/cannot unlink/, 'unlink on memfd queue croaks';
};

done_testing;
