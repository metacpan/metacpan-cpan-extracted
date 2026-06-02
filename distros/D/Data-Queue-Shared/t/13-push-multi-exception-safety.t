use strict;
use warnings;
use Test::More;
use POSIX ':sys_wait_h';
use File::Temp ();
use Data::Queue::Shared;

# Regression: Str push_multi extracted SvPV from each argument while holding
# the process-shared mutex. A tied/overloaded argument whose stringification
# die()s would longjmp past queue_mutex_unlock, abandoning the mutex and
# deadlocking peers (the process self-stalls on its next op). SvPV is now
# hoisted out of the lock (as pop_multi already does for newSVpvn). A real
# leak would hang in a futex syscall that Perl's alarm can't interrupt, so we
# fork + kill with a wall-clock deadline.

package Bomb;
use overload '""' => sub { die "boom\n" }, fallback => 1;
sub new { bless {}, shift }

package main;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    my $dir = File::Temp->newdir;
    my $q = Data::Queue::Shared::Str->new("$dir/q", 64, 65536);
    my $died = !eval { $q->push_multi("a", Bomb->new, "c"); 1 };
    die "push_multi(bomb) did not die\n" unless $died && $@ =~ /boom/;
    # The mutex must be free now (SvPV died before locking, so nothing was
    # enqueued): these must not hang, and the queue must work normally.
    $q->push("after");
    my $v = $q->pop;
    die "queue unusable / wrong value after caught die\n"
        unless defined $v && $v eq "after";
    POSIX::_exit(0);
}

my $deadline = time + 10;
my $done = 0;
while (time < $deadline) {
    if (waitpid($pid, WNOHANG) == $pid) { $done = 1; last }
    select undef, undef, undef, 0.05;
}
if (!$done) { kill 'KILL', $pid; waitpid($pid, 0); }
ok($done && $? == 0, "Str push_multi releases the mutex when an argument dies");

done_testing;
