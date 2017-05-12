#!/usr/bin/env perl
use strict;
use warnings;
use Test::More qw/no_plan/;
use Data::FormValidator;

my $input_profile = {
  required    => [qw( number_field )],
  constraints => {
    number_field => {
      name       => 'number',
      constraint => qr/^\d+$/,
    } } };

my $input_hashref = { number_field => 0, };

my $results;
eval {
  $results = Data::FormValidator->check( $input_hashref, $input_profile );
};

ok( !$@, 'survived validate' );

is( $results->valid->{number_field}, 0,
  'using 0 in a constraint regexp works' );
