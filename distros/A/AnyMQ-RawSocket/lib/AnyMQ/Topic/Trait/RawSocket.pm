package AnyMQ::Topic::Trait::RawSocket;

use Any::Moose 'Role';

sub BUILD {}; after 'BUILD' => sub {
    my ($self) = @_;

};

# publish to a topic
before 'publish' => sub {
    my ($self, @events) = @_;

    my $pub = $self->bus->server_socket;

    foreach my $event (@events) {
        # send as json to connected listeners
        foreach my $connection ($self->bus->all_connections) {
            $connection->push_write(json => $event);
        }
    }
};

1;
