package Catalyst::Action::DeserializeMultiPart;
$Catalyst::Action::DeserializeMultiPart::VERSION = '1.20';
use Moose;
use namespace::autoclean;

extends 'Catalyst::Action::Deserialize';
use HTTP::Body;

our $NO_HTTP_BODY_TYPES_INITIALIZATION;
$HTTP::Body::TYPES->{'multipart/mixed'} = 'HTTP::Body::MultiPart' unless $NO_HTTP_BODY_TYPES_INITIALIZATION;

override execute => sub {
    my $self = shift;
    my ( $controller, $c ) = @_;
    if($c->request->content_type =~ m{^multipart/}i && !defined($c->request->body)){
        my $REST_part = $self->attributes->{DeserializePart} || [];
        my($REST_body) = $c->request->upload($REST_part->[0] || 'REST');
        if($REST_body){
            $c->request->_body->body( $REST_body->fh );
            $c->request->content_type( $REST_body->type );
        }
    }
    super;
};

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Catalyst::Action::DeserializeMultiPart - Deserialize Data in a Multipart Request

=head1 SYNOPSIS

    package Foo::Controller::Bar;

    __PACKAGE__->config(
        # see Catalyst::Action::Deserialize for standard config
    );

    sub begin :ActionClass('DeserializeMultiPart') DeserializePart('REST') {}

=head1 DESCRIPTION

This action will deserialize multipart HTTP POST, PUT, OPTIONS and DELETE
requests.  It is a simple extension of L<Catalyst::Action::Deserialize>
with the exception that rather than using the entire request body (which
may contain multiple sections), it will look for a single part in the request
body named according to the C<DeserializePart> attribute on that action
(defaulting to C<REST>).  If a part is found under that name, it then
proceeds to deserialize the request as normal based on the content-type
of that individual part.  If no such part is found, the request would
be processed as if no data was sent.

This module's code will only come into play if the following conditions are met:

=over 4

=item * The C<Content-type> of the request is C<multipart/*>

=item * The request body (as returned by C<$c->request->body> is not defined

=item * There is a part of the request body (as returned by C<$c->request->upload($DeserializePart)>) available

=back

=head1 CONFIGURING HTTP::Body

By default, L<HTTP::Body> parses C<multipart/*> requests as an
L<HTTP::Body::OctetStream>.  L<HTTP::Body::OctetStream> does not separate
out the individual parts of the request body.  In order to make use of
the individual parts, L<HTTP::Body> must be told which content types
to map to L<HTTP::Body::MultiPart>.  This module makes the assumption
that you would like to have all C<multipart/mixed> requests parsed by
L<HTTP::Body::MultiPart> module.  This is done by a package variable
inside L<HTTP::Body>: C<$HTTP::Body::Types> (a HASH ref).

B<WARNING:> As this module modifies the behaviour of HTTP::Body globally,
adding it to an application can have unintended consequences as multipart
bodies will be parsed differently from before.

Feel free to
add other content-types to this hash if needed or if you would prefer
that C<multipart/mixed> NOT be added to this hash, simply delete it
after loading this module.

    # in your controller
    use Catalyst::Action::DeserializeMultiPart;

    delete $HTTP::Body::Types->{'multipart/mixed'};
    $HTTP::Body::Types->{'multipart/my-crazy-content-type'} = 'HTTP::Body::MultiPart';

=head1 SEE ALSO

This is a simple sub-class of L<Catalyst::Action::Deserialize>.

=head1 AUTHORS

See L<Catalyst::Action::REST> for authors.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
