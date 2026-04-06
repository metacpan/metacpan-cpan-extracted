use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);

use Data::Buffer::Shared::I64;
use Data::Buffer::Shared::F64;
use Data::Buffer::Shared::Str;

# --- Reopen existing file and verify persistence ---
{
    my $path = tmpnam();
    {
        my $buf = Data::Buffer::Shared::I64->new($path, 10);
        $buf->set(0, 42);
        $buf->set(9, 99);
    }
    # Object destroyed, reopen
    my $buf2 = Data::Buffer::Shared::I64->new($path, 10);
    is($buf2->get(0), 42, 'reopen: data persists after close');
    is($buf2->get(9), 99, 'reopen: last element persists');
    is($buf2->capacity, 10, 'reopen: capacity correct');
    unlink $path;
}

# --- Reopen with wrong variant ---
{
    my $path = tmpnam();
    Data::Buffer::Shared::I64->new($path, 10);
    eval { Data::Buffer::Shared::F64->new($path, 10) };
    like($@, qr/variant mismatch/, 'reopen with wrong variant croaks');
    unlink $path;
}

# --- Corrupt file (bad magic) ---
{
    my $path = tmpnam();
    open my $fh, '>', $path or die;
    # Write a non-zero bad magic so it's not treated as uninitialized
    print $fh pack("V", 0xDEADBEEF);
    print $fh "\x00" x 252;
    close $fh;
    eval { Data::Buffer::Shared::I64->new($path, 10) };
    like($@, qr/bad magic/, 'corrupt file with bad magic croaks');
    unlink $path;
}

# --- Zero capacity ---
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::I64->new($path, 0);
    is($buf->capacity, 0, 'zero capacity');
    is($buf->get(0), undef, 'get on zero-capacity returns undef');
    ok(!$buf->set(0, 1), 'set on zero-capacity returns false');
    unlink $path;
}

# --- Explicit locking ---
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::I64->new($path, 100);

    # Write lock + batch set
    $buf->lock_wr;
    for my $i (0..9) {
        # Direct set under lock (bypasses per-element lock)
        $buf->set($i, $i * 10);
    }
    $buf->unlock_wr;

    # Verify
    for my $i (0..9) {
        is($buf->get($i), $i * 10, "explicit lock batch write [$i]");
    }

    # Read lock
    $buf->lock_rd;
    my @vals;
    for my $i (0..9) {
        push @vals, $buf->get($i);
    }
    $buf->unlock_rd;
    is_deeply(\@vals, [0, 10, 20, 30, 40, 50, 60, 70, 80, 90], 'explicit lock batch read');

    # set_slice under lock_wr (regression: must not self-deadlock)
    $buf->lock_wr;
    $buf->set_slice(0, 1, 2, 3, 4, 5);
    $buf->unlock_wr;
    is($buf->get(0), 1, 'set_slice under lock_wr[0]');
    is($buf->get(4), 5, 'set_slice under lock_wr[4]');

    # fill under lock_wr
    $buf->lock_wr;
    $buf->fill(77);
    $buf->unlock_wr;
    is($buf->get(50), 77, 'fill under lock_wr');

    unlink $path;
}

# --- Str set under lock_wr (must not deadlock) ---
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::Str->new($path, 5, 16);
    $buf->lock_wr;
    $buf->set(0, "hello");
    $buf->set(1, "world");
    $buf->unlock_wr;
    is($buf->get(0), "hello", 'str set under lock_wr');
    is($buf->get(1), "world", 'str set under lock_wr[1]');
    unlink $path;
}

# --- Unlink method ---
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::I64->new($path, 10);
    $buf->set(0, 42);
    ok(-f $path, 'file exists before unlink');
    $buf->unlink;
    ok(!-f $path, 'file removed after unlink');
    # Buffer still usable (mmap valid after unlink)
    is($buf->get(0), 42, 'buffer still readable after unlink');
}

# --- Unlink class method ---
{
    my $path = tmpnam();
    Data::Buffer::Shared::I64->new($path, 10);
    ok(-f $path, 'file exists');
    Data::Buffer::Shared::I64->unlink($path);
    ok(!-f $path, 'class method unlink removes file');
}

# --- Str reopen ---
{
    my $path = tmpnam();
    {
        my $buf = Data::Buffer::Shared::Str->new($path, 5, 32);
        $buf->set(0, "hello world");
    }
    my $buf2 = Data::Buffer::Shared::Str->new($path, 5, 32);
    is($buf2->get(0), "hello world", 'str reopen: data persists');
    is($buf2->elem_size, 32, 'str reopen: elem_size correct');
    unlink $path;
}

# --- Slice out of bounds ---
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::I64->new($path, 10);
    eval { $buf->slice(8, 5) };
    like($@, qr/out of bounds/, 'slice past end croaks');
    eval { $buf->slice(0, 11) };
    like($@, qr/out of bounds/, 'slice count > capacity croaks');
    unlink $path;
}

# --- set_slice out of bounds ---
{
    my $path = tmpnam();
    my $buf = Data::Buffer::Shared::I64->new($path, 5);
    ok(!$buf->set_slice(3, 1, 2, 3), 'set_slice past end returns false');
    unlink $path;
}

# --- F64 reopen ---
{
    my $path = tmpnam();
    {
        my $buf = Data::Buffer::Shared::F64->new($path, 5);
        $buf->set(0, 3.14);
    }
    my $buf2 = Data::Buffer::Shared::F64->new($path, 5);
    ok(abs($buf2->get(0) - 3.14) < 1e-10, 'f64 reopen: data persists');
    unlink $path;
}

done_testing;
