#!perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Colon::Config;

my $data = <<'EOS';
fruits:apple:banana:orange
veggies:beet:corn:kale
EOS

is Colon::Config::read($data), [
    fruits  => 'apple:banana:orange',
    veggies => 'beet:corn:kale',
];

is Colon::Config::read( $data, 0 ), Colon::Config::read($data);

is Colon::Config::read( $data, 1 ), [
    fruits  => 'apple',
    veggies => 'beet',
];

is Colon::Config::read( $data, 2 ), [
    fruits  => 'banana',
    veggies => 'corn',
];

is Colon::Config::read( $data, 99 ), [
    fruits  => undef,
    veggies => undef,
];

done_testing;
