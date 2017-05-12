use warnings;
use strict;
use POSIX;
use BGPmon::Fetch::Client qw(connect_bgpmon read_xml_message close_connection is_connected get_error_code messages_read set_timeout);


my $resp = `pwd`;
my $location = 't/';
if($resp =~ m/bgpmon-tools\/BGPmon-core\/t/){
        $location = '';
	use Test::More;
}
else{
	use Test::More skip_all => "Only run for development";
}



my $server = '127.0.0.1';
my $xml_msg = '<BGP_MESSAGE length="00001784" version="0.4" xmlns="urn:ietf:params:xml:ns:xfb-0.4" type_value="2" type="UPDATE"><BGPMON_SEQ id="2128112124" seq_num="1532311467"/><TIME timestamp="1346087825" datetime="2012-08-27T17:17:05Z" precision_time="231"/><PEERING as_num_len="2"><SRC_ADDR><ADDRESS>189.36.224.1</ADDRESS><AFI value="1">IPV4</AFI></SRC_ADDR><SRC_PORT>179</SRC_PORT><SRC_AS>28289</SRC_AS><DST_ADDR><ADDRESS>129.82.138.6</ADDRESS><AFI value="1">IPV4</AFI></DST_ADDR><DST_PORT>4321</DST_PORT><DST_AS>6447</DST_AS><BGPID>0.0.0.0</BGPID></PEERING><ASCII_MSG length="62"><MARKER length="16">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF</MARKER><UPDATE withdrawn_len="0" path_attr_len="35"><WITHDRAWN count="0"/><PATH_ATTRIBUTES count="4"><ATTRIBUTE length="1"><FLAGS transitive="TRUE"/><TYPE value="1">ORIGIN</TYPE><ORIGIN value="2">INCOMPLETE</ORIGIN></ATTRIBUTE><ATTRIBUTE length="14"><FLAGS transitive="TRUE"/><TYPE value="2">AS_PATH</TYPE><AS_PATH><AS_SEG type="AS_SEQUENCE" length="6"><AS>28289</AS><AS>53131</AS><AS>16735</AS><AS>12956</AS><AS>7018</AS><AS>15290</AS></AS_SEG></AS_PATH></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS transitive="TRUE"/><TYPE value="3">NEXT_HOP</TYPE><NEXT_HOP>187.121.193.33</NEXT_HOP></ATTRIBUTE><ATTRIBUTE length="4"><FLAGS optional="TRUE" transitive="TRUE"/><TYPE value="8">COMMUNITIES</TYPE><COMMUNITIES><COMMUNITY><AS>28289</AS><VALUE>65500</VALUE></COMMUNITY></COMMUNITIES></ATTRIBUTE></PATH_ATTRIBUTES><NLRI count="1"><PREFIX label="NANN"><ADDRESS>199.198.218.0/24</ADDRESS><AFI value="1">IPV4</AFI><SAFI value="1">UNICAST</SAFI></PREFIX></NLRI></UPDATE></ASCII_MSG><OCTET_MSG><OCTETS length="62">FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF003E02000000234001010240020E02066E81CF8B415F329C1B6A3BBA400304BB79C121C008046E81FFDC18C7C6DA</OCTETS></OCTET_MSG></BGP_MESSAGE>';

sub server {
	my $p = shift;
	my $socket = new IO::Socket::INET (
    	LocalHost => '127.0.0.1',
   		LocalPort => $p,
		Proto => 'tcp',
    	Listen => 5,
    	Reuse => 1,
	) or die "Error creating socket: $!";

	my $client_socket = $socket->accept();

	# Write <xml> tag on client socket.
	$client_socket->send("<xml>");
	sleep(1);
	# Write XML message on client socket.
	for (my $i = 0; $i < 100; $i++) {
        $client_socket->send($xml_msg);
	}
	$socket->close();
}

# No server running, check if connected.
my $ret = is_connected();
ok($ret == 0, "actual: $ret expected 0");

# Read should fail.
my $msg = read_xml_message();
my $error_code = get_error_code('read_xml_message');
ok($error_code == 202, "actual: $error_code, expected: 202");

# Generate random port no.
my $port = int(rand(30000)) + 1024;

# Run stub server
my $pid = fork();
if ($pid == 0) {
	# Start server
	server($port);
} else {
	# Give some time for the server to fire up.
	sleep(1);
	# Try connecting.
	$ret = connect_bgpmon('127.0.0.1', $port);
	$error_code = get_error_code('connect_bgpmon');
	ok($ret == 0, "actual: $ret, expected: 0");
	ok($error_code == 0, "actual: $error_code, expected: 0");

	# Read an XML message.
	$msg = read_xml_message();
	ok($msg eq $xml_msg);
	wait;
	close_connection();
}

# Start server again, but this time we will kill the server prematurely.
$pid = fork();
if ($pid == 0) {
	server($port + 100);
} else {
	sleep(1);
	set_timeout(10);
	$ret = connect_bgpmon('127.0.0.1', ($port + 100));
	$error_code = get_error_code('connect_bgpmon');
	ok($ret == 0, "actual: $ret, expected: 0");
	ok($error_code == 0, "actual: $error_code, expected: 0");

	# Kill server.
	`kill -11 $pid`;

	# Try to read message.
	$msg = read_xml_message();
	$error_code = get_error_code('read_xml_message');
	my $isTrue = 0;
	if($error_code == 205){
		$isTrue = 1;
	}
	ok($error_code == 205, "actual: $error_code, expected: 208 or 202");
	wait;
	close_connection();
}

done_testing();
