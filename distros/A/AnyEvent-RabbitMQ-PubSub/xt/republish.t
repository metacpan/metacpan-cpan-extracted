#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Data::Dumper;
use AnyEvent::RabbitMQ::PubSub;
use AnyEvent::RabbitMQ::PubSub::Publisher;
use AnyEvent::RabbitMQ::PubSub::Consumer;
use Test::More tests => 1;

my $rmq_connect_opts = {
    host  => $ENV{RMQ_HOST} // 'localhost',
    port  => 5672,
    user  => $ENV{RMQ_USER} // 'guest',
    pass  => $ENV{RMQ_PASS} // 'guest',
    vhost => $ENV{RMQ_VHOST} // 'test',
};

my $exchange = {
    exchange    => 'rabbitmq_pubsub_test',
    type        => 'topic',
    durable     => 0,
    auto_delete => 1,
};

my $queue = {
    queue       => 'rabbitmq_pubsub_test_queue',
    auto_delete => 1,
};

my $routing_key = 'rk';

my ($ar, $channel) = AnyEvent::RabbitMQ::PubSub::connect(%$rmq_connect_opts);

my $cv = AnyEvent->condvar;

my $consumer = AnyEvent::RabbitMQ::PubSub::Consumer->new(
    channel     => $channel,
    exchange    => $exchange,
    queue       => $queue,
    routing_key => $routing_key,
);
$consumer->init();

my $publisher = AnyEvent::RabbitMQ::PubSub::Publisher->new(
    channel     => $channel,
    exchange    => $exchange,
    routing_key => $routing_key,
);
$publisher->init();

my @consumed = ();
my @messages = ('hello world', 'republish', 'hello again');


$consumer->consume(
    $cv,
    sub {
        my ($self, $msg) = @_;
        push @consumed, $msg->{body}->payload;
        if ($msg->{body}->payload eq 'republish') {
            if ($msg->{header}{headers}{trials}) {
                $consumer->ack($msg);
                $cv->send();
            }
            else {
                $self->reject_and_republish($msg);
            }
        }
        else {
            $consumer->ack($msg);
        }
    },
);
$consumer->init();

$publisher->publish(body => $_) for @messages;

$cv->recv;

is_deeply([@consumed], [@messages, 'republish'], 'republish worked');

