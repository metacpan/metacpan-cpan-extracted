use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(time sleep);
use Data::Deque::Shared;

my $dir = tempdir(CLEANUP => 1);
for my $variant (qw(Int Str)) {
    for my $method (qw(push_back_wait push_front_wait pop_front_wait pop_back_wait)) {
        for my $action (qw(cancel complete)) {
            my $label = "$variant $method $action";
            my $path = "$dir/$variant-$method-$action";
            my $class = "Data::Deque::Shared::$variant";
            my $d = $class->new($path, 1, $variant eq 'Str' ? (16) : ());
            my $push = $method =~ /^push/;
            $d->push_back(17) if $push;
            open my $fh, '<', $path or die $!;
            my $waiters = sub {
                sysseek($fh, $push ? 72 : 76, 0) // die $!;
                sysread($fh, my $buf, 4) == 4 or die $!;
                return unpack 'L', $buf;
            };
            my $pid = fork // die $!;
            if (!$pid) {
                $SIG{USR1} = sub {
                    die "cancelled\n" if $action eq 'cancel';
                    $push ? $d->pop_front : $d->push_back(23);
                };
                my $result = eval { $d->$method($push ? (23) : ()) };
                my $error = $@;
                if ($action eq 'cancel') {
                    _exit(1) unless $error eq "cancelled\n";
                    _exit(2) if $waiters->();
                    _exit(3) unless $push ? $d->pop_front == 17 : $d->is_empty;
                } else {
                    _exit(4) if $error || !$result;
                    _exit(5) unless $push ? $d->pop_front == 23 : $result == 23;
                }
                _exit(0);
            }
            my $until = time + 3;
            sleep 0.01 until $waiters->() || time >= $until;
            sleep 0.01;
            kill 'USR1', $pid;
            my $status;
            $until = time + 3;
            while (time < $until) {
                if (waitpid($pid, WNOHANG) == $pid) { $status = $?; last }
                sleep 0.01;
            }
            if (!defined $status) {
                kill 'KILL', $pid;
                waitpid $pid, 0;
                $status = $?;
            }
            is $status, 0, "$label: signal handler runs while blocked";
            is $waiters->(), 0, "$label: waiter count released";
            close $fh;
        }
    }
}
done_testing;
