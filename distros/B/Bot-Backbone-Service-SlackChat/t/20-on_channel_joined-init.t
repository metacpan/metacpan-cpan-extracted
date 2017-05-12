#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use AnyEvent;

use lib 't/lib';
use TestBot::SingleSendJoin;
use TestBot::SingleRecvJoin;

my $SENDBOT_TOKEN = $ENV{SLACKBOT_TEST_TOKEN1};
my $RECVBOT_TOKEN = $ENV{SLACKBOT_TEST_TOKEN2};
my $CHANNEL       = $ENV{SLACKBOT_TEST_CHANNEL};

unless ($SENDBOT_TOKEN and $RECVBOT_TOKEN and $CHANNEL) {
    plan skip_all => 'Please set SLACKBOT_TEST_TOKEN1,SLACKBOT_TEST_TOKEN2, and SLACKBOT_TEST_CHANNEL in the environment to run tests. Bots must both be invited to the given channel.';
}
else {
    plan tests => 3;
}

my $ready = AnyEvent->condvar;
my $done  = AnyEvent->condvar;

my $recvbot = TestBot::SingleRecvJoin->new(
    ready   => $ready,
    done    => $done,
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
    $done->send;
});

$recvbot->run;
$sendbot->run;

$done->recv;

ok($recvbot->during_init, 'recvbot invite happened at startup');
ok($sendbot->during_init, 'sendbot invite happened at startup');
is($recvbot->saw_code, $sendbot->say_code, 'bots exchanged data');
