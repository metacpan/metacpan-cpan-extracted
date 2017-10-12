package Dancer2::Plugin::WebSocket::Connection;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Role tying Plack::App::WebSocket::Connection with the Dancer serializer
$Dancer2::Plugin::WebSocket::Connection::VERSION = '0.0.1';

use Moo::Role;

has serializer => (
    is => 'rw',
);

around send => sub {
    my( $orig, $self, $message ) = @_;
    if( my $s = $self->serializer and ref $message ne 'AnyEvent::WebSocket::Message' ) {
        $message = $s->encode($message);
    }
    $orig->($self,$message);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::WebSocket::Connection - Role tying Plack::App::WebSocket::Connection with the Dancer serializer

=head1 VERSION

version 0.0.1

=head1 DESCRIPTION

The connection objects used by L<Dancer2::Plugin::WebSocket> are
L<Plack::App::WebSocket::Connection> objects augmented with this role.

This role does two itsy bitsy things: it adds a read-write C<serializer> attribute,
which typically will be populated by the plugin, and adds an C<around>
modifier for the C<send> method that, if a serializer is configured, 
will serialize any outgoing message that is not a L<AnyEvent::WebSocket::Message>
object.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
