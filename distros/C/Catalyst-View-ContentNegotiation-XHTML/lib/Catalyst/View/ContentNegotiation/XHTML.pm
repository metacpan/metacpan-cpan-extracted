package Catalyst::View::ContentNegotiation::XHTML;

use Moose::Role;
use MooseX::Types::Moose qw/Num Str ArrayRef/;
use MooseX::Types::Structured qw/Tuple/;
use HTTP::Negotiate qw/choose/;

use namespace::clean -except => 'meta';

# Remember to bump $VERSION in View::TT::XHTML also.
our $VERSION = '1.103';

requires 'process';

has variants => (
    is      => 'ro',
    isa     => ArrayRef[Tuple[Str, Num, Str]],
    lazy    => 1,
    builder => '_build_variants',
);

sub _build_variants {
    return [
        [qw| xhtml 1.000 application/xhtml+xml |],
        [qw| html  0.900 text/html             |],
    ];
}

after process => sub {
    my ($self, $c) = @_;
    if ( my $accept = $self->pragmatic_accept($c) and $c->response->headers->{'content-type'} =~ m|text/html|) {
        my $headers = $c->request->headers->clone;
        $headers->header('Accept' => $accept);
        if ( choose($self->variants, $headers) eq 'xhtml') {
            $c->response->headers->{'content-type'} =~ s|text/html|application/xhtml+xml|;
        }
    }
    $c->response->headers->push_header(Vary => 'Accept');
};

sub pragmatic_accept {
    my ($self, $c) = @_;
    my $accept = $c->request->header('Accept') or return;
    if ($accept =~ m|text/html|) {
        $accept =~ s!\*/\*\s*([,]+|$)!*/*;q=0.5$1!;
    } 
    else {
        $accept =~ s!\*/\*\s*([,]+|$)!text/html,*/*;q=0.5$1!;
    }
    return $accept;
}

1;

__END__

=head1 NAME

Catalyst::View::ContentNegotiation::XHTML - Adjusts the response Content-Type
header to application/xhtml+xml if the browser accepts it.

=head1 SYNOPSIS

    package Catalyst::View::TT;

    use Moose;
    use namespace::clean -except => 'meta';

    extends qw/Catalyst::View::TT/;
    with qw/Catalyst::View::ContentNegotiation::XHTML/;

    1;

=head1 DESCRIPTION

This is a simple Role which sets the response C<Content-Type> to be
C<application/xhtml+xml> if the users browser sends an C<Accept> header
indicating that it is willing to process that MIME type.

Changing the C<Content-Type> to C<application/xhtml+xml> causes browsers to
interpret the page as XML, meaning that your markup must be well formed.

=head1 CAVEATS

This is useful when you're developing your application, as you know that all
pages you view are parsed as XML, so any errors caused by your markup not
being well-formed will show up at once.

Whilst this module is has been tested against most popular browsers including
Internet Explorer, it may cause unexpected results on browsers which do not
properly support the C<application/xhtml+xml> MIME type.

=head1 METHOD MODIFIERS

=head2 after process

Changes the response C<Content-Type> if appropriate (from the requests
C<Accept> header).

=head1 METHODS

=head2 pragmatic_accept

Some browsers (such as Internet Explorer) have a nasty way of sending Accept
*/* and this claiming to support XHTML just as well as HTML. Saving to a file
on disk or opening with another application does count as accepting, but it
really should have a lower q value then text/html. This sub takes a pragmatic
approach and corrects this mistake by modifying the Accept header before
passing it to content negotiation.

=head1 ATTRIBUTES

=head2 variants

Returns an array ref of 3 part arrays, comprising name, priority, output
mime-type, which is used for the content negotiation algorithm.

=head1 PRIVATE METHODS

=head2 _build_variants

Returns the default variant attribute contents.

=head1 SEE ALSO

=over

=item L<Catalyst::View::TT::XHTML> - Trivial Catalyst TT view using this role.

=item L<http://www.w3.org/Protocols/rfc2616/rfc2616-sec12.html> - Content
negotiation RFC.

=back

=head1 BUGS

Should be split into a base ContentNegotiation role which is consumed by
ContentNegotiation::XHTML.

=head1 AUTHOR

    Maintainer and contributor of various features - David Dorward (dorward) C<< <david@dorward.me.uk> >>

    Original author and maintainer - Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

=head1 CONTRIBUTORS

=over

=item Florian Ragwitz (rafl) C<< <rafl@debian.org> >> - Conversion into a
Moose Role, which is what the module should have been originally.

=back

=head1 COPYRIGHT

This module itself is copyright (c) 2008 Tomas Doran and is licensed under the
same terms as Perl itself.

=cut
