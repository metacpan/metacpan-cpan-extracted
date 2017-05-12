#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use AnyEvent;

use lib 't/lib';
use TestBot::SingleSendJoin;
use TestBot::SingleRecvJoin;
use WebService::Slack::WebApi;

my $HUMAN_TOKEN   = $ENV{SLACKBOT_TEST_PERSON};
my $SENDBOT_USER  = $ENV{SLACKBOT_TEST_USER1};
my $RECVBOT_USER  = $ENV{SLACKBOT_TEST_USER2};
my $SENDBOT_TOKEN = $ENV{SLACKBOT_TEST_TOKEN1};
my $RECVBOT_TOKEN = $ENV{SLACKBOT_TEST_TOKEN2};
my $CHANNEL       = $ENV{SLACKBOT_TEST_CHANNEL};

unless ($HUMAN_TOKEN and $SENDBOT_USER and $RECVBOT_USER and $SENDBOT_TOKEN and $RECVBOT_TOKEN and $CHANNEL) {
    plan skip_all => 'Please set SLACKBOT_TEST_PERSON, SLACKBOT_TEST__USER1, SLACKBOT_TEST_USER2, SLACKBOT_TEST_TOKEN1, SLACKBOT_TEST_TOKEN2, and SLACKBOT_TEST_CHANNEL in the environment to run tests. Bots must both be invited to the given channel.';
}
else {
    plan tests => 3;
}

my $slack = WebService::Slack::WebApi->new(
    token => $HUMAN_TOKEN,
);

$slack->channels->kick(
    channel => $CHANNEL,
    user    => $SENDBOT_USER,
);

$slack->channels->kick(
    channel => $CHANNEL,
    user    => $RECVBOT_USER,
);

my $ready   = AnyEvent->condvar;
my $done    = AnyEvent->condvar;
my $invited = AnyEvent->condvar;

my $recvbot = TestBot::SingleRecvJoin->new(
    ready   => $ready,
    done    => $done,
    invited => $invited,
    token   => $RECVBOT_TOKEN,
    channel => $CHANNEL,
);
my $sendbot = TestBot::SingleSendJoin->new(
    ready    => $ready,
    say_code => substr(''.rand, 2),
    token    => $SENDBOT_TOKEN,
    channel  => $CHANNEL,
);

my $t = AnyEvent->timer( after => 10, cb => sub {
    fail("test took too long");
    exit(1);
});

$recvbot->run;
$sendbot->run;

my $t2;
$t2 = AnyEvent->timer(interval => 0.5, cb => sub {
    return unless $recvbot->get_service('slack_chat')->rtm->said_hello;
    return unless $sendbot->get_service('slack_chat')->rtm->said_hello;

    #warn "# INVITE RECVBOT\n";
    $slack->channels->invite(
        channel => $CHANNEL,
        user    => $RECVBOT_USER,
    );

    undef $t2;
});

$invited->cb(sub {
    #warn "# INVITE SENDBOT\n";
    $slack->channels->invite(
        channel => $CHANNEL,
        user    => $SENDBOT_USER,
    );
});

$done->recv;

ok(!$recvbot->during_init, 'recvbot invite happened at runtime');
ok(!$sendbot->during_init, 'sendbot invite happened at runtime');
is($recvbot->saw_code, $sendbot->say_code, 'bots exchanged data');
