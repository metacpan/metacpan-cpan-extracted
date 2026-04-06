use strict;
use warnings;
no warnings 'portable';
use Test::More;
use File::Temp qw(tmpnam);

use Data::Buffer::Shared::I64;
use Data::Buffer::Shared::U32;
use Data::Buffer::Shared::F64;
use Data::Buffer::Shared::Str;

# === clear ===
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::I64->new($path, 10);
    $buf->fill(42);
    is($buf->get(5), 42, 'pre-clear value');
    $buf->clear;
    is($buf->get(0), 0, 'clear: elem 0 is zero');
    is($buf->get(9), 0, 'clear: elem 9 is zero');

    # keyword
    $buf->set(3, 99);
    buf_i64_clear $buf;
    is($buf->get(3), 0, 'keyword clear');
    unlink $path;
}

# === get_raw / set_raw ===
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::I64->new($path, 10);
    $buf->set(0, 0x0102030405060708);
    $buf->set(1, 0x1112131415161718);

    # get_raw: read first 16 bytes (2 int64s)
    my $raw = $buf->get_raw(0, 16);
    is(length($raw), 16, 'get_raw: 16 bytes');
    my @vals = unpack("q<q<", $raw);
    is($vals[0], 0x0102030405060708, 'get_raw: first int64');
    is($vals[1], 0x1112131415161718, 'get_raw: second int64');

    # set_raw: overwrite first 8 bytes
    my $new = pack("q<", 42);
    ok($buf->set_raw(0, $new), 'set_raw');
    is($buf->get(0), 42, 'set_raw: value updated');
    is($buf->get(1), 0x1112131415161718, 'set_raw: adjacent untouched');

    # out of bounds
    eval { $buf->get_raw(72, 16) };
    like($@, qr/out of bounds/, 'get_raw OOB');
    ok(!$buf->set_raw(80, "x"), 'set_raw OOB returns false');

    unlink $path;
}

# === cmpxchg ===
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::I64->new($path, 10);
    $buf->set(0, 100);

    # successful cmpxchg returns old value
    my $old = $buf->cmpxchg(0, 100, 200);
    is($old, 100, 'cmpxchg success: returns old');
    is($buf->get(0), 200, 'cmpxchg success: value updated');

    # failed cmpxchg returns current value
    $old = $buf->cmpxchg(0, 999, 300);
    is($old, 200, 'cmpxchg failure: returns current');
    is($buf->get(0), 200, 'cmpxchg failure: value unchanged');

    # keyword
    my $kold = buf_i64_cmpxchg $buf, 0, 200, 42;
    is($kold, 200, 'keyword cmpxchg');

    unlink $path;
}

# === atomic_and / atomic_or / atomic_xor ===
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::U32->new($path, 10);
    $buf->set(0, 0xFF);

    # and
    my $r = $buf->atomic_and(0, 0x0F);
    is($r, 0x0F, 'atomic_and: result');
    is($buf->get(0), 0x0F, 'atomic_and: stored');

    # or
    $r = $buf->atomic_or(0, 0xF0);
    is($r, 0xFF, 'atomic_or: result');

    # xor
    $buf->set(0, 0xAA);
    $r = $buf->atomic_xor(0, 0xFF);
    is($r, 0x55, 'atomic_xor: result');
    is($buf->get(0), 0x55, 'atomic_xor: stored');

    # keywords
    $buf->set(1, 0xFF00);
    my $ka = buf_u32_atomic_and $buf, 1, 0x00FF;
    is($ka, 0x00, 'keyword atomic_and');
    buf_u32_atomic_or $buf, 1, 0xAB;
    is($buf->get(1), 0xAB, 'keyword atomic_or');

    unlink $path;
}

# === new_anon (anonymous mmap) ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(100);
    isa_ok($buf, 'Data::Buffer::Shared::I64');
    is($buf->capacity, 100, 'anon: capacity');
    is($buf->elem_size, 8, 'anon: elem_size');

    $buf->set(0, 42);
    is($buf->get(0), 42, 'anon: set/get');

    # incr works
    is($buf->incr(0), 43, 'anon: incr');

    # multiprocess via fork
    $buf->set(50, 0);
    my $pid = fork();
    if ($pid == 0) {
        for (1..1000) { $buf->incr(50) }
        exit 0;
    }
    for (1..1000) { $buf->incr(50) }
    waitpid($pid, 0);
    is($buf->get(50), 2000, 'anon: multiprocess atomic incr');

    # no path
    ok(!defined $buf->path, 'anon: undef path');
}

# === new_anon for Str ===
{
    my $buf = Data::Buffer::Shared::Str->new_anon(5, 16);
    isa_ok($buf, 'Data::Buffer::Shared::Str');
    $buf->set(0, "hello");
    is($buf->get(0), "hello", 'anon str: set/get');
    is($buf->elem_size, 16, 'anon str: elem_size');
}

# === new_anon for F64 ===
{
    my $buf = Data::Buffer::Shared::F64->new_anon(10);
    $buf->set(0, 3.14);
    ok(abs($buf->get(0) - 3.14) < 1e-10, 'anon f64: set/get');
}

# === clear under lock_wr ===
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::I64->new($path, 10);
    $buf->fill(99);
    $buf->lock_wr;
    $buf->clear;
    $buf->unlock_wr;
    is($buf->get(0), 0, 'clear under lock_wr');
    unlink $path;
}

# === get_raw / set_raw for Str ===
{
    my $buf = Data::Buffer::Shared::Str->new_anon(3, 8);
    $buf->set(0, "AAAAAAAA");
    $buf->set(1, "BBBBBBBB");
    my $raw = $buf->get_raw(0, 16);
    is(length($raw), 16, 'str get_raw length');
    is(substr($raw, 0, 8), "AAAAAAAA", 'str get_raw first elem');
    is(substr($raw, 8, 8), "BBBBBBBB", 'str get_raw second elem');

    $buf->set_raw(0, "CCCCCCCC");
    is($buf->get(0), "CCCCCCCC", 'str set_raw');
}

done_testing;
