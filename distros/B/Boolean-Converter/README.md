[![Build Status](https://travis-ci.org/karupanerura/Boolean-Converter.svg?branch=master)](https://travis-ci.org/karupanerura/Boolean-Converter) [![Coverage Status](http://codecov.io/github/karupanerura/Boolean-Converter/coverage.svg?branch=master)](https://codecov.io/github/karupanerura/Boolean-Converter?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/Boolean-Converter.svg)](https://metacpan.org/release/Boolean-Converter)
# NAME

Boolean::Converter - boolean object converter

# SYNOPSIS

```perl
use Boolean::Converter;

my $converter = Boolean::Converter->new();

my $booelan = $converter->convert_to(JSON::PP::true, 'Data::MessagePack');
# => Data::MessagePack::true
```

# DESCRIPTION

Boolean::Converter is the super great boolean converter for you.

# METHODS

## Boolean::Converter->new(%args)

Create a new Boolean::Converter object.

### ARGUMENTS

- evaluator

    Evaluates methods map for boolean objects.
    In default, this module evaluates the object in boolean context.

- converter

    Converts methods map to boolean object from a scalar value.

## my $can\_evaluate = $evaluate->can\_evaluate($boolean\_object)

Checks to evaluate the `$boolean_object` as a boolean object.

## my $boolean = $evaluate->evaluate($boolean\_object)

Evaluates the `$boolean_object` as a boolean object.

## my $can\_convert\_to = $convert->can\_convert($to\_boolean\_class)

Checks to convert to the `$to_boolean_object` from a boolean.

## my $boolean\_object = $convert->convert\_to($from\_boolean\_object, $to\_boolean\_class)

Converts to the `$to_boolean_object` from `$from_boolean_object`.

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
