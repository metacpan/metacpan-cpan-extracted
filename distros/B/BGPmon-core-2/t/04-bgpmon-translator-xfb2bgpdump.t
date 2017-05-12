use warnings;
use strict;
use Test::More;
use Data::Dumper;
BEGIN {use_ok( 'BGPmon::Translator::XFB2BGPdump' );}
use BGPmon::Translator::XFB2BGPdump qw(translate_message get_error_code get_error_message);

our $bgp_msg_0_description = "Incomplete message.";
our $bgp_msg_0 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">213.248.80.244</ADDRESS><PORT>179</PORT><ASN4>1299</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1380322461</TIMESTAMP><DATETIME>2013-09-27T22:54:21Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>593969376</SEQUENCE_NUMBER><COLLECTION>TABLE_DUMP</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>1299</bgp:ASN4><bgp:ASN4>3356</bgp:ASN4><bgp:ASN4>20485</bgp:AS';

our $bgp_msg_1_description = "Valid XML, type STATUS insead of UPDATE";
our $bgp_msg_1 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1380323701</TIMESTAMP><DATETIME>2013-09-27T23:15:01Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1705566568</SEQUENCE_NUMBER><STATUS Author_Xpath="/BGP_MONITOR_MESSAGE/MONITOR"><TYPE>SESSION_STATUS</TYPE></STATUS></BGP_MONITOR_MESSAGE>';

our $bgp_msg_2_description = "Invalid XML, no timestamp"; 
our $bgp_msg_2 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">213.248.80.244</ADDRESS><PORT>179</PORT><ASN4>1299</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><SEQUENCE_NUMBER>593969376</SEQUENCE_NUMBER><COLLECTION>TABLE_DUMP</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>1299</bgp:ASN4><bgp:ASN4>3356</bgp:ASN4><bgp:ASN4>20485</bgp:ASN4><bgp:ASN4>9198</bgp:ASN4><bgp:ASN4>43994</bgp:ASN4><bgp:ASN4>47254</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">213.248.80.244</bgp:NEXT_HOP><bgp:NLRI afi="1">93.190.10.0/24</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0043020000002840010100400304D5F850F440021A02060000051300000D1C00005005000023EE0000ABDA0000B896185DBE0A</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

our $bgp_msg_3_description = "No peer AS.";
our $bgp_msg_3 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1380322461</TIMESTAMP><DATETIME>2013-09-27T22:54:21Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>593969376</SEQUENCE_NUMBER><COLLECTION>TABLE_DUMP</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>1299</bgp:ASN4><bgp:ASN4>3356</bgp:ASN4><bgp:ASN4>20485</bgp:ASN4><bgp:ASN4>9198</bgp:ASN4><bgp:ASN4>43994</bgp:ASN4><bgp:ASN4>47254</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">213.248.80.244</bgp:NEXT_HOP><bgp:NLRI afi="1">93.190.10.0/24</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0043020000002840010100400304D5F850F440021A02060000051300000D1C00005005000023EE0000ABDA0000B896185DBE0A</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

our $bgp_msg_4_description = "No peer IP.";
our $bgp_msg_4 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ASN4>666</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1380322461</TIMESTAMP><DATETIME>2013-09-27T22:54:21Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>593969376</SEQUENCE_NUMBER><COLLECTION>TABLE_DUMP</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>1299</bgp:ASN4><bgp:ASN4>3356</bgp:ASN4><bgp:ASN4>20485</bgp:ASN4><bgp:ASN4>9198</bgp:ASN4><bgp:ASN4>43994</bgp:ASN4><bgp:ASN4>47254</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">213.248.80.244</bgp:NEXT_HOP><bgp:NLRI afi="1">93.190.10.0/24</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0043020000002840010100400304D5F850F440021A02060000051300000D1C00005005000023EE0000ABDA0000B896185DBE0A</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

