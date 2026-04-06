use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX ();
use Data::Queue::Shared;

my $main_pid = $$;
my $path = tmpnam() . '.shm';
END { unlink $path if $$ == $main_pid && $path && -f $path }

# Int: producer/consumer across fork
subtest 'int multiprocess' => sub {
    my $q = Data::Queue::Shared::Int->new($path, 256);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Int->new($path, 256);
        $cq->push_wait($_, 5) for 1..100;
        POSIX::_exit(0);
    }

    my @received;
    while (@received < 100) {
        my $v = $q->pop_wait(5);
        last unless defined $v;
        push @received, $v;
    }

    waitpid($pid, 0);
    is scalar @received, 100, 'received all 100 values';
    my @sorted = sort { $a <=> $b } @received;
    is_deeply \@sorted, [1..100], 'all values correct';

    $q->unlink;
};

# Int: blocking pop across fork (delayed push)
my $path2 = tmpnam() . '.shm';
END { unlink $path2 if $$ == $main_pid && $path2 && -f $path2 }

subtest 'int blocking pop' => sub {
    my $q = Data::Queue::Shared::Int->new($path2, 64);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Int->new($path2, 64);
        select(undef, undef, undef, 0.1);
        $cq->push(12345);
        POSIX::_exit(0);
    }

    my $val = $q->pop_wait(5);
    waitpid($pid, 0);
    is $val, 12345, 'blocking pop received value from child';

    $q->unlink;
};

# Int: blocking push (queue full, consumer unblocks producer)
my $path2b = tmpnam() . '.shm';
END { unlink $path2b if $$ == $main_pid && $path2b && -f $path2b }

subtest 'int blocking push' => sub {
    my $q = Data::Queue::Shared::Int->new($path2b, 4);
    $q->push($_) for 1..4;  # fill it

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Int->new($path2b, 4);
        select(undef, undef, undef, 0.1);
        $cq->pop;  # free one slot
        POSIX::_exit(0);
    }

    my $t0 = time;
    ok $q->push_wait(99, 5), 'blocking push succeeded after consumer freed slot';
    ok time - $t0 < 4, 'did not wait full timeout';

    waitpid($pid, 0);
    $q->unlink;
};

# Str: multiprocess
my $path3 = tmpnam() . '.shm';
END { unlink $path3 if $$ == $main_pid && $path3 && -f $path3 }

subtest 'str multiprocess' => sub {
    my $q = Data::Queue::Shared::Str->new($path3, 256, 65536);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Str->new($path3, 256, 65536);
        $cq->push_wait("message_$_", 5) for 1..50;
        POSIX::_exit(0);
    }

    my @received;
    while (@received < 50) {
        my $v = $q->pop_wait(5);
        last unless defined $v;
        push @received, $v;
    }

    waitpid($pid, 0);
    is scalar @received, 50, 'received all 50 strings';
    my @sorted = sort @received;
    my @sorted_exp = sort map { "message_$_" } 1..50;
    is_deeply \@sorted, \@sorted_exp, 'all string values correct';

    $q->unlink;
};

# Str: blocking pop across fork
my $path4 = tmpnam() . '.shm';
END { unlink $path4 if $$ == $main_pid && $path4 && -f $path4 }

subtest 'str blocking pop' => sub {
    my $q = Data::Queue::Shared::Str->new($path4, 64, 8192);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Str->new($path4, 64, 8192);
        select(undef, undef, undef, 0.1);
        $cq->push("delayed_message");
        POSIX::_exit(0);
    }

    my $val = $q->pop_wait(5);
    waitpid($pid, 0);
    is $val, "delayed_message", 'str blocking pop received value';

    $q->unlink;
};

# Str: clear() unblocks push_wait
my $path5 = tmpnam() . '.shm';
END { unlink $path5 if $$ == $main_pid && $path5 && -f $path5 }

subtest 'str clear unblocks push_wait' => sub {
    my $q = Data::Queue::Shared::Str->new($path5, 4, 4096);
    $q->push("x") for 1..4;  # fill

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Str->new($path5, 4, 4096);
        select(undef, undef, undef, 0.1);
        $cq->clear;
        POSIX::_exit(0);
    }

    my $t0 = time;
    ok $q->push_wait("after_clear", 5), 'push_wait succeeded after clear()';
    ok time - $t0 < 4, 'unblocked promptly';
    waitpid($pid, 0);

    $q->unlink;
};

# Str: clear() wakes blocked pop_wait consumers
my $path6 = tmpnam() . '.shm';
END { unlink $path6 if $$ == $main_pid && $path6 && -f $path6 }

subtest 'str clear wakes pop_wait' => sub {
    my $q = Data::Queue::Shared::Str->new($path6, 4, 4096);

    my $pid = fork();
    die "fork: $!" unless defined $pid;

    if ($pid == 0) {
        my $cq = Data::Queue::Shared::Str->new($path6, 4, 4096);
        select(undef, undef, undef, 0.1);
        $cq->clear;  # should wake the blocked consumer
        select(undef, undef, undef, 0.1);
        $cq->push("after_clear");  # then push something
        POSIX::_exit(0);
    }

    # Parent blocks in pop_wait — clear wakes it, then it re-blocks,
    # then the push wakes it again with actual data
    my $t0 = time;
    my $val = $q->pop_wait(5);
    ok time - $t0 < 4, 'pop_wait did not hang after clear';
    is $val, "after_clear", 'got value pushed after clear';

    waitpid($pid, 0);
    $q->unlink;
};

done_testing;
