use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Fcntl qw(LOCK_EX LOCK_UN);
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);
use Data::Graph::Shared;

plan skip_all => 'requires /proc wait channels' unless -r '/proc/self/wchan';
my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/graph";
{ my $g = Data::Graph::Shared->new($path, 8, 8); $g->add_node(42); }
open my $lock, '+<', $path or die $!;
flock($lock, LOCK_EX) or die $!;
pipe(my $reader, my $writer) or die $!;
my $pid = fork // die $!;
unless ($pid) {
    close $reader;
    close $lock;
    $SIG{USR1} = sub {};
    syswrite($writer, 'R') == 1 or _exit(2);
    my $g = eval { Data::Graph::Shared->new($path, 8, 8) };
    syswrite($writer, $g ? 'opened' : $@);
    _exit($g && $g->node_data(0) == 42 ? 0 : 1);
}
close $writer;
local $SIG{ALRM} = sub { kill 'KILL', $pid; waitpid $pid, 0; die "open test timed out\n" };
alarm 10;
sysread($reader, my $ready, 1) == 1 or die 'child not ready';
my $blocked = 0;
my $deadline = time + 2;
while (time < $deadline) {
    if (open my $fh, '<', "/proc/$pid/wchan") {
        my $where = do { local $/; <$fh> };
        $blocked = $where =~ /locks/;
    }
    last if $blocked;
    usleep(1000);
}
if ($blocked) {
    kill 'USR1', $pid;
    usleep(20_000);
}
flock($lock, LOCK_UN) or die $!;
my $output = do { local $/; <$reader> };
waitpid $pid, 0;
my $status = $?;
alarm 0;
plan skip_all => 'cannot observe the child blocked in flock' unless $blocked;
is $status, 0, 'a signal does not abort a contended graph open' or diag $output;
is $output, 'opened', 'open succeeds after the initialization lock is released';
done_testing;
