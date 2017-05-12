use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use Test::Routine::Util;

sub test_spacing {
  my ($val, $exp) = @_;

  $exp =~ s/^  //mg;

  run_tests($val => IniTests => {
    args => {
      spacing => $val,
    },
    sections => [
      # consecutive non-payloads
      Crashin =>
      Spinning =>
      # consecutive payloads
      [Swim => { american => 'love' }],
      [What => Gets => {you => 'off'}],
      # single
      [Suicide => 'Blonde'],
      # single payload with multiple lines
      [Annie => Use => {your => 'telescope', bloodshot => [drop_out => 'the so unknown']}],
      # two non-payloads
      [Hammers => 'Strings'],
      [A => 'Lullaby'],
    ],
    expected_ini => $exp,
  });
}

test_spacing none => <<INI;
  [Crashin]
  [Spinning]
  [Swim]
  american = love
  [Gets / What]
  you = off
  [Blonde / Suicide]
  [Use / Annie]
  bloodshot = drop_out
  bloodshot = the so unknown
  your      = telescope
  [Strings / Hammers]
  [Lullaby / A]
INI

test_spacing all => <<INI;
  [Crashin]

  [Spinning]

  [Swim]
  american = love

  [Gets / What]
  you = off

  [Blonde / Suicide]

  [Use / Annie]
  bloodshot = drop_out
  bloodshot = the so unknown
  your      = telescope

  [Strings / Hammers]

  [Lullaby / A]
INI

test_spacing payload => <<INI;
  [Crashin]
  [Spinning]

  [Swim]
  american = love

  [Gets / What]
  you = off

  [Blonde / Suicide]

  [Use / Annie]
  bloodshot = drop_out
  bloodshot = the so unknown
  your      = telescope

  [Strings / Hammers]
  [Lullaby / A]
INI

done_testing;
