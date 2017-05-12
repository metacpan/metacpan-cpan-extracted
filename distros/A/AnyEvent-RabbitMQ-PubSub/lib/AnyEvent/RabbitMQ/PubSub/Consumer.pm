package AnyEvent::RabbitMQ::PubSub::Consumer;
use Moose;
use AnyEvent::RabbitMQ::PubSub;
use Data::Dumper;
use Time::HiRes qw(usleep);

use AnyEvent;
use Promises qw(deferred collect);

has channel => (
    is => 'ro', isa => 'AnyEvent::RabbitMQ::Channel', required => 1
);
has exchange => (
    is => 'ro', isa => 'HashRef', required => 1
);
has queue => (
    is => 'ro', isa => 'HashRef', required => 1
);
has routing_key => (
    is => 'ro', isa => 'Str', default => '#'
);
has prefetch_count => (
    is => 'ro', isa => 'Int', default => 5,
);

sub init {
    my ($self) = @_;

    $self->channel->qos(prefetch_count => $self->prefetch_count);

    my $cv = AnyEvent->condvar;

    $self->declare_exchange_and_queue()
        ->then( sub { $self->bind_queue() })
        ->then( sub { $cv->send() })
        ->catch(sub { $cv->croak(@_) });

    $cv->recv();
    return
}

sub consume {
    my ($self, $cv, $on_consume) = @_;

    my $d = deferred();

    $self->channel->consume(
        queue      => $self->queue->{queue},
        no_ack     => 0,
        on_success => sub { $d->resolve() },
        on_cancel  => sub {AnyEvent::RabbitMQ::PubSub::_report_error($cv, @_)},
        on_failure => sub {AnyEvent::RabbitMQ::PubSub::_report_error($cv, @_)},
        on_consume => sub { $on_consume->($self, @_) },
    );

    return $d->promise
}

sub reject_and_republish {
    my ($self, $msg) = @_;

    usleep 10_000; # wait 10 ms before republish to avoid 100 % CPU
    my $delivery_tag = $msg->{deliver}{method_frame}{delivery_tag};

    $self->channel->reject(delivery_tag => $delivery_tag);

    $msg->{header}{headers}{trials}++;
    $self->channel->publish(
        body        => $msg->{body}->{payload},
        header      => $msg->{header},
        exchange    => "",
        routing_key => $self->queue->{queue},
    );
}

sub ack {
    my ($self, $msg) = @_;

    warn "Message to ack not specified" if !defined $msg;

    my $delivery_tag = $msg->{deliver}{method_frame}{delivery_tag};
    $self->channel->ack(delivery_tag => $delivery_tag);
}

sub declare_exchange_and_queue {
    my ($self, $cv) = @_;

    return collect(
        $self->declare_exchange(),
        $self->declare_queue(),
    )->then(sub {
        return @{ $_[0] }
    });
}

sub declare_queue {
    my ($self) = @_;

    my $d = deferred;
    $self->channel->declare_queue(
        %{ $self->queue },
        on_success => sub { $d->resolve() },
        on_failure => sub { $d->reject(@_) },
    );
    return $d->promise()
}

sub declare_exchange {
    my ($self) = @_;

    my $d = deferred;
    $self->channel->declare_exchange(
        %{ $self->exchange },
        on_success => sub { $d->resolve() },
        on_failure => sub { $d->reject(@_) },
    );
    return $d->promise()
}

sub bind_queue {
    my ($self) = @_;

    my $d = deferred;
    $self->channel->bind_queue(
        queue       => $self->queue->{queue},
        exchange    => $self->exchange->{exchange},
        routing_key => $self->routing_key,
        on_success  => sub { $d->resolve() },
        on_failure => sub { $d->reject(@_) },
    );
    return $d->promise()
}

1
