use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Stack::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# A SIGUSR1 while a process is parked in pop_wait must cleanly interrupt
# the futex, re-check the predicate, and (since no data arrived) continue
# waiting for the FULL remaining window. Wall-time assertion: total time
# spent blocked ≈ timeout, not just up-to-signal-arrival.

my $s = Data::Stack::Shared::Int->new(undef, 4);
my $TIMEOUT = 2.0;

pipe(my $rd, my $wr) or die $!;
my $pid = fork // die;
if ($pid == 0) {
    close $rd;
    local $SIG{USR1} = sub { };   # install handler (EINTR)
    my $t0 = time;
    my $v  = $s->pop_wait($TIMEOUT);
    my $elapsed = time - $t0;
    syswrite $wr, sprintf("%.4f %s\n", $elapsed, defined($v) ? "got" : "undef");
    _exit(0);
}
close $wr;

select(undef, undef, undef, 0.3);   # let child block
kill 'USR1', $pid;                   # signal mid-wait
waitpid($pid, 0);
my $line = do { local $/; <$rd> };
chomp $line;
my ($elapsed, $outcome) = split /\s+/, $line;
is $outcome, 'undef', 'pop_wait returned undef (no data arrived)';
cmp_ok $elapsed, '>=', $TIMEOUT * 0.95,
    sprintf("elapsed %.3fs >= %.3fs (signal did NOT shorten the wait)", $elapsed, $TIMEOUT * 0.95);
cmp_ok $elapsed, '<=', $TIMEOUT * 1.5,
    sprintf("elapsed %.3fs <= %.3fs (not stuck past timeout)", $elapsed, $TIMEOUT * 1.5);

done_testing;
