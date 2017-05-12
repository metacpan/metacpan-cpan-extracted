package AnyMQ::Topic::Trait::AMQP;
use Moose::Role;

has publisher_only => (is => "ro", isa => "Bool");

sub BUILD {}; after 'BUILD' => sub {
    my $self = shift;
    return if $self->publisher_only;

    $self->bus->_rf_channel->bind_queue(
        exchange    => $self->bus->exchange,
        queue       => $self->bus->_rf_queue,
        routing_key => $self->name,
        on_success  => $self->bus->cv,
    );
};

before publish => sub {
    my ($self, @events) = @_;
    $self->bus->_rf_channel->publish(
        exchange    => $self->bus->exchange,
        routing_key => $self->name,
        header      => { reply_to => $self->bus->_rf_queue },
        body => JSON::to_json($_)
    ) for @events;
};

sub DEMOLISH {}; after 'DEMOLISH' => sub {
    my $self = shift;
    my ($igd) = @_;
    return if $igd;
    return if $self->publisher_only;
    $self->bus->_rf_channel->unbind_queue(
        queue       => $self->bus->_rf_queue,
        routing_key => $self->name,
        on_success  => $self->bus->cv,
    );
};

1;
