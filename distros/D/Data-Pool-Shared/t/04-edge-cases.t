use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Data::Pool::Shared;

# --- Capacity boundary tests ---

for my $cap (1, 2, 63, 64, 65, 127, 128, 129) {
    my $pool = Data::Pool::Shared::I64->new(undef, $cap);
    is $pool->capacity, $cap, "capacity $cap";

    # fill to capacity
    my @slots;
    my $alloc_ok = 1;
    for my $n (1..$cap) {
        my $s = $pool->alloc;
        unless (defined $s) { $alloc_ok = 0; last }
        $pool->set($s, $n);
        push @slots, $s;
    }
    ok $alloc_ok, "cap=$cap alloc 1..$cap";
    is $pool->used, $cap, "cap=$cap fully used";
    ok !defined $pool->try_alloc, "cap=$cap full";

    # spot-check first and last
    is $pool->get($slots[0]), 1, "cap=$cap first slot";
    is $pool->get($slots[-1]), $cap, "cap=$cap last slot";

    $pool->free($_) for @slots;
    is $pool->used, 0, "cap=$cap all freed";
}

# --- I64 extreme values ---

my $i64 = Data::Pool::Shared::I64->new(undef, 4);
my $s = $i64->alloc;

# max positive IV
my $max_iv = ~0 >> 1;  # 2^63-1
$i64->set($s, $max_iv);
is $i64->get($s), $max_iv, "I64 max IV";

# min negative IV
my $min_iv = -(~0 >> 1) - 1;  # -2^63
$i64->set($s, $min_iv);
is $i64->get($s), $min_iv, "I64 min IV";

# -1
$i64->set($s, -1);
is $i64->get($s), -1, "I64 -1";

# 0
$i64->set($s, 0);
is $i64->get($s), 0, "I64 0";

# CAS with negative values
$i64->set($s, -100);
ok $i64->cas($s, -100, -200), "I64 cas negative";
is $i64->get($s), -200, "I64 cas result negative";

# add overflow (wraps)
$i64->set($s, $max_iv);
my $wrapped = $i64->add($s, 1);
is $wrapped, $min_iv, "I64 add overflow wraps to min";

# incr/decr at boundaries
$i64->set($s, 0);
is $i64->decr($s), -1, "I64 decr from 0";
$i64->set($s, -1);
is $i64->incr($s), 0, "I64 incr from -1";

$i64->free($s);

# --- F64 edge values ---

my $f64 = Data::Pool::Shared::F64->new(undef, 4);
$s = $f64->alloc;

# Infinity
$f64->set($s, 9e999);
my $v = $f64->get($s);
ok $v == 9e999, "F64 +Inf";

# -Infinity
$f64->set($s, -9e999);
$v = $f64->get($s);
ok $v == -9e999, "F64 -Inf";

# NaN
$f64->set($s, 9e999 / 9e999);
$v = $f64->get($s);
ok $v != $v, "F64 NaN (NaN != NaN)";

# Negative zero
$f64->set($s, -0.0);
$v = $f64->get($s);
ok $v == 0.0, "F64 -0.0 compares equal to 0.0";

# Very small
$f64->set($s, 5e-324);
$v = $f64->get($s);
ok $v > 0 && $v < 1e-300, "F64 denormalized";

$f64->free($s);

# --- I32 extremes ---

my $i32 = Data::Pool::Shared::I32->new(undef, 4);
$s = $i32->alloc;

$i32->set($s, 2147483647);  # INT32_MAX
is $i32->get($s), 2147483647, "I32 max";

$i32->set($s, -2147483648);  # INT32_MIN
is $i32->get($s), -2147483648, "I32 min";

# add wrap
$i32->set($s, 2147483647);
my $w = $i32->add($s, 1);
is $w, -2147483648, "I32 add overflow wraps";

$i32->free($s);

# --- Str edge cases ---

my $str = Data::Pool::Shared::Str->new(undef, 4, 32);
$s = $str->alloc;

# empty string
$str->set($s, "");
is $str->get($s), "", "Str empty string";

# null bytes (binary data)
my $bin = "a\x00b\x00c";
$str->set($s, $bin);
is $str->get($s), $bin, "Str with null bytes";
is length($str->get($s)), 5, "Str null byte length preserved";

# full max_len
my $full = "x" x 32;
$str->set($s, $full);
is $str->get($s), $full, "Str full max_len";
is length($str->get($s)), 32, "Str full length";

# exceeds max_len — truncated
my $long = "y" x 100;
$str->set($s, $long);
is length($str->get($s)), 32, "Str truncated to max_len";
is $str->get($s), "y" x 32, "Str truncated content";

$str->free($s);

# --- Error paths ---

my $pool = Data::Pool::Shared::I64->new(undef, 5);

# out of range
eval { $pool->get(99) };
like $@, qr/out of range/, "get out of range";

