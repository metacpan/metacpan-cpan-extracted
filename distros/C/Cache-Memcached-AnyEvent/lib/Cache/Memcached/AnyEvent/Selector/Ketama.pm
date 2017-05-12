package Cache::Memcached::AnyEvent::Selector::Ketama;
use strict;
use Algorithm::ConsistentHash::Ketama;
use Carp ();

sub new {
    my $class = shift;
    my $self = bless{ @_ }, $class;
    $self->set_servers($self->{memcached}->servers);
    return $self;
}

sub set_servers {
    my ($self, $servers) = @_;

    my $ketama = $self->{ketama} = Algorithm::ConsistentHash::Ketama->new;
    foreach my $server (@$servers) {
        my ($host_port, $weight) = (ref $server eq 'ARRAY') ?
            @$server : ( $server, 1 )
        ;
        $ketama->add_bucket($host_port, $weight);
    }
}

sub get_handle {
    my ($self, $key) = @_;
    
    my $count = $self->{memcached}->{_active_server_count};
    if ($count > 0) {
        my $servers = $self->{memcached}->{_active_servers};
        my $handles = $self->{memcached}->{_server_handles};

        # short-circuit for when there's only one socket
        if ($count == 1) {
            return (values %$handles)[0];
        }
    
        my $ketama = $self->{ketama};
        while ( scalar keys %$handles > 0 ) {
            my $server = $ketama->hash($key);
            my $handle = $handles->{ $server };
            if ($handle) {
                return $handle;
            } else {
                $ketama->remove_bucket($server);
            }
        }
    }
    Carp::croak("Could not find a suitable handle for key $key");
}

1;

__END__

=head1 NAME

Cache::Memcached::AnyEvent::Selector::Ketama - Ketama Server Selection Algorithm 
=head1 SYNOPSIS

    use Cache::Memcached::AnyEvent;
    my $memd = Cache::Memcached::AnyEvent->new({
        ...
        selector_class => 'Ketama',
    });

=head1 DESCRIPTION

Implements the ketama server selection mechanism, 

=head1 METHODS

=head2 $class->new( memcached => $memd )

Constructor.

=head2 $selector->set_servers( @servernames )

Called when a new server set is given

=head2 $handle = $selector->get_handle( $key )

Returns the AnyEvent handle that is responsible for handling C<$key>

=cut
