use common::sense;
use Test::More;
BEGIN {
   plan skip_all => "extended webbrowser test (PERL_ANYEVENT_MCP_TESTS=1)"
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
}

BEGIN {
   eval {
      require AnyEvent::WebSocket::Server;
      require AnyEvent::WebSocket::Message;
      require Protocol::WebSocket::Frame;
      1
   } or plan skip_all => "WebSocket modules not installed";
}
use JSON::XS ();
use IO::Socket::INET ();
use IO::Select ();
use IPC::Open3 ();
use File::Temp ();
use File::Path ();
use Symbol ();
use Time::HiRes ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
local $ENV{XDG_CONFIG_HOME} = "$dir/config";
File::Path::mkpath ("$dir/config/anyevent-mcp/rules", 0, 0700);
my $policy = "$dir/config/anyevent-mcp/rules/webbrowser-default.ini";

sub policy {
   my ($decision, $origin) = @_;
   open my $fh, ">", $policy or die $!;
   chmod 0600, $policy or die $!;
   print {$fh} "[rule]\ndecision=allow\naction=read\nsandbox-grants=\n\n"
      . "[rule]\ndecision=$decision\naction=exec\nsandbox-grants=\n"
      . (defined $origin ? "match.origin=$origin\n\n[rule]\ndecision=deny\naction=exec\n" : "");
   close $fh or die $!;
}
policy "allow";

my $reserved = IO::Socket::INET->new (
   LocalAddr => "127.0.0.1", LocalPort => 0, Proto => "tcp", Listen => 1,
) or die $!;
my $port = $reserved->sockport;
close $reserved;
my $err = Symbol::gensym;
local $ENV{PERL_ANYEVENT_LOG} = ""; # capture activity and trace logs for assertions.
local $ENV{PERL_ANYEVENT_VERBOSE} = 9; # trace-level logging, including approved code
my $pid = IPC::Open3::open3 (my $in, my $out, $err,
   $^X, "-Ilib", "bin/mcp-webbrowser", "--stdio", "--bind", "127.0.0.1:$port",
   "--token", "primary", "--token", "secondary", "--ask", "mcp");
$in->autoflush (1);
my $buffer = "";
my $serial = 0;

END {
   if ($pid) {
      kill TERM => $pid;
      waitpid $pid, 0;
   }
}

sub send_rpc {
   my ($id, $method, $params) = @_;
   print {$in} JSON::XS::encode_json ({
      jsonrpc => "2.0", (defined $id ? (id => $id) : ()), method => $method, params => $params,
   }), "\n" or die $!;
}
sub read_rpc {
   my ($id) = @_;
   my $deadline = Time::HiRes::time () + 10;

   while (Time::HiRes::time () < $deadline) {
      while ($buffer =~ s/\A([^\n]*)\n//) {
         my $reply = JSON::XS::decode_json $1;
         return $reply if $reply->{id} == $id;
      }

      next unless IO::Select->new ($out)->can_read (.1);
      my $n = sysread $out, my $bytes, 8192;
      defined $n && $n or die "Unexpected broker EOF\n";
      $buffer .= $bytes;
   }

   die "MCP reply timed out\n";
}
sub rpc {
   my ($method, $params) = @_;
   my $id = ++$serial;
   send_rpc $id, $method, $params;
   read_rpc $id
}
sub tool {
   rpc "tools/call", { name => $_[0], arguments => $_[1] || {} }
}
sub tabs {
   tool ("tabs")->{result}{structuredContent}{tabs}
}
sub tcp {
   IO::Socket::INET->new (PeerAddr => "127.0.0.1", PeerPort => $port, Proto => "tcp", Timeout => 1)
}

my $ready;
for (1 .. 300) {
   $ready = tcp;
   last if $ready;
   Time::HiRes::sleep (.02);
}
ok $ready, "browser broker listens alongside stdio";
close $ready if $ready;

my $init = rpc ("initialize", {
   protocolVersion => "2025-11-25", capabilities => {},
   clientInfo => { name => "browser-test", version => "0" },
});
is $init->{result}{serverInfo}{name}, "mcp-webbrowser", "independent browser server identity";
my $listing = rpc ("tools/list", {});
is_deeply [sort map $_->{name}, @{$listing->{result}{tools}}],
   ["add-element", "call-tab-operation", "execute", "list-tab-operations", "meta-instructions", "tabs"], "browser toolset includes instructions";
like +(grep { $_->{name} eq "execute" } @{$listing->{result}{tools}})[0]{description},
   qr/Single expression returns implicitly.*body needs explicit return/, "tool advertises expression/body contract";
my ($execute_tool) = grep { $_->{name} eq "execute" } @{$listing->{result}{tools}};
like $execute_tool->{description}, qr/CODE becomes body of async \(\) => CODE; supply CODE, not arrow-function wrapper/,
   "execute documents injected wrapper and forbids supplying it";
like $execute_tool->{description}, qr/NOT async \(\) => .*returns function, rejected/,
   "execute advertises wrong-wrapper failure";
