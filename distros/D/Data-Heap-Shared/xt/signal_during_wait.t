use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Heap::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

my $h = Data::Heap::Shared->new(undef, 4);
my $TIMEOUT = 2.0;

pipe(my $rd, my $wr) or die $!;
my $pid = fork // die;
if ($pid == 0) {
    close $rd;
    local $SIG{USR1} = sub { };
    my $t0 = time;
    my @pv = $h->pop_wait($TIMEOUT);
    my $elapsed = time - $t0;
    syswrite $wr, sprintf("%.4f %s\n", $elapsed, @pv ? "got" : "undef");
    _exit(0);
}
close $wr;

select(undef, undef, undef, 0.3);
kill 'USR1', $pid;
waitpid($pid, 0);
my $line = do { local $/; <$rd> };
chomp $line;
my ($elapsed, $outcome) = split /\s+/, $line;
is $outcome, 'undef', 'pop_wait returned undef';
cmp_ok $elapsed, '>=', $TIMEOUT * 0.95,
    sprintf("elapsed %.3fs >= %.3fs (signal didn't shorten wait)", $elapsed, $TIMEOUT * 0.95);
cmp_ok $elapsed, '<=', $TIMEOUT * 1.5,
    sprintf("elapsed %.3fs <= %.3fs (not stuck past timeout)", $elapsed, $TIMEOUT * 1.5);

done_testing;
