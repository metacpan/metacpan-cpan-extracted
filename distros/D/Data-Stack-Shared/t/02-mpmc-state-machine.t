use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::Stack::Shared;

# MPMC stress: multiple producers pushing, multiple consumers popping.
# Each pushed value is unique (pid<<20 | seq). The per-slot state machine
# must prevent torn reads where a pop races with a push on the same slot
# (the old lock-free design had this race; the state-machine gate closes it).

my $CAP       = 8;
my $PRODUCERS = 6;
my $CONSUMERS = 6;
my $PER_PROD  = 3000;

my $stk     = Data::Stack::Shared::Int->new(undef, $CAP);
my $results = Data::Stack::Shared::Int->new(undef, $PRODUCERS * $PER_PROD + 16);

my @kids;
for my $p (0 .. $PRODUCERS - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $base = ($p + 1) << 20;
        for my $i (1 .. $PER_PROD) {
            my $v = $base | $i;
            $stk->push_wait($v, 30.0) or _exit(1);
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
            my $v = $stk->pop_wait(30.0);
            defined $v or _exit(2);
            $results->push_wait($v, 30.0) or _exit(3);
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
while (defined(my $v = $results->pop)) {
    $dupes++ if $seen{$v}++;
    my $prod = $v >> 20;
    my $seq  = $v & 0xFFFFF;
    $bogus++ if $prod < 1 || $prod > $PRODUCERS || $seq < 1 || $seq > $PER_PROD;
}

is $dupes, 0, 'no duplicate values popped (publication gate holds)';
is $bogus, 0, 'no torn/zeroed values popped';
is scalar(keys %seen), $total, "all $total pushed values accounted for";
ok $stk->is_empty, 'stack drained';

done_testing;
