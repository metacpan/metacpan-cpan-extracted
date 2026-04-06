use strict;
use warnings;
use Test::More;
use POSIX ();
use Data::Queue::Shared;

# ---- Int: anonymous queue ----
subtest 'int anonymous' => sub {
    my $q = Data::Queue::Shared::Int->new(undef, 16);
    ok $q, 'created anonymous int queue';
    is $q->path, undef, 'path is undef';
    is $q->capacity, 16, 'capacity correct';

    $q->push(42);
    is $q->pop, 42, 'push/pop works';

    $q->push($_) for 1..10;
    my @got = $q->drain;
    is_deeply \@got, [1..10], 'drain works';

    $q->push($_) for 1..16;
    ok $q->is_full, 'full';
    ok !$q->push(99), 'push fails when full';
    $q->clear;
    ok $q->is_empty, 'clear works';
};

# ---- Str: anonymous queue ----
subtest 'str anonymous' => sub {
    my $q = Data::Queue::Shared::Str->new(undef, 16);
    ok $q, 'created anonymous str queue';
    is $q->path, undef, 'path is undef';

    $q->push("hello");
    is $q->pop, "hello", 'push/pop works';

    my $utf = "\x{1F600}";
    $q->push($utf);
    my $got = $q->pop;
    ok utf8::is_utf8($got), 'UTF-8 preserved';
    is $got, $utf, 'UTF-8 correct';

    $q->push_front("front");
    $q->push("back");
    is $q->pop, "front", 'push_front works';
    is $q->pop_back, "back", 'pop_back works';
};

# ---- Anonymous + fork: shared across parent/child ----
subtest 'anonymous cross-fork' => sub {
    my $q = Data::Queue::Shared::Int->new(undef, 64);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        $q->push(12345);
        POSIX::_exit(0);
    }

    waitpid($pid, 0);
    is $q->pop, 12345, 'child push visible to parent via anonymous mmap';
};

subtest 'str anonymous cross-fork' => sub {
    my $q = Data::Queue::Shared::Str->new(undef, 64);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        $q->push("from_child");
        POSIX::_exit(0);
    }

    waitpid($pid, 0);
    is $q->pop, "from_child", 'str: child push visible via anonymous mmap';
};

# ---- Anonymous + blocking ----
subtest 'anonymous blocking' => sub {
    my $q = Data::Queue::Shared::Int->new(undef, 64);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        select(undef, undef, undef, 0.1);
        $q->push(999);
        POSIX::_exit(0);
    }

    my $val = $q->pop_wait(5);
    waitpid($pid, 0);
    is $val, 999, 'blocking pop works on anonymous queue';
};

# ---- Anonymous + eventfd ----
subtest 'anonymous eventfd' => sub {
    my $q = Data::Queue::Shared::Int->new(undef, 64);
    my $fd = $q->eventfd;
    ok $fd >= 0, 'eventfd on anonymous queue';

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        select(undef, undef, undef, 0.1);
        $q->push(42);
        $q->notify;
        POSIX::_exit(0);
    }

    require IO::Select;
    require IO::Handle;
    my $sel = IO::Select->new;
    $sel->add(IO::Handle->new_from_fd($fd, 'r'));
    my @ready = $sel->can_read(5);
    ok scalar @ready, 'eventfd notified on anonymous queue';
    $q->eventfd_consume;
    is $q->pop, 42, 'popped value';

    waitpid($pid, 0);
};

# ---- Anonymous: explicit arena size ----
subtest 'str anonymous arena' => sub {
    my $q = Data::Queue::Shared::Str->new(undef, 8, 8192);
    ok $q, 'anonymous str with explicit arena';
    my $s = $q->stats;
    is $s->{arena_cap}, 8192, 'arena_cap correct';
};

# ---- unlink on anonymous queue croaks ----
subtest 'anonymous unlink croaks' => sub {
    my $q = Data::Queue::Shared::Int->new(undef, 8);
    eval { $q->unlink };
    like $@, qr/cannot unlink/, 'unlink on anonymous queue croaks';
};

done_testing;
