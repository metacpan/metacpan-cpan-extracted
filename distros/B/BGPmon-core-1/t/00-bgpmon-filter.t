use warnings;
use strict;
use Test::More;

use BGPmon::Filter;

use constant TRUE => 1;
use constant FALSE => 0;

require_ok('Net::IP');
require_ok('Regexp::IPv6');
require_ok('Net::Address::IP::Local');

my $resp = `pwd`;
my $location = 't/';
if($resp =~ m/bgpmon-tools\/BGPmon-core\/t/){
	$location = '';
}


my $xml6msg = '<BGP_MESSAGE length="00002487" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="2128112124" seq_num="2022934477"/><TIME timestamp="1343706329" datetime="2012-07-31T03:45:29Z" precision_time="354"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>2001:de8:6::6447:1</ADDRESS><AFI value="2">IPV6</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>2001:de8:6::7575:1</ADDRESS><AFI value="2">IPV6</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>7575</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="121"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="98"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="14"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="3"><AS>7575</AS><AS>6939</AS><AS>12857</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS optional="TRUE"/><TYPE value="4">MULTI_EXIT_DISC</TYPE><MULTI_EXIT_DISC>44</MULTI_EXIT_DISC></ATTRIBUTE><ATTRIBUTE length="16"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>7575</AS><VALUE>1002</VALUE></COMMUNITY><COMMUNITY><AS>7575</AS><VALUE>2017</VALUE></COMMUNITY><COMMUNITY><AS>7575</AS><VALUE>6003</VALUE></COMMUNITY><COMMUNITY><AS>7575</AS><VALUE>8002</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE><ATTRIBUTE length="48"><FLAGS optional="TRUE"/><TYPE value="14">MP_REACH_NLRI</TYPE><MP_REACH_NLRI><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI><NEXT_HOP_LEN>32</NEXT_HOP_LEN><NEXT_HOP><ADDRESS>2001:de8:6::7575:1</ADDRESS><ADDRESS>fe80::222:90ff:fe5f:2740</ADDRESS></NEXT_HOP><NLRI count="2"><PREFIX label="NANN"><ADDRESS>2a00:b400::/32</ADDRESS><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="NANN"><ADDRESS>2a00:b400:f000::/36</ADDRESS><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></MP_REACH_NLRI></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="121">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF007902000000624001010040020E020300001D9700001B1B000032398004040000002CC008101D9703EA1D9707E11D9717731D971F42800E300002012020010DE8000600000000000075750001FE80000000000000022290FFFE5F274000202A00B400242A00B400F0</OCTETS></OCTET_MSG></BGP_MESSAGE>';


#Testing Init
my $retVal = BGPmon::Filter::init();
ok($retVal == 0, 'Init Test');




#Testing Reset
my $resetRetVal = BGPmon::Filter::filterReset();
is($resetRetVal, 0, 'Reset Test');







#Testing Config File Parsing

#--test for file missing
BGPmon::Filter::init();
BGPmon::Filter::parse_config_file("madeupfilename.txt");
my $errCode = BGPmon::Filter::get_error_code('parse_config_file');
is($errCode, BGPmon::Filter::UNOPANABLE_CONFIG_FILE, "File Not Found");
BGPmon::Filter::filterReset();

#--test for file w/o permissions
=comment
TODO make sure you update the location for the files and stuff here
BGPmon::Filter::init();
my $output = `chmod 000 t/bgpmon-filter-config-no-permissions.txt 2>&1`;
if($?){
	print "$!\n";
}

BGPmon::Filter::parse_config_file($location+"bgpmon-filter-config-no-permissions.txt");
$errCode = BGPmon::Filter::get_error_code('parse_config_file');
is($errCode, BGPmon::Filter::UNOPANABLE_CONFIG_FILE, "File w/o Permissions");

BGPmon::Filter::filterReset();
## put permissions back
$output = `chmod 555 t/bgpmon-filter-config-no-permissions.txt 2>&1`;
if($?){
	print "$!\n";
}
=cut

#--test for file w/ bad ipv4 
BGPmon::Filter::init();
BGPmon::Filter::parse_config_file($location."bgpmon-filter-config-bad-ipv4.txt");
$errCode = BGPmon::Filter::get_error_code('parse_config_file');
is($errCode, BGPmon::Filter::INVALID_IPV4_CONFIG, "Bad IPv4");
BGPmon::Filter::filterReset();

