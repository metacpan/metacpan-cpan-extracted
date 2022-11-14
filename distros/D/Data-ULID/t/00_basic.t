#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok('Data::ULID', qw/ulid binary_ulid uuid_to_ulid ulid_to_uuid/);

my $b32_re = qr/^[0123456789ABCDEFGHJKMNPQRSTVWXYZ]*$/;
my $small_ulid = '00000000010000000000000001';
my $small_ulid_bin = "\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01";
my $old_ulid = '01B3Z3A7GQ6627FZPDQHQP87PM';
my $old_ulid_bin = "\x01\x58\xfe\x35\x1e\x17\x31\x84\x77\xfe\xcd\xbc\x6f\x64\x1e\xd4";
my $uuid_str_v1 = '34ca497f-c905-11e6-b28b-fa93ccfbd751';
my $uuid_str_v5 = '398e7281-ad9a-5c50-bcb0-f9b94da0aebb';
my $ulid_from_uuid_v1 = '1MS94QZJ8527KB52ZTJF6FQNTH';
my $ulid_from_uuid_v5 = '1SHSS83BCTBH8BSC7SQ56T1BNV';
my $uuid_from_old_ulid = '0158fe35-1e17-3184-77fe-cdbc6f641ed4';

my $ulid = ulid();

ok(length($ulid) == 26,
   "Length of canonical ULID is 26");

ok($ulid =~ $b32_re,
   "ULID is valid base32 (Crockford variant)");

my $b_ulid = binary_ulid($ulid);

is(length($b_ulid), 16,
   "Length of binary ULID is 16");
if (length($b_ulid) != 16) {
    use Data::Dumper; die Dumper(unpack 'H*', $b_ulid);
}

my $ulid2 = ulid($b_ulid);

is($ulid, $ulid2,
   "Converting back from binary yields same string");

my $ob_ulid = binary_ulid($old_ulid);

ok($ob_ulid eq $old_ulid_bin,
   "Binary old ULID is correct");

ok(uuid_to_ulid($uuid_str_v1) eq $ulid_from_uuid_v1,
   "UUID v1 converts to ULID as expected");

ok(uuid_to_ulid($uuid_str_v5) eq $ulid_from_uuid_v5,
   "UUID v5 converts to ULID as expected");

ok(ulid_to_uuid($old_ulid) eq $uuid_from_old_ulid,
   "ULID converts to expected UUID");

ok(uuid_to_ulid($uuid_from_old_ulid) eq $old_ulid,
   "Back-and-forth UUID<=>ULID conversion works");

is ulid($small_ulid_bin), $small_ulid, 'small ulid conversion ok';
is ulid($small_ulid), $small_ulid, 'small ulid conversion ok';
is unpack('H*', binary_ulid($small_ulid)), unpack('H*', $small_ulid_bin), 'small binary ulid conversion ok';
is binary_ulid($small_ulid_bin), $small_ulid_bin, 'small binary ulid conversion ok';

done_testing;

