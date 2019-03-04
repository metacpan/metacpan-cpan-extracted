#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Validate::WithYAML;

plan skip_all => 'Wait for a new release of Number::Phone::BR to fix a bug';

my $config = '---
default:
    phone:
        plugin: Phone
        country: BR
';

my $validator = Data::Validate::WithYAML->new( \$config );

my @phones = (
    '+55 11 2345-6789', '+55 (011) 2345-6789', '+55 011 2345-6789',
        '11 2345-6789',     '(011) 2345-6789',     '011 2345-6789',
          '1123456789',         '01123456789'
);

my @blacklist = (
    'test',
    '123',
    '+12as',
    '00012345678',
    '+012455678832',
    '+4412345677',
    '004412345677',
    '+49 177 - 123456789',
    '+49 177 / 124532344',
    '0177 / 1234392',
    '0157124567889',
    '+1 555 13351 13',
    '0177 - 123456789',
    '0211 5110',
);

for my $phone ( @phones ){
    ok( $validator->check( 'phone', $phone ), "test: $phone" );
}

for my $check ( @blacklist ){
    my $retval = $validator->check( 'phone', $check );
    ok( !$retval, "test: $check" );
}

done_testing();
