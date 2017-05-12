use warnings;
use strict;
use Test::More;

use BGPmon::Filter;

use constant TRUE => 1;
use constant FALSE => 0;

require_ok('Net::IP');
require_ok('Regexp::IPv6');
require_ok('Net::Address::IP::Local');
require_ok('BGPmon::Log');
require_ok('BGPmon::Configure');
require_ok('BGPmon::Fetch');
require_ok('BGPmon::Translator::XFB2BGPdump');
require_ok('BGPmon::Translator::XFB2PerlHash::Simpler');
require_ok('Thread::Queue');
require_ok('Time::HiRes');
require_ok('BGPmon::CPM::PList::Manager');

my $resp = `pwd`;
my $location = 't/';
if($resp =~ m/bgpmon-tools\/BGPmon-core\/t/){
	$location = '';
}


##############################################################################
##############################################################################
#                          Init and Rest tests
##############################################################################
##############################################################################

#Testing Init
my $retVal = BGPmon::Filter::init();
ok($retVal == 0, 'Init Test');

#Testing Reset
my $resetRetVal = BGPmon::Filter::filterReset();
is($resetRetVal, 0, 'Reset Test');


##############################################################################
##############################################################################
#                       Configuration File Tests
##############################################################################
##############################################################################





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





##############################################################################
##############################################################################
#                      XML Parsing Tests
##############################################################################
##############################################################################


#Testing XML Message Parsing
BGPmon::Filter::init();
BGPmon::Filter::parse_config_file($location."bgpmon-filter-config.txt");
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
#--testing that the code checks for a message
BGPmon::Filter::parse_xml_msg();
$errCode = BGPmon::Filter::get_error_code('parse_xml_msg');
is($errCode, BGPmon::Filter::NO_MSG_GIVEN, "No XML Message Given");

#--testing for correct <WITHDRAWN> filtering w/ IPv4
my $xml4msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">129.250.1.248</ADDRESS><PORT>179</PORT><ASN4>2914</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1378756365</TIMESTAMP><DATETIME>2013-09-09T19:52:45Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>760591650</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:WITHDRAW afi="1">103.6.200.0/23</bgp:WITHDRAW><bgp:WITHDRAW afi="1">103.6.202.0/23</bgp:WITHDRAW><bgp:WITHDRAW afi="1">103.6.200.0/22</bgp:WITHDRAW><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>2914</bgp:ASN4><bgp:ASN4>3549</bgp:ASN4><bgp:ASN4>9498</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>55644</bgp:ASN4><bgp:ASN4>45271</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">129.250.1.248</bgp:NEXT_HOP><bgp:MULTI_EXIT_DISC optional="true" transitive="false" partial="false" extended="false" attribute_type="4">83951616</bgp:MULTI_EXIT_DISC><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>420</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>1005</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>2000</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>3000</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>65504</bgp:ASN2><bgp:VALUE>3549</bgp:VALUE></bgp:COMMUNITY><bgp:NLRI afi="1">112.110.94.0/24</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF009102000C176706C8176706CA166706C8006A4001010040023E020F00000B6200000DDD0000251A0000D95C0000D95C0000D95C0000D95C0000D95C0000D95C0000D95C0000D95C0000D95C0000D95C0000D95C0000B0D740030481FA01F880040400000105C008140B6201A40B6203ED0B6207D00B620BB8FFE00DDD18706E5E</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>'; #ipv4 103.6.200.0/23
my $res = BGPmon::Filter::matches($xml4msg);
is($res, TRUE, "XML IPv4 WITHDRAWN tag");


#--testing for correct <WITHDRAW> filtering w/ IPv6 - done in MP_UNREACH_NLRI
my $xml6msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:a480:ffff:ffff::247</ADDRESS><PORT>179</PORT><ASN4>59469</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1378756608</TIMESTAMP><DATETIME>2013-09-09T19:56:48Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>760603508</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:MP_UNREACH_NLRI optional="true" transitive="false" partial="false" extended="true" attribute_type="15" safi="1"><bgp:MP_NLRI afi="2">2a00:7540::/48</bgp:MP_NLRI></bgp:MP_UNREACH_NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0025020000000E900F000A000201302A0075400000</OCTET_MESSAGE><METADATA><NODE_PATH>//bgp:UPDATE/bgp:MP_REACH2a00:7540::/48]/NLRI</NODE_PATH><ANNOTATION>WITH</ANNOTATION></METADATA></BGP_MONITOR_MESSAGE>'; #ipv6 2a00:7540::/48
my $res1 = BGPmon::Filter::matches($xml6msg);
is($res1, TRUE, "XML IPv6 Withdraw tag"); 


