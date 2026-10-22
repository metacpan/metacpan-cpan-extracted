use common::sense;
use Test::More;
use AnyEvent ();
use AnyEvent::Handle ();
use AnyEvent::MCP::Server ();
use AnyEvent::MCP::Server::Toolset ();
use AnyEvent::MCP::Server::JSONL ();
use AnyEvent::MCP::Server::HTTP ();
use JSON::XS ();
use Socket;

my $toolset = AnyEvent::MCP::Server::Toolset->new;
my $pending;

$toolset->tool (echo => "echo", {}, sub { $_[0]->result ($_[1]) });
$toolset->tool (slow => "slow", {}, sub { $pending = $_[0] });
$toolset->tool (fail => "fail", {}, sub { die "tool failed\n" });

my $server = AnyEvent::MCP::Server->new (toolsets => [$toolset]);
my $meta = {
   "io.modelcontextprotocol/protocolVersion" => "2026-07-28",
   "io.modelcontextprotocol/clientCapabilities" => {},
};

sub message {
   my ($id, $method, $params) = @_;

   { jsonrpc => "2.0", id => $id, method => $method, params => { %{$params || {}}, _meta => {%$meta} } }
}

my $response;
for my $id (1, 0, -1, 1.5, "1", "opaque") {
   for my $method ("ping", "unknown") {
      my $json = JSON::XS::encode_json ({
         jsonrpc => "2.0", id => $id, method => $method, params => {},
      });
      $server->json_rpc ($json, sub { $response = shift }, protocol_version => "2025-11-25");
      is JSON::XS::encode_json ([JSON::XS::decode_json ($response)->{id}]),
         JSON::XS::encode_json ([$id]), "wire ID type preserved for $method";
   }
}
$server->json_rpc (
   '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"probe","version":"0"}}}',
   sub { $response = shift },
);
like $response, qr/"id":1(?:,|})/, "initialization preserves numeric probe ID";

$server->rpc (message (1, "server/discover"), sub { $response = shift });
is $response->{result}{resultType}, "complete", "modern result type";
is $response->{result}{supportedVersions}[0], "2026-07-28", "discovery";
is $response->{result}{_meta}{"io.modelcontextprotocol/serverInfo"}{name}, "AnyEvent::MCP", "server identity";

for my $value (undef, "", "  \n \t \n") {
   my $empty = AnyEvent::MCP::Server->new (instructions => $value);
   $empty->rpc (message (101, "server/discover"), sub { $response = shift });
   ok !exists $response->{result}{instructions},
      "server/discover omits empty normalized instructions";
   $empty->rpc (message (102, "initialize", {
      protocolVersion => "2025-11-25", capabilities => {},
      clientInfo => { name => "probe", version => "0" },
   }), sub { $response = shift });
   ok !exists $response->{result}{instructions},
      "initialize omits empty normalized instructions";
}
my $guidance = AnyEvent::MCP::Server->new (instructions => "  \n   keep this\n  ");
$guidance->rpc (message (103, "server/discover"), sub { $response = shift });
is $response->{result}{instructions}, "keep this",
   "nonempty instructions still normalize and survive discovery";

my $hint = "Full instructions: meta-instructions tool description.";
my $shared = AnyEvent::MCP::Server::Toolset->new;
my $auto = AnyEvent::MCP::Server->new (
   toolsets => [$shared],
   instructions => "  Full operating rules.  ",
   short_instructions => "  Find tools when useful. ",
   custom_instructions => "  Use for persistent memory. ",
   auto_instructions => 1,
);
$auto->rpc (message (106, "server/discover"), sub { $response = shift });
is $response->{result}{instructions}, "Use for persistent memory.\n\nFind tools when useful.\n\n$hint",
   "auto instructions advertise custom purpose and short guidance";
$auto->rpc (message (107, "initialize", {
   protocolVersion => "2025-11-25", capabilities => {},
   clientInfo => { name => "probe", version => "0" },
}), sub { $response = shift });
is $response->{result}{instructions}, "Use for persistent memory.\n\nFind tools when useful.\n\n$hint",
   "legacy initialization gets short instructions too";
