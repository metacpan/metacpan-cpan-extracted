package Bing::Search::Result::Phonebook;
use Moose;
extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::UrlType';
   
with qw(
   Bing::Search::Role::Result::Business
   Bing::Search::Role::Result::Address
   Bing::Search::Role::Result::UserRating
   Bing::Search::Role::Result::BusinessUrl
   Bing::Search::Role::Result::City
   Bing::Search::Role::Result::CountryOrRegion
   Bing::Search::Role::Result::DisplayUrl
   Bing::Search::Role::Result::Latitude
   Bing::Search::Role::Result::Longitude
   Bing::Search::Role::Result::PhoneNumber
   Bing::Search::Role::Result::PostalCode
   Bing::Search::Role::Result::ReviewCount
   Bing::Search::Role::Result::StateOrProvince
   Bing::Search::Role::Result::Title
   Bing::Search::Role::Result::UniqueId
   Bing::Search::Role::Result::Url
);

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::Phonebook - Phonebook lookup result

=head1 METHODS

=over 3

=item C<Business>

The name of the business, if any.

=item C<Address>

The street address of the business, excluding a city, state, or postal code.

=item C<UserRating>

A rating from 1 to 10 provided by users.

=item C<BusinessUrl>

A L<URI> object representing the business' URL.

=item C<City>

The city the business is located in.

=item C<CountryOrRegion>

The country (or region) of the business.

=item C<DisplayUrl>

A L<URI> The modified-for-display representation of the business URL.

=item C<Latitude>

The latitude of the business location.

=item C<Longitude>

Astoundingly, the longitude of the business' location.

=item C<PhoneNumber>

The business phone number.

=item C<PostalCode>

Postal code.  In the US, we call it a Zip code.

=item C<ReviewCount>

The number of reviews this business has.

=item C<StateOrProvince>

The state or provice where the business is located.

=item C<Title>

The title of the listing, as presented in the White or Yellow pages.

=item C<UniqueId>

A unique identifier, useful for providing to L<Bing::Search::Source::Phonebook>'s C<LocId>
method.

=item C<Url>

A L<URI> object representing a link to the business.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it 
under the same terms as Perl itself.
