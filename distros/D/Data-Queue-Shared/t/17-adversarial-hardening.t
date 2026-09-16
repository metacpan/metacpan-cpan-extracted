use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use POSIX ();
use Time::HiRes qw(time);
use Data::Queue::Shared;

# 1. pop_multi and pop_wait_multi count capping at capacity
{
    my $qi = Data::Queue::Shared::Int->new(undef, 8);
    $qi->push($_) for 1 .. 8;
    # Requesting 1_000_000 items must be capped at capacity
    my @popped = $qi->pop_multi(1_000_000);
    is scalar(@popped), 8, "Int->pop_multi caps requested count at capacity";
    is_deeply \@popped, [1 .. 8], "all items correctly popped";

    # Int32
    my $qi32 = Data::Queue::Shared::Int32->new(undef, 4);
    $qi32->push($_) for 1 .. 4;
    @popped = $qi32->pop_multi(999_999);
    is scalar(@popped), 4, "Int32->pop_multi caps count at capacity";

    # Int16
    my $qi16 = Data::Queue::Shared::Int16->new(undef, 4);
    $qi16->push($_) for 1 .. 4;
    @popped = $qi16->pop_multi(999_999);
    is scalar(@popped), 4, "Int16->pop_multi caps count at capacity";

    # Str pop_wait_multi capping
    my $qs = Data::Queue::Shared::Str->new(undef, 4);
    $qs->push("item$_") for 1 .. 4;
    my @spopped = $qs->pop_wait_multi(100_000, 0.1);
    is scalar(@spopped), 4, "Str->pop_wait_multi caps count at capacity";
}

# 2. File header validation: reject capacity < 2
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    close $fh;

    # Create a valid queue first to obtain valid total_size and offsets
    my $q = Data::Queue::Shared::Int->new($path, 4);
    $q->push(10);
    undef $q;

    # Corrupt header: set capacity = 1 (offset 12 is uint32 capacity)
    open my $rfh, "+<", $path or die "cannot open $path: $!";
    binmode $rfh;
    seek $rfh, 12, 0; # offset 12: capacity
    print $rfh pack("L", 1); # capacity = 1
    close $rfh;

    # Attempt to open corrupted file; must be rejected
    eval {
        my $bad = Data::Queue::Shared::Int->new($path, 4);
    };
    ok $@, "opening file with capacity == 1 is rejected";
    like $@, qr/invalid or incompatible/, "expected error message for capacity < 2";
    unlink $path;
}

# 3. File header validation: reject arena_cap < 4096 in Str mode
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    close $fh;

    my $qs = Data::Queue::Shared::Str->new($path, 4, 4096);
    undef $qs;

    # Corrupt header: set arena_cap = 0 (offset 40 is uint64 arena_cap)
    open my $rfh, "+<", $path or die "cannot open $path: $!";
    binmode $rfh;
    seek $rfh, 40, 0; # offset 40: arena_cap
    print $rfh pack("Q", 0); # arena_cap = 0
    close $rfh;

    eval {
        my $bad = Data::Queue::Shared::Str->new($path, 4);
    };
    ok $@, "opening Str queue with arena_cap == 0 is rejected";
    like $@, qr/invalid or incompatible/, "expected error message for arena_cap < 4096";
    unlink $path;
}

# 4. Arena underflow protection in pop and pop_back
{
    my $qs = Data::Queue::Shared::Str->new(undef, 8, 4096);
    $qs->push("hello");
    $qs->push("world");

    # Stats before pop
    my $st = $qs->stats;
    ok $st->{arena_used} > 0, "arena_used > 0 after pushes";

    # Normal pop
    is $qs->pop, "hello", "pop first item";

    # Pop back
    is $qs->pop_back, "world", "pop_back second item";

    $st = $qs->stats;
    is $st->{arena_used}, 0, "arena_used is 0 after draining";

    # Subsequent push works cleanly
    ok $qs->push("fresh"), "push after drain succeeds";
    is $qs->pop, "fresh", "pop after drain succeeds";
}

