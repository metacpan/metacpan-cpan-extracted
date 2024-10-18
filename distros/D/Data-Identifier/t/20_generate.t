#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 1 + 4*2 + 9*2;

use_ok('Data::Identifier::Generate');

my %int_vectors = (
    -1 => 'a7872dea-8912-5c23-b243-567c60e8bd1a',
     0 => 'dd8e13d3-4b0f-5698-9afa-acf037584b20',
     1 => 'bd27669b-201e-51ed-9eb8-774ba7fef7ad',
     2 => '73415b5a-31fb-5b5a-bb82-8ea5eb3b12f7',
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

foreach my $date (sort keys %date_vectors) {
    my $identifier = Data::Identifier::Generate->date($date);
    isa_ok($identifier, 'Data::Identifier');
    is($identifier->uuid, $date_vectors{$date}, 'Matching UUID for '.$date);
}

exit 0;