#--test for file w/ bad ipv6
BGPmon::Filter::init();
BGPmon::Filter::parse_config_file($location."bgpmon-filter-config-bad-ipv6.txt");
$errCode = BGPmon::Filter::get_error_code('parse_config_file');
is($errCode, BGPmon::Filter::INVALID_IPV6_CONFIG, "Bad IPv6");
BGPmon::Filter::filterReset();

#--test for file w/ bad AS
BGPmon::Filter::init();
BGPmon::Filter::parse_config_file($location."bgpmon-filter-config-bad-as.txt");
$errCode = BGPmon::Filter::get_error_code('parse_config_file');
is($errCode, BGPmon::Filter::INVALID_AS_CONFIG, "Bad AS");
BGPmon::Filter::filterReset();

#--test for file w/ incorrect ms/ls
BGPmon::Filter::init();
BGPmon::Filter::parse_config_file($location."bgpmon-filter-config-incomplete-line.txt");
$errCode = BGPmon::Filter::get_error_code('parse_config_file');
is($errCode, BGPmon::Filter::INVALID_IPV4_CONFIG, "Incomplete Line");
BGPmon::Filter::filterReset();


#--test for file w/ unkown parameter
BGPmon::Filter::init();
BGPmon::Filter::parse_config_file($location."bgpmon-filter-config-bad-line.txt");
$errCode = BGPmon::Filter::get_error_code('parse_config_file');
is($errCode, BGPmon::Filter::UNKNOWN_CONFIG, "Unknown Parameter");
BGPmon::Filter::filterReset();

#--test for fully correct file.
BGPmon::Filter::init();
BGPmon::Filter::parse_config_file($location."bgpmon-filter-config.txt");
$errCode = BGPmon::Filter::get_error_code('parse_config_file');
is($errCode, BGPmon::Filter::NO_ERROR_CODE, "No Error Code");
BGPmon::Filter::filterReset();







#Testing XML Message Parsing
BGPmon::Filter::init();
BGPmon::Filter::parse_config_file($location."bgpmon-filter-config.txt");
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
#--testing that the code checks for a message
BGPmon::Filter::parse_xml_msg();
$errCode = BGPmon::Filter::get_error_code('parse_xml_msg');
is($errCode, BGPmon::Filter::NO_MSG_GIVEN, "No XML Message Given");

#--testing for correct <WITHDRAWN> filtering
my $xml4msg = '<BGP_MESSAGE length="00001140" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1541418969"/><TIME timestamp="1346459370" datetime="2012-09-01T00:29:30Z" precision_time="0"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>187.16.217.154</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>53175</SRC_AS><DST_ADDR><ADDRESS>200.160.6.217</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>6447</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="31"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="8" path_attr_len="0"><WITHDRAWN count="2"><PREFIX label="WITH"><ADDRESS>150.196.29.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>205.94.224.0/20</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></WITHDRAWN><PATH_ATTRIBUTES count="0"/><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="31">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF001F0200081896C41D14CD5EE00000</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $res = BGPmon::Filter::matches($xml4msg);
is($res, TRUE, "XML IPv4 WITHDRAWN tag");


#--testing for correct <WITHDRAW> filtering
$xml6msg = '<BGP_MESSAGE length="00001263" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="2128112124" seq_num="2022933907"/><TIME timestamp="1343706306" datetime="2012-07-31T03:45:06Z" precision_time="79"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>2001:de8:6::6447:1</ADDRESS><AFI value="2">IPV6</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>2001:de8:6::3:71:1</ADDRESS><AFI value="2">IPV6</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>30071</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="34"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="11"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="1"><ATTRIBUTE length="8"><FLAGS optional="TRUE"/><TYPE value="15">MP_UNREACH_NLRI</TYPE><MP_UNREACH_NLRI><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI><WITHDRAWN count="1"><PREFIX label="WITH"><ADDRESS>2a01:6a0::/32</ADDRESS><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></WITHDRAWN></MP_UNREACH_NLRI></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="34">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0022020000000B800F08000201202A0106A0</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $res1 = BGPmon::Filter::matches($xml6msg);
is($res1, TRUE, "XML IPv6 Withdraw tag"); 


