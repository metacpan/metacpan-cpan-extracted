[![Build Status](https://api.travis-ci.org/bluescreen10/Data-Currency.png)](https://travis-ci.org/Bluescreen10/Data-Currency)

# NAME

Data::Currency

# VERSION

version 0.0501

# SYNOPSIS

    use Data::Currency;

    my $price = Data::Currency->new(1.2, 'USD');
    print $price;            # 1.20 USD
    print $price->code;      # USD
    print $price->format;    # FMT_SYMBOL
    print $price->as_string; # 1.20 USD
    print $price->as_string('FMT_SYMBOL'); # $1.20

    print 'Your price in Canadian Dollars is: ';
    print $price->convert('CAD')->value;

# DESCRIPTION

The Data::Currency module provides basic currency formatting and conversion:

    my $price = 1.23;
    my $currency = Data::Currency->new($price);

    print $currency->convert('CAD')->as_string;

Each Data::Currency object will stringify to the original value except in string
context, where it stringifies to the format specified in `format`.

# NAME

Data::Currency - Container class for currency conversion/formatting

# VERSION

version 0.0501

# CONSTRUCTOR

## new

- Arguments: $price \[, $code, $format\] || \\%options

To create a new Data::Currency object, simply call `new` and pass in the
price to be formatted:

    my $currency = Data::Currency->new(10.23);

    my $currency = Data::Currency->new({
        value  => 1.23,
        code   => 'CAD',
        format => 'FMT_SYMBOL',
        converter_class => 'MyConverterClass'
    });

You can also pass in the default currency code and/or currency format to be
used for each instance. If no code or format are supplied, future calls to
`as_string` and `convert` will use the default format and code values.

You can set the defaults by calling the code/format values as class methods:

    Data::Currency->code('USD');
    Data::Currency->format('FMT_COMMON');

    my $currency = Data::Currency->new(1.23);
    print $currency->as_string; # $1.23

    my $currency = Data::Currency->new(1.23, 'CAD', 'FMT_STANDARD');
    print $currency->as_string; # 1.23 CAD

The following defaults are set when Data::Currency is loaded:

    value:  0
    code:   USD
    format: FMT_COMMON

# METHODS

## code

- Arguments: $code

Gets/sets the three letter currency code for the current currency object.
`code` dies loudly if `code` isn't a valid currency code.

## convert

- Arguments: $code

Returns a new Data::Currency object containing the converted value.

If no `code` is specified, the current value of `code` will be used. If the
currency you are converting to is the same as the current objects currency
code, convert will just return itself.

Remember, convert returns another currency object, so you can chain away:

    my $price = Data::Currency->new(1.25, 'USD');
    print $price->convert('CAD')->as_string;

`convert` dies if `code` isn't valid currency code or isn't defined.

## converter\_class

- Arguments: $converter\_class

Gets/sets the converter class to be used when converting currency numbers.

    Data::Currency->converter_class('MyCurrencyConverter');

The converter class can be any class that supports the following method
signature:

    sub convert {
        my ($self, $price, $from, $to) = @_;

        return $converted_price;
    };

This method dies if the specified class can not be loaded.

## format

- Arguments: $options

Gets/sets the format to be used when `as_string` is called. See
[Locale::Currency::Format](http://search.cpan.org/perldoc?Locale::Currency::Format) for the available
formatting options.

## name

Returns the currency name for the current objects currency code. If no
currency code is set the method will die.

## stringify

Sames as `as_string`.

## as\_string

Returns the current objects value as a formatted currency string.

## as\_float

Returns the value formatted as float using decimal places specified by currency
code

## value

Returns the original price value given to `new`.

## get\_component\_class

- Arguments: $name

Gets the current class for the specified component name.

    my $class = $self->get_component_class('converter_class');

There is no good reason to use this. Use the specific class accessors instead.

## set\_component\_class

- Arguments: $name, $value

Sets the current class for the specified component name.

    $self->set_component_class('converter_class', 'MyCurrencyConverter');

This method will croak if the specified class can not be loaded. There is no
good reason to use this. Use the specific class accessors instead.

# SEE ALSO

[Locale::Currency](http://search.cpan.org/perldoc?Locale::Currency), [Locale::Currency::Format](http://search.cpan.org/perldoc?Locale::Currency::Format),
[Finance::Currency::Convert::WebserviceX](http://search.cpan.org/perldoc?Finance::Currency::Convert::WebserviceX)

# AUTHOR

Christopher H. Laco <claco \_at\_ chrislaco.com>, Mariano Wahlmann <dichoso \_at\_ gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Christopher H. Laco, Mariano Wahlmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
