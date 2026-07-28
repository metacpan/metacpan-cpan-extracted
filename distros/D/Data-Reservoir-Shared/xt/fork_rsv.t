use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::Reservoir::Shared;

# Anonymous MAP_SHARED reservoir inherited across fork: children feed disjoint
# item streams concurrently (contending under the rwlock), and the parent sees
# one consistent reservoir -- count capped at k, seen == the grand total, and
# every sampled item is one that some child actually fed.
my $kids = 4;
my $per  = 10_000;
my $k    = 50;
my $r = Data::Reservoir::Shared->new(undef, $k, 32);

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $r->add("c${c}-$_") for 1 .. $per;   # disjoint per-child keyspace
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

is $r->count, $k, "reservoir full: count == k ($k) after $kids*$per adds";
is $r->seen, $kids * $per, "seen == grand total (no lost observations)";
my $bad = grep { !/^c[0-3]-\d+$/ } $r->sample;
is $bad, 0, 'every sampled item was fed by some child (no corruption)';

done_testing;
