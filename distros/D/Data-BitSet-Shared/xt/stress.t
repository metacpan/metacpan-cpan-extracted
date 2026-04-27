use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::BitSet::Shared;

my $WORKERS = $ENV{STRESS_WORKERS} || 8;
my $OPS     = $ENV{STRESS_OPS}     || 50_000;
diag "stress: $WORKERS workers x $OPS set+clear each";

my $bs = Data::BitSet::Shared->new(undef, 1024);
my @pids;
for (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..$OPS) {
            my $bit = $_ % 1024;
            $bs->set($bit);
            $bs->clear($bit);
        }
        _exit(0);
    }
    push @pids, $pid;
}
my $fails = 0;
waitpid($_, 0), $fails += $? != 0 for @pids;
is $fails, 0, "no worker failures";
done_testing;
