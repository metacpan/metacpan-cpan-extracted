use common::sense;

use Test::More;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::MCP::Server::HTTP ();
use JSON::XS ();
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

sub read_response {
   my ($handle, $cb) = @_;

   $handle->push_read (line => "\r\n\r\n", sub {
      my ($handle, $headers) = @_;
      my ($len) = $headers =~ /Content-Length: ([0-9]+)/i;
      defined $len or die "Missing Content-Length\n";
      $handle->push_read (chunk => $len, sub { $cb->($headers, $_[1]) });
   });
}

sub post {
   my ($uri, $content, $headers) = @_;
   "POST $uri HTTP/1.1\r\nContent-Length: " . length ($content)
      . "\r\n" . ($headers || "") . "\r\n$content";
}

my @requests;
my $delay;
my $server = AnyEvent::MCP::Server::HTTP->new (
   tokens => ["test-token"],
   on_http_request => sub {
      my ($server, $req, $reply) = @_;
      push @requests, [$req->{method}, $req->{uri}, $req->{body}];

      return 0 unless $req->{uri} eq "/review";

      $delay = AE::timer 0.02, 0, sub {
         $reply->(200, "OK", {
            "Content-Type" => "application/octet-stream",
            "X-Review"     => "yes",
         }, "\0\xff");
         $reply->(200, "OK", {}, "duplicate");
      };

      1
   },
);

socketpair my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
$server->accept ($a);
my $client = AnyEvent::Handle->new (fh => $b, on_error => sub { die $_[2] });
my $cv = AE::cv;
my $timeout = AE::timer 5, 0, sub { $cv->croak ("HTTP hook timeout") };

my $request = post ("/review", "A\0B", "Content-Type: application/octet-stream\r\n")
   . post ("/mcp/", JSON::XS::encode_json ({
      jsonrpc => "2.0", id => 41, method => "ping", params => {},
   }), "Content-Type: application/json\r\nAuthorization: Bearer test-token\r\n");

$client->push_write ($request);
read_response ($client, sub {
   my ($header, $body) = @_;
   like $header, qr/^HTTP\/1\.1 200 OK\r?$/m, "hook sends successful HTTP response";
   like $header, qr/^Content-Type: application\/octet-stream\r?$/m, "hook sets content type";
   like $header, qr/^X-Review: yes\r?$/m, "hook supplies additional headers";
   is length $body, 2, "binary response is two bytes";
   is unpack ("H*", $body), "00ff", "binary reply content is preserved";

   read_response ($client, sub {
      my ($header, $body) = @_;
      like $header, qr/^Content-Type: application\/json\r?$/m, "MCP retains JSON default";
      is JSON::XS::decode_json ($body)->{id}, 41, "unhandled request falls through to MCP";
      $cv->send;
   });
});
$cv->recv;
undef $timeout;
undef $delay;
is_deeply [map [$_->[0], $_->[1]], @requests],
   [["POST", "/review"], ["POST", "/mcp/"]],
   "hook sees both request methods and paths in order";
is $requests[0][2], "A\0B", "hook receives the raw binary body";
is_deeply JSON::XS::decode_json ($requests[1][2]),
   { jsonrpc => "2.0", id => 41, method => "ping", params => {} },
   "hook receives complete MCP JSON before normal dispatch";
$server->close;
$client->destroy;

# Custom endpoints do not weaken authentication on normal MCP routes.
socketpair $a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
$server->accept ($a);
$client = AnyEvent::Handle->new (fh => $b, on_error => sub { die $_[2] });
$cv = AE::cv;
$timeout = AE::timer 5, 0, sub { $cv->croak ("HTTP auth timeout") };
$client->push_write (post ("/mcp/", '{"jsonrpc":"2.0","id":42,"method":"ping","params":{}}',
   "Content-Type: application/json\r\n"));
read_response ($client, sub {
   like $_[0], qr/^HTTP\/1\.1 401 Unauthorized\r?$/m, "MCP still requires authentication";
   $cv->send;
});
$cv->recv;
undef $timeout;
$server->close;
$client->destroy;

# A hook can handle arbitrary non-MCP paths and add ordinary HTTP headers.
my $seen = 0;
$server = AnyEvent::MCP::Server::HTTP->new (
   auth => "none",
   on_http_request => sub {
      my ($server, $req, $reply) = @_;
      ++$seen;
      return 0 unless $req->{uri} eq "/home";
      $reply->(200, "OK", { "Content-Type" => "text/html; charset=utf-8",
                           "Cache-Control" => "no-store" }, "<h1>ready</h1>");
      1;
   },
);
socketpair $a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
$server->accept ($a);
$client = AnyEvent::Handle->new (fh => $b, on_error => sub { die $_[2] });
$cv = AE::cv;
$timeout = AE::timer 5, 0, sub { $cv->croak ("HTTP HTML timeout") };
$client->push_write ("GET /home HTTP/1.1\r\nHost: local\r\n\r\n");
read_response ($client, sub {
   like $_[0], qr/^Content-Type: text\/html; charset=utf-8\r?$/m, "HTML content type";
   like $_[0], qr/^Cache-Control: no-store\r?$/m, "Cache-Control header";
   is $_[1], "<h1>ready</h1>", "HTML response body";
   $cv->send;
});
$cv->recv;
is $seen, 1, "one HTTP callback";
undef $timeout;
$server->close;
$client->destroy;

done_testing;