like $execute_tool->{inputSchema}{properties}{code}{description}, qr/Do not include async \(\) => wrapper/,
   "code argument documents expression/body rather than wrapper";
is $execute_tool->{inputSchema}{properties}{max_bytes}{default}, 16384, "16 KiB default result budget";
is $execute_tool->{inputSchema}{properties}{max_bytes}{maximum}, 2097152, "2 MiB maximum result budget";
my ($element_tool) = grep { $_->{name} eq "add-element" } @{$listing->{result}{tools}};
like $element_tool->{description}, qr/distinctive id or data-\*/, "element tool recommends caller-owned selector";
is_deeply [sort @{$element_tool->{inputSchema}{required}}], ["tag", "target"], "element requires target and tag";
is $element_tool->{inputSchema}{properties}{attributes}{additionalProperties}{type}, "string", "HTML attributes have string values";
ok $element_tool->{inputSchema}{properties}{properties}{additionalProperties}, "DOM properties permit JSON values";
is_deeply tabs (), [], "no tabs before opt-in registration";

sub upgrade {
   my ($cookie, $target) = @_;
   my $sock = tcp or die $!;
   $sock->autoflush (1);
   print {$sock} "GET /$cookie/$target HTTP/1.1\r\nHost: 127.0.0.1:$port\r\n",
      "Upgrade: websocket\r\nConnection: Upgrade\r\n",
      "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n",
      "Sec-WebSocket-Version: 13\r\nOrigin: https://page.example\r\n\r\n";
   my $bytes = "";
   my $deadline = Time::HiRes::time () + 5;

   while ($bytes !~ /\r\n\r\n/ && Time::HiRes::time () < $deadline) {
      next unless IO::Select->new ($sock)->can_read (.1);
      my $n = sysread $sock, my $part, 8192;
      last unless $n;
      $bytes .= $part;
   }

   my ($header, $frames) = split /\r\n\r\n/, $bytes, 2;
   my $parser = Protocol::WebSocket::Frame->new;
   $parser->append ($frames) if length $frames;
   ({ socket => $sock, parser => $parser }, $header)
}
sub send_ws {
   my ($peer, $packet) = @_;
   print {$peer->{socket}} Protocol::WebSocket::Frame->new (
      type => "text", masked => 1, buffer => JSON::XS::encode_json ($packet),
   )->to_bytes or die $!;
}
sub read_ws {
   my ($peer) = @_;
   my $deadline = Time::HiRes::time () + 5;

   while (Time::HiRes::time () < $deadline) {
      while (defined (my $bytes = $peer->{parser}->next_bytes)) {
         my $opcode = $peer->{parser}->opcode;
         return [$opcode, $opcode == 1 ? JSON::XS::decode_json ($bytes) : $bytes] unless $opcode == 10;
      }

      next unless IO::Select->new ($peer->{socket})->can_read (.1);
      my $n = sysread $peer->{socket}, my $bytes, 8192;
      defined $n && $n or die "Unexpected WebSocket EOF\n";
      $peer->{parser}->append ($bytes);
   }

   die "WebSocket reply timed out\n";
}
sub connect_page {
   my ($target, $instance) = @_;
   my ($peer, $header) = upgrade "secondary", $target;
   $header =~ /101/ or die "WebSocket upgrade failed: $header";
   send_ws $peer, ["mcp-webbrowser", 1, 2, $instance, { url => "https://page.example/", origin => "https://page.example", title => "Page" }];
   my $welcome = read_ws ($peer)->[1];
   ($peer, $welcome)
}

my ($bad, $header) = upgrade "wrong", "bad";
unlike $header, qr/101/, "bad token cannot upgrade";
close $bad->{socket};
my ($invalid_target, $invalid_header) = upgrade "primary", "%ZZ";
unlike $invalid_header, qr/101/, "invalid target cannot upgrade";
close $invalid_target->{socket};
my ($early) = upgrade "primary", "early";
send_ws $early, ["state", { url => "https://page.example/", title => "early" }];
my $closed = read_ws $early;
is $closed->[0], 8, "commands before hello close the connection";
is unpack ("n", $closed->[1]), 1002, "protocol rejection uses status 1002";
like substr ($closed->[1], 2), qr/Invalid browser hello/, "protocol rejection carries its reason";
close $early->{socket};
my ($wrong_version) = upgrade "primary", "wrong-version";
send_ws $wrong_version, ["mcp-webbrowser", 2, 0, "wrong-version",
   { url => "https://page.example/", title => "Page" }];
my $rejected = read_ws $wrong_version;
is $rejected->[0], 8, "incompatible browser protocol closes the connection";
is unpack ("n", $rejected->[1]), 1002, "incompatible protocol uses status 1002";
like substr ($rejected->[1], 2), qr/Unsupported browser protocol 2\.0 \(server 1\.2\)/,
   "close frame explains the version mismatch";
close $wrong_version->{socket};