our $bgp_msg_5_description = "Valid XML: 1 new prefix";
our @bgp_msg_5_bgpdump = ("BGP4MP|1380326253|A|205.166.205.202|6360|64.187.64.0/23|6360 4323 1239 209 16608");
our $bgp_msg_5 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">205.166.205.202</ADDRESS><PORT>179</PORT><ASN4>6360</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1380326253</TIMESTAMP><DATETIME>2013-09-27T23:57:33Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1705950248</SEQUENCE_NUMBER><COLLECTION>LIVE</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">INCOMPLETE</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>6360</bgp:ASN4><bgp:ASN4>4323</bgp:ASN4><bgp:ASN4>1239</bgp:ASN4><bgp:ASN4>209</bgp:ASN4><bgp:ASN4>16608</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">205.166.205.202</bgp:NEXT_HOP><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>65535</bgp:ASN2><bgp:VALUE>65281</bgp:VALUE></bgp:COMMUNITY><bgp:NLRI afi="1">64.187.64.0/23</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF004A020000002B400101024002160205000018D8000010E3000004D7000000D1000040E0400304CDA6CDCAC00804FFFFFF011740BB401840BB40</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

our $bgp_msg_6_description = "Valid XML: Multiple withdrawn prefixes";
our @bgp_msg_6_bgpdump = ('BGP4MP|1380580207|W|194.71.0.1|48285|185.22.137.0/24',
		          'BGP4MP|1380580207|W|194.71.0.1|48285|69.38.178.0/24',
		          'BGP4MP|1380580207|W|194.71.0.1|48285|108.61.128.0/18',
		          'BGP4MP|1380580207|W|194.71.0.1|48285|109.161.64.0/20',
		          'BGP4MP|1380580207|W|194.71.0.1|48285|143.70.237.0/24',
		          'BGP4MP|1380580207|W|194.71.0.1|48285|186.232.14.0/23',
		          'BGP4MP|1380580207|W|194.71.0.1|48285|192.58.232.0/24',
		          'BGP4MP|1380580207|W|194.71.0.1|48285|205.107.212.0/24');
our $bgp_msg_6 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">194.71.0.1</ADDRESS><PORT>179</PORT><ASN4>48285</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1380580207</TIMESTAMP><DATETIME>2013-09-30T22:30:07Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>393363661</SEQUENCE_NUMBER><COLLECTION>LIVE</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:WITHDRAW afi="1">185.22.137.0/24</bgp:WITHDRAW><bgp:WITHDRAW afi="1">69.38.178.0/24</bgp:WITHDRAW><bgp:WITHDRAW afi="1">108.61.128.0/18</bgp:WITHDRAW><bgp:WITHDRAW afi="1">109.161.64.0/20</bgp:WITHDRAW><bgp:WITHDRAW afi="1">143.70.237.0/24</bgp:WITHDRAW><bgp:WITHDRAW afi="1">186.232.14.0/23</bgp:WITHDRAW><bgp:WITHDRAW afi="1">192.58.232.0/24</bgp:WITHDRAW><bgp:WITHDRAW afi="1">205.107.212.0/24</bgp:WITHDRAW></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF003702002018B91689184526B2126C3D80146DA140188F46ED17BAE80E18C03AE818CD6BD40000</OCTET_MESSAGE><METADATA><NODE_PATH>//bgp:UPDATE["185.22.137.0/24"]/bgp:WITHDRAW</NODE_PATH><ANNOTATION>DUPW</ANNOTATION></METADATA><METADATA><NODE_PATH>//bgp:UPDATE["69.38.178.0/24"]/bgp:WITHDRAW</NODE_PATH><ANNOTATION>DUPW</ANNOTATION></METADATA><METADATA><NODE_PATH>//bgp:UPDATE["108.61.128.0/18"]/bgp:WITHDRAW</NODE_PATH><ANNOTATION>DUPW</ANNOTATION></METADATA><METADATA><NODE_PATH>//bgp:UPDATE["109.161.64.0/20"]/bgp:WITHDRAW</NODE_PATH><ANNOTATION>DUPW</ANNOTATION></METADATA><METADATA><NODE_PATH>//bgp:UPDATE["143.70.237.0/24"]/bgp:WITHDRAW</NODE_PATH><ANNOTATION>DUPW</ANNOTATION></METADATA><METADATA><NODE_PATH>//bgp:UPDATE["186.232.14.0/23"]/bgp:WITHDRAW</NODE_PATH><ANNOTATION>DUPW</ANNOTATION></METADATA><METADATA><NODE_PATH>//bgp:UPDATE["192.58.232.0/24"]/bgp:WITHDRAW</NODE_PATH><ANNOTATION>DUPW</ANNOTATION></METADATA><METADATA><NODE_PATH>//bgp:UPDATE["205.107.212.0/24"]/bgp:WITHDRAW</NODE_PATH><ANNOTATION>DUPW</ANNOTATION></METADATA></BGP_MONITOR_MESSAGE>';

