use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX ();
use IO::Select;
use Data::Queue::Shared;

my $main_pid = $$;

sub make_sel {
    my ($fd) = @_;
    my $sel = IO::Select->new;
    $sel->add(IO::Handle->new_from_fd($fd, 'r'));
    return $sel;
}

# ---- Int: eventfd basic ----
subtest 'int eventfd basic' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 64);

    is $q->fileno, -1, 'fileno is -1 before eventfd';

    my $fd = $q->eventfd;
    ok $fd >= 0, "eventfd returned valid fd ($fd)";
    is $q->fileno, $fd, 'fileno matches eventfd';
    is $q->eventfd, $fd, 'eventfd idempotent';

    # push alone does NOT trigger notification (opt-in)
    $q->push(42);
    my $sel = make_sel($fd);
    my @ready = $sel->can_read(0.05);
    ok !scalar @ready, 'push alone does not notify';

    # explicit notify makes fd readable
    $q->notify;
    @ready = $sel->can_read(1);
    ok scalar @ready, 'notify makes eventfd readable';

    $q->eventfd_consume;
    @ready = $sel->can_read(0.05);
    ok !scalar @ready, 'not readable after consume';

    is $q->pop, 42, 'pop works normally';

    unlink $p;
};

# ---- Str: eventfd basic ----
subtest 'str eventfd basic' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Str->new($p, 64);

    my $fd = $q->eventfd;
    ok $fd >= 0, "str eventfd valid fd";

    $q->push("hello");
    my $sel = make_sel($fd);
    my @ready = $sel->can_read(0.05);
    ok !scalar @ready, 'str push alone does not notify';

    $q->notify;
    @ready = $sel->can_read(1);
    ok scalar @ready, 'str notify makes fd readable';
    $q->eventfd_consume;
    is $q->pop, "hello", 'str pop works';

    # push_front + notify
    $q->push_front("front");
    $q->notify;
    @ready = $sel->can_read(1);
    ok scalar @ready, 'readable after push_front + notify';
    $q->eventfd_consume;
    is $q->pop, "front", 'pop returns push_front item';

    unlink $p;
};

# ---- Batch + notify ----
subtest 'batch notify' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 64);

    my $fd = $q->eventfd;
    my $sel = make_sel($fd);

    $q->push_multi(1, 2, 3);
    $q->notify;
    my @ready = $sel->can_read(1);
    ok scalar @ready, 'readable after push_multi + notify';
    $q->eventfd_consume;
    $q->drain;

    unlink $p;
};

# ---- Cross-process: child pushes + notifies ----
subtest 'eventfd cross-process' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 64);
    my $fd = $q->eventfd;

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Int->new($p, 64);
        $cq->eventfd_set($fd);
        select(undef, undef, undef, 0.1);
        $cq->push(777);
        $cq->notify;
        POSIX::_exit(0);
    }

    my $sel = make_sel($fd);
    my @ready = $sel->can_read(5);
    ok scalar @ready, 'parent notified by child push+notify';
    $q->eventfd_consume;
    is $q->pop, 777, 'parent popped child value';

    waitpid($pid, 0);
    unlink $p;
};

# ---- Str cross-process ----
subtest 'str eventfd cross-process' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Str->new($p, 64);
    my $fd = $q->eventfd;

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Str->new($p, 64);
        $cq->eventfd_set($fd);
        select(undef, undef, undef, 0.1);
        $cq->push("from_child");
        $cq->notify;
        POSIX::_exit(0);
    }

    my $sel = make_sel($fd);
    my @ready = $sel->can_read(5);
    ok scalar @ready, 'str: parent notified';
    $q->eventfd_consume;
    is $q->pop, "from_child", 'str: correct value';

    waitpid($pid, 0);
    unlink $p;
};

# ---- eventfd_set replaces fd ----
subtest 'eventfd_set' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 16);

    my $fd1 = $q->eventfd;
    ok $fd1 >= 0, 'first eventfd';

    my $q2 = Data::Queue::Shared::Int->new(tmpnam() . '.shm', 16);
    my $fd2 = $q2->eventfd;
    ok $fd2 >= 0, 'second eventfd';

    open my $fh, "<&=", $fd2 or die "dup: $!";
    my $fd2_dup = fileno($fh);
    $q->eventfd_set($fd2_dup);
    is $q->fileno, $fd2_dup, 'fileno reflects new fd';

    $q->push(1);
    $q->notify;
    my $sel = IO::Select->new;
    $sel->add($fh);
    my @ready = $sel->can_read(1);
    ok scalar @ready, 'new fd receives notifications';
    $q->eventfd_consume;

    unlink $p;
    $q2->unlink;
};

# ---- no notification without eventfd ----
subtest 'no eventfd no overhead' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 16);

    # notify without eventfd is a no-op (no crash)
    $q->push(1);
    $q->notify;
    is $q->pop, 1, 'notify without eventfd is a no-op';

    unlink $p;
};

done_testing;
