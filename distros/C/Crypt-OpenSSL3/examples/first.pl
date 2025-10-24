use 5.036;

use Socket 'SOCK_STREAM';
use IO::Socket::IP;
use Crypt::OpenSSL3::SSL;

my $hostname = 'www.google.com';
my $socket = IO::Socket::IP->new(
	PeerHost => $hostname,
	PeerPort => 'https',
	Type     => SOCK_STREAM,
);

my $method = Crypt::OpenSSL3::SSL::Protocol::TLS_client;
my $ctx = Crypt::OpenSSL3::SSL::Context->new($method);
$ctx->set_verify(Crypt::OpenSSL3::SSL::VERIFY_PEER);
$ctx->set_default_verify_paths() or die;
$ctx->set_min_proto_version(Crypt::OpenSSL3::SSL::TLS1_2_VERSION) or die;

my $ssl = Crypt::OpenSSL3::SSL->new($ctx);
$ssl->set_fd(fileno $socket) or die;
$ssl->set_tlsext_host_name($hostname) or die;
$ssl->set_host($hostname) or die;

$ssl->connect >= 0 or die;
my $verify = $ssl->get_verify_result;
die $verify->error_string if not $verify->ok;

my $w_count = $ssl->write("GET / HTTP/1.1\r\nHost: www.google.com\r\n\r\n");
die unless $w_count >= 0;
my $count = $ssl->read(my $buffer, 2048);
die "Could not read($count) " . $ssl->get_error($count) if $count <= 0;

say $buffer;
