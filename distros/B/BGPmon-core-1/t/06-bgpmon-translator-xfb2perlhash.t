#Test suite for BGPmon::Translator::XFB2PerlHash

use warnings;
use strict;

use BGPmon::Translator::XFB2PerlHash qw/translate_msg toString get_content get_error_code get_error_message/;
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

#Set a debug flag for some terminal-window output
my $debug = 1;

my $test_fh;
open($test_fh,"<","$test_file") or die "Unable to open XML file for testing!";

########################### Error cases #######################################
#Try to call translate with no message. There should be an empty hash
#returned and the error code should be set
my $ret = translate_msg();
is(keys %$ret,0,"translate_msg - no message provided");
is(get_error_code('translate_msg'),601,'translate_msg - error code for no message');

#Try to call toString with no message stored in the module.
#This will return the empty string and set the error code.
my $ret2 = toString();
is($ret2,'','toString - no message provided/no previous message');
is(get_error_code('toString'),601,'toString - error code for no message');

#This first read from test_fh will return the <xml> tag from the top
#of the test file, which will break the parser.  We catch this error and
#return an empty hash
my $msg = <$test_fh>;
$ret = translate_msg($msg);
is(keys %$ret,0,'translate_msg - catch parser error on <xml> tag');

#Translate an empty message to clear out the module's buffers
translate_msg('');
#Try to read a piece of content
$ret2 = get_content("/ARCHIVER");
is(get_error_code('get_content'),601,'get_content - no message');

############################# Valid cases #####################################

#This second read will get the next XML message, which should be the first
#correct message in the file.
$msg = <$test_fh>;
$ret = translate_msg($msg);
ok(keys %$ret,'translate_msg - parse first correct message');

#Call toString to get the stringified version of the hash
$ret2 = toString();
ok(defined($ret2),'toString - get stringified version of hash');

#Call toString again, which should return the exact same string as the 
#previous call
my $ret3 = toString();
is($ret3,$ret2,'toString - multiple consecutive calls are equal');

#Now I want to extract a specific piece of information, in this case
#the 'cause' field out of the ARCHIVER/EVENT message that is currently in
#the module.
$ret2 = get_content("/ARCHIVER/EVENT/cause");
is($ret2,'CREATE_NEW_FILE','get_content - extract correct information');

#Make sure we can read a second, different piece of information out of the file.
$ret2 = get_content("/ARCHIVER/TIME/datetime");
is($ret2,'2012-06-19T20:17:30Z','get_content - extract second field');

#Get new message and let's grab some information from it
$msg = <$test_fh>;
$ret = translate_msg($msg);
ok( keys %$ret,'translate_msg - successfully translated new message');
#This fetch should return a hash that contains an array in PREFIX
$ret2 = get_content("/BGP_MESSAGE/ASCII_MSG/UPDATE/WITHDRAWN");
is(ref $ret2->{'PREFIX'},'ARRAY','get_content - successfully return an array');

############################# Error case ##################################
#Ask for an invalid hash element
$ret2 = get_content("/BGP_MESSAGE/GEOLOCATION");
is($ret2,undef,'get_content - check undef returned on invalid request');
is(get_error_code('get_content'),605,'get_content - invalid request');

#Seek forward in the test file for a message with IPv6 data
$msg = <$test_fh> for (4..9);
$ret = translate_msg($msg);
#print STDERR get_error_message('translate_msg');
ok(keys %$ret,'translate_msg - translate message w/ v6 data');
#print STDERR toString();

done_testing();
1;
