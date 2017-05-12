use warnings;
use strict;
use Test::More;


use BGPmon::Translator::XFB2PerlHash::Simpler;

use constant TRUE => 1;
use constant FALSE => 0;

require_ok('List::MoreUtils');
require_ok('BGPmon::Translator::XFB2PerlHash');

my $resp = `pwd`;
my $location = 't/';
if($resp =~ m/bgpmon-tools\/BGPmon-core\/t/){
	$location = '';
}



##Messages for all tests
my $blankMsg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2402:7400:0:3c::1</ADDRESS><PORT>179</PORT><ASN4>38883</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377030782</TIMESTAMP><DATETIME>2013-08-20T20:33:02Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691554039</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0022020000000B800F08000201202C0FFD10</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';



#Testing NLRI Message Parsing
my $nlriMsg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">129.250.1.248</ADDRESS><PORT>179</PORT><ASN4>2914</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463537</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>2914</bgp:ASN4><bgp:ASN4>7018</bgp:ASN4><bgp:ASN4>19301</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">129.250.1.248</bgp:NEXT_HOP><bgp:MULTI_EXIT_DISC optional="true" transitive="false" partial="false" extended="false" attribute_type="4">83951616</bgp:MULTI_EXIT_DISC><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>420</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>1008</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>2000</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>3000</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>65504</bgp:ASN2><bgp:VALUE>7018</bgp:VALUE></bgp:COMMUNITY><bgp:NLRI afi="1">63.172.189.0/24</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0059020000003A4001010040020E020300000B6200001B6A00004B6540030481FA01F880040400000105C008140B6201A40B6203F00B6207D00B620BB8FFE01B6A183FACBD18AA9970</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

my $nlriMsg2 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">129.250.1.248</ADDRESS><PORT>179</PORT><ASN4>2914</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463537</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>2914</bgp:ASN4><bgp:ASN4>7018</bgp:ASN4><bgp:ASN4>19301</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">129.250.1.248</bgp:NEXT_HOP><bgp:MULTI_EXIT_DISC optional="true" transitive="false" partial="false" extended="false" attribute_type="4">83951616</bgp:MULTI_EXIT_DISC><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>420</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>1008</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>2000</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>3000</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>65504</bgp:ASN2><bgp:VALUE>7018</bgp:VALUE></bgp:COMMUNITY><bgp:NLRI afi="1">63.172.189.0/24</bgp:NLRI><bgp:NLRI afi="1">170.153.112.0/24</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0059020000003A4001010040020E020300000B6200001B6A00004B6540030481FA01F880040400000105C008140B6201A40B6203F00B6207D00B620BB8FFE01B6A183FACBD18AA9970</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';


my $ret = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($nlriMsg);
is($ret, 0, "PARSE XML FOR NLRI");
my @nlris = BGPmon::Translator::XFB2PerlHash::Simpler::extract_nlri();
my $size = scalar @nlris;
is($size, 1, "NLRI_PARSING SINGLE SIZE");
is($nlris[0], '63.172.189.0/24', "NLRI SINGLE VALUE");


$ret = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($nlriMsg2);
is($ret, 0, "PARSE XML FOR 2 NLRI");
@nlris = BGPmon::Translator::XFB2PerlHash::Simpler::extract_nlri();
$size = scalar @nlris;
is($size, 2, "NLRI PARSING DOUBLE SIZE");
is($nlris[0], '63.172.189.0/24', "NLRI DOUBLE 1ST VALUE");
is($nlris[1], '170.153.112.0/24', "NLRI DOUBLE 2ND VALUE");

#$ret = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($blankMsg);
#@nlris = BGPmon::Translator::XFB2PerlHash::Simpler::extract_nlri();
#is(@nlris, undef, "NLRI NONE IN XML");


#Testing Withdraw Message Parsing

