#!perl

use strict;
use warnings;

use Test::More tests => 10;
use Config::Hosts;

ok(Config::Hosts::is_valid_ip('1.2.2.3'), "simple ip");
ok(Config::Hosts::is_valid_ip('001.002.002.000255'), "zero-padded ip");
ok(Config::Hosts::is_valid_ip('192.168.223.99'), "arbitrary ip");
ok(! Config::Hosts::is_valid_ip('1.2.2.333'), "invalid numeric ip");
ok(! Config::Hosts::is_valid_ip('a1.2.2.3'), "non-numeric ip");

ok(Config::Hosts::is_valid_host('abc-de'), "simple host");
ok(Config::Hosts::is_valid_host('a1.2-22.2.3'), "host with dash");
ok(! Config::Hosts::is_valid_host('1.2.2.3'), "ip, not host");
ok(! Config::Hosts::is_valid_host('1_1.2.2.3'), "invalid underscore");
ok(! Config::Hosts::is_valid_host('a1.2.2.23.'), "ends with dot");

