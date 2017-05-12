#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use Amazon::MWS::Uploader;
use Amazon::MWS::XML::Product;
use Data::Dumper;

if (-d 'schemas') {
    plan tests => 10;
}
else {
    plan skip_all => q{Missing "schemas" directory with the xsd from Amazon, skipping feeds tests};
}


my $existing_products = {
                         1234 => {
                                  sku => 1234,
                                  timestamp_string => '2014-11-11',
                                  status => 'ok',
                                  error_code => 0,
                                 },
                        };

my @products = (Amazon::MWS::XML::Product->new(sku => '1234',
                                               price => '10',
                                               ean => '4444123412343',
                                              ));

my %constructor = (
                   merchant_id => '__MERCHANT_ID__',
                   access_key_id => '12341234',
                   secret_key => '123412341234',
                   marketplace_id => '123412341234',
                   endpoint => 'https://mws-eu.amazonservices.com',
                   feed_dir => 't/feeds',
                   schema_dir => 'schemas',
                   existing_products => $existing_products,
                   products => \@products,
                   debug => 1,
                  );

my $uploader = Amazon::MWS::Uploader->new(%constructor);
ok($uploader, "object created");

is_deeply ($uploader->existing_products, $existing_products,
           "lazy attribute passed at constructor");

ok(scalar(@{ $uploader->products_to_upload }), "Found the product to upload");

ok(!$uploader->product_needs_upload(1234 => '2014-11-11'));

$existing_products->{1234}->{status} = 'failed';
$existing_products->{1234}->{error_code} = '20000';

$uploader = Amazon::MWS::Uploader->new(%constructor);
ok(!$uploader->product_needs_upload(1234 => '2014-11-11'));


is_deeply($uploader->products_to_upload, [], "No products to uploads (failed)") or diag Dumper($uploader);


$constructor{reset_errors} = '20000';

$uploader = Amazon::MWS::Uploader->new(%constructor);

ok($uploader->product_needs_upload(1234 => '2014-11-11'));

ok(scalar(@{ $uploader->products_to_upload }), "Found the product to upload");

eval { Amazon::MWS::XML::Product->new(sku => '1234',
                                      price => '10',
                                      ean => '4444123412343',
                                      images => [ "http://test.org/hello there.jpg" ]) };
ok $@, "unescaped url found:" . $@;

eval { Amazon::MWS::XML::Product->new(sku => '1234',
                                      price => '10',
                                      ean => '4444123412343',
                                      images => [ "http://test.org/hello%20there.jpg" ]) };
ok (!$@, "Escaped url are fine")


