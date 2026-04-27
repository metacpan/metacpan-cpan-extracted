use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(sleep);
use Data::Queue::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Linux FUTEX_WAKE doesn't guarantee fairness, but if one waiter always
# wins every wakeup that's a regression worth detecting. We have N
# blockers on pop_wait, push once, record who woke up, repeat.

my $N = 8;
my $q = Data::Queue::Shared::Int->new(undef, 4);

pipe(my $rd, my $wr) or die $!;
my @pids;
for my $id (1..$N) {
    my $pid = fork // die;
    if ($pid == 0) {
        close $rd;
        my $v = $q->pop_wait(5.0);
        if (defined $v) {
            syswrite $wr, "$id\n";
        }
        _exit(0);
    }
    push @pids, $pid;
}
close $wr;

sleep 0.3;  # let all children block on pop_wait
# Push N values, one every 10ms so each wakes a single waiter.
for my $i (1..$N) {
    $q->push($i);
    sleep 0.01;
}

my %seen;
while (<$rd>) { chomp; $seen{$_}++ }
close $rd;
waitpid($_, 0) for @pids;

is scalar(keys %seen), $N, "all $N waiters were woken (no starvation)";
# With real fairness failure, one waiter would never appear.
diag "winners: " . join(",", sort { $a <=> $b } keys %seen);

done_testing;
