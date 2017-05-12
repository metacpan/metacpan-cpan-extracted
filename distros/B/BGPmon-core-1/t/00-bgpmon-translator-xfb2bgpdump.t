use warnings;
use strict;
use Test::More;

#BEGIN {use_ok( 'BGPmon::Translator::XFB2BGPdump' );}
use BGPmon::Translator::XFB2BGPdump qw(translate_message get_error_code);

our $bgp_msg_0_description = "Incomplete message.";
our $bgp_msg_0 = '<BGP_MESSAGE length="00002048" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1436555659"/><TIME timestamp="1336075235" datetime="2012-05-03T20:00:35Z" precision_time="399"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>187.16.216.223</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>187.16.217.104</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>613</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="89"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="62"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="26';

our $bgp_msg_1_description = "Valid XFB, type changed from UPDATE to STATUS";
our $bgp_msg_1 = '<BGP_MESSAGE length="00002048" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="STATUS"><BGPMON_SEQ id="127893688" seq_num="1436555659"/><TIME timestamp="1336075235" datetime="2012-05-03T20:00:35Z" precision_time="399"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>187.16.216.223</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>187.16.217.104</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>613</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="89"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="62"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="26"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="6"><AS>262757</AS><AS>16735</AS><AS>3549</AS><AS>3257</AS><AS>12637</AS><AS>12654</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS transitive="TRUE"/><TYPE value="3">NEXT_HOP</TYPE><NEXT_HOP>187.16.217.104</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="7">AGGREGATOR</TYPE><AGGREGATOR><AS>0</AS><ADDR>192.8.8.65</ADDR></AGGREGATOR></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>16735</AS><VALUE>3</VALUE></COMMUNITY><COMMUNITY><AS>16735</AS><VALUE>6016</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="1"><PREFIX label="NANN"><ADDRESS>84.205.74.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="89">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0059020000003E4001010040021A0206000402650000415F00000DDD00000CB90000315D0000316E400304BB10D968C007080000FEBE0A03BC41C00808415F0003415F17801854CD4A</OCTETS></OCTET_MSG></BGP_MESSAGE>';

our $bgp_msg_2_description = "Invalid XFB, no timestamp";
our $bgp_msg_2 = '<BGP_MESSAGE length="00002048" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1436555659"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>187.16.216.223</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>187.16.217.104</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>613</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="89"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="62"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="26"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="6"><AS>262757</AS><AS>16735</AS><AS>3549</AS><AS>3257</AS><AS>12637</AS><AS>12654</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS transitive="TRUE"/><TYPE value="3">NEXT_HOP</TYPE><NEXT_HOP>187.16.217.104</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="7">AGGREGATOR</TYPE><AGGREGATOR><AS>0</AS><ADDR>192.8.8.65</ADDR></AGGREGATOR></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>16735</AS><VALUE>3</VALUE></COMMUNITY><COMMUNITY><AS>16735</AS><VALUE>6016</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="1"><PREFIX label="NANN"><ADDRESS>84.205.74.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="89">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0059020000003E4001010040021A0206000402650000415F00000DDD00000CB90000315D0000316E400304BB10D968C007080000FEBE0A03BC41C00808415F0003415F17801854CD4A</OCTETS></OCTET_MSG></BGP_MESSAGE>';

our $bgp_msg_3_description = "No peer AS.";
our $bgp_msg_3 = '<BGP_MESSAGE length="00002048" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1436555659"/><TIME timestamp="1336075235" datetime="2012-05-03T20:00:35Z" precision_time="399"/><PEERING as_num_len="4"><DST_ADDR><ADDRESS>187.16.216.223</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT></PEERING><ASCII_MSG length="89"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="62"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="26"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="6"><AS>262757</AS><AS>16735</AS><AS>3549</AS><AS>3257</AS><AS>12637</AS><AS>12654</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS transitive="TRUE"/><TYPE value="3">NEXT_HOP</TYPE><NEXT_HOP>187.16.217.104</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="7">AGGREGATOR</TYPE><AGGREGATOR><AS>0</AS><ADDR>192.8.8.65</ADDR></AGGREGATOR></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>16735</AS><VALUE>3</VALUE></COMMUNITY><COMMUNITY><AS>16735</AS><VALUE>6016</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="1"><PREFIX label="NANN"><ADDRESS>84.205.74.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="89">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0059020000003E4001010040021A0206000402650000415F00000DDD00000CB90000315D0000316E400304BB10D968C007080000FEBE0A03BC41C00808415F0003415F17801854CD4A</OCTETS></OCTET_MSG></BGP_MESSAGE>';

