use common::sense;
use Test::More;
use AnyEvent ();
use AnyEvent::Socket ();
use AnyEvent::Handle ();
use AnyEvent::MCP::Client::JSONL ();
use AnyEvent::MCP ();
use JSON::XS ( );
use MIME::Base64 ( );
use File::Temp ( );

my $port;
my @seen;
my $listener = AnyEvent::Socket::tcp_server "127.0.0.1", 0, sub {
   my ($fh) = @_;

   my $handle;
   $handle = AnyEvent::Handle->new (
      fh => $fh,
      on_error => sub { $handle->destroy; undef $handle },
      on_eof   => sub { $handle->destroy; undef $handle },
   );
   $handle->push_read (line => "\r\n\r\n", sub {
      my ($h, $head) = @_;
      my ($method, $path) = $head =~ m{\A(\S+) (\S+) HTTP/};
      my ($length) = $head =~ /^content-length:\s*(\d+)/im;
      my $respond = sub {
         my ($body) = @_;
         push @seen, [$method, $path, $head, $body];
         my ($code, $extra, $data) = (200, "", "alpha\nbeta\nALPHA\n");
         if ($path eq "/cookie") {
            $extra = "Set-Cookie: sid=abc; Path=/\r\n";
         } elsif ($path eq "/binary") {
            $data = "\x00\xff\x80";
         } elsif ($path eq "/redirect") {
            $code = 302;
            $extra = "Location: /unexpected\r\n";
            $data = "";
         } elsif ($path eq "/post") {
            $data = $body;
         } elsif ($path eq "/long") {
            $data = "x" x 100;
         }
         $h->push_write ("HTTP/1.1 $code Test\r\n"
            . "Content-Length: " . length ($data) . "\r\nConnection: close\r\n"
            . $extra . "\r\n" . $data);
         $h->on_drain (sub { $h->destroy; undef $handle });
      };
      if ($length) {
         $h->push_read (chunk => $length, sub { $respond->($_[1]) });
      } else {
         $respond->("");
      }
   });
}, sub { $port = $_[2] };

my $client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-http", "--stdio", "--auto-allow", "request,*"],
);
sub wait_for {
   my ($start) = @_;

   my $cv = AE::cv;
   my $timer = AE::timer 10, 0, sub { $cv->croak ("mcp-http test timeout") };
   $start->(sub { $cv->send ([@_]) });
   @{$cv->recv}
}
sub call_http {
   my ($args) = @_;

   my ($ok, $result) = wait_for (sub {
      $client->rpc ("tools/call", { name => "request", arguments => $args }, $_[0]);
   });
   ok $ok, "MCP transport success";
   $result
}

my $base = "http://127.0.0.1:$port";
my ($ok, $tools) = wait_for (sub { $client->rpc ("tools/list", {}, $_[0]) });
ok $ok, "tool list transport works";
is_deeply [sort map $_->{name}, @{$tools->{tools}}],
   [sort qw(request meta-instructions)], "one request tool and metadata";

my $r = call_http ({ url => "$base/cookie", cookie_jar => {} });
ok !$r->{isError}, "GET succeeded";
is $r->{structuredContent}{status}, 200, "HTTP status returned";
is $r->{structuredContent}{body}, "alpha\nbeta\nALPHA\n", "text response";
like $seen[-1][2], qr/^user-agent:\s*mcp-http\/\Q$AnyEvent::MCP::VERSION\E\s*$/im,
   "default User-Agent identifies versioned mcp-http";
is $r->{structuredContent}{cookie_jar}{version}, 2, "versioned cookie jar returned";
ok $r->{structuredContent}{cookie_jar}{"127.0.0.1"}, "jar contains response cookie";
my $jar = $r->{structuredContent}{cookie_jar};

$r = call_http ({
   url => "$base/post", method => "POST", cookie_jar => $jar,
   headers => { "content-type" => "application/octet-stream" },
   body_base64 => MIME::Base64::encode_base64 ("A\0B", ""),
});
is $r->{structuredContent}{body}, "A\0B", "binary request body preserved";
like $seen[-1][2], qr/^cookie:\s*sid=abc/im, "cookie sent from caller-provided jar";
is $seen[-1][0], "POST", "HTTP method forwarded";

