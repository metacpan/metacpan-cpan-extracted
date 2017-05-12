package Business::CPI::Role::Buyer;
# ABSTRACT: Information about the client
use Moo::Role;
use Locale::Country ();
use Business::CPI::Util::Types qw/Country/;
use Types::Standard qw/Str/;
use Type::EmailAddress qw/EmailAddress/;

our $VERSION = '0.924'; # VERSION

has email => (
    isa => EmailAddress,
    is => 'ro',
);

has name => (
    isa => Str,
    is => 'ro',
);

has address_line1      => ( is => 'lazy' );
has address_line2      => ( is => 'lazy' );

has address_street     => ( is => 'ro', required => 0 );
has address_number     => ( is => 'ro', required => 0 );
has address_district   => ( is => 'ro', required => 0 );
has address_complement => ( is => 'ro', required => 0 );
has address_zip_code   => ( is => 'ro', required => 0 );
has address_city       => ( is => 'ro', required => 0 );
has address_state      => ( is => 'ro', required => 0 );
has address_country    => (
    is => 'ro',
    required => 0,
    isa => Country,
    coerce => Country->coercion,
);

sub _build_address_line1 {
    my $self = shift;

    my $street = $self->address_street || '';
    my $number = $self->address_number || '';

    return unless $street;

    return $street unless $number;

    return "$street, $number";
}

sub _build_address_line2 {
    my $self = shift;

    my $distr = $self->address_district   || '';
    my $compl = $self->address_complement || '';

    return $distr if ($distr && !$compl);
    return $compl if (!$distr && $compl);

    return "$distr - $compl";
}

# TODO
# add all the other attrs.
#
# try and find the common ones between PagSeguro / PayPal / etc, and keep them
# here. Specific attrs can stay in Business::CPI::${gateway}::Buyer

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Role::Buyer - Information about the client

=head1 VERSION

version 0.924

=head1 DESCRIPTION

This role holds information about the buyer in a shopping cart. The address
attributes are available so that if shipping is required, the buyer's address
will be passed to the gateway (if the attributes were set).

=head1 ATTRIBUTES

=head2 email

Buyer's e-mail, which usually is their unique identifier in the gateway.

=head2 name

Buyer's name.

=head2 address_line1

=head2 address_line2

Some gateways (such as PayPal) do not define the street address as specific
separate fields (such as Street, Number, District, etc). Instead, they only
accept two address lines. For our purposes, we define a lazy builder for these
attributes in case they are not directly set, using the specific fields
mentioned above.

=head2 address_street

Street name for shipping.

=head2 address_number

Address number for shipping.

=head2 address_district

District name.

=head2 address_complement

If any extra information is required to find the address set this field.

=head2 address_zip_code

Postal code.

=head2 address_city

City.

=head2 address_state

State.

=head2 address_country

L<Locale::Country> code for the country. You can set using the ISO 3166-1
two-letter code, or the full name in English. It will coerce it and store the
ISO 3166-1 two-letter code.

=head1 NOTE

This role will soon be ported to use L<Business::CPI::Role::Account>, or
deprecated. So beware of backcompatibility issues. In particular, all
attributes prefixed with C<address_*> will lose the prefix and be set using
L<Business::CPI::Role::Account::Address>.

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
