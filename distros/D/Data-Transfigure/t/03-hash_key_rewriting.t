#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Transfigure qw(hk_rewrite_cb);

my $t = {
  one           => 1,
  two_three     => 23,
  four_five_six => 456
};

hk_rewrite_cb($t, \&CORE::uc);

is($t, {ONE => 1, TWO_THREE => 23, FOUR_FIVE_SIX => 456}, 'uppercase hash keys');

$t = {
  one => 1,
  two => {
    three_four     => 34,
    five_six_seven => 567
  },
  eight => [{nine => 9, 10 => {eleven_twelve => 1112}}, 13]
};

hk_rewrite_cb($t, \&CORE::uc);

is(
  $t, {
    ONE => 1,
    TWO => {
      THREE_FOUR     => 34,
      FIVE_SIX_SEVEN => 567
    },
    EIGHT => [{NINE => 9, 10 => {ELEVEN_TWELVE => 1112}}, 13]
  },
  'uppercase hash keys - deep'
);

done_testing;
