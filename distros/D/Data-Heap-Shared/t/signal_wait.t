use strict;
use warnings;
use Test::More;
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(time usleep);
use Data::Heap::Shared;

my $heap = Data::Heap::Shared->new_memfd('signal-wait', 4);
pipe(my $ready_r, my $ready_w) or die $!;
my $pid = fork // die $!;
if (!$pid) {
    close $ready_r;
    $SIG{USR1} = sub { die "cancel wait\n" };
    syswrite $ready_w, 'R';
    my $ok = eval { $heap->pop_wait; 1 };
    _exit(!$ok && $@ eq "cancel wait\n" ? 0 : 1);
}
close $ready_w;
sysread($ready_r, my $ready, 1) == 1 or die 'child not ready';
usleep 100_000;
kill 'USR1', $pid;
my $deadline = time + 3;
my $status;
while (time < $deadline) {
    if (waitpid($pid, WNOHANG) == $pid) { $status = $?; last }
    usleep 10_000;
}
if (!defined $status) { kill 'KILL', $pid; waitpid $pid, 0 }
is $status, 0, 'signal handler can cancel an indefinite pop_wait';
open my $fd, '<&', $heap->memfd or die $!;
sysseek($fd, 76, 0) // die $!;
sysread($fd, my $count, 4) == 4 or die $!;
is unpack('L', $count), 0, 'cancelled wait unregisters its waiter';

sub grow_stack { scalar @_ }
$pid = fork // die $!;
if (!$pid) {
    $SIG{USR1} = sub { grow_stack(1 .. 2048); $heap->push(3, 30) };
    my @got = $heap->pop_wait(2);
    _exit(@got == 2 && $got[0] == 3 && $got[1] == 30 ? 0 : 1);
}
usleep 100_000;
kill 'USR1', $pid;
waitpid $pid, 0;
is $?, 0, 'signal handler may grow the Perl stack and publish an entry';

done_testing;