$auto->rpc (message (108, "tools/list"), sub { $response = shift });
my ($meta_tool) = grep $_->{name} eq "meta-instructions", @{$response->{result}{tools}};
like $meta_tool->{description}, qr/Use for persistent memory\..*Full operating rules\./s,
   "instance purpose precedes full instructions in generated tool description";
$auto->rpc (message (109, "tools/call", { name => "meta-instructions" }), sub { $response = shift });
is $response->{result}{content}[0]{text}, "Use for persistent memory.\n\nFull operating rules.",
   "generated tool returns full effective instructions";
ok !@{$shared->list}, "generated tool does not mutate caller toolsets";

my $custom_only = AnyEvent::MCP::Server->new (
   instructions => "Details", custom_instructions => "Memory", auto_instructions => 1,
);
$custom_only->rpc (message (110, "server/discover"), sub { $response = shift });
is $response->{result}{instructions}, "Memory\n\n$hint",
   "custom purpose can replace generic short instructions";

my $short_only = AnyEvent::MCP::Server->new (
   instructions => "Details", short_instructions => "Discover tools", auto_instructions => 1,
);
$short_only->rpc (message (113, "server/discover"), sub { $response = shift });
is $response->{result}{instructions}, "Discover tools\n\n$hint",
   "short instructions also receive the standard pointer";

my $fallback = AnyEvent::MCP::Server->new (instructions => "Details", auto_instructions => 1);
$fallback->rpc (message (114, "server/discover"), sub { $response = shift });
is $response->{result}{instructions}, "Details",
   "no redundant pointer when advertising full instructions as fallback";

my $disabled = AnyEvent::MCP::Server->new (
   instructions => "Details", short_instructions => "Short", auto_instructions => 0,
);
$disabled->rpc (message (111, "server/discover"), sub { $response = shift });
is $response->{result}{instructions}, "Details", "low-level default opt-out keeps full instructions";
$disabled->rpc (message (112, "tools/list"), sub { $response = shift });
ok !(grep $_->{name} eq "meta-instructions", @{$response->{result}{tools}}),
   "opt-out creates no meta tool";

my $collision = AnyEvent::MCP::Server::Toolset->new;
$collision->tool (meta_instructions => "existing", {}, sub { $_[0]->reply ({}) });
eval { AnyEvent::MCP::Server->new (toolsets => [$collision], instructions => "Details", auto_instructions => 1) };
like $@, qr/duplicate MCP tool 'meta-instructions'/, "reserved tool name collision fails";

my $aemcp_caps = { extensions => { "anyevent-mcp/multibroker" => { version => 1 } } };
my $legacy_peer = {};
$server->rpc ({
   jsonrpc => "2.0", id => 104, method => "initialize",
   params => { protocolVersion => "2025-11-25", capabilities => $aemcp_caps,
               clientInfo => { name => "broker", version => "1" } },
}, sub { $response = shift }, peer => $legacy_peer);
ok $legacy_peer->{aemcp_multibroker}, "legacy initialization negotiates multibroker extension";
my $modern_peer = {};
my $modern_discover = message (105, "server/discover");
$modern_discover->{params}{_meta}{"io.modelcontextprotocol/clientCapabilities"} = $aemcp_caps;
$server->rpc ($modern_discover, sub { $response = shift }, peer => $modern_peer);
ok $modern_peer->{aemcp_multibroker},
   "modern discovery negotiates multibroker extension from per-request capabilities";

my $request = $server->rpc (message (2, "tools/call", { name => "echo", arguments => { a => 42 } }),
   sub { $response = shift });
is $response->{result}{structuredContent}{a}, 42, "structured result";
is JSON::XS::decode_json ($response->{result}{content}[0]{text})->{a}, 42, "JSON text fallback";
ok !exists $request->{on_reply} && !exists $request->{_reply}, "release reply callbacks";
eval { $request->reply ({}) };
like $@, qr/already finished/, "duplicate reply dies";

$server->rpc (message (3, "tools/call", { name => "fail" }), sub { $response = shift });
ok $response->{result}{isError}, "tool exception is a tool error";
is $response->{result}{content}[0]{text}, "tool failed\n", "tool exception text";

