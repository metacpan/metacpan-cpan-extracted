#!/usr/bin/env perl
# Producer/consumer pattern with eventfd notifications
use strict;
use warnings;
use POSIX qw(_exit);
use Data::Buffer::Shared::I64;

my $buf = Data::Buffer::Shared::I64->new_anon(1024);
$buf->create_eventfd;

my $pid = fork();
if ($pid == 0) {
    # producer: write data then notify
    for my $i (0..9) {
        $buf->set($i, ($i + 1) * 100);
    }
    $buf->set(1023, 10); # item count in last slot
    $buf->notify;
    _exit(0);
}

# consumer: wait for notification, then read
my $val;
while (!defined($val = $buf->wait_notify)) {
    select(undef, undef, undef, 0.001); # 1ms poll
}

my $count = $buf->get(1023);
printf "received %d notifications, %d items:\n", $val, $count;
for my $i (0..$count-1) {
    printf "  buf[%d] = %d\n", $i, $buf->get($i);
}

waitpid($pid, 0);