#--testing for addresses in <NLRI>
$xml4msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">129.250.1.248</ADDRESS><PORT>179</PORT><ASN4>2914</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1378756776</TIMESTAMP><DATETIME>2013-09-09T19:59:36Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>760612563</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>2914</bgp:ASN4><bgp:ASN4>4323</bgp:ASN4><bgp:ASN4>7545</bgp:ASN4><bgp:ASN4>9942</bgp:ASN4><bgp:ASN4>9942</bgp:ASN4><bgp:ASN4>132895</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">129.250.1.248</bgp:NEXT_HOP><bgp:MULTI_EXIT_DISC optional="true" transitive="false" partial="false" extended="false" attribute_type="4">83951616</bgp:MULTI_EXIT_DISC><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>420</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>1008</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>2000</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>3000</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>65504</bgp:ASN2><bgp:VALUE>4323</bgp:VALUE></bgp:COMMUNITY><bgp:NLRI afi="1">103.27.172.0/23</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF006102000000464001010040021A020600000B62000010E300001D79000026D6000026D60002071F40030481FA01F880040400000105C008140B6201A40B6203F00B6207D00B620BB8FFE010E317671BAC</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>'; #ipv4 103.27.172.0/23
my $res2 = BGPmon::Filter::matches($xml4msg);
is($res2, TRUE, "XML IPv4 NLRI tag"); 



#--testing for address in <MP_REACH_NLRI> for IPv4
$xml4msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:2f00:ffff:ff00::2</ADDRESS><PORT>179</PORT><ASN4>197264</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1378756974</TIMESTAMP><DATETIME>2013-09-09T20:02:54Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>760623023</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>197264</bgp:ASN4><bgp:ASN4>174</bgp:ASN4><bgp:ASN4>6453</bgp:ASN4><bgp:ASN4>36930</bgp:ASN4><bgp:ASN4>37013</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:MP_REACH_NLRI optional="true" transitive="false" partial="false" extended="false" attribute_type="14" safi="1"><bgp:MP_NLRI afi="1">1.1.1.0/24</bgp:MP_NLRI></bgp:MP_REACH_NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0051020000003A40010100400216020500030290000000AE000019350000904200009095800E1A000201102A032F00FFFFFF00000000000000000200202C0FFD10</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>'; #ipv4 1.1.1.0/24
my $res32 = BGPmon::Filter::matches($xml4msg);
is($res32, TRUE, "XML IPv4 MP_REACH_NLRI tag"); 

#--testing for address in <MP_REACH_NLRI> for IPv6 
$xml6msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:2f00:ffff:ff00::2</ADDRESS><PORT>179</PORT><ASN4>197264</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1378756974</TIMESTAMP><DATETIME>2013-09-09T20:02:54Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>760623023</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>197264</bgp:ASN4><bgp:ASN4>174</bgp:ASN4><bgp:ASN4>6453</bgp:ASN4><bgp:ASN4>36930</bgp:ASN4><bgp:ASN4>37013</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:MP_REACH_NLRI optional="true" transitive="false" partial="false" extended="false" attribute_type="14" safi="1"><bgp:MP_NEXT_HOP afi="2">2a03:2f00:ffff:ff00::2</bgp:MP_NEXT_HOP><bgp:MP_NLRI afi="2">2c0f:fd10::/32</bgp:MP_NLRI></bgp:MP_REACH_NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0051020000003A40010100400216020500030290000000AE000019350000904200009095800E1A000201102A032F00FFFFFF00000000000000000200202C0FFD10</OCTET_MESSAGE><METADATA><NODE_PATH>//bgp:UPDATE/bgp:MP_REACH2c0f:fd10::/32]/NLRI</NODE_PATH><ANNOTATION>DPATH</ANNOTATION></METADATA></BGP_MONITOR_MESSAGE>'; #ipv6 2c0f:fd10::/32
my $res3 = BGPmon::Filter::matches($xml6msg);
is($res3, TRUE, "XML IPv6 MP_REACH_NLRI tag"); 




