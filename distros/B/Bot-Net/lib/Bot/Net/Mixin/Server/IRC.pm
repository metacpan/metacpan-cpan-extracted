use strict;
use warnings;

package Bot::Net::Mixin::Server::IRC;

use Bot::Net::Mixin;

use POE qw/ Component::Server::IRC /;

=head1 NAME

Bot::Net::Mixin::Server::IRC - mixin class for building IRC servers

=head1 SYNOPSIS

  # Build a basic, no-frills IRC server 
  use strict;
  use warnings;
  package MyBotNet::Server::Main;

  use Bot::Net::Server;
  use Bot::Net::Mixin::Server::IRC;

  1;

=head1 DESCRIPTION

This is the mixin-class for L<Bot::Net> IRC servers. By using this class you create an IRC daemon:

  use Bot::Net::Server;             # define common Bot::Net server features
  use Bot::Net::Mixin::Server::IRC; # we're an IRC server

=head1 METHODS

=head2 setup

Setup a new IRC server.

=cut

sub setup {
    my $self  = shift;
    my $brain = shift;

    $brain->remember( [ 'ircd' ] => POE::Component::Server::IRC->spawn( 
        antiflood => 0,
        config    => $brain->recall( [ config => 'ircd_config' ] ),
        alias     => 'ircd',
    ));
}

=head2 default_configuration PACKAGE

Returns a base configuration for an IRC server daemon.

=cut

sub default_configuration {
    my $class   = shift;
    my $package = shift;

    return {
        ircd_config => {
            servername => lc Bot::Net->short_name_for_server($package) . '.irc',
            nicklen    => 15,
            network    => Bot::Net->config->net('ApplicationName'),
        },
        listeners => [
            { port => 6667 },
        ],
    };
}

=head1 POE STATES

=head2 on _start

At startup, this hanlder loads the information stored in the configuration file and configures the IRC daemon.

=cut

on _start => run {
    # Start receiving server events
    post ircd => 'register';

    yield 'install_auth_configuration';
    yield 'install_operator_configuration';
    yield 'install_listener_configuration';
    yield 'install_peer_configuration';
};

=head2 on install_auth_configuration

Called by L</on _start> to configure the authentication masks. This reads the "masks" section of the configuration and makes it so that only the users found in that configuration may successfully login. 

See L<POE::Component::Server::IRC/add_auth>.

=cut

on install_auth_configuration => run {
    my $log  = recall 'log';
    my $ircd = recall 'ircd';

    # Installing masks
    $log->info("Installing the masks...");
    my $masks = recall [ config => 'masks' ];
    for my $mask (@$masks) {
        $ircd->add_auth( %$mask );
    }
};

=head2 on install_operator_configuration

This is called by L</on _start> and reads the "operators" setting from the configuration file. That configuration will be used to grant logging users server op status.

See L<POE::Component::Server::IRC/add_operator>.

=cut

on install_operator_configuration => run {
    my $log  = recall 'log';
    my $ircd = recall 'ircd';

    # Installing operators
    $log->info("Installing the operators...");
    my $operators = recall [ config => 'operators' ];
    for my $operator (@$operators) {
        $ircd->add_operator( %$operator );
    }
};

=head2 on install_listener_configuration

This event handler initializes a listening port for each entry in the "listeners" setting of the configuration file. This is called by L</on _start>. For each listener initialized, it also reports a READY status message to the logs.

See L<POE::Component::Server::IRC/add_listener>.

=cut

on install_listener_configuration => run {
    my $log  = recall 'log';
    my $ircd = recall 'ircd';

    # Start a listener on the 'standard' IRC port.
    $log->info("Installing the listeners...");
    my $listeners = recall [ config => 'listeners' ];
    for my $listener (@$listeners) {
        $ircd->add_listener( %$listener );
        $log->info("SERVER READY : port $listener->{port}");
    }
};

=head2 on install_peer_configuration

Run by L</on _start>, this handler intiates peer connections between IRC servers to create the IRC network. This will either notify the server that it should be anticipating an incoming connection from a peer or cause it to initiate a connection.

See L<POE::Component::Server::IRC/add_peer>.

=cut

on install_peer_configuration => run {
    my $log  = recall 'log';
    my $ircd = recall 'ircd';

    # Tell the server to wait for a peer connection or initiate one
    $log->info("Installing the peers...");
    my $peers = recall [ config => 'peers' ];
    for my $peer (@$peers) {
        $ircd->add_peer( %$peer );
        $log->info(
            ($peer->{type} eq 'r' ? 'Connecting to'  : 'Listening for')
           .' server peer named '.$peer->{name});
   }
};

=head2 on server quit

This causes the IRC daemon to close all connections and stop listening.

=cut

on server_quit => run {
    recall('log')->warn("Shutting down the server.");
    recall('ircd')->shutdown;

    post ircd => unregister => 'all';
    forget 'ircd';
};

=head1 SEE ALSO

L<Bot::Net::Server>

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
