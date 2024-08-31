package Business::TrueLayer::Payment;

=head1 NAME

Business::TrueLayer::Payment - class representing a payment
as used in the TrueLayer v3 API.

Business::TrueLayer::Payment uses the Status role.

=head1 SYNOPSIS

    my $Payment = Business::TrueLayer::Payment->new(
        amount_in_minor => ...
    );

=cut

use strict;
use warnings;
use feature qw/ signatures postderef /;

use Moose;
extends 'Business::TrueLayer::Request';
with 'Business::TrueLayer::Role::Status';
use Moose::Util::TypeConstraints;
no warnings qw/ experimental::signatures experimental::postderef /;

with 'Business::TrueLayer::Types::User';
use Business::TrueLayer::Payment::Method;

use namespace::autoclean;

=head1 ATTRIBUTES

=over

=item id (Str)

=item resource_token (Str)

=item amount_in_minor (Int)

=item currency (Str)

=item payment_method

A L<Business::TrueLayer::Payment::Method> object. Hash refs will be coerced.


=item user

A L<Business::TrueLayer::User> object. Hash refs will be coerced.

=back

=cut

has [ qw/ status id resource_token metadata related_products / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
);

has [ qw/ currency / ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has [ qw/
    amount_in_minor
/ ] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

coerce 'Business::TrueLayer::Payment::Method'
    => from 'HashRef'
    => via {
        Business::TrueLayer::Payment::Method->new( %{ $_ } );
    }
;

has payment_method => (
    is       => 'ro',
    isa      => 'Business::TrueLayer::Payment::Method',
    coerce   => 1,
    required => 1,
);

=head1 METHODS

=head2 hosted_payment_page_link

Returns the TrueLayer hosted payment page URI, allowing you to redirect
a user to it to complete the payment.

    my $link = $Payment->hosted_payment_page_link(
        $return_uri, # must be one of those set in the TrueLayer console
    );

It only makes sense to do this after you have created a payment, so the
object will check some of its attributes and throw an exception if it is
not in the correct state.

=cut

sub hosted_payment_page_link (
    $self,
    $return_uri = undef
) {
    ( $self->id && $self->resource_token )
        || confess( "Payment lacks an id and resource_token" );

    return 'https://' . $self->payment_host
        . '/payments#'
        . 'payment_id=' . $self->id
        . '&resource_token=' . $self->resource_token
        . ( $return_uri ? ( '&return_uri=' . $return_uri ) : '' )
}

=head1 SEE ALSO

L<Business::TrueLayer::Payment::Method>

L<Business::TrueLayer::User>

L<Business::TrueLayer::Role::Status>

=cut

1;
