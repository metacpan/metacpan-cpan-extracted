#!/usr/bin/env perl
use strict;
use warnings;
use Data::FormValidator;
use Test::More tests => 8;
use lib ( '.', '../t' );

my $input_profile = {
  required    => ['my_zipcode_field'],
  constraints => {
    my_zipcode_field => [
      'zip',
      {
        constraint => '/^406/',
        name       => 'starts_with_406',
      }
    ],
  },
};

my $validator = new Data::FormValidator( { default => $input_profile } );

my $input_hashref = {
  my_zipcode_field => '402015',    # born to lose
};

my ( $valids, $missings, $invalids, $unknowns );

eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hashref, 'default' );
};

ok( !$@, 'survived eval' );

ok( ( grep { ( ref $_ ) eq 'ARRAY' } @$invalids ) );

# Test that the array ref in the invalids array contains three elements,
my @zip_failures;
for (@$invalids)
{
  if ( ref $_ eq 'ARRAY' )
  {
    if ( scalar @$_ == 3 )
    {
      @zip_failures = @$_;

      # This is cheesy, and could be further refactored.
      ok(1);
      last;
    }
  }
}

# Test that the first element of the array is 'my_zipcode_field'
my $t = shift @zip_failures;

ok( $t eq 'my_zipcode_field' );

# Test that the two elements are 'zip' and 'starts_with_406'
ok( eq_set( \@zip_failures, [qw/zip starts_with_406/] ) );

# The next three tests are to confirm that an input field is deleted
# from the valids under the following conditions

# 1. the input field has multiple constraints
# 2. one or more constraint fails

my %data = (
  multiple => 'to fail',

  #multiple => [qw{this multi-value input will fail on the constraint below}],
  single => 'to pass',
);

my %profile = (
  required => [
    qw/
      multiple
      single
      /
  ],
  constraints => {
    multiple => [
      { name => 'constraint_1', constraint => qr/\w/ },    # pass
      { name => 'constraint_2', constraint => qr/\d/ },    # force fail
    ],
  },
);

my $results = Data::FormValidator->check( \%data, \%profile );

ok( !$results->valid('multiple'), "expect 'multiple' not to appear in valid" );
is_deeply( $results->invalid('multiple'),
  ['constraint_2'], "list of failed constraints for 'multiple'" );
is( $results->valid('single'), 'to pass', "single is valid" );
