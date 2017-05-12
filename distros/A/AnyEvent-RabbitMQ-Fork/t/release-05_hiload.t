#!/usr/bin/env perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;

use Test::More;

BEGIN { use_ok 'AnyEvent::RabbitMQ::Fork'; }

use AnyEvent;

use constant VERBOSE  => 0;
use constant TO_SEND  => 10_000;
use constant TO_CHECK => TO_SEND / 10;

my $final = AE::cv;

my $consumer_ch;
my $consume_cb = do {
    my $count = 0;
    sub {
        my $message = shift;

        my $i = $message->{body}->payload;

        unless (++$count % TO_CHECK) {
            cmp_ok $i, q{==}, $count, "saw message $i in order";
        }

        $consumer_ch->ack(
            delivery_tag => $message->{deliver}->method_frame->delivery_tag);

        $final->send('fin') if $i == TO_SEND;
    };
};

my $cv = AE::cv;

my $consumer
  = AnyEvent::RabbitMQ::Fork->new(verbose => VERBOSE)->load_xml_spec->connect(
    host       => 'localhost',
    port       => 5672,
    user       => 'guest',
    pass       => 'guest',
    vhost      => q{/},
    tune       => { heartbeat => 5 },
    on_failure => sub { fail join q{ }, 'consumer on_failure:', @_ },
    on_success => sub {
        my $conn = shift;
        $conn->open_channel(
            on_success => sub {
                $consumer_ch = shift;

                $consumer_ch->qos(prefetch_count => 1)->declare_queue(
                    queue      => 'test_consume',
                    durable    => 0,
                    exclusive  => 1,
                    on_success => sub {
                        $consumer_ch->consume(
                            queue      => 'test_consume',
                            no_ack     => 0,
                            on_consume => $consume_cb,
                            on_success => $cv,
                        );
                    },
                );
            },
        );
    },
  );

$cv->recv;

isa_ok $consumer_ch, 'AnyEvent::RabbitMQ::Fork::Channel';
ok $consumer->is_open,      'consumer is_open';
ok $consumer_ch->is_open,   'consumer channel is_open';
ok $consumer_ch->is_active, 'consumer channel is_active';
ok !$consumer_ch->is_confirm, 'consumer channel !is_confirm';

$cv = AE::cv;

my $producer_ch;
my $producer
  = AnyEvent::RabbitMQ::Fork->new(verbose => VERBOSE)->load_xml_spec->connect(
    host       => 'localhost',
    port       => 5672,
    user       => 'guest',
    pass       => 'guest',
    vhost      => q{/},
    tune       => { heartbeat => 5 },
    on_failure => sub { fail join q{ }, 'producer on_failure:', @_ },
    on_success => sub {
        my $conn = shift;

        $conn->open_channel(
            on_success => sub {
                $producer_ch = shift;

                $producer_ch->confirm(on_success => $cv);
            },
        );
    },
  );

$cv->recv;

isa_ok $producer_ch, 'AnyEvent::RabbitMQ::Fork::Channel';

ok $producer->is_open,       'producer is_open';
ok $producer_ch->is_open,    'producer channel is_open';
ok $producer_ch->is_active,  'producer channel is_active';
ok $producer_ch->is_confirm, 'producer channel is_confirm';

$cv = AE::cv;

my $j = 0;
while (++$j <= TO_SEND) {
    $cv->begin;
    $producer_ch->publish(
        exchange    => q{},
        routing_key => 'test_consume',
        body        => $j,
        on_ack      => sub { $cv->end; },
    );
}

$cv->recv;

# back-track $j after last ++
is $j - 1, TO_SEND, "all messages sent";

is $final->recv, 'fin', 'fin';

done_testing;
