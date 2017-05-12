#!perl
use strict;
use Test::More tests => 4;
BEGIN { use_ok('Data::Sorting'); }
require 't/sort_tests.pl';

test_sort_cases (
  {
    values => [ qw( 14 9x foo foo12 foo12a Foo12a foo12z foo13a fooa Foolio foolio ) ],
    sorted => [ -compare=>'natural' ],
    okvals => [
      [ qw( 14 9x foo foo12 foo12a Foo12a foo12z foo13a fooa Foolio foolio ) ],
      [ qw( 14 9x foo foo12 Foo12a foo12a foo12z foo13a fooa Foolio foolio ) ],
      [ qw( 14 9x foo foo12 foo12a Foo12a foo12z foo13a fooa foolio Foolio ) ],
      [ qw( 14 9x foo foo12 Foo12a foo12a foo12z foo13a fooa foolio Foolio ) ],
    ],
  },
  {
    values => [ '', '021', '1', '1', '1.1', '1.1.A.3.7', '1.5', '12', '123', '13', '2', '27', 'Three pennies', 'Three penny', 'half-bushel', 'potato', 'three', 'three penny', 'thrice scorned', 'thrice-scorned', 'twice' ],
    sorted => [ -compare=>'bytewise' ],
  },
  {
    values => [ '', '1.0', '1', '1.1', '1.5', '2', '12', '13', '021', '27', '123', '1.1.A.3.7', 'half-bushel', 'potato', 'three', 'Three pennies', 'three penny', 'Three penny', 'thrice scorned', 'thrice-scorned', 'twice' ],
    sorted => [ -compare=>'natural' ],
    okvals => [
      [ '', '1.0', '1', '1.1', '1.5', '2', '12', '13', '021', '27', '123', '1.1.A.3.7', 'half-bushel', 'potato', 'three', 'Three pennies', 'three penny', 'Three penny', 'thrice scorned', 'thrice-scorned', 'twice' ],
      [ '', '1.0', '1', '1.1', '1.5', '2', '12', '13', '021', '27', '123', '1.1.A.3.7', 'half-bushel', 'potato', 'three', 'Three pennies', 'three penny', 'Three penny', 'thrice-scorned', 'thrice scorned', 'twice' ],
      [ '', '1.0', '1', '1.1', '1.5', '2', '12', '13', '021', '27', '123', '1.1.A.3.7', 'half-bushel', 'potato', 'three', 'Three pennies', 'Three penny', 'three penny', 'thrice scorned', 'thrice-scorned', 'twice' ],
      [ '', '1.0', '1', '1.1', '1.5', '2', '12', '13', '021', '27', '123', '1.1.A.3.7', 'half-bushel', 'potato', 'three', 'Three pennies', 'Three penny', 'three penny', 'thrice-scorned', 'thrice scorned', 'twice' ],
      [ '', '1', '1.0', '1.1', '1.5', '2', '12', '13', '021', '27', '123', '1.1.A.3.7', 'half-bushel', 'potato', 'three', 'Three pennies', 'three penny', 'Three penny', 'thrice scorned', 'thrice-scorned', 'twice' ],
      [ '', '1', '1.0', '1.1', '1.5', '2', '12', '13', '021', '27', '123', '1.1.A.3.7', 'half-bushel', 'potato', 'three', 'Three pennies', 'three penny', 'Three penny', 'thrice-scorned', 'thrice scorned', 'twice' ],
      [ '', '1', '1.0', '1.1', '1.5', '2', '12', '13', '021', '27', '123', '1.1.A.3.7', 'half-bushel', 'potato', 'three', 'Three pennies', 'Three penny', 'three penny', 'thrice scorned', 'thrice-scorned', 'twice' ],
      [ '', '1', '1.0', '1.1', '1.5', '2', '12', '13', '021', '27', '123', '1.1.A.3.7', 'half-bushel', 'potato', 'three', 'Three pennies', 'Three penny', 'three penny', 'thrice-scorned', 'thrice scorned', 'twice' ],
    ],
  },
);