our $bgp_msg_4_description = "No peer IP.";
our $bgp_msg_4 = '<BGP_MESSAGE length="00002048" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1436555659"/><TIME timestamp="1336075235" datetime="2012-05-03T20:00:35Z" precision_time="399"/><PEERING as_num_len="4"><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>187.16.216.223</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>613</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="89"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="62"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="26"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="6"><AS>262757</AS><AS>16735</AS><AS>3549</AS><AS>3257</AS><AS>12637</AS><AS>12654</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS transitive="TRUE"/><TYPE value="3">NEXT_HOP</TYPE><NEXT_HOP>187.16.217.104</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="7">AGGREGATOR</TYPE><AGGREGATOR><AS>0</AS><ADDR>192.8.8.65</ADDR></AGGREGATOR></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>16735</AS><VALUE>3</VALUE></COMMUNITY><COMMUNITY><AS>16735</AS><VALUE>6016</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="1"><PREFIX label="NANN"><ADDRESS>84.205.74.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="89">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0059020000003E4001010040021A0206000402650000415F00000DDD00000CB90000315D0000316E400304BB10D968C007080000FEBE0A03BC41C00808415F0003415F17801854CD4A</OCTETS></OCTET_MSG></BGP_MESSAGE>';

our $bgp_msg_5_description = "Valid XFB: 1 new prefix";
our @bgp_msg_5_bgpdump = ("BGP4MP|1336075235|A|187.16.217.104|613|84.205.74.0/24|262757 16735 3549 3257 12637 12654");
our $bgp_msg_5 = '<BGP_MESSAGE length="00002048" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1436555659"/><TIME timestamp="1336075235" datetime="2012-05-03T20:00:35Z" precision_time="399"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>187.16.216.223</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>187.16.217.104</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>613</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="89"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="62"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="26"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="6"><AS>262757</AS><AS>16735</AS><AS>3549</AS><AS>3257</AS><AS>12637</AS><AS>12654</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS transitive="TRUE"/><TYPE value="3">NEXT_HOP</TYPE><NEXT_HOP>187.16.217.104</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="7">AGGREGATOR</TYPE><AGGREGATOR><AS>0</AS><ADDR>192.8.8.65</ADDR></AGGREGATOR></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>16735</AS><VALUE>3</VALUE></COMMUNITY><COMMUNITY><AS>16735</AS><VALUE>6016</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="1"><PREFIX label="NANN"><ADDRESS>84.205.74.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="89">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0059020000003E4001010040021A0206000402650000415F00000DDD00000CB90000315D0000316E400304BB10D968C007080000FEBE0A03BC41C00808415F0003415F17801854CD4A</OCTETS></OCTET_MSG></BGP_MESSAGE>';

our $bgp_msg_6_description = "Valid XFB: 3 withdrawn prefixes";
our @bgp_msg_6_bgpdump = ("BGP4MP|133771499|W|205.167.76.241|10876|205.104.52.0/24",
	"BGP4MP|133771499|W|205.167.76.241|10876|205.104.50.0/23",
	"BGP4MP|133771499|W|205.167.76.241|10876|198.143.33.0/24");
our $bgp_msg_6 = '<BGP_MESSAGE length="00001270" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="2128112124" seq_num="821217386"/><TIME timestamp="1337714997" datetime="2012-05-22T19:29:57Z" precision_time="542"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>129.82.138.6</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>4321</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>205.167.76.241</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>10876</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="35"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="12" path_attr_len="0"><WITHDRAWN count="3"><PREFIX label="WITH"><ADDRESS>205.104.52.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>205.104.50.0/23</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>198.143.33.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></WITHDRAWN><PATH_ATTRIBUTES count="0"/><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="35">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF002302000C18CD683417CD683218C68F210000</OCTETS></OCTET_MSG></BGP_MESSAGE>';

our $bgp_msg_7_description = "AFI of 1 withdrawn prefix set to IPV6";
our @bgp_msg_7_bgpdump = ("BGP4MP|133771499|W|205.167.76.241|10876|205.104.50.0/23",
	"BGP4MP|133771499|W|205.167.76.241|10876|198.143.33.0/24");
