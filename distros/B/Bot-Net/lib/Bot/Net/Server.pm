use strict;
use warnings;

package Bot::Net::Server;

use Bot::Net::Mixin;

require Exporter;
push our @ISA, 'Exporter';

our @EXPORT = (
    # Re-export POE::Session constants
    qw/ OBJECT SESSION KERNEL HEAP STATE SENDER CALLER_FILE CALLER_LINE
        CALLER_STATE ARG0 ARG1 ARG2 ARG3 ARG4 ARG5 ARG6 ARG7 ARG8 ARG9 /,

    # Re-export POE::Declarative
    @POE::Declarative::EXPORT, 
    
    # Re-export Data::Remember
    qw/ remember recall forget brain /,

    # Add in our own subs
    qw/ server setup /,
);

=head1 NAME

Bot::Net::Server - mixin class for building Bot::Net servers

=head1 SYNOPSIS

  bin/botnet server --name Main --mixin IRC

=head1 DESCRIPTION

This is the main mixin class implemented by all L<Bot::Net> servers. A server may facilitate the communication between bots. In some cases, a server may also simultaneously be a bot too (IRC server bots can be helpful for authentication and channel and nick management, for example). 

=head1 METHODS

=head2 import

Custom exporter for this mixin.

=cut

sub import {
    my $class = shift;

    $class->export_to_level(1, undef);
    $class->export_poe_declarative_to_level;

    my $package = caller;
    no strict 'refs';
    push @{ $package . '::ISA' }, qw/ Bot::Net::Object /;
}

=head2 server

This is a helper for L<POE::Declarative>. It prefixes "server_" to the name of your POE states. For example:

  on server startup => run { ... };

is the same as:

  on server_startup => run { ... };

It can also be used to yield messages:

  yield server 'startup'; # probably shouldn't actually do that

You may choose to use it or not.

=cut

sub server($) { 'server_'.shift }

=head2 setup

Setup the server and call all the mixin C<setup> methods.

=cut

sub setup {
    my $class = shift;
    my $self  = bless {}, $class;

    my $name = Bot::Net->short_name_for_server($class);
    my $config_file = Bot::Net->config->server_file($name);

    my $config;
    { 
        no strict 'refs';
        $config = ${ $class . '::CONFIG' } || $config_file;
    }

    my $brain = brain->new_heap( Hybrid => [] => 'Memory' );

    # Configuration is defined in the package itself (mostly for testing)
    if (ref $config) {
        $brain->remember( [ 'config' ] => $config );
    }

    # Use the YAML config file
    else {
        -f $config_file
            or die qq{Server startup failed, }
                .qq{no configuration found for $name: $config_file};

        $brain->register_brain(
            config => [ YAML => file => $config_file ]
        );
    }

    if (my $state_file = $brain->recall([ config => 'state_file' ])) {
        $brain->register_brain(
            state => [ DBM => file => $state_file ]
        );
    }

    $brain->remember( [ 'name' ] => $name );
    $brain->remember( [ 'log'  ] => $self->log);

    # Setup any mixins
    my $mixins = Bot::Net::Mixin::_mixins_for_package($class);
    for my $mixin (@$mixins) {
        
        # Don't setup this one
        next if $mixin->isa('Bot::Net::Server');

        if (my $method = $mixin->can('setup')) {
            $method->($self, $brain);
        }
    }

    POE::Declarative->setup($self, $brain);
}

=head2 default_configuration PACKAGE

Returns a base configuration appropriate for all servers.

=cut

sub default_configuration {
    my $class   = shift;
    my $package = shift;

    my $filename = join '/', split /::/, 
        Bot::Net->short_name_for_server($package);

    return {
        state_file => 'var/server/'.$filename.'.db',
    };
}

=head1 SERVER STATES

These are additional states your server (or server mixin) may choose to implement that are provided to your server.

=head2 on server startup

This is yielded at the end of the L</on _start> handler for the L<POE> session. Your server should perform any initialization needed here.

=head2 on server quit

A server should emit this state when it wants the server to disconnect and shutdown. If all mixins are implemented correctly, they should listen for this state and close all resources, which should result in the server going into the L</on _stop> state and exiting shortly after emitting this state. (If they are not, the server might just be stuck alive and have to be killed externally.)

This should be used by protocol mixins to implement the shutdown sequence for their listening ports, open files, etc.

=head2 on server shutdown

This is called synchronously at the end of the L</on _stop> handler for the L<POE> session. 

=head1 POE STATES

=head2 on _start

Handles session startup. At startup, it loads the information stored in the configuration file and then fires L</on server startup>.

=cut

on _start => run {
    yield server 'startup';
    undef;
};

=head2 on _default ARG0 .. ARGN

Performs logging for the general messages that are not handled by the system.

=cut

on _default => run {
    my ( $event, $args ) = @_[ ARG0 .. $#_ ];

    my $msg = "$event: ";
    foreach (@$args) {
        SWITCH: {
            if ( ref($_) eq 'ARRAY' ) {
                $msg .= "[". join ( ", ", @$_ ). "] ";
                last SWITCH;
            }
            if ( ref($_) eq 'HASH' ) {
                $msg .= "{". join ( ", ", %$_ ). "} ";
                last SWITCH;
            }
            unless (defined $_) {
                $_ = '';
            }
            $msg .= "'$_' ";
        }
    }
    recall('log')->debug($msg);
    return 0;    # Don't handle signals.
};

=head2 on _stop

This calls (synchronously) the L</on server shutdown> state, to handle any final clean up before quitting.

=cut

on _stop => run {
    call get(SESSION) => server 'shutdown';
};

=head1 SEE ALSO

L<Bot::Net::Mixin::Server::IRC>

=head1 AUTHORS

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
