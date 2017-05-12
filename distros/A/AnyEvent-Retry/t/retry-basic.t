use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'AnyEvent::Retry';
diag(AnyEvent->detect);

my $start = AnyEvent->now;
my $cv = AnyEvent->condvar;

my $times = 0;

my $r = AnyEvent::Retry->new(
    on_failure => sub { $cv->croak($_[1]) },
    on_success => sub { $cv->send($_[0])  },
    max_tries  => 50,
    interval   => { Fibonacci => { scale => 1/1000 } },
    try        => sub {
        my ($success, $error) = @_;
        $times++;
        my $t; $t = AnyEvent->timer( after => 0.01, cb => sub {
            undef $t;
            $success->(AnyEvent->now - $start > 1 ? AnyEvent->now : 0);
        });
    },
);

$r->start;

my $end;
lives_ok {
    $end = $cv->recv;
} 'lives ok';

ok $times > 1, 'called more than once (should be 15 times)';
ok $end - $start > 1, 'got the value returned by try';

done_testing;
