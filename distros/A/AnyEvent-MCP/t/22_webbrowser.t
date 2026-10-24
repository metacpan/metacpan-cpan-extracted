use common::sense;
use Test::More;
use JSON::XS ();
use IO::Socket::INET ();
use IO::Select ();
use IPC::Open3 ();
use Protocol::WebSocket::Frame ();
use File::Temp ();
use File::Path ();
use Symbol ();
use Time::HiRes ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
local $ENV{XDG_CONFIG_HOME} = "$dir/config";
File::Path::mkpath ("$dir/config/anyevent-mcp/rules", 0, 0700);
my $policy = "$dir/config/anyevent-mcp/rules/webbrowser-default.ini";

sub policy {
   my ($decision) = @_;
   open my $fh, ">", $policy or die $!;
   chmod 0600, $policy or die $!;
   print {$fh} "[rule]\ndecision=allow\naction=read\nsandbox-grants=\n\n"
      . "[rule]\ndecision=$decision\naction=exec\nsandbox-grants=\n";
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
   "--token", "primary", "--token", "secondary");
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
   ["add-element", "execute", "meta-instructions", "tabs"], "browser toolset includes instructions";
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
   send_ws $peer, ["mcp-webbrowser", 1, 0, $instance, { url => "https://page.example/", title => "Page" }];
   my $welcome = read_ws ($peer)->[1];
   ($peer, $welcome)
}

my ($bad, $header) = upgrade "wrong", "bad";
unlike $header, qr/101/, "bad token cannot upgrade";
close $bad->{socket};
my ($early) = upgrade "primary", "early";
send_ws $early, ["state", { url => "https://page.example/", title => "early" }];
my $closed = read_ws $early;
is $closed->[0], 8, "commands before hello close the connection";
is unpack ("n", $closed->[1]), 1002, "protocol rejection uses status 1002";
close $early->{socket};

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

send_ws $one, ["state", { url => "https://page.example/next?secret=not-for-logs#fragment", title => "Updated" }];
for (1 .. 100) {
   $registered = tabs;
   last if $registered->[0]{title} eq "Updated";
   Time::HiRes::sleep (.01);
}
is $registered->[1]{title}, "Updated", "state updates replace reported metadata";
is $registered->[1]{revision}, 1, "tabs expose the document revision";
like JSON::XS::encode_json ({revision => $registered->[1]{revision}}),
   qr/"revision":1/, "tabs serializes document revision as a JSON number";

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

ok tool ("execute", { target => "tab", instance_id => "old", code => "1" })->{result}{isError},
   "optional instance guard rejects a replaced document";
policy "deny";
ok tool ("execute", { target => "tab", code => "denied" })->{result}{isError}, "permission denial prevents dispatch";
ok tool ("add-element", { target => "tab", tag => "style" })->{result}{isError},
   "add_element requires the same exec permission";
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
   url => "https://page.example/spa", title => "SPA"},
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
   url => "https://page.example/", title => "Page"},
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

send_ws $again, ["quit"];
is read_ws ($again)->[0], 8, "explicit tab disable closes browser connection";
is_deeply tabs (), [], "disabled tab is no longer listed";
close $again->{socket};
my ($fresh, $new_session) = connect_page "other", "document-three";
is $new_session->[3], 1, "explicit disable ends session; next opt-in starts revision 1";
send_ws $fresh, ["quit"];
is read_ws ($fresh)->[0], 8, "newly enabled tab may be disabled again";
close $fresh->{socket};

close $in;
waitpid $pid, 0;
$pid = undef;
my $errors = do { local $/; <$err> };
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
