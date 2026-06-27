#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 1 + 4*2 + 3*2 + 5*2 + 9*2 + 8*2 + 4*2*2 + 7*2;

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

my %language_vectors = (
    af            => '4fc82126-3ead-594a-9846-a0f2db006347',
    de            => '6895ad9b-2ba6-5933-8455-968aa781a88b',
    en            => 'c50134ca-0a32-5c5c-833c-2686043c0b3f',
    nl            => 'da816af7-e49b-5406-b712-8dc96d968541',
    'de-de'       => '1efa0416-9478-55c2-91ef-3895e0403612',
    'en-au'       => '3e90523c-14b6-5d72-8004-4f4575e5a9ac',
    'en-gb'       => '202a80e8-a188-5e2d-9972-9733bf12a4ce',
    'en-zw'       => 'ec524f05-a786-58e2-a453-a21922f6a8d7',
);

my @multiplicity_vectors = (
    [[total     => 0] => '535af734-8197-51fa-a61b-295d166595e7'],
    [[total     => 1] => 'a6bdec44-2d17-58f0-91ae-1a9527c6743a'],
    [[total     => 2] => '1ce04668-42af-5c16-b852-9da3371b167c'],
    [[total     => 3] => '9fdf665e-dc1f-5b6d-9f3f-f4257f3a70d3'],
    [[minimum   => 0] => '59922082-1cdd-5bec-a018-313c17680dab'],
    [[minimum   => 1] => 'd0477113-6126-5378-9084-8a2044151ad6'],
    [[minimum   => 2] => '9d092e53-23f3-59b0-8df7-b6be09db73d6'],
    [[minimum   => 3] => '67f5f8f6-95fe-52e2-9eaa-056596fcadb5'],
);

my @unit_vectors = (
    # Generic:
    [{A =>  1}                => 'efbba5cc-fb18-5328-9536-36dc88657842'],
    [{A =>  1, prefix => 'k'} => 'af9fc575-297e-5ec7-8c4f-e54ed074c908'],
    [{s => -1, prefix => 'M'} => '4101d8ea-292a-5b05-9dba-78d22f1e8be5'],
    [{s => -1, prefix => 'm'} => 'd1baf28e-9393-5f5a-b49a-d9384c5463c3'],
    [{s => -2, m =>  2, kg =>  1, prefix => 'G'} => '6c03ede4-eecd-5c51-99e4-d5c27bbe88f2'],

    # Some special cases:
    [{J =>  1, prefix => 'G'} => '6c03ede4-eecd-5c51-99e4-d5c27bbe88f2'],
    [{2 => 1} => '73415b5a-31fb-5b5a-bb82-8ea5eb3b12f7'],
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

foreach my $date (sort keys %language_vectors) {
    my $identifier = Data::Identifier::Generate->language($date);
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, $language_vectors{$date}, 'Matching UUID for '.$date);
}

foreach my $vector (@multiplicity_vectors) {
    my $identifier = Data::Identifier::Generate->multiplicity(@{$vector->[0]});
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, $vector->[-1], 'Matching UUID for '.$vector->[-1]);
}

foreach my $vector (@unit_vectors) {
    my $identifier = Data::Identifier::Generate->unit($vector->[0]);
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, $vector->[-1], 'Matching UUID for '.$vector->[-1]);
}

exit 0;