$server->rpc (message (4, "tools/call", { name => "absent" }), sub { $response = shift });
is $response->{error}{code}, -32602, "unknown tool is a protocol error";
$server->rpc (message (5, "unknown"), sub { $response = shift });
is $response->{error}{code}, -32601, "unknown method";
$server->json_rpc ("{", sub { $response = JSON::XS::decode_json shift });
is $response->{error}{code}, -32700, "parse error";
$server->rpc ([], sub { $response = shift });
is $response->{error}{code}, -32600, "reject batches";
$server->rpc (message (6, "tools/call", { name => "echo", arguments => [] }), sub { $response = shift });
is $response->{error}{code}, -32602, "invalid arguments";

my $unsupported = message (7, "ping");
$unsupported->{params}{_meta}{"io.modelcontextprotocol/protocolVersion"} = "2099-01-01";
$server->rpc ($unsupported, sub { $response = shift });
is $response->{error}{code}, -32022, "unsupported version";
is $response->{error}{data}{requested}, "2099-01-01", "requested version in error";

my $peer = {};
$server->rpc ({
   jsonrpc => "2.0", id => 8, method => "initialize",
   params => { protocolVersion => "2025-06-18", capabilities => {}, clientInfo => { name => "test", version => "0" } },
}, sub { $response = shift }, peer => $peer);
is $response->{result}{protocolVersion}, "2025-06-18", "legacy initialization";
ok !exists $response->{result}{resultType}, "legacy result shape";
$server->rpc ({ jsonrpc => "2.0", id => 9, method => "tools/call", params => { name => "echo" } },
   sub { $response = shift }, peer => $peer);
is_deeply $response->{result}{structuredContent}, {}, "omitted arguments";
$server->rpc (message (10, "ping"), sub { $response = shift }, peer => $peer);
is $response->{result}{resultType}, "complete", "modern metadata overrides legacy peer";
is $peer->{protocol_version}, "2025-06-18", "modern request does not alter legacy state";

my @cancel_responses;
$request = $server->rpc (message (11, "tools/call", { name => "slow" }),
   sub { push @cancel_responses, $_[0] }, peer => $peer);
my $cancels = 0;
$request->{on_cancel} = sub { ++$cancels };
$server->rpc ({ jsonrpc => "2.0", method => "notifications/cancelled", params => { requestId => 11 } },
   sub { ok !defined $_[0], "notification has no JSON-RPC response" }, peer => $peer);
ok $request->{cancelled}, "cancellation";
is_deeply \@cancel_responses, [undef],
   "cancellation completes the transport without a JSON-RPC response";
$request->cancel;
is $cancels, 1, "cancel callback once";
is scalar @cancel_responses, 1, "cancelled transport completes once";
eval { $request->reply ({}) };
like $@, qr/already finished/, "reply after cancellation dies";
$pending = undef;

my @notifications;
$request = AnyEvent::MCP::Server::Request->new (
   params => { _meta => { progressToken => 0 } },
   on_notify => sub { push @notifications, $_[2] },
);
$request->progress (1);
is $notifications[0]{progressToken}, 0, "zero progress token";
$request->reply ({});
$request->progress (2);
is scalar @notifications, 1, "late progress ignored";

my $custom = AnyEvent::MCP::Server->new (
   on_tools_call => sub {
      my ($server, $req, $args) = @_;
      is $args, $req->{args}, "custom dispatch receives same arguments";
      $req->error ("custom error");
   },
);
$custom->rpc (message (12, "tools/call", { name => "custom" }), sub { $response = shift });
is $response->{result}{content}[0]{text}, "custom error", "dispatch override";

socketpair my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
my $jsonl = AnyEvent::MCP::Server::JSONL->new (toolsets => [$toolset]);
$jsonl->accept ($a);
my $client = AnyEvent::Handle->new (fh => $b, on_error => sub { die $_[2] });
my $cv = AnyEvent->condvar;
my $timer = AnyEvent->timer (after => 30, cb => sub { die "JSONL timeout" });

