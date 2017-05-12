package AnyEvent::RabbitMQ::PubSub::Publisher;
use Moose;

use AnyEvent;

has channel => (
    is => 'ro', isa => 'AnyEvent::RabbitMQ::Channel', required => 1
);
has exchange => (
    is => 'ro', isa => 'HashRef', required => 1
);
has routing_key => (
    is => 'ro', isa => 'Str', default => '#'
);
has default_header => (
    is => 'ro', isa => 'Maybe[HashRef]'
);

sub init {
    my ($self) = @_;

    my $cv = AnyEvent->condvar;

    $self->channel->declare_exchange(
        %{ $self->exchange },
        on_success => sub { $cv->send() },
        on_failure => sub { $cv->croak(@_) },
    );

    $cv->recv();
    return
}

sub publish {
    my ($self, %options) = @_;

    $self->channel->publish(
        exchange    => $self->exchange->{exchange},
        routing_key => $self->routing_key,
        on_inactive => sub { die 'Failed to publish: channel inactive' },
        %options,
        header      => $options{header} // $self->default_header,
        body        => $options{body} // '',
    );
}

1