eval { $pool->set(99, 1) };
like $@, qr/out of range/, "set out of range";

eval { $pool->free(99) };
like $@, qr/out of range/, "free out of range";

eval { $pool->is_allocated(99) };
like $@, qr/out of range/, "is_allocated out of range";

eval { $pool->owner(99) };
like $@, qr/out of range/, "owner out of range";

# not allocated
eval { $pool->get(0) };
like $@, qr/not allocated/, "get not allocated";

eval { $pool->set(0, 1) };
like $@, qr/not allocated/, "set not allocated";

# I64-specific errors on unallocated
eval { $pool->cas(0, 0, 1) };
like $@, qr/not allocated/, "cas not allocated";

eval { $pool->add(0, 1) };
like $@, qr/not allocated/, "add not allocated";

eval { $pool->incr(0) };
like $@, qr/not allocated/, "incr not allocated";

eval { $pool->decr(0) };
like $@, qr/not allocated/, "decr not allocated";

# slot_sv not allocated
eval { $pool->slot_sv(0) };
like $@, qr/not allocated/, "slot_sv not allocated";

# double free returns false
$s = $pool->alloc;
ok $pool->free($s), "first free ok";
ok !$pool->free($s), "double free returns false";

# free_n with non-arrayref
eval { $pool->free_n("not an array") };
like $@, qr/expected arrayref/, "free_n non-arrayref croaks";

# --- alloc_n / free_n ---

$pool->reset;

my $batch = $pool->alloc_n(3);
ok ref $batch eq 'ARRAY', "alloc_n returns arrayref";
is scalar @$batch, 3, "alloc_n returned 3 slots";
is $pool->used, 3, "3 allocated after alloc_n";

# set values on batch
$pool->set($batch->[$_], $_ * 10) for 0..2;
is $pool->get($batch->[1]), 10, "batch slot value correct";

# free_n
my $freed = $pool->free_n($batch);
is $freed, 3, "free_n freed 3";
is $pool->used, 0, "0 used after free_n";

# alloc_n all-or-nothing: request more than available
$pool->alloc for 1..4;  # 4 of 5 used
my $too_many = $pool->alloc_n(3, 0);
ok !defined $too_many, "alloc_n returns undef when not enough (non-blocking)";
is $pool->used, 4, "no partial allocation left behind";

$pool->reset;

# alloc_n(0) returns empty arrayref
my $empty = $pool->alloc_n(0);
ok ref $empty eq 'ARRAY', "alloc_n(0) returns arrayref";
is scalar @$empty, 0, "alloc_n(0) is empty";

# free_n empty
is $pool->free_n([]), 0, "free_n([]) returns 0";

# --- allocated_slots ---

$pool->reset;
$pool->alloc_set(100);
$pool->alloc_set(200);
$pool->alloc_set(300);

my $slots = $pool->allocated_slots;
ok ref $slots eq 'ARRAY', "allocated_slots returns arrayref";
is scalar @$slots, 3, "allocated_slots has 3 entries";
my @vals = sort map { $pool->get($_) } @$slots;
is_deeply \@vals, [100, 200, 300], "allocated_slots covers all";

$pool->reset;

# allocated_slots on empty pool
$slots = $pool->allocated_slots;
is scalar @$slots, 0, "allocated_slots empty on empty pool";

# --- slot_sv zero-copy ---

my $raw = Data::Pool::Shared->new(undef, 4, 16);
$s = $raw->alloc;
$raw->set($s, "hello world\0\0\0\0\0");

my $sv = $raw->slot_sv($s);
is length($sv), 16, "slot_sv length matches elem_size";
is substr($sv, 0, 11), "hello world", "slot_sv reads slot data";

# slot_sv reflects changes made via set()
$raw->set($s, "updated data\0\0\0\0");
my $sv2 = $raw->slot_sv($s);
is substr($sv2, 0, 12), "updated data", "slot_sv reflects set() changes";

$raw->free($s);

# --- ptr / data_ptr ---

my $ppool = Data::Pool::Shared::I64->new(undef, 10);
my $ps = $ppool->alloc;
$ppool->set($ps, 0xDEADBEEF);

my $ptr = $ppool->ptr($ps);
ok $ptr > 0, "ptr returns non-zero address";

my $dptr = $ppool->data_ptr;
ok $dptr > 0, "data_ptr returns non-zero address";

# ptr should equal data_ptr + slot * elem_size
is $ptr, $dptr + $ps * $ppool->elem_size, "ptr = data_ptr + slot * elem_size";

# verify the pointer actually points to our data (read via unpack from slot_sv)
my $from_sv = unpack('q<', $ppool->slot_sv($ps));
is $from_sv, 0xDEADBEEF, "ptr target matches slot data";

# error: ptr on unallocated
$ppool->free($ps);
eval { $ppool->ptr($ps) };
like $@, qr/not allocated/, "ptr on freed slot croaks";

