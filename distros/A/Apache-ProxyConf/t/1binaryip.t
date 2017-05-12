use strict;
use Test;

BEGIN { plan tests => 4 }

use Apache::ProxyConf;

ok(Apache::ProxyConf::binaryip("0.0.0.0"), 0);
ok(Apache::ProxyConf::binaryip("172.16.16.1"), 2886733825);
ok(Apache::ProxyConf::binaryip("255.255.255.255"), 4294967295);
ok(Apache::ProxyConf::binaryip("invalid IP"), 0);
