use strict;
use warnings;
use Test::More;

use AnyEvent;
use AnyEvent::Debounce;

{
    my $sent = 0;
    my $done = AnyEvent->condvar;
    my $d = AnyEvent::Debounce->new(
        front_triggered    => 0,
        always_reset_timer => 0,
        delay              => 2,
        cb                 => sub { $done->send([@_]) },
    );

    my $sender; $sender = AnyEvent->timer( after => 0, interval => 0.1, cb => sub {
        $d->send($sent);
        undef $sender if ++$sent > 9;
    });

    my $result = $done->recv;

    is $sent, 10, 'got 10 events before cb was called';
    is_deeply $result, [map { [$_] } 0..9], 'got the events we expected';
}

{
    my $sent = 0;
    my $done = AnyEvent->condvar;
    my $d = AnyEvent::Debounce->new(
        front_triggered    => 0,
        always_reset_timer => 1,
        delay              => 0.15,
        cb                 => sub { $done->send([@_]) },
    );

    my $sender; $sender = AnyEvent->timer( after => 0, interval => 0.1, cb => sub {
        $d->send($sent);
        undef $sender if ++$sent > 9;
    });

    my $result = $done->recv;

    is $sent, 10, 'got 10 events before cb was called';
    is_deeply $result, [map { [$_] } 0..9], 'got the events we expected';
}


{
    my $sent = 0;
    my $got  = 0;
    my $done = AnyEvent->condvar;

    my $d = AnyEvent::Debounce->new(
        front_triggered    => 1,
        always_reset_timer => 0,
        delay              => 1.5,
        cb                 => sub { $got++ },
    );

    $done->begin;
    my $waiter = AnyEvent->timer( after => 2, cb => sub { $done->end } );

    $done->begin;
    my $sender; $sender = AnyEvent->timer( after => 0, interval => 0.1, cb => sub {
        $d->send($sent);
        if(++$sent > 9){
            undef $sender;
            $done->end;
        }
    });

    $done->recv;

    is $sent, 10, 'sent 10 events';
    is $got, 1, 'got 1 event';
}

{
    my $sent = 0;
    my $got  = 0;
    my $done = AnyEvent->condvar;

    my $d = AnyEvent::Debounce->new(
        front_triggered    => 1,
        always_reset_timer => 1,
        delay              => 0.15,
        cb                 => sub { $got++ },
    );

    $done->begin;
    my $waiter = AnyEvent->timer( after => 2, cb => sub { $done->end } );

    $done->begin;
    my $sender; $sender = AnyEvent->timer( after => 0, interval => 0.1, cb => sub {
        $d->send($sent);
        if(++$sent > 9){
            undef $sender;
            $done->end;
        }
    });

    $done->recv;

    is $sent, 10, 'sent 10 events';
    is $got, 1, 'got 1 event';
}

done_testing;
