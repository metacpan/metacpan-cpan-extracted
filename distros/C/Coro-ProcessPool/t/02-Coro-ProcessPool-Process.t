use strict;
use warnings;
use Test::More;
use Coro;
use Guard qw(scope_guard);
use List::Util qw(shuffle);

BEGIN { use AnyEvent::Impl::Perl }

BAIL_OUT 'MSWin32 is not supported' if $^O eq 'MSWin32';

my $timeout = 3;
my $class = 'Coro::ProcessPool::Process';

sub test_sub {
    my ($x) = @_;
    return $x * 2;
}

use_ok($class) or BAIL_OUT;
my @range = (1 .. 20);

note 'shutdown';
{
    my $proc = new_ok($class);
    ok(my $pid = $proc->pid, 'spawned correctly');

    ok(my $id = $proc->send(\&test_sub, [21]), 'final send');
    ok($proc->shutdown($timeout), 'shutdown with pending task');

    my $reply = eval { $proc->recv($id) };
    my $error = $@;

    ok(!$reply, 'no reply received after termination');
    ok($error, 'error thrown in recv after termination');
    like($error, qr/process killed while waiting on this task to complete/, 'expected error');
};

note 'in order';
{
    my $proc = new_ok($class);
    ok(my $pid = $proc->pid, 'spawned correctly');

    scope_guard { $proc->shutdown($timeout) };

    my $count = 0;
    foreach my $i (@range) {
        ok(my $id = $proc->send(\&test_sub, [$i]), "send ($i)");
        ok(my $reply = $proc->recv($id), "recv ($i)");
        is($reply, $i * 2, "receives expected result ($i)");
        is($proc->messages_sent, ++$count, "message count tracking ($i)");
    }
};

note 'out of order';
{
    my $proc = new_ok($class);
    ok(my $pid = $proc->pid, 'spawned correctly');

    scope_guard { $proc->shutdown($timeout) };

    my %pending;
    foreach my $i (shuffle @range) {
        ok(my $id = $proc->send(\&test_sub, [$i]), "ooo send ($i)");
        $pending{$i} = $id;
    }

    foreach my $i (shuffle keys %pending) {
        my $id = $pending{$i};
        ok(my $reply = $proc->recv($id), "ooo recv ($i)");
        is($reply, $i * 2, "ooo receives expected result ($i)");
    }
};

note 'include path';
{
    my $proc = new_ok($class, [include => ['t/']]);
    ok(my $pid = $proc->pid, 'spawned correctly');

    scope_guard { $proc->shutdown($timeout) };

    my $id = $proc->send('TestTaskNoNS', []);
    my $rs = eval { $proc->recv($id) };

    ok !$@, 'no errors' or diag $@;
    is $rs, 42, 'expected result';
}

done_testing;
