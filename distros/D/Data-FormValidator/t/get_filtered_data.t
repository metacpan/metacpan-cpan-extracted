#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Data::FormValidator;
use Data::FormValidator::Constraints qw(FV_eq_with);

# Empty data/empty results; make sure fcn call works fine
access_filtered_data_no_data:
{
  my $results = Data::FormValidator->check( {}, {} );
  my $filtered = $results->get_filtered_data();
  is_deeply( $filtered, {}, 'get_filtered_data works for empty hashref' );
}

# Test to make sure that we can access filtered data and that it looks right.
access_filtered_data:
{
  my $data = {
    'password' => ' foo ',
    'confirm'  => ' foo ',
  };
  my $expect_filtered_data = {
    'password' => 'foo',
    'confirm'  => 'foo',
  };
  my $profile = {
    'required' => [qw( password confirm )],
    'filters'  => 'trim',
  };
  my $results = Data::FormValidator->check( $data, $profile );
  my $filtered = $results->get_filtered_data();
  is_deeply( $filtered, $expect_filtered_data,
    'get_filtered_data returns correct filtered data' );
}

# RT#22589; FV_eq_with uses 'get_filtered_data()'
rt22589:
{
  my $data = {
    'password' => ' foo ',
    'confirm'  => ' foo ',
  };
  my $profile = {
    'required'           => [qw( password confirm )],
    'filters'            => 'trim',
    'constraint_methods' => {
      'confirm' => FV_eq_with('password'),
    },
  };
  my $results = Data::FormValidator->check( $data, $profile );
  ok( $results->valid('password'), 'password valid' );
  ok( $results->valid('confirm'),  'confirm valid' );
}
