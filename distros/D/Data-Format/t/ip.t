#!/usr/bin/perl
use 5.008;
use strict;
use warnings;

use Test::Simple tests => 12;
use Data::Format::Validate::String q/:ip/;

ok(looks_like_ipv4 '127.0.0.1');
ok(looks_like_ipv4 '192.168.0.1');
ok(looks_like_ipv4 '255.255.255.255');

ok(not looks_like_ipv4 '255255255255');
ok(not looks_like_ipv4 '255.255.255.256');

ok(looks_like_ipv6 '1762:0:0:0:0:B03:1:AF18');
ok(looks_like_ipv6 '1762:ABC:464:4564:0:BA03:1000:AA1F');
ok(looks_like_ipv6 '1762:4546:A54f:d6fd:5455:B03:1fda:dFde');

ok(not looks_like_ipv6 '17620000AFFFB031AF187');
ok(not looks_like_ipv6 '1762:0:0:0:0:B03:AF18');
ok(not looks_like_ipv6 '1762:0:0:0:0:B03:1:Ag18');
ok(not looks_like_ipv6 '1762:0:0:0:0:AFFFB03:1:AF187');