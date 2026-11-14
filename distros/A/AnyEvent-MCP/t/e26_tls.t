use common::sense;
use Test::More;
BEGIN {
   plan skip_all => "extended tls test (PERL_ANYEVENT_MCP_TESTS=1)"
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
}

use AnyEvent ();
use AnyEvent::Log ();
use AnyEvent::Handle ();
use AnyEvent::Socket ();
use AnyEvent::MCP::Server::HTTP ();
use AnyEvent::MCP::Server::Connect ();
use AnyEvent::MCP::Client::JSONL ();
use AnyEvent::MCP::Server::Toolset ();
use File::Temp ();
use JSON::XS ();

eval { require AnyEvent::TLS; require Net::SSLeay; 1 }
   or plan skip_all => "TLS support unavailable";

my $dir = File::Temp::tempdir (CLEANUP => 1);
my ($cert, $key, $combined) = map "$dir/$_", qw(cert.pem key.pem combined.pem);
my $generated;
{
   open my $saved_stderr, ">&", \*STDERR or die $!;
   open STDERR, ">", "/dev/null" or die $!;
   $generated = system ("openssl", "req", "-quiet", "-x509", "-newkey", "rsa:2048", "-noenc",
      "-days", "1", "-keyout", $key, "-out", $cert, "-subj", "/CN=localhost",
      "-addext", "subjectAltName=DNS:localhost",
      "-addext", "basicConstraints=critical,CA:TRUE");
   open STDERR, ">&", $saved_stderr or die $!;
}
$generated == 0
   or plan skip_all => "openssl certificate generation unavailable";

open my $combined_out, ">:raw", $combined or die $!;
for my $path ($key, $cert) {
   open my $in, "<:raw", $path or die $!;
   local $/;
   print {$combined_out} <$in>;
}
close $combined_out or die $!;

my $body = JSON::XS::encode_json ({
   jsonrpc => "2.0", id => 1, method => "ping",
   params => { _meta => {
      "io.modelcontextprotocol/protocolVersion" => "2026-07-28",
      "io.modelcontextprotocol/clientCapabilities" => {},
   }},
});
my $request = "POST /mcp/ HTTP/1.1\r\nContent-Type: application/json\r\n"
   . "Mcp-Method: ping\r\nMCP-Protocol-Version: 2026-07-28\r\n"
   . "Content-Length: " . length ($body) . "\r\n\r\n$body";

