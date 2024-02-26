#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Transfigure;

my $t1 = Data::Transfigure->bare();
$t1->add_transfigurators(
  qw(
    Data::Transfigure::HashKeys::CapitalizedIDSuffix
    Data::Transfigure::HashKeys::CamelCase
    )
);

my $h = {
  id      => 1,
  time    => '03:06',
  type_id => 6
};

is(
  $t1->transfigure($h), {
    id     => 1,
    time   => '03:06',
    typeId => 6,
  },
  'wrong-order registration'
);    # registration order matters!

my $t2 = Data::Transfigure->bare();
$t2->add_transfigurators(
  qw(
    Data::Transfigure::HashKeys::CamelCase
    Data::Transfigure::HashKeys::CapitalizedIDSuffix
    )
);

is(
  $t2->transfigure($h), {
    id     => 1,
    time   => '03:06',
    typeID => 6,
  },
  'correct-order registration'
);

done_testing;
