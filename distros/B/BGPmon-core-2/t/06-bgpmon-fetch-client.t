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
	#use Test::More;
}



my $server = '127.0.0.1';
my $xml_msg = '<BGP_MONITOR_MESSAGE xmlns:xsi="http://www.w3.org/2001/XMLSchema" xmlns="urn:ietf:params:xml:ns:bgp_monitor" xmlns:bgp="urn:ietf:params:xml:ns:xfb" xmlns:ne="urn:ietf:params:xml:ns:network_elements"><SOURCE><ADDRESS afi="1">129.250.0.11</ADDRESS><PORT>179</PORT><ASN4>2914</ASN4></SOURCE><DEST><ADDRESS afi="1">127.0.0.1</ADDRESS><PORT>179</PORT><ASN4>6447</ASN4></DEST><MONITOR><ADDRESS afi="1">128.223.51.102</ADDRESS><PORT>0</PORT><ASN4>0</ASN4></MONITOR><OBSERVED_TIME precision="false"><TIMESTAMP>1372636819</TIMESTAMP><DATETIME>2013-07-01T00:00:19Z</DATETIME></OBSERVED_TIME><SEQUENCE_NUMBER>226102578</SEQUENCE_NUMBER><COLLECTION>LIVE</COLLECTION><bgp:UPDATE bgp_message_type="2"><bgp:AS_PATH optional="false" transitive="true" partial="false" extended="false" attribute_type="2"><bgp:AS_SEQUENCE><bgp:ASN4>2914</bgp:ASN4><bgp:ASN4>7575</bgp:ASN4><bgp:ASN4>7575</bgp:ASN4><bgp:ASN4>7575</bgp:ASN4><bgp:ASN4>24436</bgp:ASN4></bgp:AS_SEQUENCE></bgp:AS_PATH><bgp:MULTI_EXIT_DISC optional="true" transitive="false" partial="false" extended="false" attribute_type="4">184549376</bgp:MULTI_EXIT_DISC><bgp:MP_REACH_NLRI optional="true" transitive="false" partial="false" extended="true" attribute_type="14" safi="2"><bgp:MP_NEXT_HOP afi="1">129.250.0.11</bgp:MP_NEXT_HOP><bgp:MP_NLRI afi="1">192.150.139.0/24</bgp:MP_NLRI></bgp:MP_REACH_NLRI></bgp:UPDATE><OCTET_MESSAGE>FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0073020000005C40010100400216020500000B6200001D9700001D9700001D9700005F748004040000000BC008200B62019A0B6203F00B6207D00B620BB81D9703E81D9708CB1D970BBCFF1651E5900E00110001020481FA000B0018C0968B18C09689</OCTET_MESSAGE>></BGP_MONITOR_MESSAGE>';

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
