package Amazon::MWS::XML::Feed;

use strict;
use warnings;
use utf8;

use base 'Amazon::MWS::XML::GenericFeed';
use Data::Dumper;

use Moo;

=head1 NAME

Amazon::MWS::XML::Feed -- module to create XML feeds for Amazon MWS

=head2 DESCRIPTION

Extends Amazon::MWS::XML::GenericFeed and inherits its accessors/methods.

=head1 ACCESSORS

=head2 merchant_id

Required. The merchant id provided by Amazon.

=head2 products

Required. An arrayref with products objects. The objects must respond
to the following methods:

=over 4

=item as_hash

The data structure to populate the Product stanza.

=back

=cut


has products => (is => 'ro',
                 required => 1,
                 isa => sub {
                     die "Not an arrayref" unless ref($_[0]) eq 'ARRAY';
                 });

sub _create_feed {
    my ($self, $operation) = @_;

    my %methods = (
                   Product => 'as_product_hash',
                   Inventory => 'as_inventory_hash',
                   Price => 'as_price_hash',
                   ProductImage => 'as_images_array',
                   Relationship => 'as_variants_hash',
                  );

    my $method = $methods{$operation} or die "$operation is not supported";

    my @messages;
    my $message_counter = 1;
    my @products = @{ $self->products };
    for (my $i = 0; $i < @products; $i++) {
        my $data = $products[$i]->$method;
        print Dumper($data) if $self->debug;
        # unclear if it's the right thing to do
        if (ref($data) eq 'ARRAY') {
            foreach my $msg (@$data) {
                push @messages, {
                                 MessageID => $message_counter++,
                                 OperationType => 'Update',
                                 $operation => $msg,
                                };
            }
        }
        elsif ($data) {
            push @messages, {
                             MessageID => $message_counter++,
                             OperationType => 'Update',
                             # here will crash if the object is not the one required.
                             $operation => $data,
                            };
        }
    }
    return $self->create_feed($operation, \@messages);
}


=head1 METHODS

=head2 product_feed

Return a string with the product XML.

The Product feed contains descriptive information about the products
in your catalog. This information allows Amazon to build a record and
assign a unique identifier known as an ASIN (Amazon Standard Item
Number) to each product. This feed is always the first step in
submitting products to Amazon because it establishes the mapping
between the seller's unique identifier (SKU) and Amazon's unique
identifier (ASIN).

=cut

sub product_feed {
    return shift->_create_feed('Product');
}

=head2 inventory_feed

The Inventory feed allows you to update inventory quantities (stock
levels) for your items. For each item you offer only on Amazon, send
the exact number you currently have in stock. If you use multiple
sales channels, we recommend configuring your systems to send a value
of zero once your available inventory reaches a level you specify.
When the quantity is greater than zero the buy button is activated and
the quantity is decremented with each order. When the quantity reaches
zero, the item is no longer available for purchase on Amazon until you
send a replenishment value. The inventory feed can also be used to
indicate the lead-time to ship a given item. If no value is sent, the
default value of two business days is used.

=head2 inventory_feed_name

=cut

sub inventory_feed {
    return shift->_create_feed('Inventory');
}

=head2 price_feed

The Price feed allows you to set the current price and sale price
(when applicable) for an item. The sale price is optional, but, if
used, the start and end date must be provided also (so far, not
implemented).

=head2 price_feed_name

=cut

sub price_feed {
    return shift->_create_feed('Price');
}

=head2 image_feed

The Image feed allows you to upload various images for a product.
Amazon can display several images for each product. It is in your best
interest to provide several high-resolution images for each of your
products so customers can make informed buying decisions.

=head3 Image Requirements

=over 4

=item Format - photographs, not drawings

=item Color Model - RGB (no CMYK images)

=item Background - white or clear, no borders or words, no brand logos

=item Recommended dimensions

Images should be 1000 pixels or larger in either height or width as
this will enable zoom functionality on the website (zoom has proven to
enhance sales). The smallest your file should be is 500 pixels on the
longest side. Consistently sized images are strongly recommended.

=item File type - JPEG (.jpg) or GIF (.gif)

=item Resolution - 72 ppi

=item Animation - none

=back

=cut

sub image_feed {
    return shift->_create_feed('ProductImage');
}

=head2 variants_feed

Creates variants feed.

=cut

sub variants_feed {
    return shift->_create_feed('Relationship');
}

1;


