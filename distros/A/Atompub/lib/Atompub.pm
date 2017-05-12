package Atompub;

use warnings;
use strict;

use 5.006;
use version 0.74; our $VERSION = qv('0.3.7');

use HTTP::Headers;
use HTTP::Request;
use HTTP::Response;
use XML::Atom;
use XML::Atom::Service 0.15.4;

our %REQUEST_HEADERS = (
    accept              => 'Accept',
    if_match            => 'If-Match',
    if_none_match       => 'If-None-Match',
    if_modified_since   => 'If-Modified-Since',
    if_unmodified_since => 'If-Unmodified-Since',
);

our %RESPONSE_HEADERS = (
    content_location => 'Content-Location',
    etag             => 'ETag',
    location         => 'Location',
);

our %ENTITY_HEADERS = (
    last_modified => 'Last-Modified',
    slug          => 'Slug',
);

while (my($method, $header) = each %REQUEST_HEADERS) {
    no strict 'refs'; ## no critic
    *{"HTTP::Headers::$method"} = sub { shift->header($header, @_) }
        unless HTTP::Headers->can($method);
    *{"HTTP::Request::$method"} = sub { shift->header($header, @_)}
        unless (HTTP::Request->can($method));
}

while (my($method, $header) = each %RESPONSE_HEADERS) {
    no strict 'refs'; ## no critic
    *{"HTTP::Headers::$method"} = sub { shift->header($header, @_) }
        unless HTTP::Headers->can($method);
    *{"HTTP::Response::$method"} = sub { shift->header($header, @_) }
        unless HTTP::Response->can($method);
}

while (my($method, $header) = each %ENTITY_HEADERS) {
    no strict 'refs'; ## no critic
    *{"HTTP::Headers::$method"} = sub { shift->header($header, @_) }
        unless HTTP::Headers->can($method);
    *{"HTTP::Request::$method"} = sub { shift->header($header, @_) }
        unless HTTP::Request->can($method);
    *{"HTTP::Response::$method"} = sub { shift->header($header, @_) }
        unless HTTP::Response->can($method);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Atompub - Atom Publishing Protocol implementation


=head1 DESCRIPTION

The Atom Publishing Protocol (Atompub) is a protocol for publishing and
editing Web resources described at L<http://www.ietf.org/rfc/rfc5023.txt>.

L<Atompub> implements client L<Atompub::Client> and server L<Atompub::Server> for the protocol.
XML formats used in the protocol are implemented in L<XML::Atom> and
L<XML::Atom::Service>.
Catalyst extension L<Catalyst::Controller::Atompub> is also available.

This module was tested in July2007InteropTokyo and November2007Interop,
and interoperated with other implementations.
See L<http://intertwingly.net/wiki/pie/July2007InteropTokyo> and
L<http://www.intertwingly.net/wiki/pie/November2007Interop> in detail.


=head1 METHODS of HTTP::Headers, HTTP::Request, and HTTP::Response

Some accessors for the HTTP header fields, which are used in the Atom Publishing Protocol,
are imported into L<HTTP::Headers>, L<HTTP::Request>, and L<HTTP::Response>.
See L<http://www.ietf.org/rfc/rfc2616.txt> in detail.


=head2 $headers->accept([ $value ])

An accessor for the I<Accept> header field.

This method is imported into L<HTTP::Headers> and L<HTTP::Request>.

=head2 $headers->if_match([ $value ])

An accessor for the I<If-Match> header field.

This method is imported into L<HTTP::Headers> and L<HTTP::Request>.

=head2 $headers->if_none_match([ $value ])

An accessor for the I<If-None-Match> header field.

This method is imported into L<HTTP::Headers> and L<HTTP::Request>.

=head2 $headers->if_modified_since([ $value ])

An accessor for the I<If-Modified-Since> header field.
$value MUST be UTC epoch value, like C<1167609600>.

This method is imported into L<HTTP::Headers> and L<HTTP::Request>.

=head2 $headers->if_unmodified_since([ $value ])

An accessor for the I<If-Unmodified-Since> header field.
$value MUST be UTC epoch value, like C<1167609600>.

This method is imported into L<HTTP::Headers> and L<HTTP::Request>.

=head2 $headers->content_location([ $value ])

An accessor for the I<Content-Location> header field.

This method is imported into L<HTTP::Headers> and L<HTTP::Response>.

=head2 $headers->etag([ $value ])

An accessor for the I<ETag> header field.

This method is imported into L<HTTP::Headers> and L<HTTP::Response>.

=head2 $headers->location([ $value ])

An accessor for the I<Location> header field.

This method is imported into L<HTTP::Headers> and L<HTTP::Response>.

=head2 $headers->last_modified([ $value ])

An accessor for the I<Last-Modified> header field.

This method is imported into L<HTTP::Headers>, L<HTTP::Request>, and L<HTTP::Response>.

=head2 $headers->slug([ $value ])

An accessor for the I<Slug> header field.

This method is imported into L<HTTP::Headers>, L<HTTP::Request>, and L<HTTP::Response>.


=head1 AUTHOR

Takeru INOUE, E<lt>takeru.inoue _ gmail.comE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
