#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Business::eWAY::RapidAPI;

my $rapidapi = Business::eWAY::RapidAPI->new(
    mode => 'test',
    username =>
      "44DD7C70Jre1dVgIsULcEyi+A+/cX9V5SAHkIiyVdWrHRG2tZm0rdintfZz85Pa/kGwq/1",
    password => "Abcd1234",
    debug    => 1,
);

my $request = Business::eWAY::RapidAPI::CreateAccessCodeRequest->new();
$request->Customer->Reference('A12345');
$request->Customer->Title('Mr.');

# Note: FirstName is Required Field When Create/Update a TokenCustomer
$request->Customer->FirstName('John');

# Note: LastName is Required Field When Create/Update a TokenCustomer
$request->Customer->LastName("Doe");
$request->Customer->CompanyName('WEB ACTIVE');
$request->Customer->JobDescription('Developer');
$request->Customer->Street1("15 Smith St");
$request->Customer->City('Phillip');
$request->Customer->State('ACT');
$request->Customer->PostalCode('2602');

# Note: Country is Required Field When Create/Update a TokenCustomer
$request->Customer->Country('au');
$request->Customer->Email('sales@eway.co.uk');
$request->Customer->Phone('1800 10 10 65');
$request->Customer->Mobile('1800 10 10 65');
$request->Customer->Comments("Some Comments Here");
$request->Customer->Fax("0131 208 0321");
$request->Customer->Url("http://www.yoursite.com");

$request->ShippingAddress->FirstName("John");
$request->ShippingAddress->LastName("Doe");
$request->ShippingAddress->Street1("9/10 St Andrew");
$request->ShippingAddress->Street2(" Square");
$request->ShippingAddress->City("Edinburgh");
$request->ShippingAddress->State("");
$request->ShippingAddress->Country("gb");
$request->ShippingAddress->PostalCode("EH2 2AF");
$request->ShippingAddress->Email('sales@eway.co.uk');
$request->ShippingAddress->Phone("0131 208 0321");

# ShippingMethod, e.g. "LowCost", "International", "Military". Check the spec for available values.
$request->ShippingAddress->ShippingMethod("LowCost");

my $item1 = Business::eWAY::RapidAPI::LineItem->new();
$item1->SKU("SKU1");
$item1->Description("Description1");
my $item2 = Business::eWAY::RapidAPI::LineItem->new();
$item2->SKU("SKU2");
$item2->Description("Description2");
$request->Items->LineItem( [ $item1, $item2 ] );

my $opt1 = Business::eWAY::RapidAPI::Option->new( Value => 'Test1' );
my $opt2 = Business::eWAY::RapidAPI::Option->new( Value => 'Test2' );
$request->Options->Option( [ $opt1, $opt2 ] );

$request->Payment->TotalAmount(100);
$request->Payment->InvoiceNumber('Inv 21540');
$request->Payment->InvoiceDescription('Individual Invoice Description');
$request->Payment->InvoiceReference('513456');
$request->Payment->CurrencyCode('AUD');

$request->RedirectUrl('http://fayland.org/');
$request->Method('ProcessPayment');

my $result = $rapidapi->CreateAccessCode($request);

use Data::Dumper;
print Dumper( \$rapidapi, \$request, \$result );

1;
