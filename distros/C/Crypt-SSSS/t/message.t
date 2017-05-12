#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok 'Crypt::SSSS::Message';
my $m = new_ok 'Crypt::SSSS::Message', [p => 257];

$m->push_data(0xf6);
$m->push_data(0x00);
$m->push_data(0x101);

is $m->get_p, 257;
is_deeply $m->get_data, [0xf6, 0x00, 0x101];
is_deeply [unpack 'C*', $m->binary], [0x7b, 0x00, 0x20, 0x20];

$m = Crypt::SSSS::Message->build_from_binary($m->get_p, $m->binary);

isa_ok $m, 'Crypt::SSSS::Message';
is_deeply $m->get_data, [0xf6, 0x00, 0x101];

$m = new_ok 'Crypt::SSSS::Message', [p => 13];
$m->push_data(0x00);
$m->push_data(0x01);
$m->push_data(0x0a);
$m->push_data(0x01);
is_deeply $m->get_data, [0x00, 0x01, 0x0a, 0x01];
is_deeply [unpack 'C*', $m->binary], [0x01, 0xa1];
is_deeply Crypt::SSSS::Message->build_from_binary($m->get_p, $m->binary)
  ->get_data,
  [0x00, 0x01, 0x0a, 0x01];

$m = new_ok 'Crypt::SSSS::Message', [p => 65537];
$m->push_data(0x8000);
$m->push_data(0xf001);
is_deeply Crypt::SSSS::Message->build_from_binary($m->get_p, $m->binary)
  ->get_data,
  [0x8000, 0xf001], 'P=65537';

$m = new_ok 'Crypt::SSSS::Message', [p => 4294967311];
$m->push_data(0xffffffff);
$m->push_data(0x16161616);
is_deeply Crypt::SSSS::Message->build_from_binary($m->get_p, $m->binary)
  ->get_data,
  [0xffffffff, 0x16161616], 'P=4294967311';

done_testing;
