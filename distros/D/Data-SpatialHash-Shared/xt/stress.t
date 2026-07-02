use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::SpatialHash::Shared;

plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

my $WORKERS = $ENV{STRESS_WORKERS} || 4;
my $OPS     = $ENV{STRESS_OPS}     || 5_000;
diag "stress: $WORKERS workers x $OPS insert/move/remove/query each";

# anonymous MAP_SHARED is inherited across fork
my $s = Data::SpatialHash::Shared->new(undef, $WORKERS * $OPS, 0, 1.0);
my $t0 = time;
my @pids;
for my $w (1 .. $WORKERS) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my @mine;
        for (1 .. $OPS) {
            my ($x, $y) = (rand() * 1000, rand() * 1000);
            my $h = $s->insert($x, $y, $$);
            next unless defined $h;
            push @mine, $h;
            $s->move($h, rand() * 1000, rand() * 1000) if @mine % 4 == 0;
            $s->query_radius($x, $y, 5)               if @mine % 8 == 0;
            $s->remove(shift @mine)                   if @mine > 16;
        }
        _exit(0);
    }
    push @pids, $pid;
}
my $fails = 0;
waitpid($_, 0), ($fails += ($? != 0)) for @pids;
my $dt = time - $t0;

is $fails, 0, 'no worker crashed (lock + heap intact under concurrent churn)';
cmp_ok $s->count, '>', 0, 'entries survived: ' . $s->count;
# the index is still coherent: a full-extent aabb returns exactly count entries
my @all = $s->query_aabb(-1, -1, 1001, 1001);
is scalar(@all), $s->count, 'aabb sees exactly count entries after churn';
diag sprintf "%.0f ops/s (%.3fs)", $WORKERS * $OPS / $dt, $dt;

done_testing;
