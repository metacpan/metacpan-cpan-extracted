#!/usr/bin/env perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Data::FormValidator;

my %h = ( key => [ ' value1 ', ' value2 ' ] );

# Testing an internal function here, so it's OK if this test starts
# to fail because the API changes
my %out = Data::FormValidator::Results::_get_input_as_hash( {}, \%h );

isnt( $h{key}, $out{key},
  "after copying structure, values should have different memory addresses" );

{
  Data::FormValidator->check(
    \%h,
    {
      required => ['key'],
      filters  => ['trim'],
    } );

  is( $h{key}[0], ' value1 ', "filters shouldn't modify data in arrayrefs" );
}