my ($old_client) = upgrade "primary", "old-client";
send_ws $old_client, ["mcp-webbrowser", 1, 0, "old-document",
   { url => 'https://user:pass@page.example/path?query', title => "Old client" }];
is_deeply read_ws ($old_client)->[1], ["welcome", "old-client", "old-document", 1],
   "compatible old browser protocol 1.0 connects";
is +(tabs ())->[0]{origin}, "https://page.example", "broker derives origin from URL without credentials";
my $old_id = ++$serial;
send_rpc $old_id, "tools/call", { name => "execute", arguments => { target => "old-client", code => "1+1" } };
my $old_call = read_ws ($old_client)->[1];
is $old_call->[3]{code}, "1+1", "old browser client retains JavaScript execution";
send_ws $old_client, ["reply", $old_call->[1], JSON::XS::true, 2];
is read_rpc ($old_id)->{result}{structuredContent}{value}, 2, "old client execution completes";
is_deeply tool ("list-tab-operations", { target => "old-client" })->{result}{structuredContent}{operations},
   [], "unsupported tab operations discover as empty for old client";
like tool ("call-tab-operation", { target => "old-client", operation => "test" })
   ->{result}{content}[0]{text}, qr/require protocol 1\.1/,
   "calling unsupported old-client operation fails without disconnect";
send_ws $old_client, ["quit"];
is read_ws ($old_client)->[0], 8, "old browser client quits normally";
close $old_client->{socket};

my ($newer_client) = upgrade "primary", "newer-client";
send_ws $newer_client, ["mcp-webbrowser", 1, 3, "newer-document",
   { url => "https://page.example/", title => "Newer client" }];
is_deeply read_ws ($newer_client)->[1], ["welcome", "newer-client", "newer-document", 1],
   "compatible newer minor protocol connects";
send_ws $newer_client, ["quit"];
is read_ws ($newer_client)->[0], 8, "newer client quits normally";
close $newer_client->{socket};

my ($one, $welcome) = connect_page "tab", "document-one";
is_deeply $welcome, ["welcome", "tab", "document-one", 1], "authenticated page is registered";
is $welcome->[3], 1, "first document starts at revision 1";
like JSON::XS::encode_json ($welcome), qr/\A\["welcome","tab","document-one",1\]\z/,
   "welcome revision is a JSON number";
my ($two, $second) = connect_page "other", "document-two";
is_deeply $second, ["welcome", "other", "document-two", 1], "different tabs have their own revisions";
my ($again, $replacement) = connect_page "other", "document-two";
is_deeply $replacement, ["welcome", "other", "document-two", 1], "same document reconnect retains revision";
like JSON::XS::encode_json ($replacement), qr/\A\["welcome","other","document-two",1\]\z/,
   "reconnect welcome still uses numeric revision";
is read_ws ($two)->[0], 8, "reconnect closes old connection";
close $two->{socket};
my $registered = tabs;
is_deeply [map $_->{target}, @$registered], ["other", "tab"], "tabs enumerates registered tabs";

policy "ask";
my $scope_reply = rpc "tools/call", {
   name => "execute", arguments => { target => "tab", code => "arbitrary_code()" },
   _meta => {
      "io.modelcontextprotocol/protocolVersion" => "2026-07-28",
      "io.modelcontextprotocol/clientCapabilities" => { elicitation => { form => {} } },
   },
};
is $scope_reply->{result}{resultType}, "input_required", "browser execution requests permission";
my ($scope_question) = values %{$scope_reply->{result}{inputRequests}};
my $scope = $scope_question->{params}{_meta}{"anyevent-mcp/permission"}{request}{dimensions};
is_deeply [sort keys %$scope], [qw(code origin tab)],
   "execution permissions have independent code, tab and origin dimensions";
is $scope->{tab}{default}, $scope->{tab}{choices}[0]{match},
   "tab scope defaults to this observable tab";
is $scope->{code}{default}, $scope->{code}{choices}[1]{match},
   "JavaScript scope defaults to any code";
is $scope->{code}{choices}[0]{match}, 'execute:"arbitrary_code()"',
   "exact-code approval uses a distinct, reproducible command identity";
is $scope->{code}{choices}[0]{label}, "This exact code: arbitrary_code()",
   "exact-code scope displays the selected JavaScript";
is $scope->{origin}{default},
   "https://page.example", "site scope defaults to current origin";
is $scope->{tab}{label}, "Tab", "tab scope is clearly labelled";
is $scope->{code}{label}, "JavaScript", "code scope is clearly labelled";
is $scope->{origin}{label}, "Site", "origin scope is clearly labelled";
is $scope->{origin}{choices}[0]{label}, "This origin: https://page.example",
   "origin scope shows the selected site";
like $scope->{tab}{choices}[1]{label}, qr/Any opted-in tab/,
   "all-tab choice remains available";