$client->push_write (
   JSON::XS::encode_json (message (20, "tools/call", { name => "slow" })) . "\n"
   . JSON::XS::encode_json (message (21, "ping")) . "\n"
);
$client->push_read (line => sub {
   like $_[1], qr/"id":21(?:,|})/, "JSONL preserves numeric ID";
   is JSON::XS::decode_json ($_[1])->{id}, 21, "JSONL out-of-order reply";
   $pending->reply ({});
   $pending = undef;
});
$client->push_read (line => sub {
   is JSON::XS::decode_json ($_[1])->{id}, 20, "delayed JSONL reply";
   $cv->send;
});
$cv->recv;
undef $timer;
$jsonl->close;
$client->destroy;

sub post {
   my ($msg, $extra) = @_;

   my $body = JSON::XS::encode_json $msg;
   "POST /mcp/ HTTP/1.1\r\nContent-Type: application/json\r\nContent-Length: " . length ($body)
      . "\r\nMCP-Protocol-Version: 2026-07-28\r\nMcp-Method: $msg->{method}\r\n"
      . ($msg->{method} eq "tools/call" ? "Mcp-Name: $msg->{params}{name}\r\n" : "")
      . ($extra || "") . "\r\n$body"
}

sub http_read {
   my ($handle, $callback) = @_;

   $handle->push_read (line => "\r\n\r\n", sub {
      my ($handle, $header) = @_;
      my ($length) = $header =~ /Content-Length: ([0-9]+)/;

      $handle->push_read (chunk => $length, sub { $callback->($header, $_[1]) });
   });
}

my $headers = AnyEvent::MCP::Server::HTTP::_parse_request_headers (
   "POST /mcp/ HTTP/1.1\r\nmCp-MeThOd: ping\r\n"
   . "Mcp-Param-Region: a\r\nmcp-param-region: b\r\n"
   . "X-Value: one:two\r\nEmpty:\r\n"
   . "Method: DELETE\r\nUri: /wrong\r\nHttp_Version: 0.0"
);
is $headers->{method}, "POST", "HTTP parser reads request method";
is $headers->{uri}, "/mcp/", "HTTP parser reads request target";
is $headers->{http_version}, "1.1", "HTTP parser reads request protocol";
is $headers->{"mcp-method"}, "ping", "HTTP parser normalizes header case";
is $headers->{"mcp-param-region"}, "a,b", "HTTP parser comma-combines repeated fields";
is $headers->{"x-value"}, "one:two", "HTTP parser preserves colons in values";
is $headers->{empty}, "", "HTTP parser accepts empty field values";
is $headers->{method}, "POST", "header cannot override request method";
is $headers->{uri}, "/mcp/", "header cannot override request URI";
is $headers->{http_version}, "1.1", "header cannot override HTTP version";
my $ows = AnyEvent::MCP::Server::HTTP::_parse_request_headers (
   "POST /mcp/ HTTP/1.0\r\nContent-Length: \t42 \t"
);
is $ows->{http_version}, "1.0", "HTTP parser accepts legacy HTTP/1.0";
is $ows->{"content-length"}, "42", "HTTP parser strips optional whitespace";
my $future = AnyEvent::MCP::Server::HTTP::_parse_request_headers (
   "POST /mcp/ HTTP/1.9\r\nContent-Length: 0"
);
is $future->{http_version}, "1.9",
   "HTTP parser accepts future HTTP/1.x minor versions";
my $leading_zeroes = AnyEvent::MCP::Server::HTTP::_parse_request_headers (
   "POST   /mcp/  http/01.09\r\nContent-Length: 0"
);
is $leading_zeroes->{http_version}, "1.09",
   "HTTP parser follows AnyEvent::HTTP version recognition and normalizes major version";
ok !AnyEvent::MCP::Server::HTTP::_parse_request_headers (
   "POST /mcp/ HTTP/1.1\r\nX-Value: a\x00b"
), "HTTP parser rejects control bytes in field values";
ok !AnyEvent::MCP::Server::HTTP::_parse_request_headers (
   "POST /mcp/ HTTP/2.0\r\nHost: example"
), "HTTP parser rejects unsupported request version";
ok !AnyEvent::MCP::Server::HTTP::_parse_request_headers (
   "POST /mcp/ HTTP/1.1\r\nBad Header: value"
), "HTTP parser rejects malformed field names";
ok !AnyEvent::MCP::Server::HTTP::_parse_request_headers (
   "POST /mcp/ HTTP/1.1\r\nMcp-Method: ping\r\n continued"
), "HTTP parser rejects obsolete folded headers";