#--testing for addresses in <NLRI>
$xml4msg = '<BGP_MESSAGE length="00002181" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="2128112124" seq_num="2021378732"/><TIME timestamp="1343692801" datetime="2012-07-31T00:00:01Z" precision_time="792"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>129.82.138.6</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>4321</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>89.149.178.10</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>3257</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="85"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="58"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="2">INCOMPLETE</ORIGIN></ATTRIBUTE><ATTRIBUTE length="14"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="6"><AS>3257</AS><AS>1239</AS><AS>8151</AS><AS>8151</AS><AS>8151</AS><AS>8151</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS transitive="TRUE"/><TYPE value="3">NEXT_HOP</TYPE><NEXT_HOP>89.149.178.10</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS optional="TRUE"/><TYPE value="4">MULTI_EXIT_DISC</TYPE><MULTI_EXIT_DISC>10</MULTI_EXIT_DISC></ATTRIBUTE><ATTRIBUTE length="20"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>3257</AS><VALUE>8095</VALUE></COMMUNITY><COMMUNITY><AS>3257</AS><VALUE>30288</VALUE></COMMUNITY><COMMUNITY><AS>3257</AS><VALUE>50002</VALUE></COMMUNITY><COMMUNITY><AS>3257</AS><VALUE>51300</VALUE></COMMUNITY><COMMUNITY><AS>3257</AS><VALUE>51301</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="1"><PREFIX label="SPATH"><ADDRESS>148.208.196.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="85">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0055020000003A4001010240020E02060CB904D71FD71FD71FD71FD74003045995B20A8004040000000AC008140CB91F9F0CB976500CB9C3520CB9C8640CB9C8651894D0C4</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $res2 = BGPmon::Filter::matches($xml4msg);
is($res2, TRUE, "XML IPv4 NLRI tag"); 




#--testing for addresses in <MP_REACH_NLRI> for IPv6

$xml6msg = '<BGP_MESSAGE length="00002062" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1540154687"/><TIME timestamp="1346261193" datetime="2012-08-29T17:26:33Z" precision_time="0"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>2001:12f8::20</ADDRESS><AFI value="2">IPV6</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>28571</SRC_AS><DST_ADDR><ADDRESS>200.160.6.217</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>6447</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="105"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="82"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="4"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="22"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="5"><AS>28571</AS><AS>1916</AS><AS>27750</AS><AS>11537</AS><AS>18592</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>1916</AS><VALUE>1350</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE><ATTRIBUTE length="42"><FLAGS optional="TRUE" extended="TRUE"/><TYPE value="14">MP_REACH_NLRI</TYPE><MP_REACH_NLRI><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI><NEXT_HOP_LEN>32</NEXT_HOP_LEN><NEXT_HOP><ADDRESS>2001:12f8::20</ADDRESS><ADDRESS>fe80::223:9c00:1469:b3fc</ADDRESS></NEXT_HOP><NLRI count="1"><PREFIX label="DPATH"><ADDRESS>2001:1228::/32</ADDRESS><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></MP_REACH_NLRI></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="105">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0069020000005240010100400216020500006F9B0000077C00006C6600002D11000048A0C00804077C0546900E002A00020120200112F8000000000000000000000020FE8000000000000002239C001469B3FC002020011228</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $res3 = BGPmon::Filter::matches($xml6msg);
is($res3, TRUE, "XML IPv6 MP_REACH_NLRI tag"); 

#--testing for addresses in <MP_REACH_NLRI> for IPv4

$xml4msg = '<BGP_MESSAGE length="00002062" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1540154687"/><TIME timestamp="1346261193" datetime="2012-08-29T17:26:33Z" precision_time="0"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>2001:12f8::20</ADDRESS><AFI value="2">IPV6</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>28571</SRC_AS><DST_ADDR><ADDRESS>200.160.6.217</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>6447</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="105"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="82"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="4"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="22"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="5"><AS>28571</AS><AS>1916</AS><AS>27750</AS><AS>11537</AS><AS>18592</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>1916</AS><VALUE>1350</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE><ATTRIBUTE length="42"><FLAGS optional="TRUE" extended="TRUE"/><TYPE value="14">MP_REACH_NLRI</TYPE><MP_REACH_NLRI><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI><NEXT_HOP_LEN>32</NEXT_HOP_LEN><NEXT_HOP><ADDRESS>2001:12f8::20</ADDRESS><ADDRESS>fe80::223:9c00:1469:b3fc</ADDRESS></NEXT_HOP><NLRI count="1"><PREFIX label="DPATH"><ADDRESS>148.208.196.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></MP_REACH_NLRI></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="105">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0069020000005240010100400216020500006F9B0000077C00006C6600002D11000048A0C00804077C0546900E002A00020120200112F8000000000000000000000020FE8000000000000002239C001469B3FC002020011228</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $res8 = BGPmon::Filter::matches($xml4msg);
is($res8, TRUE, "XML IPv4 MP_REACH_NLRI tag"); 


