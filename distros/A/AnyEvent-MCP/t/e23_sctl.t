use common::sense;
use Test::More;
BEGIN {
   plan skip_all => "extended sctl bridge test (PERL_ANYEVENT_MCP_TESTS=1)"
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
}
BEGIN {
   eval {
      require Protocol::WebSocket::Frame;
      require Crypt::AuthEnc::GCM;
      require AnyEvent::WebSocket::Server;
      require AnyEvent::WebSocket::Message;
      1
   } or plan skip_all => "WebSocket/CryptX modules not installed";
}

use JSON::XS ();
use Digest::SHA qw(hmac_sha256 hmac_sha256_hex);
use MIME::Base64 ();
use IO::Socket::INET ();
use IO::Select ();
use IPC::Open3 ();
use File::Temp ();
use File::Path ();
use Symbol ();
use Time::HiRes ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
local $ENV{XDG_CONFIG_HOME} = "$dir/config";
local $ENV{XDG_CACHE_HOME} = "$dir/cache";
File::Path::mkpath ("$dir/cache/anyevent-mcp", 0, 0700);
open my $schema, ">", "$dir/cache/anyevent-mcp/sctl-protocol.json" or die $!;
print {$schema} JSON::XS::encode_json ({
   methods => {
      "scripts.list" => { peer => "scriptcat", params => "Params", result => "Results", effect => "read", level => "L0" },
      "debugger.send" => { peer => "browser", params => "Params", result => "Results", effect => "read", level => "L0" },
   },
   types => { Params => { type => "object", properties => {} }, Results => { type => "object" } },
   schemaVersion => "1.0.0",
});
close $schema;

my $reserve = IO::Socket::INET->new (
   LocalAddr => "127.0.0.1", LocalPort => 0, Proto => "tcp", Listen => 1,
) or die $!;
my $port = $reserve->sockport;
close $reserve;
my $err = Symbol::gensym;
local $ENV{PERL_ANYEVENT_LOG} = "";
local $ENV{PERL_ANYEVENT_VERBOSE} = 0;
my $pid = IPC::Open3::open3 (my $in, my $out, $err,
   $^X, "-Ilib", "bin/mcp-sctl", "--stdio", "--bind", "127.0.0.1:$port", "--token", "secret",
   "--auto-allow", "*", "--ask", "none");
$in->autoflush (1);
my ($buffer, $serial) = ("", 0);

END {
   if ($pid) {
      kill TERM => $pid;
      waitpid $pid, 0;
   }
}

sub send_rpc {
   my ($id, $method, $params) = @_;
   print {$in} JSON::XS::encode_json ({
      jsonrpc => "2.0", id => $id, method => $method, params => $params,
   }), "\n" or die $!;
}

