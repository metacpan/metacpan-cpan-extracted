use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::Deque::Shared;

# Smaller MPMC stress to keep wallclock bounded.
my $CAP       = 8;       # small cap forces contention
my $PRODUCERS = 6;
my $CONSUMERS = 6;
my $PER_PROD  = 3000;

my $dq      = Data::Deque::Shared::Int->new(undef, $CAP);
my $results = Data::Deque::Shared::Int->new(undef, $PRODUCERS * $PER_PROD + 16);

my @kids;
for my $p (0 .. $PRODUCERS - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $base = ($p + 1) << 20;
        for my $i (1 .. $PER_PROD) {
            my $v = $base | $i;
            if ($i % 2) { $dq->push_back_wait($v, 30.0)  or _exit(1) }
            else        { $dq->push_front_wait($v, 30.0) or _exit(1) }
        }
        _exit(0);
    }
    push @kids, $pid;
}

my $total   = $PRODUCERS * $PER_PROD;
my $per_con = int($total / $CONSUMERS);
my $extra   = $total - $per_con * $CONSUMERS;

for my $c (0 .. $CONSUMERS - 1) {
    my $n = $per_con + ($c < $extra ? 1 : 0);
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for (1 .. $n) {
            my $v = ($c % 2) ? $dq->pop_front_wait(30.0) : $dq->pop_back_wait(30.0);
            defined $v or _exit(2);
            $results->push_back_wait($v, 30.0) or _exit(3);
        }
        _exit(0);
    }
    push @kids, $pid;
}

for my $pid (@kids) {
    waitpid $pid, 0;
    ok $? >> 8 == 0, "worker $pid exit 0 (got $?)";
}

my %seen;
my $dupes = 0;
my $bogus = 0;
while (defined(my $v = $results->pop_front)) {
    $dupes++ if $seen{$v}++;
    my $prod = $v >> 20;
    my $seq  = $v & 0xFFFFF;
    $bogus++ if $prod < 1 || $prod > $PRODUCERS || $seq < 1 || $seq > $PER_PROD;
}

is $dupes, 0, 'no duplicate values popped';
is $bogus, 0, 'no torn/zeroed values popped';
is scalar(keys %seen), $total, "all $total pushed values accounted for";
ok $dq->is_empty, 'deque drained';

done_testing;
