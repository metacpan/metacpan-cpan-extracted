package AnyMQ::Topic::Trait::Pg;

use Any::Moose 'Role';

has 'publish_to_queues' => (is => 'rw', default => 0);

# publish to a channel
sub dispatch_messages {
    my ($self, @events) = @_;

    my $channel = $self->name;

    foreach my $event (@events) {
        my $encoded = $self->bus->encode_event($event) or next;
        $self->bus->notify($channel, $encoded);
    }
}

# subscribe to a channel
after 'add_subscriber' => sub {
    my ($self, $queue) = @_;

    my $channel = $self->name;
    $self->bus->listen($channel);
};

1;