ok !exists $scope->{subject}, "no overlapping combined subject dimension";
{
   my $coder = JSON::XS->new->allow_nonref;
   open my $fh, ">", $policy or die $!;
   print {$fh} "[rule]\ndecision=allow\naction=read\nsandbox-grants=\n\n",
      "[rule]\ndecision=allow\naction=exec\nsandbox-grants=\n",
      "match.tab=", $coder->encode ("tab"), "\n",
      "match.code=execute:", $coder->encode ("only_here()"), "\n",
      "match.origin=https://page.example\n\n",
      "[rule]\ndecision=deny\naction=exec\n";
   close $fh or die $!;

   my $id = ++$serial;
   send_rpc $id, "tools/call", { name => "execute", arguments => { target => "tab", code => "only_here()" } };
   my $call = read_ws ($one)->[1];
   is $call->[3]{code}, "only_here()", "specific tab, code and origin permission permits matching call";
   send_ws $one, ["reply", $call->[1], JSON::XS::true, "ok"];
   is read_rpc ($id)->{result}{structuredContent}{value}, "ok", "matched grant executes normally";

   ok tool ("execute", { target => "other", code => "only_here()" })->{result}{isError},
      "same code in another tab is denied";
   ok tool ("execute", { target => "tab", code => "different_code()" })->{result}{isError},
      "different code in the same tab is denied";
   ok tool ("call-tab-operation", { target => "tab", operation => "only_here()" })->{result}{isError},
      "a JavaScript grant cannot authorize browser operations";
}
policy "allow";

send_ws $one, ["state", { url => "https://page.example/next?secret=not-for-logs#fragment", origin => "https://page.example", title => "Updated" }];
for (1 .. 100) {
   $registered = tabs;
   last if $registered->[1]{title} eq "Updated";
   Time::HiRes::sleep (.01);
}
is $registered->[1]{title}, "Updated", "state updates replace reported metadata";
is $registered->[1]{revision}, 1, "tabs expose the document revision";
like JSON::XS::encode_json ({revision => $registered->[1]{revision}}),
   qr/"revision":1/, "tabs serializes document revision as a JSON number";

policy "allow", "https://page.example";
my $origin_id = ++$serial;
send_rpc $origin_id, "tools/call", { name => "execute", arguments => { target => "tab", code => "allowed_origin()" } };
my $origin_call = read_ws ($one)->[1];
is $origin_call->[3]{code}, "allowed_origin()", "exact origin allows execution";
send_ws $one, ["reply", $origin_call->[1], JSON::XS::true, "yes"];
is read_rpc ($origin_id)->{result}{structuredContent}{value}, "yes", "origin-scoped permission dispatch succeeded";
send_ws $one, ["state", { url => "https://other.example/", origin => "https://other.example", title => "Cross-origin" }];
for (1 .. 100) {
   last if (tabs ())->[1]{origin} eq "https://other.example";
   Time::HiRes::sleep (.01);
}
ok tool ("execute", { target => "tab", code => "forbidden_origin()" })->{result}{isError},
   "same opted-in tab loses origin-specific execution authority on cross-origin navigation";
ok tool ("add-element", { target => "tab", tag => "style" })->{result}{isError},
   "DOM injection is origin-scoped too";
ok tool ("call-tab-operation", { target => "tab", operation => "debugger.trace" })->{result}{isError},
   "tab operation execution is origin-scoped too";
send_ws $one, ["state", { url => "https://page.example/next?secret=not-for-logs#fragment", origin => "https://page.example", title => "Updated" }];
for (1 .. 100) {
   last if (tabs ())->[1]{origin} eq "https://page.example";
   Time::HiRes::sleep (.01);
}
policy "allow", "https://page.example";

send_ws $one, ["state", { url => "https://page.example/", title => "Old userscript" }];
for (1 .. 100) {
   $registered = tabs;
   last if $registered->[1]{title} eq "Old userscript";
   Time::HiRes::sleep (.01);
}
is $registered->[1]{origin}, "https://page.example", "origin is inferred from legacy state update";
$old_id = ++$serial;
send_rpc $old_id, "tools/call", { name => "execute", arguments => {
   target => "tab", code => "legacy_origin()",
}};
$old_call = read_ws ($one)->[1];
is $old_call->[3]{code}, "legacy_origin()", "origin-scoped permission works for legacy state";
send_ws $one, ["reply", $old_call->[1], JSON::XS::true, "old"];
is read_rpc ($old_id)->{result}{structuredContent}{value}, "old",
   "old state without origin does not prevent execution";
send_ws $one, ["state", {
   url => "https://page.example/next?secret=not-for-logs#fragment",
   origin => "https://spoof.example", title => "Updated",
}];
for (1 .. 100) {
   $registered = tabs;
   last if $registered->[1]{title} eq "Updated";
   Time::HiRes::sleep (.01);
}
is $registered->[1]{origin}, "https://page.example", "URL takes precedence over redundant origin field";
policy "allow";

