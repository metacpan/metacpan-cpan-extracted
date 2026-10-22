use strict;
use warnings;
use Test::More;
use POSIX qw(_exit WNOHANG);
use Time::HiRes qw(time sleep alarm);
use Data::Log::Shared;

sub check_child {
    my ($label, $code) = @_;
    my $pid = fork // die "fork: $!";
    unless ($pid) {
        my $ok = eval { $code->() };
        _exit($ok ? 0 : 1);
    }
    my $deadline = time + 3;
    while (time < $deadline) {
        if (waitpid($pid, WNOHANG) == $pid) {
            is $?, 0, $label;
            return;
        }
        sleep 0.01;
    }
    kill 'KILL', $pid;
    waitpid($pid, 0);
    fail "$label (wait hung)";
}

for my $timeout (undef, 0.75) {
    check_child(defined $timeout ? 'alarm interrupts a timed wait' : 'alarm interrupts an indefinite wait', sub {
        my $log = Data::Log::Shared->new(undef, 4096);
        local $SIG{ALRM} = sub { die "cancelled\n" };
        my $start = time;
        alarm 0.05;
        eval { $log->wait_for(0, $timeout) };
        my $error = $@;
        alarm 0;
        return $error eq "cancelled\n" && time - $start < 0.6
            && $log->stats->{waiters} == 0;
    });
}

check_child('returning signal handlers preserve the deadline and statistics', sub {
    my $log = Data::Log::Shared->new(undef, 4096);
    my $signals = 0;
    local $SIG{ALRM} = sub { $signals++ };
    alarm 0.02, 0.02;
    my $start = time;
    my $ready = $log->wait_for(0, 0.16);
    my $elapsed = time - $start;
    alarm 0;
    my $stats = $log->stats;
    return !$ready && $signals >= 2 && $elapsed >= 0.12 && $elapsed < 0.6
        && $stats->{waiters} == 0 && $stats->{waits} == 1 && $stats->{timeouts} == 1;
});

check_child('a signal handler can append and wake an indefinite wait', sub {
    my $log = Data::Log::Shared->new(undef, 4096);
    local $SIG{ALRM} = sub { $log->append('from signal') };
    alarm 0.05;
    my $ready = $log->wait_for(0);
    alarm 0;
    return $ready && $log->entry_count == 1 && $log->stats->{waiters} == 0;
});

done_testing;
