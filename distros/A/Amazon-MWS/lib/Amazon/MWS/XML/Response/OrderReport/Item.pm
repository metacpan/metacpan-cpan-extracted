package Amazon::MWS::XML::Response::OrderReport::Item;

use utf8;
use strict;
use warnings;
use MooX::Types::MooseLike::Base qw(Int Str HashRef);
use namespace::clean;
use Moo;

=head1 NAME

Amazon::MWS::XML::Response::OrderReport::Item

=head1 DESCRIPTION

Class which handles the xml structures reported by the C<GetReport>
with type C<OrderReport> in the C<Item> slot (the orderline's items).

The class should act like L<Amazon::MWS::XML::OrderlineItem> when
applicable.

=head1 ACCESSORS

They correspond to the documented structure. They should not be called
directly, though, prefer the methods above.

=over 4

=item Title              

=item Quantity           

=item SKU                

=item ItemPrice          

=item ProductTaxCode     

=item AmazonOrderItemCode

=item ItemFees           

=back

=cut

has Title               => (is => 'ro', isa => Str);
has Quantity            => (is => 'ro', isa => Int);
has SKU                 => (is => 'ro', isa => Str);
has ItemPrice           => (is => 'ro', isa => HashRef);
has ProductTaxCode      => (is => 'ro', isa => Str);
has AmazonOrderItemCode => (is => 'ro', isa => Str);
has ItemFees            => (is => 'ro', isa => HashRef);

=head2 merchant_order_item

Our id (read-write).

=head1 METHODS AND SHORTCUTS

All the methods are read only.

=over 4

=item total_price

The grand total for the item in the given quantity.

=item subtotal

If there are taxes in the amazon price component, including taxes, but
without shipping.

=item shipping

The shipping cost including taxes.

=item price

Individual price of a single item, including taxes (from the Amazon
point of view): subtotal / quantity.

=item shipping_netto

The shipping without the taxes (from the Amazon point of view).

=item price_netto

The price without taxes (from the Amazon point of view) for the
quantity.

=item item_tax

=item shipping_tax

=item amazon_fee

The price paid to amazon for the given item. It could be a negative
number.

=item quantity

=item currency

=item name

=item sku

=item amazon_order_item

=item as_ack_orderline_item_hashref

=back

=cut

has merchant_order_item => (is => 'rw',
                            default => sub { '' });

has total_price => (is => 'lazy');
has subtotal => (is => 'lazy');
has price => (is => 'lazy');
has shipping => (is => 'lazy');
has shipping_netto => (is => 'lazy');
has price_netto => (is => 'lazy');
has item_tax => (is => 'lazy');
has shipping_tax => (is => 'lazy');
has amazon_fee => (is => 'lazy');

sub _build_amazon_fee {
    my $self = shift;
    my $toll = 0;
    if (my $fees = $self->ItemFees->{Fee}) {
        foreach my $fee (@$fees) {
            $toll += $fee->{Amount}->{_} || 0;
        }
    }
    return sprintf('%.2f', $toll);
}

sub _build_shipping_netto {
    return shift->_get_price_component('Shipping');
}

sub _build_price_netto {
    return shift->_get_price_component('Principal');
}

sub _build_item_tax {
    return shift->_get_price_component('Tax');
}

sub _build_shipping_tax {
    return shift->_get_price_component('ShippingTax');
}

sub _build_price {
    my $self = shift;
    return sprintf('%.2f', $self->subtotal / $self->quantity);
}

sub _build_shipping {
    my $self = shift;
    return sprintf('%.2f', $self->shipping_netto + $self->shipping_tax);
}

sub _build_subtotal {
    my $self = shift;
    return sprintf('%.2f', $self->price_netto + $self->item_tax);
}


sub _build_total_price {
    my $self = shift;
    my $amount = 0;
    if (my $components = $self->ItemPrice->{Component}) {
        foreach my $comp (@$components) {
            $amount += $comp->{Amount}->{_} || 0;
        }
    }
    my $total_price = sprintf('%.2f', $amount);
    my $check = $self->price_netto + $self->item_tax + $self->shipping_netto + $self->shipping_tax;
    if ($total_price eq sprintf('%.2f', $check)) {
        return $total_price;
    }
    else {
        die "There is a bug in the price routine!";
    }
}

has currency => (is => 'lazy');

sub _build_currency {
    my $self = shift;
    my $currency;
    if (my $components = $self->ItemPrice->{Component}) {
        foreach my $comp (@$components) {
            last if $currency = $comp->{Amount}->{currency};
        }
    }
    return $currency;
}

sub _get_price_component {
    my ($self, $type) = @_;
    die unless $type;
    my $amount = 0;
    if (my $components = $self->ItemPrice->{Component}) {
        foreach my $comp (@$components) {
            if ($type eq $comp->{Type}) {
                $amount += $comp->{Amount}->{_};
            }
        }
    }
    return sprintf('%.2f', $amount);
}


sub sku {
    return shift->SKU;
}

sub quantity {
    return shift->Quantity;
}

sub name {
    return shift->Title;
}

sub amazon_order_item {
    return shift->AmazonOrderItemCode;
}

sub as_ack_orderline_item_hashref {
    my $self = shift;
    return {
            AmazonOrderItemCode => $self->amazon_order_item,
            MerchantOrderItemID => $self->merchant_order_item,
           };

}


1;