my $id = ++$serial;
send_rpc $id, "tools/call", { name => "execute", arguments => {
   target => "tab", instance_id => "document-one", code => "Promise.resolve (42)", max_bytes => 65536,
}};
my $call = read_ws ($one)->[1];
is_deeply [@$call[0, 2, 3]], ["call", "execute", { code => "Promise.resolve (42)", max_bytes => 65536 }],
   "execute RPC preserves code and custom result budget";
like JSON::XS::encode_json ($call), qr/\A\["call",[1-9][0-9]*,"execute",/,
   "normal call ID remains a JSON number";
send_ws $one, ["reply", $call->[1], JSON::XS::true, [42, undef, "\x{e4}"]];
is_deeply read_rpc ($id)->{result}{structuredContent}{value}, [42, undef, "\x{e4}"], "structured JSON results preserve arrays, null and Unicode";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "execute", arguments => { target => "tab", code => "{ throw 1; }" } };
$call = read_ws ($one)->[1];
is $call->[3]{max_bytes}, 16384, "normal execute uses 16 KiB budget when omitted";
send_ws $one, ["reply", $call->[1], JSON::XS::false, "page exception"];
like read_rpc ($id)->{result}{content}[0]{text}, qr/page exception/, "browser exception becomes tool error";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "add-element", arguments => {
   target => "tab", instance_id => "document-one", revision => 1,
   tag => "style", parent => "head",
   attributes => { id => "mcp-css", "data-owner" => "test" },
   properties => { textContent => "body{color:red}" },
}};
$call = read_ws ($one)->[1];
is_deeply [@$call[0, 2, 3]], ["call", "add_element", {
   tag => "style", parent => "head",
   attributes => { id => "mcp-css", "data-owner" => "test" },
   properties => { textContent => "body{color:red}" },
}], "add_element forwards attributes/properties and optional parent without inventing an id";
send_ws $one, ["reply", $call->[1], JSON::XS::true, { tag => "style", id => "mcp-css" }];
is_deeply read_rpc ($id)->{result}{structuredContent}{value}, { tag => "style", id => "mcp-css" },
   "add_element returns the browser-created element identity";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "add-element", arguments => { target => "tab", tag => "div" } };
$call = read_ws ($one)->[1];
is_deeply $call->[3], { tag => "div" }, "add_element does not add automatic attributes or identifiers";
send_ws $one, ["reply", $call->[1], JSON::XS::false, "Element parent not found"];
like read_rpc ($id)->{result}{content}[0]{text}, qr/Element parent not found/, "DOM injection errors propagate";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "list-tab-operations", arguments => {
   target => "tab", instance_id => "document-one", revision => 1,
}};
$call = read_ws ($one)->[1];
is_deeply [@$call[0, 2, 3]], ["call", "list_tab_operations", { max_bytes => 16384 }],
   "list-tab-operations asks the tab, without registering any commands";
send_ws $one, ["reply", $call->[1], JSON::XS::true, []];
is_deeply read_rpc ($id)->{result}{structuredContent}, { operations => [] },
   "a tab with no extensions offers no additional operations";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "list-tab-operations", arguments => {
   target => "tab", max_bytes => 32768,
}};
$call = read_ws ($one)->[1];
is $call->[3]{max_bytes}, 32768, "custom discovery result budget reaches tab";
send_ws $one, ["reply", $call->[1], JSON::XS::true, [
   { name => "debugger.trace", description => "Collect breakpoint hits",
     inputSchema => { type => "object" } },
]];
is +(read_rpc ($id)->{result}{structuredContent}{operations}[0]{name}),
   "debugger.trace", "tab-provided operation descriptions pass through";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "call-tab-operation", arguments => {
   target => "tab", instance_id => "document-one", revision => 1,
   operation => "debugger.trace", arguments => { max_hits => 10 }, max_bytes => 32768,
}};
$call = read_ws ($one)->[1];
is_deeply [@$call[0, 2, 3]], ["call", "call_tab_operation", {
   operation => "debugger.trace", arguments => { max_hits => 10 }, max_bytes => 32768,
}], "generic tab-operation call forwards name, arguments and result budget";
send_ws $one, ["reply", $call->[1], JSON::XS::true, { hits => [1, 2] }];
is_deeply read_rpc ($id)->{result}{structuredContent}{value}, { hits => [1, 2] },
   "tab-operation result passes through unchanged";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "call-tab-operation", arguments => {
   target => "tab", operation => "debugger.pause",
}};
$call = read_ws ($one)->[1];
is_deeply $call->[3]{arguments}, {}, "omitted operation arguments default to empty object";
send_ws $one, ["reply", $call->[1], JSON::XS::false, "No additional operations"];
like read_rpc ($id)->{result}{content}[0]{text}, qr/No additional operations/,
   "userscript can reject calls when no additional operations exist";

ok tool ("call-tab-operation", { target => "tab", operation => "", arguments => {} })
   ->{result}{isError}, "empty operation name is rejected";
ok tool ("call-tab-operation", { target => "tab", operation => "debugger.trace", arguments => [] })
   ->{result}{isError}, "operation arguments must be a JSON object";
