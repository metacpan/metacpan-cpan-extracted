use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Buffer::Shared::I64;

# Regression: all-reader rwlock contention must not deadlock.
# Buffer has same write-preferring rwlock as HashMap (fix Pass 1).

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";
my $b = Data::Buffer::Shared::I64->new($path, 64);
$b->set(0, 100);

my $N = 6;
my $OPS = 5000;

my $t0 = time;
my @pids;
for my $k (0..$N-1) {
    my $pid = fork // die;
    if ($pid == 0) {
        my $c = Data::Buffer::Shared::I64->new($path, 64);
        for (1..$OPS) { $c->get(0) }  # all readers, no writer
        _exit(0);
    }
    push @pids, $pid;
}

my $fails = 0;
for my $pid (@pids) { waitpid $pid, 0; $fails++ if $? }
my $dt = time - $t0;
unlink $path;

is $fails, 0, "$N readers × $OPS get completed";
ok $dt < 10, sprintf('completed in %.2fs', $dt);

done_testing;
