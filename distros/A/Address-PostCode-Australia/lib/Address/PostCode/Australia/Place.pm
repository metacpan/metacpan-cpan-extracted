package Address::PostCode::Australia::Place;

$Address::PostCode::Australia::Place::VERSION   = '0.08';
$Address::PostCode::Australia::Place::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Address::PostCode::Australia::Place - Placeholder for 'place' for Address::PostCode::Australia.

=head1 VERSION

Version 0.08

=cut

use 5.006;
use Data::Dumper;

use Moo;
use namespace::clean;

has 'id'        => (is => 'ro');
has 'category'  => (is => 'ro');
has 'location'  => (is => 'ro');
has 'latitude'  => (is => 'ro');
has 'longitude' => (is => 'ro');
has 'postcode'  => (is => 'ro');
has 'state'     => (is => 'ro');

=head1 DESCRIPTION

It holds the place detailed information as provided by API response. It  provides
simple interface to fetch individual information on request.

=head1 METHODS

=head2 id()

Returns the place id.

=head2 category()

Returns the place category.

=head2 location()

Returns the place location.

=head2 latitude()

Returns the place latitude.

=head2 longitude()

Returns the place longitude.

=head2 postcode()

Returns the place postcode.

=head2 state()

Returns the place state.

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Address-PostCode-Australia>

=head1 BUGS

Please report any bugs or feature requests to C<bug-address-postcode-australia at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Address-PostCode-Australia>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Address::PostCode::Australia::Place

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Address-PostCode-Australia>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Address-PostCode-Australia>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Address-PostCode-Australia>

=item * Search CPAN

L<http://search.cpan.org/dist/Address-PostCode-Australia/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2015 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Address::PostCode::Australia::Place
