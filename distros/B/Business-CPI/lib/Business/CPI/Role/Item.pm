package Business::CPI::Role::Item;
# ABSTRACT: Role to represent a product in the cart
use Moo::Role;
use Business::CPI::Util::Types qw/Money/;
use Types::Standard qw/Str Int Num/;

our $VERSION = '0.924'; # VERSION

has id => (
    coerce   => Str->coercion,
    isa      => Str,
    is       => 'ro',
    required => 1,
);

has price => (
    coerce   => Money->coercion,
    isa      => Money,
    is       => 'ro',
    required => 1,
);

has weight => (
    coerce => Num->coercion,
    isa    => Num,
    is     => 'ro',
);

has shipping => (
    coerce    => Money->coercion,
    isa       => Money,
    is        => 'ro',
    predicate => 1,
);

has shipping_additional => (
    coerce    => Money->coercion,
    isa       => Money,
    is        => 'ro',
    predicate => 1,
);

has description => (
    coerce => Str->coercion,
    isa    => Str,
    is     => 'ro',
);

has quantity => (
    coercion => Int->coercion,
    isa     => Int,
    is      => 'ro',
    default => sub { 1 },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::CPI::Role::Item - Role to represent a product in the cart

=head1 VERSION

version 0.924

=head1 DESCRIPTION

This class holds information about the products in a shopping cart.

=head1 ATTRIBUTES

=head2 id

B<MANDATORY> - Unique identifier for this product in your application.

=head2 description

A longer description of the product, or just the name, if the gateway doesn't
differentiate between name and description.

=head2 price

B<MANDATORY> - The price (in the chosen currency; see
L<Business::CPI::Gateway::Base/currency>) of one item. This will be multiplied
by the quantity.

=head2 quantity

How many of this product is being bought? Defaults to 1.

=head2 shipping

The shipping cost (in the chosen currency, same as in the price above) for this
particular item.

=head2 shipping_additional

The cost of each additional quantity of this item. For example, if the quantity
is 5, the L</shipping> attribute is set to 1.50, and this attribute is set to
0.50, then the total shipping cost will be 1*1.50 + 4*0.50 = 3.50. Note that
not all gateways implement this. In PayPal, for instance, it's called
shipping2.

=head2 weight

The weight of this item. If you define the L</shipping>, this will probably be
ignored by the gateway.

=head1 METHODS

=head2 has_shipping

Predicate for shipping attribute.

=head2 has_shipping_additional

Predicate for shipping_additional attribute.

=head1 AUTHOR

André Walker <andre@andrewalker.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by André Walker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