our $bgp_msg_7 = '<BGP_MESSAGE length="00001270" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="2128112124" seq_num="821217386"/><TIME timestamp="1337714997" datetime="2012-05-22T19:29:57Z" precision_time="542"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>129.82.138.6</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>4321</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>205.167.76.241</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>10876</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="35"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="12" path_attr_len="0"><WITHDRAWN count="3"><PREFIX label="WITH"><ADDRESS>2a00:ddc0::/32</ADDRESS><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>205.104.50.0/23</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>198.143.33.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></WITHDRAWN><PATH_ATTRIBUTES count="0"/><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="35">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF002302000C18CD683417CD683218C68F210000</OCTETS></OCTET_MSG></BGP_MESSAGE>';

our $bgp_msg_8_description = "SAFI one 1 withdrawn prefix set to MULTICAST";
our @bgp_msg_8_bgpdump = ("BGP4MP|133771499|W|205.167.76.241|10876|205.104.52.0/24",
	"BGP4MP|133771499|W|205.167.76.241|10876|205.104.50.0/23");
our $bgp_msg_8 = '<BGP_MESSAGE length="00001270" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="2128112124" seq_num="821217386"/><TIME timestamp="1337714997" datetime="2012-05-22T19:29:57Z" precision_time="542"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>129.82.138.6</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>4321</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>205.167.76.241</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>10876</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="35"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="12" path_attr_len="0"><WITHDRAWN count="3"><PREFIX label="WITH"><ADDRESS>205.104.52.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>205.104.50.0/23</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="WITH"><ADDRESS>225.0.0.0/16</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="2">MULTICAST</SAFI></PREFIX></WITHDRAWN><PATH_ATTRIBUTES count="0"/><NLRI count="0"/></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="35">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF002302000C18CD683417CD683218C68F210000</OCTETS></OCTET_MSG></BGP_MESSAGE>';

our $bgp_msg_9_description = "AFI of 1 announced prefix set to IPV6";
our @bgp_msg_9_bgpdump = ("BGP4MP|1336075235|A|187.16.217.104|613|84.205.74.0/24|262757 16735 3549 3257 12637 12654");
our $bgp_msg_9 = '<BGP_MESSAGE length="00002048" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1436555659"/><TIME timestamp="1336075235" datetime="2012-05-03T20:00:35Z" precision_time="399"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>187.16.216.223</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>187.16.217.104</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>613</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="89"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="62"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="26"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="6"><AS>262757</AS><AS>16735</AS><AS>3549</AS><AS>3257</AS><AS>12637</AS><AS>12654</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS transitive="TRUE"/><TYPE value="3">NEXT_HOP</TYPE><NEXT_HOP>187.16.217.104</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="7">AGGREGATOR</TYPE><AGGREGATOR><AS>0</AS><ADDR>192.8.8.65</ADDR></AGGREGATOR></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>16735</AS><VALUE>3</VALUE></COMMUNITY><COMMUNITY><AS>16735</AS><VALUE>6016</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="2"><PREFIX label="NANN"><ADDRESS>84.205.74.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="NANN"><ADDRESS>2a00:ddc0::/32</ADDRESS><AFI value="2">IPV6</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="89">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0059020000003E4001010040021A0206000402650000415F00000DDD00000CB90000315D0000316E400304BB10D968C007080000FEBE0A03BC41C00808415F0003415F17801854CD4A</OCTETS></OCTET_MSG></BGP_MESSAGE>';

our $bgp_msg_10_description = "SAFI of 1 announced prefix set to MULTICAST";
our @bgp_msg_10_bgpdump = ("BGP4MP|1336075235|A|187.16.217.104|613|84.205.74.0/24|262757 16735 3549 3257 12637 12654");
our $bgp_msg_10 = '<BGP_MESSAGE length="00002048" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="127893688" seq_num="1436555659"/><TIME timestamp="1336075235" datetime="2012-05-03T20:00:35Z" precision_time="399"/><PEERING as_num_len="4"><SRC_ADDR><ADDRESS>187.16.216.223</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>187.16.217.104</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>613</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="89"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="62"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="5"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="0">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length="26"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="6"><AS>262757</AS><AS>16735</AS><AS>3549</AS><AS>3257</AS><AS>12637</AS><AS>12654</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS transitive="TRUE"/><TYPE value="3">NEXT_HOP</TYPE><NEXT_HOP>187.16.217.104</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="7">AGGREGATOR</TYPE><AGGREGATOR><AS>0</AS><ADDR>192.8.8.65</ADDR></AGGREGATOR></ATTRIBUTE><ATTRIBUTE length="8"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>16735</AS><VALUE>3</VALUE></COMMUNITY><COMMUNITY><AS>16735</AS><VALUE>6016</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="2"><PREFIX label="NANN"><ADDRESS>84.205.74.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX><PREFIX label="NANN"><ADDRESS>225.0.0.0/16</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="2">MULTICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="89">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0059020000003E4001010040021A0206000402650000415F00000DDD00000CB90000315D0000316E400304BB10D968C007080000FEBE0A03BC41C00808415F0003415F17801854CD4A</OCTETS></OCTET_MSG></BGP_MESSAGE>';

