#!/usr/bin/env perl

use strict;
use warnings;
use AnyEvent::RabbitMQ::Simple;

# create main loop
my $loop = AE::cv;

my $rmq = AnyEvent::RabbitMQ::Simple->new(
    failure_cb => sub {
        my ($event, $details, $why) = @_;
        if ( ref $why ) {
            my $method_frame = $why->method_frame;
            $why = $method_frame->reply_text;
        }
        $loop->croak("[ERROR] $event($details): $why" );
    },
);

# publisher timer
my $t;

# connect and set up channel
my $conn = $rmq->connect();
$conn->cb(
    sub {
        print "waiting for channel..\n";
        my $channel = shift->recv or $loop->croak("Could not open channel");

        # generated queue name
        my $queue_name = $rmq->gen_queue;

        print "************* consuming\n";
        consume($channel, $queue_name);

        print "************* starting publishing\n";
        $t = AE::timer 0, 1.0, sub { publish($channel, $queue_name, "message prepared at ". scalar(localtime) ) };
    }
);

# consumes from requested queue
sub consume {
    my ($channel, $queue) = @_;

    my $consumer_tag;

    $channel->consume(
        queue => $queue,
        on_success => sub {
            my $frame = shift;
            $consumer_tag = $frame->method_frame->consumer_tag;
            print "************* consuming from $queue with $consumer_tag\n";
        },
        on_consume => sub {
            my $res = shift;
            my $body = $res->{body}->payload;
            print "+++++++++++++ consumed($queue): $body\n";
        },
        on_failure => sub {
            print "************* failed to consume($queue)\n";
        }
    );
}

# randomly generates routing key and message body
sub publish {
    my ($channel, $routing_key, $msg) = @_;

    unless ( $channel->is_open ) {
        warn "Cannot publish, channel closed";
        return;
    }

    $msg = sprintf("[%s] %s", uc($routing_key), $msg);
    print "\n------- publishing: $msg\n";
    $channel->publish(
        routing_key => $routing_key,
        exchange => '',
        body => $msg,
    );
}

# wait forever or die on error
my $done = $loop->recv;


