use strict;
use warnings;
use Test::More;
use POSIX ':sys_wait_h';
use Data::PubSub::Shared;

# Regression: Str publish_multi extracted SvPV from each argument while
# holding the process-shared mutex. A tied/overloaded argument whose
# stringification die()s would longjmp past pubsub_mutex_unlock, abandoning
# the mutex and deadlocking peers (and the process itself on its next op).
# SvPV is now hoisted out of the lock. A real leak hangs in a futex syscall
# that Perl's alarm can't interrupt, so we fork + kill with a deadline.

package Bomb;
use overload '""' => sub { die "boom\n" }, fallback => 1;
sub new { bless {}, shift }

package main;

my $pid = fork // die "fork: $!";
if ($pid == 0) {
    my $ps = Data::PubSub::Shared::Str->new(undef, 64, 4096);
    my $died = !eval { $ps->publish_multi("ok", Bomb->new, "x"); 1 };
    die "publish_multi(bomb) did not die\n" unless $died && $@ =~ /boom/;
    # The mutex must be free now: this must not hang.
    $ps->publish("after");
    POSIX::_exit(0);
}

my $deadline = time + 10;
my $done = 0;
while (time < $deadline) {
    if (waitpid($pid, WNOHANG) == $pid) { $done = 1; last }
    select undef, undef, undef, 0.05;
}
if (!$done) { kill 'KILL', $pid; waitpid($pid, 0); }
ok($done && $? == 0, "Str publish_multi releases the mutex when an argument dies");

done_testing;
