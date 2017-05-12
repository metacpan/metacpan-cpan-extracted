package Catalyst::Engine::Apache2;
BEGIN {
  $Catalyst::Engine::Apache2::AUTHORITY = 'cpan:BOBTFISH';
}
BEGIN {
  $Catalyst::Engine::Apache2::VERSION = '1.16';
}
# ABSTRACT: Base class for Apache 1.99x and 2.x Engines

use strict;
use warnings;
use base 'Catalyst::Engine::Apache';

sub finalize_headers {
    my ( $self, $c ) = @_;

    $self->SUPER::finalize_headers( $c );

    # This handles the case where Apache2 will remove the Content-Length
    # header on a HEAD request.
    # http://perl.apache.org/docs/2.0/user/handlers/http.html
    if ( $self->apache->header_only ) {
        $self->apache->rflush;
    }

    return 0;
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::Engine::Apache2 - Base class for Apache 1.99x and 2.x Engines

=head1 SYNOPSIS

See L<Catalyst>.

=head1 DESCRIPTION

This is a base class for Apache 1.99x and 2.x Engines.

=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine>.

=over 4

=item finalize_headers

=back

=head1 SEE ALSO

L<Catalyst> L<Catalyst::Engine>.

=head1 AUTHORS

=over 4

=item *

Sebastian Riedel <sri@cpan.org>

=item *

Christian Hansen <ch@ngmedia.com>

=item *

Andy Grundman <andy@hybridized.org>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by The "AUTHORS".

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

