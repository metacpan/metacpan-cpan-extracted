use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::Buffer::Shared::I64;

# === create_eventfd / eventfd accessor ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(10);
    ok(!defined $buf->eventfd, 'no eventfd by default');

    my $efd = $buf->create_eventfd;
    ok($efd >= 0, 'create_eventfd returns valid fd');
    is($buf->eventfd, $efd, 'eventfd accessor returns same fd');
}

# === notify / wait_notify (single process) ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(10);
    $buf->create_eventfd;

    ok($buf->notify, 'notify succeeds');
    ok($buf->notify, 'notify again');

    # eventfd is EFD_NONBLOCK + EFD_SEMAPHORE is NOT set,
    # so read returns sum of all writes
    my $val = $buf->wait_notify;
    is($val, 2, 'wait_notify: returns accumulated count');

    # second read would block (nonblocking → undef)
    $val = $buf->wait_notify;
    ok(!defined $val, 'wait_notify: returns undef when no notification pending');
}

# === notify without eventfd ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(10);
    ok(!$buf->notify, 'notify without eventfd returns false');
    ok(!defined $buf->wait_notify, 'wait_notify without eventfd returns undef');
}

# === cross-process notify ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(10);
    $buf->create_eventfd;
    $buf->set(0, 0);

    my $pid = fork();
    if ($pid == 0) {
        # child: write data then notify
        $buf->set(0, 42);
        $buf->notify;
        _exit(0);
    }

    # parent: wait for notification, then read
    # busy-wait with short sleep since eventfd is nonblocking
    my $val;
    for (1..100) {
        $val = $buf->wait_notify;
        last if defined $val;
        select(undef, undef, undef, 0.01);
    }
    waitpid($pid, 0);

    ok(defined $val, 'cross-process: received notification');
    is($buf->get(0), 42, 'cross-process: data visible after notify');
}

# === attach_eventfd (external eventfd) ===
{
    my $buf1 = Data::Buffer::Shared::I64->new_anon(10);
    my $buf2 = Data::Buffer::Shared::I64->new_anon(10);

    my $efd = $buf1->create_eventfd;
    $buf2->attach_eventfd($efd);

    is($buf2->eventfd, $efd, 'attach_eventfd: fd matches');

    # notify on buf1, wait on buf2 (same eventfd)
    $buf1->notify;
    my $val = $buf2->wait_notify;
    is($val, 1, 'shared eventfd: notify on one, wait on other');
}

# === create_eventfd is idempotent: second call returns same fd ===
{
    my $buf = Data::Buffer::Shared::I64->new_anon(10);
    my $efd1 = $buf->create_eventfd;
    $buf->notify;
    my $efd2 = $buf->create_eventfd;
    is($efd2, $efd1, 'create_eventfd is idempotent');
    is($buf->wait_notify, 1, 'notifications persist across idempotent create');
}

done_testing;