#--testing for addresses in <MP_UNREACH_NLRI> for IPv6
$xml6msg = '<BGP_MESSAGE length="00001265" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="2128112124" seq_num="2022934043"/><TIME timestamp="1343706309" datetime="2012-07-31T03:45:09Z" precision_time="923"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>2001:de8:6::6447:1</ADDRESS><AFI value="2">IPV6</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>2001:de8:6::3:71:1</ADDRESS><AFI value="2">IPV6</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>30071</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="34"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="11"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="1"><ATTRIBUTE length="8"><FLAGS optional="TRUE"/><TYPE value="15">MP_UNREACH_NLRI</TYPE><MP_UNREACH_NLRI><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI><WITHDRAWN count="1"><PREFIX label="WITH"><ADDRESS>2a00:14f8::/32</ADDRESS><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></WITHDRAWN></MP_UNREACH_NLRI></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="34">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0022020000000B800F08000201202A0014F8</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $res4 = BGPmon::Filter::matches($xml6msg);
is($res4, TRUE, "XML IPv6 MP_UNREACH_NLRI tag"); 

#--testing for addresses in <MP_UNREACH_NLRI> for IPv4
$xml4msg = '<BGP_MESSAGE length="00001265" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="2128112124" seq_num="2022934043"/><TIME timestamp="1343706309" datetime="2012-07-31T03:45:09Z" precision_time="923"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>2001:de8:6::6447:1</ADDRESS><AFI value="2">IPV6</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>2001:de8:6::3:71:1</ADDRESS><AFI value="2">IPV6</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>30071</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="34"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="11"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="1"><ATTRIBUTE length="8"><FLAGS optional="TRUE"/><TYPE value="15">MP_UNREACH_NLRI</TYPE><MP_UNREACH_NLRI><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI><WITHDRAWN count="1"><PREFIX label="WITH"><ADDRESS>148.208.196.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></WITHDRAWN></MP_UNREACH_NLRI></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="34">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0022020000000B800F08000201202A0014F8</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $res9 = BGPmon::Filter::matches($xml4msg);
is($res9, TRUE, "XML IPv4 MP_UNREACH_NLRI tag"); 

#--testing for as number in as path - last as number
$xml4msg = '<BGP_MESSAGE length="00002457" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="2128112124" seq_num="2021378733"/><TIME timestamp="1343692801" datetime="2012-07-31T00:00:01Z" precision_time="925"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>129.82.138.6</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>4321</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>89.149.178.10</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>3257</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="94"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="63"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="6"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="10"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="4"><AS>3257</AS><AS>6453</AS><AS>9498</AS><AS>17813</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS transitive="TRUE"/><TYPE value="3">NEXT_HOP</TYPE><NEXT_HOP>89.149.178.10</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS optional="TRUE"/><TYPE value="4">MULTI_EXIT_DISC</TYPE><MULTI_EXIT_DISC>10</MULTI_EXIT_DISC></ATTRIBUTE><ATTRIBUTE length="6"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="7">AGGREGATOR</TYPE><AGGREGATOR><AS>17813</AS><ADDR>20.12.185.31</ADDR></AGGREGATOR></ATTRIBUTE><ATTRIBUTE length="20"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>3257</AS><VALUE>8076</VALUE></COMMUNITY><COMMUNITY><AS>3257</AS><VALUE>30109</VALUE></COMMUNITY><COMMUNITY><AS>3257</AS><VALUE>50002</VALUE></COMMUNITY><COMMUNITY><AS>3257</AS><VALUE>51300</VALUE></COMMUNITY><COMMUNITY><AS>3257</AS><VALUE>51301</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="2"><PREFIX label="DPATH"><ADDRESS>59.177.48.0/20</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="DPATH"><ADDRESS>59.177.64.0/18</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="94">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF005E020000003F4001010040020A02040CB91935251A45954003045995B20A8004040000000AC007064595CB5EF68FC008140CB91F8C0CB9759D0CB9C3520CB9C8640CB9C865143BB130123BB140</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $res5 = BGPmon::Filter::matches($xml4msg);
is($res5, TRUE, "XML AS Last in AS_PATH"); 


