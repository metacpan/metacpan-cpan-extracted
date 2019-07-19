package Dancer2::Plugin::WebSocket::Group;
our $AUTHORITY = 'cpan:YANICK';
# ABSTACT: Grouping of connections to send messages to
$Dancer2::Plugin::WebSocket::Group::VERSION = '0.2.0';

use strict;
use warnings;

use Moo;


has source => (
    is => 'ro',
    required => 1,
);

has channels => (
    is => 'ro',
    required => 1,
);

use Set::Tiny;

sub targets {
    my ( $self, $omit_self ) = @_;

    my $channels = Set::Tiny->new( @{$self->channels} );

    return grep { 
        $_->in_channel($channels) and
        ( !$omit_self or $self->source->id != $_->id )
    } values %{ $self->source->manager->connections };
}


sub send {
    my ( $self, @args ) = @_;

    $_->send(@args) for $self->targets;
}


sub broadcast {
    my ( $self, @args ) = @_;

    $_->send(@args) for $self->targets(1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::WebSocket::Group

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

    websocket_on_message sub {
        my( $conn, $message ) = @_;

        if ( $message eq 'tell to everybody' ) {
            $conn->to( '* ' )->send( "HEY, Y'ALL!" );
        }
    };

=head1 DESC

Those objects are generated via the C<to> method of the L<Dancer2::Plugin::WebSocket::Connection>
objects, and allow to easily send to groups of connections.

In addition to any channels one might fancy creating, each connection also has a private
channel that is associated to its numerical id, and a global channel C<*> also exist
to send messages to all connections.

=head2 Methods

=over

=item send( $message )

Send the message to all connections of the group.

    $conn->to( 'players' )->send( "Hi!" );

=item broadcast( $message )

Send the message to all connections of the group, except the original connection.

    websocket_on_message sub {
        my( $conn, $msg ) = @_;

        if ( $msg eq ='resign' ) {
            $conn->broadcast( "player ", $conn->idm " resigned" );
        }
    }

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