our $bgp_msg_7_description = "AFI of 1 withdrawn prefix set to IPV6";
our @bgp_msg_7_bgpdump = ();
our $bgp_msg_7 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">194.71.0.1</ADDRESS><PORT>179</PORT><ASN4>48285</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1380580207</TIMESTAMP><DATETIME>2013-09-30T22:30:07Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>393363661</SEQUENCE_NUMBER><COLLECTION>LIVE</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:WITHDRAW afi="2">185.22.137.0/24</bgp:WITHDRAW></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF003702002018B91689184526B2126C3D80146DA140188F46ED17BAE80E18C03AE818CD6BD40000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

our $bgp_msg_9_description = "AFI of 1 announced prefix set to IPV6";#TODO
our @bgp_msg_9_bgpdump = ("BGP4MP|1336075235|A|187.16.217.104|613|84.205.74.0/24|262757 16735 3549 3257 12637 12654");
our $bgp_msg_9 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">164.128.32.11</ADDRESS><PORT>179</PORT><ASN4>3303</ASN4></SOURCE><DEST><ADDRESS afi="1">127.0.0.1</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.102</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1372636819</TIMESTAMP><DATETIME>2013-07-01T00:00:19Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>226125243</SEQUENCE_NUMBER><COLLECTION>LIVE</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>3303</bgp:ASN4><bgp:ASN4>3491</bgp:ASN4><bgp:ASN4>18187</bgp:ASN4><bgp:ASN4>9821</bgp:ASN4><bgp:ASN4>9821</bgp:ASN4><bgp:ASN4>45600</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">164.128.32.11</bgp:NEXT_HOP><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>3303</bgp:ASN2><bgp:VALUE>1004</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>3303</bgp:ASN2><bgp:VALUE>1006</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>3303</bgp:ASN2><bgp:VALUE>3052</bgp:VALUE></bgp:COMMUNITY><bgp:NLRI afi="3">MALLICIOUS_ADDRESS_INSERTED</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF005202000000374001010040021A020600000CE700000DA30000470B0000265D0000265D0000B220400304A480200BC0080C0CE703EC0CE703EE0CE70BEC16CA5C94</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

our $bgp_msg_11_description = "Valid XML: Table dump message";
our @bgp_msg_11_bgpdump = ("TABLE_DUMP2|1380322461|A|213.248.80.244|1299|93.190.10.0/24|1299 3356 20485 9198 43994 47254");
our $bgp_msg_11 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">213.248.80.244</ADDRESS><PORT>179</PORT><ASN4>1299</ASN4></SOURCE><DEST><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1380322461</TIMESTAMP><DATETIME>2013-09-27T22:54:21Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>593969376</SEQUENCE_NUMBER><COLLECTION>TABLE_DUMP</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>1299</bgp:ASN4><bgp:ASN4>3356</bgp:ASN4><bgp:ASN4>20485</bgp:ASN4><bgp:ASN4>9198</bgp:ASN4><bgp:ASN4>43994</bgp:ASN4><bgp:ASN4>47254</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">213.248.80.244</bgp:NEXT_HOP><bgp:NLRI afi="1">93.190.10.0/24</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0043020000002840010100400304D5F850F440021A02060000051300000D1C00005005000023EE0000ABDA0000B896185DBE0A</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

