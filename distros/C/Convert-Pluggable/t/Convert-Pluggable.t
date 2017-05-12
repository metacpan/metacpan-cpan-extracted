#!/usr/bin/env perl

# TODO - move old and new tests to separate files?
# TODO - let user specify his/her own data_file to test?

use strict;
use warnings;

use Test::More;
use Math::Round qw/nearest/;
use Data::Dump qw/dump/;
use File::Basename;

BEGIN { use_ok('Convert::Pluggable') }

my $data_file = dirname(__FILE__) . '/../data/units.json';

# test we can get a C::P object with and without a data file:
my $old = new Convert::Pluggable();
my $new = new Convert::Pluggable( data_file => $data_file );
my @cps = ( $old, $new );

my $result;
my $precision = 3;

foreach my $cp (@cps) {
    isa_ok( $cp, 'Convert::Pluggable' );

    # should get a list of all units
    my $units_ref = ( $cp->{data_file} ) ? $cp->types : $cp->get_units();

    isa_ok( $units_ref, 'ARRAY' );

    my @units = @{$units_ref};

    # all units should be singular:
    my %singular_exceptions = ( celsius => 1, );
    foreach my $unit (@units) {
        my $unit = $unit->{'unit'};
        unlike( $unit, qr/s$/, "$unit should be singular" )
          unless ( exists $singular_exceptions{$unit} );
    }

    $result = $cp->convert(
        {
            'factor'    => '-40',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Celsius',
            'precision' => '4',
        }
    );
    is( $result->{'result'}, '-40', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-40',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '-40', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '10',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '10', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '10',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '50', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '10',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '-441.67', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '10',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '-449.67', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '1234', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '2253.2', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '774.33', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '1761.53', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '-87', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '-124.6', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-7',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '-7', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-7',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '19.4', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-7',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-7',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '0',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '0', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '0',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '32', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '0',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '-459.67', 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '0',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '-459.67', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '10',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '-12.222', 'OK' );
    $result = $cp->convert(
        { 'factor' => '10', 'from_unit' => 'Celsius', 'to_unit' => 'Celsius', }
    );
    is( $result->{'result'}, '10', 'OK' );
    $result = $cp->convert(
        { 'factor' => '10', 'from_unit' => 'Rankine', 'to_unit' => 'Celsius', }
    );
    is( $result->{'result'}, '-267.594', 'OK' );
    $result = $cp->convert(
        { 'factor' => '10', 'from_unit' => 'Kelvin', 'to_unit' => 'Celsius', }
    );
    is( $result->{'result'}, '-263.15', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '667.778', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '1234', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '412.406', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '960.85', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '-66.111', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '-87', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        { 'factor' => '-87', 'from_unit' => 'Kelvin', 'to_unit' => 'Celsius', }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-7',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '-21.667', 'OK' );
    $result = $cp->convert(
        { 'factor' => '-7', 'from_unit' => 'Celsius', 'to_unit' => 'Celsius', }
    );
    is( $result->{'result'}, '-7', 'OK' );
    $result = $cp->convert(
        { 'factor' => '-7', 'from_unit' => 'Rankine', 'to_unit' => 'Celsius', }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        { 'factor' => '-7', 'from_unit' => 'Kelvin', 'to_unit' => 'Celsius', }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '0',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '-17.778', 'OK' );
    $result = $cp->convert(
        { 'factor' => '0', 'from_unit' => 'Celsius', 'to_unit' => 'Celsius', }
    );
    is( $result->{'result'}, '0', 'OK' );
    $result = $cp->convert(
        { 'factor' => '0', 'from_unit' => 'Rankine', 'to_unit' => 'Celsius', }
    );
    is( $result->{'result'}, '-273.15', 'OK' );
    $result = $cp->convert(
        { 'factor' => '0', 'from_unit' => 'Kelvin', 'to_unit' => 'Celsius', } );
    is( $result->{'result'}, '-273.15', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '10',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '260.928', 'OK' );
    $result = $cp->convert(
        { 'factor' => '10', 'from_unit' => 'Celsius', 'to_unit' => 'Kelvin', }
    );
    is( $result->{'result'}, '283.15', 'OK' );
    $result = $cp->convert(
        { 'factor' => '10', 'from_unit' => 'Kelvin', 'to_unit' => 'Kelvin', } );
    is( $result->{'result'}, '10', 'OK' );
    $result = $cp->convert(
        { 'factor' => '10', 'from_unit' => 'Rankine', 'to_unit' => 'Kelvin', }
    );
    is( $result->{'result'}, '5.556', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '940.928', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '1507.15', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '685.556', 'OK' );
    $result = $cp->convert(
        { 'factor' => '1234', 'from_unit' => 'Kelvin', 'to_unit' => 'Kelvin', }
    );
    is( $result->{'result'}, '1234', 'OK' );
    $result = $cp->convert(
        { 'factor' => '-87', 'from_unit' => 'Rankine', 'to_unit' => 'Kelvin', }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        { 'factor' => '-87', 'from_unit' => 'Kelvin', 'to_unit' => 'Kelvin', }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '207.039', 'OK' );
    $result = $cp->convert(
        { 'factor' => '-87', 'from_unit' => 'Celsius', 'to_unit' => 'Kelvin', }
    );
    is( $result->{'result'}, '186.15', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-7',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '251.483', 'OK' );
    $result = $cp->convert(
        { 'factor' => '-7', 'from_unit' => 'Celsius', 'to_unit' => 'Kelvin', }
    );
    is( $result->{'result'}, '266.15', 'OK' );
    $result = $cp->convert(
        { 'factor' => '-7', 'from_unit' => 'Rankine', 'to_unit' => 'Kelvin', }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        { 'factor' => '-7', 'from_unit' => 'Kelvin', 'to_unit' => 'Kelvin', } );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '0',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '255.372', 'OK' );
    $result = $cp->convert(
        { 'factor' => '0', 'from_unit' => 'Celsius', 'to_unit' => 'Kelvin', } );
    is( $result->{'result'}, '273.15', 'OK' );
    $result = $cp->convert(
        { 'factor' => '0', 'from_unit' => 'Rankine', 'to_unit' => 'Kelvin', } );
    is( $result->{'result'}, '0', 'OK' );

    # bda check this one, should be 0, getting 3.14e-14 ...
    $result = $cp->convert(
        { 'factor' => '0', 'from_unit' => 'Kelvin', 'to_unit' => 'Kelvin', } );
    is( $result->{'result'}, '0', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '10',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '469.67', 'OK' );
    $result = $cp->convert(
        { 'factor' => '10', 'from_unit' => 'Celsius', 'to_unit' => 'Rankine', }
    );
    is( $result->{'result'}, '509.67', 'OK' );
    $result = $cp->convert(
        { 'factor' => '10', 'from_unit' => 'Kelvin', 'to_unit' => 'Rankine', }
    );
    is( $result->{'result'}, '18', 'OK' );
    $result = $cp->convert(
        { 'factor' => '10', 'from_unit' => 'Rankine', 'to_unit' => 'Rankine', }
    );
    is( $result->{'result'}, '10', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '1693.67', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '2712.87', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '1234', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '1234',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '2221.2', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '372.67', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '335.07', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-87',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        { 'factor' => '-87', 'from_unit' => 'Kelvin', 'to_unit' => 'Rankine', }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '-7',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '452.67', 'OK' );
    $result = $cp->convert(
        { 'factor' => '-7', 'from_unit' => 'Celsius', 'to_unit' => 'Rankine', }
    );
    is( $result->{'result'}, '479.07', 'OK' );
    $result = $cp->convert(
        { 'factor' => '-7', 'from_unit' => 'Rankine', 'to_unit' => 'Rankine', }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        { 'factor' => '-7', 'from_unit' => 'Kelvin', 'to_unit' => 'Rankine', }
    );
    is( $result->{'result'}, undef, 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '0',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '459.67', 'OK' );
    $result = $cp->convert(
        { 'factor' => '0', 'from_unit' => 'Celsius', 'to_unit' => 'Rankine', }
    );
    is( $result->{'result'}, '491.67', 'OK' );
    $result = $cp->convert(
        { 'factor' => '0', 'from_unit' => 'Rankine', 'to_unit' => 'Rankine', }
    );
    is( $result->{'result'}, '0', 'OK' );
    $result = $cp->convert(
        { 'factor' => '0', 'from_unit' => 'Kelvin', 'to_unit' => 'Rankine', } );
    is( $result->{'result'}, '0', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '152740.8', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '84582.85', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '152281.13', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Kelvin',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '84856', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '84856', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '46869.072', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '84396.33', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Rankine',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '47142.222', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '153232.47', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '84856', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '152772.8', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Celsius',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '85129.15', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Rankine',
        }
    );
    is( $result->{'result'}, '85315.67', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Celsius',
        }
    );
    is( $result->{'result'}, '47124.444', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Fahrenheit',
        }
    );
    is( $result->{'result'}, '84856', 'OK' );
    $result = $cp->convert(
        {
            'factor'    => '84856',
            'from_unit' => 'Fahrenheit',
            'to_unit'   => 'Kelvin',
        }
    );
    is( $result->{'result'}, '47397.594', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'liter', 'to_unit' => 'cup', } );
    is( $result->{'result'}, '4.227', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'year', 'to_unit' => 'months', } );
    is( $result->{'result'}, '12', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'year', 'to_unit' => 'wk', } );
    is( $result->{'result'}, '52.143', 'OK' );

    $result = $cp->convert(
        { 'factor' => '16', 'from_unit' => 'years', 'to_unit' => 'months', } );
    is( $result->{'result'}, '192', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'day', 'to_unit' => 'yr', } );
    is( $result->{'result'}, '0.003', 'OK' );

    $result = $cp->convert(
        { 'factor' => '5', 'from_unit' => 'oz', 'to_unit' => 'g', } );
    is( $result->{'result'}, '141.747', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'ton', 'to_unit' => 'long ton', } );
    is( $result->{'result'}, '0.893', 'OK' );

    $result = $cp->convert(
        { 'factor' => '158', 'from_unit' => 'ounce', 'to_unit' => 'lbm', } );
    is( $result->{'result'}, '9.875', 'OK' );

    $result = $cp->convert(
        { 'factor' => '0.111', 'from_unit' => 'stone', 'to_unit' => 'pound', }
    );
    is( $result->{'result'}, '1.554', 'OK' );

    $result = $cp->convert(
        { 'factor' => '3', 'from_unit' => 'kilogramme', 'to_unit' => 'pound', }
    );
    is( $result->{'result'}, '6.614', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1.3', 'from_unit' => 'tonnes', 'to_unit' => 'ton', } );
    is( $result->{'result'}, '1.433', 'OK' );

    $result = $cp->convert(
        { 'factor' => '2', 'from_unit' => 'tons', 'to_unit' => 'kg', } );
    is( $result->{'result'}, '1814.372', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'ton', 'to_unit' => 'kilos', } );
    is( $result->{'result'}, '907.186', 'OK' );

    $result = $cp->convert(
        { 'factor' => '3.9', 'from_unit' => 'oz', 'to_unit' => 'grams', } );
    is( $result->{'result'}, '110.563', 'OK' );

    $result = $cp->convert(
        { 'factor' => '2', 'from_unit' => 'miles', 'to_unit' => 'km', } );
    is( $result->{'result'}, '3.219', 'OK' );

    $result = $cp->convert(
        { 'factor' => '5', 'from_unit' => 'feet', 'to_unit' => 'in', } );
    is( $result->{'result'}, '60', 'OK' );

    $result = $cp->convert(
        { 'factor' => '2', 'from_unit' => 'mi', 'to_unit' => 'km', } );
    is( $result->{'result'}, '3.219', 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '0.5',
            'from_unit' => 'nautical mile',
            'to_unit'   => 'klick',
        }
    );
    is( $result->{'result'}, '0.926', 'OK' );

    $result = $cp->convert(
        { 'factor' => '500', 'from_unit' => 'miles', 'to_unit' => 'metres', } );
    is( $result->{'result'}, '804672', 'OK' );

    $result = $cp->convert(
        { 'factor' => '25', 'from_unit' => 'cm', 'to_unit' => 'inches', } );
    is( $result->{'result'}, '9.843', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1760', 'from_unit' => 'yards', 'to_unit' => 'miles', } );
    is( $result->{'result'}, '1', 'OK' );

    $result = $cp->convert(
        { 'factor' => '3520', 'from_unit' => 'yards', 'to_unit' => 'miles', } );
    is( $result->{'result'}, '2', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'stone', 'to_unit' => 'lbs', } );
    is( $result->{'result'}, '14', 'OK' );

    $result = $cp->convert(
        { 'factor' => '30', 'from_unit' => 'cm', 'to_unit' => 'in', } );
    is( $result->{'result'}, '11.811', 'OK' );

    $result = $cp->convert(
        { 'factor' => '36', 'from_unit' => 'months', 'to_unit' => 'years', } );
    is( $result->{'result'}, '3', 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '43200',
            'from_unit' => 'seconds',
            'to_unit'   => 'hours',
        }
    );
    is( $result->{'result'}, '12', 'OK' );

    $result = $cp->convert(
        { 'factor' => '4', 'from_unit' => 'hours', 'to_unit' => 'minutes', } );
    is( $result->{'result'}, '240', 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '5',
            'from_unit' => 'kelvin',
            'to_unit'   => 'fahrenheit',
        }
    );
    is( $result->{'result'}, '-450.67', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'bar', 'to_unit' => 'pascal', } );
    is( $result->{'result'}, '100000', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'kilopascal', 'to_unit' => 'psi', } );
    is( $result->{'result'}, '0.145', 'OK' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'atm', 'to_unit' => 'kpa', } );
    is( $result->{'result'}, '101.325', 'OK' );

    $result = $cp->convert(
        { 'factor' => '5', 'from_unit' => 'yrds', 'to_unit' => 'km', } );
    is( $result->{'result'}, '0.005', 'OK' );

    $result = $cp->convert(
        { 'factor' => '12', 'from_unit' => '"', 'to_unit' => 'cm', } );
    is( $result->{'result'}, '30.48', 'OK' );

    $result = $cp->convert(
        { 'factor' => '25', 'from_unit' => 'inches', 'to_unit' => 'feet', } );
    is( $result->{'result'}, '2.083', 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '42',
            'from_unit' => 'kilowatt hours',
            'to_unit'   => 'joules',
        }
    );
    is( $result->{'result'}, '151200000', 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '2500',
            'from_unit' => 'kcal',
            'to_unit'   => 'tons of tnt',
        }
    );
    is( $result->{'result'}, '0.003', 'OK' );

    $result = $cp->convert(
        { 'factor' => '90', 'from_unit' => 'ps', 'to_unit' => 'watts', } );
    is( $result->{'result'}, '66194.888', 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'gigawatt',
            'to_unit'   => 'horsepower',
        }
    );
    is( $result->{'result'}, '1341022.09', 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '180',
            'from_unit' => 'degrees',
            'to_unit'   => 'radians',
        }
    );
    is( $result->{'result'}, '3.142', 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '270',
            'from_unit' => 'degrees',
            'to_unit'   => 'quadrants',
        }
    );
    is( $result->{'result'}, '3', 'OK' );

    $result = $cp->convert(
        { 'factor' => '180', 'from_unit' => 'degrees', 'to_unit' => 'grads', }
    );
    is( $result->{'result'}, '200', 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '45',
            'from_unit' => 'newtons',
            'to_unit'   => 'pounds force',
        }
    );
    is( $result->{'result'}, '10.116', 'OK' );

    $result = $cp->convert(
        { 'factor' => '8', 'from_unit' => 'poundal', 'to_unit' => 'newtons', }
    );
    is( $result->{'result'}, '1.106', 'OK' );

    $result = $cp->convert(
        { 'factor' => '5', 'from_unit' => 'f', 'to_unit' => 'celsius', } );
    is( $result->{'result'}, '-15', 'OK' );

    $result = $cp->convert(
        { 'factor' => '6^2', 'from_unit' => 'oz', 'to_unit' => 'grams', } );
    is( $result->{'result'}, '1020.582', 'OK' );

    $result = $cp->convert(
        { 'factor' => 'NaN', 'from_unit' => 'oz', 'to_unit' => 'stones', } );
    is( $result->{'result'}, undef, 'OK' );

    $result = $cp->convert(
        { 'factor' => '45x10', 'from_unit' => 'oz', 'to_unit' => 'stones', } );
    is( $result->{'result'}, undef, 'OK' );

    $result = $cp->convert(
        { 'factor' => '-9', 'from_unit' => 'g', 'to_unit' => 'ozs', } );
    is( $result->{'result'}, undef, 'OK' );

    $result = $cp->convert(
        { 'factor' => '5', 'from_unit' => 'oz', 'to_unit' => 'yards', } );
    is( $result->{'result'}, undef, 'OK' );

    $result = $cp->convert(
        { 'factor' => 'Inf', 'from_unit' => 'oz', 'to_unit' => 'stones', } );
    is( $result->{'result'}, undef, 'OK' );

    $result = $cp->convert(
        {
            'factor'    => '-5',
            'from_unit' => 'kelvin',
            'to_unit'   => 'fahrenheit',
        }
    );
    is( $result->{'result'}, undef, 'OK' );

    $result = $cp->convert(
        { 'factor' => 'use', 'from_unit' => 'ton', 'to_unit' => 'stones', } );
    is( $result->{'result'}, undef, 'OK' );

    $result = $cp->convert(
        { 'factor' => 'shoot', 'from_unit' => 'oneself', 'to_unit' => 'foot', }
    );
    is( $result->{'result'}, undef, 'OK' );

    $result = $cp->convert(
        { 'factor' => 'foot', 'from_unit' => 'both', 'to_unit' => 'camps', } );
    is( $result->{'result'}, undef, 'OK' );

    $result = $cp->convert(
        { 'factor' => 'puff', 'from_unit' => 'toke', 'to_unit' => 'kludge', } );
    is( $result->{'result'}, undef, 'OK' );

    $result = $cp->convert(
        { 'factor' => '10', 'from_unit' => 'milligrams', 'to_unit' => 'tons', }
    );
    is( $result->{'result'}, 0, '10 milligrams is 1.1e-08 tons' );

    $result = $cp->convert(
        {
            'factor'    => '10000',
            'from_unit' => 'minutes',
            'to_unit'   => 'microseconds',
        }
    );
    is( $result->{'result'}, '600000000000',
        '10000 minutes is 6e+11 microseconds' );

    $result = $cp->convert(
        { 'factor' => '5', 'from_unit' => 'bytes', 'to_unit' => 'bit', } );
    is( $result->{'result'}, '40', '5 bytes is 40.000 bits' );

    $result = $cp->convert(
        { 'factor' => '5', 'from_unit' => 'GB', 'to_unit' => 'megabyte', } );
    is( $result->{'result'}, '5000', '5 gigabytes is 5000.000 megabytes' );

    $result = $cp->convert(
        { 'factor' => '0.013', 'from_unit' => 'mb', 'to_unit' => 'bits', } );
    is( $result->{'result'}, '104000', '0.013 megabytes is 104000.000 bits' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'exabyte', 'to_unit' => 'pib', } );
    is( $result->{'result'}, '888.178', '1 exabyte is 888.178 pebibytes' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'yb', 'to_unit' => 'yib', } );
    is( $result->{'result'}, '0.827', '1 yottabyte is 0.827 yobibytes' );

    #areas
    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'ha', 'to_unit' => 'acre', } );
    is( $result->{'result'}, '2.471', '1 hectare is ~ 2.471 acres' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'km^2',
            'to_unit'   => 'ha',
            'precision' => $precision,
        }
    );
    is( $result->{'result'}, '100', '1 km^2 is 100 ha' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'cm^2',
            'to_unit'   => 'square inches',
        }
    );
    is( $result->{'result'}, '0.155', '1 cm^2 is ~ 0.155 inches^2' );

    $result = $cp->convert(
        {
            'factor'    => '1254',
            'from_unit' => 'm^2',
            'to_unit'   => 'square miles',
        }
    );
    is( $result->{'result'}, '0', '1254 m^2 is ~ 0.00048417211 miles^2' );

    $result = $cp->convert(
        {
            'factor'    => '1254',
            'from_unit' => 'feet^2',
            'to_unit'   => 'square inches',
        }
    );
    is( $result->{'result'}, '180576.007', '1254 feet^2 is ~ 180576 inch^2' );

    $result = $cp->convert(
        { 'factor' => '1254', 'from_unit' => 'm^2', 'to_unit' => 'sq mi', } );
    is( $result->{'result'}, '0', '1254 m^2 is ~ 0.00048417211 miles^2' );

    $result = $cp->convert(
        {
            'factor'    => '125',
            'from_unit' => 'yards^2',
            'to_unit'   => 'metres^2',
        }
    );
    is( $result->{'result'}, 104.516, '125 yards^2 is ~ 104.516 metres^2' );

    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'ha', 'to_unit' => 'tsubo', } );
    is( $result->{'result'}, 3024.986, '1 hectare is ~ 3025 tsubo' );

    #volumes
    $result = $cp->convert(
        { 'factor' => '1', 'from_unit' => 'pint', 'to_unit' => 'ml', } );
    is( $result->{'result'}, 568.261, '1 fl oz is ~ 568 ml' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'imperial gallon',
            'to_unit'   => 'l',
        }
    );
    is( $result->{'result'}, 4.546, '1 gallon is ~ 4.5 litres' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'imperial gallon',
            'to_unit'   => 'pints',
        }
    );
    is( $result->{'result'}, 8, '1 gallon  = 8 pints' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'us gallon',
            'to_unit'   => 'us quarts',
        }
    );
    is( $result->{'result'}, 4, '1 gallon  = 4 quarts' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'us pints',
            'to_unit'   => 'us fluid ounces',
        }
    );
    is( $result->{'result'}, 16, '1 us pint  = 16 us fluid oz' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'us gallon',
            'to_unit'   => 'us fluid ounces',
        }
    );
    is( $result->{'result'}, 16 * 8, '1 gallon  = 16*8' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'imperial pints',
            'to_unit'   => 'imperial fluid ounces',
        }
    );
    is( $result->{'result'}, 16, '1 imperial pint  = 16 imperial fluid oz' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'imperial gallon',
            'to_unit'   => 'imperial fluid ounces',
        }
    );
    is( $result->{'result'}, 16 * 8, '1 gallon  = 16*8' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'millilitre',
            'to_unit'   => 'imperial fluid ounces',
        }
    );
    is( $result->{'result'}, 0.028, '1 millilitre ~ 0.03 us fl oz' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'millilitre',
            'to_unit'   => 'us cup',
        }
    );
    is( $result->{'result'}, 0.004, '1 millilitre = 0.004 us cups' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'millilitre',
            'to_unit'   => 'metric cup',
        }
    );
    is( $result->{'result'}, 0.004, '1 millilitre = 0.004 metric cups' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'ha',
            'to_unit'   => 'square kilometer',
            'precision' => $precision,
        }
    );
    is( $result->{'result'}, 0.01, '1 hectare is ~ 0.01 square kilometers' );

    $result = $cp->convert(
        {
            'factor'    => '1',
            'from_unit' => 'mile',
            'to_unit'   => 'yards',
            'precision' => $precision,
        }
    );
    is( $result->{'result'}, 1760, '1 mile is 1760 yards' );
}

done_testing();