my $withMsg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">64.25.208.71</ADDRESS><PORT>179</PORT><ASN2>20225</ASN2></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN2>6447</ASN2></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377030780</TIMESTAMP><DATETIME>2013-08-20T20:33:00Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691554003</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:WITHDRAW afi="1">62.231.26.0/24</bgp:WITHDRAW></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF001B020004183EE71A0000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';
my $withMsg2 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">64.25.208.71</ADDRESS><PORT>179</PORT><ASN2>20225</ASN2></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN2>6447</ASN2></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377030780</TIMESTAMP><DATETIME>2013-08-20T20:33:00Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691554003</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:WITHDRAW afi="1">62.231.26.0/24</bgp:WITHDRAW><bgp:WITHDRAW afi="1">129.82.0.0/16</bgp:WITHDRAW></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF001B020004183EE71A0000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

$ret = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($withMsg);
is($ret, 0, "PARSE XML FOR WITHDRAW");
my @withs = BGPmon::Translator::XFB2PerlHash::Simpler::extract_withdraw();
$size = scalar @withs;
is($size, 1, "WITHDRAW PARSING SINGLE SIZE");
is($withs[0], '62.231.26.0/24', "WITHDRAW SINGLE VALUE");


$ret = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($withMsg2);
is($ret, 0, "PARSE XML FOR 2 WITHDRAW");
@withs = BGPmon::Translator::XFB2PerlHash::Simpler::extract_withdraw();
$size = scalar @withs;
is($size, 2, "WITHDRAW PARSING DOUBLE SIZE");
is($withs[0], '62.231.26.0/24', "WITHDRAW DOUBLE 1ST VALUE");
is($withs[1], '129.82.0.0/16', "WITHDRAW DOUBLE 2ND VALUE");





#Testing MP_REACH_NLRI message parsing

my $mpreach = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN4>59469</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463535</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>59469</bgp:ASN4><bgp:ASN4>12617</bgp:ASN4><bgp:ASN4>3356</bgp:ASN4><bgp:ASN4>6939</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>6503</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:ATOMIC_AGGREGATE optional="false" transitive="true" partial="false" extended="false" attribute_type="6"/><bgp:AGGREGATOR optional="true" transitive="true" partial="false" extended="false" attribute_type="7"><bgp:ASN4>0</bgp:ASN4><bgp:IPv4_ADDRESS afi="1">148.245.204.236</bgp:IPv4_ADDRESS></bgp:AGGREGATOR><bgp:MP_REACH_NLRI optional="true" transitive="false" partial="false" extended="true" attribute_type="14" safi="1"><bgp:MP_NEXT_HOP afi="2">2a03:a480:ffff:ffff::247</bgp:MP_NEXT_HOP><bgp:MP_NLRI afi="2">2806:1::/32</bgp:MP_NLRI></bgp:MP_REACH_NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00A0020000008940010100400232020C0000E84D0000314900000D1C00001B1B0000356F0000356F0000356F0000356F0000356F0000356F0000356F00001967400600C007080000196794F5CCECC0081C0D1C00020D1C00160D1C00560D1C01F50D1C02590D1C029A0D1C0811900E001F000201102A03A480FFFFFFFF00000000000002470020280600012028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';
my $mpreach2 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN4>59469</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463535</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>59469</bgp:ASN4><bgp:ASN4>12617</bgp:ASN4><bgp:ASN4>3356</bgp:ASN4><bgp:ASN4>6939</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>6503</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:ATOMIC_AGGREGATE optional="false" transitive="true" partial="false" extended="false" attribute_type="6"/><bgp:AGGREGATOR optional="true" transitive="true" partial="false" extended="false" attribute_type="7"><bgp:ASN4>0</bgp:ASN4><bgp:IPv4_ADDRESS afi="1">148.245.204.236</bgp:IPv4_ADDRESS></bgp:AGGREGATOR><bgp:MP_REACH_NLRI optional="true" transitive="false" partial="false" extended="true" attribute_type="14" safi="1"><bgp:MP_NEXT_HOP afi="2">2a03:a480:ffff:ffff::247</bgp:MP_NEXT_HOP><bgp:MP_NLRI afi="2">2806:1::/32</bgp:MP_NLRI><bgp:MP_NLRI afi="2">2806::/32</bgp:MP_NLRI></bgp:MP_REACH_NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00A0020000008940010100400232020C0000E84D0000314900000D1C00001B1B0000356F0000356F0000356F0000356F0000356F0000356F0000356F00001967400600C007080000196794F5CCECC0081C0D1C00020D1C00160D1C00560D1C01F50D1C02590D1C029A0D1C0811900E001F000201102A03A480FFFFFFFF00000000000002470020280600012028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';


