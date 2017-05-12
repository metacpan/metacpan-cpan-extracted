#Test script for XFB2PerlHash::Simple

use strict;
use warnings;
use BGPmon::Translator::XFB2PerlHash::Simple qw/init get_timestamp get_dateTime
 get_nlri get_mp_nlri get_withdrawn get_mp_withdrawn get_peering get_origin 
get_as_path get_as4_path get_next_hop get_mp_next_hop get_xml_string 
get_error_code get_error_message get_error_msg/;
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

my $test_fh;
open($test_fh,"<",$test_file) or die "unable to open sample file";

######################## VALIDATION CASES #####################################
#Read the first message from the XML file and initialize Simple with it.
my $msg = <$test_fh>;   #This call skips the first <xml> tag in the file
$msg = <$test_fh>;      #This call reads the first XML message (an ARCHIVER msg)
#Since the first message in the test file is not XFB but is valid XML, the init
#function should work correctly.
my $ret = init($msg);
is(get_error_code('init'),0,'init - check error code on invalid XFB message');
is($ret,1,'init - valid XML message/invalid XFB message');

#However, since the message is NOT valid XFB, trying to get fields out of it via
#the Simple interface will not/should not work.
$ret = get_timestamp();
is($ret,undef,'get_timestamp - invalid message type');

$msg = <$test_fh>;      #Now we read a valid XFB message
$ret = init($msg);

#Make sure we can extract correct fields out of a valid message
#Check the timestamp
$ret = get_timestamp();
is($ret,'1340136901','get_timestamp - valid message w/ valid timestamp');

#Check dateTime
$ret = get_dateTime();
is($ret,'2012-06-19T20:15:01Z','get_dateTime - valid message/valid dateTime');

#Get the Withdrawn array (XFB2PerlHash forces this to always be an array)
my @arr = get_withdrawn();
is(scalar @arr,1,'get_withdrawn - single withdrawn route');
is(ref $arr[0],'HASH','get_withdrawn - check that the array contains hashes');

#Read a couple messages down to get to an announcement message
$msg = <$test_fh>;
$msg = <$test_fh>;
$ret = init($msg);
is($ret,1,'init - check initilization with new message');
#Let's check some path attributes, starting with origin
$ret = get_origin();
is($ret,'IGP','get_origin - valid');
#Get the v4 next hop
$ret = get_next_hop();
is($ret,'89.149.178.10','get_next_hop - valid v4 NH');
#Get an AS Path (returns an array of hashes)
@arr = get_as_path();
is(ref $arr[0],'HASH','get_as_path - confirm array contains hashes');
is(scalar @arr,1,'get_as_path - check that there is only one AS_SEG');
#Finally, get the NLRI from the message (again, returns an array of hashes)
@arr = get_nlri();
is(scalar @arr,1,'get_nlri - get the NLRI successfully');
#Get the peering information (this one returns a hash ref)
my $hash = get_peering();
is(get_error_code('get_peering'),0,'check error code for get_peering');
is($hash->{'SRC_ADDR'}->{'ADDRESS'}->{'content'},'129.82.138.6','get_peering - check address');
#Check that the get_raw function works
$ret = get_xml_string();
is($ret,$msg,'get_xml_string - works correctly');

#Read 3 more messages to get to one with an AS4_PATH
$msg = <$test_fh>;
$msg = <$test_fh>;
$msg = <$test_fh>;
$ret = init($msg);
#Fetch the AS4_PATH attribute (an array of hashes)
@arr = get_as4_path();
#Going deeper into the returned data structure requires some reference work
my $path = $arr[0]->{'AS'};
is(scalar @$path,6,'get_as4_path - fetch the AS4-path correctly');

#Read the next message(s) to test MP_REACH
#First one has a 32-byte MP_REACH next hop field
$msg = <$test_fh>;
$ret = init($msg);
is($ret,1,'init - check return value for new message');
#First, let's get the MP_REACH NEXT_HOP field (which returns an ARRAY! because
#the spec allows for multiple next hops)
@arr = get_mp_next_hop();
is(scalar @arr,2,'get_mp_next_hop - got a length-2 MP next hop array');

#Next, grab the MP_REACH_NLRI hash
$ret = get_mp_nlri();
@arr = $ret->{'NLRI'}->{'PREFIX'};
is(scalar @arr,1,'get_mp_mlri - read the hash and get the actual prefixes');

#Now the MP_UNREACH_NLRI
$ret = get_mp_withdrawn();
is(get_error_code('get_mp_withdrawn'),0,'confirm');
@arr = $ret->{'WITHDRAWN'}->{'PREFIX'};
is(scalar @arr,1,'get_mp_withdrawn - get the hash and extract the NLRI array');


done_testing();
1;

