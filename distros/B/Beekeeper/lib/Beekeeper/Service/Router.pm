package Beekeeper::Service::Router;

use strict;
use warnings;

our $VERSION = '0.04';

use Exporter 'import';

our @EXPORT_OK = qw(
    bind_remote_session
    unbind_remote_session
    unbind_remote_address
);

our %EXPORT_TAGS = ('all' => \@EXPORT_OK );


sub bind_remote_session {
    my ($self, %args) = @_;

    my $params = {
        address     => $args{'address'},
        caller_id   => $self->{_CLIENT}->{caller_id},
        caller_addr => $self->{_CLIENT}->{caller_addr},
        auth_data   => $self->{_CLIENT}->{auth_data},
    };

    my $guard = $self->__use_authorization_token('BKPR_ROUTER');

    $self->call_remote(
        method => '_bkpr.router.bind',
        params => $params,
    );
}

sub unbind_remote_session {
    my ($self) = @_;

    my $params = { caller_id => $self->{_CLIENT}->{caller_id} };

    my $guard = $self->__use_authorization_token('BKPR_ROUTER');

    $self->call_remote(
        method => '_bkpr.router.unbind',
        params => $params,
    );
}

sub unbind_remote_address {
    my ($self, %args) = @_;

    my $params = { address => $args{'address'} };

    my $guard = $self->__use_authorization_token('BKPR_ROUTER');

    $self->call_remote(
        method => '_bkpr.router.unbind',
        params => $params,
    );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Beekeeper::Service::Router - Route messages between backend and frontend buses

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

  $self->bind_remote_session( address => "frontend.user-123" );
  
  $self->send_notification(
      method  => 'myapp.private_message',
      address => 'frontend.user-123',
      params  => 'hello',
  );
  
  $self->unbind_remote_session;
  
  $self->unbind_remote_address( address => "frontend.user-123" );

=head1 DESCRIPTION

Router workers shovel requests messages between frontend and backend brokers.

Additionally, routers include some primitives that can be used to implement session 
management and push notifications.

If the application does not bind client sessions the routers can scale really well,
as you can have a lot of them in a large number of servers. 

But please note that when the application does use the session binding mechanism all
routers will need to share an address table, and this shared table will not scale as 
well as the rest of the system. So a better strategy (some kind of partition) will 
be needed for applications with a large number of concurrent clients.

=head1 METHODS

=head3 bind_remote_session ( address => $address )

Make authorization data persist for remote caller session and optionally assign an 
arbitrary address to the remote client.

The authorization data can be used to store a session ID or other tokens which identify
requests as coming from a particular remote client.

If an address is provided it can be used to push notifications to the client. The same
address can be assigned to multiple remote clients, and all of them will receive the 
notifications sent to it. This is intended to allow to push notifications to users logged 
into multiple devices.

=head3 unbind_remote_session

Clear the authorization data and address assignment of a single remote caller session.

This does not affect other remote clients which share the same address. This is intended
to implement "logout from this device" functionality.

=head3 unbind_remote_address ( address => $address )

Clear the authorization data and address assignment of all remote clients which were
assigned the given address.

This is intended to implement "logout from all devices" functionality.

=head1 SEE ALSO
 
L<Beekeeper::Service::Router::Worker>

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2021 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
