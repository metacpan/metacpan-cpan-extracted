use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    if(!eval 'require Coro'){
        plan skip_all => 'this test requires Coro';
    }
}

use AnyEvent;
use Coro;
use Coro::AnyEvent;

use ok 'AnyEvent::Retry::Coro';

my $start = AnyEvent->now;
my $cv = AnyEvent->condvar;

my $times = 0;

my $r = AnyEvent::Retry::Coro->new(
    max_tries  => 50,
    interval   => { Fibonacci => { scale => 1/1000 } },
    try        => sub {
        $times++;
        Coro::AnyEvent::sleep 0.01;
        return AnyEvent->now - $start > 1 ? AnyEvent->now : 0;
    },
);

my $end;
lives_ok {
    $end = $r->run;
} 'lives ok';

ok $times > 1, 'called more than once';
ok $end - $start > 1, 'got the value returned by try';

$start = AnyEvent->now;
my $middle;
lives_ok {
    $r->start;
    $middle = AnyEvent->now;
    $end = $r->wait;
} 'start/wait also works';

ok $end - $start > 1, 'got the value returned by try (again)';
ok((($middle - $start) < ($end - $start)), 'middle runs before "wait"');

my $r2 = AnyEvent::Retry::Coro->new(
    interval => { Fibonacci => { scale => 1000 } },
    try      => sub { Coro::AnyEvent::sleep 1; return 0 },
);

my $kill = async {
    while(1){
        Coro::AnyEvent::sleep 1;
        undef $r2;
    }
};

throws_ok {
    $r2->run;
} qr/DEMOLISH/, 'demolition still works';

$kill->cancel;

done_testing;
