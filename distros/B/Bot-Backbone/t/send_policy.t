#!/usr/bin/perl
use v5.10;
use Moose;

use lib 't/lib';
#use AnyEvent;
use POE;
use Scalar::Util qw( weaken );
use Test::More tests => 16;

{
    package TestBot;
    use Bot::Backbone;

    use Test::More;

    send_policy use_1_second_interval => (
        MinimumInterval => { interval => 1 },
    );

    send_policy use_1_second_interval_but_discard => (
        MinimumInterval => { interval => 1, discard => 1 },
    );

    send_policy dont_repeat_for_1_second => (
        MinimumRepeatInterval => { 
            interval => 1,
            discard  => 1,
        },
    );

    service chat1 => (
        service     => 'TestChat',
        send_policy => 'use_1_second_interval',
    );

    service chat2 => (
        service     => 'TestChat',
        send_policy => 'use_1_second_interval_but_discard',
    );

    service chat3 => (
        service     => 'TestChat',
        send_policy => 'dont_repeat_for_1_second',
    );

}

my $bot = TestBot->new;
$bot->construct_services;

# For reference during testing below
my $chat1 = $bot->get_service('chat1');
my $chat2 = $bot->get_service('chat2');
my $chat3 = $bot->get_service('chat3');

# TODO Figure out what incantation is required to get this version of the
# test run to work.
#my $w;
#$w = AnyEvent->timer(
#    interval => 0.01,
#    cb       => sub {
#        state $counter = 0;
#
#        $counter++;
#
#        if ($counter < 300) {
#            warn "SENDING $counter\n";
#            $bot->get_service('chat1')->send_message(text => $counter);
#            $bot->get_service('chat2')->send_message(text => $counter);
#        }
#        elsif ($counter < 600) {
#            warn "DO NOTHING $counter\n";
#            # do nothing
#        }
#        else {
#            warn "SHUTDOWN $counter\n";
#            $bot->shutdown;
#            warn "SHUTDOWN COMPLETE\n";
#            undef $w;
#        }
#    },
#);

POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->delay(send_test_chat => 0.01);
        },
        send_test_chat => sub {
            state $counter = 0;

            if (++$counter < 300) {
                my $ticktock = $counter % 2 ? 'tick' : 'tock';
                $bot->get_service('chat1')->send_message({ text => $counter });
                $bot->get_service('chat2')->send_message({ text => $counter });
                $bot->get_service('chat3')->send_message({ text => $ticktock });

                $_[KERNEL]->delay(send_test_chat => 0.01);
            }
            else {
                $_[KERNEL]->delay(do_shutdown => 3);
            }
        },
        do_shutdown => sub {
            $bot->shutdown;
        },
    },
);

$bot->run;

# Test chat1 with 1 second intervals
cmp_ok($chat1->mq_count, '>=', 5, 'at least 5 messages sent by now');
cmp_ok($chat1->mq_count, '<=', 8, 'no more than 8 should be sent');

for my $i (0 .. 3) {
    is($chat1->mq->[$i]->{text}, $chat1->mq->[$i+1]->{text} - 1, 
        "messages $i and $i + 1 should be sequential");
}

# Test chat2 with 1 seonc intervals, with extras discarded
cmp_ok($chat2->mq_count, '>=', 2, 'at least 2 messages sent');
cmp_ok($chat2->mq_count, '<=', 5, 'no more than 5 should be sent');

for my $i (0 .. 1) {
    cmp_ok($chat2->mq->[$i]->{text}, '<', $chat2->mq->[$i+1]->{text} - 50, 
        "messages $i and $i + 1 should not be contiguous");
}

# Test chat3 with no repeats for 1 second
cmp_ok($chat3->mq_count, '>=', 4, 'at least 4 messages sent');
cmp_ok($chat3->mq_count, '<=', 10, 'no more than 10 should be sent');

is($chat3->mq->[0]->{text}, 'tick', '0 is tick');
is($chat3->mq->[1]->{text}, 'tock', '1 is tock');
is($chat3->mq->[2]->{text}, 'tick', '2 is tick');
is($chat3->mq->[3]->{text}, 'tock', '3 is tock');
