use strict;
use warnings;
use Test::More;
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(time alarm);
use Data::RingBuffer::Shared;

sub in_child {
    my ($name, $code) = @_;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        my $ok = eval { $code->() };
        _exit($ok ? 0 : 1);
    }
    my $deadline = time + 3;
    while (time < $deadline) {
        if (waitpid($pid, WNOHANG) == $pid) {
            is $?, 0, $name;
            return;
        }
        select undef, undef, undef, 0.01;
    }
    kill 'KILL', $pid;
    waitpid $pid, 0;
    fail "$name (hung)";
}

in_child 'an infinite wait runs a throwing signal handler', sub {
    my $r = Data::RingBuffer::Shared::Int->new(undef, 8);
    local $SIG{ALRM} = sub { die "interrupted\n" };
    alarm 0.05;
    eval { $r->wait_for(0) };
    my $error = $@;
    alarm 0;
    return $error =~ /interrupted/;
};

in_child 'signal handlers can publish data during a wait', sub {
    my $r = Data::RingBuffer::Shared::Int->new(undef, 8);
    local $SIG{ALRM} = sub { $r->write(42) };
    alarm 0.05;
    my $ok = $r->wait_for(0);
    alarm 0;
    return $ok && $r->latest == 42;
};

in_child 'repeated signals preserve the original timeout', sub {
    my $r = Data::RingBuffer::Shared::Int->new(undef, 8);
    my $signals = 0;
    local $SIG{ALRM} = sub { ++$signals; alarm 0.03 };
    my $start = time;
    alarm 0.03;
    my $ok = $r->wait_for(0, 0.3);
    alarm 0;
    my $elapsed = time - $start;
    return !$ok && $signals >= 3 && $elapsed >= 0.25 && $elapsed < 1.5;
};

in_child 'a signal can destroy the waiting handle safely', sub {
    my $r = Data::RingBuffer::Shared::Int->new(undef, 8);
    local $SIG{ALRM} = sub { $r->DESTROY };
    alarm 0.05;
    eval { $r->wait_for(0) };
    my $error = $@;
    alarm 0;
    return $error =~ /destroyed/;
};

done_testing;
