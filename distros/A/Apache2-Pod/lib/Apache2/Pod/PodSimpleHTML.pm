=head1 NAME

Apache2::Pod::PodSimpleHTML - Pod::Simple::HTML subclass for Apache2::Pod::HTML

=head1 VERSION

The version is sucked in from whatever
L<Pod::Simple::HTML> version is installed.

=head1 SYNOPSIS

Used by L<Apache2::Pod::HTML>.

I don't understand what this is for or why we use it,
but I'm cleaning up errors because the old name is
already indexed by someone else on CPAN.

=head1 METHODS

=head2 resolve_pod_page_link

We override this to return the link using URI::Escape.

=head1 SEE ALSO

L<Apache2::Pod>

L<Apache2::Pod::HTML>

=head1 AUTHOR

Theron Lewis C<< <theron at theronlewis dot com> >>

Mark Hedges C<< <hedges 831*&#@& scriptdolphin blop org > >>

=head1 LICENSE

This package is licensed under the same terms as Perl itself.

=cut

package Apache2::Pod::PodSimpleHTML;

use strict;
use warnings FATAL => 'all';
use base qw( Pod::Simple::HTML );

*VERSION = *Pod::Simple::HTML::VERSION;

use URI::Escape;


sub resolve_pod_page_link {
    my $self = shift;
    my $to = shift;
    my $section = shift;

    my $link = $to;

    return uri_escape( $link );
}

1;
