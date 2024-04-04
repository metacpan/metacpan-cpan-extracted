package Amazon::Site;

=head1 NAME

Amazon::Site - A class to represent an Amazon site

=head1 SYNOPSIS

  use Amazon::Site;

  my $site = Amazon::Site->new(
    code     => 'UK',
    country  => 'United Kingdom',
    tldn     => 'co.uk',
    currency => 'GBP',
    sort     => 1,
  );

  say $site->tldn;   # co.uk
  say $site->domain; # amazon.co.uk
  say $site->asin_url('XXXXXXX'); # https://amazon.co.uk/dp/XXXXXXX

=cut

use strict;
use warnings;

use Feature::Compat::Class;

use feature 'signatures';
no warnings 'experimental::signatures';

class Amazon::Site {
  field $code :param;
  field $country :param;
  field $tldn :param;
  field $currency :param;
  field $sort :param;
  field $assoc_code :param = '';

=head1 METHODS

=head2 new

Creates a new Amazon::Site object.

=head3 Parameters

=over 4

=item code

The two-letter country code.

=item country

The country name.

=item tldn

The top-level domain name.

=item currency

The currency code.

=item sort

The sort order. Used by Amazon::Sites to sort the sites.

=item assoc_code

The optional Amazon Associate code for this site.

=back

=head2 code

Returns the two-letter country code.

=cut

  method code     { return $code }

=head2 country

Returns the country name.

=cut
  method country  { return $country }

=head2 tldn

Returns the top-level domain name.

=cut

  method tldn     { return $tldn }

=head2 domain

Return the whole domain name.

=cut

  method domain   { return "amazon.$tldn" }

=head2 currency

Returns the currency code.

=cut

  method currency { return $currency }

=head2 sort

Returns the sort order.

=cut

  method sort     { return $sort }

=head2 assoc_code

Returns the Amazon Associate code for this site.

=cut

  method assoc_code { return $assoc_code }

=head2 asin_url($asin)

Returns the URL for the ASIN on this site.

If you've defined an associate code for this site, it will be included in the URL.

=cut

  method asin_url($asin) {
    my $url = 'https://' . $self->domain . "/dp/$asin";
    $url .= "?tag=$assoc_code" if $assoc_code;

    return $url;
  }
}

=head1 COPYRIGHT

Copyright 2024, Dave Cross. All rights reserved.

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it under
the terms of either:

=over 4

=item * the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version, or

=item * the Artistic License version 2.0.

=back

=cut

1;