$ret = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($mpreach);
is($ret, 0, "PARSE XML FOR MP_REACH_NLRI");
@nlris = BGPmon::Translator::XFB2PerlHash::Simpler::extract_mpreach_nlri();
$size = scalar @nlris;
is($size, 1, "MP_REACH_NLRI PARSING SINGLE SIZE");
is($nlris[0], '2806:1::/32', "MP_REACH_NLRI SINGLE VALUE");


$ret = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($mpreach2);
is($ret, 0, "PARSE XML FOR 2 MP_REACH_NLRI");
@nlris = BGPmon::Translator::XFB2PerlHash::Simpler::extract_mpreach_nlri();
$size = scalar @nlris;
is($size, 2, "MP_REACH_NLRI PARSING DOUBLE SIZE");
is($nlris[0], '2806:1::/32', "MP_UNREACH_NLRI DOUBLE 1ST VALUE");
is($nlris[1], '2806::/32', "MP_UNREACH_NLRI DOUBLE 2ND VALUE");



#Testing MP_UNREACH_NLRI message parsing
#-- Has only 1 MP_NLRI in MP_UNREACH_NLRI
my $unreachMsg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2607:f278:0:ffff::2</ADDRESS><PORT>179</PORT><ASN4>6360</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377032900</TIMESTAMP><DATETIME>2013-08-20T21:08:20Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691654842</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:MP_UNREACH_NLRI optional="true" transitive="false" partial="false" extended="true" attribute_type="15" safi="1"><bgp:MP_NLRI afi="2">2806:3::/32</bgp:MP_NLRI></bgp:MP_UNREACH_NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0032020000001B900F00170002012028060003202806000120280600022028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

#-- Has 2 MP_NLRI's in MP_UNREACH_NLRI
my $unreachMsg2 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2607:f278:0:ffff::2</ADDRESS><PORT>179</PORT><ASN4>6360</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377032900</TIMESTAMP><DATETIME>2013-08-20T21:08:20Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691654842</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:MP_UNREACH_NLRI optional="true" transitive="false" partial="false" extended="true" attribute_type="15" safi="1"><bgp:MP_NLRI afi="2">2806:3::/32</bgp:MP_NLRI><bgp:MP_NLRI afi="2">2806:1::/32</bgp:MP_NLRI><bgp:MP_NLRI afi="2">2806:2::/32</bgp:MP_NLRI><bgp:MP_NLRI afi="2">2806::/32</bgp:MP_NLRI></bgp:MP_UNREACH_NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0032020000001B900F00170002012028060003202806000120280600022028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';


my $unreachres = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($unreachMsg);
is($unreachres, 0, "PARSE XML FOR UNREACH");
my @unreaches = BGPmon::Translator::XFB2PerlHash::Simpler::extract_mpunreach_nlri();
$size = scalar @unreaches;
is($size, 1, "MP_UNREACH_PARSING SINGLE SIZE");
is($unreaches[0], '2806:3::/32', "MP_UNREACH_PARSING SINGLE VALUE");


$unreachres = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($unreachMsg2);
is($unreachres, 0, "PARSE XML FOR 2 UNREACH");
@unreaches = BGPmon::Translator::XFB2PerlHash::Simpler::extract_mpunreach_nlri();
$size = scalar @unreaches;
is($size, 4, "MP_UNREACH_PARSING MULTI SIZE");
is($unreaches[0], '2806:3::/32', "MP_UNREACH_PARSING MULTI 1ST VALUE");
is($unreaches[1], '2806:1::/32', "MP_UNREACH_PARSING MULTI 2ND VALUE");
is($unreaches[2], '2806:2::/32', "MP_UNREACH_PARSING MULTI 3RD VALUE");
is($unreaches[3], '2806::/32', "MP_UNREACH_PARSING MULTI 4TH VALUE");


#Testing AS_PATH message parsing
#Testing AS4_PATH message parsing


