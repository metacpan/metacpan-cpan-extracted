#!/usr/bin/env perl
use v5.14;

use Test::More;
use AnyEvent;
use AnyEvent::SlackRTM;

$SIG{__DIE__} = sub { warn @_; die @_ };

my $token   = $ENV{SLACK_TOKEN};
my $channel = $ENV{SLACK_CHANNEL};

if ($token && $channel) {
    plan tests => 12;
}
else {
    plan skip_all => 'SLACK_TOKEN and SLACK_CHANNEL must be configured for testing messaging.';
}

my $rtm = AnyEvent::SlackRTM->new($token);
isa_ok($rtm, 'AnyEvent::SlackRTM');

my $c = AnyEvent->condvar;
$rtm->on('hello' => sub {
    isa_ok($_[0], 'AnyEvent::SlackRTM');
    is($_[1]{type}, 'hello', 'got hello');
    ok($rtm->said_hello, 'said hello');

    $rtm->send({
        type    => 'message',
        channel => $channel,
        text    => 'I am <your> father!',
    });
});

$rtm->on('message' => sub {
    isa_ok($_[0], 'AnyEvent::SlackRTM');
    is($_[1]{type}, 'message', 'got message');

    # quit on the first *real* message, ignore others
    if ($_[1]{subtype}) {
        return;
    }
    else {
        is($_[1]{text}, "I am &lt;your&gt; father!", 'echo message returned');
        $rtm->ping({ echo => "That's impossible!" });
    }

});

$rtm->on('pong' => sub {
    isa_ok($_[0], 'AnyEvent::SlackRTM');
    is($_[1]{type}, 'pong', 'got pong');
    is($_[1]{echo}, "That's impossible!", 'echo message returned');

    $rtm->close;
});

$rtm->on('finish' => sub {
    isa_ok($_[0], 'AnyEvent::SlackRTM');
    ok($rtm->finished, 'is finished');
    $c->send;
});

$rtm->start;
$c->recv;
