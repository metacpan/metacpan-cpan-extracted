package Address::PostCode::Australia;

$Address::PostCode::Australia::VERSION   = '0.12';
$Address::PostCode::Australia::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Address::PostCode::Australia - Interface to the Australia PostCode.

=head1 VERSION

Version 0.12

=cut

use 5.006;
use JSON;
use Data::Dumper;
use Address::PostCode::UserAgent;
use Address::PostCode::Australia::Place;
use Address::PostCode::Australia::Params qw(validate);

use Moo;
use namespace::autoclean;
extends 'Address::PostCode::UserAgent';

our $BASE_URL = 'https://auspost.com.au/api/postcode/search.json';
has 'auth_key' => (is => 'ro', required => 1);

=head1 DESCRIPTION

Interface to the API provided by L<AusPost|http://auspost.com.au>.

To use the API, you would need auth key, which you can get it L<here|https://developers.auspost.com.au/apis/pacpcs-registration>.

More details can be found L<here|https://developers.auspost.com.au/apis/pac/reference/postcode-search>.

=head1 SYNOPSIS

    use strict; use warnings;
    use Address::PostCode::Australia;

    my $auth_key = 'Your Auth Key';
    my $postcode = 3002;
    my $address  = Address::PostCode::Australia->new({ auth_key => $auth_key });
    my $places   = $address->details({ postcode => $postcode });

    print "Location: ", $places->[0]->location, "\n";
    print "State   : ", $places->[0]->state,    "\n";

=head1 CONSTRUCTOR

The only parameter requires is the auth key.

    use strict; use warnings;
    use Address::PostCode::Australia;

    my $auth_key = 'Your Auth Key';
    my $address  = Address::PostCode::Australia->new({ auth_key => $auth_key });

=head2 details(\%params)

It returns ref  to list of objects of type L<Address::PostCode::Australia::Place>
on success. The parameters requires are list below:

    +----------+----------------------------------------------------------------+
    | Name     | Description                                                    |
    +----------+----------------------------------------------------------------+
    | postcode | Mandatory parameter unless location is passed.                 |
    |          |                                                                |
    | location | Mandatory paramerer unless postcode is passed.                 |
    |          |                                                                |
    | state    | Optional parameter.                                            |
    +----------+----------------------------------------------------------------+

=cut

sub details {
    my ($self, $params) = @_;

    my $keys     = { postcode => 0, location => 0, state => 0 };
    my $url      = _get_url($keys, $params);
    my $response = $self->get($url, { 'auth-key' => $self->auth_key });
    my $contents = from_json($response->{'content'});

    my $places = [];
    if (ref($contents->{'localities'}->{'locality'}) eq 'ARRAY') {
        foreach my $location (@{$contents->{'localities'}->{'locality'}}) {
            push @$places, Address::PostCode::Australia::Place->new($location);
        }
    }
    else {
        push @$places, Address::PostCode::Australia::Place->new($contents->{'localities'}->{'locality'});
    }

    return $places;
}

#
#
# PRIVATE METHODS

sub _get_url {
    my ($keys, $values) = @_;

    validate($keys, $values);

    my $url = $BASE_URL;
    if (exists $values->{'postcode'}) {
        $url .= sprintf("?q=%d", $values->{'postcode'});
    }
    elsif (exists $values->{'location'}) {
        $url .= sprintf("?q=%s", $values->{'location'});
    }
    else {
        die "ERROR: Missing required key postcode/location.\n";
    }

    if (exists $values->{'state'}) {
        $url .= sprintf("&state=%s", $values->{'state'});
    }

    return $url;
}

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

    perldoc Address::PostCode::Australia

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

1; # End of Address::PostCode::Australia
