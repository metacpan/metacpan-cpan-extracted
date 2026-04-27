use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use Data::Queue::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# wait_for / pop_wait / push_wait: advertised timeout should match wall time
# within a loose band. Catches timeout arithmetic regressions.

my $q = Data::Queue::Shared::Int->new(undef, 1);

for my $timeout (0.1, 0.5, 1.0) {
    my $t0 = time;
    my $v = $q->pop_wait($timeout);
    my $elapsed = time - $t0;
    ok !defined $v, "pop_wait($timeout) on empty returns undef";
    cmp_ok $elapsed, '>=', $timeout * 0.9,
        sprintf("pop_wait took %.3fs >= %.3f (lower bound)", $elapsed, $timeout * 0.9);
    cmp_ok $elapsed, '<=', $timeout * 2,
        sprintf("pop_wait took %.3fs <= %.3f (upper bound)", $elapsed, $timeout * 2);
}

# push_wait on full queue
$q->push(1); $q->push(2);
for my $timeout (0.1, 0.5) {
    my $t0 = time;
    my $ok = $q->push_wait(99, $timeout);
    my $elapsed = time - $t0;
    ok !$ok, "push_wait($timeout) on full returns false";
    cmp_ok $elapsed, '>=', $timeout * 0.9, "push_wait lower bound OK";
    cmp_ok $elapsed, '<=', $timeout * 2,   "push_wait upper bound OK";
}

done_testing;
