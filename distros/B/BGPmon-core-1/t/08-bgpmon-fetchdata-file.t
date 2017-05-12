#Test suite for BGPmon::Fetch::File

use warnings;
use strict;
use Test::More;

use BGPmon::Fetch::File qw/init_bgpdata connect_file read_xml_message
 get_error_code get_error_message close_connection messages_read is_connected/;
use BGPmon::Log;

my $first_msg = "<ARCHIVER><TIME timestamp=\"1340136304\" datetime=\"2012-06-19T20:05:04Z\"/><EVENT cause=\"CREATE_NEW_FILE\">OPENED</EVENT></ARCHIVER>";

my $second_msg = "<BGP_MESSAGE xmlns=\"urn:ietf:params:xml:ns:xfb-0.4\" length=\"00001735\" version=\"0.4\" type_value=\"2\" type=\"UPDATE\"><BGPMON_SEQ id=\"2128112124\" seq_num=\"-1913318876\"/><TIME timestamp=\"1340136301\" datetime=\"2012-06-19T20:05:01Z\" precision_time=\"187\"/><PEERING as_num_len=\"2\"><SRC_ADDR><ADDRESS>129.82.138.6</ADDRESS><AFI value=\"1\">IPV4</AFI></SRC_ADDR><SRC_PORT>4321</SRC_PORT><SRC_AS>6447</SRC_AS><DST_ADDR><ADDRESS>64.71.255.61</ADDRESS><AFI value=\"1\">IPV4</AFI></DST_ADDR><DST_PORT>179</DST_PORT><DST_AS>812</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length=\"62\"><MARKER length=\"16\">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len=\"0\" path_attr_len=\"35\"><WITHDRAWN count=\"0\"/><PATH_ATTRIBUTES count=\"4\"><ATTRIBUTE length=\"1\"><FLAGS transitive=\"TRUE\"/><TYPE value=\"1\">ORIGIN</TYPE><ORIGIN value=\"0\">IGP</ORIGIN></ATTRIBUTE><ATTRIBUTE length=\"12\"><FLAGS transitive=\"TRUE\"/><TYPE value=\"2\">AS_PATH</TYPE><AS_PATH><AS_SEG type=\"AS_SEQUENCE\" length=\"5\"><AS>812</AS><AS>6461</AS><AS>3356</AS><AS>2907</AS><AS>23803</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length=\"4\"><FLAGS transitive=\"TRUE\"/><TYPE value=\"3\">NEXT_HOP</TYPE><NEXT_HOP>64.71.255.61</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length=\"6\"><FLAGS optional=\"TRUE\" transitive=\"TRUE\"/><TYPE value=\"7\">AGGREGATOR</TYPE><AGGREGATOR><AS>23803</AS><ADDR>175.144.4.24</ADDR></AGGREGATOR></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count=\"1\"><PREFIX label=\"DANN\"><ADDRESS>202.175.144.0/20</ADDRESS><AFI value=\"1\">IPV4</AFI><SAFI value=\"1\">UNICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length=\"62\">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF003E02000000234001010040020C0205032C193D0D1C0B5B5CFB4003044047FF3DC007065CFBCAAF9B3014CAAF90</OCTETS></OCTET_MSG></BGP_MESSAGE>";

#set the data directory
#my $data_dir = `echo -n \`pwd\``."/t/data";
#my $data_dir = 't';

my $resp = `pwd`;
my $location = 't/';
if($resp =~ m/bgpmon-tools\/BGPmon-core\/t/){
        $location = '';
}



my $ret = undef;    #Return value of calls
my $err = undef;    #Log message


##################### connect_file ###########################################
##################### Validation conditions ##################################
#Connect with no argument (done)
#Connect with 2 arguments (done)
#Connect with nonexistant file (done)
#Connect with file w/ invalid permissions (done)
#Connect with valid bz2 file (done)
#Connect with valid gz file (done)
#Connect to uncompressed file (done)
#Connect while already connected (done)
#No <xml> tag (wrong format) (done)


#Read XML while not connected (done)
#Connect, read, delete file, continue reading (done)
#Connect, delete file, read (done)
#Connect, read, move file, read (done)
#Connect, change permissions, read (done)

init_bgpdata();

#Connect w/ no argument
$ret = connect_file();
is($ret,1,"connect_file - no argument");
is(get_error_code("connect_file"),301, "connect_file - check error code");

#Connect w/ 2 arguments
#Test should work because connect_file only SHIFTs out the first argument
$ret = connect_file($location."bgpmon-fetch-file-valid.xml.gz", "Makefile");
is($ret,0,"connect_file - too many arguments");
close_connection();

#Connect to a valid, gzipped file
$ret = connect_file($location."bgpmon-fetch-file-valid.xml.gz");
is($ret,0,"connect_file - valid gzip archive");
close_connection();

#Connect to a compressed archive file that is missing ARCHIVER tags
$ret = connect_file($location."bgpmon-fetch-file-no-archiver.xml.bz2");
ok( is_connected() ,"connect_file - valid XML archive (compressed)");

#Try to read the first message out of the file
#This test will fail because of the missing ARCHIVER messages
my $msg = read_xml_message();
ok(!defined($msg),"read_xml_message - missing ARCHIVER tags");
ok( !is_connected(), "read_xml_message - no ARCHIVER");
is(get_error_code("read_xml_message"),313,"read_xml_message - error code");

#Disconnect and reconnect to a valid archive file.
close_connection();
$ret = connect_file($location."bgpmon-fetch-file-valid.xml.gz");
ok( is_connected() ,"connect_file - valid XML archive");

