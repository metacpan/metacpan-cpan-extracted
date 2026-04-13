#!/usr/bin/env perl
# Sliding window: push_back new values, pop_front oldest when full
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Deque::Shared;
$| = 1;

my $window_size = 5;
my $dq = Data::Deque::Shared::Int->new(undef, $window_size);

for my $val (1..12) {
    $dq->pop_front if $dq->is_full;  # evict oldest
    $dq->push_back($val);

    # read window contents (drain and refill for display)
    my @win;
    while (!$dq->is_empty) { push @win, $dq->pop_front }
    $dq->push_back($_) for @win;

    printf "add %2d → window: [%s]\n", $val, join(' ', @win);
}
