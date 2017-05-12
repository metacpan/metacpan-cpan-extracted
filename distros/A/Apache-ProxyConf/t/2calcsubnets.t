use strict;
use Test;

BEGIN { plan tests => 3 }

use Apache::ProxyConf;
use Config::IniFiles;

my $conf = new Config::IniFiles(-file => "t/pc1.ini");
Apache::ProxyConf::calcsubnets($conf, "proxy");
Apache::ProxyConf::calcsubnets($conf, "noproxy");
Apache::ProxyConf::calcsubnets($conf, "https");
ok($conf->val("proxy", "subnets"), "24,12");
ok($conf->val("noproxy", "subnets"), "");
ok($conf->val("https", "subnets"), "16");
