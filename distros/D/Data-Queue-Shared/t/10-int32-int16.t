use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX ();
use Data::Queue::Shared;

# ---- Int32 ----
subtest 'int32 basic' => sub {
    my $q = Data::Queue::Shared::Int32->new(undef, 16);
    ok $q, 'created Int32 queue';
    is $q->capacity, 16, 'capacity';
    ok $q->is_empty, 'empty';

    $q->push(42);
    is $q->pop, 42, 'push/pop';
    is $q->pop, undef, 'pop empty';

    # FIFO
    $q->push($_) for 1..5;
    my @got;
    push @got, $q->pop for 1..5;
    is_deeply \@got, [1..5], 'FIFO order';

    # Full
    $q->push($_) for 1..16;
    ok $q->is_full, 'full';
    ok !$q->push(99), 'push fails when full';
    $q->clear;
    ok $q->is_empty, 'clear';

    # Negative values
    $q->push(-100);
    is $q->pop, -100, 'negative';

    # Int32 range: -2^31 .. 2^31-1
    $q->push(2147483647);
    is $q->pop, 2147483647, 'max int32';
    $q->push(-2147483648);
    is $q->pop, -2147483648, 'min int32';

    # Batch
    my $n = $q->push_multi(10, 20, 30);
    is $n, 3, 'push_multi';
    @got = $q->pop_multi(3);
    is_deeply \@got, [10, 20, 30], 'pop_multi';

    # Drain
    $q->push($_) for 1..5;
    @got = $q->drain;
    is_deeply \@got, [1..5], 'drain';

    # Peek
    $q->push(77);
    is $q->peek, 77, 'peek';
    is $q->size, 1, 'size after peek';
    $q->pop;

    # Stats
    my $s = $q->stats;
    ok $s->{push_ok} > 0, 'stats push_ok';
};

# ---- Int16 ----
subtest 'int16 basic' => sub {
    my $q = Data::Queue::Shared::Int16->new(undef, 16);
    ok $q, 'created Int16 queue';

    $q->push(42);
    is $q->pop, 42, 'push/pop';

    # FIFO
    $q->push($_) for 1..5;
    my @got;
    push @got, $q->pop for 1..5;
    is_deeply \@got, [1..5], 'FIFO';

    # Int16 range: -32768 .. 32767
    $q->push(32767);
    is $q->pop, 32767, 'max int16';
    $q->push(-32768);
    is $q->pop, -32768, 'min int16';

    # Batch + drain
    $q->push_multi(100, 200, 300);
    @got = $q->drain;
    is_deeply \@got, [100, 200, 300], 'batch+drain';
};

# ---- Int32 cross-process ----
subtest 'int32 cross-process' => sub {
    my $q = Data::Queue::Shared::Int32->new(undef, 256);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        $q->push($_) for 1..100;
        POSIX::_exit(0);
    }

    my @got;
    while (@got < 100) {
        my $v = $q->pop_wait(5);
        last unless defined $v;
        push @got, $v;
    }
    waitpid($pid, 0);
    my @sorted = sort { $a <=> $b } @got;
    is_deeply \@sorted, [1..100], 'cross-process FIFO';
};

# ---- Int32 blocking ----
subtest 'int32 blocking' => sub {
    my $q = Data::Queue::Shared::Int32->new(undef, 64);

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        select(undef, undef, undef, 0.1);
        $q->push(12345);
        POSIX::_exit(0);
    }

    my $val = $q->pop_wait(5);
    waitpid($pid, 0);
    is $val, 12345, 'blocking pop';
};

# ---- Int32 file-backed ----
subtest 'int32 file-backed' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int32->new($p, 32);
    $q->push(42);
    $q->sync;

    my $q2 = Data::Queue::Shared::Int32->new($p, 32);
    is $q2->pop, 42, 'file-backed persistence';
    unlink $p;
};

# ---- Int32 memfd ----
subtest 'int32 memfd' => sub {
    my $q = Data::Queue::Shared::Int32->new_memfd("test32", 32);
    ok $q, 'memfd';
    ok $q->memfd >= 0, 'memfd fd';
    $q->push(99);
    is $q->pop, 99, 'memfd push/pop';
};

# ---- Int16 memfd ----
subtest 'int16 memfd' => sub {
    my $q = Data::Queue::Shared::Int16->new_memfd("test16", 32);
    $q->push(500);
    is $q->pop, 500, 'int16 memfd';
};

# ---- Int32 eventfd ----
subtest 'int32 eventfd' => sub {
    my $q = Data::Queue::Shared::Int32->new(undef, 16);
    my $fd = $q->eventfd;
    ok $fd >= 0, 'eventfd';
    is $q->fileno, $fd, 'fileno';
    $q->push(1);
    $q->notify;
    $q->eventfd_consume;
    is $q->pop, 1, 'eventfd round-trip';
};

# ---- Slot size verification (8 bytes vs 16 for Int) ----
subtest 'slot size efficiency' => sub {
    my $cap = 1024;
    my $q64 = Data::Queue::Shared::Int->new(undef, $cap);
    my $q32 = Data::Queue::Shared::Int32->new(undef, $cap);
    my $q16 = Data::Queue::Shared::Int16->new(undef, $cap);

    my $s64 = $q64->stats->{mmap_size};
    my $s32 = $q32->stats->{mmap_size};
    my $s16 = $q16->stats->{mmap_size};

    # Int: 256 header + 1024*16 = 16640
    # Int32/Int16: 256 header + 1024*8 = 8448
    ok $s32 < $s64, "Int32 mmap ($s32) < Int ($s64)";
    is $s32, $s16, "Int32 mmap == Int16 mmap (same slot size)";
    cmp_ok $s32, '==', 256 + $cap * 8, 'Int32: header + 8*cap';
    cmp_ok $s64, '==', 256 + $cap * 16, 'Int: header + 16*cap';
};

# ---- Mode mismatch ----
subtest 'mode mismatch' => sub {
    my $p = tmpnam() . '.shm';
    Data::Queue::Shared::Int32->new($p, 8);
    eval { Data::Queue::Shared::Int16->new($p, 8) };
    like $@, qr/invalid|incompatible/, 'Int32 vs Int16 mismatch';
    eval { Data::Queue::Shared::Int->new($p, 8) };
    like $@, qr/invalid|incompatible/, 'Int32 vs Int mismatch';
    unlink $p;
};

done_testing;
