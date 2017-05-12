package Catalyst::Authentication::User::AuthTkt;

use warnings;
use strict;
use base qw( Catalyst::Authentication::User );
__PACKAGE__->mk_accessors(qw( data ticket ));

our $VERSION = '0.15';

=head1 NAME

Catalyst::Authentication::User::AuthTkt - shim for Apache::AuthTkt

=head1 DESCRIPTION

This module implements the Catalyst::Plugin::Authentication API for Apache::AuthTkt.
See Catalyst::Authentication::AuthTkt for complete user documentation.

=head1 METHODS

=cut

=head2 new( I<hash_ref> )

Returns a new User object.

=head2 data

Returns whatever arbitrary data was stored in the AuthTkt.

=head2 ticket

Get/set the ticket data.

=head2 roles

Returns an array for any tokens stored in the AuthTkt.

=cut

sub roles {
    my $self = shift;
    return @{ $self->{tokens} };
}

=head2 id

Returns the user's id (username).

=cut

sub id { $_[0]->{id} }

my %features = ( session => 1, roles => { self_check => 0 }, );

=head2 supported_features

Returns hashref of features this class implements.

=cut

sub supported_features {
    my $self = shift;
    return \%features;
}

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

1;    # End of Catalyst::Authentication::AuthTkt