sub read_rpc {
   my ($id) = @_;
   my $until = Time::HiRes::time () + 8;
   while (Time::HiRes::time () < $until) {
      while ($buffer =~ s/\A([^\n]*)\n//) {
         my $reply = JSON::XS::decode_json $1;
         return $reply if $reply->{id} == $id;
      }
      next unless IO::Select->new ($out)->can_read (.1);
      my $n = sysread $out, my $bytes, 8192;
      $n or die "MCP server exited\n";
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
   rpc ("tools/call", { name => $_[0], arguments => $_[1] || {} });
}

sub tcp {
   IO::Socket::INET->new (PeerAddr => "127.0.0.1", PeerPort => $port, Proto => "tcp", Timeout => 1)
}

my $ready;
for (1 .. 200) {
   $ready = tcp;
   last if $ready;
   Time::HiRes::sleep (.02);
}
ok $ready, "sctl listener runs beside MCP stdio";
close $ready if $ready;

my $init = rpc ("initialize", {
   protocolVersion => "2025-11-25", capabilities => {},
   clientInfo => { name => "test", version => "0" },
});
is $init->{result}{serverInfo}{name}, "mcp-sctl", "MCP server identity";
my $tools = rpc ("tools/list", {})->{result}{tools};
ok +(grep $_->{name} eq "call", @$tools), "opaque call tool available";

{
   local $ENV{PERL_ANYEVENT_VERBOSE} = 0;
   my $url_err = Symbol::gensym;
   my $url_pid = IPC::Open3::open3 (my $url_in, my $url_out, $url_err,
      $^X, "-Ilib", "bin/mcp-sctl", "--bind", "127.0.0.1:$port",
      "--token", "secret", "--print-url");
   close $url_in;
   local $/;
   my $printed = <$url_out>;
   my $diagnostics = <$url_err>;
   waitpid $url_pid, 0;
   is $? >> 8, 0, "sctl URL discovery exits without binding a second listener";
   is $printed, "http://127.0.0.1:$port/secret/\nws://127.0.0.1:$port/  # ScriptCat / sctl Browser\n",
      "print-url shows normal MCP URL and direct extension WebSocket URL";
   is $diagnostics, "", "URL discovery prints no diagnostics";

   $url_pid = IPC::Open3::open3 ($url_in, $url_out, $url_err,
      $^X, "-Ilib", "bin/mcp-sctl", "--token", "secret", "--print-urls");
   close $url_in;
   $printed = <$url_out>;
   $diagnostics = <$url_err>;
   waitpid $url_pid, 0;
   is $? >> 8, 0, "default sctl URL discovery succeeds";
   is $printed, "http://127.0.0.1:8643/secret/\nws://127.0.0.1:8643/  # ScriptCat / sctl Browser\n",
      "sctl defaults to port 8643 while explicit --bind can override it";
   is $diagnostics // "", "", "default URL discovery has no diagnostics";

   $url_pid = IPC::Open3::open3 ($url_in, $url_out, $url_err,
      $^X, "-Ilib", "bin/mcp-sctl", "--bind", "::", "--token", "secret", "--print-urls");
   close $url_in;
   $printed = <$url_out>;
   $diagnostics = <$url_err>;
   waitpid $url_pid, 0;
   is $? >> 8, 0, "IPv6 wildcard host-only bind URL discovery succeeds";
   like $printed, qr{\Ahttp://[^/]+:8643/secret/\nws://[^/]+:8643/  \# ScriptCat / sctl Browser\n\z},
      "--bind :: retains sctl default port 8643";
   is $diagnostics // "", "", "IPv6 wildcard URL discovery has no diagnostics";
}

my $http_socket = tcp () or die $!;
$http_socket->autoflush (1);
my $http_body = JSON::XS::encode_json ({
   jsonrpc => "2.0", id => 1, method => "initialize",
   params => {
      protocolVersion => "2025-11-25", capabilities => {},
      clientInfo => { name => "http-test", version => "0" },
   },
});
print {$http_socket} "POST /secret/ HTTP/1.1\r\nHost: 127.0.0.1:$port\r\n",
   "Content-Type: application/json\r\nAccept: application/json, text/event-stream\r\n",
   "Connection: close\r\nContent-Length: ", length ($http_body), "\r\n\r\n", $http_body;
my $http_reply = "";
my $http_deadline = Time::HiRes::time () + 5;
while (Time::HiRes::time () < $http_deadline && $http_reply !~ /"mcp-sctl"/) {
   next unless IO::Select->new ($http_socket)->can_read (.1);
   my $size = sysread $http_socket, my $part, 8192;
   last unless $size;
   $http_reply .= $part;
}
like $http_reply, qr{\AHTTP/1\.[01] 200\b}, "same port accepts authenticated MCP HTTP POST";
like $http_reply, qr/"mcp-sctl"/, "shared listener dispatches HTTP to MCP server";
close $http_socket;

sub upgrade {
   my $sock = tcp or die $!;
   $sock->autoflush (1);
   print {$sock} "GET / HTTP/1.1\r\nHost: 127.0.0.1:$port\r\n",
      "Upgrade: websocket\r\nConnection: Upgrade\r\n",
      "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n",
      "Sec-WebSocket-Version: 13\r\nOrigin: chrome-extension://test\r\n\r\n";
   my $headers = "";
   while ($headers !~ /\r\n\r\n/) {
      IO::Select->new ($sock)->can_read (3) or die "WebSocket handshake timed out\n";
      sysread ($sock, my $bytes, 8192) or do { my $detail = ""; if (IO::Select->new ($err)->can_read (.5)) { sysread $err, $detail, 8192 }; die "WebSocket EOF while upgrading: $detail\n" };
      $headers .= $bytes;
   }
   my ($header, $tail) = split /\r\n\r\n/, $headers, 2;
   $header =~ /101/ or die "WebSocket refused: $header\n";
   my $parser = Protocol::WebSocket::Frame->new;
   $parser->append ($tail) if length $tail;
   +{ sock => $sock, parser => $parser }
}

sub ws_send {
   my ($peer, $message) = @_;
   print {$peer->{sock}} Protocol::WebSocket::Frame->new (
      type => "text", masked => 1, buffer => JSON::XS::encode_json ($message),
   )->to_bytes or die $!;
}

sub ws_recv {
   my ($peer) = @_;
   my $until = Time::HiRes::time () + 5;
   while (Time::HiRes::time () < $until) {
      while (defined (my $bytes = $peer->{parser}->next_bytes)) {
         return JSON::XS::decode_json ($bytes) if $peer->{parser}->opcode == 1;
         die "Unexpected close frame\n" if $peer->{parser}->opcode == 8;
      }
      next unless IO::Select->new ($peer->{sock})->can_read (.1);
      sysread ($peer->{sock}, my $bytes, 8192) or die "Unexpected WebSocket EOF\n";
      $peer->{parser}->append ($bytes);
   }
   die "WebSocket reply timed out\n";
}

sub hkdf {
   my ($code, $info) = @_;
   my $prk = hmac_sha256 ($code, "scriptcat-rpc-v1/pair-salt");
   hmac_sha256 ($info . "\1", $prk)
}

sub pair_peer {
   my ($kind, $id, $name) = @_;
   my $pair = tool ("pair")-> {result}{structuredContent}{code};
   ok $pair, "pairing code received";
   $pair =~ s/-//g;
   my $peer = upgrade ();
   my $challenge = ws_recv ($peer);
   is $challenge->{method}, '$session.authenticate', "server challenges extension";

   my $nonceD = $challenge->{params}{nonceD};
   my $nonceE = "ab" x 32;
   my $prefix = $kind eq "browser" ? "sctl-browser-rpc-v1/" : "scriptcat-rpc-v1/";
   my $extctx = $kind eq "browser" ? "ext" : "instance-pair-ext";
   my $daemonctx = $kind eq "browser" ? "pair-daemon" : "instance-pair-daemon";
   $extctx = "pair-ext" if $kind eq "browser";
   my $mac = hkdf ($pair, "scriptcat-rpc-v1/pair-mac");
   ws_send $peer, {
      jsonrpc => "2.0", id => $challenge->{id},
      result => {
         mode => "pairing", nonceE => $nonceE,
         hmac => hmac_sha256_hex ($prefix . $extctx . $id . $nonceD . $nonceE, $mac),
         peer => { kind => $kind, instanceId => $id },
      }
   };
   my $authenticated = ws_recv ($peer);
   is $authenticated->{method}, '$session.authenticated', "mutual authentication response";
   is $authenticated->{params}{hmac},
      hmac_sha256_hex ($prefix . $daemonctx . $id . $nonceE . $nonceD, $mac),
      "daemon HMAC matches protocol";
   my $iv = MIME::Base64::decode_base64 ($authenticated->{params}{key}{iv});
   my $sealed = MIME::Base64::decode_base64 ($authenticated->{params}{key}{ciphertext});
   my $enc = hkdf ($pair, "scriptcat-rpc-v1/pair-enc");
   my ($ciphertext, $tag) = (substr ($sealed, 0, -16), substr ($sealed, -16));
   my $key = Crypt::AuthEnc::GCM::gcm_decrypt_verify ("AES", $enc, $iv, "", $ciphertext, $tag);
   is length $key, 32, "enrolled key decrypts with correct GCM tag";
   is ws_recv ($peer)->{method}, '$session.hello', "server sends hello";
   my $methods = $kind eq "scriptcat" ? ["scripts.list"] : ["debugger.send"];
   ws_send $peer, {
      jsonrpc => "2.0", id => "caps-$id", method => '$session.capabilities',
      params => {
         schemaVersion => "1.0.0", methods => $methods,
         peer => { name => $name, extensionVersion => "test" },
      }
   };
   is ws_recv ($peer)->{id}, "caps-$id", "capabilities acknowledged";
   my $keyfile = "$dir/config/anyevent-mcp/sctl-default-keys.json";
   open my $keyfh, "<", $keyfile or die "$keyfile: $!";
   local $/;
   my $stored = JSON::XS::decode_json (<$keyfh>);
   my $keyhex = $stored->{"$kind:$id"}{key};
   my ($expected_ct, $expected_tag) = Crypt::AuthEnc::GCM::gcm_encrypt_authenticate (
      "AES", $enc, $iv, "", pack ("H*", $keyhex));
   is unpack ("H*", $sealed), unpack ("H*", $expected_ct . $expected_tag),
      "external encryption matches persisted key";
   ($peer, $key)
}

my ($scriptcat, $key) = pair_peer ("scriptcat", "11" x 16, "scriptcat-test");
my $list = tool ("list")-> {result}{structuredContent}{instances};
is @$list, 1, "ScriptCat registered";
is $list->[0]{name}, "scriptcat-test", "ScriptCat name";

my $matches = tool ("search", { query => "scripts.list", details => JSON::XS::true })
   ->{result}{structuredContent}{matches};
is @$matches, 1, "search uses actual advertised method list";
is $matches->[0]{params}{type}, "object", "search augments with cached schema";

my $call_id = ++$serial;
send_rpc $call_id, "tools/call", {
   name => "call", arguments => { instance => "scriptcat-test", method => "scripts.list", input => {} },
};
my $command = ws_recv ($scriptcat);
is $command->{method}, "scripts.list", "opaque call forwarded to ScriptCat";
is_deeply $command->{params}{input}, {}, "business input stays under params.input";
ws_send $scriptcat, { jsonrpc => "2.0", id => $command->{id}, result => { scripts => [] } };
is_deeply read_rpc ($call_id)->{result}{structuredContent}{result}, { scripts => [] },
   "business result forwarded to MCP";

my ($browser) = pair_peer ("browser", "22" x 16, "chrome-test");
$list = tool ("list")-> {result}{structuredContent}{instances};
is @$list, 2, "browser and ScriptCat remain connected together";

$call_id = ++$serial;
send_rpc $call_id, "tools/call", {
   name => "call", arguments => {
      instance => "chrome-test", method => "debugger.send", input => {
         tabId => 7, method => "Runtime.evaluate", params => { expression => "2+2" }
      }
   },
};
$command = ws_recv ($browser);
is $command->{method}, "debugger.send", "CDP forwarded as opaque debugger.send RPC";
is $command->{params}{input}{params}{expression}, "2+2", "CDP parameters preserved";
ws_send $browser, { jsonrpc => "2.0", id => $command->{id}, result => { result => { value => 4 } } };
is read_rpc ($call_id)->{result}{structuredContent}{result}{result}{value}, 4,
   "CDP result forwarded unchanged";

my $again = upgrade ();
my $challenge = ws_recv ($again);
my $nonceD = $challenge->{params}{nonceD};
my $nonceE = "cd" x 32;
my $instance_id = "11" x 16;
ws_send $again, {
   jsonrpc => "2.0", id => $challenge->{id},
   result => {
      mode => "session", nonceE => $nonceE,
      hmac => hmac_sha256_hex ("scriptcat-rpc-v1/instance-ext" . $instance_id . $nonceD . $nonceE, $key),
      peer => { kind => "scriptcat", instanceId => $instance_id },
   },
};
my $authenticated = ws_recv ($again);
is $authenticated->{method}, '$session.authenticated', "existing shared key authenticates reconnect";
is $authenticated->{params}{hmac},
   hmac_sha256_hex ("scriptcat-rpc-v1/instance-daemon" . $instance_id . $nonceE . $nonceD, $key),
   "reconnect mutually authenticates the daemon";
ok !exists $authenticated->{params}{key}, "session does not deliver another key";
is ws_recv ($again)->{method}, '$session.hello', "reconnected client receives hello";
ws_send $again, {
   jsonrpc => "2.0", id => "rejoin", method => '$session.capabilities',
   params => {
      schemaVersion => "1.0.0", methods => ["scripts.list"],
      peer => { name => "scriptcat-test", extensionVersion => "test" },
   }
};
is ws_recv ($again)->{id}, "rejoin", "reconnected instance replaces old connection";
$list = tool ("list")-> {result}{structuredContent}{instances};
is @$list, 2, "reconnection preserves separate browser and ScriptCat peers";

my $logs = "";
while (IO::Select->new ($err)->can_read (.05)) {
   my $n = sysread $err, my $chunk, 8192;
   last unless $n;
   $logs .= $chunk;
}
like $logs, qr/pairing window opened \(120s, 3 attempts\)/, "pairing activity logged without code";
like $logs, qr/listening on 127\.0\.0\.1:\d+ \(MCP HTTP \+ sctl WebSocket\)/, "startup log identifies listening endpoint";
like $logs, qr/list: 2 connected instances/, "instance discovery logs result count";
like $logs, qr/search: 1 matching methods/, "method discovery logs result count";
like $logs, qr/"scriptcat-test"#11111111: paired and connected \(1 methods\)/,
   "connection log identifies the named extension with abbreviated instance ID";
like $logs, qr/call .*method="scripts.list"/, "generic MCP call log includes forwarded method";
like $logs, qr/"scriptcat-test"#11111111: scripts.list scripts=0 \([0-9.]+s\)/,
   "successful call logs script count and elapsed time";
like $logs, qr/call .*method="debugger.send"/, "CDP operation method appears in activity log";
unlike $logs, qr/2\+2/, "arbitrary CDP expression stays out of operator log";

done_testing;