#--testing more specific prefix matching works correctly
BGPmon::Filter::filterReset();
BGPmon::Filter::parse_config_file($location.'bgpmon-filter-config-ms.txt');
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
$xml4msg = '<BGP_MESSAGE length="00001140" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1541418969"/><TIME timestamp="1346459370" datetime="2012-09-01T00:29:30Z" precision_time="0"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>187.16.217.154</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>53175</SRC_AS><DST_ADDR><ADDRESS>200.160.6.217</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>6447</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="31"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="8" path_attr_len="0"><WITHDRAWN count="2"><PREFIX label="WITH"><ADDRESS>150.196.29.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>205.94.224.0/20</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></WITHDRAWN><PATH_ATTRIBUTES count="0"/><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="31">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF001F0200081896C41D14CD5EE00000</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $resa = BGPmon::Filter::matches($xml4msg);
is($resa, TRUE, "More Specific Prefix Matching"); 


#--testing less specific prefix matching works correctly
BGPmon::Filter::filterReset();
BGPmon::Filter::parse_config_file($location.'bgpmon-filter-config-ls.txt');
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
$xml4msg = '<BGP_MESSAGE length="00001140" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1541418969"/><TIME timestamp="1346459370" datetime="2012-09-01T00:29:30Z" precision_time="0"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>187.16.217.154</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>53175</SRC_AS><DST_ADDR><ADDRESS>200.160.6.217</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>6447</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="31"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="8" path_attr_len="0"><WITHDRAWN count="2"><PREFIX label="WITH"><ADDRESS>150.196.29.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>205.94.224.0/20</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></WITHDRAWN><PATH_ATTRIBUTES count="0"/><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="31">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF001F0200081896C41D14CD5EE00000</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $resb = BGPmon::Filter::matches($xml4msg);
is($resb, TRUE, "Less Specific Prefix Matching"); 


#--tsting that IPv4 address matching works correctly
#Note - this depends on the $xml4msg from the Less Specific Prefix Matching test.
BGPmon::Filter::filterReset();
BGPmon::Filter::parse_config_file($location.'bgpmon-filter-config-ip.txt');
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
my $rescc = BGPmon::Filter::matches($xml4msg);
is($rescc, TRUE, "IPv4 Address Matching");

#--tsting that IPv4 address matching works correctly
#Note - this depends on the $xml4msg from the Less Specific Prefix Matching test.
BGPmon::Filter::filterReset();
BGPmon::Filter::parse_config_file($location.'bgpmon-filter-config-ip.txt');
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
$xml4msg = '<BGP_MESSAGE length="00001140" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1541418969"/><TIME timestamp="1346459370" datetime="2012-09-01T00:29:30Z" precision_time="0"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>187.16.217.154</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>53175</SRC_AS><DST_ADDR><ADDRESS>200.160.6.217</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>6447</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="31"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="8" path_attr_len="0"><WITHDRAWN count="2"><PREFIX label="WITH"><ADDRESS>2.2.2.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>1.1.1.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></WITHDRAWN><PATH_ATTRIBUTES count="0"/><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="31">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF001F0200081896C41D14CD5EE00000</OCTETS></OCTET_MSG></BGP_MESSAGE>';
$rescc = BGPmon::Filter::matches($xml4msg);
is($rescc, FALSE, "IPv4 Address Matching");




BGPmon::Filter::filterReset();
BGPmon::Filter::parse_config_file($location.'bgpmon-filter-config-all-ms.txt');
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
$xml4msg = '<BGP_MESSAGE length="00001140" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1541418969"/><TIME timestamp="1346459370" datetime="2012-09-01T00:29:30Z" precision_time="0"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>187.16.217.154</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>53175</SRC_AS><DST_ADDR><ADDRESS>200.160.6.217</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>6447</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="31"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="8" path_attr_len="0"><WITHDRAWN count="2"><PREFIX label="WITH"><ADDRESS>150.196.29.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>205.94.224.0/20</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></WITHDRAWN><PATH_ATTRIBUTES count="0"/><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="31">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF001F0200081896C41D14CD5EE00000</OCTETS></OCTET_MSG></BGP_MESSAGE>';
my $num = BGPmon::Filter::get_total_num_filters();
is($num, 1, "Number of Filters");
$rescc = BGPmon::Filter::matches($xml4msg);
is($rescc, TRUE, "Filter All");






done_testing();

