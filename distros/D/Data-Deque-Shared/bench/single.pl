#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::Deque::Shared;

my $N = shift || 1_000_000;

sub bench {
    my ($label, $code) = @_;
    my $t0 = time;
    $code->();
    my $dt = time - $t0;
    printf "  %-35s %10.0f/s  (%.3fs)\n", $label, $N / $dt, $dt;
}

printf "Data::Deque::Shared single-process benchmark (%d ops)\n\n", $N;

my $dq = Data::Deque::Shared::Int->new(undef, 1000);

bench "push_back + pop_front (FIFO)" => sub {
    for (1..$N) { $dq->push_back(42); $dq->pop_front }
};

bench "push_back + pop_back (LIFO)" => sub {
    for (1..$N) { $dq->push_back(42); $dq->pop_back }
};

bench "push_front + pop_front (LIFO)" => sub {
    for (1..$N) { $dq->push_front(42); $dq->pop_front }
};

bench "push_front + pop_back (FIFO)" => sub {
    for (1..$N) { $dq->push_front(42); $dq->pop_back }
};
