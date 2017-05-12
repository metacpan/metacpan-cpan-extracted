#!/usr/bin/env perl
use strict;
use warnings;
use Data::Currency;
use Test::Exception;
use Test::More tests => 10;

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.2, 'USD' );
    my $result = $value1 % $value2;
    is $result->code,     'USD',  'symbol';
    is $result->as_float, '0.00', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( -1,  'USD' );
    my $result = $value1 % $value2;
    is $result->code,     'USD',   'symbol';
    is $result->as_float, '0.00', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = -10;
    my $result = $value1 % $value2;
    is $result->code,     'USD',   'symbol';
    is $result->as_float, '-9.00', 'value';
}

{
    my $value1 = 10;
    my $value2 = Data::Currency->new( 1.2, 'USD' );
    my $result = $value1 % $value2;
    is $result->code,     'USD',  'symbol';
    is $result->as_float, '0.00', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.2, 'EUR' );
    dies_ok sub { $value1 % $value2 }, 'Different symbols';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new(0);
    dies_ok sub { $value1 % $value2 }, 'Modulus zero';
}
