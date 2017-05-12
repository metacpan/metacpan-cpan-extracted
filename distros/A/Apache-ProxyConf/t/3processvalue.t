use strict;
use Test;

BEGIN { plan tests => 3 }

use Apache::ProxyConf;

my @proxylist = Apache::ProxyConf::processvalue("172.16.16.1:80,172.16.16.2:80", "172.16.16.1", 0);
ok(join (',', @proxylist), "172.16.16.1:80,172.16.16.2:80");

@proxylist = Apache::ProxyConf::processvalue("172.16.16.1:80,172.16.16.2:80", "172.16.16.8", 0);
ok(join (',', @proxylist), "172.16.16.1:80,172.16.16.2:80");

@proxylist = Apache::ProxyConf::processvalue("(172.16.16.1:80,172.16.16.2:80)", "172.16.16.1", 0);
ok(join (',', @proxylist), "172.16.16.2:80,172.16.16.1:80");
