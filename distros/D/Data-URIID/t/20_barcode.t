#!/usr/bin/perl -w
    
use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More;

use_ok('Data::URIID::Barcode');

ok(scalar(@{[Data::URIID::Barcode->type_info]}) > 0, '> 0 types known');
ok(scalar(@{[Data::URIID::Barcode->type_info(
        Data::URIID::Barcode->TYPE_QRCODE,
        Data::URIID::Barcode->TYPE_EAN8,
        Data::URIID::Barcode->TYPE_EAN13,
        )]}) == 3, 'Core types known');

is(Data::URIID::Barcode->type_info(Data::URIID::Barcode->TYPE_QRCODE)->{type}, Data::URIID::Barcode->TYPE_QRCODE, 'Positive type match');
isnt(Data::URIID::Barcode->type_info(Data::URIID::Barcode->TYPE_QRCODE)->{type}, Data::URIID::Barcode->TYPE_EAN13, 'Negative type match');

my $barcode = Data::URIID::Barcode->new(type => Data::URIID::Barcode->TYPE_QRCODE, data => 'xxx');
isa_ok($barcode, 'Data::URIID::Barcode');
is($barcode->type, Data::URIID::Barcode->TYPE_QRCODE);
is($barcode->type_info->{type}, Data::URIID::Barcode->TYPE_QRCODE);

done_testing();

exit 0;
