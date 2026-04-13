#!/usr/bin/env perl
# Priority lanes: high-priority items push_front, normal push_back
# Consumer always pop_front — high-priority served first
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Deque::Shared;
$| = 1;

my $dq = Data::Deque::Shared::Int->new(undef, 100);

# producer: mix of normal (positive) and high-priority (negative) items
my $pid = fork // die;
if ($pid == 0) {
    for my $i (1..30) {
        if ($i % 7 == 0) {
            $dq->push_front(-$i);  # high priority
        } else {
            $dq->push_back($i);   # normal
        }
    }
    $dq->push_back(0);  # sentinel
    _exit(0);
}
waitpid($pid, 0);

# consumer: process in order — high-priority appears first
printf "processing order:\n";
my (@hi, @lo);
while (1) {
    my $v = $dq->pop_front;
    last unless defined $v;
    last if $v == 0;
    if ($v < 0) { push @hi, -$v } else { push @lo, $v }
}
printf "  high-priority: %s\n", join(' ', @hi);
printf "  normal:        %s\n", join(' ', @lo);
printf "  high served before normal: %s\n",
    (@hi && @lo && $hi[0] > $lo[0]) ? "yes" : "no";