#Testing Source message parsing
#--Testing valid source with ASN2
my $source2 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">1.1.1.1</ADDRESS><PORT>179</PORT><ASN2>38883</ASN2></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377030782</TIMESTAMP><DATETIME>2013-08-20T20:33:02Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691554039</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0022020000000B800F08000201202C0FFD10</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

my $sourceres = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($source2);
is($sourceres, 0, "PARSE XML FOR SOURCE");
my $addr = BGPmon::Translator::XFB2PerlHash::Simpler::extract_sender_addr();
my $port = BGPmon::Translator::XFB2PerlHash::Simpler::extract_sender_port();
my $asn = BGPmon::Translator::XFB2PerlHash::Simpler::extract_sender_asn();
is($addr, '1.1.1.1', "SOURCE ADDRESS VALUE");
is($port, '179', "SOURCE PORT VALUE");
is($asn, '38883', "SOURCE ASN2 VALUE");


#--Testing valid source with ASN4
my $source4 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">1.1.1.1</ADDRESS><PORT>179</PORT><ASN4>38883</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377030782</TIMESTAMP><DATETIME>2013-08-20T20:33:02Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691554039</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0022020000000B800F08000201202C0FFD10</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';
$sourceres = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($source4);
is($sourceres, 0, "PARSE XML FOR SOURCE 2");
$addr = BGPmon::Translator::XFB2PerlHash::Simpler::extract_sender_addr();
$port = BGPmon::Translator::XFB2PerlHash::Simpler::extract_sender_port();
$asn = BGPmon::Translator::XFB2PerlHash::Simpler::extract_sender_asn();
is($addr, '1.1.1.1', "SOURCE ADDRESS VALUE 2");
is($port, '179', "SOURCE PORT VALUE 2");
is($asn, '38883', "SOURCE ASN4 VALUE");

#--Testing no Souce in XML
my $sourceNull = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377030782</TIMESTAMP><DATETIME>2013-08-20T20:33:02Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691554039</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0022020000000B800F08000201202C0FFD10</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

$sourceres = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($sourceNull);
is($sourceres, 0, "PARSE XML FOR SOURCE 3");
$addr = BGPmon::Translator::XFB2PerlHash::Simpler::extract_sender_addr();
$port = BGPmon::Translator::XFB2PerlHash::Simpler::extract_sender_port();
$asn = BGPmon::Translator::XFB2PerlHash::Simpler::extract_sender_asn();
is($addr, undef, "SOURCE ADDRESS VALUE 3");
is($port, undef, "SOURCE PORT VALUE 3");
is($asn, undef, "SOURCE ASN VALUE 3");



#Testing AS_PATH message parsing
#--Has only 1 as in path
my $aspath = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN2>59469</ASN2></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN2>6447</ASN2></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN2>0</ASN2></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463535</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN2>59469</bgp:ASN2></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:ATOMIC_AGGREGATE optional="false" transitive="true" partial="false" extended="false" attribute_type="6"/></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00A0020000008940010100400232020C0000E84D0000314900000D1C00001B1B0000356F0000356F0000356F0000356F0000356F0000356F0000356F00001967400600C007080000196794F5CCECC0081C0D1C00020D1C00160D1C00560D1C01F50D1C02590D1C029A0D1C0811900E001F000201102A03A480FFFFFFFF00000000000002470020280600012028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';
my $asnres = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($aspath);
is($asnres, 0, "PARSE XML FOR AS_PATH");
my @asns = BGPmon::Translator::XFB2PerlHash::Simpler::extract_aspath();
$size = scalar @asns;
is($size, 1, "AS_PATH SINGLE SIZE");
is($asns[0], '59469', "AS_PATH PARSING SINGLE VALUE");


