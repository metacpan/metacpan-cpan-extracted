package Business::CyberSource::RequestPart::ShipTo;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.010008'; # VERSION

use Moose;
use MooseX::RemoteHelper;
extends 'Business::CyberSource::MessagePart';
with 'MooseX::RemoteHelper::CompositeSerialization';
use MooseX::Aliases;

use MooseX::Types::Common::String qw( NonEmptySimpleStr );

use MooseX::Types::CyberSource qw(
  CountryCode
  _VarcharTen
  _VarcharFifteen
  _VarcharTwenty
  _VarcharFifty
  _VarcharSixty
  ShippingMethod
);

use Moose::Util 'throw_exception';
use Moose::Util::TypeConstraints;

sub BUILD {
    my $self = shift;
    if ( $self->country eq 'US' or $self->country eq 'CA' ) {
        throw_exception(
            AttributeIsRequired => attribute_name => 'city',
            class_name          => __PACKAGE__,
            message             => 'Attribute (' . 'city'
              . ') is required for US or Canada',
        ) unless $self->has_city;

        throw_exception(
            AttributeIsRequired => attribute_name => 'postal_code',
            class_name          => __PACKAGE__,
            message             => 'Attribute ('
              . 'postal_code'
              . ') is required for US or Canada',
        ) unless $self->has_postal_code;

        throw_exception(
            AttributeIsRequired => attribute_name => 'state',
            class_name          => __PACKAGE__,
            message             => 'Attribute (' . 'state'
              . ') is required for US or Canada',
        ) unless $self->has_state;
    }

    return;
}

has first_name => (
    remote_name => 'firstName',
    is          => 'ro',
    isa         => _VarcharSixty,
);

has last_name => (
    remote_name => 'lastName',
    is          => 'ro',
    isa         => _VarcharSixty,
);

has street1 => (
    remote_name => 'street1',
    required    => 1,
    is          => 'ro',
    isa         => _VarcharSixty,
);

has street2 => (
    remote_name => 'street2',
    isa         => _VarcharSixty,
    is          => 'ro',
);

has city => (
    remote_name => 'city',
    isa         => _VarcharFifty,
    is          => 'ro',
    predicate   => 'has_city',
);

has state => (
    remote_name => 'state',
    isa         => subtype( NonEmptySimpleStr, where { length $_ == 2 } ),
    is          => 'ro',
    predicate   => 'has_state',
);

has country => (
    remote_name => 'country',
    required    => 1,
    coerce      => 1,
    is          => 'ro',
    isa         => CountryCode,
);

has postal_code => (
    remote_name => 'postalCode',
    isa         => _VarcharTen,
    is          => 'ro',
    predicate   => 'has_postal_code',
);

has phone_number => (
    remote_name => 'phoneNumber',
    isa         => _VarcharFifteen,
    is          => 'ro',
);

has shipping_method => (
    remote_name => 'shippingMethod',
    isa         => ShippingMethod,
    is          => 'ro',
);

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: ShipTo information

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CyberSource::RequestPart::ShipTo - ShipTo information

=head1 VERSION

version 0.010008

=head1 EXTENDS

L<Business::CyberSource::MessagePart>

=head1 ATTRIBUTES

=head2 first_name

=head2 last_name

=head2 city

=head2 state

=head2 postal_code

=head2 street1

=head2 street2

=head2 country

=head2 phone_number

=head2 shipping_method

=for Pod::Coverage BUILD

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hostgator/business-cybersource/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Caleb Cushing <xenoterracide@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
