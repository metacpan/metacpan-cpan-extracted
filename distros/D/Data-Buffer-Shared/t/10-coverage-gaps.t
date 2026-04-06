use strict;
use warnings;
no warnings 'portable';
use Test::More;
use POSIX qw(_exit);

use Data::Buffer::Shared::I8;
use Data::Buffer::Shared::U8;
use Data::Buffer::Shared::I64;
use Data::Buffer::Shared::F32;
use Data::Buffer::Shared::F64;
use Data::Buffer::Shared::Str;

# === Signed type boundaries (INT8_MIN, INT64_MIN wrapping) ===
{
    my $buf = Data::Buffer::Shared::I8->new_anon(5);
    $buf->set(0, 127);
    is($buf->incr(0), -128, 'i8 incr wraps 127 -> -128');
    $buf->set(1, -128);
    is($buf->decr(1), 127, 'i8 decr wraps -128 -> 127');
    $buf->set(2, -1);
    is($buf->get(2), -1, 'i8 negative value');
}

{
    my $buf = Data::Buffer::Shared::I64->new_anon(5);
    $buf->set(0, -9223372036854775808);
    is($buf->get(0), -9223372036854775808, 'i64 INT64_MIN');
    is($buf->decr(0), 9223372036854775807, 'i64 decr wraps INT64_MIN -> INT64_MAX');
}

# === Unsigned boundaries ===
{
    my $buf = Data::Buffer::Shared::U8->new_anon(5);
    $buf->set(0, 255);
    is($buf->incr(0), 0, 'u8 incr wraps 255 -> 0');
    $buf->set(1, 0);
    is($buf->decr(1), 255, 'u8 decr wraps 0 -> 255');
}

# === F32 dedicated tests ===
{
    my $buf = Data::Buffer::Shared::F32->new_anon(10);
    is($buf->capacity, 10, 'f32 capacity');
    is($buf->elem_size, 4, 'f32 elem_size');

    $buf->set(0, 3.14);
    ok(abs($buf->get(0) - 3.14) < 0.001, 'f32 set/get');

    $buf->fill(2.5);
    ok(abs($buf->get(9) - 2.5) < 0.001, 'f32 fill');

    $buf->set(0, 1.0);
    $buf->set(1, 2.0);
    my @vals = $buf->slice(0, 2);
    ok(abs($vals[0] - 1.0) < 0.001, 'f32 slice[0]');
    ok(abs($vals[1] - 2.0) < 0.001, 'f32 slice[1]');

    ok($buf->set_slice(3, 10.5, 20.5), 'f32 set_slice');
    ok(abs($buf->get(3) - 10.5) < 0.01, 'f32 set_slice[0]');

    $buf->clear;
    ok(abs($buf->get(0)) < 0.001, 'f32 clear');

    my $raw = $buf->get_raw(0, 4);
    is(length($raw), 4, 'f32 get_raw');

    my $ref = $buf->as_scalar;
    is(length($$ref), 40, 'f32 as_scalar length = 10 * 4');
}

# === Float multiprocess ===
{
    my $buf = Data::Buffer::Shared::F64->new_anon(10);
    $buf->set(0, 0.0);

    my $pid = fork();
    if ($pid == 0) {
        for (1..1000) { $buf->set(0, 1.0) }
        _exit(0);
    }
    for (1..1000) { $buf->set(0, 2.0) }
    waitpid($pid, 0);
    my $v = $buf->get(0);
    ok($v == 1.0 || $v == 2.0, 'f64 multiprocess: value is one of the writers');
}

# === Str keyword API ===
{
    my $buf = Data::Buffer::Shared::Str->new_anon(5, 16);
    buf_str_set $buf, 0, "keyword";
    my $v = buf_str_get $buf, 0;
    is($v, "keyword", 'str keyword get/set');

    buf_str_fill $buf, "x";
    is($buf->get(4), "x", 'str keyword fill');

    buf_str_clear $buf;
    is($buf->get(0), "", 'str keyword clear');
}

# === set_raw OOB ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(5);
    ok(!$buf->set_raw(40, "x"), 'set_raw past end returns false');
    ok(!$buf->set_raw(39, "xx"), 'set_raw spanning end returns false');
    ok($buf->set_raw(0, ""), 'set_raw empty string succeeds');
}

# === get_raw crossing element boundaries ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(4);
    $buf->set(0, 0x0102030405060708);
    $buf->set(1, 0x1112131415161718);
    # read 4 bytes from middle of first element + 4 bytes from second
    my $raw = $buf->get_raw(4, 8);
    is(length($raw), 8, 'get_raw cross-element boundary length');
}

# === Str multiprocess ===
{
    my $buf = Data::Buffer::Shared::Str->new_anon(5, 16);
    $buf->set(0, "initial");

    my $pid = fork();
    if ($pid == 0) {
        for (1..500) { $buf->set(0, "child_wrote") }
        _exit(0);
    }
    for (1..500) { $buf->set(0, "parent_wrote") }
    waitpid($pid, 0);
    my $v = $buf->get(0);
    ok($v eq "child_wrote" || $v eq "parent_wrote",
       "str multiprocess: value is from one writer ($v)");
}

# === Multiple handles to same file ===
{
    use File::Temp qw(tmpnam);
    my $path = tmpnam();
    my $buf1 = Data::Buffer::Shared::I64->new($path, 10);
    my $buf2 = Data::Buffer::Shared::I64->new($path, 10);

    $buf1->set(0, 42);
    is($buf2->get(0), 42, 'two handles same file: writes visible');

    $buf2->incr(0);
    is($buf1->get(0), 43, 'two handles same file: incr visible');
    unlink $path;
}

# === eventfd on F64 variant ===
{
    my $buf = Data::Buffer::Shared::F64->new_anon(5);
    my $efd = $buf->create_eventfd;
    ok($efd >= 0, 'f64 create_eventfd');
    ok($buf->notify, 'f64 notify');
    is($buf->wait_notify, 1, 'f64 wait_notify');
}

# === cmpxchg multiprocess ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(5);
    $buf->set(0, 0);

    my $pid = fork();
    if ($pid == 0) {
        for (1..1000) {
            my $old;
            do { $old = $buf->get(0) }
            until ($buf->cas(0, $old, $old + 1));
        }
        _exit(0);
    }
    for (1..1000) {
        my $old;
        do { $old = $buf->get(0) }
        until ($buf->cas(0, $old, $old + 1));
    }
    waitpid($pid, 0);
    is($buf->get(0), 2000, 'cmpxchg/cas multiprocess: 2000 atomic increments');
}

done_testing;