#--Has multiple as in path
my $as2msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN2>59469</ASN2></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN2>6447</ASN2></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN2>0</ASN2></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463535</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN2>59469</bgp:ASN2><bgp:ASN2>12617</bgp:ASN2><bgp:ASN2>3356</bgp:ASN2><bgp:ASN2>6939</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>6503</bgp:ASN2></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:ATOMIC_AGGREGATE optional="false" transitive="true" partial="false" extended="false" attribute_type="6"/></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00A0020000008940010100400232020C0000E84D0000314900000D1C00001B1B0000356F0000356F0000356F0000356F0000356F0000356F0000356F00001967400600C007080000196794F5CCECC0081C0D1C00020D1C00160D1C00560D1C01F50D1C02590D1C029A0D1C0811900E001F000201102A03A480FFFFFFFF00000000000002470020280600012028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';
$asnres = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($as2msg);
is($asnres, 0, "PARSE XML FOR MULTIPLE AS_PATH");
@asns = BGPmon::Translator::XFB2PerlHash::Simpler::extract_aspath();
$size = scalar @asns;
is($size, 12, "AS_PATH MULTIPLE SIZE");
is($asns[0], '59469', "AS_PATH PARSING MULT 1ST VALUE");
is($asns[-1], '6503', "AS_PATH PARSING MULT LAST VALUE");

#--Hash no as in path
my $asNomsg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN2>59469</ASN2></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN2>6447</ASN2></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN2>0</ASN2></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463535</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:ATOMIC_AGGREGATE optional="false" transitive="true" partial="false" extended="false" attribute_type="6"/></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00A0020000008940010100400232020C0000E84D0000314900000D1C00001B1B0000356F0000356F0000356F0000356F0000356F0000356F0000356F00001967400600C007080000196794F5CCECC0081C0D1C00020D1C00160D1C00560D1C01F50D1C02590D1C029A0D1C0811900E001F000201102A03A480FFFFFFFF00000000000002470020280600012028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';
$asnres = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($asNomsg);
is($asnres, 0, "PARSE XML FOR NO AS_PATH");
@asns = BGPmon::Translator::XFB2PerlHash::Simpler::extract_aspath();
$size = scalar @asns;
is($size, 0, "AS_PATH NO AS_PATHA SIZE");




#Testing AS4_PATH message parsing

#--Has one as in the path
my $asn4msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN4>59469</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463535</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS4_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS4_SEQUENCE><bgp:ASN4>59469</bgp:ASN4></bgp:AS4_SEQUENCE></bgp:AS4_PATH><bgp:ATOMIC_AGGREGATE optional="false" transitive="true" partial="false" extended="false" attribute_type="6"/></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00A0020000008940010100400232020C0000E84D0000314900000D1C00001B1B0000356F0000356F0000356F0000356F0000356F0000356F0000356F00001967400600C007080000196794F5CCECC0081C0D1C00020D1C00160D1C00560D1C01F50D1C02590D1C029A0D1C0811900E001F000201102A03A480FFFFFFFF00000000000002470020280600012028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

my $asn4res = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($asn4msg);
is($asnres, 0, "PARSE XML FOR AS4_PATH");
my @asn4s = BGPmon::Translator::XFB2PerlHash::Simpler::extract_as4path();
$size = scalar @asn4s;
is($size, 1, "AS4_PATH SINGLE SIZE");
is($asn4s[0], '59469', "AS4_PATH PARSING SINGLE VALUE");


#--Has multiple as in the path
my $asn42msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN4>59469</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463535</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS4_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>59469</bgp:ASN4><bgp:ASN4>12617</bgp:ASN4><bgp:ASN4>3356</bgp:ASN4><bgp:ASN4>6939</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>13679</bgp:ASN4><bgp:ASN4>6503</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS4_PATH><bgp:ATOMIC_AGGREGATE optional="false" transitive="true" partial="false" extended="false" attribute_type="6"/></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00A0020000008940010100400232020C0000E84D0000314900000D1C00001B1B0000356F0000356F0000356F0000356F0000356F0000356F0000356F00001967400600C007080000196794F5CCECC0081C0D1C00020D1C00160D1C00560D1C01F50D1C02590D1C029A0D1C0811900E001F000201102A03A480FFFFFFFF00000000000002470020280600012028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

$asn4res = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($asn42msg);
is($asn4res, 0, "PARSE XML FOR MULTIPLE AS4_PATH");
@asn4s = BGPmon::Translator::XFB2PerlHash::Simpler::extract_as4path();
$size = scalar @asn4s;
is($size, 12, "AS4_PATH MULTIPLE SIZE");
is($asn4s[0], '59469', "AS4_PATH PARSING MULT 1ST VALUE");
is($asn4s[-1], '6503', "AS4_PATH PARSING MULT LAST VALUE");