# Test for complete xml message.
my %out = translate_message();
my $error_code = get_error_code('translate_message');
ok ($error_code == 701, "actual: $error_code, expected: 701");
my $num_keys = scalar(%out);
ok ($num_keys == 0, "actual: $num_keys, expected: 0");


# Test for invalid xml message
%out = translate_message($bgp_msg_0);
$error_code = get_error_code('translate_message');
ok ($error_code == 703, "actual: $error_code, expected: 703");
$num_keys = scalar(%out);
ok ($num_keys == 0, "actual: $num_keys, expected: 0");

# Test for message with type not UPDATE
%out = translate_message($bgp_msg_1);
$error_code = get_error_code('translate_message');
ok ($error_code == 705, "actual: $error_code, expected: 705");
$num_keys = scalar(%out);
ok ($num_keys == 0, "actual: $num_keys, expected: 0");

# Test for message with invalid timestamp.
%out = translate_message($bgp_msg_2);
$error_code = get_error_code('translate_message');
ok ($error_code == 706, "actual: $error_code, expected: 706");
$num_keys = scalar(%out);
ok ($num_keys == 0, "actual: $num_keys, expected: 0");

# Test for message with no peer AS.
%out = translate_message($bgp_msg_3);
$error_code = get_error_code('translate_message');
ok ($error_code == 707, "actual: $error_code, expected: 707");
$num_keys = scalar(%out);
ok ($num_keys == 0, "actual: $num_keys, expected: 0");

# Test for message with no peer IP.
%out = translate_message($bgp_msg_4);
$error_code = get_error_code('translate_message');
ok ($error_code == 708, "actual: $error_code, expected: 708");
$num_keys = scalar(%out);
ok ($num_keys == 0, "actual: $num_keys, expected: 0");

# Test for IPv4 announced.
%out = translate_message($bgp_msg_5);
my @bgpdump_lines = @{$out{1}};
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_5_bgpdump),
	"actual: " . scalar(@bgpdump_lines) .
	" expected: " .scalar(@bgp_msg_5_bgpdump));

# Test for IPv4 withdrawn
%out = translate_message($bgp_msg_6);
@bgpdump_lines = @{$out{1}};
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_6_bgpdump),
	"actual: " . scalar(@bgpdump_lines) .
	" expected: " .scalar(@bgp_msg_6_bgpdump));

# Test for invalid AFI in withdrawn
%out = translate_message($bgp_msg_7);
@bgpdump_lines = @{$out{1}};
$error_code = get_error_code('translate_message');
ok ($error_code == 710, "actual: $error_code, expected: 710");
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_7_bgpdump),
	"actual: " . scalar(@bgpdump_lines) .
	" expected: " .scalar(@bgp_msg_7_bgpdump));

# Test for invalid SAFI in withdrawn
%out = translate_message($bgp_msg_8);
@bgpdump_lines = @{$out{1}};
$error_code = get_error_code('translate_message');
ok ($error_code == 710, "actual: $error_code, expected: 710");
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_8_bgpdump),
	"actual: " . scalar(@bgpdump_lines) .
	" expected: " .scalar(@bgp_msg_8_bgpdump));

# Test for invalid AFI in NLRI
%out = translate_message($bgp_msg_9);
@bgpdump_lines = @{$out{1}};
$error_code = get_error_code('translate_message');
ok ($error_code == 709, "actual: $error_code, expected: 709");
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_9_bgpdump),
	"actual: " . scalar(@bgpdump_lines) .
	" expected: " .scalar(@bgp_msg_9_bgpdump));

# Test for invalid SAFI in NLRI
%out = translate_message($bgp_msg_10);
@bgpdump_lines = @{$out{1}};
$error_code = get_error_code('translate_message');
ok ($error_code == 709, "actual: $error_code, expected: 709");
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_10_bgpdump),
	"actual: " . scalar(@bgpdump_lines) .
	" expected: " .scalar(@bgp_msg_10_bgpdump));

done_testing();
