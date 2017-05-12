#!/usr/bin/env perl

use DateTime;
use Test::More tests => 15;

use_ok('Data::ULID', qw/ulid binary_ulid ulid_date uuid_to_ulid ulid_to_uuid/);

my $b32_re = qr/^[0123456789ABCDEFGHJKMNPQRSTVWXYZ]*$/;
my $old_ulid = '01B3Z3A7GQ6627FZPDQHQP87PM';
my $old_ulid_bin = "\x01\x58\xfe\x35\x1e\x17\x31\x84\x77\xfe\xcd\xbc\x6f\x64\x1e\xd4";
my $fixed_t = 1481797018.267;
my $fixed_dt = DateTime->from_epoch(epoch=>$fixed_t);
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

ok(length($b_ulid) == 16,
   "Length of binary ULID is 16");

my $ulid2 = ulid($b_ulid);

ok($ulid eq $ulid2,
   "Converting back from binary yields same string");

my $dt = ulid_date($ulid);

ok($dt->isa("DateTime"),
   "ulid_date() yields DateTime");

my $b_dt = ulid_date($b_ulid);

ok("$dt" eq "$b_dt",
   "Canonical and binary ULID yield same DateTime");

my $o_dt = ulid_date($old_ulid);

ok($o_dt->hires_epoch == 1481733643.799,
   "Old ULID timestamp has correct hires_epoch");

my $ob_ulid = binary_ulid($old_ulid);

ok($ob_ulid eq $old_ulid_bin,
   "Binary old ULID is correct");

my $f_ulid = ulid($fixed_dt);

ok(substr($f_ulid, 0, 10) eq '01B40ZR8MV',
   "ULID from fixed DateTime works as expected");

ok(ulid_date($f_ulid)->hires_epoch == $fixed_t,
   "ULID from fixed DateTime has correct hires_epoch");

ok(uuid_to_ulid($uuid_str_v1) eq $ulid_from_uuid_v1,
   "UUID v1 converts to ULID as expected");

ok(uuid_to_ulid($uuid_str_v5) eq $ulid_from_uuid_v5,
   "UUID v5 converts to ULID as expected");

ok(ulid_to_uuid($old_ulid) eq $uuid_from_old_ulid,
   "ULID converts to expected UUID");

ok(uuid_to_ulid($uuid_from_old_ulid) eq $old_ulid,
   "Back-and-forth UUID<=>ULID conversion works");
