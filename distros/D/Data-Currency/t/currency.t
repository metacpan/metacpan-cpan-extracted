#!/usr/bin/env perl
# $Id: currency.t 1731 2007-02-11 20:35:41Z claco $

use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Test::More tests => 118;
    use Scalar::Util qw/refaddr/;

    eval 'use Test::MockObject 1.07';
    if ( !$@ ) {
        Test::MockObject->fake_module(
            'Finance::Currency::Convert::WebserviceX' => (
                new     => sub { return bless {}, shift },
                convert => sub { return $_[1] + 1.00 }
            )
        );

        Test::MockObject->fake_module(
            'MyConverterClass' => (
                new     => sub { return bless {}, shift },
                convert => sub { return $_[1] + 2.00 }
            )
        );
    }

    use_ok('Data::Currency');
}

## check overloads
{
    my $currency = Data::Currency->new(1);
    cmp_ok( $currency + 1, '==', 2, 'overloads as numeric' );
    ok( $currency, 'overloads boolean' );
    is( "$currency", '$1.00', 'overloads string' );
    cmp_ok( $currency, '==', 1, 'overloads ==' );
};

## as_string/stringify with format
{
    my $currency = Data::Currency->new;
    isa_ok( $currency, 'Data::Currency' );
    is( $currency->value, 0, 'value was set' );
    is( $currency->stringify('FMT_STANDARD'), '0.00 USD',
        'stringify to value' );
    is( $currency->code,      'USD',        'code is set' );
    is( $currency->format,    'FMT_COMMON', 'format is not set' );
    is( $currency->name,      'US Dollar',  'got name' );
    is( $currency->converter, undef,        'converter no defined' );
};

## croak as_string/stringify with no code
{
    my $currency = Data::Currency->new;
    isa_ok( $currency, 'Data::Currency' );
    delete $currency->{'code'};
    local $Data::Currency::__cag_code = undef;

    eval { $currency->stringify; };
    like( $@, qr/invalid currency code/i );
};

## croak as_string/stringify with bad code
{
    my $currency = Data::Currency->new;
    isa_ok( $currency, 'Data::Currency' );
    $currency->{'code'} = 'BAD';

    eval { $currency->stringify; };
    like( $@, qr/invalid currency code/i );
};

## croak convert with bad target code
{
    my $currency = Data::Currency->new;
    isa_ok( $currency, 'Data::Currency' );

    eval { $currency->convert('BAD'); };
    like( $@, qr/invalid currency code/i );
};


## croak convert with bad source code
{
    my $currency = Data::Currency->new;
    isa_ok( $currency, 'Data::Currency' );
    $currency->{'code'} = 'BAD';

    eval { $currency->convert('CAD'); };
    like( $@, qr/invalid currency code/i );
};

## default to FMT_COMMON when no format is set in stringify
{
    my $currency = Data::Currency->new(1.23);
    $currency->format(undef);
    Data::Currency->format(undef);
    is( $currency->format, undef );
    delete $currency->{'format'};
    is( $currency->format, undef );

    is( $currency->stringify, '$1.23' );
    Data::Currency->format('FMT_COMMON');
    is( $currency->format, 'FMT_COMMON' );
};

## create with no value
{
    my $currency = Data::Currency->new;
    isa_ok( $currency, 'Data::Currency' );
    is( $currency->value,     0,            'value was set' );
    is( $currency->stringify, '$0.00',      'stringify to value' );
    is( $currency->code,      'USD',        'code is set' );
    is( $currency->format,    'FMT_COMMON', 'format is not set' );
    is( $currency->name,      'US Dollar',  'got name' );
    is( $currency->converter, undef,        'converter no defined' );
};

## create new with no options
{
    my $currency = Data::Currency->new(1.23);
    isa_ok( $currency, 'Data::Currency' );
    is( $currency->value,     1.23,         'value was set' );
    is( $currency->stringify, '$1.23',      'stringify to value' );
    is( $currency->code,      'USD',        'code is set' );
    is( $currency->format,    'FMT_COMMON', 'format is set' );
    is( $currency->name,      'US Dollar',  'got name' );
    is( $currency->converter, undef,        'converter no defined' );
};

