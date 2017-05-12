#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::FormValidator;
use Data::FormValidator::Constraints qw(:closures);

# Test FV_num_values and FV_num_values_between

my $results = Data::FormValidator->check( {
    num_values_pass         => [qw(a b)],
    num_values_fail         => [qw(a b)],
    num_values_between_pass => [qw(a)],
    num_values_between_fail => [qw(a b)],
  },
  {
    optional_regexp    => qr/.*/,
    constraint_methods => {
      num_values_pass         => FV_num_values(2),
      num_values_fail         => FV_num_values(1),
      num_values_between_pass => FV_num_values_between( 1, 2 ),
      num_values_between_fail => FV_num_values_between( 3, 4 ),
    } } );

my $valid = $results->valid;
ok( $valid->{num_values_pass},         'FV_num_values pass' );
ok( $valid->{num_values_between_pass}, 'FV_num_values_between pass' );

my $invalid = $results->invalid;
ok( $invalid->{num_values_fail},
  'FV_num_values fail - one value requested, two found' );
ok( $invalid->{num_values_between_fail}, 'FV_num_values_between fail' );

done_testing();
