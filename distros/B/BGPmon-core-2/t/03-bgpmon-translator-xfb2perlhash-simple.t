#Test script for XFB2PerlHash::Simple

use strict;
use warnings;
use BGPmon::Translator::XFB2PerlHash::Simple qw/init get_timestamp get_dateTime
 get_nlri get_mp_nlri get_withdrawn get_mp_withdrawn get_peering get_origin 
get_as_path get_as4_path get_next_hop get_mp_next_hop get_xml_string 
get_xml_message_type get_error_code get_error_message get_error_msg
get_status/;
use Test::More;
use Data::Dumper;

#set the data directory and a test file containing XML messages
#my $data_dir = `echo -n \`pwd\``."/t/data";

my $resp = `pwd`;
my $location = 't/';
if($resp =~ m/bgpmon-tools\/BGPmon-core\/t/){
        $location = '';
}


my $test_file = $location."bgpmon-translator-dup-archiver-msg.xml";

######################## VALIDATION CASES #####################################
#Read the first message from the XML file and initialize Simple with it.
my $test_fh;
open($test_fh,"<",$test_file) or die "unable to open sample file";

my $msg = <$test_fh>;   #This call skips the first <xml> tag in the file
my $badmsg = <$test_fh>;      #This call reads the bad xml
   $msg = <$test_fh>; #good message
my $withmsg = <$test_fh>; #this read the xml message with a withdraw on it
my $withmsg2 = <$test_fh>; #this will hold a message with > 1 withdraws
my $nlrimsg = <$test_fh>; #this message hold an nlri
my $mpnlrimsg = <$test_fh>; #this message hold an mp nlri
my $unreachmsg = <$test_fh>; #this message holds nan mp unreach
my $as4msg = <$test_fh>; #this message holds an as4 path

#This message is a bad message purposfully put in to call invalid message errors
my $ret = init($badmsg);
is(get_error_code('init'),0,'init - check error code on invalid XFB message');
is($ret,1,'init - valid XML message/invalid XFB message');
$ret = get_timestamp();
is($ret,undef,'get_timestamp - invalid message type');

#testing timestamps
#-bad message first
$ret = get_timestamp();
is($ret,undef,'get_timestamp - invalid message w/ valid timestamp');
$ret = get_dateTime();
is($ret,undef,'get_dateTime - invalid message/valid dateTime');

#-valid xml message next
$ret = init($msg);
$ret = get_timestamp();
is($ret,'1380138142','get_timestamp - valid message w/ valid timestamp');
$ret = get_dateTime();
is($ret,'2013-09-25T19:42:22Z','get_dateTime - valid message/valid dateTime');


#Testing origin
#-bad message
$ret = init($badmsg);
$ret = get_origin();
is($ret,undef,'get_origin - invalid');
#-valid message
$ret = init($msg);
$ret = get_origin();
is($ret,'INCOMPLETE','get_origin - valid');


#Testing AS_PATH
my $asarr = get_as_path();
is($asarr->{'bgp:AS_SEQUENCE'}->{'bgp:ASN4'}[0]->{'content'},'2518','get_as_path');

#Get the v4 next hop
#-bad message
$ret = init($badmsg);
$ret = get_next_hop();
is($ret,undef,'get_next_hop - invalid v4 NH');
#-valid message
$ret = init($msg);
$ret = get_next_hop();
is($ret,'133.205.1.142','get_next_hop - valid v4 NH');


#Get the Withdrawn array (XFB2PerlHash forces this to always be an array)
#-test with 1 withdraw
$ret = init($withmsg);
my @arr = get_withdrawn();
is(scalar @arr,1,'get_withdrawn - single withdrawn route');

#-test with 2 withdraws
$ret = init($withmsg2);
@arr = get_withdrawn();
is(scalar @arr,2,'get_withdrawn - multiple withdrawn route');



#Test peering information
my $source = get_peering();
is(get_error_code('get_peering'),0,'check error code for get_peering');
is($source->{'ADDRESS'}->{'content'},'119.63.216.246','get_peering - check address');


#Testing xml raw string
$ret = init($withmsg);
my $temp = get_xml_string();
is($temp, $withmsg, "raw xml string");

#Testing the nlri
$ret = init($nlrimsg);
@arr = get_nlri();
is(scalar @arr,1,'get_nlri - get the NLRI successfully');

#Testing the mpnlri
#-getting mp_nlris
$ret = init($mpnlrimsg);
@arr = get_mp_next_hop();
is(scalar @arr,1,'get_mp_next_hop - got a length-2 MP next hop array');

#-getting mp reach nlri
$ret = get_mp_nlri();
@arr = $ret->{'NLRI'}->{'PREFIX'};
is(scalar @arr,1,'get_mp_mlri - read the hash and get the actual prefixes');

#tesint MP_UNREACH_NLRI
$ret = init($unreachmsg);
$ret = get_mp_withdrawn();
@arr = $ret->{'MP_NLRI'};
is(scalar @arr,1,'get_mp_withdrawn - get the hash and extract the NLRI array');


#testomg AS4_PATH attribut
$ret = init($as4msg);
$ret = get_as4_path();
is($ret->{'bgp:AS_SEQUENCE'}->{'bgp:ASN4'}[0]->{'content'},3549,'get_as4_path');

#testing content attribtute
$ret = init($as4msg);
$ret = get_xml_message_type();
ok($ret eq 'LIVE', "get xml message type");




#testing status message attribute
my $statusMsg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><MONITOR><ADDRESS afi="1">128.223.51.15</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1381174201</TIMESTAMP><DATETIME>2013-10-07T19:30:01Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>1229569096</SEQUENCE_NUMBER><STATUS Author_Xpath="/BGP_MONITOR_MESSAGE/MONITOR"><TYPE>SESSION_STATUS</TYPE></STATUS></BGP_MONITOR_MESSAGE>';
$ret = init($statusMsg);
$ret = get_status();
ok($ret eq 'SESSION_STATUS', "get xml status type");
$statusMsg = '<xml></xml>';
$ret = init($statusMsg);
$ret = get_status();
is($ret, undef, "get xml status type undef");


done_testing();
1;

