#!/usr/bin/env perl
# EV event loop integration via eventfd
#
# The eventfd descriptor is pollable — plug it directly into EV::io
# for non-blocking notifications without busy-wait.
#
# Requires: EV
use strict;
use warnings;
use POSIX qw(_exit);

use Data::Buffer::Shared::I64;

my $buf = Data::Buffer::Shared::I64->new_anon(10);
my $efd = $buf->create_eventfd;

my $pid = fork();
if ($pid == 0) {
    # producer: write data and notify
    for my $i (0..4) {
        select(undef, undef, undef, 0.05);
        $buf->set($i, ($i + 1) * 100);
        $buf->notify;
    }
    _exit(0);
}

# consumer: EV watches the eventfd
eval { require EV };
if ($@) {
    # fallback without EV
    print "EV not available, using poll fallback\n";
    my $received = 0;
    while ($received < 5) {
        my $n = $buf->wait_notify;
        unless (defined $n) { select(undef, undef, undef, 0.01); next }
        $received += $n;
        printf "notified (count=%d, total=%d)\n", $n, $received;
    }
} else {
    my $received = 0;
    my $w = EV::io($efd, EV::READ(), sub {
        my $n = $buf->wait_notify;
        return unless defined $n;
        $received += $n;
        printf "EV callback: %d new notifications (total %d)\n", $n, $received;
        for my $i (0..$buf->capacity-1) {
            my $v = $buf->get($i);
            printf "  buf[%d] = %d\n", $i, $v if $v;
        }
        EV::break() if $received >= 5;
    });
    EV::run();
}

waitpid($pid, 0);
printf "done, buf[0..4]: %s\n",
    join(', ', map { $buf->get($_) } 0..4);
