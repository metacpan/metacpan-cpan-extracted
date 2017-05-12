use strict;
use warnings;
use Test::More;
use BGPmon::Validate;
use Data::Dumper;

#check the dependencies
BEGIN {
  use_ok('XML::LibXML');
  use_ok('BGPmon::Fetch');
}



#setting up testing

my $retval = BGPmon::Validate::init("non_existent_file_name.xsd");
is($retval, 1, "Non-existent file test");
is(BGPmon::Validate::get_error_code('init'), 692, "Confirming get_error_code on init");


$retval = BGPmon::Validate::init("etc/bgp_monitor_2_00.xsd");
is($retval, 0, "Correct XSD file");


$retval = BGPmon::Validate::validate();
is($retval, 1, "No message given to validate");
is(BGPmon::Validate::get_error_code('validate'), 690, "Confirming get_error_code on validate");

$retval = BGPmon::Validate::validate("garbage");
is($retval, 1, "Message did not parse");
is(BGPmon::Validate::get_error_code('validate'), 693, "confirming get_error_code on validate with garbage");


my $xmlMsg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">91.209.102.2</ADDRESS><PORT>179</PORT><ASN2>39756</ASN2></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN2>6447</ASN2></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1376416018</TIMESTAMP><DATETIME>2013-08-13T17:46:58Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1675145523</SEQUENCE_NUMBER><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN2>39756</bgp:ASN2><bgp:ASN2>35449</bgp:ASN2><bgp:ASN2>6830</bgp:ASN2><bgp:ASN2>209</bgp:ASN2><bgp:ASN2>22561</bgp:ASN2><bgp:ASN2>40735</bgp:ASN2></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">91.209.102.2</bgp:NEXT_HOP><bgp:NLRI afi="1">74.51.115.0/24</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0037020000001C4001010040020E02069B4C8A791AAE00D158219F1F4003045BD16602184A3373</OCTET_MESSAGE><METADATA><NODE_PATH>//bgp:UPDATE/bgp:MP_REACH[MP_NLRI="74.51.115.0/24"]/MP_NLRI</NODE_PATH><ANNOTATION>DPATH</ANNOTATION></METADATA></BGP_MONITOR_MESSAGE>';


$retval = BGPmon::Validate::validate($xmlMsg);
is($retval, 0, "Validated valid message");




my $invalidXML = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF006002000000454001010040020E020300000B620000193D0000805F40030481FA01F880040400000103C008140B6201A40B6203EF0B6207D00B620BB8FFE0193DC01008193D3D19000008B318266110</OCTET_MESSAGE><SOURCE><ADDRESS afi="1">129.250.1.248</ADDRESS><PORT>179</PORT><ASN4>2914</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1381273945</TIMESTAMP><DATETIME>2013-10-08T23:12:25Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>261072797</SEQUENCE_NUMBER><COLLECTION>LIVE</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>2914</bgp:ASN4><bgp:ASN4>6461</bgp:ASN4><bgp:ASN4>32863</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">129.250.1.248</bgp:NEXT_HOP><bgp:MULTI_EXIT_DISC optional="true" transitive="false" partial="false" extended="false" attribute_type="4">50397184</bgp:MULTI_EXIT_DISC><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>420</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>1007</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>2000</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>2914</bgp:ASN2><bgp:VALUE>3000</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>65504</bgp:ASN2><bgp:VALUE>6461</bgp:VALUE></bgp:COMMUNITY><bgp:EXTENDED_COMMUNITIES optional="true" transitive="true" partial="false" extended="false" attribute_type="16" extended_communities_type="UNKNOWN"><bgp:HEX_STRING>C01008193D3D190000</bgp:HEX_STRING></bgp:EXTENDED_COMMUNITIES><bgp:NLRI afi="1">38.97.16.0/24</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF006002000000454001010040020E020300000B620000193D0000805F40030481FA01F880040400000103C008140B6201A40B6203EF0B6207D00B620BB8FFE0193DC01008193D3D19000008B318266110</OCTET_MESSAGE><METADATA><NODE_PATH>//bgp:UPDATE/bgp:MP_REACH[MP_NLRI="38.97.16.0/24"]/MP_NLRI</NODE_PATH><ANNOTATION>NANN</ANNOTATION></METADATA></BGP_MONITOR_MESSAGE>';
$retval = BGPmon::Validate::validate($invalidXML);
is($retval, 1, "Saw invalid message");
my $invalidMessage = BGPmon::Validate::get_valid_error();
my $correctRes = "Element \'{urn:ietf:params:xml:ns:bgp_monitor}OCTET_MESSAGE\': This element is not expected. Expected is one of ( {urn:ietf:params:xml:ns:bgp_monitor}SOURCE, {urn:ietf:params:xml:ns:bgp_monitor}DEST, {urn:ietf:params:xml:ns:bgp_monitor}MONITOR ).\n";
is($invalidMessage, $correctRes, "Correct validation error response");

done_testing();