eval { $ppool->ptr(999) };
like $@, qr/out of range/, "ptr out of range croaks";

# --- try_alloc_guard ---

my $gpool = Data::Pool::Shared::I64->new(undef, 3);

# successful try_alloc_guard in list context
my ($gi, $gg) = $gpool->try_alloc_guard;
ok defined $gi, "try_alloc_guard returns index";
ok ref $gg, "try_alloc_guard returns guard";
$gpool->set($gi, 42);
is $gpool->is_allocated($gi), 1, "try_alloc_guard slot allocated";

# guard auto-frees on scope exit
{ my ($i2, $g2) = $gpool->try_alloc_guard }
is $gpool->used, 1, "try_alloc_guard guard freed on scope exit";

# fill pool, try_alloc_guard returns undef
my @fill_guards;
push @fill_guards, scalar $gpool->try_alloc_guard for 1..2;
my ($fail_i, $fail_g) = $gpool->try_alloc_guard;
ok !defined $fail_i, "try_alloc_guard returns undef when full";
@fill_guards = ();
undef $gg;
is $gpool->used, 0, "all try_alloc_guard guards cleaned up";

# --- Concurrent recovery ---

my $rpath = tmpnam() . '.shm';
END { unlink $rpath if $rpath && -f $rpath }

my $rpool = Data::Pool::Shared::I64->new($rpath, 100);

# Fork 5 children that each alloc 4 slots and die
for (1..5) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $c = Data::Pool::Shared::I64->new($rpath, 100);
        $c->alloc for 1..4;
        _exit(0);
    }
    waitpid($pid, 0);
}
is $rpool->used, 20, "20 stale slots from 5 dead children";

# Two processes recover simultaneously — both call recover_stale
my $rpid = fork // die "fork: $!";
if ($rpid == 0) {
    my $c = Data::Pool::Shared::I64->new($rpath, 100);
    $c->recover_stale;
    _exit(0);
}
# parent also recovers concurrently
$rpool->recover_stale;
waitpid($rpid, 0);

is $rpool->used, 0, "concurrent recovery freed all 20 stale slots";

# --- cmpxchg / xchg ---

my $cx = Data::Pool::Shared::I64->new(undef, 4);
$s = $cx->alloc;
$cx->set($s, 100);

# cmpxchg success — returns old value (== expected)
my $old = $cx->cmpxchg($s, 100, 200);
is $old, 100, "cmpxchg success returns old value";
is $cx->get($s), 200, "cmpxchg updated slot";

# cmpxchg failure — returns actual value (!= expected)
$old = $cx->cmpxchg($s, 999, 300);
is $old, 200, "cmpxchg failure returns actual value";
is $cx->get($s), 200, "cmpxchg did not modify on failure";

# xchg — unconditional swap
$old = $cx->xchg($s, 500);
is $old, 200, "xchg returns old value";
is $cx->get($s), 500, "xchg set new value";

$cx->free($s);

# I32 cmpxchg/xchg
my $cx32 = Data::Pool::Shared::I32->new(undef, 4);
$s = $cx32->alloc;
$cx32->set($s, 10);
$old = $cx32->cmpxchg($s, 10, 20);
is $old, 10, "I32 cmpxchg success";
$old = $cx32->cmpxchg($s, 99, 30);
is $old, 20, "I32 cmpxchg failure returns actual";
$old = $cx32->xchg($s, 77);
is $old, 20, "I32 xchg returns old";
is $cx32->get($s), 77, "I32 xchg set new";
$cx32->free($s);

# --- File persistence ---

my $ppath = tmpnam() . '.shm';
{
    my $p = Data::Pool::Shared::I64->new($ppath, 10);
    my $a = $p->alloc;
    my $b = $p->alloc;
    $p->set($a, 111);
    $p->set($b, 222);
    # handle goes out of scope — mmap unmapped, fd closed
}

# reopen from same path — data should survive
{
    my $p = Data::Pool::Shared::I64->new($ppath, 10);
    is $p->used, 2, "persistence: used=2 after reopen";
    my $slots = $p->allocated_slots;
    is scalar @$slots, 2, "persistence: 2 allocated slots";
    my @vals = sort map { $p->get($_) } @$slots;
    is_deeply \@vals, [111, 222], "persistence: values survived";
}
unlink $ppath;

# Str persistence
my $spath2 = tmpnam() . '.shm';
{
    my $p = Data::Pool::Shared::Str->new($spath2, 5, 32);
    my $a = $p->alloc;
    $p->set($a, "persistent data");
}
{
    my $p = Data::Pool::Shared::Str->new($spath2, 5, 32);
    is $p->used, 1, "Str persistence: used=1";
    my $slots = $p->allocated_slots;
    is $p->get($slots->[0]), "persistent data", "Str persistence: data survived";
}
unlink $spath2;

done_testing;
