use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SortedSet::Shared;

# SIGKILL readers while they hold the read lock; the writer-side dead-reader
# recovery (reader-slot scan + force-reset) must reclaim their lock contribution
# so a writer can still acquire -- otherwise the read count stays inflated forever
# and writers deadlock. This exercises a path distinct from crash_recovery.t
# (which kills a writer); here the victims die holding the READ lock.

my $z = Data::SortedSet::Shared->new(undef, 50_000);
$z->add($_, rand() * 1000) for 1 .. 5000;

my $READERS = $ENV{READERS} || 12;
my @pids;
for (1 .. $READERS) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $z->range_by_rank(0, -1) while 1;     # full snapshot -> time spent inside the read lock
        _exit(0);
    }
    push @pids, $pid;
}
select undef, undef, undef, 0.2;              # let readers pile into the lock
kill 'KILL', @pids;                           # abrupt: no chance to release the read lock
waitpid $_, 0 for @pids;

my $ok = eval {
    local $SIG{ALRM} = sub { die "writer could not acquire -- dead-reader recovery failed\n" };
    alarm 20;
    $z->add(-1, 0);
    $z->incr(-1, 1) for 1 .. 100;
    alarm 0;
    1;
};
ok $ok, 'writer acquires the lock after readers were SIGKILLed mid-read (recovery works)' or diag $@;
is $z->count, 5001, 'state intact after dead-reader recovery';
ok $z->_validate, 'tree consistent after dead-reader recovery';

done_testing;
