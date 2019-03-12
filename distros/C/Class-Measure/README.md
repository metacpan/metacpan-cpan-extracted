# NAME

Class::Measure - Create, compare, and convert units of measurement.

# SYNOPSIS

See [Class::Measure::Length](https://metacpan.org/pod/Class::Measure::Length) for some examples.

# DESCRIPTION

This is a base class that is inherited by the Class::Measure 
classes.  This distribution comes with the class [Class::Measure::Length](https://metacpan.org/pod/Class::Measure::Length).

The classes [Class::Measure::Area](https://metacpan.org/pod/Class::Measure::Area), [Class::Measure::Mass](https://metacpan.org/pod/Class::Measure::Mass),
[Class::Measure::Space](https://metacpan.org/pod/Class::Measure::Space), [Class::Measure::Temperature](https://metacpan.org/pod/Class::Measure::Temperature),
and [Class::Measure::Volume](https://metacpan.org/pod/Class::Measure::Volume) are planned and will be added soon.

The methods described here are available in all Class::Measure classes.

# METHODS

## new

    my $m = new Class::Measure::Length( 1, 'inch' );

Creates a new measurement object.  You must pass an initial
measurement and default unit.

In most cases the measurement class that you are using
will export a method to create new measurements.  For
example [Class::Measure::Length](https://metacpan.org/pod/Class::Measure::Length) exports the
`length()` method.

## unit

    my $unit = $m->unit();

Returns the object's default unit.

## set\_unit

    $m->set_unit( 'feet' );

Sets the default unit of the measurement.

## value

    my $yards = $m->value('yards');
    my $val = $m->value();
    print "$m is the same as $val when in a string\n";

Retrieves the value of the measurement in the
default unit.  You may specify a unit in which
case the value is converted to the unit and returned.

This method is also used to handle overloading of
stringifying the object.

## set\_value

    my $m = length( 0, 'inches' );
    $m->set_value( 12 ); # 12 inches.
    $m->set_value( 1, 'foot' ); # 1 foot.

Sets the measurement in the default unit.  You may
specify a new default unit as well.

## reg\_units

    Class::Measure::Length->reg_units(
        'inch', 'foot', 'yard'
    );

Registers one or more units for use in the specified
class.  Units should be in the singular, most common,
form.

## units

    my @units = Class::Measure::Length->units();

Returns a list of all registered units.

## reg\_aliases

    Class::Measure::Length->reg_aliases(
        ['feet','ft'] => 'foot',
        ['in','inches'] => 'inch',
        'yards' => 'yard'
    );

Register alternate names for units.  Expects two
arguments per unit to alias.  The first argument
being the alias (scalar) or aliases (array ref), and
the second argument being the unit to alias them to.

## reg\_convs

    Class::Measure::Length->reg_convs(
        12, 'inches' => 'foot',
        'yard' => '3', 'feet'
    );

Registers a unit conversion.  There are three distinct
ways to specify a new conversion.  Each requires three
arguments.

    $count1, $unit1 => $unit2
    $unit1 => $count2, $unit2

These first two syntaxes create automatic reverse conversions
as well.  So, saying there are 12 inches in a foot implies
that there are 1/12 feet in an inch.

    $unit1 => $unit2, $sub

The third syntax accepts a subroutine as the last argument
the subroutine will be called with the value of $unit1 and
it's return value will be assigned to $unit2.  This
third syntax does not create a reverse conversion automatically.

# SUPPORT

Please submit bugs and feature requests to the
Class-Measure GitHub issue tracker:

[https://github.com/bluefeet/Class-Measure/issues](https://github.com/bluefeet/Class-Measure/issues)

# AUTHORS

    Aran Clary Deltac <bluefeet@cpan.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
