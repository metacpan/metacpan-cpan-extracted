package Amazon::MWS::XML::ShippedOrder;

use strict;
use warnings;
use DateTime;
use DateTime::Format::ISO8601;
use Moo;

=head1 NAME

Amazon::MWS::XML::ShippedOrder

=head1 DESCRIPTION

Class to validate and generate a shipping confirmation feed. While
L<Amazon::MWS::XML::Order> is meant to be used to parse the response,
this is meant to produce the XML, generating a structure suitable to
satisfy the Amazon XSD.

=head1 SYNOPSIS

 my $shipped = Amazon::MWS::XML::ShippedOrder->new(....); # see below the accessors
 print Dumper($shipped->as_shipping_confirmation_hashref);

=head1 CONSTRUCTOR ARGUMENTS/ACCESSORS

=head2 amazon_order_id

=head2 merchant_order_id

This will be used if amazon_order_id is not provided. This should work
as long as the order aknowledgement sent it back, so Amazon is able to
pair it with its own id.

=head2 merchant_fulfillment_id

Optional and not used by Amazon

=head2 fulfillment_date

The date the item was actually shipped or picked up, depending on the
fulfillment method specified in the order.

A DateTime object is required. It will default to the current datetime
if not provided.

=head2 carrier

The "standard" carrier code or the carrier name. The module will try
to match it with the Amazon codes.

=head2 shipping_method

The shipping method for the carrier. Optional.

=head2 shipping_tracking_number

The tracking number. Optional.

=head2 items

A arrayref of hashrefs with the codes and quantities of shipped items.
The following keys (most of them optional) are expected:

=over 4

=item amazon_order_item_code

If not provided will use C<merchant_order_item_code> instead (provided
that the orderline id was passed in the aknowledgement).

=item merchant_order_item_code

Our orderline ID which should have been passed to in the order
aknowledgement.

=item merchant_fulfillment_item_id

Optional.

=item quantity

The quantity shipped (if more than one of a given item was
purchased, and all of them are not shipped together).

=back


=cut

has amazon_order_id => (is => 'ro');
has merchant_order_id => (is => 'ro');
has merchant_fulfillment_id => (is => 'ro');
has fulfillment_date => (is => 'ro',
                         isa => sub {
                             my $dt = $_[0];
                             die "Not a DateTime object"
                               unless ref($dt) && $dt->isa('DateTime');
                         },
                         default => sub { DateTime->now(time_zone => 'Europe/Berlin')},
                        );
has carrier => (is => 'ro', required => 1);
has shipping_method => (is => 'ro');
has shipping_tracking_number => (is => 'ro');
has items => (is => 'ro',
              isa => \&_validate_items,
              required => 1,
             );

sub _validate_items {
    my $items = $_[0];
    die "items should be an hashref"
      unless ($items and ref($items) eq 'ARRAY');
    foreach my $item (@$items) {
        die "An item passed is not an hashref"
          unless ($item and ref($item) eq 'HASH');

        die "An item is missing amazon_order_item_code or merchant_order_item_code"
          unless
            $item->{amazon_order_item_code} || $item->{merchant_order_item_code};
    }
}

=head1 METHODS

=head2 as_shipping_confirmation_hashref

Return an hashref which can be fed into an Amazon message XSD.

=cut

sub as_shipping_confirmation_hashref {
    my $self = shift;
    my %struct;
    # priority goes to the amazon id
    if ($self->amazon_order_id) {
        $struct{AmazonOrderID} = $self->amazon_order_id;
    }
    elsif ($self->merchant_order_id) {
        $struct{MerchantOrderID} = $self->merchant_order_id;
    }
    else {
        die "Missing amazon_order_id or merchant_order_id";
    }

    if ($self->merchant_fulfillment_id) {
        $struct{MerchantFulfillmentID} = $self->merchant_fulfillment_id;
    }
    my $shipping_date = $self->fulfillment_date->iso8601;
    # little hack to have the timezone
    my $tz = $self->fulfillment_date->strftime('%z');
    $tz =~ s/(\d\d)(\d\d)/$1:$2/;

    $struct{FulfillmentDate} = $shipping_date.$tz;

    if ($self->_carrier_is_recognized) {
        $struct{FulfillmentData}{CarrierCode} = $self->carrier;
    }
    else {
        $struct{FulfillmentData}{CarrierName} = $self->carrier;
    }

    if ($self->shipping_method) {
        $struct{FulfillmentData}{ShippingMethod} = $self->shipping_method;
    }
    if ($self->shipping_tracking_number) {
        $struct{FulfillmentData}{ShipperTrackingNumber} = $self->shipping_tracking_number;
    }
    my @items;
    foreach my $item (@{ $self->items }) {
        my %item_struct;
        # precedence to amazon order item
        if ($item->{amazon_order_item_code}) {
            $item_struct{AmazonOrderItemCode} = $item->{amazon_order_item_code};
        }
        elsif ($item->{merchant_order_item_code}) {
            $item_struct{MerchantOrderItemID} = $item->{merchant_order_item_code};
        }
        else {
            die "This shouldn't happen, item was validated";
        }
        if ($item->{merchant_fulfillment_item_id}) {
            $item_struct{MerchantFulfillmentItemID} = $item->{merchant_fulfillment_item_id};
        }
        # more items and partial shipping
        if ($item->{quantity}) {
            $item_struct{Quantity} = $item->{quantity};
        }
        push @items, \%item_struct;
    }
    $struct{Item} = \@items;
    return \%struct;
}

sub _carrier_is_recognized {
    my $self = shift;
    my $carrier = $self->carrier;
    my %carriers = (
                    'AFL/Fedex'              => 1,
                    Aramex                   => 1,
                    "Blue Package"           => 1,
                    BlueDart                 => 1,
                    "Canada Post"            => 1,
                    Chronopost               => 1,
                    "City Link"              => 1,
                    DHL                      => 1,
                    "DHL Global Mail"        => 1,
                    DPD                      => 1,
                    DTDC                     => 1,
                    Delhivery                => 1,
                    "Deutsche Post"          => 1,
                    FEDEX_JP                 => 1,
                    Fastway                  => 1,
                    FedEx                    => 1,
                    "FedEx SmartPost"        => 1,
                    "First Flight"           => 1,
                    GLS                      => 1,
                    'GO!'                    => 1,
                    "Hermes Logistik Gruppe" => 1,
                    "India Post"             => 1,
                    JP_EXPRESS               => 1,
                    "La Poste"               => 1,
                    Lasership                => 1,
                    NITTSU                   => 1,
                    Newgistics               => 1,
                    NipponExpress            => 1,
                    OSM                      => 1,
                    OnTrac                   => 1,
                    Other                    => 1,
                    "Overnite Express"       => 1,
                    Parcelforce              => 1,
                    Parcelnet                => 1,
                    "Poste Italiane"         => 1,
                    Professional             => 1,
                    "Royal Mail"             => 1,
                    SAGAWA                   => 1,
                    SDA                      => 1,
                    SagawaExpress            => 1,
                    Smartmail                => 1,
                    Streamlite               => 1,
                    TNT                      => 1,
                    Target                   => 1,
                    UPS                      => 1,
                    "UPS Mail Innovations"   => 1,
                    UPSMI                    => 1,
                    USPS                     => 1,
                    YAMATO                   => 1,
                    YamatoTransport          => 1,
                    Yodel                    => 1,
                   );
    return $carriers{$carrier};
}


1;