our $bgp_msg_12_description = "Valid XML: IPv6 MP_REACH message";
our @bgp_msg_12_bgpdump = ("BGP4MP|1380586060|A|2001:1620:1::203|13030|2a00:7540::/48|13030 6939 31692 31692 41938 8359 8359 41938 31692 57401");
our $bgp_msg_12 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2001:1620:1::203</ADDRESS><PORT>179</PORT><ASN4>13030</ASN4></SOURCE><DEST><ADDRESS afi="1">127.0.0.1</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:3370</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1380586060</TIMESTAMP><DATETIME>2013-10-01T00:07:40Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>718751799</SEQUENCE_NUMBER><COLLECTION>LIVE</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>13030</bgp:ASN4><bgp:ASN4>6939</bgp:ASN4><bgp:ASN4>31692</bgp:ASN4><bgp:ASN4>31692</bgp:ASN4><bgp:ASN4>41938</bgp:ASN4><bgp:ASN4>8359</bgp:ASN4><bgp:ASN4>8359</bgp:ASN4><bgp:ASN4>41938</bgp:ASN4><bgp:ASN4>31692</bgp:ASN4><bgp:ASN4>57401</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:MULTI_EXIT_DISC optional="true" transitive="false" partial="false" extended="false" attribute_type="4">16777216</bgp:MULTI_EXIT_DISC><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>13030</bgp:ASN2><bgp:VALUE>61</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>13030</bgp:ASN2><bgp:VALUE>1605</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>13030</bgp:ASN2><bgp:VALUE>51102</bgp:VALUE></bgp:COMMUNITY><bgp:MP_REACH_NLRI optional="true" transitive="false" partial="false" extended="false" attribute_type="14" safi="1"><bgp:MP_NEXT_HOP afi="2">2001:1620:1::203</bgp:MP_NEXT_HOP><bgp:MP_NLRI afi="2">2a00:7540::/48</bgp:MP_NLRI></bgp:MP_REACH_NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF007D02000000664001010040022A020A000032E600001B1B00007BCC00007BCC0000A3D2000020A7000020A70000A3D200007BCC0000E03980040400000001C0080C32E6003D32E6064532E6C79E800E1C000201102001162000010000000000000000020300302A0075400000</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

our $bgp_msg_13_description = "Valid XML: IPv6 MP_UNREACH message";
our @bgp_msg_13_bgpdump = ('BGP4MP|1380586081|W|2001:470:0:1a::1|6939|2408:8056:4f00::/40',
                           'BGP4MP|1380586081|W|2001:470:0:1a::1|6939|2408:8ffe::/32',
                           'BGP4MP|1380586081|W|2001:470:0:1a::1|6939|100::/1');
our $bgp_msg_13 = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="2">2001:470:0:1a::1</ADDRESS><PORT>179</PORT><ASN4>6939</ASN4></SOURCE><DEST><ADDRESS afi="1">127.0.0.1</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="2">2001:468:d01:33::80df:3370</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1380586081</TIMESTAMP><DATETIME>2013-10-01T00:08:01Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>718756384</SEQUENCE_NUMBER><COLLECTION>LIVE</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:MP_UNREACH_NLRI optional="true" transitive="false" partial="false" extended="false" attribute_type="15" safi="1"><bgp:MP_NLRI afi="2">2408:8056:4f00::/40</bgp:MP_NLRI><bgp:MP_NLRI afi="2">2408:8ffe::/32</bgp:MP_NLRI><bgp:MP_NLRI afi="2">100::/1</bgp:MP_NLRI></bgp:MP_UNREACH_NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00280200000011800F0E00020128240880564F2024088FFE</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

# Test for complete xml message.
my $out = translate_message();
ok (!defined($out), "Testing for complete XML correct output return.");
my $error_code = get_error_code('translate_message');
ok ($error_code == 701, "Testing for complete XML error code");


# Test for invalid xml message
$out = translate_message($bgp_msg_0);
ok (!defined($out), "Testing for complete invalid XML output return.");
$error_code = get_error_code('translate_message');
ok ($error_code == 703, "Testing for invalid XML");

