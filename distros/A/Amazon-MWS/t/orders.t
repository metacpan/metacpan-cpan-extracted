#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 36;

use Amazon::MWS::XML::Order;
use Amazon::MWS::XML::Address;

my $order_data = {
                  'NumberOfItemsUnshipped' => '0',
                  'PaymentMethod' => 'Other',
                  'ShipmentServiceLevelCategory' => 'Standard',
                  'LatestShipDate' => '2014-10-28T22:59:59Z',
                  'OrderTotal' => {
                                   'Amount' => '119.80',
                                   'CurrencyCode' => 'EUR'
                                  },
                  'ShippedByAmazonTFM' => 'false',
                  'SalesChannel' => 'Amazon.de',
                  'LastUpdateDate' => '2014-10-27T09:38:56Z',
                  'NumberOfItemsShipped' => '2',
                  'PurchaseDate' => '2014-10-26T04:40:40Z',
                  'AmazonOrderId' => '333-9999999-99999999',
                  'ShipServiceLevel' => 'Std DE Dom',
                  'BuyerEmail' => 'xxxxxxxxxxxxx@marketplace.amazon.de',
                  'ShippingAddress' => {
                                        'StateOrRegion' => 'Berlin',
                                        'CountryCode' => 'DE',
                                        'PostalCode' => '11111',
                                        'AddressLine2' => 'Strazze',
                                        'AddressLine1' => {},
                                        'Name' => "John U. Doe",
                                        'City' => 'Berlin'
                                       },
                  'BuyerName' => "John Doe",
                  'EarliestDeliveryDate' => '2014-10-27T23:00:00Z',
                  'EarliestShipDate' => '2014-10-26T23:00:00Z',
                  'FulfillmentChannel' => 'MFN',
                  'OrderType' => 'StandardOrder',
                  'MarketplaceId' => 'MARKETPLACE-ID',
                  'LatestDeliveryDate' => '2014-10-31T22:59:59Z',
                  'OrderStatus' => 'Shipped'
                 };
my $orderline_data = [
                      {
                       'ShippingPrice' => {
                                           'Amount' => '0.00',
                                           'CurrencyCode' => 'EUR'
                                          },
                       'GiftWrapPrice' => {
                                           'CurrencyCode' => 'EUR',
                                           'Amount' => '0.00'
                                          },
                       'PromotionDiscount' => {
                                               'CurrencyCode' => 'EUR',
                                               'Amount' => '0.00'
                                              },
                       'ConditionId' => 'New',
                       'ItemPrice' => {
                                       'CurrencyCode' => 'EUR',
                                       'Amount' => '119.80'
                                      },
                       'ShippingTax' => {
                                         'Amount' => '0.00',
                                         'CurrencyCode' => 'EUR'
                                        },
                       'ShippingDiscount' => {
                                              'CurrencyCode' => 'EUR',
                                              'Amount' => '0.00'
                                             },
                       'OrderItemId' => '999999999999999',
                       'Title' => "Blablablablba",
                       'SellerSKU' => '9999999',
                       'ItemTax' => {
                                     'Amount' => '0.00',
                                     'CurrencyCode' => 'EUR'
                                    },
                       'QuantityOrdered' => '2',
                       'ConditionSubtypeId' => 'New',
                       'ASIN' => 'AAAAAAAAA',
                       'GiftWrapTax' => {
                                         'Amount' => '0.00',
                                         'CurrencyCode' => 'EUR'
                                        },
                       'QuantityShipped' => '2'
                      }
                     ];

my $order = Amazon::MWS::XML::Order->new(order => $order_data,
                                         orderline => $orderline_data);

is($order->subtotal, "119.80");
my @items = $order->items;
is($items[0]->price, "59.90");
ok ($order->order_is_shipped, "It is shipped");

my $global = 0;

my $get_orderline = sub {
    diag "Retrieving orderline";
    $global++;
    return $orderline_data;
};

$order = Amazon::MWS::XML::Order->new(order => $order_data,
                                      retrieve_orderline_sub => $get_orderline);

my $amazon_order_number = $order->amazon_order_number;

is $global, 0, "No get_orderline called yet";

my @newitems = $order->items;

is $global, 1, "get_orderline called";

is_deeply(\@newitems, \@items);
is($items[0]->price, "59.90");
is ($items[0]->amazon_order_item, $items[0]->remote_shop_order_item);
ok ($order->order_is_shipped, "It is shipped");
is ($order->amazon_order_number, $order->remote_shop_order_id, "alias ok");
is ($order->shipping_address->state, $order->shipping_address->region, "state and region are aliases");
is ($order->shipping_address->address1, '');
is ($order->shipping_address->address2, 'Strazze');
is ($order->first_name, 'John U.');
is ($order->last_name, 'Doe');
is ($order->shipping_method, 'Standard');

$order_data->{ShippingAddress}->{Name} = 'Doe';
$order = Amazon::MWS::XML::Order->new(order => $order_data);
is ($order->first_name, '');
is ($order->last_name, 'Doe');

{
    my $address = Amazon::MWS::XML::Address->new(AddressLine1 => {test => 1});
    is $address->address1, 'test 1';
    is $address->address2, '';
}
{
    my $address = Amazon::MWS::XML::Address->new(AddressLine1 => {});
    is $address->address1, '';
    is $address->address2, '';
}
{
    my $address = Amazon::MWS::XML::Address->new(AddressFieldOne => ['pippo']);
    is $address->address1, 'pippo';
    is $address->address2, '';
}
{
    my $address = Amazon::MWS::XML::Address->new(AddressFieldOne => []);
    is $address->address1, '';
    is $address->address2, '';
}
{
    my $address = Amazon::MWS::XML::Address->new(AddressLine2 => {test => 2});
    is $address->address1, '';
    is $address->address2, 'test 2';
}
{
    my $address = Amazon::MWS::XML::Address->new(AddressLine2 => {});
    is $address->address1, '';
    is $address->address2, '';
}
{
    my $address = Amazon::MWS::XML::Address->new(AddressFieldTwo => ['pippo']);
    is $address->address1, '';
    is $address->address2, 'pippo';
}
{
    my $address = Amazon::MWS::XML::Address->new(AddressFieldTwo => []);
    is $address->address1, '';
    is $address->address2, '';
}
{
    my $address = Amazon::MWS::XML::Address->new(AddressFieldTwo => \0);
    is $address->address1, '';
    is $address->address2, '';
}
