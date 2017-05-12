use strict;
use Test;

BEGIN { plan tests => 2 }

use Apache::ProxyConf;
use Config::IniFiles;

my $conf = new Config::IniFiles(-file => "t/pc1.ini");
Apache::ProxyConf::calcsubnets($conf, "proxy");
Apache::ProxyConf::calcsubnets($conf, "noproxy");
Apache::ProxyConf::calcsubnets($conf, "https");

my $proxyline = Apache::ProxyConf::getproxyconf("172.16.16.1", $conf, "proxy",
	0);
ok($proxyline, "172.16.16.10:8001");

$proxyline = Apache::ProxyConf::getproxyconf("172.17.3.100", $conf, "proxy",
	0);
ok($proxyline, "172.17.3.10:80,172.16.16.10:8001");
