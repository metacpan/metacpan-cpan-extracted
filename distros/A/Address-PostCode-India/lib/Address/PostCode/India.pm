package Address::PostCode::India;

$Address::PostCode::India::VERSION   = '0.08';
$Address::PostCode::India::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Address::PostCode::India - Interface to the India PinCode.

=head1 VERSION

Version 0.08

=cut

use 5.006;
use JSON;
use Data::Dumper;
use Address::PostCode::UserAgent;
use Address::PostCode::India::Place;

use Moo;
use namespace::clean;
extends 'Address::PostCode::UserAgent';

our $BASE_URL = 'http://getpincodes.info/api.php';

=head1 DESCRIPTION

The API service  is provided by L<website|http://getpincodes.info/apidetail.php>.

A Postal Index Number or PIN or Pincode is the post office numbering or post code
system used by India Post, the Indian postal administration. The code is 6 digits
long. The PIN was introduced on 15 August 1972.

There are nine PIN zones in India,including eight regional zones & one functional
zone  (Indian Army). The  first  digit  of the PIN code indicates the region. The
second digit indicates the sub-region, and  the third digit indicates the sorting
district within the region.The final three digits are assigned to individual post
offices.

    +-------------------------+-------------------------------------------------+
    | First 2/3 Digits of PIN | Postal Circle                                   |
    +-------------------------+-------------------------------------------------+
    | 11                      | Delhi                                           |
    | 12 and 13               | Haryana                                         |
    | 14 to 15                | Punjab                                          |
    | 16                      | Chandigarh                                      |
    | 17                      | Himachal Pradesh                                |
    | 18 to 19                | Jammu and Kashmir                               |
    | 20 to 28                | Uttar Pradesh/Uttrakhand                        |
    | 30 to 34                | Rajasthan                                       |
    | 36 to 39                | Gujarat                                         |
    | 40                      | Goa                                             |
    | 40 to 44                | Maharashtra                                     |
    | 45 to 48                | Madhya Pradesh                                  |
    | 49                      | Chhattisgarh                                    |
    | 50 to 53                | Andhra Pradesh                                  |
    | 56 to 59                | Karnataka                                       |
    | 60 to 64                | Tamil Nadu                                      |
    | 67 to 69                | Kerala                                          |
    | 682                     | Lakshadweep (Islands)                           |
    | 70 to 74                | West Bengal                                     |
    | 744                     | Andaman and Nicobar Islands                     |
    | 75 to 77                | Odisha                                          |
    | 78                      | Assam                                           |
    | 79                      | Arunachal Pradesh                               |
    | 793, 794, 783123        | Meghalaya                                       |
    | 795                     | Manipur                                         |
    | 796                     | Mizoram                                         |
    | 799                     | Tripura                                         |
    | 80 to 85                | Bihar and Jharkhand                             |
    +-------------------------+-------------------------------------------------+

=head1 METHODS

=head2 details($pin_code)

It  returns  an object of type L<Address::PostCode::India::Place> on success. The
only parameter requires is the 6-digits pin code.

    use strict; use warnings;
    use Address::PostCode::India;

    my $address  = Address::PostCode::India->new;
    my $pin_code = 832110;
    my $place    = $address->details($pin_code);

    print "City    : ", $place->city,     "\n";
    print "District: ", $place->district, "\n";
    print "State   : ", $place->state,    "\n";

=cut

sub details {
    my ($self, $pin_code) = @_;

    die "ERROR: Missing required param 'pin code'.\n" unless defined $pin_code;
    die "ERROR: Invalid pin code [$pin_code].\n"      unless ($pin_code =~ /^\d{6}$/);

    my $url      = sprintf("%s?pincode=%d", $BASE_URL, $pin_code);
    my $response = $self->get($url);
    my $contents = from_json($response->{'content'});

    return Address::PostCode::India::Place->new($contents->[0]);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Address-PostCode-India>

=head1 BUGS

Please report any bugs or feature requests to C<bug-address-postcode-india at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Address-PostCode-India>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Address::PostCode::India

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Address-PostCode-India>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Address-PostCode-India>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Address-PostCode-India>

=item * Search CPAN

L<http://search.cpan.org/dist/Address-PostCode-India/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2015 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
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

1; # End of Address::PostCode::India
