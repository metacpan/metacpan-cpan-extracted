#!perl

use Test::More;

eval "use Test::Kwalitee";
plan skip_all => "Test::Kwalitee required for testing kwalitee"
  if $@;

