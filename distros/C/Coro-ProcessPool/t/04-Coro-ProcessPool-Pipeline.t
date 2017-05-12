use strict;
use warnings;
use Coro;
use Coro::AnyEvent;
use Guard qw(scope_guard);
use List::Util qw(shuffle);
use Test::More;
use Coro::ProcessPool;

BEGIN { use AnyEvent::Impl::Perl }

BAIL_OUT 'MSWin32 is not supported' if $^O eq 'MSWin32';

my $class = 'Coro::ProcessPool::Pipeline';
use_ok($class);

sub double {
    my ($x) = @_;
    return [$x, $x * 2];
}

sub error {
    die 'test error';
}

my $pool = Coro::ProcessPool->new(max_procs => 2);
scope_guard { $pool->shutdown };

subtest 'basic' => sub {
    my $pipeline = new_ok($class, [pool => $pool]);
    my @range = 1 .. 10;

    my $producer = async {
        foreach my $i (shuffle @range) {
            $pipeline->queue(\&double, [$i]);
        }

        $pipeline->shutdown;

        eval { $pipeline->queue };
        like($@, qr/shutting down/, 'error triggered when queue is shutting down');
    };

    my $received = 0;

    while (my $reply = $pipeline->next) {
        my ($input, $result) = @$reply;
        is($result, 2 * $input, "correct response: $input");
        ++$received;
    }

    is($received, scalar(@range), 'correct number of results');

    eval { $pipeline->queue };
    like($@, qr/shut down/, 'error triggered when queue is shut down');
};

subtest 'errors' => sub {
    my $pipeline = new_ok($class, [pool => $pool]);
    $pipeline->queue(\&error, []);
    eval { $pipeline->next };
    like($@, qr/test error/, 'errors correctly triggered');
    $pipeline->shutdown;
};

subtest 'auto shutdown' => sub {
    my $pipeline = new_ok($class, [pool => $pool, auto_shutdown => 1]);
    my @range = 1 .. 10;

    my $producer = async {
        foreach my $i (shuffle @range) {
            $pipeline->queue(\&double, [$i]);
        }
    };

    my $timer = async {
        Coro::AnyEvent::sleep(30);
        $producer->throw('timed out');
    };

    my $received = 0;

    while (my $reply = $pipeline->next) {
        my ($input, $result) = @$reply;
        is($result, 2 * $input, "correct response: $input");
        ++$received;
    }

    $timer->cancel;

    is($received, scalar(@range), 'correct number of results');
};

subtest 'from pool' => sub {
    my $pipeline = $pool->pipeline;
    my @range = 1 .. 10;

    my $producer = async {
        foreach my $i (shuffle @range) {
            $pipeline->queue(\&double, [$i]);
        }

        $pipeline->shutdown;
    };

    my $received = 0;

    while (my $reply = $pipeline->next) {
        my ($input, $result) = @$reply;
        is($result, 2 * $input, "correct response: $input");
        ++$received;
    }

    is($received, scalar(@range), 'correct number of results');
};

done_testing;
