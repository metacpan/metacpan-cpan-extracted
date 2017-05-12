package AnyEvent::RabbitMQ::PubSub;
use 5.010;
use strict;
use warnings;
use AnyEvent;
use AnyEvent::RabbitMQ;
use Data::Dumper;
use Carp qw(longmess);

our $VERSION = "3.1.2";

sub connect {
    my %connection_opts = @_;

    my $cv = AnyEvent->condvar;

    my $ar = AnyEvent::RabbitMQ->new->load_xml_spec()->connect(
        %connection_opts,
        on_success      => sub { _open_channel_given_condvar($cv, @_) },
        on_failure      => sub { _report_error($cv, @_) },
        on_read_failure => sub { _report_error($cv, @_) },
        on_return       => sub { _report_error($cv, @_) },
        on_close        => sub { _report_error($cv, @_) },
    );

    return $cv->recv()
}

sub open_channel {
    my ($ar) = @_;

    my $cv = AnyEvent->condvar;
    _open_channel_given_condvar($cv, $ar);

    (undef, my $channel) = $cv->recv();

    return $channel
}

sub _open_channel_given_condvar {
    my ($cv, $ar) = @_;

    $ar->open_channel(
        on_success => sub { my $channel = shift; $cv->send($ar, $channel); },
        on_failure => sub { _report_error($cv, @_) },
        on_close   => sub { _report_error($cv, @_) },
    )
}

sub _report_error {
    my ($cv, $why) = @_;
    if (ref($why)) {
        my $method_frame = $why->method_frame;
        $cv->croak(longmess(
            sprintf '%s: %s',
            $method_frame->reply_code || 503,
            $method_frame->reply_text || 'Something went wrong.',
        ));
    }
    else {
        $cv->croak(longmess(Dumper($why)));
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

AnyEvent::RabbitMQ::PubSub - Publish and consume RabbitMQ messages.

=head1 SYNOPSIS

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


=head1 DESCRIPTION

AnyEvent::RabbitMQ::PubSub allows to easily create publishers and consumers
of RabbitMQ messages.

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Miroslav Tynovsky E<lt>tynovsky@avast.comE<gt>

=cut