## create new with code/format
{
    my $currency = Data::Currency->new( 1.23, 'CAD', 'FMT_STANDARD' );
    isa_ok( $currency, 'Data::Currency' );
    is( $currency->value,     1.23,           'value was set' );
    is( $currency->stringify, '1.23 CAD',     'stringify to string' );
    is( $currency->code,      'CAD',          'code was set' );
    is( $currency->format,    'FMT_STANDARD', 'format was set' );
    is( $currency->converter, undef,          'converter no defined' );
};

## create new with code/format as a hash
{
    my $currency = Data::Currency->new(
        {
            value  => 1.23,
            code   => 'CAD',
            format => 'FMT_STANDARD'
        }
    );
    isa_ok( $currency, 'Data::Currency' );
    is( $currency->value,     1.23,           'value was set' );
    is( $currency->stringify, '1.23 CAD',     'stringify to string' );
    is( $currency->code,      'CAD',          'code was set' );
    is( $currency->format,    'FMT_STANDARD', 'format was set' );
    is( $currency->converter, undef,          'converter no defined' );
};

## create new with code/format as a hash w/ bad data
{
    my $currency = Data::Currency->new(
        {
            value  => undef,
            code   => undef,
            format => undef
        }
    );
    isa_ok( $currency, 'Data::Currency' );
    is( $currency->value,     0,            'value was set' );
    is( $currency->stringify, '$0.00',      'stringify to string' );
    is( $currency->code,      'USD',        'code was set' );
    is( $currency->format,    'FMT_COMMON', 'format was set' );
    is( $currency->converter, undef,        'converter no defined' );
};

## croak when bad currency code is set in new
{
    eval { my $currency = Data::Currency->new( 1.23, 'BAD' ); };
    like( $@, qr/invalid currency code/i );
};

## create and set code/format
{
    my $currency = Data::Currency->new(1.23);
    isa_ok( $currency, 'Data::Currency' );
    is( $currency->value,     1.23,    'value was set' );
    is( $currency->stringify, '$1.23', 'stringify to string' );
    is( $currency->code,      'USD',   'code is set' );
    is( $currency->converter, undef,   'converter no defined' );

    $currency->code('CAD');
    is( $currency->code, 'CAD', 'code set' );

    $currency->format('FMT_STANDARD');
    is( $currency->format, 'FMT_STANDARD', 'format set' );

    is( $currency->stringify, '1.23 CAD', 'stringify to string' );
};

## tcroak when bad currency code is set
{
    my $currency = Data::Currency->new(1.23);

    eval { $currency->code('BAD'); };
    like( $@, qr/invalid currency code/i );
};

## get name
{
    my $currency = Data::Currency->new( 1.23, 'JPY' );
    isa_ok( $currency, 'Data::Currency' );
    is( $currency->code, 'JPY', 'code was set' );
    is( $currency->name, 'Yen', 'got name' );
};

## throw exception when converter_class can't be loaded
{
    eval { Data::Currency->converter_class('Bogus'); };
    like( $@, qr/Bogus could not be loaded/i );
};


