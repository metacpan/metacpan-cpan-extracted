#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use Test::Simple tests => 5;
use Data::Format::Validate::String q/:ip/;

ok(looks_like_ipv4 '127.0.0.1');
ok(looks_like_ipv4 '192.168.0.1');
ok(looks_like_ipv4 '255.255.255.255');

ok(!looks_like_ipv4 '255255255255');
ok(!looks_like_ipv4 '255.255.255.256');