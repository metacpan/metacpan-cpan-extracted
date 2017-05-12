#!/usr/bin/env perl
use v5.14;

use Test::More;
use AnyEvent;
use AnyEvent::SlackRTM;

$SIG{__DIE__} = sub { warn @_; die @_ };

my $token = $ENV{SLACK_TOKEN};
if ($token) {
    plan tests => 9;
}
else {
    plan skip_all => 'No SLACK_TOKEN configured for testing.';
}

my $rtm = AnyEvent::SlackRTM->new($token);
isa_ok($rtm, 'AnyEvent::SlackRTM');

my $c = AnyEvent->condvar;
$rtm->on('hello' => sub { 
    isa_ok($_[0], 'AnyEvent::SlackRTM');
    is($_[1]{type}, 'hello', 'got hello');
    ok($rtm->said_hello, 'said hello');

    $rtm->ping({ echo => 'I am your father!' });
});

$rtm->on('pong' => sub {
    isa_ok($_[0], 'AnyEvent::SlackRTM');
    is($_[1]{type}, 'pong', 'got pong');
    is($_[1]{echo}, 'I am your father!', 'echo message returned');

    $rtm->close;
});

$rtm->on('finish' => sub {
    isa_ok($_[0], 'AnyEvent::SlackRTM');
    ok($rtm->finished, 'is finished');
    $c->send;
});

$rtm->start;
$c->recv;
