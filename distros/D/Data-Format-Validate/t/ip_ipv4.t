#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use Test::Simple tests => 5;
use Data::Format::Validate::IP 'looks_like_ipv4';

ok(looks_like_ipv4 '127.0.0.1');
ok(looks_like_ipv4 '192.168.0.1');
ok(looks_like_ipv4 '255.255.255.255');

ok(not looks_like_ipv4 '255255255255');
ok(not looks_like_ipv4 '25z5.255.255.256');
