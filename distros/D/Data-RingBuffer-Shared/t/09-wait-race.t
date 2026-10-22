use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::RingBuffer::Shared;

my $r = Data::RingBuffer::Shared::Int->new(undef, 8);
my $rounds = 2000;
pipe my $ready, my $go or die $!;
my $pid = fork // die "fork: $!";
if (!$pid) {
    close $ready;
    for my $expected (0..$rounds-1) {
        syswrite($go, 'G') == 1 or _exit(1);
        $r->wait_for($expected, 0.5) or _exit(2);
        ($r->read_seq($expected) // -1) == $expected or _exit(3);
    }
    _exit(0);
}
close $go;
for my $value (0..$rounds-1) {
    last unless sysread($ready, my $byte, 1) == 1;
    $r->write($value);
}
close $ready;
waitpid $pid, 0;
is $?, 0, 'writes racing waiter registration never lose a wakeup';
is $r->count, $rounds, 'all handshake rounds completed';
done_testing;
