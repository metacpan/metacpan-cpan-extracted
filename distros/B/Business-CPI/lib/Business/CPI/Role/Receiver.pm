package Business::CPI::Role::Receiver;
# ABSTRACT: The person receiving the money
use utf8;
use Moo::Role;
use Business::CPI::Util::Types qw/Money/;
use Types::Standard qw/Bool/;

our $VERSION = '0.924'; # VERSION

has _gateway => (
    is       => 'rw',
    required => 1,
);

has gateway_fee => (
    is       => 'rwp',
    required => 0,
);

has account => (
    is       => 'rw',
    required => 1,
);

has is_primary => (
    is      => 'rw',
    isa     => Bool,
    default => sub { 0 },
);

has pay_gateway_fee => (
    is      => 'rw',
    isa     => Bool,
);

has fixed_amount => (
    is     => 'rw',
    isa    => Money,
    coerce => Money->coercion,
);

has percent_amount => (
    is     => 'rw',
    coerce => sub { 0 + $_[0] }
);

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    my $args = $self->$orig(@_);

    # let it die elsewhere
    return $args unless $args->{_gateway};

    if (my $id = delete $args->{gateway_id}) {
        $args->{account} = $args->{_gateway}->new_account({ gateway_id => $id });
    }

    return $args;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Role::Receiver - The person receiving the money

=head1 VERSION

version 0.924

=head1 SYNOPSIS

    # when building a cart
    my $cart = $cpi->new_cart({
        ...
        receivers => [
            {
                # alias for account.gateway_id
                gateway_id      => 2313,

                fixed_amount    => 50.00,
                percent_amount  => 5.00,
                pay_gateway_fee => 1,
            },
            {
                account         => $cpi->account_class->new({ ... }),
                fixed_amount    => 250.00,
                pay_gateway_fee => 0,
            },
        ],
    });

=head1 DESCRIPTION

This role is meant to be included by the class which represents Receivers in
the gateway, such as L<Business::CPI::Base::Receiver>. A Receiver is an account
in the gateway which is going to receive a percentage or fixed amount of the
payment being made.

=head1 ATTRIBUTES

=head2 account

B<MANDATORY>. A representation of the user account in the gateway. See
L<< the Account role | Business::CPI::Role::Account >> for details.

=head2 gateway_id (shortcut)

This is not really an attribute, but a shortcut to the
L<< gateway_id | Business::CPI::Role::Account/gateway_id >>
attribute in the Account. You should provide either a gateway_id or an Account
object (for the account attribute) when instantiating a Receiver object, but
never both.

=head2 is_primary

Boolean. Is this the main account receiving the money, or secondary? Defaults
to false, i.e., it's a secondary receiver.

=head2 pay_gateway_fee

Boolean attribute to define whether this receiver should be the one paying the
gateway fees. Similar to the "feesPayer" parameter in Adaptive Payments in
PayPal.

=head2 gateway_fee

The fee amount this receiver was charged by the gateway.

=head2 fixed_amount

The value, in the chosen currency, this receiver is getting of the payment.

=head2 percentual_amount

The percentage of the payment that this receiver is getting.

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
