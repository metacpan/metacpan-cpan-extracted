#!/usr/bin/env perl
use v5.14;

use Test::More;
use AnyEvent;
use AnyEvent::SlackRTM;

my $token   = $ENV{SLACK_TOKEN};
my $channel = $ENV{SLACK_CHANNEL};

my $got_api;
eval {
    $got_api = eval 'use WebService::Slack::WebApi; $WebService::Slack::WebApi::VERSION';
    undef $got_api if $@;
};

$SIG{__DIE__} = sub { warn @_; die @_ };

if ($token && $channel && $got_api) {
    plan tests => 14;
}
else {
    plan skip_all => 'SLACK_TOKEN and SLACK_CHANNEL must be configured and WebService::Slack::WebApi installed for testing API messaging.';
}

my $api = WebService::Slack::WebApi->new(token => $token);
my $rtm = AnyEvent::SlackRTM->new($token);
isa_ok($rtm, 'AnyEvent::SlackRTM');

my $c = AnyEvent->condvar;
$rtm->on('hello' => sub {
    isa_ok($_[0], 'AnyEvent::SlackRTM');
    is($_[1]{type}, 'hello', 'got hello');
    ok($rtm->said_hello, 'said hello');

    $api->chat->post_message(
        channel => $channel,
        text    => 'I am <your> father!',
    );
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

