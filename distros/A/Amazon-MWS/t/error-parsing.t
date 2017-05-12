#!perl

use utf8;
use strict;
use warnings;
use Amazon::MWS::Uploader;
use Data::Dumper;
use Test::More;

my %constructor = (
                   merchant_id => '__MERCHANT_ID__',
                   access_key_id => '12341234',
                   secret_key => '123412341234',
                   marketplace_id => '123412341234',
                   endpoint => 'https://mws-eu.amazonservices.com',
                   feed_dir => 't/feeds',
                   schema_dir => 'schemas',
                  );

plan skip_all => "Missing schema and feed dirs"
  unless (-d $constructor{schema_dir} && -d $constructor{feed_dir});

my $uploader = Amazon::MWS::Uploader->new(%constructor);

my $error_msg = q{upload-2016-03-14-19-07-09 8541 The SKU data provided conflicts with the Amazon catalog. The standard_product_id value(s) provided correspond to the ASIN  XXXXXX, but some information contradicts with the Amazon catalog. The following are the attribute value(s) that are conflicting: part_number (Merchant: 'MERCHANT_ID' / Amazon: 'AMAZON_ID'). If your product is this ASIN, then modify your data to reflect the Amazon catalog values. Else, check your value(s) for standard_product_id are correct.};

is_deeply($uploader->_parse_error_message_mismatches($error_msg),
          {
           asin => 'XXXXXX',
           shop_part_number => 'MERCHANT_ID',
           amazon_part_number => 'AMAZON_ID',
           part_number => {
                           shop => 'MERCHANT_ID',
                           amazon => 'AMAZON_ID',
                          }
          });

done_testing;
