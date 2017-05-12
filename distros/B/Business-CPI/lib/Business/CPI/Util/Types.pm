package Business::CPI::Util::Types;
# ABSTRACT: Basic types for Business::CPI
use warnings;
use strict;
use Scalar::Util qw/looks_like_number blessed/;
use List::Util qw/first/;
use Locale::Country ();
use Email::Valid ();

use Type::Utils -all;
use Types::Standard qw/Str/;
use Type::Library
  -base,
  -declare => qw(
     DateTime Country Money PhoneNumber
     ExceptionType UserAgent HTTPResponse
  );

our $VERSION = '0.924'; # VERSION

enum ExceptionType, [qw.
    invalid_data
    incomplete_data
    invalid_request
    resource_not_found
    unauthorized
    unauthenticated
    duplicate_transaction
    rejected
    gateway_unavailable
    gateway_error
    unknown
.];

class_type DateTime, { class => "DateTime" };

class_type UserAgent, { class => 'LWP::UserAgent' };
class_type HTTPResponse, { class => 'HTTP::Response' };

my @CountryCodes = Locale::Country::all_country_codes();

declare Country, as Str,
  where {
    my $re = qr/^$_$/;
    return !! first { m|$re| } @CountryCodes;
  };

coerce Country,
  from Str,
  via {
    my $country = lc $_;
    my $re = qr/^$country$/;
    if (first { m|$re| } @CountryCodes) {
        return $country;
    }
    return Locale::Country::country2code($country) || '';
  };

declare Money,
  as Str,
  where { m|^ \-? [\d\,]+ \. \d{2} $|x };

coerce Money,
  from Str,
  via {
    my $r = looks_like_number($_) ? $_ : 0;
    return sprintf( "%.2f", 0+$r);
  };

declare PhoneNumber,
  as Str,
  where { m|^ \+? \d+ $|x };

coerce PhoneNumber,
  from Str,
  via {
    # avoid warnings
    return '' unless defined $_;

    # force it to stringify
    my $r = "$_";

    # Remove anything that is not alphanumerical or "+"
    # Note that we are using \w instead of \d here, because this sub is used
    # only for coersion. We don't want to remove letters from the phone number,
    # we want it to fail in the `is_valid_phone_number` routine.
    $r =~ s{[^\+\w]}{}g;

    return $r;
  };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Util::Types - Basic types for Business::CPI

=head1 VERSION

version 0.924

=head1 DESCRIPTION

Moo types for isa checks and coercions.

=head1 TYPES

=head2 Money

Most gateways require the money amount to be provided with two decimal places.
This method coerces the value into number, and then to a string as expected by
the gateways.

Examples:

=over

=item 5.55 becomes "5.55"

=item 5.5 becomes "5.50"

=item 5 becomes "5.00"

=back

=head2 PhoneNumber

Phone numbers should contain an optional + sign in the beginning, indicating
whether it contains the country code or not, and numbers only.
Non-alphanumerical characters are allowed, such as parenthesis and spaces, but
will be removed.

Examples of accepted phone numbers, and their coerced values are:

=over

=item "+55 11 12345678" becomes "+551112345678"

=item "+55 (11) 12345678" becomes "+551112345678"

=item "+551112345678" remains the same

=item "1234-5678" becomes "12345678"

=item "(11)1234-5678" becomes "1112345678"

=item "1234567890123" remains the same

=back

=head2 Country

Lowercase two-letter code for countries, according to ISO 3166-1. See:

L<http://www.iso.org/iso/country_codes>

The type is somewhat flexible, coercing to the alpha-2 code if the English name
is provided. But the recommended way is to set it as expected, the lowercase
alpha-2 code.

=head2 DateTime

A valid DateTime object. No coercions here.

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
