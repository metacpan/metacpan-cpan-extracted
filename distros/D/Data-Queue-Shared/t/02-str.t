use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Queue::Shared;

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

# Basic create
my $q = Data::Queue::Shared::Str->new($path, 16);
ok $q, 'created str queue';
is $q->size, 0, 'starts empty';

# Push/pop
ok $q->push("hello"), 'push hello';
is $q->size, 1, 'size 1';
is $q->pop, "hello", 'pop returns hello';
is $q->pop, undef, 'pop empty returns undef';

# FIFO ordering
$q->push("msg$_") for 1..5;
my @got;
push @got, $q->pop for 1..5;
is_deeply \@got, [map { "msg$_" } 1..5], 'FIFO order';

# Empty string
ok $q->push(""), 'push empty string';
my $v = $q->pop;
is $v, "", 'pop returns empty string';
ok defined $v, 'empty string is defined';

# UTF-8 preservation
my $utf8_str = "\x{263A}";  # smiley
utf8::encode(my $encoded = $utf8_str);
ok $q->push($utf8_str), 'push UTF-8 string';
my $got = $q->pop;
ok utf8::is_utf8($got), 'UTF-8 flag preserved';
is $got, $utf8_str, 'UTF-8 content correct';

# Binary data
my $bin = "\x00\x01\x02\xff\xfe";
ok $q->push($bin), 'push binary';
is $q->pop, $bin, 'pop binary';

# Fill to capacity
my $cap = $q->capacity;
ok $q->push("x" x 10), "push item $_" for 1..$cap;
ok $q->is_full, 'full';
ok !$q->push("overflow"), 'push fails when full';

# Drain
$q->pop for 1..$cap;
ok $q->is_empty, 'empty after drain';

# Arena wrap-around: push large strings, pop, push again
my $big = "A" x 200;
for my $round (1..3) {
    $q->push($big) for 1..5;
    for (1..5) {
        my $v = $q->pop;
        is $v, $big, "round $round: large string preserved";
    }
}

# Batch operations
my $n = $q->push_multi("a", "b", "c");
is $n, 3, 'push_multi 3';
my @batch = $q->pop_multi(2);
is_deeply \@batch, ["a", "b"], 'pop_multi 2';
is $q->pop, "c", 'remaining element';

# Clear
$q->push("x") for 1..5;
$q->clear;
is $q->size, 0, 'clear works';
is $q->pop, undef, 'pop after clear';

# Push after clear (arena reset)
ok $q->push("after_clear"), 'push after clear';
is $q->pop, "after_clear", 'pop after clear push';

# Stats
my $s = $q->stats;
ok $s->{push_ok} > 0, 'stats push_ok';
ok $s->{arena_cap} > 0, 'stats arena_cap';
is $s->{capacity}, $cap, 'stats capacity';

# Path
is $q->path, $path, 'path correct';

# Reopen
my $q2 = Data::Queue::Shared::Str->new($path, 16);
$q->push("cross");
is $q2->pop, "cross", 'cross-handle works';

# pop_wait timeout
my $t0 = time;
is $q->pop_wait(0.1), undef, 'pop_wait timeout';
cmp_ok time - $t0, '<', 30, 'pop_wait returned (not hung)';

# Arena-full condition (slots available but arena exhausted)
# arena_cap minimum is 4096; use 2000-byte strings to fill it
{
    my $apath = tmpnam() . '.shm';
    my $aq = Data::Queue::Shared::Str->new($apath, 256, 4096);
    my $big = "X" x 2000;
    ok $aq->push($big), 'arena: push 1st big string';
    ok $aq->push($big), 'arena: push 2nd big string';  # 4000/4096 used
    ok !$aq->push($big), 'arena: 3rd push fails (arena full, slots available)';
    my $as = $aq->stats;
    ok $as->{push_full} > 0, 'arena: push_full stat counted';
    ok $as->{arena_used} > 0, 'arena: arena_used > 0';
    is $aq->pop, $big, 'arena: pop 1st';
    is $aq->pop, $big, 'arena: pop 2nd';
    ok $aq->is_empty, 'arena: empty after drain';
    ok $aq->push($big), 'arena: push after drain succeeds';
    unlink $apath;
}

# push_wait timeout when full
{
    my $fpath = tmpnam() . '.shm';
    my $fq = Data::Queue::Shared::Str->new($fpath, 4, 4096);
    $fq->push("a") for 1..4;
    my $t0 = time;
    ok !$fq->push_wait("overflow", 0.1), 'str push_wait timeout when full';
    cmp_ok time - $t0, '<', 30, 'str push_wait returned (not hung)';
    unlink $fpath;
}

# Explicit arena size
my $path2 = tmpnam() . '.shm';
END { unlink $path2 if $path2 && -f $path2 }
my $q3 = Data::Queue::Shared::Str->new($path2, 8, 4096);
ok $q3, 'created with explicit arena';
my $s3 = $q3->stats;
is $s3->{arena_cap}, 4096, 'arena_cap matches';

$q->unlink;
done_testing;
