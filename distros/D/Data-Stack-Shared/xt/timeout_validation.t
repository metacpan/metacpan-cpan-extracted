use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Stack::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Boundary timeouts: negative, +Inf, NaN. None should crash; results
# should match documented behavior or croak cleanly.

my $h = Data::Stack::Shared::Int->new(undef, 4);

# Run each timeout in a child to detect signal-death.
sub run_child {
    my ($label, $code) = @_;
    my $pid = fork // die;
    if ($pid == 0) {
        eval { $code->() };
        _exit($@ ? 1 : 0);
    }
    # Poll until reaped or timeout. Capture $? from the successful reap;
    # a second waitpid would return -1 (ECHILD) and look like a deadlock.
    my $deadline = time + 1.5;
    my $child_status;
    while (time < $deadline) {
        my $w = waitpid($pid, POSIX::WNOHANG());
        if ($w == $pid) { $child_status = $?; last }
        select(undef, undef, undef, 0.05);
    }
    if (!defined $child_status) {
        kill 'KILL', $pid;
        waitpid($pid, 0);
        return "deadlock";
    }
    my $sig = $child_status & 127;
    return $sig ? "signal_$sig" : "exit_" . ($child_status >> 8);
}

# Negative timeout: many modules treat as "block forever". We ensure
# it doesn't crash; deadlock is ok if module doesn't have data.
# Use a wrapper that only blocks briefly.
my $r1 = run_child('negative timeout',
    sub { local $SIG{ALRM} = sub { _exit(0) }; alarm 1; $h->pop_wait(-1.0) });
isnt $r1, 'signal_11', "negative timeout: no SIGSEGV (got $r1)";
isnt $r1, 'signal_6',  "negative timeout: no SIGABRT (got $r1)";

# +Infinity: same as negative, may block forever
my $r2 = run_child('inf timeout',
    sub { local $SIG{ALRM} = sub { _exit(0) }; alarm 1; $h->pop_wait("Inf"+0) });
isnt $r2, 'signal_11', "inf timeout: no SIGSEGV (got $r2)";
isnt $r2, 'signal_6',  "inf timeout: no SIGABRT (got $r2)";

# NaN: implementation-defined, must not crash
my $r3 = run_child('nan timeout',
    sub { local $SIG{ALRM} = sub { _exit(0) }; alarm 1; $h->pop_wait("NaN"+0) });
isnt $r3, 'signal_11', "NaN timeout: no SIGSEGV (got $r3)";
isnt $r3, 'signal_6',  "NaN timeout: no SIGABRT (got $r3)";

done_testing;
