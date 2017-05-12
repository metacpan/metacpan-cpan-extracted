#!/usr/bin/env perl
use strict;
use warnings;
use Data::Currency;
use Test::Exception;
use Test::More tests => 9;

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $result = $value1 * 1.3;
    is $result->code,     'USD',  'symbol';
    is $result->as_float, '1.56', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $result = $value1 * 0;
    is $result->code,     'USD',  'symbol';
    is $result->as_float, '0.00', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2,  'USD' );
    my $value2 = Data::Currency->new( -1.2, 'USD' );
    my $result = $value1 * $value2;
    is $result->code,     'USD',   'symbol';
    is $result->as_float, '-1.44', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.2, 'EUR' );
    dies_ok sub { $value1 * $value2 }, 'Different symbols';
}

{
    local $SIG{__WARN__} = sub { die "Warnings" };
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $result = $value1 * undef;
    is $result->code,     'USD',  'symbol';
    is $result->as_float, '0.00', 'value';
}
