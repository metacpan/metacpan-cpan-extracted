use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SortedSet::Shared;

# Many processes race to fill a small set to capacity with DISJOINT members. The
# node/index pools must hand out each member exactly once: total successful new
# adds == capacity, never more, and the tree stays valid at the brink.

my $CAP   = 2000;
my $PROCS = 8;
my $z = Data::SortedSet::Shared->new(undef, $CAP);

pipe(my $R, my $W) or die "pipe: $!";
my @pids;
for my $w (0 .. $PROCS - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $R;
        my $ok = 0;
        for (1 .. $CAP) { $ok++ if $z->add($w * 1_000_000 + $_, rand()) }   # disjoint -> new(1) or full(undef)
        syswrite $W, "$ok\n";
        _exit(0);
    }
    push @pids, $pid;
}
close $W;
my $total = 0;
$total += $_ for map { chomp; $_ } <$R>;
waitpid $_, 0 for @pids;

is $total, $CAP, "exactly capacity new members handed out under contention ($total == $CAP)";
is $z->count, $CAP, 'set is full, count == capacity';
ok !defined($z->add(-1, 0)), 'further add of a new member returns undef (no overflow)';
ok $z->_validate, 'tree valid at full capacity';
my @all;
$z->each(sub { push @all, $_[0] });
is scalar(@all), $CAP, 'every handed-out member is a reachable, distinct entry';

done_testing;
