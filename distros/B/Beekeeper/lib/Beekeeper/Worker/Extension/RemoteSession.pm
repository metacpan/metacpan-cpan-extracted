package Beekeeper::Worker::Extension::RemoteSession;

use strict;
use warnings;

our $VERSION = '0.10';

use Exporter 'import';

our @EXPORT = qw(
    bind_remote_session
    unbind_remote_session
    unbind_remote_address
);

# Show errors from perspective of caller
$Carp::Internal{(__PACKAGE__)}++;


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
        method  => '_bkpr.router.bind',
        params  => $params,
        timeout => $args{'timeout'},
    );
}

sub bind_remote_session_async {
    my ($self, %args) = @_;

    my $params = {
        address     => $args{'address'},
        caller_id   => $self->{_CLIENT}->{caller_id},
        caller_addr => $self->{_CLIENT}->{caller_addr},
        auth_data   => $self->{_CLIENT}->{auth_data},
    };

    my $guard = $self->__use_authorization_token('BKPR_ROUTER');

    $self->call_remote_async(
        method     => '_bkpr.router.bind',
        params     => $params,
        timeout    => $args{'timeout'},
        on_success => $args{'on_success'},
        on_error   => $args{'on_error'},
    );
}

sub unbind_remote_session {
    my ($self, %args) = @_;

    my $params = { caller_id => $self->{_CLIENT}->{caller_id} };

    my $guard = $self->__use_authorization_token('BKPR_ROUTER');

    $self->call_remote(
        method  => '_bkpr.router.unbind',
        params  => $params,
        timeout => $args{'timeout'},
    );
}

sub unbind_remote_session_async {
    my ($self, %args) = @_;

    my $params = { caller_id => $self->{_CLIENT}->{caller_id} };

    my $guard = $self->__use_authorization_token('BKPR_ROUTER');

    $self->call_remote_async(
        method     => '_bkpr.router.unbind',
        params     => $params,
        timeout    => $args{'timeout'},
        on_success => $args{'on_success'},
        on_error   => $args{'on_error'},
    );
}

sub unbind_remote_address {
    my ($self, %args) = @_;

    my $params = { address => $args{'address'} };

    my $guard = $self->__use_authorization_token('BKPR_ROUTER');

    $self->call_remote(
        method  => '_bkpr.router.unbind',
        params  => $params,
        timeout => $args{'timeout'},
    );
}

sub unbind_remote_address_async {
    my ($self, %args) = @_;

    my $params = { address => $args{'address'} };

    my $guard = $self->__use_authorization_token('BKPR_ROUTER');

    $self->call_remote_async(
        method     => '_bkpr.router.unbind',
        params     => $params,
        timeout    => $args{'timeout'},
        on_success => $args{'on_success'},
        on_error   => $args{'on_error'},
    );
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Beekeeper::Worker::Extension::RemoteSession - Remote client session handling

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

  use Beekeeper::Worker::Extension::RemoteSession;
  
  $self->bind_remote_session( address => "frontend.user-123" );
  
  $self->send_notification(
      method  => 'myapp.private_message',
      address => 'frontend.user-123',
      params  => 'hello',
  );
  
  $self->unbind_remote_session;
  
  $self->unbind_remote_address( address => "frontend.user-123" );
  
  $self->bind_remote_session_async(
      address    => "frontend.user-123";
      on_success => sub {
          log_info "Address assigned";
      },
      on_error => sub {
          my ($error) = @_;
          log_error $error->message;
      },
  );

=head1 DESCRIPTION

This extension allows to assign authorization data to remote client sessions and
give arbitrary addresses to them. These addresses can be used later to push unicasted 
notifications to clients.

Router workers pull requests from all frontend brokers and forward them to the single
backend broker it is connected to, and pull generated responses from the backend and
forward them to the aproppiate frontend broker which the client is connected to.

Additionally, routers include some primitives that can be used to implement session
management and push notifications. In order to push unicasted notifications, routers will
keep an in-memory shared table of client connections and server side assigned addresses.
Each entry consumes 1.5 KiB of memory, so a table of 100K sessions will consume around
150 MiB for each Router worker.

If the application does not bind client sessions the routers can scale horizontally 
really well, as you can have thousands of them connected to hundreds of brokers.

But please note that, when the application does use the session binding mechanism, all
routers will need the in-memory shared table, and this shared table will not scale to 
a great extent as the rest of the system. The limiting factor is the global rate of 
updates to the table, which will cap around 5000 bind operations (logins) per second.
This might be fixed on future releases by means of partitioning the table. Meanwhile, 
this session binding mechanism is not suitable for applications with a large number
of concurrent clients.

Router workers are not created automatically. In order to add Router workers to a pool
these must be declared into config file C<pool.config.json>.

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

=head3 bind_remote_session_async ( address => $address, on_success => $cb, on_error => $cb )

Asynchronous version of C<bind_remote_session> method.

Callbacks C<on_success> and C<on_error> must be coderefs and will receive respectively 
L<Beekeeper::JSONRPC::Response> and L<Beekeeper::JSONRPC::Error> objects as arguments.

=head3 unbind_remote_session_async ( on_success => $cb, on_error => $cb )

Asynchronous version of C<unbind_remote_session> method.

=head3 unbind_remote_address_async ( address => $address, on_success => $cb, on_error => $cb )

Asynchronous version of C<unbind_remote_address> method.

=head1 SEE ALSO
 
L<Beekeeper::Service::Router::Worker>

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2023 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
