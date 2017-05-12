[![Build Status](https://travis-ci.org/tynovsky/AnyEvent-RabbitMQ-PubSub.svg?branch=master)](https://travis-ci.org/tynovsky/AnyEvent-RabbitMQ-PubSub)
# NAME

AnyEvent::RabbitMQ::PubSub - Publish and consume RabbitMQ messages.

# SYNOPSIS

    # print 'received Hello World' and exit

    use AnyEvent;
    use AnyEvent::RabbitMQ::PubSub;
    use AnyEvent::RabbitMQ::PubSub::Publisher;
    use AnyEvent::RabbitMQ::PubSub::Consumer;

    my ($rmq_connection, $channel) = AnyEvent::RabbitMQ::PubSub::connect(
        host  => 'localhost',
        port  => 5672,
        user  => 'guest',
        pass  => 'guest',
        vhost => '/',
    );

    my $exchange = {
        exchange    => 'my_test_exchange',
        type        => 'topic',
        durable     => 0,
        auto_delete => 1,
    };

    my $queue = {
        queue       => 'my_test_queue';
        auto_delete => 1,
    };

    my $routing_key = 'my_rk';

    my $cv = AnyEvent->condvar;

    my $consumer = AnyEvent::RabbitMQ::PubSub::Consumer->new(
        channel        => $channel,
        exchange       => $exchange,
        queue          => $queue,
        routing_key    => $routing_key,
    );
    $consumer->init(); #declares channel, queue and binding
    $consumer->consume(
        $cv,
        sub {
            my ($self, $msg) = @_;
            print 'received ', $msg->{body}->payload, "\n";
            $self->channel->ack();
            $cv->send();
        },
    );

    my $publisher = AnyEvent::RabbitMQ::PubSub::Publisher->new(
        channel     => $channel,
        exchange    => $exchange,
        routing_key => $routing_key,
    );
    $publisher->init(); #declares exchange;
    $publisher->publish(body => 'Hello World');

    $cv->recv();

# DESCRIPTION

AnyEvent::RabbitMQ::PubSub allows to easily create publishers and consumers
of RabbitMQ messages.

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Miroslav Tynovsky <tynovsky@avast.com>
