use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

plan tests => 18;   # plan one test.

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

while (<DATA>) {
  chomp;
  my ($ipaddr, $exp_country) = split ' ', $_, 2;
 
 my $received = GET_BODY "/TestGeoIP__ip?$ipaddr";
 my $expected = $exp_country;
  
ok t_cmp(
        $received,
        $expected,
        "testing ip with $ipaddr",
        );

}

__DATA__
203.174.65.12	JP
212.208.74.140	FR
200.219.192.106	BR
134.102.101.18	DE
193.75.148.28	BE
134.102.101.18	DE
147.251.48.1	CZ
194.244.83.2	IT
203.15.106.23	AU
196.31.1.1	ZA
210.54.22.1	NZ
210.25.5.5	CN
210.54.122.1	NZ
210.25.15.5	CN
192.37.51.100	CH
192.37.150.150	CH
192.106.51.100	IT
192.106.150.150	IT