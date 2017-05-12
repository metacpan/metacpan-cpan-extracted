#!/usr/bin/env perl
use strict;
use warnings;

## 01-i2osp.t -- Test for ::DataFormat::i2osp()
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.

use Test::More;
use Crypt::RSA::DataFormat qw(i2osp os2ip);

plan tests => 2;

my $number = 4;
my $str = i2osp ($number,4);
my $n = os2ip ($str);
is($n, $number, "os2ip(i2osp(n)) = n");

$number = '123485709238475934857903284752987598237450923847592384759032487592384752465346539847658327456823746587342658736587324658736453548634986439032342237489750398756037408972134678645678364987346128974682376487456987436487964879326487964378569287346529';
$str = i2osp($number,102);
$n = os2ip ($str);
is($n, $number, "os2ip(i2osp(bign)) = bign");
