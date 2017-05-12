#!/usr/bin/env perl
use strict;
use warnings;
use Data::Currency;
use Test::Exception;
use Test::More tests => 8;

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.3, 'USD' );
    my $result = $value1 + $value2;
    is $result->code,     'USD',  'symbol';
    is $result->as_float, '2.50', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2,  'USD' );
    my $value2 = Data::Currency->new( -1.2, 'USD' );
    my $result = $value1 + $value2;
    is $result->code,     'USD',  'symbol';
    is $result->as_float, '0.00', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = 0.1;
    my $result = $value1 + $value2;
    is $result->code,     'USD',  'symbol';
    is $result->as_float, '1.30', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.2, 'EUR' );
    dies_ok sub { $value1 + $value2 }, 'Different symbols';
}

{
    local $SIG{__WARN__} = sub { die "Warnings" };
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = undef;
    is $value1 + $value2, '$1.20', 'Add undef';
}