$r = call_http ({ url => "$base/page", headers => { "uSeR-aGeNt" => "custom-agent/1" } });
is $r->{structuredContent}{status}, 200, "custom User-Agent request succeeded";
like $seen[-1][2], qr/^user-agent:\s*custom-agent\/1\s*$/im,
   "explicit User-Agent is not overridden";

$r = call_http ({ url => "$base/page", grep => "alpha" });
is $r->{structuredContent}{body}, "alpha\n", "literal grep selects lines";
$r = call_http ({
   url => "$base/page", regex => "(?i)^alpha",
   substitute => { pattern => "(?i)alpha", replacement => "X" },
});
is $r->{structuredContent}{body}, "X\nX\n", "regex selection followed by global substitution";

$r = call_http ({ url => "$base/binary" });
is $r->{structuredContent}{body_base64}, MIME::Base64::encode_base64 ("\x00\xff\x80", ""),
   "non-UTF-8 response returns Base64";

$r = call_http ({ url => "$base/long", max_bytes => 12 });
is length $r->{structuredContent}{body}, 12, "response size bounded";
ok $r->{structuredContent}{truncated}, "truncated response indicated";
is $r->{structuredContent}{status}, 200, "HTTP status retained after early stop";

my $count = @seen;
$r = call_http ({ url => "$base/redirect" });
is $r->{structuredContent}{status}, 302, "redirect returned, not followed";
is scalar @seen, $count + 1, "no redirected request was sent";

for my $bad (
   { url => "http://user:pw\@example.com/" },
   { url => "$base/page", headers => { "x-test" => "bad\nheader" } },
   { url => "$base/page", regex => "[" },
   { url => "$base/page", body => "x", body_base64 => "WA==" },
) {
   my $before = @seen;
   $r = call_http ($bad);
   ok $r->{isError}, "invalid request is rejected";
   is scalar @seen, $before, "invalid request performed no network I/O";
}

my $restricted = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-http", "--stdio", "--ask", "mcp"],
   env => { XDG_CONFIG_HOME => File::Temp::tempdir (CLEANUP => 1) },
   client_capabilities => { elicitation => { form => {} } },
);
my $before = @seen;
($ok, $r) = wait_for (sub {
   $restricted->rpc ("tools/call", {
      name => "request",
      arguments => { url => "$base/page?q=1", method => "PUT" },
   }, $_[0]);
});
ok $ok, "permission request transport success";
is $r->{resultType}, "input_required", "new method and URL require approval";
is scalar @seen, $before, "no HTTP call before permission granted";
my $question = (values %{$r->{inputRequests} || {}})[0];
my $permission = $question->{params}{_meta}{"anyevent-mcp/permission"}{request};
is $permission->{action}, "PUT", "HTTP method is permission action";
is $permission->{dimensions}{url}{value}, "$base/page?q=1", "URL is separate permission dimension";
is_deeply [map $_->{label}, @{$permission->{dimensions}{url}{choices}}], [
   "Exact URL including query", "This path, any query", "This origin (scheme, host, port)",
   "This hostname, any scheme or port", "Any HTTP(S) URL",
], "IP URL offers exact, path, origin, hostname and universal scopes";

($ok, $r) = wait_for (sub {
   $restricted->rpc ("tools/call", {
      name => "request",
      arguments => { url => "HTTPS://Example.COM:443/path?q=1#fragment", method => "PROPFIND" },
   }, $_[0]);
});
is $r->{resultType}, "input_required", "arbitrary HTTP method recognized";
$question = (values %{$r->{inputRequests} || {}})[0];
$permission = $question->{params}{_meta}{"anyevent-mcp/permission"}{request};
is $permission->{dimensions}{url}{value}, "https://example.com/path?q=1",
   "URL normalizes origin and removes fragments";
is scalar @{$permission->{dimensions}{url}{choices}}, 6, "DNS hostname offers subdomain scope";

undef $restricted;
undef $client;
undef $listener;
done_testing;
