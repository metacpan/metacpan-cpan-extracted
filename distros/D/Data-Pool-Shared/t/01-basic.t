use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use Data::Pool::Shared;

# --- Raw pool ---

my $path = tmpnam() . '.shm';
END { unlink $path if $path && -f $path }

my $pool = Data::Pool::Shared->new($path, 10, 32);
ok $pool, 'created raw pool';
is $pool->capacity, 10, 'capacity 10';
is $pool->elem_size, 32, 'elem_size 32';
is $pool->used, 0, 'used 0';
is $pool->available, 10, 'available 10';

# alloc/free
my $idx = $pool->alloc;
ok defined $idx, 'alloc returned index';
ok $pool->is_allocated($idx), 'slot is allocated';
is $pool->used, 1, 'used 1';
is $pool->owner($idx), $$, 'owner is our PID';

$pool->set($idx, "hello");
my $data = $pool->get($idx);
is substr($data, 0, 5), "hello", 'get returns data';
is length($data), 32, 'get returns full elem_size bytes';

ok $pool->free($idx), 'free returns true';
ok !$pool->is_allocated($idx), 'slot freed';
is $pool->used, 0, 'used 0 after free';

# double free returns false
ok !$pool->free($idx), 'double free returns false';

# try_alloc
my $i1 = $pool->try_alloc;
ok defined $i1, 'try_alloc succeeds';
$pool->free($i1);

# fill pool
my @slots;
for (1..10) {
    my $s = $pool->alloc;
    ok defined $s, "alloc slot $_";
    push @slots, $s;
}
is $pool->used, 10, 'pool full';
is $pool->available, 0, 'available 0';

# alloc with timeout=0 when full
my $failed = $pool->alloc(0);
ok !defined $failed, 'alloc(0) returns undef when full';

# try_alloc when full
$failed = $pool->try_alloc;
ok !defined $failed, 'try_alloc returns undef when full';

# free one and alloc again
$pool->free($slots[0]);
my $realloc = $pool->try_alloc;
ok defined $realloc, 'alloc after free succeeds';
$pool->free($realloc);

# free all
$pool->free($_) for @slots[1..$#slots];
is $pool->used, 0, 'all freed';

# reset
$pool->alloc for 1..5;
is $pool->used, 5, '5 allocated';
$pool->reset;
is $pool->used, 0, 'reset clears all';

# out of range
eval { $pool->get(100) };
like $@, qr/out of range/, 'get out of range croaks';

eval { $pool->set(100, "x") };
like $@, qr/out of range/, 'set out of range croaks';

# not allocated
eval { $pool->get(0) };
like $@, qr/not allocated/, 'get unallocated croaks';

# path
is $pool->path, $path, 'path correct';

# stats
my $st = $pool->stats;
ok ref $st eq 'HASH', 'stats returns hashref';
is $st->{capacity}, 10, 'stats capacity';

# --- Anonymous pool ---

my $anon = Data::Pool::Shared->new(undef, 5, 8);
ok $anon, 'anonymous pool created';
ok !defined $anon->path, 'anonymous path is undef';
my $ai = $anon->alloc;
ok defined $ai, 'alloc on anonymous pool';
$anon->free($ai);

# --- I64 pool ---

my $i64_path = tmpnam() . '.shm';
END { unlink $i64_path if $i64_path && -f $i64_path }

my $i64 = Data::Pool::Shared::I64->new($i64_path, 50);
ok $i64, 'created I64 pool';
is $i64->capacity, 50, 'I64 capacity';
is $i64->elem_size, 8, 'I64 elem_size';

my $s = $i64->alloc;
$i64->set($s, 42);
is $i64->get($s), 42, 'I64 get/set';

$i64->set($s, 0);
is $i64->incr($s), 1, 'incr returns 1';
is $i64->incr($s), 2, 'incr returns 2';
is $i64->decr($s), 1, 'decr returns 1';
is $i64->get($s), 1, 'value is 1';

is $i64->add($s, 10), 11, 'add(10) returns 11';

ok $i64->cas($s, 11, 99), 'cas succeeds';
is $i64->get($s), 99, 'value after cas';
ok !$i64->cas($s, 11, 0), 'cas fails with wrong expected';
is $i64->get($s), 99, 'value unchanged after failed cas';

$i64->free($s);

# alloc_set
my $as = $i64->alloc_set(777);
ok defined $as, 'alloc_set returned index';
is $i64->get($as), 777, 'alloc_set value correct';
$i64->free($as);

# alloc_guard
{
    my ($gi, $guard) = $i64->alloc_guard;
    ok defined $gi, 'alloc_guard returned index';
    ok ref $guard, 'alloc_guard returned guard';
    $i64->set($gi, 123);
    is $i64->is_allocated($gi), 1, 'slot allocated in guard scope';
    # $gi is saved for check after scope
    $s = $gi;
}
ok !$i64->is_allocated($s), 'guard auto-freed slot on scope exit';

# --- F64 pool ---

my $f64 = Data::Pool::Shared::F64->new(undef, 10);
ok $f64, 'created F64 pool';
my $fi = $f64->alloc;
$f64->set($fi, 3.14);
ok abs($f64->get($fi) - 3.14) < 0.001, 'F64 get/set';
$f64->free($fi);

# --- I32 pool ---

my $i32 = Data::Pool::Shared::I32->new(undef, 10);
ok $i32, 'created I32 pool';
my $ti = $i32->alloc;
$i32->set($ti, -100);
is $i32->get($ti), -100, 'I32 get/set';
is $i32->add($ti, 150), 50, 'I32 add';
ok $i32->cas($ti, 50, 0), 'I32 cas';
$i32->free($ti);

# --- Str pool ---

my $str = Data::Pool::Shared::Str->new(undef, 10, 64);
ok $str, 'created Str pool';
is $str->max_len, 64, 'max_len 64';
my $si = $str->alloc;
$str->set($si, "hello world");
is $str->get($si), "hello world", 'Str get/set';

# truncation
my $long = "x" x 100;
$str->set($si, $long);
is length($str->get($si)), 64, 'Str truncates to max_len';
$str->free($si);

# --- Non-multiple-of-64 capacity ---

my $odd = Data::Pool::Shared::I64->new(undef, 65);
ok $odd, 'pool with capacity 65';
my @odd_slots;
for (1..65) {
    my $s = $odd->alloc;
    ok defined $s, "alloc odd slot $_";
    push @odd_slots, $s;
}
ok !defined $odd->try_alloc, 'odd pool full at 65';
$odd->free($_) for @odd_slots;

# --- each_allocated ---

my $ep = Data::Pool::Shared::I64->new(undef, 10);
$ep->alloc_set(100);
$ep->alloc_set(200);
$ep->alloc_set(300);
my @found;
$ep->each_allocated(sub { push @found, $ep->get($_[0]) });
is_deeply [sort @found], [100, 200, 300], 'each_allocated iterates allocated slots';

done_testing;