socketpair $a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
my $http = AnyEvent::MCP::Server::HTTP->new (auth => "none", toolsets => [$toolset]);
$http->accept ($a);
$client = AnyEvent::Handle->new (fh => $b, on_error => sub { die $_[2] });
$cv = AnyEvent->condvar;
$timer = AnyEvent->timer (after => 30, cb => sub { die "HTTP timeout" });

$client->push_write (
   post (message (30, "tools/call", { name => "slow" }),
      "Method: DELETE\r\nUri: /not-mcp/\r\nHttp_Version: 0.0\r\n")
   . post (message (31, "ping"))
);
my $release = AnyEvent->timer (after => 0.01, cb => sub {
   $pending->reply ({});
   $pending = undef;
});
http_read ($client, sub {
   like $_[0], qr/HTTP\/1.1 200 OK/, "HTTP status";
   like $_[1], qr/"id":30(?:,|})/, "HTTP preserves numeric ID";
   is JSON::XS::decode_json ($_[1])->{id}, 30, "HTTP first reply";
   http_read ($client, sub {
      is JSON::XS::decode_json ($_[1])->{id}, 31, "HTTP pipelined reply order";
      $cv->send;
   });
});
$cv->recv;
undef $timer;
undef $release;
$http->close;
$client->destroy;

# An unknown future 1.x minor version must still use persistent HTTP framing.
socketpair $a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
$http = AnyEvent::MCP::Server::HTTP->new (auth => "none", toolsets => [$toolset]);
$http->accept ($a);
$client = AnyEvent::Handle->new (fh => $b, on_error => sub { die $_[2] });
$cv = AnyEvent->condvar;
$timer = AnyEvent->timer (after => 30, cb => sub { die "HTTP/1.9 timeout" });
my $future_requests = post (message (32, "ping")) . post (message (33, "ping"));
$future_requests =~ s{HTTP/1\.1}{HTTP/1.9}g;
$client->push_write ($future_requests);
http_read ($client, sub {
   like $_[0], qr{HTTP/1.1 200 OK}, "HTTP/1.9 request accepted";
   is JSON::XS::decode_json ($_[1])->{id}, 32, "first future-version response";
   http_read ($client, sub {
      is JSON::XS::decode_json ($_[1])->{id}, 33,
         "future HTTP/1.x minor versions preserve persistent connections";
      $cv->send;
   });
});
$cv->recv;
undef $timer;
$http->close;
$client->destroy;

$http = AnyEvent::MCP::Server::HTTP->new (auth => "none", toolsets => [$toolset], origins => []);
for my $case (
   ["Origin: https://invalid.example\r\n", 403, undef],
   ["Mcp-Method: different\r\n", 400, -32020],
   ["Content-Length: 0\r\n", 400, undef],
   ["Content-Length: 999\r\n", 400, undef],
   ["Transfer-Encoding: chunked\r\n", 400, undef],
   ["Not A Header\r\n", 400, undef],
) {
   socketpair $a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
   $http->accept ($a);
   $client = AnyEvent::Handle->new (fh => $b, on_error => sub { die $_[2] });
   $cv = AnyEvent->condvar;
   $timer = AnyEvent->timer (after => 30, cb => sub { die "HTTP rejection timeout" });

   $client->push_write (post (message (40, "ping"), $case->[0]));
   http_read ($client, sub {
      like $_[0], qr/HTTP\/1.1 $case->[1]/, "HTTP rejection";
      is JSON::XS::decode_json ($_[1])->{error}{code}, $case->[2], "HTTP protocol error"
         if defined $case->[2];
      $cv->send;
   });
   $cv->recv;
   undef $timer;
   $http->close;
   $client->destroy;
}

