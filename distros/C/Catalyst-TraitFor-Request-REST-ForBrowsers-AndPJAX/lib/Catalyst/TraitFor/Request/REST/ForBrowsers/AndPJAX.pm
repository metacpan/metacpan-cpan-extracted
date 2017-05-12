#
# This file is part of Catalyst-TraitFor-Request-REST-ForBrowsers-AndPJAX
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Catalyst::TraitFor::Request::REST::ForBrowsers::AndPJAX;
{
  $Catalyst::TraitFor::Request::REST::ForBrowsers::AndPJAX::VERSION = '0.001';
}

# ABSTRACT: Acknowledge C<PJAX> requests as browser requests

use Moose::Role;
use namespace::autoclean;

with 'Catalyst::TraitFor::Request::REST::ForBrowsers' =>{
    -excludes => [ '_build_looks_like_browser' ],
    -alias    => {
        _build_looks_like_browser => '_original_build_looks_like_browser',
    },
};


sub _build_looks_like_browser {
    my ($self) = @_;

    my $pjax = $self->header('X-Pjax') || 'false';

    return 1
        if $pjax eq 'true' && uc $self->method eq 'GET';

    return $self->_original_build_looks_like_browser;
}


!!42;


=pod

=encoding utf-8

=for :stopwords Chris Weyl PJAX Pjax

=head1 NAME

Catalyst::TraitFor::Request::REST::ForBrowsers::AndPJAX - Acknowledge C<PJAX> requests as browser requests

=head1 VERSION

This document describes version 0.001 of Catalyst::TraitFor::Request::REST::ForBrowsers::AndPJAX - released June 06, 2012 as part of Catalyst-TraitFor-Request-REST-ForBrowsers-AndPJAX.

=head1 SYNOPSIS

    # in your app class
    use CatalystX::RoleApplicator;
    __PACKAGE__->apply_request_class_roles(qw/
        Catalyst::TraitFor::Request::REST::ForBrowsers::AndPJAX
    /);

    # then, off in an controller somewhere...
    sub action_GET_html { ... also called for PJAX requests ...  }

=head1 DESCRIPTION

This is a tiny little L<Catalyst::Request> class trait that recognizes that a
PJAX request is also a browser request, and thus looks_like_browser() also
returns true when the method is GET and the C<X-Pjax> header is present and is
'true'.

This allows actions using an action class of REST::ForBrowsers to
transparently handle PJAX requests, without requiring any more modification to
the controller or application than applying this trait to the request class,
rather than plain-old L<Catalyst::TraitFor::Request::REST::ForBrowsers>.

=head1 METHODS

=head2 looks_like_browser

This method is wrapped to return true if the method is GET and the C<X-Pjax>
header is present and is 'true'.

Otherwise we hand things off to the original method, to render its verdict as
to the tenor of the request.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Catalyst::TraitFor::Request::REST::ForBrowsers>

=item *

L<Catalyst::Action::REST::ForBrowsers>

=item *

L<Plack::Middleware::Pjax>

=back

=head1 SOURCE

The development version is on github at L<http://github.com/RsrchBoy/catalyst-traitfor-request-rest-forbrowsers-andpjax>
and may be cloned from L<git://github.com/RsrchBoy/catalyst-traitfor-request-rest-forbrowsers-andpjax.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/catalyst-traitfor-request-rest-forbrowsers-andp
jax/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut


__END__

