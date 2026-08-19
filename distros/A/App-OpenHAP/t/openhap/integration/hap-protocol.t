#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Integration test: HAP protocol endpoints and HTTP functionality

use v5.36;
use Test::More tests => 16;
use FindBin qw($RealBin);
use lib "$RealBin/../../../lib";

use App::OpenHAP::Test::Integration;

my $env = App::OpenHAP::Test::Integration->new;
$env->setup;

# Test 1: The HAP server is reachable over HTTP
my $response = $env->http_request('GET', '/');
ok(defined $response && $response =~ /^HTTP\/1\.[01]/, 'server reachable');

# Test 2: /accessories endpoint responds
$response = $env->http_request('GET', '/accessories');
my $status = App::OpenHAP::Test::Integration::status($response);
ok(defined $status, '/accessories endpoint responds');

# Test 3: /accessories has correct Content-Type
my $has_content_type = $response =~ /Content-Type:\s*application\/hap\+json/i;
ok($has_content_type || $status == 470,
   '/accessories uses application/hap+json');

# Test 4: /pair-setup endpoint accepts POST
$response = $env->http_request('POST', '/pair-setup', "\x00\x01\x00",
	{'Content-Type' => 'application/pairing+tlv8'});
ok(defined $response && $response =~ /HTTP\/1\.[01]\s+200/,
   '/pair-setup accepts POST');

# Test 5: /pair-setup uses correct Content-Type
$has_content_type = $response =~ /Content-Type:\s*application\/pairing\+tlv8/i;
ok($has_content_type, '/pair-setup uses application/pairing+tlv8');

# Test 6: /pair-verify endpoint accepts POST
$response = $env->http_request('POST', '/pair-verify', "\x00\x01\x00",
	{'Content-Type' => 'application/pairing+tlv8'});
ok(defined $response && $response =~ /HTTP\/1\.[01]\s+200/,
   '/pair-verify accepts POST');

# Test 7: /pair-verify uses correct Content-Type
$has_content_type = $response =~ /Content-Type:\s*application\/pairing\+tlv8/i;
ok($has_content_type, '/pair-verify uses application/pairing+tlv8');

# Test 8: Server uses HTTP/1.x protocol
$response = $env->http_request('GET', '/accessories');
ok($response =~ /HTTP\/1\.[01]/, 'server uses HTTP/1.x');

# Test 9: Multiple concurrent connections work
my @sockets;
for (1..5) {
	my $sock = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		PeerPort => $env->{hap_port},
		Proto    => 'tcp',
		Timeout  => 2,
	);
	push @sockets, $sock if defined $sock;
}
ok(@sockets >= 5, 'handles multiple concurrent connections');
$_->close for @sockets;

# Test 10: Connection persistence works
my $socket = IO::Socket::INET->new(
	PeerAddr => '127.0.0.1',
	PeerPort => $env->{hap_port},
	Proto    => 'tcp',
	Timeout  => 2,
);
ok(defined $socket, 'connection established');

# Make multiple requests on the same connection
print $socket "GET /accessories HTTP/1.1\r\n";
print $socket "Host: 127.0.0.1\r\n\r\n";
my $resp1 = '';
while (my $line = <$socket>) {
	$resp1 .= $line;
	last if $line =~ /^\r?\n$/;
}

print $socket "GET /accessories HTTP/1.1\r\n";
print $socket "Host: 127.0.0.1\r\n\r\n";
my $resp2 = '';
while (my $line = <$socket>) {
	$resp2 .= $line;
	last if $line =~ /^\r?\n$/;
}

$socket->close;

# Test 11: Both requests succeed
ok($resp1 =~ /HTTP/ && $resp2 =~ /HTTP/,
   'connection persistence works');

# Test 12: Connection: keep-alive header in responses
$response = $env->http_request('GET', '/accessories');
my $has_keepalive = $response =~ /Connection:\s*keep-alive/i;
ok($has_keepalive, 'response includes Connection: keep-alive header');

# Test 13: HTTP responses use HTTP/1.1
$response = $env->http_request('GET', '/accessories');
ok($response =~ /HTTP\/1\.1/, 'server uses HTTP/1.1 specifically');

# Test 14: /pair-setup returns TLV response
$response = $env->http_request('POST', '/pair-setup', "\x00\x01\x00",
	{'Content-Type' => 'application/pairing+tlv8'});
# TLV responses are binary. Check for Content-Length.
my ($content_length) = $response =~ /Content-Length:\s*(\d+)/i;
ok(defined $content_length && $content_length > 0,
   '/pair-setup returns non-empty TLV response');

# Test 15: /pair-verify step 1 returns proper response
# Send a minimal step 1: kTLVType_State=1, kTLVType_PublicKey=<32 bytes>
my $fake_public_key = 'A' x 32;
my $step1_request = "\x00\x01\x01" . "\x03\x20" . $fake_public_key;
$response = $env->http_request('POST', '/pair-verify', $step1_request,
	{'Content-Type' => 'application/pairing+tlv8'});
ok(defined $response && $response =~ /HTTP\/1\.1\s+200/,
   '/pair-verify step 1 returns HTTP 200');

# Test 16: Error responses use application/hap+json
$response = $env->http_request('PUT', '/characteristics',
	'invalid json',
	{'Content-Type' => 'application/hap+json'});
# Check if the response has a content-type header
my $error_content_type = $response =~ /Content-Type:\s*application\/(hap\+)?json/i;
# Either proper error content-type or 470 unpaired
ok($error_content_type || $response =~ /470/,
   'error responses use appropriate content type');

$env->teardown;
