#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Data::ULID qw/ulid binary_ulid ulid_date/;

plan skip_all => 'these tests require DateTime module'
    unless Data::ULID::HAS_DATETIME;

require DateTime;
my $old_ulid = '01B3Z3A7GQ6627FZPDQHQP87PM';
my $fixed_t = 1481797018.267;
my $fixed_dt = DateTime->from_epoch(epoch=>$fixed_t);

my $ulid = ulid();
my $b_ulid = binary_ulid($ulid);

my $dt = ulid_date($ulid);

ok($dt->isa("DateTime"),
   "ulid_date() yields DateTime");

my $b_dt = ulid_date($b_ulid);

ok("$dt" eq "$b_dt",
   "Canonical and binary ULID yield same DateTime");

my $o_dt = ulid_date($old_ulid);

is($o_dt->hires_epoch, 1481733643.799,
   "Old ULID timestamp has correct hires_epoch");

my $f_ulid = ulid($fixed_dt);

ok(substr($f_ulid, 0, 10) eq '01B40ZR8MV',
   "ULID from fixed DateTime works as expected");

ok(ulid_date($f_ulid)->hires_epoch == $fixed_t,
   "ULID from fixed DateTime has correct hires_epoch");

done_testing;

