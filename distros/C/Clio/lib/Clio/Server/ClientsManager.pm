
package Clio::Server::ClientsManager;
BEGIN {
  $Clio::Server::ClientsManager::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Server::ClientsManager::VERSION = '0.02';
}
# ABSTRACT: Clients manager

use strict;
use Moo;
use Carp qw( croak );
use Class::Load ();

with 'Clio::Role::HasContext';


has 'clients' => (
    is => 'ro',
    lazy => 1,
    default => sub { +{} },
);


sub new_client {
    my ($self, %args) = @_;

    my $uuid = delete $args{id};

    if ( my $client = $self->clients->{ $uuid } ) {
        return $client->_restore( %args );
    }

    my $client_class = $self->c->config->server_client_class;
    $self->c->log->trace("Creating new client, class of $client_class");
    Class::Load::load_class($client_class);

    return $self->clients->{ $uuid } = $client_class->new(
        manager => $self,
        id => $uuid,
        %args
    );
}


sub disconnect_client {
    my ($self, $client_id) = @_;

    $self->c->log->debug("Disconnecting client $client_id");

    $self->clients->{ $client_id }->disconnect;

    delete $self->clients->{ $client_id };
}


sub total_count {
    my $self = shift;

    return scalar keys %{ $self->clients };
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Server::ClientsManager - Clients manager

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Clients manager is created by L<Clio::Server> to manage incoming connections. 

Class used to create new client object is set by configuration key, eg:

    <Server>
        Class TCP
        <Client>
            Class Handle
            ...
        </Client>
    </Server>

would use L<Clio::Server::TCP::Client::Handle>.

Consumes the L<Clio::Role::HasContext>.

=head1 ATTRIBUTES

=head2 clients

    while ( my ($id, $client) = each %{ $clients_manager->clients } ) {
        print $client->write("Welcome client $id");
    }

All managed clients.

=head1 METHODS

=head2 new_client

    my $client = $client_manager->new_client(
        id => $uuid,
        %class_specific_args
    );

Creates new managed client. Arguments are specific to the class.

=head2 disconnect_client

    $client_manager->disconnect_client( $client->id );

Disconnects client.

=head2 total_count

    my $connected_clients = $clients_manager->total_count;

Total number of connected clients.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

