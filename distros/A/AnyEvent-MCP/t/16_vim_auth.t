use common::sense;
use Test::More;
use JSON::XS ();
use IO::Socket::INET ();
use IO::Select ();
use Protocol::WebSocket::Frame ();
use IPC::Open3 ();
use POSIX qw(WNOHANG);
use Time::HiRes ();
use File::Temp ();
use File::Path ();
use Symbol ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
File::Path::mkpath (["$dir/home", "$dir/config"], 0, 0700);
local $ENV{HOME} = "$dir/home";
local $ENV{XDG_CONFIG_HOME} = "$dir/config";

my $policy = "$dir/config/anyevent-mcp/rules/vim-default.ini";
File::Path::mkpath (["$dir/config/anyevent-mcp/rules"], 0, 0700);

sub permission_rules {
   open my $fh, ">", $policy or die "$policy: $!";
   chmod 0600, $policy or die "$policy: $!";
   print {$fh} join "", map {
      my ($decision, $action, $subject) = @$_;
      "[rule]\ndecision=$decision\naction=$action\n"
         . (defined $subject ? "subject=$subject\n" : "")
         . ($decision eq "allow" ? "sandbox-grants=\n" : "") . "\n"
   } @_;
   close $fh or die "$policy: $!";
}

permission_rules (["allow", "read"], ["allow", "write"]);

my $listener = IO::Socket::INET->new (
   LocalAddr => "127.0.0.1", LocalPort => 0, Proto => "tcp", Listen => 1,
) or die "allocate TCP test port: $!";
my $port = $listener->sockport;
close $listener;

my $err = Symbol::gensym;
local $ENV{PERL_ANYEVENT_LOG} = ""; # capture the broker's full activity log.
local $ENV{PERL_ANYEVENT_VERBOSE} = 6; # include notice-level rejection logs
my $pid = IPC::Open3::open3 (my $in, my $out, $err, $^X, "-Ilib",
   "-e", 'unshift @INC, sub { die "Coro must not be loaded\\n" if $_[1] =~ m{^Coro(?:/|\\.pm)}; return }; do shift @ARGV; die $@ if $@;',
   "./bin/mcp-vim", "--name", "default", "--stdio", "--bind", "127.0.0.1:$port",
   "--token", "primary", "--token", "secondary", "--ask", "mcp");
my $old = select $in;
$| = 1;
select $old;

sub tcp {
   IO::Socket::INET->new (
      PeerAddr => "127.0.0.1", PeerPort => $port,
      Proto => "tcp", Timeout => 1,
   )
}

my $ready;
for (1 .. 1000) {
   $ready = tcp ();
   last if $ready;
   Time::HiRes::sleep (0.03);
}
ok $ready, "mcp-vim listens on TCP with two static tokens";
# leave this connection silent while the other protocols are exercised.

sub rpc {
   my ($id, $method, $params) = @_;
   print {$in} JSON::XS::encode_json ({
      jsonrpc => "2.0", id => $id, method => $method, params => $params,
   }), "\n" or die "send JSONL request: $!";
   IO::Select->new ($out)->can_read (30) or die "MCP stdio response timed out";
   my $line = <$out> // die "unexpected MCP stdio EOF";
   JSON::XS::decode_json $line
}

sub target_names {
   my $r = rpc (++$main::request_id, "tools/call",
      { name => "targets", arguments => {} });
   return [] unless $r->{result}{content}[0]{text};
   JSON::XS::decode_json $r->{result}{content}[0]{text}
}

sub vim_connect {
   my ($token, $target) = @_;
   my $sock = tcp () or die "connect private Vim TCP: $!";
   my $hello = JSON::XS::encode_json ([
      "mcp-vim", $token, 1, 0, $target, "test-$target",
   ]) . "\n";
   print {$sock} $hello or die "send private Vim hello: $!";
   $sock
}

