#!/usr/bin/env perl
use strict;
use warnings;
use lib ( '.', '../t', 't/' );
use Test::More tests => 8;
use Data::FormValidator;

my $input_profile = {
  validator_packages => 'ValidatorPackagesTest1',
  required           => [ 'required_1', 'required_2', 'required_3' ],
  constraints        => {
    required_1 => 'single_validator_success_expected',
    required_2 => 'single_validator_failure_expected',
  },
  field_filters => {
    required_3 => 'single_filter_remove_whitespace',
  },
};

my $validator = new Data::FormValidator( { default => $input_profile } );

my $input_hashref = {
  required_1 => 123,
  required_2 => 'testing',
  required_3 => '  has whitespace  ',
};

my ( $valids, $missings, $invalids, $unknowns );

eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hashref, 'default' );
};
ok( not $@ )
  or diag "eval error: $@";

ok( defined $valids->{required_1} );

# Test to make sure that the field failed imported validator
ok( grep /required_2/, @$invalids );

ok( defined $valids->{required_3} );

is( $valids->{required_3}, 'has whitespace' );

#### Now test importing from multiple packages

$input_profile = {
  validator_packages => [ 'ValidatorPackagesTest1', 'ValidatorPackagesTest2' ],
  required           => [ 'required_1',             'required_2' ],
  constraints        => {
    required_1 => 'single_validator_success_expected',
    required_2 => 'multi_validator_success_expected',
  },
};

$validator = new Data::FormValidator( { default => $input_profile } );

$input_hashref = {
  required_1 => 123,
  required_2 => 'testing',
};

eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hashref, 'default' );
};

ok( defined $valids->{required_1} );

ok( defined $valids->{required_2} );

# Now test calling 'validate' as a class method
use Data::FormValidator;

eval {
  my ( $valid, $missing, $invalid ) = Data::FormValidator->validate(
    $input_hashref,
    {
      required           => [qw/required_1/],
      validator_packages => 'Data::FormValidator',
    } );
};
ok( not $@ );
