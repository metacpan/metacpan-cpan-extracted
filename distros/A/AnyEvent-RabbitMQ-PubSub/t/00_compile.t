use strict;
use Test::More 0.98;

use_ok $_ for qw(
    AnyEvent::RabbitMQ::PubSub
    AnyEvent::RabbitMQ::PubSub::Publisher
    AnyEvent::RabbitMQ::PubSub::Consumer
);

done_testing;