#--Has no message in the path
my $asn4Nomsg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN4>59469</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463535</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:ATOMIC_AGGREGATE optional="false" transitive="true" partial="false" extended="false" attribute_type="6"/></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00A0020000008940010100400232020C0000E84D0000314900000D1C00001B1B0000356F0000356F0000356F0000356F0000356F0000356F0000356F00001967400600C007080000196794F5CCECC0081C0D1C00020D1C00160D1C00560D1C01F50D1C02590D1C029A0D1C0811900E001F000201102A03A480FFFFFFFF00000000000002470020280600012028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

$asn4res = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($asn4Nomsg);
is($asn4res, 0, "PARSE XML FOR NO AS4_PATH");
@asn4s = BGPmon::Translator::XFB2PerlHash::Simpler::extract_as4path();
$size = scalar @asn4s;
is($size, 0, "AS4_PATH NO AS_PATHA SIZE");

#--Has asn2 in the path
my $asn4with2msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN4>59469</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463535</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS4_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN2>59469</bgp:ASN2><bgp:ASN2>12617</bgp:ASN2><bgp:ASN2>3356</bgp:ASN2><bgp:ASN2>6939</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>6503</bgp:ASN2></bgp:AS_SEQUENCE></bgp:AS4_PATH><bgp:ATOMIC_AGGREGATE optional="false" transitive="true" partial="false" extended="false" attribute_type="6"/></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00A0020000008940010100400232020C0000E84D0000314900000D1C00001B1B0000356F0000356F0000356F0000356F0000356F0000356F0000356F00001967400600C007080000196794F5CCECC0081C0D1C00020D1C00160D1C00560D1C01F50D1C02590D1C029A0D1C0811900E001F000201102A03A480FFFFFFFF00000000000002470020280600012028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

$asn4res = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($asn4with2msg);
is($asn4res, 0, "PARSE XML FOR ASN2 IN AS4_PATH");
@asn4s = BGPmon::Translator::XFB2PerlHash::Simpler::extract_as4path();
$size = scalar @asn4s;
is($size, 12, "AS4_PATH WITH ASN2 MULTIPLE SIZE");
is($asn4s[0], '59469', "AS4_PATH PARSING ASN2 MULT 1ST VALUE");
is($asn4s[-1], '6503', "AS4_PATH PARSING ASN2 MULT LAST VALUE");


#Testing origin message parsing

#--testing with origin
my $originMsg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN2>59469</ASN2></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN2>6447</ASN2></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN2>0</ASN2></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377028766</TIMESTAMP><DATETIME>2013-08-20T19:59:26Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691463535</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN2>59469</bgp:ASN2><bgp:ASN2>12617</bgp:ASN2><bgp:ASN2>3356</bgp:ASN2><bgp:ASN2>6939</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>13679</bgp:ASN2><bgp:ASN2>6503</bgp:ASN2></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:ATOMIC_AGGREGATE optional="false" transitive="true" partial="false" extended="false" attribute_type="6"/></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00A0020000008940010100400232020C0000E84D0000314900000D1C00001B1B0000356F0000356F0000356F0000356F0000356F0000356F0000356F00001967400600C007080000196794F5CCECC0081C0D1C00020D1C00160D1C00560D1C01F50D1C02590D1C029A0D1C0811900E001F000201102A03A480FFFFFFFF00000000000002470020280600012028060000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

my $origres = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($originMsg);
is($origres, 0, "PARSE XML FOR ORIGIN ASN");
my $origin = BGPmon::Translator::XFB2PerlHash::Simpler::extract_origin();
is($origin, 6503, "ORIGIN FROM AS_PATH");


#-- testing with no origin
my $originNomsg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1377030782</TIMESTAMP><DATETIME>2013-08-20T20:33:02Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1691554039</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0022020000000B800F08000201202C0FFD10</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';
$origres = BGPmon::Translator::XFB2PerlHash::Simpler::parse_xml_msg($originNomsg);
is($origres, 0, "PARSE XML FOR (NO) ORIGIN ASN");
$origin = BGPmon::Translator::XFB2PerlHash::Simpler::extract_origin();
is($origin, undef, "ORIGIN FROM AS_PATH");


done_testing();

