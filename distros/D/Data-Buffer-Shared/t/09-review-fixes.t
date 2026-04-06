use strict;
use warnings;
use Test::More;

use Data::Buffer::Shared::I64;
use Data::Buffer::Shared::Str;

# === Str eventfd methods (was broken: wrong classname STR vs Str) ===
{
    my $buf = Data::Buffer::Shared::Str->new_anon(5, 16);
    my $efd = $buf->create_eventfd;
    ok($efd >= 0, 'str create_eventfd works');
    is($buf->eventfd, $efd, 'str eventfd accessor');
    ok($buf->notify, 'str notify');
    my $val = $buf->wait_notify;
    is($val, 1, 'str wait_notify');

    # attach
    my $buf2 = Data::Buffer::Shared::Str->new_anon(5, 16);
    $buf2->attach_eventfd($efd);
    is($buf2->eventfd, $efd, 'str attach_eventfd');
}

# === unlink on anon buffer croaks (was: SIGSEGV) ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(10);
    eval { $buf->unlink };
    like($@, qr/cannot unlink anonymous/, 'unlink on anon croaks');
}

# === unlink on memfd buffer croaks ===
{
    my $buf = Data::Buffer::Shared::I64->new_memfd("test", 10);
    eval { $buf->unlink };
    like($@, qr/cannot unlink anonymous/, 'unlink on memfd croaks');
}

# === get_raw with nbytes=0 ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(10);
    my $raw = $buf->get_raw(0, 0);
    is($raw, '', 'get_raw(0, 0) returns empty string');
    is(length($raw), 0, 'get_raw(0, 0) length is 0');
}

# === get_slice under lock_wr (was: deadlock) ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(10);
    $buf->set(0, 10);
    $buf->set(1, 20);
    $buf->set(2, 30);

    $buf->lock_wr;
    my @vals = $buf->slice(0, 3);
    $buf->unlock_wr;
    is_deeply(\@vals, [10, 20, 30], 'slice under lock_wr');
}

# === get_raw under lock_wr (was: deadlock) ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(10);
    $buf->set(0, 42);

    $buf->lock_wr;
    my $raw = $buf->get_raw(0, 8);
    $buf->unlock_wr;
    my @v = unpack("q<", $raw);
    is($v[0], 42, 'get_raw under lock_wr');
}

# === Str get under lock_wr (was: deadlock) ===
{
    my $buf = Data::Buffer::Shared::Str->new_anon(5, 16);
    $buf->set(0, "hello");

    $buf->lock_wr;
    is($buf->get(0), "hello", 'str get under lock_wr');
    my @vals = $buf->slice(0, 1);
    is($vals[0], "hello", 'str slice under lock_wr');
    $buf->unlock_wr;
}

# === as_scalar keeps buffer alive (prevents use-after-free) ===
{
    my $ref;
    {
        my $buf = Data::Buffer::Shared::I64->new_anon(10);
        $buf->set(0, 12345);
        $ref = $buf->as_scalar;
        # $buf goes out of scope here — but magic ref prevents DESTROY
    }
    # buffer should still be alive because $ref holds a backref
    my @vals = unpack("q<", $$ref);
    is($vals[0], 12345, 'as_scalar keeps buffer alive after scope exit');
}

done_testing;
