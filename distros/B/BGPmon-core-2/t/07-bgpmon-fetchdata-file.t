#Test suite for BGPmon::Fetch::File

use warnings;
use strict;
use Test::More;
use Data::Dumper;
use BGPmon::Fetch::File qw/init_bgpdata connect_file read_xml_message
 get_error_code get_error_message close_connection messages_read is_connected/;
use BGPmon::Log;

my $first_msg = "<ARCHIVER><TIME timestamp=\"1340136304\" datetime=\"2012-06-19T20:05:04Z\"/><EVENT cause=\"CREATE_NEW_FILE\">OPENED</EVENT></ARCHIVER>";

my $second_msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">164.128.32.11</ADDRESS><PORT>179</PORT><ASN4>3303</ASN4></SOURCE><DEST><ADDRESS afi="1">127.0.0.1</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.102</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1372636819</TIMESTAMP><DATETIME>2013-07-01T00:00:19Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>226125243</SEQUENCE_NUMBER><COLLECTION>LIVE</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:ORIGIN optional="false" transitive="true" partial="false" extended="false" attribute_type="1">IGP</bgp:ORIGIN><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>3303</bgp:ASN4><bgp:ASN4>3491</bgp:ASN4><bgp:ASN4>18187</bgp:ASN4><bgp:ASN4>9821</bgp:ASN4><bgp:ASN4>9821</bgp:ASN4><bgp:ASN4>45600</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:NEXT_HOP optional="false" transitive="true" partial="false" extended="false" attribute_type="3" afi="1">164.128.32.11</bgp:NEXT_HOP><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>3303</bgp:ASN2><bgp:VALUE>1004</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>3303</bgp:ASN2><bgp:VALUE>1006</bgp:VALUE></bgp:COMMUNITY><bgp:COMMUNITY optional="true" transitive="true" partial="false" extended="false" attribute_type="8"><bgp:ASN2>3303</bgp:ASN2><bgp:VALUE>3052</bgp:VALUE></bgp:COMMUNITY><bgp:NLRI afi="3">MALLICIOUS_ADDRESS_INSERTED</bgp:NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF005202000000374001010040021A020600000CE700000DA30000470B0000265D0000265D0000B220400304A480200BC0080C0CE703EC0CE703EE0CE70BEC16CA5C94</OCTET_MESSAGE></BGP_MONITOR_MESSAGE>';

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
is(messages_read(), 5, "read_xml_message - read all messages");
ok(!is_connected(), "is_connected - not connected after EOF");
is(close_connection(), 1, "close_connection - close after closed");

#Try to read from no connection
$msg = read_xml_message();
is(get_error_code("read_xml_message"),302,"read_xml_message - read without connection");

# read from a non-existant file
$ret = connect_file($location."updates.20120101.0000.xml.bz2");
is($ret,1,"connect_file - nonexistent file");
is(get_error_code("connect_file"),304,"connect_file - Nonexistent file");

# read from a file we don't have permissions for
$ret = connect_file("/etc/sudoers");
is($ret,1,"connect_file - no permission on file");
is(get_error_code("connect_file"),307,"connect_file - bad permissions");

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
$ret = connect_file($location."bgpmon-fetch-dup-archiver-msg.xml");
ok(is_connected(),"confirm file connection");
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
