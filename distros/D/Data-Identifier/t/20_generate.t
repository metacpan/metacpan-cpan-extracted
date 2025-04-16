#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 1 + 4*2 + 3*2 + 5*2 + 9*2;

use_ok('Data::Identifier::Generate');

my %int_vectors = (
    -1 => 'a7872dea-8912-5c23-b243-567c60e8bd1a',
     0 => 'dd8e13d3-4b0f-5698-9afa-acf037584b20',
     1 => 'bd27669b-201e-51ed-9eb8-774ba7fef7ad',
     2 => '73415b5a-31fb-5b5a-bb82-8ea5eb3b12f7',
);

my %character_vectors = (
    'A'           => '51ae7e0b-a182-5f47-a766-dd5837a7cd8e',
    "\N{U+1F981}" => '5adc5592-19ba-5519-85f1-0add86316b05',
    "\0"          => 'c3d41fce-2e6c-5928-8f5e-0939d1c8bfe2',
);

my %colour_vectors = (
    '#000000'     => '6a1338b8-517f-5b45-9c17-37cda5d7146d',
    '#ffffff'     => 'feb62789-9ad6-5302-9a17-9de4f2f44d5c',
    '#FFFFFF'     => 'feb62789-9ad6-5302-9a17-9de4f2f44d5c',
    '#FfFfFf'     => 'feb62789-9ad6-5302-9a17-9de4f2f44d5c',
    '#0000FF'     => 'd9739512-b882-56b8-a971-7f1a71afe02c',
);

my %date_vectors = (
    '2024-04-13Z' => 'f3e72374-dde4-5056-b125-badb829cec0a',
    '2024-04Z'    => '8bdbf1e5-f39c-54ea-916c-9523c140961c',
    '2024Z'       => '22c02bd0-4428-5bb1-bfd8-ed1a59a32553',
    '1970-01-01Z' => 'e49c8067-d293-5f1a-bbeb-00c99977f610',
    0             => 'e49c8067-d293-5f1a-bbeb-00c99977f610',
    '2038-01-19Z' => '51a431e8-4971-5e4e-9581-063280f42029',
    2147483647    => '51a431e8-4971-5e4e-9581-063280f42029',
    '1901-12-13Z' => '4195ae1b-66f4-558e-bde3-055909b43f13',
    -2147483647   => '4195ae1b-66f4-558e-bde3-055909b43f13',
);

foreach my $int (sort keys %int_vectors) {
    my $identifier = Data::Identifier::Generate->integer($int);
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, $int_vectors{$int}, 'Matching UUID for '.$int);
}

foreach my $char (sort keys %character_vectors) {
    my $identifier = Data::Identifier::Generate->unicode_character(raw => $char);
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, $character_vectors{$char}, 'Matching UUID for '.ord($char));
}

foreach my $colour (sort keys %colour_vectors) {
    my $identifier = Data::Identifier::Generate->colour($colour);
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, $colour_vectors{$colour}, 'Matching UUID for '.$colour);
}

foreach my $date (sort keys %date_vectors) {
    my $identifier = Data::Identifier::Generate->date($date);
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, $date_vectors{$date}, 'Matching UUID for '.$date);
}

exit 0;
