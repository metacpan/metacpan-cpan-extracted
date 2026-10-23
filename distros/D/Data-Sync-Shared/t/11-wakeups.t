use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time sleep);
use IO::Select;
use POSIX qw(_exit WUNTRACED WIFSTOPPED);
use Data::Sync::Shared;

my %children;
END {
    kill 'KILL', keys %children if %children;
    waitpid($_, 0) for keys %children;
}

sub await_waiters {
    my ($obj, $count) = @_;
    my $deadline = time + 2;
    sleep 0.001 while $obj->stats->{waiters} < $count && time < $deadline;
    is $obj->stats->{waiters}, $count, "$count waiters registered";
    sleep 0.02;
}

sub sem_waiter {
    my ($sem, $n) = @_;
    pipe my $read, my $write or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $read;
        my $ok = $n == 1 ? $sem->acquire(3) : $sem->acquire_n($n, 3);
        syswrite $write, $ok ? '1' : '0';
        $sem->release($n) if $ok;
        _exit($ok ? 0 : 1);
    }
    close $write;
    $children{$pid} = 1;
    return ($pid, $read);
}

for my $case (['release', 1, 1, 1], ['release(1)', 1, 0, 1], ['release(2)', 2, 0, 3]) {
    my ($label, $n, $single, $heads) = @$case;
    subtest "$label wakes an eligible waiter behind a larger request" => sub {
        my $sem = Data::Sync::Shared::Semaphore->new(undef, 3, 0);
        my (@large, @large_read);
        for (1 .. $heads) {
            my ($pid, $read) = sem_waiter($sem, 3);
            push @large, $pid;
            push @large_read, $read;
            await_waiters($sem, $_);
        }
        my ($small, $small_read) = sem_waiter($sem, $n);
        await_waiters($sem, $heads + 1);

        $single ? $sem->release : $sem->release($n);
        my @ready = IO::Select->new($small_read)->can_read(0.6);
        ok @ready, 'eligible waiter wakes without another release';
        if (@ready) {
            sysread $small_read, my $result, 1;
            is $result, '1', 'eligible waiter acquired its permits';
        }

        $sem->release(3);
        for my $pid (@large, $small) {
            waitpid($pid, 0);
            is $?, 0, 'waiter completed';
            delete $children{$pid};
        }
        is $sem->stats->{waiters}, 0, 'waiter registrations balanced';
        is $sem->value, 3, 'all permits returned';
    };
}

subtest 'a later timeout preserves a completed barrier generation' => sub {
    my $bar = Data::Sync::Shared::Barrier->new(undef, 2);
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        _exit($bar->wait(3) == 0 ? 0 : 1);
    }
    $children{$pid} = 1;
    await_waiters($bar, 1);
    kill 'STOP', $pid or die "SIGSTOP: $!";
    waitpid($pid, WUNTRACED);
    ok WIFSTOPPED(${^CHILD_ERROR_NATIVE}), 'first waiter paused before the barrier trips';

    is $bar->wait(1), 1, 'first generation completes';
    is $bar->wait(0.05), -1, 'next generation times out';
    ok $bar->is_broken, 'later generation is broken';

    kill 'CONT', $pid or die "SIGCONT: $!";
    waitpid($pid, 0);
    is $?, 0, 'completed-generation waiter still succeeds';
    delete $children{$pid};
    is $bar->stats->{waiters}, 0, 'barrier waiter registration balanced';
};

done_testing;