#Read the first message out of the file again, and confirm we are still connected.
$msg = read_xml_message();
ok(defined($msg),"read_xml_message - confirm message exists");
is($msg,$first_msg,"read_xml_message - check first message");
ok( is_connected(),"read_xml_message - first message");

#Attempt to connect to another file while
#still connected to a file
$ret = connect_file($location."bgpmon-translator-dup-archiver-msg.xml");
is($ret,1,"confirm no new connection");
is(get_error_code("connect_file"),303,"connect_file - connect while already connected");

#Read the next message from the already-open connection
$msg = read_xml_message();
ok(defined($msg),"read_xml_message - confirm message exists");
is($msg,$second_msg,"read_xml_message - check second message");
is(messages_read(),2,"read_xml_message - read after failed connect");

#Read the remainder of the messages
while( defined($msg) ){
    $msg = read_xml_message();
}
#There are 8 messages in this file, the connection should be closed, and
#I shouldn't be able to re-close the connection
is(messages_read(),8,"read_xml_message - read all messages");
ok(!is_connected(),"is_connected - not connected after EOF");
is(close_connection(),1,"close_connection - close after closed");

#Try to read from no connection
$msg = read_xml_message();
is(get_error_code("read_xml_message"),302,"read_xml_message - read without connection");

# read from a non-existant file
$ret = connect_file($location."updates.20120101.0000.xml.bz2");
is($ret,1,"connect_file - nonexistent file");
is(get_error_code("connect_file"),304,"connect_file - Nonexistent file");

=comment
# read from a file we don't have permissions for
$ret = connect_file("/etc/sudoers");
is($ret,1,"connect_file - no permission on file");
is(get_error_code("connect_file"),307,"connect_file - bad permissions");
=cut

# read from a wrong format file
$ret = connect_file($location."bgpmon-fetch-file-bgpdump-001");
is($ret,1,"connect_file - bgpdump format");
ok(!is_connected(),"connect_file - wrong format");

# start reading, delete file, continue reading
$ret = connect_file($location."bgpmon-fetch-file-valid.xml.gz");
ok( is_connected(),"confirm file connection");
$msg = read_xml_message();
$msg = read_xml_message();
`rm -f /tmp/BGP.File.$$/extract_bgp.$$`;
$msg = read_xml_message();
is($msg,undef,"read_xml_message - delete a file mid-read");
is(get_error_code("read_xml_message"),304,"read_xml_message - check error code on deleted file mid-read");

if( !(-e $location."/compress_test.gz") ){
	my $te = $location."compress_test.gz";
    `echo "This is an uncompressed file" > $te`;
}
# decompress an uncompressed file and try to connect
#This will fail because the scratch directory has not been initialized
$ret = BGPmon::Fetch::File::decompress_file($location."compress_test.gz");
isnt($ret,undef,"decompress_file - corrupt compressed file");
#Try actually connecting to the file this time
$ret = connect_file($location."compress_test.gz");
is($ret,1,"connect_file - connect to binary file");
ok(!is_connected(),"connect_file - not connected to binary file");

#Connect to a file, read a message, change the permissions, try to read again
#This should work because permissions only get checked once, not per-read
$ret = connect_file($location."bgpmon-fetch-file-valid.xml.gz");
ok( is_connected(),"confirm file connection");
$msg = read_xml_message();
`chmod a-r "/tmp/BGP.File.$$/extract_bgp.$$"`;
$msg = read_xml_message();
ok(defined($msg),"read_xml_message - chmod mid-read");
close_connection();

#Connect to a file, read a message, move the file, try to read again
$ret = connect_file($location."bgpmon-fetch-file-valid.xml.gz");
ok( is_connected(),"confirm file connection");
$msg = read_xml_message();
ok(defined($msg),"read_xml_message - read before move");
`mv "/tmp/BGP.File.$$/extract_bgp.$$" "/tmp/BGP.File.$$/extract_bgp.$$.bak"`;
#Now that we've moved the file that we were reading, the next read will fail
$msg = read_xml_message();
is($msg,undef,"read_xml_message - move mid-read");

#Connect to a file with a broken XML message
$ret = connect_file($location."bad_xml_test.bz2");
ok(is_connected(),"confirm file connection");
$msg = read_xml_message();
ok(!defined($msg),"read_xml_message - detect bad XML");
close_connection();

#Connect to a file with an extra ARCHIVER/START message in the middle
$ret = connect_file($location."bgpmon-translator-dup-archiver-msg.xml");
ok(is_connected(),"confirm file connection");
$msg = read_xml_message();
$msg = read_xml_message();
$msg = read_xml_message();
is(get_error_code("read_xml_message"),314,"read_xml_message - duplicate ARCHIVER/OPENED message");

#We are going to close this connection, reinitialize with flags set to ignore
#data errors, then test reading on previously-wrong files
$ret = close_connection();
$ret = init_bgpdata('ignore_data_errors' => 1,'ignore_incomplete_data' => 1);
is($ret,1,'init_bgpdata - set the flags w/ default directory');
$ret = connect_file($location."bgpmon-fetch-file-no-archiver.xml.bz2");
ok( is_connected() ,"connect_file - valid XML archive (compressed)");

#Try to read the first message out of the file
#This test should pass because we're ignoring the missing ARCHIVER messages
$msg = read_xml_message();
ok(defined($msg),"read_xml_message - ignore missing ARCHIVER tags");
ok(is_connected(), "read_xml_message - ignore missing ARCHIVER tags");
is(get_error_code("read_xml_message"),0,"read_xml_message - error code");
close_connection();

done_testing();
1;
