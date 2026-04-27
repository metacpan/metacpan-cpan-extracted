use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Stack::Shared;

# --- Int stack ---
my $stk = Data::Stack::Shared::Int->new(undef, 10);
ok $stk, 'created Int stack';
is $stk->capacity, 10;
is $stk->size, 0;
ok $stk->is_empty;

ok $stk->push(10), 'push 10';
ok $stk->push(20), 'push 20';
ok $stk->push(30), 'push 30';
is $stk->size, 3;

is $stk->peek, 30, 'peek returns top (LIFO)';
is $stk->pop, 30, 'pop returns 30';
is $stk->pop, 20, 'pop returns 20';
is $stk->pop, 10, 'pop returns 10';
ok !defined $stk->pop, 'pop on empty returns undef';
ok $stk->is_empty;

# fill to capacity
ok $stk->push($_), "push $_" for 1..10;
ok $stk->is_full, 'full after 10 pushes';
ok !$stk->push(99), 'push fails when full';

# pop all — LIFO order
my @got;
while (defined(my $v = $stk->pop)) { push @got, $v }
is_deeply \@got, [reverse 1..10], 'LIFO order';

# clear
$stk->push($_) for 1..5;
$stk->clear;
is $stk->size, 0, 'clear empties stack';

# blocking pop with timeout
my $t0 = time;
ok !defined $stk->pop_wait(0.1), 'pop_wait timeout';
cmp_ok time - $t0, '<', 30, 'pop_wait returned (not hung)';

# blocking push with timeout
$stk->push($_) for 1..10;
$t0 = time;
ok !$stk->push_wait(99, 0.1), 'push_wait timeout when full';
cmp_ok time - $t0, '<', 30, 'push_wait returned (not hung)';
$stk->clear;

# cross-process
$stk->push(42);
my $pid = fork // die;
if ($pid == 0) {
    my $v = $stk->pop;
    _exit($v == 42 ? 0 : 1);
}
waitpid($pid, 0);
is $? >> 8, 0, 'child popped parent value';

# futex wakeup: child pushes, parent pops
$pid = fork // die;
if ($pid == 0) {
    select(undef, undef, undef, 0.05);
    $stk->push(77);
    _exit(0);
}
my $val = $stk->pop_wait(2.0);
is $val, 77, 'blocking pop woke on child push';
waitpid($pid, 0);

# --- Str stack ---
my $ss = Data::Stack::Shared::Str->new(undef, 5, 32);
ok $ss, 'created Str stack';
ok $ss->push("hello"), 'push str';
ok $ss->push("world"), 'push str 2';
is $ss->pop, "world", 'LIFO str';
is $ss->pop, "hello";
ok !defined $ss->pop;

# Str common methods work via @ISA
is $ss->capacity, 5, 'Str capacity via ISA';
is $ss->size, 0, 'Str size via ISA';
ok $ss->is_empty, 'Str is_empty via ISA';

# Str peek
$ss->push("peek_test");
is $ss->peek, "peek_test", 'Str peek';
$ss->clear;
is $ss->size, 0, 'Str clear via ISA';

# Str binary data
$ss->push("a\x00b\x00c");
is $ss->pop, "a\x00b\x00c", 'Str with null bytes';

# Str DESTROY — should not leak (was a critical bug before fix)
{
    my $tmp = Data::Stack::Shared::Str->new(undef, 3, 16);
    $tmp->push("leak test");
}
pass('Str DESTROY did not leak');

# --- stats ---
my $s = $stk->stats;
ok ref $s eq 'HASH';
ok $s->{pushes} > 0;
ok $s->{pops} > 0;

# Str stats via ISA
my $ss2 = Data::Stack::Shared::Str->new(undef, 3, 16);
$ss2->push("x");
$ss2->pop;
my $ss2_stats = $ss2->stats;
is $ss2_stats->{pushes}, 1, 'Str stats pushes';
is $ss2_stats->{pops}, 1, 'Str stats pops';

# --- file-backed ---

my $path = tmpnam() . '.shm';
{
    my $fs = Data::Stack::Shared::Int->new($path, 10);
    $fs->push(111);
    $fs->push(222);
    is $fs->path, $path, 'path';
}
# reopen
{
    my $fs = Data::Stack::Shared::Int->new($path, 10);
    is $fs->size, 2, 'file-backed persistence';
    is $fs->pop, 222, 'persisted LIFO';
    is $fs->pop, 111;
}
unlink $path;

# --- memfd / new_from_fd ---

my $ms = Data::Stack::Shared::Int->new_memfd("test_stk", 10);
ok $ms, 'memfd created';
my $mfd = $ms->memfd;
ok $mfd >= 0, 'memfd fd valid';
$ms->push(42);

my $ms2 = Data::Stack::Shared::Int->new_from_fd($mfd);
is $ms2->pop, 42, 'data via new_from_fd';

# memfd across fork
$ms->push(99);
$pid = fork // die;
if ($pid == 0) {
    my $child = Data::Stack::Shared::Int->new_from_fd($mfd);
    _exit($child->pop == 99 ? 0 : 1);
}
waitpid($pid, 0);
is $? >> 8, 0, 'memfd fd inherited across fork';

# --- eventfd ---

my $es = Data::Stack::Shared::Int->new(undef, 5);
is $es->fileno, -1, 'no eventfd initially';
my $efd = $es->eventfd;
ok $efd >= 0, 'eventfd created';
is $es->fileno, $efd, 'fileno returns eventfd';
ok $es->notify, 'notify';
ok $es->notify, 'notify again';
my $count = $es->eventfd_consume;
is $count, 2, 'eventfd_consume returns accumulated count';

# --- drain ---

my $sd = Data::Stack::Shared::Int->new(undef, 8);
$sd->push($_) for 1..5;
is $sd->size, 5, 'size before drain';
is $sd->drain, 5, 'drain returns discarded count';
is $sd->size, 0, 'empty after drain';
is $sd->drain, 0, 'drain on empty returns 0';

# --- sync / unlink ---

my $upath = tmpnam() . '.shm';
my $us = Data::Stack::Shared::Int->new($upath, 5);
$us->push(1);
eval { $us->sync };
ok !$@, 'sync does not croak';
$us->unlink;
ok !-f $upath, 'unlink removed file';

done_testing;