## test convert
SKIP: {
    eval 'use Test::MockObject 1.07';
    skip 'Test::MockObject 1.07 not installed', 44 if $@;

    ## convert with code
    {
        my $currency = Data::Currency->new( 1.23, 'USD' );
        isa_ok( $currency, 'Data::Currency' );
        is( $currency->value,     1.23,         'value was set' );
        is( $currency->stringify, '$1.23',      'stringify to string' );
        is( $currency->code,      'USD',        'code is set' );
        is( $currency->format,    'FMT_COMMON', 'format is not set' );
        is( $currency->converter, undef,        'converter not defined' );

        my $converted = $currency->convert('CAD');
        isa_ok( $currency->converter,
            'Finance::Currency::Convert::WebserviceX' );
        isa_ok( $converted, 'Data::Currency' );
        is( $converted->value,     2.23,         'value was set' );
        is( $converted->stringify, '$2.23',      'stringify to value' );
        is( $converted->code,      'CAD',        'code is set' );
        is( $converted->format,    'FMT_COMMON', 'format is set' );
    };

    ## use an existing converter
    {
        my $currency = Data::Currency->new( 1.23, 'USD' );
        isa_ok( $currency, 'Data::Currency' );
        is( $currency->value,     1.23,         'value was set' );
        is( $currency->stringify, '$1.23',      'stringify to string' );
        is( $currency->code,      'USD',        'code is set' );
        is( $currency->format,    'FMT_COMMON', 'format is not set' );
        is( $currency->converter, undef,        'converter not defined' );
        $currency->converter( MyConverterClass->new );

        my $converted = $currency->convert('CAD');
        isa_ok( $currency->converter, 'MyConverterClass' );
        isa_ok( $converted,           'Data::Currency' );
        is( $converted->value,     3.23,         'value was set' );
        is( $converted->stringify, '$3.23',      'stringify to value' );
        is( $converted->code,      'CAD',        'code is set' );
        is( $converted->format,    'FMT_COMMON', 'format is set' );
    };

    ## test when converter returns nothing
    {
        Test::MockObject->fake_module(
            'Finance::Currency::Convert::WebserviceX' => (
                new     => sub { return bless {}, shift },
                convert => sub { }
            )
        );

        my $currency = Data::Currency->new( 1.23, 'USD' );
        my $converted = $currency->convert('CAD');
        isa_ok( $converted, 'Data::Currency' );
        is( $converted->value,     0,       'value is 0 when converter fails' );
        is( $converted->stringify, '$0.00', 'stringify to value' );
        is( $converted->code,      'CAD',   'code is set' );
        is( $converted->format, 'FMT_COMMON', 'format is not set' );
    };

    ## throw exception when no code is set during convert
    {
        my $currency = Data::Currency->new(1.23);

        eval {
            $currency->{'code'} = undef;
            $currency->convert('CAD');
        };
        like( $@, qr/invalid currency code source/i );
    };

    ## throw exception when no code is passed to convert
    {
        my $currency = Data::Currency->new( 1.23, 'CAD' );

        eval { $currency->convert; };
        like( $@, qr/invalid currency code target/i );
    };

    ## return self if to is same as from
    {
        my $currency = Data::Currency->new( 1.23, 'USD' );
        isa_ok( $currency, 'Data::Currency' );
        is( $currency->value,     1.23,         'value was set' );
        is( $currency->stringify, '$1.23',      'stringify to string' );
        is( $currency->code,      'USD',        'code is set' );
        is( $currency->format,    'FMT_COMMON', 'format is set' );
        is( $currency->converter, undef,        'converter not defined' );

        my $converted = $currency->convert('USD');
        is( $currency->converter, undef, 'converter not defined' );
        is(
            refaddr $converted,
            refaddr $currency,
            'return self if codes are the same'
        );
        isa_ok( $converted, 'Data::Currency' );
        is( $converted->value,     1.23,         'value was set' );
        is( $converted->stringify, '$1.23',      'stringify to string' );
        is( $converted->code,      'USD',        'code is set' );
        is( $converted->format,    'FMT_COMMON', 'format is not set' );
    };
}

## test loading of utf8
{
    local $] = 5.007999;

    my $currency = Data::Currency->new(1.23);
    isa_ok( $currency, 'Data::Currency' );
    is( $currency->stringify, '$1.23', 'still got format' );
};

## set converter_class to nothing, and put it back
{
    Data::Currency->converter_class(undef);
    is( Data::Currency->converter_class, undef, 'unset converter_class' );

    Data::Currency->converter_class('Data::Currency');
    is( Data::Currency->converter_class,
        'Data::Currency', 'set converter_class' );
};