# 6. Str::push_multi consumer wakeup on oversized item croak
{
    my $q = Data::Queue::Shared::Str->new(undef, 8, 4096);
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $item = $q->pop_wait(5.0);
        POSIX::_exit($item && $item eq 'valid_item' ? 0 : 1);
    }
    select(undef, undef, undef, 0.05); # let child enter pop_wait
    my $oversized = "X" x 5000;
    my $t0 = time();
    eval {
        $q->push_multi("valid_item", $oversized);
    };
    ok $@, "push_multi croaked on oversized item";
    waitpid($pid, 0);
    my $elapsed = time() - $t0;
    is $?, 0, "waiting consumer popped the valid item";
    ok $elapsed < 2.5, "consumer was woken, not left to its 5s timeout (${elapsed}s)";
}

# 7. Non-regular file rejection (FIFO)
{
    use File::Temp qw(tempdir);
    my $dir = tempdir(CLEANUP => 1);
    my $fifo = "$dir/test.fifo";
    require POSIX;
    if (POSIX::mkfifo($fifo, 0600)) {
        eval { Data::Queue::Shared::Int->new($fifo, 4) };
        ok $@, "new on FIFO is rejected";
        like $@, qr/invalid \(not a regular file\)/, "expected error for FIFO";
    }
}

# 8. push_wait_multi: the timeout bounds the waiting, never values that fit
{
    my $qi = Data::Queue::Shared::Int->new(undef, 1024);
    is $qi->push_wait_multi(0.000001, 1 .. 1000), 1000,
        "Int: a tiny timeout still pushes every value that fits";
    my $qs = Data::Queue::Shared::Str->new(undef, 1024);
    is $qs->push_wait_multi(0.000001, map { "s$_" } 1 .. 1000), 1000,
        "Str: a tiny timeout still pushes every value that fits";

    my $q = Data::Queue::Shared::Int->new(undef, 2);
    $q->push(1);
    $q->push(2); # queue is now completely full
    my $t0 = time();
    my $pushed = $q->push_wait_multi(0.2, 10, 20, 30);
    my $elapsed = time() - $t0;
    is $pushed, 0, "no items pushed to full queue within timeout";
    ok $elapsed < 1.0, "push_wait_multi respected its timeout (elapsed ${elapsed}s < 1.0s)";
}

# 9. Size underflow / skew safety when tail < head in header
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    close $fh;
    my $q = Data::Queue::Shared::Int->new($path, 8);
    undef $q;

    open my $rfh, "+<", $path or die "open $path: $!";
    binmode $rfh;
    seek $rfh, 64, 0; # head
    print $rfh pack("Q<", 10);
    seek $rfh, 128, 0; # tail
    print $rfh pack("Q<", 0);
    close $rfh;

    my $q2 = Data::Queue::Shared::Int->new($path, 8);
    is $q2->size, 0, "size returns 0 when head > tail (skew/corruption guard)";
    ok $q2->is_empty, "is_empty returns true when head > tail";
    ok !$q2->is_full, "is_full returns false when head > tail";
}

# 10. pop_wait_multi(0) must return empty list without consuming items
{
    for my $variant (qw(Int Str)) {
        my $pkg = "Data::Queue::Shared::$variant";
        my $q = $pkg->new(undef, 4);
        my $val = ($variant eq 'Str') ? "hello" : 42;
        $q->push($val);
        my @popped = $q->pop_wait_multi(0, 0.5);
        is scalar(@popped), 0, "$variant: pop_wait_multi(0) returns empty list";
        is $q->size, 1, "$variant: item remains unconsumed in queue";
        is $q->pop, $val, "$variant: item can subsequently be popped";
    }
}

# 11. Str push_multi argument count capped at capacity
{
    my $q = Data::Queue::Shared::Str->new(undef, 4);
    # Pass 100 items to a capacity-4 queue
    my @items = map { "str$_" } 1 .. 100;
    my $pushed = $q->push_multi(@items);
    is $pushed, 4, "Str->push_multi capped pushes at capacity (4)";
    is $q->size, 4, "queue size is 4";
    my @got = $q->drain;
    is_deeply \@got, ["str1", "str2", "str3", "str4"], "first 4 items preserved in order";
}

done_testing;
