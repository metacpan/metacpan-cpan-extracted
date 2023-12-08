package Business::TrueLayer::Payment::Method;

=head1 NAME

Business::TrueLayer::Payment::Method - class representing a payment_method
as used in the TrueLayer v3 API.

=head1 SYNOPSIS

    my $PaymentMethod = Business::TrueLayer::Payment::Method->new(
        name => ...
    );

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
use MooseX::Aliases;
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures experimental::postderef /;

use Business::TrueLayer::Beneficiary;
use Business::TrueLayer::Provider;

use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item type (Str)

=item beneficiary

A L<Business::TrueLayer::Beneficiary> object. Hash refs will be coerced.

=item provider

A L<Business::TrueLayer::Provider> object. Hash refs will be coerced.

=back

=cut

has [ qw/ type / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

coerce 'Business::TrueLayer::Beneficiary'
    => from 'HashRef'
    => via {
        Business::TrueLayer::Beneficiary->new( %{ $_ } );
    }
;

has beneficiary => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Beneficiary',
    coerce   => 1,
    required => 1,
);

coerce 'Business::TrueLayer::Provider'
    => from 'HashRef'
    => via {
        Business::TrueLayer::Provider->new( %{ $_ } );
    }
;

has provider => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Provider',
    coerce   => 1,
    required => 0,
    alias    => 'provider_selection',
);

=head1 METHODS

None yet.

=head1 SEE ALSO

L<Business::TrueLayer::Beneficiary>

L<Business::TrueLayer::Provider>

=cut

1;
