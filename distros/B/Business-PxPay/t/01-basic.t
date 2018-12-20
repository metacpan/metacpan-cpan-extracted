#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
    plan skip_all => "ENV{PxPay_USER} and ENV{PxPay_KEY} are required"
        unless ( $ENV{PxPay_USER} and $ENV{PxPay_KEY} );
    plan tests => 2;
};

use Business::PxPay;

my $pxpay = Business::PxPay->new(
    userid => $ENV{PxPay_USER},
    key => $ENV{PxPay_KEY},
    Currency => 'NZD',
);
isa_ok($pxpay, 'Business::PxPay');

my $data = {
    TxnType => 'Purchase',
    Amount  => 10.9,
    UrlFail => 'http://test.com',
    UrlSuccess => 'http://example.com',
    MerchantReference => 'Test Transaction',
    EmailAddress => 'test@example.com',
    TxnData1 => 'test=A',
    TxnData2 => 'data2=B',
    TxnData3 => 'data3=C',
};
my $out = $pxpay->request_xml( $data );
#diag($out);
ok( index($out, '<AmountInput>10.90</AmountInput>') > -1, '10.90' );

my $rtn = $pxpay->request($data);
diag(Dumper(\$rtn));

1;