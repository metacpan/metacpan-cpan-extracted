package Address::PostCode::UK;

$Address::PostCode::UK::VERSION   = '0.13';
$Address::PostCode::UK::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Address::PostCode::UK - Interface to the UK PostCode.

=head1 VERSION

Version 0.13

=cut

use 5.006;
use JSON;
use Data::Dumper;
use Address::PostCode::UserAgent;
use Address::PostCode::UK::Location;
use Address::PostCode::UK::Place;
use Address::PostCode::UK::Place::Geo;
use Address::PostCode::UK::Place::Ward;
use Address::PostCode::UK::Place::Council;
use Address::PostCode::UK::Place::Constituency;

use Moo;
use namespace::clean;
extends 'Address::PostCode::UserAgent';

our $BASE_URL = 'http://uk-postcodes.com';

=head1 DESCRIPTION

Interface to the API provided by L<UK Postcodes|http://uk-postcodes.com/>.

=head1 NOTE

Data  may  be  used  under the terms of the OS OpenData licence. Northern Ireland
postcode  data may be used under the terms of the ONSPD licence. Currently, there
are no limitations on usage, but they may introduce rate limiting in future.

=head1 METHODS

=head2 details()

It returns an object of type L<Address::PostCode::UK::Place> on success. The only
parameter requires is the post code.

    use strict; use warnings;
    use Address::PostCode::UK;

    my $address   = Address::PostCode::UK->new;
    my $post_code = 'Post Code';
    my $place     = $address->details($post_code);

    print "Latitude : ", $place->geo->lat, "\n";
    print "Longitude: ", $place->geo->lng, "\n";

=cut

sub details {
    my ($self, $post_code) = @_;

    die "ERROR: Missing required param 'post code'.\n" unless defined $post_code;
    die "ERROR: Invalid format for UK post code [$post_code].\n" unless ($post_code =~ /[A-Z]{1,2}[0-9][0-9A-Z]?\s?[0-9][A-Z]{2}/gi);

    $post_code =~ s/\s//g;
    my $url      = sprintf("%s/postcode/%s.json", $BASE_URL, $post_code);
    my $response = $self->get($url);
    my $contents = from_json($response->{'content'});

    my ($geo, $ward, $council, $constituency);
    $geo  = Address::PostCode::UK::Place::Geo->new($contents->{'geo'})
        if (exists $contents->{'geo'});
    $ward = Address::PostCode::UK::Place::Ward->new($contents->{'administrative'}->{'ward'})
        if (exists $contents->{'administrative'}->{'ward'});
    $council = Address::PostCode::UK::Place::Council->new($contents->{'administrative'}->{'council'})
        if (exists $contents->{'administrative'}->{'council'});
    $constituency = Address::PostCode::UK::Place::Constituency->new($contents->{'administrative'}->{'constituency'})
        if (exists $contents->{'administrative'}->{'constituency'});

    return Address::PostCode::UK::Place->new(
        'geo' => $geo, 'ward' => $ward, 'council' => $council, 'constituency' => $constituency);
}

=head2 nearest()

It returns ref to a list of objects of type L<Address::PostCode::UK::Location> on
success. The required parameters are the post code and distance in miles.

    use strict; use warnings;
    use Address::PostCode::UK;

    my $address   = Address::PostCode::UK->new;
    my $post_code = 'Post Code';
    my $distance  = 1;
    my $locations = $address->nearest($post_code, $distance);

    print "Location Latitude : ", $locations->[0]->lat, "\n";
    print "Location Longitude: ", $locations->[0]->lng, "\n";

=cut

sub nearest {
    my ($self, $post_code, $distance) = @_;

    die "ERROR: Missing required param 'post code'.\n" unless defined $post_code;
    die "ERROR: Missing required param 'distance'.\n"  unless defined $distance;

    die "ERROR: Invalid format for UK post code [$post_code].\n" unless ($post_code =~ /[A-Z]{1,2}[0-9][0-9A-Z]?\s?[0-9][A-Z]{2}/gi);
    die "ERROR: Invalid distance [$distance].\n" unless ($distance =~ /^[\d+]$/);

    $post_code =~ s/\s//g;
    my $url      = sprintf("%s/postcode/nearest?postcode=%s&miles=%d&format=json", $BASE_URL, $post_code, $distance);
    my $response = $self->get($url);
    my $contents = from_json($response->{'content'});

    my $locations = [];
    foreach (@$contents) {
        push @$locations, Address::PostCode::UK::Location->new($_);
    }

    return $locations;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Address-PostCode-UK>

=head1 BUGS

Please report any bugs or feature requests to C<bug-address-postcode-uk at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Address-PostCode-UK>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Address::PostCode::UK

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Address-PostCode-UK>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Address-PostCode-UK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Address-PostCode-UK>

=item * Search CPAN

L<http://search.cpan.org/dist/Address-PostCode-UK/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
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

1; # End of Address::PostCode::UK