for my $case (
   [undef, "https://browser.example", "POST", 200, "*", 1],
   [undef, "https://browser.example", "OPTIONS", 204, "*", 0],
   [["*"], "https://browser.example", "POST", 200, "*", 1],
   [["https://browser.example"], "https://browser.example", "POST", 200, "https://browser.example", 1],
   [["https://browser.example"], "https://other.example", "POST", 403, undef, 1],
   [["*"], "https://browser.example", "OPTIONS", 204, "*", 0],
   [[], "https://browser.example", "OPTIONS", 403, undef, 0],
   [[], undef, "OPTIONS", 405, undef, 0],
   [["*"], "https://browser.example", "POST", 401, "*", 0],
) {
   my ($origins, $origin, $method, $status, $allowed, $cookie) = @$case;

   socketpair $a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
   $http = AnyEvent::MCP::Server::HTTP->new (
      toolsets => [$toolset], (defined $origins ? (origins => $origins) : ()), tokens => ["token"],
   );
   $http->accept ($a);
   $client = AnyEvent::Handle->new (fh => $b, on_error => sub { die $_[2] });
   $cv = AnyEvent->condvar;
   $timer = AnyEvent->timer (after => 30, cb => sub { die "CORS timeout" });

   my $request = $method eq "POST"
      ? post (message (50, "ping"), defined $origin ? "Origin: $origin\r\n" : "")
      : "OPTIONS /mcp/ HTTP/1.1\r\n"
         . (defined $origin ? "Origin: $origin\r\n" : "")
         . "Access-Control-Request-Method: POST\r\n"
         . "Access-Control-Request-Headers: content-type,mcp-method\r\n\r\n";
   $request =~ s{POST /mcp/}{POST /token/mcp/} if $cookie;

   $client->push_write ($request);
   http_read ($client, sub {
      my ($header) = @_;

      like $header, qr/HTTP\/1.1 $status /, "CORS $method status";
      if (defined $allowed) {
         like $header, qr/^Access-Control-Allow-Origin: \Q$allowed\E\r?$/m, "allowed origin";
         like $header, qr/^Vary: Origin\r?$/m, "vary by allowed origin" if $allowed ne "*";
      } else {
         unlike $header, qr/Access-Control-Allow-Origin:/, "no allowed origin";
      }
      if ($status == 204) {
         like $header, qr/Access-Control-Allow-Methods: POST, OPTIONS/, "preflight methods";
         like $header, qr/Access-Control-Allow-Headers: .*mcp-method,mcp-name/, "modern preflight headers";
         like $header, qr/Access-Control-Max-Age: 86400/, "preflight cache";
      }
      $cv->send;
   });
   $cv->recv;
   undef $timer;
   $http->close;
   $client->destroy;
}

socketpair $a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
my $dispatched = 0;
$http = AnyEvent::MCP::Server::HTTP->new (auth => "none", 
   toolsets => [$toolset], connection_close => 1, on_request => sub { ++$dispatched },
);
$http->accept ($a);
undef $a;
$cv = AnyEvent->condvar;
my $received = 0;
$client = AnyEvent::Handle->new (
   fh => $b,
   on_error => sub { die $_[2] },
   on_read => sub { fail "unexpected second HTTP response"; $cv->send },
   on_eof => sub {
      ok $received, "response drained before EOF";
      is $_[0]{rbuf}, "", "no pipelined second response";
      is $dispatched, 1, "connection_close prevents dispatch of the next request";
      $cv->send;
   },
);
$timer = AnyEvent->timer (after => 30, cb => sub { $cv->croak ("connection_close timeout") });
$client->push_write (
   post (message (60, "tools/call", { name => "slow" }))
   . post (message (61, "ping"))
);
$release = AnyEvent->timer (after => 0.01, cb => sub {
   $pending->reply ({ content => [{ type => "text", text => "x" x 131072 }] });
   $pending = undef;
});
http_read ($client, sub {
   my ($header, $body) = @_;

   like $header, qr/^Connection: close\r?$/m, "connection_close header for HTTP/1.1";
   my $response = JSON::XS::decode_json $body;
   is $response->{id}, 60, "delayed response delivered";
   is length $response->{result}{content}[0]{text}, 131072, "complete response body before close";
   $received = 1;
});
$cv->recv;
undef $timer;
undef $release;
$http->close;
$client->destroy;

done_testing;
