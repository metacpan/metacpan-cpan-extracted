#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML::Plugin::Phone' );
}

my $module = 'Data::Validate::WithYAML::Plugin::Phone';

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
    ok( $module->check($phone, { country => 'BR' }), "test: $phone" );
}

for my $check ( @blacklist ){
    my $retval = $module->check( $check, { country => 'BR' } );
    ok( !$retval, "test: $check" );
}

#my $de_nr_ok = $module->check('+4917712346799', { country => 'DE' } );
#is $de_nr_ok, 1;

my $uk_nr_nok = $module->check('+4917712346799', { country => 'UK' } );
is $uk_nr_nok, 0;



done_testing();
