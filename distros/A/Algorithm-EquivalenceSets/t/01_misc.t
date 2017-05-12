#!/usr/bin/env perl
use warnings;
use strict;
use Algorithm::EquivalenceSets;
use Test::More;
use YAML;
my $tests = Load(<<EOYAML);
- data:
    -
      - a
      - 1
      - 2
  expect:
    - 12a
#
- data:
    -
      - a
      - 1
      - 2
    -
      - b
      - 3
      - 4
  expect:
    - 12a
    - 34b
#
- data:
    -
      - a
      - 1
      - 2
    -
      - b
      - 3
      - 4
    -
      - a
      - 3
  expect:
    - 1234ab
#
- data:
    -
      - a
      - 1
      - 2
    -
      - b
      - 1
      - 3
  expect:
    - 123ab
#
- data:
    -
      - a
      - 1
      - 2
    -
      - b
      - 3
      - 4
    -
      - c
      - 5
    -
      - d
      - 1
      - 6
    -
      - e
      - 3
      - 6
  expect:
    - 5c
    - 12346abde
#
- data:
    -
      - a
      - 1
      - 2
    -
      - b
      - 3
      - 4
    -
      - c
      - 5
    -
      - d
      - 1
      - 6
    -
      - e
      - 3
      - 6
    -
      - f
      - 5
      - 7
  expect:
    - 57cf
    - 12346abde
EOYAML
plan tests => scalar @$tests;
for my $test (@$tests) {
    my $sep = equivalence_sets($test->{data});

    # transform the result slightly for easier testing
    $_ = join '' => sort @$_ for @$sep;
    ok(eq_set($sep, $test->{expect}), join ' - ' => @{ $test->{expect} });
}