# Test for message with type not UPDATE
$out = translate_message($bgp_msg_1);
ok (!defined($out), "Testing for non update message output return.");
$error_code = get_error_code('translate_message');
ok ($error_code == 705, "Testing recognizing non update message");

# Test for message with invalid timestamp.
$out = translate_message($bgp_msg_2);
ok (!defined($out), "Testing for invalid timestamp output return.");
$error_code = get_error_code('translate_message');
ok ($error_code == 706, "Testing invalid timestamp");

# Test for message with no peer AS.
$out = translate_message($bgp_msg_3);
ok (!defined($out), "Testing for invalid AS_PATH output return.");
$error_code = get_error_code('translate_message');
ok ($error_code == 707, "Testing missing peer ASN");

# Test for message with no peer IP.
$out = translate_message($bgp_msg_4);
ok (!defined($out), "Testing for invalid peer information output return.");
$error_code = get_error_code('translate_message');
ok ($error_code == 708, "Testing missing peer IP");

# Test for IPv4 announced.
$out = translate_message($bgp_msg_5);
ok (defined($out), "Testing for IPv4 NLRI Announcement output return.");
ok(scalar(@$out) == scalar(@bgp_msg_5_bgpdump),
	"Testing IPv4 announcements");
ok(@{$out}[0] eq $bgp_msg_5_bgpdump[0], 
	"IPv4 announcement output");

# Test for IPv4 withdrawn
$out = undef;
$out = translate_message($bgp_msg_6);
ok (defined($out), "Testing for IPv4 Withdraw output return.");
$error_code = get_error_code('translate_message');
my $error_msg = get_error_message('translate_message');
my @bgpdump_lines = @{$out};
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_6_bgpdump),
	"Testing IPv4 withdraw");
ok($bgpdump_lines[0] eq $bgp_msg_6_bgpdump[0], 
	"IPv4 withdraw output");
ok($bgpdump_lines[-1] eq $bgp_msg_6_bgpdump[-1], 
	"IPv4 withdraw ending output ");

# Test for invalid AFI in withdrawn
$out = undef;
$out = translate_message($bgp_msg_7);
ok (defined($out), "Testing for invalid IPv4 Withdraw output return.");
@bgpdump_lines = @{$out};
$error_code = get_error_code('translate_message');
ok ($error_code == 710, "Testing invalid withdraw");
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_7_bgpdump),
	"invalid withdraw size");


# Test for invalid AFI in NLRI
$out = undef;
$out = translate_message($bgp_msg_9);
ok (!defined($out), "Testing for invalid afi in IPv4 Ann. output return.");
$error_code = get_error_code('translate_message');
ok ($error_code == 709, "Testing invalid AFI in NLRI");

# Test for valid Table Dump message
$out = undef;
$out = translate_message($bgp_msg_11);
ok (defined($out), "Testing for valid table dump output return.");
@bgpdump_lines = @{$out};
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_11_bgpdump),
	"invalid withdraw size");
ok($bgpdump_lines[0] eq $bgp_msg_11_bgpdump[0], "Testing for valid table dump string.");

# Test for valid IPv6 Announcement
$out = undef;
$out = translate_message($bgp_msg_12);
ok (defined($out), "Testing for valid IPv6 ann. output return.");
@bgpdump_lines = @{$out};
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_12_bgpdump),
	"IPv6 ann. return size");
ok($bgpdump_lines[0] eq $bgp_msg_12_bgpdump[0], "Testing for valid IPv6 ann. string.");

# Test for valid IPv6 Withdraw
$out = undef;
$out = translate_message($bgp_msg_13);
ok (defined($out), "Testing for valid IPv6 with. output return.");
@bgpdump_lines = @{$out};
ok(scalar(@bgpdump_lines) == scalar(@bgp_msg_13_bgpdump),
	"IPv6 with. return size");
ok($bgpdump_lines[0] eq $bgp_msg_13_bgpdump[0], "Testing valid IPv6 with. string.");
ok($bgpdump_lines[-1] eq $bgp_msg_13_bgpdump[0-1], "Testing another valid IPv6 with. string.");


done_testing();
