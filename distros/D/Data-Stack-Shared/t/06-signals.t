use strict;
use warnings;
use Test::More;
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(time sleep alarm);
use Data::Stack::Shared;

for my $variant (qw(Int Str)) {
    for my $op (qw(push_wait pop_wait)) {
        for my $action (qw(die wake)) {
            my $pid = fork // die "fork: $!";
            if (!$pid) {
                my $class = "Data::Stack::Shared::$variant";
                my $s = $class->new_memfd('signal-test', 1, $variant eq 'Str' ? (32) : ());
                $s->push(42) if $op eq 'push_wait';
                local $SIG{ALRM} = sub {
                    die "interrupted\n" if $action eq 'die';
                    $op eq 'push_wait' ? $s->pop : $s->push(42);
                };
                alarm 0.1;
                my $got = eval { $op eq 'push_wait' ? $s->push_wait(99) : $s->pop_wait };
                my $err = $@;
                alarm 0;
                _exit(1) unless $action eq 'die' ? $err eq "interrupted\n"
                    : !$err && defined($got) && $got == ($op eq 'push_wait' ? 1 : 42);
                open my $fh, '<&', $s->memfd or _exit(2);
                sysseek($fh, 68, 0) == 68 or _exit(3);
                sysread($fh, my $waiters, 8) == 8 or _exit(4);
                _exit(5) if grep { $_ } unpack('L2', $waiters);
                $s->pop if $op eq 'push_wait';
                _exit(6) unless $s->push(7) && $s->pop eq '7';
                _exit(0);
            }
            my $deadline = time + 3;
            my $status;
            while (time < $deadline) {
                if (waitpid($pid, WNOHANG) == $pid) { $status = $?; last }
                sleep 0.01;
            }
            if (!defined $status) {
                kill 'KILL', $pid;
                waitpid($pid, 0);
                $status = $?;
            }
            is $status, 0, "$variant $op: signal handlers can $action and unregister the waiter";
        }
    }
}

done_testing;
