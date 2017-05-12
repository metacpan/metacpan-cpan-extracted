package Amazon::MWS::XML::Response::OrderReport;

use utf8;
use strict;
use warnings;
use DateTime;
use DateTime::Format::ISO8601;
use Data::Dumper;
use Amazon::MWS::XML::Response::OrderReport::Item;
use Amazon::MWS::XML::Address;
use Moo;
use MooX::Types::MooseLike::Base qw(HashRef ArrayRef Str Int);
use namespace::clean;

=head1 NAME

Amazon::MWS::XML::Response::OrderReport

=head1 DESCRIPTION

Class to handle the xml structures returned by the C<GetReport> with type
C<OrderReport>.

The constructor is meant to be called by L<Amazon::MWS::Uploader> when
C<get_order_reports> is called. A list of objects of this class will be
returned.

=head1 SYNOPSIS

 my $order = Amazon::MWS::XML::Response::OrderReport->new(struct => $struct);
 my @items = $order->items;

=head1 ACCESSORS

=head2 struct

Mandatory. Must be an hashref.

=head2 order_number

Our order ID. Read-write.

=head2 shipping_address

An L<Amazon::MWS::XML::Address> instance, lazily built.

=head2 billing_address

An L<Amazon::MWS::XML::Address> instance, lazily built.

=cut

has struct => (is => 'ro', isa => HashRef, required => 1);
has order_number => (is => 'rw');
has shipping_address => (is => 'lazy');
has billing_address => (is => 'lazy');

sub _build_shipping_address {
    my $self = shift;
    if (my $data = $self->struct->{FulfillmentData}) {
        # unclear if we want to check the FulfillmentMethod
        if (my $address = $data->{Address}) {
            return Amazon::MWS::XML::Address->new(%$address);
        }
    }
    return undef;
}

sub _build_billing_address {
    my $self = shift;
    if (my $data = $self->struct->{BillingData}) {
        if (my $address = $data->{Address}) {
            return Amazon::MWS::XML::Address->new(%$address);
        }
    }
    return undef;
}

has _items_ref => (is => 'lazy');

sub _build__items_ref {
    my $self = shift;
    my @items;
    if (my $list = $self->struct->{Item}) {
        foreach my $item (@$list) {
            my $obj = Amazon::MWS::XML::Response::OrderReport::Item->new(%$item);
            push @items, $obj;
        }
    }
    return \@items;
}

=head1 METHODS

=head2 amazon_order_number

=head2 email

The buyer email.

=head2 order_date

The date when the order processing was complete or when the order was
placed as a L<DateTime> object.

=head2 items

Return a list of L<Amazon::MWS::XML::Response::OrderReport::Item>,
which acts (more or less) like L<Amazon::MWS::XML::OrderlineItem>.

=cut

sub amazon_order_number {
    return shift->struct->{AmazonOrderID};
}

sub email {
    my $self = shift;
    if (my $billing = $self->struct->{BillingData}) {
        if (exists $billing->{BuyerEmailAddress}) {
            return $billing->{BuyerEmailAddress};
        }
    };
    return;
}


# OrderDate The date the order was placed
# OrderPostedDate The date the buyer's credit card was charged and order processing was completed

sub order_date {
    my $self = shift;
    my $struct = $self->struct;
    # maybe this would need a different method, but we don't know what
    # to do with it anyway.
    my $date = $struct->{OrderPostedDate} || $struct->{OrderDate};
    return DateTime::Format::ISO8601->parse_datetime($date);
}

sub items {
    return @{ shift->_items_ref };
}

=head2 as_ack_order_hashref

Return a structure suitable create an the acknowledge feed.

=cut

sub as_ack_order_hashref {
    my $self = shift;
    my @items;
    foreach my $item ($self->items) {
        push @items, $item->as_ack_orderline_item_hashref;
    }
    return {
            AmazonOrderID => $self->amazon_order_number,
            MerchantOrderID => $self->order_number,
            Item => \@items,
           };
}

=head2 can_be_imported

Compatibility method with L<Amazon::MWS::XML::Order>. Given that this
is a report, the order can be imported right away without checking.
LFW.

=head2 order_status

Compatibility method.

=cut

sub can_be_imported {
    # why not?
    return 1;
}

sub order_status {
    return 'Report';
}

=head2 currency

We check the items currency.

=head2 shipping_cost

The sum of the shipping of all the items (including taxes from the
Amazon point of view).

=head2 subtotal

The sum of the items' subtotal

=head2 total_cost

The grand total

=head2 total_amazon_fee

The total of the amazon fees.

=head2 number_of_items

Total number of items.

=cut

has currency => (is => 'lazy', isa => Str);

sub _build_currency {
    my $self = shift;
    my $currency;
    foreach my $item ($self->items) {
        my $item_currency = $item->currency;
        die "Missign currency on item?" . Dumper($item) unless $item_currency;
        if ($currency) {
            if ($currency ne $item_currency) {
                die "Currency mismatch in the same order, should happen" . Dumper($self);
            }
        }
        else {
            $currency = $item_currency;
        }
    }
    return $currency;
}

has shipping_cost => (is => 'lazy', isa => Str);

sub _build_shipping_cost {
    return shift->_calc_sum_item_method('shipping');
}

has subtotal => (is => 'lazy', isa => Str);

sub _build_subtotal {
    return shift->_calc_sum_item_method('subtotal');
}

has total_cost => (is => 'lazy', isa => Str);

sub _build_total_cost {
    return shift->_calc_sum_item_method('total_price');
}

has total_amazon_fee => (is => 'lazy', isa => Str);

sub _build_total_amazon_fee {
    return shift->_calc_sum_item_method('amazon_fee');
}

sub _calc_sum_item_method {
    my ($self, $method) = @_;
    die unless $method;
    my $cost = 0;
    foreach my $item ($self->items) {
        $cost += $item->$method;
    }
    return sprintf ('%.2f', $cost);
}

has number_of_items => (is => 'lazy', isa => Int);

sub _build_number_of_items {
    my $self = shift;
    my $count = 0;
    foreach my $item ($self->items) {
        $count += $item->quantity;
    }
    return $count;
}

1;
