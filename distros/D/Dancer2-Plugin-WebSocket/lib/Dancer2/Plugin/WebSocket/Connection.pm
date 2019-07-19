package Dancer2::Plugin::WebSocket::Connection;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Role tying Plack::App::WebSocket::Connection with the Dancer serializer
$Dancer2::Plugin::WebSocket::Connection::VERSION = '0.2.0';


use Scalar::Util qw/ refaddr /;
use Set::Tiny;

use Dancer2::Plugin::WebSocket::Group;

use Moo::Role;

has manager => (
    is => 'rw',
);

has serializer => (
    is => 'rw',
);

has id => (
    is => 'ro',
    lazy => 1,
    default => sub { refaddr shift },
);

has channels => (
    is => 'rw',
    lazy => 1,
    clearer => 1,
    default =>  sub { Set::Tiny->new( '*', $_[0]->id ) },
);


sub set_channels {
    my ( $self, @channels ) = @_;
    $self->clear_channels;
    $self->add_channels(@channels);
}


sub add_channels {
    my ( $self, @channels ) = @_;
    $self->channels->insert(@channels);
}

around send => sub {
    my( $orig, $self, $message ) = @_;
    if( my $s = $self->serializer and ref $message ne 'AnyEvent::WebSocket::Message' ) {
        $message = $s->encode($message);
    }
    $orig->($self,$message);
};


sub in_channel {
    my ( $self, @channels ) = @_;
    my $target_set;
    if ( @channels == 1 and ref $channels[0] eq 'Set::Tiny' ) {
        $target_set = shift @channels;
    }
    else {
        $target_set = Set::Tiny->new(@channels);
    }
    return not $self->channels->is_disjoint($target_set);
}


sub to {
    my ( $self, @channels ) = @_;
    return Dancer2::Plugin::WebSocket::Group->new(
        source => $self,
        channels => \@channels,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::WebSocket::Connection - Role tying Plack::App::WebSocket::Connection with the Dancer serializer

=head1 VERSION

version 0.2.0

=head1 DESCRIPTION

The connection objects used by L<Dancer2::Plugin::WebSocket> are
L<Plack::App::WebSocket::Connection> objects augmented with this role.

=head2 Attributes

=over serializer

Serializer object used to serialize/deserialize messages. If it's not
C<undef>, all messages that are not L<AnyEvent::WebSocket::Message> objects 
are assumed to be JSON and will be deserialized
before being passed to the handlers, and will be serialized after being
give to C<send>. 

=over id

A numerical value that is the id of the connection. 

=item

=head2 Methods

=over

=item set_channels( @channels )

Set the channels this connection belongs to. In addition to the C<@channels> provided, the
connection is always associated to its id channel (which is always numerical)
as well as the global channel C<*>.

=item add_channels( @channels )

Add C<@channels> to the list of channels the connection belongs to.

=item in_channel( @channels )

Returns C<true> if the connection belongs to at least one of the 
given C<@channels>.

=item to( @channels )

Returns a L<Dancer2::Plugin::WebSocket::Group> that will emit messages
to all connections belonging to the given C<@channels>.

    $conn->to( 'players' )->send( "game about to begin" );

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