sub http_request {
   my ($port, $secure, $input) = @_;

   my $cv = AE::cv;
   my $timer = AE::timer 10, 0, sub { $cv->croak ("HTTP/TLS timeout") };
   my ($connector, $handle);
   $connector = AnyEvent::Socket::tcp_connect "127.0.0.1", $port, sub {
      undef $connector;
      my ($fh) = @_;
      $fh or die "connect: $!";
      $handle = AnyEvent::Handle->new (
         fh => $fh,
         ($secure ? (tls => "connect", peername => "localhost",
            tls_ctx => { verify => 1, verify_peername => "https", ca_file => $cert }) : ()),
         on_error => sub { $cv->croak ($_[2]) },
         on_eof => sub { $cv->croak ("Premature HTTP EOF") },
      );
      $handle->push_read (line => "\r\n\r\n", sub {
         my ($handle, $headers) = @_;
         my ($length) = $headers =~ /Content-Length:\s*(\d+)/i;
         defined $length or die "Missing Content-Length\n";
         $handle->push_read (chunk => $length, sub { $cv->send ([$headers, $_[1]]) });
      });
      $handle->push_write ($input // $request);
   };

   my $response = $cv->recv;
   $handle->destroy;
   @$response
}

my $tools = AnyEvent::MCP::Server::Toolset->new;
$tools->tool (echo => "echo", {}, sub { $_[0]->result ($_[1]) });

for my $case (
   ["combined certificate", { tls_cert => $combined }],
   ["combined key", { tls_key => $combined }],
   ["separate files", { tls_cert => $cert, tls_key => $key }],
) {
   my ($name, $options) = @$case;
   my $http = AnyEvent::MCP::Server::HTTP->new (
      auth => "none", toolsets => [$tools], host => "127.0.0.1", port => 0,
      %$options,
   );
   $http->listen;
   like $http->url, qr{\Ahttps://}, "$name advertises HTTPS";

   for my $secure (0, 1) {
      my ($headers, $body) = http_request ($http->{port}, $secure);
      like $headers, qr{HTTP/1\.1 200 OK}, "$name " . ($secure ? "HTTPS" : "HTTP") . " response";
      is JSON::XS::decode_json ($body)->{id}, 1,
         "$name " . ($secure ? "HTTPS" : "HTTP") . " response ID";
   }

   $http->close;
}

my $cv = AE::cv;
my $timeout = AE::timer 15, 0, sub { $cv->croak ("HTTPS reverse timeout") };
my $upstream;
my $accepted = 0;
my $listener = AnyEvent::MCP::Server::HTTP->new (
   host => "127.0.0.1", port => 0, tokens => ["cookie"], tls_cert => $combined,
   on_extension => sub {
      ++$accepted;
      my ($server, $handle, $hello) = @_;
      is $hello->[0], "mcp-connect", "HTTPS reverse hello dispatched";
      ok $handle->{tls}, "reverse hello arrived over TLS";
      $upstream = AnyEvent::MCP::Client::JSONL->new;
      $upstream->attach ($handle);
      $upstream->call (echo => { value => 42 }, sub { $cv->send ([@_]) });
   },
);
$listener->listen;
my $authenticated = $request;
$authenticated =~ s{POST /mcp/}{POST /cookie/mcp/};
for my $secure (0, 1) {
   my ($headers, $body) = http_request ($listener->{port}, $secure, $authenticated);
   like $headers, qr{HTTP/1\.1 200 OK},
      "extension listener accepts " . ($secure ? "HTTPS" : "HTTP");
   is JSON::XS::decode_json ($body)->{id}, 1,
      "extension listener preserves " . ($secure ? "HTTPS" : "HTTP") . " response";
}

my $reverse = AnyEvent::MCP::Server::Connect->new (
   connect => "https://localhost:$listener->{port}/cookie/remote",
   toolsets => [$tools],
);
{
   local $ENV{PERL_ANYEVENT_CA_FILE} = $cert;
   $reverse->start;
   my ($success, $result) = @{$cv->recv};
   ok $success, "verified HTTPS reverse call completed";
   is $result->{structuredContent}{value}, 42, "verified HTTPS reverse result";
}
$reverse->close;
$upstream->close if $upstream;
{
   my @errors;
   my $ctx = AnyEvent::Log::ctx "AnyEvent::MCP::Server::Connect";
   local $ctx->[3] = sub { push @errors, shift; 1 };

   my $untrusted = AnyEvent::MCP::Server::Connect->new (
      connect => "https://localhost:$listener->{port}/cookie/untrusted",
      toolsets => [$tools],
   );
   {
      local $ENV{PERL_ANYEVENT_CA_FILE} = "/dev/null";
      $untrusted->start;
      my $wait = AE::cv;
      my $timer = AE::timer 0.5, 0, sub { $wait->send };
      $wait->recv;
   }
   ok $untrusted->{_closed} && !$untrusted->{retry},
      "untrusted HTTPS certificate closes immediately rather than retrying";
   $untrusted->close;
   is $accepted, 1, "untrusted HTTPS reverse connection cannot send an extension hello";
   my $mismatch = AnyEvent::MCP::Server::Connect->new (
      connect => "https://127.0.0.1:$listener->{port}/cookie/mismatch",
      toolsets => [$tools],
   );
   {
      local $ENV{PERL_ANYEVENT_CA_FILE} = $cert;
      $mismatch->start;
      my $wait = AE::cv;
      my $timer = AE::timer 0.5, 0, sub { $wait->send };
      $wait->recv;
   }
   ok $mismatch->{_closed} && !$mismatch->{retry} && $mismatch->{attempts} == 1,
      "hostname mismatch fails permanently after one attempt";
   $mismatch->close;
   is $accepted, 1, "hostname mismatch cannot send an extension hello";

   is scalar @errors, 2, "both expected TLS verification errors were logged";
   like $errors[0], qr/HTTPS handshake failed: .*certificate verify failed/,
      "untrusted certificate produces a useful error";
   like $errors[1], qr/HTTPS handshake failed: .*certificate verify failed/,
      "hostname mismatch produces a useful error";
}
$listener->close;

done_testing;