ok tool ("list-tab-operations", { target => [] })
   ->{result}{isError}, "operation discovery requires a valid target";
ok tool ("call-tab-operation", { target => "tab", revision => 999, operation => "debugger.trace" })
   ->{result}{isError}, "stale document revision rejects additional operations";
ok tool ("list-tab-operations", { target => "tab", instance_id => "old" })
   ->{result}{isError}, "stale document instance rejects operation discovery";

ok tool ("execute", { target => "tab", instance_id => "old", code => "1" })->{result}{isError},
   "optional instance guard rejects a replaced document";
policy "deny";
ok tool ("execute", { target => "tab", code => "denied" })->{result}{isError}, "permission denial prevents dispatch";
ok tool ("add-element", { target => "tab", tag => "style" })->{result}{isError},
   "add_element requires the same exec permission";
ok tool ("call-tab-operation", { target => "tab", operation => "debugger.trace" })->{result}{isError},
   "tab operations also require exec permission";
policy "allow";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "execute", arguments => { target => "tab", code => "pending" } };
$call = read_ws ($one)->[1];
is $call->[3]{code}, "pending", "denied and stale calls never reached the browser";
send_rpc undef, "notifications/cancelled", { requestId => $id, reason => "test" };
my $cancel = read_ws ($one)->[1];
is_deeply $cancel, ["cancel", $call->[1]], "cancellation reaches browser client";
like JSON::XS::encode_json ($cancel), qr/\A\["cancel",[1-9][0-9]*\]\z/,
   "cancel ID remains a JSON number";
send_ws $one, ["reply", $call->[1], JSON::XS::true, "late"];
is scalar @{tabs ()}, 2, "late cancelled reply is ignored";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "execute", arguments => { target => "tab", code => "slow", timeout => 1 } };
$call = read_ws ($one)->[1];
is_deeply read_ws ($one)->[1], ["cancel", $call->[1]], "timeout sends best-effort cancellation";
like read_rpc ($id)->{result}{content}[0]{text}, qr/timed out/, "timeout finishes outstanding tool request";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "execute", arguments => { target => "tab", code => "disconnect" } };
$call = read_ws ($one)->[1];
close $one->{socket};
like read_rpc ($id)->{result}{content}[0]{text}, qr/disconnected/, "disconnect fails pending calls";
is scalar @{tabs ()}, 1, "disconnected page is removed";

my ($rejoined, $same_doc) = connect_page "tab", "document-one";
is $same_doc->[3], 1, "same document rejoining after disconnect keeps revision";
$id = ++$serial;
send_rpc $id, "tools/call", { name => "list-tab-operations", arguments => { target => "tab" }};
$call = read_ws ($rejoined)->[1];
send_ws $rejoined, ["reply", $call->[1], JSON::XS::true, []];
is_deeply read_rpc ($id)->{result}{structuredContent}{operations}, [],
   "reconnect rediscovers operations rather than retaining a stale list";

$id = ++$serial;
send_rpc $id, "tools/call", { name => "execute", arguments => {
   target => "tab", revision => 1, code => "history.pushState({}, '', '/spa')", navigate => JSON::XS::true,
}};
$call = read_ws ($rejoined)->[1];
is_deeply [@$call[0, 2, 3]], ["call", "navigate", { code => "history.pushState({}, '', '/spa')", max_bytes => 16384 }],
   "navigation call is distinguished from ordinary execution";
