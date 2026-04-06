use strict;
use warnings;
no warnings 'portable';
use Test::More;
use POSIX qw(_exit);

use Data::Buffer::Shared::I64;
use Data::Buffer::Shared::U32;
use Data::Buffer::Shared::F64;
use Data::Buffer::Shared::Str;

# === memfd constructor ===
{
    my $buf = Data::Buffer::Shared::I64->new_memfd("test_buf", 100);
    isa_ok($buf, 'Data::Buffer::Shared::I64');
    is($buf->capacity, 100, 'memfd: capacity');
    $buf->set(0, 42);
    is($buf->get(0), 42, 'memfd: set/get');

    # fd is available
    my $fd = $buf->fd;
    ok(defined $fd, 'memfd: fd defined');
    ok($fd >= 0, 'memfd: fd >= 0');

    # fork and share via inherited fd
    $buf->set(50, 0);
    my $pid = fork();
    if ($pid == 0) {
        for (1..500) { $buf->incr(50) }
        _exit(0);
    }
    for (1..500) { $buf->incr(50) }
    waitpid($pid, 0);
    is($buf->get(50), 1000, 'memfd: multiprocess via fork');
}

# === new_from_fd (reopen via fd) ===
{
    my $buf1 = Data::Buffer::Shared::I64->new_memfd("share_test", 20);
    $buf1->set(0, 999);
    my $fd = $buf1->fd;

    # dup the fd and open from it
    my $fd2 = POSIX::dup($fd);
    ok($fd2 >= 0, 'dup fd');
    my $buf2 = Data::Buffer::Shared::I64->new_from_fd($fd2);
    isa_ok($buf2, 'Data::Buffer::Shared::I64');
    is($buf2->get(0), 999, 'new_from_fd: sees data from original');
    is($buf2->capacity, 20, 'new_from_fd: correct capacity');

    # writes visible both ways
    $buf2->set(1, 777);
    is($buf1->get(1), 777, 'new_from_fd: writes visible to original');
}

# === fd returns undef for file-backed and anon ===
{
    use File::Temp qw(tmpnam);
    my $path = tmpnam();
    my $fb = Data::Buffer::Shared::I64->new($path, 10);
    ok(!defined $fb->fd, 'file-backed: fd is undef');
    unlink $path;

    my $anon = Data::Buffer::Shared::I64->new_anon(10);
    ok(!defined $anon->fd, 'anon: fd is undef');
}

# === as_scalar (zero-copy read) ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(4);
    $buf->set(0, 1);
    $buf->set(1, 2);
    $buf->set(2, 3);
    $buf->set(3, 4);

    my $ref = $buf->as_scalar;
    is(ref $ref, 'SCALAR', 'as_scalar: returns scalar ref');
    is(length($$ref), 32, 'as_scalar: length = 4 * 8');
    my @vals = unpack("q<4", $$ref);
    is_deeply(\@vals, [1, 2, 3, 4], 'as_scalar: correct values');

    # read-only
    eval { $$ref = "x" };
    like($@, qr/read-only|Modification/, 'as_scalar: read-only');

    # reflects live data (zero-copy)
    $buf->set(0, 99);
    @vals = unpack("q<4", $$ref);
    is($vals[0], 99, 'as_scalar: reflects live writes');
}

# === as_scalar for F64 ===
{
    my $buf = Data::Buffer::Shared::F64->new_anon(3);
    $buf->set(0, 1.5);
    $buf->set(1, 2.5);
    $buf->set(2, 3.5);
    my $ref = $buf->as_scalar;
    is(length($$ref), 24, 'f64 as_scalar: 3 * 8');
    my @vals = unpack("d<3", $$ref);
    ok(abs($vals[0] - 1.5) < 1e-10, 'f64 as_scalar[0]');
    ok(abs($vals[2] - 3.5) < 1e-10, 'f64 as_scalar[2]');
}

# === as_scalar for Str ===
{
    my $buf = Data::Buffer::Shared::Str->new_anon(2, 8);
    $buf->set(0, "AAAAAAAA");
    $buf->set(1, "BBBB");
    my $ref = $buf->as_scalar;
    is(length($$ref), 16, 'str as_scalar: 2 * 8');
    is(substr($$ref, 0, 8), "AAAAAAAA", 'str as_scalar[0]');
    is(substr($$ref, 8, 4), "BBBB", 'str as_scalar[1] prefix');
}

# === add_slice (batch atomic add) ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(10);
    $buf->fill(100);
    ok($buf->add_slice(2, 10, 20, 30), 'add_slice');
    is($buf->get(2), 110, 'add_slice[0]');
    is($buf->get(3), 120, 'add_slice[1]');
    is($buf->get(4), 130, 'add_slice[2]');
    is($buf->get(5), 100, 'add_slice: adjacent untouched');

    # out of bounds
    ok(!$buf->add_slice(8, 1, 2, 3), 'add_slice OOB');

    # multiprocess atomicity
    $buf->fill(0);
    my $pid = fork();
    if ($pid == 0) {
        for (1..1000) { $buf->add_slice(0, 1, 1, 1) }
        _exit(0);
    }
    for (1..1000) { $buf->add_slice(0, 1, 1, 1) }
    waitpid($pid, 0);
    is($buf->get(0), 2000, 'add_slice: multiprocess atomic[0]');
    is($buf->get(1), 2000, 'add_slice: multiprocess atomic[1]');
    is($buf->get(2), 2000, 'add_slice: multiprocess atomic[2]');
}

# === U32 add_slice ===
{
    my $buf = Data::Buffer::Shared::U32->new_anon(5);
    $buf->set(0, 10);
    $buf->set(1, 20);
    $buf->add_slice(0, 5, 10);
    is($buf->get(0), 15, 'u32 add_slice[0]');
    is($buf->get(1), 30, 'u32 add_slice[1]');
}

# === memfd for Str ===
{
    my $buf = Data::Buffer::Shared::Str->new_memfd("str_test", 5, 16);
    isa_ok($buf, 'Data::Buffer::Shared::Str');
    $buf->set(0, "hello");
    is($buf->get(0), "hello", 'str memfd: set/get');
    ok(defined $buf->fd, 'str memfd: has fd');
}

# === new_from_fd wrong variant ===
{
    my $buf = Data::Buffer::Shared::I64->new_memfd("wrong_type", 10);
    my $fd2 = POSIX::dup($buf->fd);
    eval { Data::Buffer::Shared::U32->new_from_fd($fd2) };
    like($@, qr/variant mismatch/, 'new_from_fd: wrong variant croaks');
    POSIX::close($fd2);
}

done_testing;
