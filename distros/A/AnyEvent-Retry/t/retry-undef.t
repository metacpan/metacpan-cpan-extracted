use strict;
use warnings;
use Test::More;
use Test::Exception;

use AnyEvent::Retry;

{
    my $cv = AnyEvent->condvar;
    my $r = AnyEvent::Retry->new(
        on_failure => sub { $cv->croak($_[1]) },
        on_success => sub { $cv->send($_[0])  },
        max_tries  => 50,
        interval   => { Fibonacci => { scale => 1/1000 } },
        try        => sub {},   # do nothing
    );

    $r->start;
    my $t = AnyEvent->timer( after => 0.1, cb => sub {
        ok !$r->has_timer, 'no timer running';
        undef $r;
    } );

    throws_ok {
        $cv->recv;
    } qr/DEMOLISH/,
        'we destroyed $r and the failure callback was called with DEMOLISH';
}

{
    my $cv = AnyEvent->condvar;
    my $r = AnyEvent::Retry->new(
        on_failure => sub { $cv->croak($_[1]) },
        on_success => sub { $cv->send($_[0])  },
        max_tries  => 50,
        interval   => { Constant => { interval => 9999 } },
        try        => sub { $_[0]->(0) }, # always unsuccessful
    );

    $r->start;
    my $t = AnyEvent->timer( after => 0.1, cb => sub {
        ok $r->has_timer, 'timer is running';
        undef $r;
    } );

    throws_ok {
        $cv->recv;
    } qr/DEMOLISH/,
        'we get the DEMOLISH message even when the timer is running';
}

done_testing;
