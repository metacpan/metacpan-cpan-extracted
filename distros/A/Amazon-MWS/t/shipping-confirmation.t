#!perl

use utf8;
use strict;
use warnings;
use Test::More;
use Amazon::MWS::XML::ShippedOrder;
use Amazon::MWS::Uploader;
use DateTime;


my $test_extended;
my $schema_dir = 'schemas';
if (-d $schema_dir) {
    plan tests => 5;
    $test_extended = 1;
}
else {
    plan tests => 2;
}

my %shipped = (
               # amazon_order_id => '12341234',
               merchant_order_id => '8888888',
               merchant_fulfillment_id => '666666', # optional
               fulfillment_date => DateTime->new(
                                                 year => 2014,
                                                 month => 11,
                                                 day => 14,
                                                 hour => 11,
                                                 minute => 11,
                                                 second => 0,
                                                 time_zone => 'Europe/Berlin',
                                                ),
               carrier => 'UPS',
               shipping_method => 'Second Day',
               shipping_tracking_number => '123412341234',
               items => [
                         {
                          # amazon_order_item_code => '1111',
                          merchant_order_item_code => '2222',
                          merchant_fulfillment_item_id => '3333',
                          quantity => 2,
                         },
                         {
                          # amazon_order_item_code => '4444',
                          merchant_order_item_code => '5555',
                          merchant_fulfillment_item_id => '6666',
                          quantity => 3,
                         }
                        ],
              );

my $shipped_order = Amazon::MWS::XML::ShippedOrder->new(%shipped);

ok($shipped_order, "constructor validates");

is_deeply($shipped_order->as_shipping_confirmation_hashref,
          {
           MerchantOrderID => 8888888,
           MerchantFulfillmentID => '666666',
           FulfillmentDate => '2014-11-14T11:11:00+01:00',
           FulfillmentData => {
                               CarrierCode => 'UPS',
                               ShippingMethod => 'Second Day',
                               ShipperTrackingNumber => '123412341234',
                              },
           Item => [
                    {
                     MerchantOrderItemID => '2222',
                     MerchantFulfillmentItemID => '3333',
                     Quantity => 2,
                    },
                    {
                     MerchantOrderItemID => '5555',
                     MerchantFulfillmentItemID => '6666',
                     Quantity => 3,
                    },
                   ],

          },
          "Structure appears ok");

exit unless $test_extended;

my $feed_dir = 't/feeds';

my $uploader = Amazon::MWS::Uploader->new(
                                          merchant_id => 'My Store',
                                          access_key_id => '12341234',
                                          secret_key => '123412341234',
                                          marketplace_id => '123412341234',
                                          endpoint => 'https://mws-eu.amazonservices.com',
                                          feed_dir => $feed_dir,
                                          schema_dir => $schema_dir,
                                          );
ok($uploader, "Uploader ok");

my $feed = $uploader->shipping_confirmation_feed($shipped_order);
ok($feed, "Can create the feed and validates against the schema"); # and diag $feed;

# test against the example provided in the documentation


my $expected = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<AmazonEnvelope>
  <Header>
    <DocumentVersion>1.1</DocumentVersion>
    <MerchantIdentifier>My Store</MerchantIdentifier>
  </Header>
  <MessageType>OrderFulfillment</MessageType>
  <Message>
    <MessageID>1</MessageID>
    <OrderFulfillment>
      <MerchantOrderID>1234567</MerchantOrderID>
      <MerchantFulfillmentID>1234567</MerchantFulfillmentID>
      <FulfillmentDate>2002-05-01T15:36:33-08:00</FulfillmentDate>
      <FulfillmentData>
        <CarrierCode>UPS</CarrierCode>
        <ShippingMethod>Second Day</ShippingMethod>
        <ShipperTrackingNumber>1234567890</ShipperTrackingNumber>
      </FulfillmentData>
      <Item>
        <MerchantOrderItemID>1234567</MerchantOrderItemID>
        <MerchantFulfillmentItemID>1234567</MerchantFulfillmentItemID>
        <Quantity>2</Quantity>
      </Item>
    </OrderFulfillment>
  </Message>
</AmazonEnvelope>
XML

%shipped = (
            merchant_order_id => 1234567,
            merchant_fulfillment_id => 1234567,
            fulfillment_date => DateTime->new(year => 2002,
                                              month => 5,
                                              day => 1,
                                              hour => 15,
                                              minute => 36,
                                              second => 33,
                                              time_zone => '-08:00',
                                              ),
            carrier => 'UPS',
            shipping_method => 'Second Day',
            shipping_tracking_number => 1234567890,
            items => [
                      {
                       merchant_order_item_code => 1234567,
                       merchant_fulfillment_item_id => 1234567,
                       quantity => 2,
                      },
                     ],
           );

$shipped_order = Amazon::MWS::XML::ShippedOrder->new(%shipped);
is_deeply ([ split(/\n/, $uploader->shipping_confirmation_feed($shipped_order)) ],
           [ split(/\n/, $expected) ],
           "Feed looks ok");
