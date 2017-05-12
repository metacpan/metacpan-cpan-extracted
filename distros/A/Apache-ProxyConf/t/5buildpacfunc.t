use strict;
use Test;

BEGIN { plan tests => 4 }

use Apache::ProxyConf;
use Config::IniFiles;

sub checkpac {
	my($conf, $ipaddr, $pacfile) = @_;

	my($proxy, $noproxy, $https, $pacscript, $expected);

	$proxy = Apache::ProxyConf::getproxyconf($ipaddr, $conf, "proxy", 0);
	$noproxy = Apache::ProxyConf::getproxyconf($ipaddr, $conf, "noproxy",
		0);
	$https = Apache::ProxyConf::getproxyconf($ipaddr, $conf, "https", 0);
	$pacscript = Apache::ProxyConf::buildpacfunc($proxy, $noproxy, $https,
		0);
	$expected = `cat $pacfile`;
	ok($pacscript, $expected) or print STDERR "\n", $pacscript, "\n";
}

my $conf = new Config::IniFiles(-file => "t/pc2.ini");
Apache::ProxyConf::calcsubnets($conf, "proxy");
Apache::ProxyConf::calcsubnets($conf, "noproxy");
Apache::ProxyConf::calcsubnets($conf, "https");

checkpac($conf, "172.16.0.100", "t/t1.pac");
checkpac($conf, "172.16.0.101", "t/t2.pac");
checkpac($conf, "172.16.16.100", "t/t3.pac");
checkpac($conf, "172.16.32.101", "t/t4.pac");
