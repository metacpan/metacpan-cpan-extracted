#!/usr/bin/env perl

use strict;
use warnings;
use AnyEvent::RabbitMQ::Simple;

# create main loop
my $loop = AE::cv;

my $rmq = AnyEvent::RabbitMQ::Simple->new(
    host       => '127.0.0.1',
    port       => 5672,
    user       => 'guest',
    pass       => 'guest',
    vhost      => '/',
    timeout    => 1,
    tls        => 0,
    verbose    => 0,
    confirm_publish => 1,
    prefetch_count => 10,

    failure_cb => sub {
        my ($event, $details, $why) = @_;
        if ( ref $why ) {
            my $method_frame = $why->method_frame;
            $why = $method_frame->reply_text;
        }
        $loop->croak("[ERROR] $event($details): $why" );
    },

    # routing layout 
    # [========== exchanges ===================] [===== queues ==============]
    # [             (type/routing key)         ] [        (routing key) ]
    #  logger ----------> stats -------------->   stats-logs
    #   |(fanout)           (direct)                (mail.stats)
    #   |  |
    #   |  | \----------> errors ------------->   ftp-error-logs
    #   |  |              | (topic/*.error.#)       (ftp.error.#)
    #   |  |              |
    #   |  |              \------------------->   mail-error-logs
    #   |  |                                        (mail.error.#)
    #   |  |
    #   |   \-----------> info --------------->   info-logs
    #   |                   (topic/*.info.#)        (*.info.#)
    #   |
    #    \------------------------------------>   debug-queue


    # declare exchanges
    exchanges => [
        'logger' => {
            durable => 0,
            type => 'fanout',
            internal => 0,
            auto_delete => 1,
        },
        'stats' => {
            durable => 0,
            type => 'direct',
            internal => 0,
            auto_delete => 1,
        },
        'errors' => {
            durable => 0,
            type => 'topic',
            internal => 0,
            auto_delete => 1,
        },
        'info' => {
            durable => 0,
            type => 'topic',
            internal => 0,
            auto_delete => 1,
        },
    ],

    # declare queues
    queues => [
        'debug-queue' => {
            durable => 0,
            auto_delete => 1,
        },
        'stats-logs' => {
            durable => 0,
            auto_delete => 1,
        },
        'ftp-error-logs' => {
            durable => 0,
            auto_delete => 1,
        },
        'mail-error-logs' => {
            durable => 0,
            auto_delete => 1,
        },
        'info-logs' => {
            durable => 0,
            auto_delete => 1,
        },
    ],

    # exchange to exchange bindings, with optional routing key
    bind_exchanges => [
        { 'stats'   =>   'logger'                 },
        { 'errors'  => [ 'logger', '*.error.#' ]  },
        { 'info'    => [ 'logger', '*.info.#'  ]  },
    ],


    # queue to exchange bindings, with optional routing key
    bind_queues => [
        { 'debug-queue'     =>   'logger'                   },
        { 'ftp-error-logs'  => [ 'errors', 'ftp.error.#'  ] },
        { 'mail-error-logs' => [ 'errors', 'mail.error.#' ] },
        { 'info-logs'       => [ 'info',   'info.#'       ] },
        { 'stats-logs'      => [ 'stats',  'mail.stats'   ] },
    ],

);

# publisher timer
my $t;

# connect and set up channel
my $conn = $rmq->connect();
$conn->cb(
    sub {
        print "waiting for channel..\n";
        my $channel = shift->recv or $loop->croak("Could not open channel");

        print "************* consuming\n";
        for my $q ( qw( debug-queue ftp-error-logs mail-error-logs info-logs stats-logs ) ) {
            consume($channel, $q);
        }

        print "************* starting publishing\n";
        $t = AE::timer 0, 1.0, sub { publish($channel, "message prepared at ". scalar(localtime) ) };
    }
);

# consumes from requested queue
sub consume {
    my ($channel, $queue) = @_;

    my $consumer_tag;

    $channel->consume(
        queue => $queue,
        no_ack => 0,
        on_success => sub {
            my $frame = shift;
            $consumer_tag = $frame->method_frame->consumer_tag;
            print "************* consuming from $queue with $consumer_tag\n";
        },
        on_consume => sub {
            my $res = shift;
            my $body = $res->{body}->payload;
            print "+++++++++++++ consumed($queue): $body\n";
            $channel->ack(
                delivery_tag => $res->{deliver}->method_frame->delivery_tag
            );
        },
        on_failure => sub {
            print "************* failed to consume($queue)\n";
        }
    );
}

# randomly generates routing key and message body
sub publish {
    my ($channel, $msg) = @_;

    unless ( $channel->is_open ) {
        warn "Cannot publish, channel closed";
        return;
    }

    my @system = qw( mail ftp web );
    my @levels = qw( debug info error stats );

    my $routing_key = $system[rand @system] .'.'. $levels[ rand @levels ];

    $msg = sprintf("[%s] %s", uc($routing_key), $msg);
    print "\n------- publishing: $msg\n";
    $channel->publish(
        routing_key => $routing_key,
        exchange => 'logger',
        body => $msg,
        on_ack => sub {
            print "------- published: $msg\n";
        },
        on_return => sub {
            print "************* failed to publish: $msg\n";
        }
    );
}

# wait forever or die on error
my $done = $loop->recv;


