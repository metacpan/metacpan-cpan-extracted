#!/usr/bin/env perl
#
# Copyright 2008-2010 Tim Rayner
# 
# This file is part of Bio::MAGETAB.
# 
# Bio::MAGETAB is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
# 
# Bio::MAGETAB is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Bio::MAGETAB.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id: CommonTests.pm 333 2010-06-02 16:41:31Z tfrayner $

use strict;
use warnings;

package CommonTests;

use Test::More;
use Test::Exception;
use Storable qw(dclone);

use base qw(Exporter);
our @EXPORT_OK = qw(test_class test_methods test_parse check_term);

sub instantiate {

    my ( $class, $options ) = @_;

    my $obj = $class->new( %{ $options } );

    return $obj;
}

sub test_required_arg_instantiation {

    my ( $class, $required ) = @_;

    my @attr_pairs;
    while ( my ( $key, $value ) = each %{ $required } ) {
        push @attr_pairs, [ $key, $value ];
    }

    foreach my $index ( 0 .. $#attr_pairs ) {
        my @opts = @attr_pairs;
        splice( @opts, $index, 1 );
        my %attr = map { @{$_} } @opts;
        dies_ok( sub { instantiate( $class, \%attr ) },
                 qq{instantiation lacking required attribute "$attr_pairs[$index][0]" fails} );
    }

    return;
}

sub test_instantiation {

    # Test object instantiation under a number of conditions.
    my ( $class, $required, $optional, $bad ) = @_;

    my $obj;

    if ( scalar grep { defined $_ } values %$required ) {

        # Required attributes not set; should fail.
        dies_ok(  sub { $obj = instantiate( $class, $optional ) },
                  "instantiation with only optional args fails" );
    }
    else {

        # No required attributes, so this should pass.
        lives_ok( sub { $obj = instantiate( $class, $optional ) },
                  "instantiation with only optional args succeeds" );
    }

    # Attributes with bad data types; should fail.
    dies_ok(  sub { $obj = instantiate( $class, $bad ) },
              "instantiation with bad args fails" );

    # Test instantiation with $required minus each attribute, one at a
    # time, to confirm that they're really required.
    test_required_arg_instantiation( $class, $required );

    # Required attributes only; should pass.
    lives_ok( sub { $obj = instantiate( $class, $required ) },
              "instantiation with all required args succeeds" );

    # Check predicate method behaviour - before opt attr setting.
    while ( my ( $key, $value ) = each %{ $optional } ) {
        my $predicate = "has_$key";
        ok( ! $obj->$predicate, qq{and optional "$key" attribute predicate method agrees} );
    }

    # Required attributes with an unrecognised impostor; should fail.
    my %with_unrecognised = ( 'this_is_not_a_recognised_attribute' => 1, %{ $required } );
    dies_ok( sub { $obj = instantiate( $class, \%with_unrecognised ) },
              "instantiation with an unrecognised arg fails" );

    # Construct a full instance as our return value.
    my $all = { %{ $optional }, %{ $required } };
    lives_ok( sub { $obj = instantiate( $class, $all      ) },
              "instantiation with all required and optional args succeeds" );

    # Check our fully-constructed object.
    ok( defined $obj,        'and returns an object' );
    ok( $obj->isa( $class ), 'of the correct class' );
    while ( my ( $key, $value ) = each %{ $all } ) {
        my $getter = "get_$key";
        is( $obj->$getter, $value, qq{with the correct "$key" attribute} );
    }
    ok( ! defined $obj->get_ClassContainer(), 'and no container object set' );

    # Check predicate method behaviour - after opt attr setting.
    while ( my ( $key, $value ) = each %{ $optional } ) {
        my $predicate = "has_$key";
        ok( $obj->$predicate, qq{and optional "$key" attribute predicate method agrees} );
    }

    return $obj;
}

sub test_update {

    my ( $obj, $required, $optional, $bad, $secondary ) = @_;

    # Check that updates work as we expect; correct update values first.
    while ( my ( $key, $value ) = each %{ $secondary } ) {
        my $setter = "set_$key";
        lives_ok( sub { $obj->$setter( $value ) }, qq{good "$key" attribute update succeeds} );
        my $getter = "get_$key";
        is( $obj->$getter, $value, 'and sets correct value' );
    }

    # Bad values next.
    while ( my ( $key, $value ) = each %{ $bad } ) {
        my $setter = "set_$key";
        dies_ok( sub { $obj->$setter( $value ) }, qq{bad "$key" attribute update fails} );
    }

    # Update with null values. Required attributes should fail.
    while ( my ( $key, $value ) = each %{ $required } ) {

        # In principle this should fail because the attributes are
        # required. In practice it's more likely they fail because we
        # simply don't provide a "clearer" method for such
        # attributes. Either way, success is bad.
        my $clearer = "clear_$key";
        dies_ok( sub { $obj->$clearer }, qq{clearing required "$key" attribute fails} );
    }
    
    # Optional attributes should be nullable.
    while ( my ( $key, $value ) = each %{ $optional } ) {

        # Clear the key
        my $clearer = "clear_$key";
        ok( $obj->can($clearer), qq{object can clear optional attribute "$key"} );
        lives_ok( sub { $obj->$clearer }, qq{clearing optional "$key" attribute succeeds} );

        # Check the value.
        my $getter = "get_$key";
        is( $obj->$getter, undef, 'and sets undef value' );

        # Check predicate method behaviour - after opt attr clearing.
        my $predicate = "has_$key";
        ok( ! $obj->$predicate, qq{and optional "$key" attribute predicate method agrees} );
    }

    return;
}

sub test_class {

    # Main entry point for the tests in this module.
    my ( $class, $required, $optional, $bad, $secondary ) = @_;

    my $instance = test_instantiation(
        $class,
        $required,
        $optional,
        $bad,
    );

    my $instance2 = dclone( $instance );

    test_update(
        $instance2,
        $required,
        $optional,
        $bad,
        $secondary,
    );

    # This needs to be a valid instance; further tests may be run.
    return $instance;
}

sub test_methods {

    my ( $class, $expected ) = @_;

    foreach my $method ( @{ $expected } ) {
        ok( $class->can( $method ), "$class can $method" );
    }

    return;
}

sub test_parse {

    my ( $reader ) = @_;

    $reader->parse();

    return $reader->get_magetab_object();
}

sub check_term {

    my ( $cat, $val, $attr, $obj, $ts, $builder ) = @_;

    my $method = "get_$attr";

    my $ct;
    lives_ok( sub { $ct = $builder->get_controlled_term({
        category   => $cat,
        value      => $val,
        termSource => $ts,
    }) }, "Builder returns a $cat term" );
    is( $ct->get_termSource(), $ts, 'with the correct termSource' );
    is_deeply( $obj->$method(), $ct, "$attr set correctly" );

    return;
}

1;