like JSON::XS::encode_json ($call), qr/\A\["call",[1-9][0-9]*,"navigate",/,
   "navigate call ID remains a JSON number";
send_ws $rejoined, ["ready", $call->[1]];
my $proceed = read_ws ($rejoined)->[1];
is_deeply $proceed, ["proceed", $call->[1]],
   "broker confirms receipt before navigation is executed";
like JSON::XS::encode_json ($proceed), qr/\A\["proceed",[1-9][0-9]*\]\z/,
   "navigation proceed preserves numeric request ID for JavaScript Map lookup";
send_ws $rejoined, ["navigated", $call->[1], {url => "https://page.example/spa", title => "SPA"}];
my $nav_result = read_rpc ($id)->{result}{structuredContent};
is_deeply $nav_result, {navigation => "same-document", revision => 1,
   url => "https://page.example/spa", origin => "https://page.example", title => "SPA"},
   "same-document navigation completes without changing revision";

$id = ++$serial;
send_rpc $id, "tools/call", {name => "execute", arguments => {
   target => "tab", code => "location.href='/next'", navigate => JSON::XS::true,
}};
$call = read_ws ($rejoined)->[1];
send_ws $rejoined, ["ready", $call->[1]];
is_deeply read_ws ($rejoined)->[1], ["proceed", $call->[1]], "full navigation receives proceed";
my ($next, $new_doc) = connect_page "tab", "document-next";
is $new_doc->[3], 2, "replacement document increments revision";
is read_ws ($rejoined)->[0], 8, "old connection replaced when a new document arrives";
$nav_result = read_rpc ($id)->{result}{structuredContent};
is_deeply $nav_result, {navigation => "document", revision => 2,
   url => "https://page.example/", origin => "https://page.example", title => "Page"},
   "new document finishes pending navigation request";
ok tool ("execute", {target => "tab", revision => 1, code => "1"})->{result}{isError},
   "stale revision rejects execution";
is scalar @{tabs ()}, 2, "new document takes old tab's target instead of allocating a suffix";

$id = ++$serial;
send_rpc $id, "tools/call", {name => "execute", arguments => {
   target => "tab", code => "nothing()", navigate => JSON::XS::true, timeout => 1,
}};
$call = read_ws ($next)->[1];
send_ws $next, ["ready", $call->[1]];
is_deeply read_ws ($next)->[1], ["proceed", $call->[1]], "ambiguous navigation started";
is_deeply read_ws ($next)->[1], ["cancel", $call->[1]], "timeout sends cancellation advisory";
$nav_result = read_rpc ($id)->{result}{structuredContent};
is $nav_result->{navigation}, "timeout", "unobserved navigation reported as timeout";
is $nav_result->{revision}, 2, "timed out navigation still reports known revision";

$id = ++$serial;
send_rpc $id, "tools/call", {name => "execute", arguments => {
   target => "tab", code => "location.href='/nowhere'", navigate => JSON::XS::true, timeout => 1,
}};
$call = read_ws ($next)->[1];
send_ws $next, ["ready", $call->[1]];
is_deeply read_ws ($next)->[1], ["proceed", $call->[1]], "navigation handshake before disconnection";
close $next->{socket};
$nav_result = read_rpc ($id)->{result}{structuredContent};
is $nav_result->{navigation}, "timeout", "lost connection eventually yields navigation timeout, not an error";
is $nav_result->{revision}, 2, "lost connection retains last known revision";
is scalar @{tabs ()}, 1, "disconnected tab is hidden while navigation state survives";

close $rejoined->{socket};

my $http = tcp or die $!;
$http->autoflush (1);
my $body = JSON::XS::encode_json ({ jsonrpc => "2.0", id => 1, method => "server/discover", params => {} });
print {$http} "POST /primary/ HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\nContent-Type: application/json\r\n",
   "Content-Length: ", length $body, "\r\n\r\n", $body;
my $response = do { local $/; <$http> };
like $response, qr/HTTP\/1\.1 200/, "same listener serves authenticated MCP HTTP";
close $http;

my $other_id = JSON::XS->new->allow_nonref->encode ("other");
my @tab_only = (
   "execute:$other_id:" . JSON::XS->new->allow_nonref->encode ("document.title"),
   "^" . quotemeta ("execute:$other_id:"),
   "^" . quotemeta ("operation:$other_id:"),
);
my @keep_scopes = ("^execute:", "^" . quotemeta ('execute:"tab":'));
my $tab_id = JSON::XS->new->allow_nonref->encode ("tab");
open my $rules, ">>", $policy or die $!;
print {$rules} map {
   "[rule]\ndecision=allow\naction=exec\nmatch.subject=$_\nsandbox-grants=\n\n"
} @tab_only, @keep_scopes;
print {$rules}
   "[rule]\ndecision=allow\naction=exec\nsandbox-grants=\n",
   "match.tab=$other_id\nmatch.code=^execute:\n\n",
   "[rule]\ndecision=allow\naction=exec\nsandbox-grants=\n",
   "match.tab=$other_id\nmatch.code=^operation:\n\n",
   "[rule]\ndecision=allow\naction=exec\nsandbox-grants=\n",
   "match.tab=$tab_id\nmatch.code=^execute:\n\n",
   "[rule]\ndecision=allow\naction=exec\nsandbox-grants=\n",
   "match.tab=^\nmatch.code=^execute:\n\n";
close $rules or die $!;

send_ws $again, ["quit"];
is read_ws ($again)->[0], 8, "explicit tab disable closes browser connection";
is_deeply tabs (), [], "disabled tab is no longer listed";
open my $saved, "<", $policy or die $!;
my $saved_rules = do { local $/; <$saved> };
close $saved;
for my $scope (@tab_only) {
   unlike $saved_rules, qr/\Qmatch.subject\E\s*=\s*\Q$scope\E(?:\n|\z)/,
      "disabled tab's $scope permission is removed";
}
for my $scope (@keep_scopes) {
   like $saved_rules, qr/\Qmatch.subject\E\s*=\s*\Q$scope\E(?:\n|\z)/,
      "unrelated $scope permission survives tab cleanup";
}
unlike $saved_rules, qr/\Qmatch.tab\E\s*=\s*\Q$other_id\E(?:\n|\z)/,
   "new tab-dimension grants for retired tab are removed";
like $saved_rules, qr/\Qmatch.tab\E\s*=\s*\Q$tab_id\E(?:\n|\z)/,
   "new grant for another tab survives";
like $saved_rules, qr/\Qmatch.tab\E\s*=\s*\^(?:\n|\z)/,
   "all-tab grant survives";
close $again->{socket};
my ($fresh, $new_session) = connect_page "other", "document-three";
is $new_session->[3], 1, "explicit disable ends session; next opt-in starts revision 1";
is_deeply [map { [$_->{last_allowed}, $_->{marked}] } @{tabs ()}], [[JSON::XS::false, JSON::XS::false]],
   "connecting a tab alone neither selects nor marks it";
send_ws $fresh, ["allowed"];
send_ws $fresh, ["mark", JSON::XS::true];
is_deeply read_ws ($fresh)->[1], ["marked", JSON::XS::true], "mark confirmation reaches the browser";
ok +(tabs ())->[0]{last_allowed}, "explicit Allow event selects the most recently allowed tab";
ok +(tabs ())->[0]{marked}, "explicit mark is exposed through tab discovery";

my ($selector, $selector_welcome) = connect_page "selector", "selector-document";
is_deeply $selector_welcome, ["welcome", "selector", "selector-document", 1],
   "another tab connects without changing selections";
my %by_target = map { $_->{target} => $_ } @{tabs ()};
ok $by_target{other}{last_allowed} && $by_target{other}{marked}
   && !$by_target{selector}{last_allowed} && !$by_target{selector}{marked},
   "connecting another tab does not change the last Allow or explicit mark";
send_ws $selector, ["mark", JSON::XS::true];
is_deeply read_ws ($fresh)->[1], ["marked", JSON::XS::false], "old marked tab is notified";
is_deeply read_ws ($selector)->[1], ["marked", JSON::XS::true], "new marked tab is notified";
%by_target = map { $_->{target} => $_ } @{tabs ()};
ok $by_target{other}{last_allowed} && !$by_target{other}{marked}
   && !$by_target{selector}{last_allowed} && $by_target{selector}{marked},
   "marking another tab does not change last allowed";
send_ws $selector, ["allowed"];
send_ws $selector, ["mark", JSON::XS::false];
is_deeply read_ws ($selector)->[1], ["marked", JSON::XS::false], "unmark confirmation synchronizes allow event";
is_deeply read_ws ($fresh)->[1], ["marked", JSON::XS::false], "other tab receives unmark notification";
%by_target = map { $_->{target} => $_ } @{tabs ()};
ok !$by_target{other}{last_allowed} && $by_target{selector}{last_allowed},
   "a later Allow event replaces the previously last allowed tab";
send_ws $selector, ["quit"];
is read_ws ($selector)->[0], 8, "marked and most recently allowed tab can retire";
is_deeply [map { [$_->{last_allowed}, $_->{marked}] } @{tabs ()}],
   [[JSON::XS::false, JSON::XS::false]], "retiring a tab clears its selection and mark";
close $selector->{socket};
send_ws $fresh, ["quit"];
is read_ws ($fresh)->[0], 8, "newly enabled tab may be disabled again";
close $fresh->{socket};

close $in;
waitpid $pid, 0;
$pid = undef;
my $errors = do { local $/; <$err> };
like $errors, qr/Browser WebSocket rejected: invalid token/,
   "rejected browser token has a specific warning without exposing the token";
like $errors, qr/Browser WebSocket rejected: invalid target/,
   "invalid browser target has a specific warning";
unlike $errors, qr/handshake response was undef|warn main:\s*\n/,
   "expected handshake rejections do not produce exception traces or empty warnings";
like $errors, qr/tab: session started \("https:\/\/page\.example\/"\)/,
   "new browser tab session is operationally logged";
like $errors, qr/other: connected \(revision 1\)/,
   "reconnecting a browser document is operationally logged";
like $errors, qr/tab: disconnected \(Page disconnected\)/,
   "browser tab disconnect is operationally logged";
like $errors, qr/other: session finished \(disabled\)/,
   "browser tab session shutdown is operationally logged";
like $errors, qr/webbrowser tabs/, "page listing is debug-logged";
like $errors, qr/webbrowser execute "tab" "https:\/\/page\.example\/next" "Promise\.resolve \(42\)"/,
   "browser debug log shows tab, abbreviated URL and short code";
like $errors, qr/webbrowser navigate "tab" "https:\/\/page\.example\/" "history\.pushState/,
   "browser debug logs navigation tool use";
unlike $errors, qr/not-for-logs|fragment/,
   "browser debug log strips URL query and fragment";
like $errors, qr/webbrowser execute tab #\d+: "Promise\.resolve \(42\)"/,
   "ordinary JavaScript is trace-logged after permission approval";
like $errors, qr/webbrowser navigate tab #\d+: "history\.pushState/,
   "navigation JavaScript is trace-logged when proceed is sent";
unlike $errors, qr/webbrowser execute tab #\d+: "denied"/,
   "denied JavaScript is never logged as executed";
unlike $errors, qr/EV: error|uninitialized|already finished|Can't call/, "normal lifecycle produces no callback errors";

done_testing;
