#!/usr/bin/env perl
use strict;
use warnings;
use Data::Currency;
use Test::Exception;
use Test::More tests => 11;

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.2, 'USD' );
    my $result = $value1 / $value2;
    is $result->code,     'USD',  'symbol';
    is $result->as_float, '1.00', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( -1,  'USD' );
    my $result = $value1 / $value2;
    is $result->code,     'USD',   'symbol';
    is $result->as_float, '-1.20', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = -10;
    my $result = $value1 / $value2;
    is $result->code,     'USD',   'symbol';
    is $result->as_float, '-0.12', 'value';
}

{
    my $value1 = 10;
    my $value2 = Data::Currency->new( 1.2, 'USD' );
    my $result = $value1 / $value2;
    is $result->code,     'USD',  'symbol';
    is $result->as_float, '8.33', 'value';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new( 1.2, 'EUR' );
    dies_ok sub { $value1 / $value2 }, 'Different symbols';
}

{
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = Data::Currency->new(0);
    dies_ok sub { $value1 / $value2 }, 'Division by zero';
}

{
    local $SIG{__WARN__} = sub { die "Warnings" };
    my $value1 = Data::Currency->new( 1.2, 'USD' );
    my $value2 = undef;
    throws_ok sub { $value1 / $value2 },
      qr/division by zero/, 'Division by zero';
}
