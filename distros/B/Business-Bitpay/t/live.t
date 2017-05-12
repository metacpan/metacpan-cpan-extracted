#!/usr/bin/env perl

use strict;
use warnings;

use Business::Bitpay;
use Test::More;

plan skip_all => 'set BITPAY env variable to API key'
  unless $ENV{BITPAY};
my $api_key = $ENV{BITPAY};

my $bitpay = new_ok 'Business::Bitpay', [$api_key];

my $invoice;
subtest 'create invoice' => sub {
    $invoice = $bitpay->create_invoice(
        price    => 10,
        currency => 'USD',
        posData  => rand
    );

    is $invoice->{status}, 'new';
    is $invoice->{price},  10;
};

subtest 'get invoice' => sub {
    my $invoice_getted = $bitpay->get_invoice($invoice->{id});

    is $invoice_getted->{posData}, $invoice->{posData};
};

subtest 'wrong invoice data' => sub {
    eval {
        $bitpay->create_invoice(
            price    => 10,
            price    => 'a',
            currency => 'money'
        );
    };

    like $@, qr/One or more fields is invalid/;
};

done_testing;
