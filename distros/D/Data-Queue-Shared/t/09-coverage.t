use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Queue::Shared;

# ---- Constructor error paths ----
subtest 'constructor errors' => sub {
    # Mismatched mode: create as Int, open as Str
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 8);
    eval { Data::Queue::Shared::Str->new($p, 8) };
    like $@, qr/invalid|incompatible/, 'open Int file as Str croaks';
    unlink $p;

    # Mismatched mode: create as Str, open as Int
    my $p2 = tmpnam() . '.shm';
    my $q2 = Data::Queue::Shared::Str->new($p2, 8);
    eval { Data::Queue::Shared::Int->new($p2, 8) };
    like $@, qr/invalid|incompatible/, 'open Str file as Int croaks';
    unlink $p2;
};

# ---- Partial batch push (queue fills mid-batch) ----
subtest 'partial push_multi' => sub {
    my $p = tmpnam() . '.shm';

    # Int: push_multi with more items than capacity
    my $q = Data::Queue::Shared::Int->new($p, 4);
    $q->push(1);
    $q->push(2);
    # 2 slots used, 2 remaining
    my $n = $q->push_multi(10, 20, 30, 40, 50);
    is $n, 2, 'int push_multi partial: pushed 2 of 5';
    is $q->size, 4, 'queue full after partial push';
    my @got = $q->drain;
    is_deeply \@got, [1, 2, 10, 20], 'values correct';
    unlink $p;

    # Str: push_multi partial
    my $p2 = tmpnam() . '.shm';
    my $q2 = Data::Queue::Shared::Str->new($p2, 4);
    $q2->push("a");
    $q2->push("b");
    $n = $q2->push_multi("c", "d", "e", "f");
    is $n, 2, 'str push_multi partial: pushed 2 of 4';
    @got = $q2->drain;
    is_deeply \@got, ["a", "b", "c", "d"], 'str values correct';
    unlink $p2;
};

# ---- Partial push_wait_multi (fills mid-batch with timeout) ----
subtest 'partial push_wait_multi' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 4);
    $q->push(1);
    $q->push(2);
    # 2 remaining; push 5 with timeout=0 (try once)
    my $n = $q->push_wait_multi(0, 10, 20, 30, 40, 50);
    is $n, 2, 'int push_wait_multi partial with timeout=0';
    $q->drain;
    unlink $p;
};

# ---- Class-method unlink ----
subtest 'class method unlink' => sub {
    my $p = tmpnam() . '.shm';
    Data::Queue::Shared::Int->new($p, 4);
    ok -f $p, 'file exists';
    Data::Queue::Shared::Int->unlink($p);
    ok !-f $p, 'class method unlink removed file';

    my $p2 = tmpnam() . '.shm';
    Data::Queue::Shared::Str->new($p2, 4);
    Data::Queue::Shared::Str->unlink($p2);
    ok !-f $p2, 'str class method unlink';
};

# ---- sync persistence round-trip ----
subtest 'sync persistence' => sub {
    my $p = tmpnam() . '.shm';
    {
        my $q = Data::Queue::Shared::Int->new($p, 16);
        $q->push(42);
        $q->push(99);
        $q->sync;
    }
    # Reopen and verify
    my $q2 = Data::Queue::Shared::Int->new($p, 16);
    is $q2->pop, 42, 'sync: value 1 persisted';
    is $q2->pop, 99, 'sync: value 2 persisted';
    unlink $p;

    my $p2 = tmpnam() . '.shm';
    {
        my $q = Data::Queue::Shared::Str->new($p2, 16);
        $q->push("hello");
        $q->sync;
    }
    my $q3 = Data::Queue::Shared::Str->new($p2, 16);
    is $q3->pop, "hello", 'str sync: persisted';
    unlink $p2;
};

# ---- Str pop_empty stat ----
subtest 'str pop_empty stat' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Str->new($p, 8);
    $q->pop;  # empty
    my $s = $q->stats;
    ok $s->{pop_empty} > 0, 'str pop_empty stat counted';
    unlink $p;
};

# ---- Str push_full via arena exhaustion stat ----
subtest 'str push_full stat' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Str->new($p, 4);
    $q->push("x") for 1..4;
    $q->push("overflow");  # fails: full
    my $s = $q->stats;
    ok $s->{push_full} > 0, 'str push_full stat counted';
    unlink $p;
};

# ---- stats mmap_size field ----
subtest 'stats mmap_size' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 16);
    my $s = $q->stats;
    ok $s->{mmap_size} > 0, 'int mmap_size > 0';
    ok $s->{mmap_size} >= 256 + 16 * 16, 'int mmap_size >= header + slots';
    unlink $p;

    my $p2 = tmpnam() . '.shm';
    my $q2 = Data::Queue::Shared::Str->new($p2, 8, 4096);
    my $s2 = $q2->stats;
    ok $s2->{mmap_size} > 4096, 'str mmap_size > arena_cap';
    unlink $p2;
};

# ---- DESTROY / use-after-destroy ----
subtest 'use after destroy' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 4);
    $q->push(1);
    undef $q;  # triggers DESTROY
    # $q is now undef, can't call methods — just verify no crash
    ok 1, 'DESTROY did not crash';
    unlink $p;
};

# ---- capacity rounding ----
subtest 'capacity rounding' => sub {
    my $p = tmpnam() . '.shm';
    my $q = Data::Queue::Shared::Int->new($p, 5);
    is $q->capacity, 8, 'capacity 5 rounds to 8';
    unlink $p;

    my $p2 = tmpnam() . '.shm';
    my $q2 = Data::Queue::Shared::Int->new($p2, 1);
    is $q2->capacity, 2, 'capacity 1 rounds to 2';
    unlink $p2;
};

# ---- peek on Int after pop ----
subtest 'int peek edge cases' => sub {
    my $q = Data::Queue::Shared::Int->new(undef, 8);
    is $q->peek, undef, 'peek empty';
    $q->push(1);
    $q->push(2);
    is $q->peek, 1, 'peek front';
    $q->pop;
    is $q->peek, 2, 'peek after pop';
    $q->pop;
    is $q->peek, undef, 'peek after drain';
};

# ---- Str pop_back on single element ----
subtest 'str pop_back single' => sub {
    my $q = Data::Queue::Shared::Str->new(undef, 8);
    $q->push("only");
    is $q->pop_back, "only", 'pop_back single element';
    ok $q->is_empty, 'empty after pop_back single';
};

done_testing;
