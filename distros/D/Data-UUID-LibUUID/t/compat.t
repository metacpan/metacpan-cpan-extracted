#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Data::UUID::LibUUID::DataUUIDCompat';

my $ug = Data::UUID::LibUUID::DataUUIDCompat->new;

isa_ok( $ug, "Data::UUID" );

can_ok( $ug, $_ ) for qw(
    compare
    create
    create_b64
    create_bin
    create_from_name
    create_from_name_b64
    create_from_name_bin
    create_from_name_hex
    create_from_name_str
    create_hex
    create_str
    from_b64string
    from_hexstring
    from_string
    new
    to_b64string
    to_hexstring
    to_string
);

# from Data::UUID's basic.t

ok(my $uuid1 = $ug->create(),             "create a new uuid");
ok(length($uuid1) eq 16, 'correct length of uuid');
ok(my $uuid2 = $ug->to_hexstring($uuid1), "hexstringify it");
ok(my $uuid3 = $ug->from_string($uuid2),  "create a uuid from that string");
is($ug->compare($uuid1, $uuid3), 0,       "they compare as equal");

ok(my $uuid4 = $ug->to_b64string($uuid1), "get base64 string of original uuid");
ok(my $uuid5 = $ug->to_b64string($uuid3), "get base64 string of from_string");
is($uuid4, $uuid5,                        "those base64 strings are equal");

ok(my $uuid6 = $ug->from_b64string($uuid5), "make uuid from the base64 string");
is($ug->compare($uuid6,$uuid1), 0,          "and it compares at equal, too");

# some basic "all unique" tests
my $HOW_MANY = 15;

my %uuids;
$uuids{ $ug->to_b64string($ug->create) } = 1 for 1 .. ($HOW_MANY);

is(
  scalar keys %uuids,
  $HOW_MANY,
  "we get all unique UUIDs",
);

for my $uuid (keys %uuids) {
  ok(
    index($uuid, "\n") == -1,
    "no carriage return in base64 version",
  );
}