#--testing for as number in as path - last as number
$xml6msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2a03:2f00:ffff:ff00::2</ADDRESS><PORT>179</PORT><ASN4>197264</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:330f</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1378756974</TIMESTAMP><DATETIME>2013-09-09T20:02:54Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>760623023</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>197264</bgp:ASN4><bgp:ASN4>174</bgp:ASN4><bgp:ASN4>6453</bgp:ASN4><bgp:ASN4>36930</bgp:ASN4><bgp:ASN4>12121</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0051020000003A40010100400216020500030290000000AE000019350000904200009095800E1A000201102A032F00FFFFFF00000000000000000200202C0FFD10</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>'; #asn 12121
my $res33 = BGPmon::Filter::matches($xml6msg);
is($res33, TRUE, "XML ASN IN AS PATH");


#--testing more specific prefix matching works correctly
BGPmon::Filter::filterReset();
BGPmon::Filter::parse_config_file($location.'bgpmon-filter-config-ms.txt');
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
$xml4msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">213.248.80.244</ADDRESS><PORT>179</PORT><ASN4>1299</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1378757682</TIMESTAMP><DATETIME>2013-09-09T20:14:42Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>760657428</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>1299</bgp:ASN4><bgp:ASN4>6762</bgp:ASN4><bgp:ASN4>262589</bgp:ASN4><bgp:ASN4>28168</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">213.248.80.244</bgp:NEXT_HOP><bgp:NLRI afi="1">150.150.1.0/24</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF005302000000204001010040021202040000051300001A6A000401BD00006E08400304D5F850F416BAC20418BB3FE016BAC20016BAC20C14BB3FE014BAC20016BAC208</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

my $resa = BGPmon::Filter::matches($xml4msg);
is($resa, TRUE, "More Specific Prefix Matching"); 


#--testing less specific prefix matching works correctly
BGPmon::Filter::filterReset();
BGPmon::Filter::parse_config_file($location.'bgpmon-filter-config-ls.txt');
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
$xml4msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">213.248.80.244</ADDRESS><PORT>179</PORT><ASN4>1299</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1378757682</TIMESTAMP><DATETIME>2013-09-09T20:14:42Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>760657428</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>1299</bgp:ASN4><bgp:ASN4>6762</bgp:ASN4><bgp:ASN4>262589</bgp:ASN4><bgp:ASN4>28168</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">213.248.80.244</bgp:NEXT_HOP><bgp:NLRI afi="1">150.0.0.0/8</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF005302000000204001010040021202040000051300001A6A000401BD00006E08400304D5F850F416BAC20418BB3FE016BAC20016BAC20C14BB3FE014BAC20016BAC208</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';
my $resb = BGPmon::Filter::matches($xml4msg);
is($resb, TRUE, "Less Specific Prefix Matching"); 


#--tEsting that IPv4 address matching works correctly 
BGPmon::Filter::filterReset();
BGPmon::Filter::parse_config_file($location.'bgpmon-filter-config-ip.txt');
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
my $rescc = BGPmon::Filter::matches($xml4msg);
is($rescc, FALSE, "IPv4 Address No Matching");

$xml4msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">213.248.80.244</ADDRESS><PORT>179</PORT><ASN4>1299</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1378757682</TIMESTAMP><DATETIME>2013-09-09T20:14:42Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>760657428</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>1299</bgp:ASN4><bgp:ASN4>6762</bgp:ASN4><bgp:ASN4>262589</bgp:ASN4><bgp:ASN4>28168</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">213.248.80.244</bgp:NEXT_HOP><bgp:NLRI afi="1">151.0.0.0/8</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF005302000000204001010040021202040000051300001A6A000401BD00006E08400304D5F850F416BAC20418BB3FE016BAC20016BAC20C14BB3FE014BAC20016BAC208</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';
$rescc = BGPmon::Filter::matches($xml4msg);
is($rescc, TRUE, "IPv4 Address Matching");




#--Testing that the filter will deliever true if 0.0.0.0/0 is given (accept all)
BGPmon::Filter::filterReset();
BGPmon::Filter::parse_config_file($location.'bgpmon-filter-config-all-ms.txt');
BGPmon::Filter::condense_prefs();
BGPmon::Filter::optimize_prefs();
my $num = BGPmon::Filter::get_total_num_filters();
is($num, 1, "Number of Filters");
$rescc = BGPmon::Filter::matches($xml4msg);
is($rescc, TRUE, "Filter All");






done_testing();

