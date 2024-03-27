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

  print $site->tldn;   # co.uk
  print $site->domain; # amazon.co.uk

=cut

use Feature::Compat::Class;

use feature 'signatures';
no warnings 'experimental::signatures';

class Amazon::Site {
  field $code :param;
  field $country :param;
  field $tldn :param;
  field $currency :param;
  field $sort :param;

=head1 METHODS

=head2 new

Creates a new Amazon::Site object.

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
}

1;
