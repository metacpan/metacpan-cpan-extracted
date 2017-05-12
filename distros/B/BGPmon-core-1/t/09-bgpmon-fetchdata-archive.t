#Test suite for BGPmon::Fetch::Archive

use warnings;
use strict;
use Test::More;

use BGPmon::Fetch::Archive;

#set the data directory
my $data_dir = `echo -n \`pwd\``."/t/data";

my $ret = undef;    #Return value of calls
my $msg = undef;    #Log message

#Set some common use values
use constant NETSEC_VALID_ARCHIVE_ADDR => 'archive.netsec.colostate.edu/peers/89.149.178.10';
use constant NETSEC_VALID_START_TIME => 1345852800; #25 Aug 12 @ 0000 UTC
use constant NETSEC_VALID_END_TIME => 1346468400;    #1 Sep 12 @ 0300 UTC

##################### init_bgpdata ############################################
#call init_bgpdata to set up a scratch directory
$ret = BGPmon::Fetch::Archive::init_bgpdata('ignore_data_errors' => 1, 'ignore_incomplete_data' => 1);
is($ret,1,"init_bgpdata - worked");

##################### connect_archive #########################################
##################### Error conditions ########################################
#Test for incorrect number of arguments to connect_archive
$ret = BGPmon::Fetch::Archive::connect_archive("data.ripe.ris.net/rrs13",
                                                     1338552838);
is($ret,1,'connect_archive - missing argument');
is(BGPmon::Fetch::Archive::get_error_code("connect_archive"),401,
"connect_archive - missing argument");

#Test for invalid start/end times
$ret = BGPmon::Fetch::Archive::connect_archive("data.ripe.ris.net/rrs13",
                                                1338552838,1338550000);
is($ret,1,'connect_archive - invalid interval');
is(BGPmon::Fetch::Archive::get_error_code("connect_archive"),406,
"connect_archive - invalid timerange");

$ret = BGPmon::Fetch::Archive::connect_archive("data.ripe.ris.net/rrs13",
                                                -1338552838,1338550000);
is($ret,1,'connect_archive: negative start time');
is(BGPmon::Fetch::Archive::get_error_code("connect_archive"),406,
"connect_archive - invalid timerange");

#Test for incorrectly-formatted start/end times
$ret = BGPmon::Fetch::Archive::connect_archive("data.ripe.ris.net/rrs13",
                                                "Mar 13 2011 12:34:56",
                                                "Apr 1 2011 11:11:11");
is($ret,1,'connect_archive: string time format');
is(BGPmon::Fetch::Archive::get_error_code("connect_archive"),406,
"connect_archive - invalid timerange");

#Test for illegal characters in argument
my $illegal = chr(0x90).chr(0x90).chr(0x90).chr(0x90).chr(0x90);
$ret = BGPmon::Fetch::Archive::connect_archive("data.ris.ripe.net/$illegal",
                                              1338508800,1340150400);
is($ret,1, "connect_archive - invalid character in URL");
is(BGPmon::Fetch::Archive::get_error_code("connect_archive"),406,
"connect_archive - invalid character URL");


##################### side effects ############################################
# check the internals after a correct call
$ret = BGPmon::Fetch::Archive::connect_archive(NETSEC_VALID_ARCHIVE_ADDR, NETSEC_VALID_START_TIME, NETSEC_VALID_END_TIME);
is($ret,0,"connect_archive - valid initilization");
is(BGPmon::Fetch::Archive::get_error_code("connect_archive"),0,
"connect_archive - no error code set on success");

$ret = BGPmon::Fetch::Archive::close_connection();
is($ret,0,"close_connection - close valid connection");

##################### download_URL ############################################
##################### Error conditions ########################################
#Test with no arguments
$ret = BGPmon::Fetch::Archive::download_URL();
ok( !defined($ret), "download_URL - no argument");
is(BGPmon::Fetch::Archive::get_error_code("download_URL"),401,
"download_URL - missing arguments");

#Test invalid URL
$ret = BGPmon::Fetch::Archive::download_URL("xml://archive.netsec.colostate.edu/collectors/bgpdata-netsec/2012.06/updates.20120601.2214.bgpdata-netsec.xml.bz2",
"/tmp/BGP.Archive.$$/gonna_fail.bz2");
ok( !defined($ret), "download_URL - invalid URL");
is(BGPmon::Fetch::Archive::get_error_code("download_URL"),409,
"download_URL - invalid_URL");

##################### validation tests ########################################
#Test valid index URL
$ret = BGPmon::Fetch::Archive::download_URL(NETSEC_VALID_ARCHIVE_ADDR."/2012.08/UPDATES/","/tmp/BGP.Archive.$$/index.html");
is($ret,0,"download_URL - valid index");
ok( (-e "/tmp/BGP.Archive.$$/index.html"), "download_URL - valid index URL");

#Test valid archive file URL
$ret = BGPmon::Fetch::Archive::download_URL(NETSEC_VALID_ARCHIVE_ADDR."/2012.08/UPDATES/updates.20120824.2215.89.149.178.10.xml","/tmp/BGP.Archive.$$/test-archive-file.xml.bz2");
ok( (-e "/tmp/BGP.Archive.$$/test-archive-file.xml.bz2"), "download_URL - valid archive URL");

##################### get_next_index ##########################################
##################### Error conditions ########################################
#Try to get next index with no state defined
my @return = BGPmon::Fetch::Archive::get_next_index();
is(BGPmon::Fetch::Archive::get_error_code("get_next_index"),401,
"get_next_index - undefined state (no connection)");
ok(!@return,"get_next_index - undefined state");

####################### validation tests ######################################
#Routeviews' archive will fail because there are no files with 'xml' in the
#filename.  Therefore no file will ever be downloaded or opened.
$ret = BGPmon::Fetch::Archive::connect_archive(
"http://archive.routeviews.org/route-views6/bgpdata",1298937600,1302393600);
is($ret,1,"connect_archive - RV archive");

$ret = BGPmon::Fetch::Archive::close_connection();
is($ret,1,"close_connection - try to close invalid connection");

#Reconnect to netsec archive and get next message
$ret = BGPmon::Fetch::Archive::connect_archive(
NETSEC_VALID_ARCHIVE_ADDR, NETSEC_VALID_START_TIME, NETSEC_VALID_END_TIME);
is($ret,0,"connect_archive - valid netsec archive connection");

$msg = BGPmon::Fetch::Archive::read_xml_message();
ok( defined($msg),"read_xml_message - read first message");

#Now read all messages through the entire interval
#Netsec's archive is broken, so this will most likely throw a fatal error
#while( defined($msg) ){
#    $msg = BGPmon::Fetch::Archive::read_xml_message();
#}
BGPmon::Fetch::Archive::close_connection();

done_testing();
