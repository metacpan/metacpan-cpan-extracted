package AnyMQ::Trait::RawSocket;

use Any::Moose 'Role';

use AnyEvent::Socket;
use AnyEvent::Handle;
use Carp qw/croak/;

has 'address' => ( is => 'rw', isa => 'Str' );

has 'allow_wildcard_subscription' => ( is => 'rw', isa => 'Bool' );

has 'server_socket' => (
    is => 'rw',
    lazy_build => 1,
);

has 'connections' => (
    is => 'rw',
    isa => 'ArrayRef[AnyEvent::Handle]',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        all_connections => 'elements',
        add_connection  => 'push',
    },
);

sub BUILD {}; after 'BUILD' => sub {
    my ($self) = @_;

    # start listening
    $self->server_socket;
};

sub _build_server_socket {
    my ($self) = @_;

    my ($address, $port) = parse_hostport($self->address)
        or croak 'subscribe_address must be defined to subscribe to messages';
    
    my $server = tcp_server $address, $port, sub {
        my ($fh, $rhost, $rport) = @_;

        my $h; $h = new AnyEvent::Handle
           fh => $fh,
           on_read => sub {
               $h->push_read(json => sub {
                   my (undef, $evt) = @_;

                   $self->handle_event($evt);
               });
           },
           on_error => sub {
               my (undef, $fatal, $msg) = @_;
               AE::log error => $msg;
               $self->remove_connection($h);
               $h->destroy;
               undef $h;
           };

        $self->add_connection($h);
    };

    warn "Now listening on $address, port $port\n";

    return $server;
}

sub handle_event {
    my ($self, $evt) = @_;
    
    # find event topic
    my $topic_name = $evt->{Type} || $evt->{type} || $evt->{name} || $evt->{topic} || '*';
    
    $self->topic($topic_name)->publish($evt);
    
    if ($topic_name ne '*') {
        # publish to '*' topic too
        
        $self->topic('*')->publish($evt)
            if $self->allow_wildcard_subscription;
    }
}

sub new_topic {
    my ($self, $opt) = @_;

    # name of topic to subscribe to, passed in
    $opt = { name => $opt } unless ref $opt;

    # use our topic role
    AnyMQ::Topic->new_with_traits(
        %$opt,
        traits => [ 'RawSocket' ],
        bus => $self,
    );
}

sub remove_connection {
    my ($self, $h) = @_;

    $self->connections([ grep { $_ != $h } $self->all_connections ]);
}

sub DEMOLISH {}; after 'DEMOLISH' => sub {
    my $self = shift;
    my ($igd) = @_;

    return if $igd;

    # cleanup
};

1;
