use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);

use Data::Stack::Shared;

my $N = 8;
my $ITERS = 20;

for my $iter (1..$ITERS) {
    my $path = tmpnam() . ".$$.$iter";
    my @pids;
    for (1..$N) {
        my $pid = fork // die "fork: $!";
        if ($pid == 0) {
            my $ok = eval {
                my $s = Data::Stack::Shared::Int->new($path, 64);
                1;
            };
            _exit($ok ? 0 : 1);
        }
        push @pids, $pid;
    }
    my @fails;
    for my $pid (@pids) {
        waitpid $pid, 0;
        push @fails, $pid if $? != 0;
    }
    unlink $path;
    is scalar(@fails), 0, "iter $iter: $N procs race open, all succeed"
        or diag "failed pids: @fails";
}

done_testing;
