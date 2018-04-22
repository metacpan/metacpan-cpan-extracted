package Catalyst::Authentication::Realm::AuthTkt;
use strict;
use warnings;
use base qw( Catalyst::Authentication::Realm );
use Carp;

our $VERSION = '0.16';

=head1 NAME

Catalyst::Authentication::Realm::AuthTkt - shim for Apache::AuthTkt

=head1 DESCRIPTION

This module implements the Catalyst::Plugin::Authentication API for Apache::AuthTkt.
See Catalyst::Authentication::AuthTkt for complete user documentation.

=head1 METHODS

=cut

=head2 remove_persisted_user( I<context> )

This method overrides the base class in order to call expire_ticket()
on the Store::AuthTkt object.

=cut

sub remove_persisted_user {
    my ( $self, $c ) = @_;
    $self->SUPER::remove_persisted_user($c);
    $self->store->expire_ticket($c);
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan dot org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-authentication-authtkt at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Authentication-AuthTkt>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Authentication::AuthTkt

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Authentication-AuthTkt>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Authentication-AuthTkt>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Authentication-AuthTkt>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Authentication-AuthTkt>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