sub upgrade {
   my ($token, $path) = @_;
   my $sock = tcp () or die "connect browser WS TCP: $!";
   $sock->autoflush (1);
   $path //= "/$token/http://page.example:818";
   my $req = "GET $path HTTP/1.1\r\n"
      . "Host: 127.0.0.1:$port\r\n"
      . "Upgrade: websocket\r\nConnection: Upgrade\r\n"
      . "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
      . "Sec-WebSocket-Version: 13\r\n"
      . "Origin: http://page.example:818\r\n\r\n";
   print {$sock} $req or die "send WebSocket upgrade: $!";

   my $bytes = "";
   my $deadline = Time::HiRes::time () + 2;
   while ($bytes !~ /\r\n\r\n/ && Time::HiRes::time () < $deadline) {
      last unless IO::Select->new ($sock)->can_read (0.2);
      my $n = sysread $sock, my $chunk, 4096;
      last unless $n;
      $bytes .= $chunk;
   }

   my ($headers, $frames) = split /\r\n\r\n/, $bytes, 2;
   ($sock, $headers // "", $frames // "")
}

sub ws_close_code {
   my ($sock, $initial) = @_;
   my $frame = Protocol::WebSocket::Frame->new;
   $frame->append ($initial) if length $initial;
   my $deadline = Time::HiRes::time () + 3;
   while (Time::HiRes::time () < $deadline) {
      while (defined (my $payload = $frame->next_bytes)) {
         return unpack ("n", $payload) if $frame->opcode == 8 && length ($payload) >= 2;
      }
      next unless IO::Select->new ($sock)->can_read (0.2);
      my $n = sysread $sock, my $bytes, 8192;
      last unless $n;
      $frame->append ($bytes);
   }
   undef
}

my $init = rpc (1, "initialize", {
   protocolVersion => "2025-11-25", capabilities => {},
   clientInfo => { name => "auth-test", version => "0" },
});
ok !$init->{error} && $init->{result}{serverInfo},
   "stdio control channel initializes while a TCP peer sends no first byte";
is $init->{result}{serverInfo}{name}, "mcp-vim", "stdio reports mcp-vim as its identity";
like $init->{result}{instructions}, qr/Live Vim buffers/,
   "stdio gives MCP clients live-buffer guidance";
unlike JSON::XS::encode_json ($init->{result}), qr/xpcse/i,
   "stdio initialization does not expose the legacy browser name";

my $discover = rpc (2, "server/discover", {});
is $discover->{result}{instructions}, $init->{result}{instructions},
   "discovery gives the same Vim instructions as initialize";

{
   my $http = tcp () or die "connect MCP HTTP: $!";
   my $body = JSON::XS::encode_json ({
      jsonrpc => "2.0", id => 3, method => "initialize",
      params => {
         protocolVersion => "2025-11-25", capabilities => {},
         clientInfo => { name => "auth-test", version => "0" },
      },
   });
   print {$http} "POST / HTTP/1.1\r\n",
      "Host: 127.0.0.1:$port\r\n",
      "Authorization: Bearer primary\r\n",
      "Content-Type: application/json\r\n",
      "Content-Length: ", length $body, "\r\n\r\n", $body
      or die "send MCP HTTP request: $!";
   local $/;
   my $response = <$http> // "";
   close $http;
   my ($headers, $json) = split /\r\n\r\n/, $response, 2;
   like $headers, qr{\AHTTP/1\.1 200\b}, "HTTP initialization succeeds";
   my $result = eval { JSON::XS::decode_json $json };
   is $result->{result}{serverInfo}{name}, "mcp-vim", "HTTP reports mcp-vim as its identity";
   is $result->{result}{instructions}, $init->{result}{instructions},
      "HTTP gives the same Vim instructions as stdio";
}

my $empty_state = rpc (4, "tools/call", { name => "state", arguments => {} });
is_deeply JSON::XS::decode_json ($empty_state->{result}{content}[0]{text}), {},
   "state with no connected editors completes immediately with an empty object";

my $bad = vim_connect ("unknown", "bad-vim");
my $before = target_names ();
ok !grep ($_ eq "bad-vim", @$before), "unknown private Vim token cannot register a target";
close $bad;

my $valid = vim_connect ("secondary", "secondary-vim");
my $visible;
for (1 .. 1000) {
   my $names = target_names ();
   $visible = grep $_ eq "secondary-vim", @$names;
   last if $visible;
   Time::HiRes::sleep (0.03);
}
ok $visible, "secondary token authenticates private Vim handshake";

# A private Vim RPC supplying disjoint ranges must yield a separate
# [range=...] metadata text entry and an unchanged lines text entry for each.
print {$in} JSON::XS::encode_json ({
   jsonrpc => "2.0", id => 180, method => "tools/call",
   params => { name => "read-lines", arguments => {
      target => "secondary-vim", buffer => 1, ranges => ["727,728", "985,986"],
   } },
}), "\n" or die "send Vim read-lines request: $!";

my $wire = "";
my $vim_call;
for (1 .. 100) {
   IO::Select->new ($valid)->can_read (0.3)
      or next;
   my $n = sysread $valid, my $fragment, 8192;
   last unless $n;
   $wire .= $fragment;
   $vim_call = eval { JSON::XS::decode_json $wire };
   last if $vim_call;
}
ok $vim_call && $vim_call->[1][0] eq "call"
   && $vim_call->[1][2] eq "read_lines",
   "read-lines delegates disjoint ranges to the private Vim RPC";
if ($vim_call) {
   $valid->autoflush (1);
   print {$valid} JSON::XS::encode_json ([0, [
      reply => $vim_call->[1][1], 1, {
         changedtick => 7,
         ranges => [
            { range => "727,728", start => 727, end => 728, lines => ["function alpha () {", "   return a;"] },
            { range => "985,986", start => 985, end => 986, lines => ["function beta () {", "   return b;"] },
         ],
      },
   ]]) or die "send mock Vim RPC reply: $!";
}
IO::Select->new ($out)->can_read (30) or die "read-lines MCP reply timeout";
my $lines_reply = JSON::XS::decode_json (scalar <$out>);
my $blocks = $lines_reply->{result}{content} || [];
is @{$blocks}, 5, "Vim returns initial metadata plus two text entries per requested range";
is_deeply [map $_->{type}, @$blocks], [("text") x 5],
   "all Vim metadata and source blocks remain MCP text entries";
is_deeply JSON::XS::decode_json ($blocks->[0]{text}), {
   changedtick => 7,
   ranges => [
      { range => "727,728", start => 727, end => 728 },
      { range => "985,986", start => 985, end => 986 },
   ],
}, "Vim changedtick and resolved range metadata remain available";
is_deeply [map $_->{text}, @{$blocks}[1..4]], [
   "[range=727,728]",
   "function alpha () {\n   return a;\n",
   "[range=985,986]",
   "function beta () {\n   return b;\n",
], "each Vim range has visible standalone metadata and unchanged newline-terminated source";


sub send_tool {
   my ($id, $name, $args) = @_;
   print {$in} JSON::XS::encode_json ({
      jsonrpc => "2.0", id => $id, method => "tools/call",
      params => { name => $name, arguments => $args },
   }), "\n" or die "send tool request: $!";
}

my %vim_parser;

sub vim_call {
   my $socket = $_[0] || $valid;
   my $parser = $vim_parser{fileno $socket} ||= JSON::XS->new->utf8;
   for (1 .. 120) {
      my $packet = $parser->incr_parse;
      return $packet if $packet;
      next unless IO::Select->new ($socket)->can_read (0.25);
      my $n = sysread $socket, my $fragment, 8192;
      last unless $n;
      $parser->incr_parse ($fragment); # void context: leave complete packets for the next iteration
   }
   die "private Vim message timeout\n";
}

sub vim_reply {
   my ($call, $success, $result, $socket) = @_;
   $socket ||= $valid;
   print {$socket} JSON::XS::encode_json ([0, [
      reply => $call->[1][1], $success, $result,
   ]]) or die "send Vim RPC reply: $!";
}

sub mcp_reply {
   IO::Select->new ($out)->can_read (30) or die "MCP reply timeout\n";
   JSON::XS::decode_json (scalar <$out>)
}

send_tool 184, "read-lines", {
   target => "secondary-vim", buffer => 1, ranges => ["40,41", "8"], linenums => JSON::XS::true,
};
my $numbered_call = vim_call;
vim_reply $numbered_call, 1, {
   changedtick => 7,
   ranges => [
      { range => "40,41", start => 40, end => 41, lines => ["", "second"] },
      { range => "8", start => 8, end => 8, lines => ["first"] },
   ],
};
my $numbered_reply = mcp_reply;
is_deeply [map $_->{text}, @{$numbered_reply->{result}{content}}[1..4]], [
   "[range=40,41]", "40:\n41:second\n", "[range=8,8]", "8:first\n",
], "Vim linenums prefixes absolute numbers for disjoint ranges and empty lines";

my $other = vim_connect ("secondary", "parallel-vim");
$other->autoflush (1);
my $other_visible;
for (1 .. 1000) {
   $other_visible = grep $_ eq "parallel-vim", @{target_names ()};
   last if $other_visible;
   Time::HiRes::sleep (0.03);
}
ok $other_visible, "second mock editor connected for parallel state collection";

sub permission_params {
   my ($name, $args, $state, $answer) = @_;
   +{
      name => $name, arguments => $args,
      _meta => {
         "io.modelcontextprotocol/protocolVersion" => "2026-07-28",
         "io.modelcontextprotocol/clientCapabilities" => { elicitation => { form => {} } },
      },
      (defined $state ? (
         requestState => $state, inputResponses => { permission => $answer },
      ) : ()),
   }
}

# a saved grant for one editor must not authorize another, or start a partial fan-out.
permission_rules (["allow", "read", "targets"], ["allow", "read", "target:secondary-vim"]);
my $challenge = rpc (800, "tools/call", permission_params ("state", {}));
is $challenge->{result}{resultType}, "input_required", "another editor requires its own read permission";
ok !IO::Select->new ($valid, $other)->can_read (0.1), "state starts no RPC before all editor permissions pass";
my $declined = rpc (801, "tools/call", permission_params (
   "state", {}, $challenge->{result}{requestState}, { action => "decline" },
));
ok $declined->{result}{isError}, "declining an editor permission fails the state request";
ok !IO::Select->new ($valid, $other)->can_read (0.1), "declined state sends no editor RPC";

$challenge = rpc (802, "tools/call", permission_params ("state", {}));
print {$in} JSON::XS::encode_json ({
   jsonrpc => "2.0", id => 803, method => "tools/call",
   params => permission_params ("state", {}, $challenge->{result}{requestState}, {
      action => "accept", content => { decision => "allow-once" },
   }),
}), "\n";
my $approved_first = vim_call;
my $approved_second = vim_call $other;
vim_reply $approved_first, 1, { approved => 1 };
vim_reply $approved_second, 1, { approved => 2 }, $other;
is mcp_reply ()->{id}, 803, "approved state dispatches both RPCs and completes the continuation";
$challenge = rpc (804, "tools/call", permission_params ("state", { target => "parallel-vim" }));
is $challenge->{result}{resultType}, "input_required", "one-time approval does not grant later editor reads";
rpc (805, "tools/call", permission_params (
   "state", { target => "parallel-vim" }, $challenge->{result}{requestState}, { action => "decline" },
));

permission_rules (["allow", "read"]);
my $patch_args = {
   target => "secondary-vim", buffer => 1,
   diff => "@@ -1 @@\n-old\n+new\n", expected_changedtick => 7,
};
my $nul_patch = rpc (1090, "tools/call", permission_params ("apply-diff", {
   %$patch_args, diff => "@@ -1 @@\n-a\0z\n+b\0z\n",
}));
ok $nul_patch->{result}{isError} && $nul_patch->{result}{content}[0]{text} =~ /NUL/,
   "NUL diff is rejected before permission prompting";
ok !IO::Select->new ($valid)->can_read (0.1), "NUL diff never reaches Vim's lossy JSON decoder";
my $patch_challenge = rpc (806, "tools/call", permission_params ("apply-diff", $patch_args));

is_deeply $patch_challenge->{result}{inputRequests}{permission}{params}{_meta}{"anyevent-mcp/permission"}{request}{details},
   { "View patch" => "Editor: secondary-vim\nBuffer: 1\n\n$patch_args->{diff}" },
   "Vim patch permission carries generic details with editor and buffer";
like $patch_challenge->{result}{inputRequests}{permission}{params}{message}, qr/-old\n\+new\n/,
   "native Vim permission displays the patch";
ok !IO::Select->new ($valid)->can_read (0.1), "patch preview starts no editor RPC";
rpc (807, "tools/call", permission_params (
   "apply-diff", $patch_args, $patch_challenge->{result}{requestState}, { action => "decline" },
));
ok !IO::Select->new ($valid)->can_read (0.1), "declined patch starts no editor RPC";

permission_rules (["allow", "read"], ["deny", "write"]);
for my $case (
   ["apply-diff", { target => "secondary-vim", buffer => 1, diff => "@@ -1 @@\n-old\n+new\n", expected_changedtick => 7 }],
   ["substitute", { target => "secondary-vim", buffer => 1, range => "%", pattern => "x", replacement => "y", flags => "", expected_changedtick => 7 }],
   ["undo", { target => "secondary-vim", buffer => 1, expected_changedtick => 7 }],
   ["redo", { target => "secondary-vim", buffer => 1, expected_changedtick => 7 }],
   ["set-cursor", { target => "secondary-vim", buffer => 1, line => 1, column => 1 }],
) {
   my $reply = rpc (++$main::permission_id + 810, "tools/call", { name => $case->[0], arguments => $case->[1] });
   ok $reply->{result}{isError}, "$case->[0] requires write permission despite an existing read grant";
   ok !IO::Select->new ($valid)->can_read (0.1), "$case->[0] denial precedes Vim RPC";
}
permission_rules (["deny", "read"], ["allow", "write"]);
for my $case (
   ["targets", {}],
   ["state", { target => "secondary-vim" }],
   ["read-lines", { target => "secondary-vim", buffer => 1, ranges => ["1"] }],
   ["grep", { target => "secondary-vim", buffers => [1], pattern => "x", mode => "word", max_results => 1 }],
) {
   my $reply = rpc (++$main::permission_id + 810, "tools/call", { name => $case->[0], arguments => $case->[1] });
   ok $reply->{result}{isError}, "$case->[0] requires read permission despite an existing write grant";
   ok !IO::Select->new ($valid)->can_read (0.1), "$case->[0] denial precedes Vim RPC";
}
{
   my $http = tcp () or die "connect permission HTTP test: $!";
   $http->autoflush (1);
   my $body = JSON::XS::encode_json ({
      jsonrpc => "2.0", id => 840, method => "tools/call",
      params => { name => "targets", arguments => {} },
   });
   print {$http} "POST / HTTP/1.1\r\nHost: localhost\r\n",
      "Authorization: Bearer primary\r\nContent-Type: application/json\r\n",
      "Content-Length: ", length $body, "\r\n\r\n", $body;
   IO::Select->new ($http)->can_read (30) or die "HTTP permission response timed out\n";
   local $/;
   my $wire = <$http>;
   close $http;
   my (undef, $json) = split /\r\n\r\n/, $wire, 2;
   my $reply = JSON::XS::decode_json $json;
   ok $reply->{result}{isError}, "HTTP tool calls enforce the same read denial as stdio";
}
permission_rules (["allow", "read"], ["allow", "write"]);

# read/write grants must not authorize unrestricted execution.
my $ex_args = { target => "secondary-vim", command => "echo 'hello' | echo 'world'\nlet g:example = 1" };
my $ex_challenge = rpc (850, "tools/call", permission_params ("ex", $ex_args));
is $ex_challenge->{result}{resultType}, "input_required", "read and write grants do not authorize exec";
like ($ex_challenge->{result}{inputRequests}{permission}{params}{message}, qr/\Q$ex_args->{command}\E/,
   "exec permission prompt includes the complete command");
ok !IO::Select->new ($valid)->can_read (0.1), "exec waits for permission before sending Vim a command";
my $ex_denied = rpc (851, "tools/call", permission_params (
   "ex", $ex_args, $ex_challenge->{result}{requestState}, { action => "decline" },
));
ok $ex_denied->{result}{isError}, "declining exec does not execute the command";

$ex_challenge = rpc (852, "tools/call", permission_params ("ex", $ex_args));
my $changed_ex = rpc (853, "tools/call", permission_params (
   "ex", { %$ex_args, command => "echo 'different'" }, $ex_challenge->{result}{requestState},
   { action => "accept", content => { decision => "allow-once" } },
));
ok $changed_ex->{result}{isError}, "exec continuation cannot substitute another command";
ok !IO::Select->new ($valid)->can_read (0.1), "changed exec continuation sends no Vim RPC";

$ex_challenge = rpc (854, "tools/call", permission_params ("ex", $ex_args));
print {$in} JSON::XS::encode_json ({
   jsonrpc => "2.0", id => 855, method => "tools/call",
   params => permission_params ("ex", $ex_args, $ex_challenge->{result}{requestState}, {
      action => "accept", content => { decision => "allow-once" },
   }),
}), "\n";
my $ex_call = vim_call;
is_deeply [@{$ex_call->[1]}[2, 3]], ["ex", $ex_args->{command}], "approved Ex text reaches Vim without filtering";
vim_reply $ex_call, 1, { output => "\nhello\nworld" };
my $ex_result = mcp_reply;
is_deeply JSON::XS::decode_json ($ex_result->{result}{content}[0]{text}), { output => "\nhello\nworld" },
   "exec returns the captured Vim messages";
$ex_challenge = rpc (856, "tools/call", permission_params ("ex", $ex_args));
is $ex_challenge->{result}{resultType}, "input_required", "one-time exec permission does not authorize a later call";
rpc (857, "tools/call", permission_params (
   "ex", $ex_args, $ex_challenge->{result}{requestState}, { action => "decline" },
));

$ex_challenge = rpc (861, "tools/call", permission_params ("ex", $ex_args));
my $ex_rule = rpc (862, "tools/call", permission_params (
   "ex", $ex_args, $ex_challenge->{result}{requestState},
   { action => "accept", content => { decision => "allow-always" } },
));
my $ex_scopes = $ex_rule->{result}{inputRequests}{permission}{params}{requestedSchema}{properties}{subject}{enum};
is scalar @$ex_scopes, 3, "Ex offers exact command, editor-wide and global persistent scopes";
is $ex_scopes->[0], 'ex:"secondary-vim":' . JSON::XS->new->allow_nonref->encode ($ex_args->{command}),
   "exact scope encodes the complete command including newlines";
print {$in} JSON::XS::encode_json ({
   jsonrpc => "2.0", id => 863, method => "tools/call",
   params => permission_params ("ex", $ex_args, $ex_rule->{result}{requestState}, {
      action => "accept", content => {
         decision => "allow-always", sandbox_grants => "", subject => $ex_scopes->[0],
      },
   }),
}), "\n";
$ex_call = vim_call;
vim_reply $ex_call, 1, { output => "" };
ok !mcp_reply ()->{result}{isError}, "exact-command persistent approval executes the approved call";
send_tool 864, "ex", { %$ex_args, buffer => 7, expected_changedtick => 42 };
$ex_call = vim_call;
is_deeply [@{$ex_call->[1]}[2 .. 5]], ["ex", $ex_args->{command}, 7, 42],
   "exact approval survives buffer/tick changes and forwards both guards to Vim";
vim_reply $ex_call, 0, "rpc/stale_buffer: expected 42, got 43";
ok mcp_reply ()->{result}{isError}, "stale guarded Ex execution returns a tool error";
for my $args (
   { %$ex_args, command => "$ex_args->{command} " },
   { %$ex_args, command => "echo 'different'" },
   { %$ex_args, target => "parallel-vim" },
) {
   my $id = ++$main::permission_id + 950;
   my $challenge = rpc ($id, "tools/call", permission_params ("ex", $args));
   is $challenge->{result}{resultType}, "input_required", "exact approval rejects changed command text or editor";
   rpc ($id, "tools/call", permission_params (
      "ex", $args, $challenge->{result}{requestState}, { action => "decline" },
   ));
}
my $missing_buffer = rpc (865, "tools/call", permission_params (
   "ex", { %$ex_args, expected_changedtick => 42 },
));
ok $missing_buffer->{result}{isError}, "changedtick without a buffer is rejected";
ok !IO::Select->new ($valid, $other)->can_read (0.1), "unapproved and malformed Ex calls send no Vim RPC";

permission_rules (["allow", "read"], ["allow", "write"], ["allow", "exec", "target:secondary-vim"]);
$ex_challenge = rpc (866, "tools/call", permission_params ("ex", $ex_args));
is $ex_challenge->{result}{resultType}, "input_required", "legacy literal target exec rule requires a fresh approval";
rpc (867, "tools/call", permission_params (
   "ex", $ex_args, $ex_challenge->{result}{requestState}, { action => "decline" },
));
permission_rules (["allow", "read"], ["allow", "write"], ["allow", "exec", $ex_scopes->[1]]);
send_tool 858, "ex", { target => "secondary-vim", command => "NoSuchExCommand" };
$ex_call = vim_call;
vim_reply $ex_call, 0, "Vim:E492: Not an editor command";
my $ex_error = mcp_reply;
ok $ex_error->{result}{isError} && $ex_error->{result}{content}[0]{text} =~ /E492/,
   "Vim execution failure becomes a tool error";
$ex_challenge = rpc (859, "tools/call", permission_params ("ex", { %$ex_args, target => "parallel-vim" }));
is $ex_challenge->{result}{resultType}, "input_required", "saved exec permission remains scoped to its editor";
ok !IO::Select->new ($other)->can_read (0.1), "unapproved editor receives no exec RPC";
rpc (860, "tools/call", permission_params (
   "ex", { %$ex_args, target => "parallel-vim" }, $ex_challenge->{result}{requestState}, { action => "decline" },
));
for my $command ("", [], "echo\0bad") {
   my $reply = rpc (++$main::permission_id + 900, "tools/call", {
      name => "ex", arguments => { target => "secondary-vim", command => $command },
   });
   ok $reply->{result}{isError}, "malformed Ex command is rejected before RPC";
}
ok !IO::Select->new ($valid)->can_read (0.1), "invalid commands never reach Vim";
permission_rules (["allow", "read"], ["allow", "write"]);

send_tool 181, "state", {};
my $first_state_call = vim_call;
my $second_state_call = vim_call $other;
is_deeply [$first_state_call->[1][2], $second_state_call->[1][2]], ["state", "state"],
   "state sends both editor requests before waiting for either reply";
my $first_state = { cwd => "/first", buffers => [] };
my $second_state = { cwd => "/second", buffers => [] };
vim_reply $second_state_call, 1, $second_state, $other;
vim_reply $first_state_call, 1, $first_state;
my $states = mcp_reply;
is $states->{id}, 181, "parallel state completes the original request";
is_deeply JSON::XS::decode_json ($states->{result}{content}[0]{text}), {
   "secondary-vim" => $first_state,
   "parallel-vim" => $second_state,
}, "state collects both editor replies under their target names";

send_tool 182, "state", {};
my $failed_state_call = vim_call;
my $late_state_call = vim_call $other;
vim_reply $failed_state_call, 0, "mock state error";
my $state_error = mcp_reply;
ok $state_error->{id} == 182 && $state_error->{result}{isError}
   && $state_error->{result}{content}[0]{text} =~ /mock state error/,
   "state fails without waiting for the other editor";
vim_reply $late_state_call, 1, $second_state, $other;

send_tool 183, "state", { target => "secondary-vim" };
my $selected_state_call = vim_call;
vim_reply $selected_state_call, 1, $first_state;
my $selected_state = mcp_reply;
is $selected_state->{id}, 183, "late state reply does not complete a failed request again";
is_deeply JSON::XS::decode_json ($selected_state->{result}{content}[0]{text}),
   { "secondary-vim" => $first_state }, "state can select one editor";
close $other;

permission_rules (["allow", "read"], ["allow", "write"], ["allow", "save"]);
my $tool_id = 190;
for my $case (
   ["grep", {
      target => "secondary-vim", buffers => [1], pattern => "alpha",
      mode => "word", max_results => 2,
   }, "grep", [[1], "alpha", "word", 2]],
   ["apply-diff", {
      target => "secondary-vim", buffer => 1,
      diff => "@@ -1 @@\n-old\n+new\n", expected_changedtick => 7,
   }, "apply_patch", [1, "@@ -1,1 +1,1 @@\n-old\n+new\n", [0], 7]],
   ["substitute", {
      target => "secondary-vim", buffer => 1, range => "%",
      pattern => "alpha", replacement => "beta", flags => "g",
      expected_changedtick => 7,
   }, "substitute", [1, "%", "alpha", "beta", "g", 7]],
   ["undo", {
      target => "secondary-vim", buffer => 1, expected_changedtick => 7,
   }, "undo", [1, 7]],
   ["redo", {
      target => "secondary-vim", buffer => 1, expected_changedtick => 7,
   }, "redo", [1, 7]],
   ["save", {
      target => "secondary-vim", buffer => 1, expected_changedtick => 7,
   }, "update", [1, 7]],
   ["set-cursor", {
      target => "secondary-vim", buffer => 1, line => 2, column => 3,
      expected_changedtick => 7,
   }, "set_cursor", [1, 2, 3, 7]],
   ["set-cursor", {
      target => "secondary-vim", buffer => 1, line => 2, column => 3,
   }, "set_cursor", [1, 2, 3]],
) {
   my ($name, $args, $command, $rpc_args) = @$case;
   send_tool ++$tool_id, $name, $args;
   my $call = vim_call;
   is_deeply [@{$call->[1]}[2 .. $#{$call->[1]}]], [$command, @$rpc_args],
      "$name forwards its arguments and guards through callback RPC";
   is JSON::XS::encode_json ([$call->[1][3]]), "[1]", "apply-diff keeps buffer ID numeric"
      if $name eq "apply-diff";
   my $result = { changedtick => 8, tool => $name };
   vim_reply $call, 1, $result;
   my $reply = mcp_reply;
   is $reply->{id}, $tool_id, "$name completes the original MCP request";
   is_deeply JSON::XS::decode_json ($reply->{result}{content}[0]{text}), $result,
      "$name preserves the JSON tool result";
}

permission_rules (["allow", "read"], ["allow", "write"], ["allow", "exec"]);
my $save_args = { target => "secondary-vim", buffer => 1, expected_changedtick => 7 };
my $save_challenge = rpc (1050, "tools/call", permission_params ("save", $save_args));
is $save_challenge->{result}{resultType}, "input_required", "editing and exec grants do not imply save permission";
is $save_challenge->{result}{inputRequests}{permission}{params}{_meta}{"anyevent-mcp/permission"}{request}{action},
   "save", "save uses the separate save action";
ok !IO::Select->new ($valid)->can_read (0.1), "unapproved save sends no Vim RPC";
my $save_denied = rpc (1051, "tools/call", permission_params (
   "save", $save_args, $save_challenge->{result}{requestState}, { action => "decline" },
));
ok $save_denied->{result}{isError}, "declining save denies save tool";
permission_rules (["allow", "read"], ["allow", "save"], ["deny", "write"]);
send_tool 1052, "save", $save_args;
my $save_call = vim_call;
is_deeply [@{$save_call->[1]}[2 .. $#{$save_call->[1]}]], ["update", 1, 7],
   "save grant permits the save tool without edit permission";
vim_reply $save_call, 1, { buffer => 1, changedtick => 7, modified => 0, filename => "/saved" };
is mcp_reply ()->{id}, 1052, "save returns the update result";
permission_rules (["allow", "read"], ["allow", "write"]);

permission_rules (["allow", "read"], ["allow", "write"], ["allow", "save"], ["allow", "exec"]);
my $open_args = { target => "secondary-vim", path => "/tmp/literal | % # [name]" };
my $open_challenge = rpc (1100, "tools/call", permission_params ("open", $open_args));
is $open_challenge->{result}{resultType}, "input_required", "read/edit/save/exec grants do not imply opening files";
my $open_request = $open_challenge->{result}{inputRequests}{permission}{params}{_meta}{"anyevent-mcp/permission"}{request};
is $open_request->{action}, "open", "opening files has a separate action";
like $open_request->{reason}, qr/\Q$open_args->{path}\E/, "open permission displays the requested pathname";
ok !IO::Select->new ($valid)->can_read (0.1), "unapproved open sends no Vim RPC";
my $open_denied = rpc (1101, "tools/call", permission_params (
   "open", $open_args, $open_challenge->{result}{requestState}, { action => "decline" },
));
ok $open_denied->{result}{isError}, "declining open stops the operation";
permission_rules (["allow", "open"], ["deny", "read"], ["deny", "write"]);
send_tool 1102, "open", $open_args;
my $open_call = vim_call;
is_deeply [@{$open_call->[1]}[2 .. $#{$open_call->[1]}]], ["open", $open_args->{path}],
   "open forwards the literal pathname without requiring read/edit grants";
my $opened_buffer = { buffer => 4, filename => $open_args->{path}, changedtick => 2, line_count => 3, modified => 0 };
vim_reply $open_call, 1, $opened_buffer;
my $open_reply = mcp_reply;
is_deeply JSON::XS::decode_json ($open_reply->{result}{content}[0]{text}), $opened_buffer,
   "open returns the loaded buffer identity and state";
for my $path ("", [], "bad\0path") {
   my $reply = rpc (++$main::open_test_id + 1110, "tools/call",
      { name => "open", arguments => { target => "secondary-vim", path => $path } });
   ok $reply->{result}{isError}, "open rejects empty, non-text and NUL-containing paths";
   ok !IO::Select->new ($valid)->can_read (0.1), "invalid open pathname never reaches Vim";
}
permission_rules (["allow", "read"], ["allow", "write"]);

for my $operation (qw(undo redo save)) {
   for my $args (
      { target => "secondary-vim", buffer => 1 },
      { target => "secondary-vim", buffer => 0, expected_changedtick => 7 },
      { target => "secondary-vim", buffer => 1, expected_changedtick => -1 },
   ) {
      my $reply = rpc (++$main::undo_test_id + 1000, "tools/call",
         { name => $operation, arguments => $args });
      ok $reply->{result}{isError}, "$operation rejects an invalid buffer or missing/invalid tick";
      ok !IO::Select->new ($valid)->can_read (0.1), "$operation validation precedes Vim RPC";
   }
}

my $grep_args = {
   target => "secondary-vim", buffers => [1], pattern => "alpha",
   mode => "word", max_results => 2,
};
send_tool 196, "grep", $grep_args;
my $failed_call = vim_call;
vim_reply $failed_call, 0, "mock Vim error";
my $failed_reply = mcp_reply;
ok $failed_reply->{id} == 196 && $failed_reply->{result}{isError}
   && $failed_reply->{result}{content}[0]{text} =~ /mock Vim error/,
   "failed Vim RPC becomes an MCP tool error";

send_tool 197, "grep", $grep_args;
my $cancelled_call = vim_call;
print {$in} JSON::XS::encode_json ({
   jsonrpc => "2.0", method => "notifications/cancelled",
   params => { requestId => 197 },
}), "\n" or die "cancel tool request: $!";
is rpc (198, "ping", {})->{id}, 198, "cancellation processed before the late Vim reply";
send_tool 199, "grep", $grep_args;
my $next_call = vim_call;
vim_reply $cancelled_call, 1, { cancelled => 1 };
vim_reply $next_call, 1, { after_cancel => 1 };
my $after_cancel = mcp_reply;
ok $after_cancel->{id} == 199 && !$after_cancel->{result}{isError}
   && JSON::XS::decode_json ($after_cancel->{result}{content}[0]{text})->{after_cancel},
   "late cancelled reply is ignored and the next tool call completes";

my ($invalid_ws, $invalid_headers) = upgrade ("secret-do-not-log-XYZ");
unlike $invalid_headers, qr{\AHTTP/1\.[01] 101\b},
   "unknown WebSocket URL token does not upgrade";
close $invalid_ws;

my ($malformed_ws, $malformed_headers) = upgrade ("secondary", "/secondary/");
unlike $malformed_headers, qr{\AHTTP/1\.[01] 101\b},
   "malformed WebSocket URL rejected even when it contains a valid token";
close $malformed_ws;

{
   my ($sock, $headers, $pending) = upgrade ("secondary");
   like $headers, qr{\AHTTP/1\.1 101\b},
      "secondary token authenticates xpcse WebSocket handshake";
   if ($headers =~ /\AHTTP\/1\.1 101\b/) {
      my $payload = JSON::XS::encode_json (["xpcse-client", 99]);
      my $frame = Protocol::WebSocket::Frame->new (
         type => "text", masked => 1, buffer => $payload,
      );
      print {$sock} $frame->to_bytes or die "send xpcse mismatch: $!";
      is ws_close_code ($sock, $pending), 1002,
         "xpcse version mismatch triggers protocol-error close";
   } else {
      fail "xpcse version mismatch closes connection";
   }
   close $sock;
}

subtest "browser transfers" => sub {
   plan skip_all => "extended browser transfer tests (PERL_ANYEVENT_MCP_TESTS=1)"
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;

   # browser transfers use the same broker, with Coro unavailable.
   sub browser {
      my ($sock, $headers, $pending) = upgrade ("secondary");
      $headers =~ /\AHTTP\/1\.1 101\b/ or die "browser upgrade failed\n";
      my $frame = Protocol::WebSocket::Frame->new (max_payload_size => 100e6);
      $frame->append ($pending);
      my $browser = [$sock, $frame];
      ws_message ($browser); # nick
      ws_message ($browser); # targets
      $browser
   }

   sub ws_message {
      my ($browser, $timeout) = @_;
      $timeout //= 30;
      my ($socket, $frame) = @$browser;
      my $deadline = Time::HiRes::time () + $timeout;
      while (1) {
         while (defined (my $payload = $frame->next_bytes)) {
            next if $frame->opcode == 10;
            return [$frame->opcode, $payload];
         }
         my $left = $deadline - Time::HiRes::time ();
         return if $left <= 0 || !IO::Select->new ($socket)->can_read ($left);
         my $n = sysread $socket, my $bytes, 65536;
         return unless $n;
         $frame->append ($bytes);
      }
   }

   sub browser_send {
      my ($browser, $message) = @_;
      print {$browser->[0]} Protocol::WebSocket::Frame->new (
         type => "text", masked => 1, buffer => JSON::XS::encode_json ($message),
      )->to_bytes or die "send browser message: $!";
   }

   sub vim_send {
      print {$valid} JSON::XS::encode_json ([0, $_[0]]) or die "send Vim message: $!";
   }

   sub browser_json {
      my $message = ws_message $_[0];
      $message && $message->[0] == 1 or die "expected browser JSON\n";
      JSON::XS::decode_json $message->[1]
   }

   vim_send [session => "save-test", {
      origin => "http://page.example:818", filename => "test.txt",
   }];

   my $browser = browser ();
   vim_send [save => "save-test"];
   like vim_call ()->[1][1], qr/requesting save/, "save reports its destination";
   is browser_json ($browser)->[0], "upload", "save starts a browser upload";

   require MIME::Base64;
   my $data = "x" x (10e6 + 37);
   vim_send [data => MIME::Base64::encode_base64 ($data, "")];

   my $message = ws_message $browser or die "oversized upload chunk stalled\n";
   is $message->[0], 2, "upload frame is binary";
   ok $message->[1] eq $data, "one oversized Vim chunk is forwarded whole";
   ok !IO::Select->new ($valid)->can_read (0.1), "receiving Vim data does not acknowledge browser receipt";

   # further chunks wait while credit is negative; eof and a queued save may already arrive.
   my @tail = ("first tail", "", "second tail");
   vim_send [data => MIME::Base64::encode_base64 ($_, "")] for @tail;
   vim_send [eof => 1];
   vim_send [save => "save-test"];
   like vim_call ()->[1][1], qr/requesting save/, "another save queues without acknowledging unsent data";
   vim_send [eof => 1];
   ok !ws_message ($browser, 0.1), "negative credit holds back the next whole chunk";

   browser_send $browser, [ack => length $data];
   is_deeply vim_call ()->[1], [ack => length $data], "browser receipt is forwarded to the originating Vim after its eof";
   for my $tail (@tail) {
      my $message = ws_message $browser or die "upload did not resume after acknowledgement\n";
      is_deeply $message, [2, $tail], "acknowledgement resumes output with the original chunk boundary";
   }
   is_deeply browser_json ($browser), ["upload-done"], "eof follows all input chunks";
   ok !ws_message ($browser, 0.1), "next upload waits for the browser's completion reply";
   for my $tail (@tail) {
      browser_send $browser, [ack => length $tail];
      is_deeply vim_call ()->[1], [ack => length $tail], "each browser chunk acknowledgement reaches Vim";
   }
   browser_send $browser, ["upload-done", "200", "saved first"];
   is_deeply vim_call ()->[1], [echo => "200 saved first"], "save completion remains separate from chunk receipt";
   is browser_json ($browser)->[0], "upload", "completion releases the queued save";
   is_deeply browser_json ($browser), ["upload-done"], "empty save sends eof without waiting for credit";
   browser_send $browser, ["upload-done", "500", "upload ok, but errors:\nat line 12, broken\n\n"];
   is_deeply vim_call ()->[1], [error => "error: at line 12, broken"], "multiline upload error retains its diagnostic";
   is_deeply vim_call ()->[1], [goto => "save-test", 12, 1], "upload error retains its session and line";

   vim_send [save => "save-test"];
   vim_call ();
   is browser_json ($browser)->[0], "upload", "another upload starts after an error reply";
   vim_send [eof => 0];
   my $aborted = ws_message $browser;
   is $aborted->[0], 8, "failed Vim eof closes the active upload instead of posting a partial file";
   is_deeply vim_call ()->[1], [echo => "save-test: browser disconnected"], "aborted upload releases its Vim input";
   close $browser->[0];

   # rejected saves still consume their input and leave RPC dispatch usable.
   vim_send [save => "save-test"];
   like vim_call ()->[1][1], qr/no origin found/, "save without a browser explains how to reconnect";
   vim_send [data => MIME::Base64::encode_base64 ("ignored", "")];
   vim_send [eof => 1];
   is_deeply vim_call ()->[1], [ack => 7], "rejected save consumes subsequent data";

   $browser = browser ();
   vim_send [save => "save-test"];
   vim_call ();
   browser_json $browser;
   close $browser->[0];
   is_deeply vim_call ()->[1], [echo => "save-test: browser disconnected"], "browser disconnect releases an unfinished save";

   my $leaving = vim_connect ("secondary", "leaving-vim");
   $leaving->autoflush (1);
   for (1 .. 1000) {
      last if grep $_ eq "leaving-vim", @{target_names ()};
      Time::HiRes::sleep (0.03);
   }
   $browser = browser ();
   print {$leaving} JSON::XS::encode_json ([0, [session => "leaving", {
      origin => "http://page.example:818", filename => "leaving.txt",
   }]]), JSON::XS::encode_json ([0, [save => "leaving"]]);
   vim_call $leaving;
   is browser_json ($browser)->[0], "upload", "disconnect test starts an unfinished upload";
   close $leaving;
   is ws_message ($browser)->[0], 8, "Vim disconnect aborts its unfinished browser upload";
   close $browser->[0];

   done_testing;
};

send_tool 200, "grep", $grep_args;
my $disconnected_call = vim_call;
close $valid;
my $disconnected_reply = mcp_reply;
ok $disconnected_reply->{id} == 200 && $disconnected_reply->{result}{isError}
   && $disconnected_reply->{result}{content}[0]{text} =~ /vim disconnected/,
   "disconnect fails an outstanding callback RPC";
close $ready if $ready;
close $in;
my $exit;
for (1 .. 1200) {
   my $w = waitpid ($pid, WNOHANG);
   if ($w == $pid) {
      $exit = $? >> 8;
      last;
   }
   Time::HiRes::sleep (0.025);
}
if (!defined $exit) {
   kill TERM => $pid;
   waitpid ($pid, 0);
   $exit = -1;
}
is $exit, 0, "broker exits after stdio EOF";
close $out;
local $/;
my $log = <$err> // "";
like $log, qr/vim <secondary-vim> connected/,
   "authenticated editor registration is logged without debug mode";
like $log, qr/vim <secondary-vim> disconnected/,
   "editor disconnect is logged without debug mode";
like $log, qr/ex target=secondary-vim command="echo 'hello' \| echo 'world'\\nlet g:example = 1"/,
   "Ex call logs its command preview without requiring debug verbosity";
like $log, qr/illegal websocket connect from 127\.0\.0\.1:\d+/,
   "rejected websocket handshake logs the numeric TCP peer and port";
unlike $log, qr/secret-do-not-log-XYZ|\/secondary\//,
   "rejected URL never exposes supplied credentials in the log";
close $err;

done_testing;
