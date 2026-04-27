use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::HashMap::Shared::II;

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";

my $N_PROC = 4;
my $OPS = 2000;  # per child

my $m = Data::HashMap::Shared::II->new($path, 8192);

my @pids;
for my $k (0 .. $N_PROC - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $c = Data::HashMap::Shared::II->new($path, 8192);
        srand($k * 1000 + $$);
        for my $i (1..$OPS) {
            my $key = int(rand(1_000));
            my $op = int(rand(4));
            if    ($op == 0) { $c->put($key, $key * 3 + $k) }
            elsif ($op == 1) { $c->get($key) }
            elsif ($op == 2) { $c->remove($key) }
            else             { $c->incr($key) }
        }
        _exit(0);
    }
    push @pids, $pid;
}

my @fails;
for my $pid (@pids) {
    waitpid $pid, 0;
    push @fails, $pid if $? != 0;
}

unlink $path;

is scalar(@fails), 0, "$N_PROC processes ran $OPS-op MPMC fuzz without crash"
    or diag "failed pids: @fails";

done_testing;
