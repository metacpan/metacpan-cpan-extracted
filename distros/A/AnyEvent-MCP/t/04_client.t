use common::sense;
# These tests and their subprocesses connect to private loopback listeners.
BEGIN { delete $ENV{http_proxy} }
use AnyEvent ();
use AnyEvent::Handle ();
use AnyEvent::Socket ();
use AnyEvent::MCP::Client::HTTP ();
use AnyEvent::MCP::Client::JSONL ();
use AnyEvent::MCP::Server::HTTP ();
use AnyEvent::MCP::Server::JSONL ();
use AnyEvent::MCP::Server::Toolset ();
use AnyEvent::MCP::Config ();
use JSON::XS ();
use File::Temp ();
use Socket;
use Scalar::Util qw(weaken);

print "1..65\n";

my $test;
sub ok($$) {
   my ($condition, $name) = @_;
   print (($condition ? "ok " : "not ok "), ++$test, " - $name\n");
}

sub wait_for {
   my ($start) = @_;
   my $cv = AnyEvent->condvar;
   my $timer = AnyEvent->timer (after => 30, cb => sub { die "Client test timeout\n" });
   $start->(sub { $cv->send ([@_]) });
   @{$cv->recv}
}

my $dir = File::Temp::tempdir (CLEANUP => 1);
local $ENV{XDG_CONFIG_HOME} = "$dir/config";
my $toolset = AnyEvent::MCP::Server::Toolset->new;
my $pending;
$toolset->tool (echo => "echo", {}, sub { $_[0]->result ($_[1]) });
$toolset->tool (slow => "slow", {}, sub { $pending = $_[0] });
$toolset->tool (fail => "fail", {}, sub { $_[0]->error ("tool failure") });

my $server = AnyEvent::MCP::Server::HTTP->new (
   toolsets => [$toolset], tokens => ["secret"],
);
$server->listen;
my $ready = 0;
my $client = AnyEvent::MCP::Client::HTTP->new (url => $server->url (0), bearer => "secret",
   on_ready => sub { ++$ready });
ok !-e "$dir/config", "unnamed server and client read no config";

my ($success, $result) = wait_for (sub { $client->call (echo => { text => "hello" }, $_[0]) });
ok $success && $result->{structuredContent}{text} eq "hello", "modern HTTP tool call";
ok $ready == 1, "ready event fires after successful MCP discovery";
($success, $result) = wait_for (sub { $client->connect ($_[0]) });
ok $success && $ready == 1, "reusing an initialized connection does not repeat ready event";
ok $client->{protocol_version} eq "2026-07-28", "modern discovery";
ok $client->{server_info}{name} eq "AnyEvent::MCP", "server identity";
ok ref $client->{server_capabilities}{tools} eq "HASH", "server capabilities";
($success, $result) = wait_for (sub { $client->tools ($_[0]) });
ok $success && @$result == 3, "list tools";
($success, $result) = wait_for (sub { $client->call (fail => {}, $_[0]) });
ok $success && $result->{isError}, "tool failure remains successful RPC";
($success, $result) = wait_for (sub { $client->rpc ("unknown", {}, $_[0]) });
ok !$success && $result->{code} == -32601, "HTTP protocol error preserved";
($success, $result) = wait_for (sub { $client->notify ("notifications/initialized", {}, $_[0]) });
ok $success, "HTTP notification";
$client->close;
($success, $result) = wait_for (sub { $client->call (echo => {}, $_[0]) });
ok $success && $ready == 2, "ready event fires again after reconnect";
$client->close;

$client = AnyEvent::MCP::Client::HTTP->new (url => $server->url);
($success, $result) = wait_for (sub { $client->call (echo => {}, $_[0]) });
ok $success, "URL cookie without header auth";
$client->close;
$client = AnyEvent::MCP::Client::HTTP->new (url => $server->url (0), bearer => "wrong");
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
ok !$success && $result->{transport} && $result->{message} =~ /401/, "wrong bearer fails";
$client->close;
$server->close;

$server = AnyEvent::MCP::Server::HTTP->new (toolsets => [$toolset], tokens => ["alpha", "beta"]);
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (url => $server->url (0), bearer => "beta");
($success, $result) = wait_for (sub { $client->call (echo => {}, $_[0]) });
ok $success, "second token accepted in Authorization header";
$client->close;
$server->close;
eval { AnyEvent::MCP::Client::HTTP->new (url => "http://localhost/", bearer => "token", username => "alice", password => "pw") };
ok $@ =~ /Basic authentication is unsupported/, "Basic credentials rejected even with bearer";
eval { AnyEvent::MCP::Client::HTTP->new (url => "http://localhost/", username => "alice") };
ok $@ =~ /Basic authentication is unsupported/, "Basic client credentials rejected";

$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", toolsets => [$toolset], versions => ["2025-06-18"]);
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (url => $server->url);
($success, $result) = wait_for (sub { $client->call (echo => { value => 42 }, $_[0]) });
ok $success && $result->{structuredContent}{value} == 42, "legacy fallback tool call";
ok $client->{protocol_version} eq "2025-06-18", "negotiated legacy version";
ok $client->{server_info}{name} eq "AnyEvent::MCP", "legacy wire identity preserved";
$client->close;
$server->close;

# Old dispatchers can return an internal error for an unknown discovery method.
my $discoveries = 0;
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", 
   toolsets => [$toolset],
   on_request => sub {
      if ($_[1]{method} eq "server/discover") {
         ++$discoveries;
         die "Undefined discovery handler\n"
      }
   },
);
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (url => $server->url);
($success, $result) = wait_for (sub { $client->call (echo => { value => 42 }, $_[0]) });
ok $success && $result->{structuredContent}{value} == 42, "discovery internal error falls back to initialization";
ok $discoveries == 1 && $client->{protocol_version} eq "2025-11-25", "fallback negotiates legacy once";
$client->close;
$server->close;

my $calls = 0;
my @input;
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_call => sub {
   my ($server, $req, $args) = @_;
   ++$calls;
   if (exists $req->{params}{inputResponses}) {
      ok $req->{params}{requestState} eq "opaque", "request state echoed";
      ok $req->{params}{inputResponses}{question}{content}{answer} == 42, "input answer echoed";
      ok $args->{original} eq "keep", "original tool arguments preserved";
      $req->result ({ answer => 42 });
   } else {
      $req->reply ({
         resultType => "input_required", requestState => "opaque",
         inputRequests => { question => {
            method => "elicitation/create", params => { message => "question" },
         } },
      });
   }
});
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (
   url => $server->url, client_capabilities => { elicitation => { form => {} } },
   on_request => sub {
      my ($client, $req) = @_;
      push @input, $req;
      $req->reply ({ action => "accept", content => { answer => 42 } });
   },
);
($success, $result) = wait_for (sub { $client->call (question => { original => "keep" }, $_[0]) });
ok $success && $result->{structuredContent}{answer} == 42, "modern input continuation";
ok $calls == 2 && @input == 1 && $input[0]{finished}, "input handled once";
($success, $result) = wait_for (sub {
   $client->rpc ("tools/call", { name => "question", arguments => {} }, $_[0]);
});
ok $success && $result->{resultType} eq "input_required" && @input == 1, "raw RPC preserves challenge";
$client->close;
$server->close;
@input = ();

my $page = 0;
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_list => sub {
   $_[1]->reply ({ tools => [{ name => ++$page }], ($page == 1 ? (nextCursor => "second") : ()) });
});
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (url => $server->url);
($success, $result) = wait_for (sub { $client->tools ($_[0]) });
ok $success && @$result == 2 && $result->[1]{name} == 2, "tool pagination";
$server->{on_tools_list} = sub { $_[1]->reply ({ tools => [], nextCursor => "repeat" }) };
($success, $result) = wait_for (sub { $client->tools ($_[0]) });
ok !$success && $result->{message} =~ /Repeated/, "pagination loop rejected";
$client->close;
$server->close;

socketpair my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
$server = AnyEvent::MCP::Server::JSONL->new (toolsets => [$toolset]);
$server->accept ($a);
$client = AnyEvent::MCP::Client::JSONL->new;
$client->attach ($b);
my @order;
($success, $result) = wait_for (sub {
   my $done = $_[0];
   $client->call (slow => {}, sub { push @order, "slow"; $done->(@_) });
   $client->rpc ("ping", {}, sub { push @order, "ping"; $pending->reply ({}); undef $pending });
});
ok $success && join (",", @order) eq "ping,slow", "JSONL replies can be out of order";

my ($id, $cancelled, $completions);
$id = $client->call (slow => {}, sub { ++$completions; $cancelled = $_[1] });
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
$client->cancel ($id);
ok $completions == 1 && $cancelled->{cancelled}, "local cancellation once";
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
ok $pending->{cancelled}, "wire cancellation reaches server";
undef $pending;
$client->cancel ($id);
ok $completions == 1, "repeated cancellation ignored";

$id = $client->call (slow => {}, sub { ++$completions; $cancelled = $_[1] });
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
$client->close;
ok $completions == 2 && $cancelled->{transport}, "close fails outstanding call";
$server->close;
undef $pending;

$client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "-e", '
      use AnyEvent::MCP::Server::Simple;
      mcp_tool echo => "echo", {}, sub { $_[0]->result ($_[1]) };
      mcp_start;
   '],
   env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
);
($success, $result) = wait_for (sub { $client->call (echo => { subprocess => 1 }, $_[0]) });
ok $success && $result->{structuredContent}{subprocess}, "direct subprocess command";
my $pid = $client->{pid};
$client->close;
ok !$client->{pid}, "close detaches child";
($success, $result) = wait_for (sub { $client->call (echo => { restarted => 1 }, $_[0]) });
ok $success && $result->{structuredContent}{restarted} && $client->{pid} != $pid, "new call restarts child";
$client->close;

# A real streaming response: progress arrives before the final event.
my ($sse_handle, $release, $listener, $port, $ended, $progress);
$listener = AnyEvent::Socket::tcp_server "127.0.0.1", 0, sub {
   $sse_handle = AnyEvent::Handle->new (fh => $_[0], on_error => sub { die $_[2] });
   $sse_handle->push_read (line => "\r\n\r\n", sub {
      my ($handle, $header) = @_;
      my ($length) = $header =~ /Content-Length: ([0-9]+)/i;
      $handle->push_read (chunk => $length, sub {
         my $msg = JSON::XS::decode_json $_[1];
         my $first = "data: " . JSON::XS::encode_json ({
            jsonrpc => "2.0", method => "notifications/progress", params => { progress => 1 },
         }) . "\r\n\r\n";
         my $last = "data: " . JSON::XS::encode_json ({
            jsonrpc => "2.0", id => $msg->{id}, result => { resultType => "complete", streamed => 1 },
         }) . "\r\n\r\n";
         $handle->push_write (
            "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nConnection: close\r\n"
            . "Content-Length: " . (length ($first) + length ($last)) . "\r\n\r\n"
            . substr ($first, 0, 8)
         );
         $release = AnyEvent->timer (after => 0.02, cb => sub {
            $handle->push_write (substr ($first, 8));
            $release = AnyEvent->timer (after => 0.02, cb => sub {
               $ended = 1;
               $handle->push_write ($last);
            });
         });
      });
   });
}, sub { $port = $_[2]; () };
$client = AnyEvent::MCP::Client::HTTP->new (
   url => "http://127.0.0.1:$port/", on_notification => sub {
      $progress = $_[1] eq "notifications/progress" && !$ended;
   },
);
$client->{connected} = 1;
$client->{protocol_version} = "2026-07-28";
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
ok $progress, "fragmented SSE progress delivered while streaming";
ok $success && $result->{streamed}, "SSE matching final response";
$client->close;
$sse_handle->destroy;
undef $release;
undef $listener;

my $config = AnyEvent::MCP::Config->global;
$config->{section}{"client example"} = { url => "http://example.invalid/", bearer => "configured", timeout => 7 };
$client = AnyEvent::MCP::Client::HTTP->new (name => "example", timeout => 9);
ok $client->{url} eq "http://example.invalid/" && $client->{bearer} eq "configured", "named client defaults";
ok $client->{timeout} == 9, "explicit client option wins";
$client->close;
$client = AnyEvent::MCP::Client::HTTP->new (name => "example", bearer => undef);
ok !defined $client->{bearer}, "explicit undef disables named auth";
$client->close;

$config->{section}{"instance example"} = { path => "/named/", tokens => "configured,secondary" };
$server = AnyEvent::MCP::Server::HTTP->new ($config->http_settings ("example"), port => 31740);
ok $server->{path} eq "/named/" && $server->{tokens}[0] eq "configured", "resolved named server settings";
ok @{$server->{tokens}} == 2 && $server->{tokens}[1] eq "secondary", "ordered configured tokens";
ok $server->url eq "http://127.0.0.1:31740/configured/named/", "first token is the advertised URL token";
$server->close;

my $req = AnyEvent::MCP::Client::Request->new (client => $client, on_reply => sub {});
$req->reply ({});
eval { $req->reply ({}) };
ok $@ =~ /already finished/, "duplicate input reply dies";
my $dismissed = 0;
$req = AnyEvent::MCP::Client::Request->new (client => $client, on_cancel => sub { ++$dismissed }, on_reply => sub {});
$req->cancel;
$req->cancel;
ok $req->{cancelled} && $dismissed == 1, "cancel dismisses input once";

# Pending operations must not keep the client alive through its own callbacks.
socketpair $a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
$server = AnyEvent::MCP::Server::JSONL->new (toolsets => [$toolset]);
$server->accept ($a);
$client = AnyEvent::MCP::Client::JSONL->new;
$client->attach ($b);
my $released;
$client->call (slow => {}, sub { $released = $_[1] });
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
my $weak = $client;
weaken $weak;
undef $client;
ok !defined $weak && $released->{transport}, "dropping pending client releases it and fails callback";
$server->close;
undef $pending;

# A close callback must still know which operations were interrupted, even
# though ordinary request callbacks have already been failed.
socketpair $a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
$server = AnyEvent::MCP::Server::JSONL->new (toolsets => [$toolset]);
$server->accept ($a);
$client = AnyEvent::MCP::Client::JSONL->new;
$client->attach ($b);
my $interrupted;
$client->call (slow => {}, sub { $interrupted = $_[1] });
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
my $close_error;
$client->{on_close} = sub { $close_error = $_[1] };
$client->close ("simulated broken stream");
ok $close_error->{pending} == 1 && $interrupted->{transport},
   "close reports the interrupted operation count after failing callbacks";
$server->close;
undef $pending;

socketpair $a, $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
$server = AnyEvent::MCP::Server::JSONL->new (toolsets => [$toolset]);
$server->accept ($a);
$client = AnyEvent::MCP::Client::JSONL->new (request_timeout => 0.02);
$client->attach ($b);
($success, $result) = wait_for (sub { $client->call (slow => {}, $_[0]) });
ok !$success && $result->{cancelled} && $result->{message} =~ /timed out/, "overall request deadline";
$client->close;
$server->close;
undef $pending;

# Keep an asynchronous input prompt open, then cancel its originating call.
my $prompt;
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_call => sub {
   $_[1]->reply ({
      resultType => "input_required", requestState => "opaque",
      inputRequests => { q => { method => "elicitation/create", params => {} } },
   });
});
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (url => $server->url);
($success, $result) = wait_for (sub { $client->call (question => {}, $_[0]) });
ok !$success && $result->{message} =~ /without a client handler/, "no implicit input approval";
my $prompt_ready;
my $dismiss = 0;
$client->{on_request} = sub {
   $prompt = $_[1];
   $prompt->{on_cancel} = sub { ++$dismiss };
   $prompt_ready->();
};
($success, $result) = wait_for (sub {
   $prompt_ready = $_[0];
   $id = $client->call (question => {}, sub { $cancelled = $_[1] });
});
$client->cancel ($id);
ok $prompt->{cancelled} && $dismiss == 1 && $cancelled->{cancelled}, "cancelling call dismisses asynchronous prompt";
$client->close;
$server->close;
undef $prompt;

# Modern tool-name headers must encode non-ASCII names.
my $unicode = "echo-" . chr 0x3bb;
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_call => sub {
   $_[1]->result ({ name => $_[1]{tool} });
});
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (url => $server->url);
($success, $result) = wait_for (sub { $client->call ($unicode, {}, $_[0]) });
ok $success && $result->{structuredContent}{name} eq $unicode, "Unicode Mcp-Name header";
$client->close;
$server->close;

# Two asynchronous answers can arrive in any order; continuation happens once.
my $rounds = 0;
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_call => sub {
   my ($server, $req) = @_;
   ++$rounds;
   if ($req->{params}{inputResponses}) {
      $req->result ({ inputs => $req->{params}{inputResponses} });
   } else {
      $req->reply ({
         resultType => "input_required", inputRequests => {
            a => { method => "elicitation/create", params => {} },
            b => { method => "elicitation/create", params => {} },
         },
      });
   }
});
$server->listen;
my %prompts;
$client = AnyEvent::MCP::Client::HTTP->new (
   url => $server->url, on_request => sub {
      $prompts{$_[1]{id}} = $_[1];
      if (keys %prompts == 2) {
         $prompts{b}->reply ({ action => "decline" });
         $prompts{a}->reply ({ action => "accept" });
      }
   },
);
($success, $result) = wait_for (sub { $client->call (question => {}, $_[0]) });
ok $success && $rounds == 2, "multiple input answers produce one continuation";
ok $result->{structuredContent}{inputs}{a}{action} eq "accept"
   && $result->{structuredContent}{inputs}{b}{action} eq "decline", "input keys and decisions preserved";
$client->close;
$server->close;
%prompts = ();

# Named token settings authenticate either by bearer header or URL path.
$server = AnyEvent::MCP::Server::HTTP->new ($config->http_settings ("example"));
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (
   url => $server->url (0), bearer => "secondary",
);
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
ok $success, "second configured token authenticates";
$client->close;
$client = AnyEvent::MCP::Client::HTTP->new (
   url => $server->url (0), bearer => "unlisted",
);
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
ok !$success && $result->{message} =~ /401/, "unlisted token rejected";
$client->close;
$server->close;

my $exit_cv = AnyEvent->condvar;
my $reap_poll = AnyEvent->timer (after => 0, interval => 0.02, cb => sub {
   $exit_cv->send (1) unless kill 0 => $pid;
});
my $reap_timeout = AnyEvent->timer (after => 30, cb => sub { $exit_cv->send (0) });
ok $exit_cv->recv && waitpid ($pid, 1) == -1, "subprocess child was reaped";
undef $reap_poll;
undef $reap_timeout;
eval { AnyEvent::MCP::Client::HTTP->new (url => "http://localhost/", bearer => "bad\nheader") };
ok $@ =~ /Invalid bearer/, "credential header injection rejected";

# A legacy session ID belongs to initialization and must accompany later POSTs.
my (@http_handles, $initializations, $session_header);
$listener = AnyEvent::Socket::tcp_server "127.0.0.1", 0, sub {
   my $handle = AnyEvent::Handle->new (
      fh => $_[0], on_error => sub { $_[0]->destroy }, on_eof => sub { $_[0]->destroy },
   );
   push @http_handles, $handle;
   $handle->push_read (line => "\r\n\r\n", sub {
      my ($handle, $header) = @_;
      my ($length) = $header =~ /Content-Length: ([0-9]+)/i;
      $handle->push_read (chunk => $length, sub {
         my $msg = JSON::XS::decode_json $_[1];
         my ($status, $extra, $body) = ("202 Accepted", "", "");
         if ($msg->{method} eq "initialize") {
            ++$initializations;
            $status = "200 OK";
            $extra = "Mcp-Session-Id: test-session\r\n";
            $body = JSON::XS::encode_json ({
               jsonrpc => "2.0", id => $msg->{id}, result => {
                  protocolVersion => "2025-06-18", capabilities => {},
                  serverInfo => { name => "legacy", version => "0" },
               },
            });
         } elsif ($msg->{method} eq "ping") {
            $session_header = $header =~ /Mcp-Session-Id: test-session/i;
            $status = "404 Not Found";
         }
         $handle->push_write (
            "HTTP/1.1 $status\r\nContent-Type: application/json\r\n"
            . $extra . "Content-Length: " . length ($body) . "\r\nConnection: close\r\n\r\n$body"
         );
      });
   });
}, sub { $port = $_[2]; () };
$client = AnyEvent::MCP::Client::HTTP->new (
   url => "http://127.0.0.1:$port/", versions => ["2025-06-18"],
);
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
ok !$success && $result->{message} =~ /session expired/ && !$client->{connected}, "session expiry invalidates client";
ok $session_header && $initializations == 1, "session header retained without retry";
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
ok !$success && $initializations == 2, "later operation creates a fresh session";
$client->close;
$_->destroy for @http_handles;
@http_handles = ();
undef $listener;

my $sent = 0;
$listener = AnyEvent::Socket::tcp_server "127.0.0.1", 0, sub {
   my $handle = AnyEvent::Handle->new (
      fh => $_[0], on_error => sub { $_[0]->destroy }, on_eof => sub { $_[0]->destroy },
   );
   push @http_handles, $handle;
   $handle->push_read (line => "\r\n\r\n", sub {
      ++$sent;
      $_[0]->destroy;
   });
}, sub { $port = $_[2]; () };
$client = AnyEvent::MCP::Client::HTTP->new (url => "http://127.0.0.1:$port/");
$client->{connected} = 1;
$client->{protocol_version} = "2026-07-28";
($success, $result) = wait_for (sub { $client->call (change => {}, $_[0]) });
ok !$success && $result->{transport} && $sent == 1, "broken HTTP tool call is not replayed";
$client->close;
$_->destroy for @http_handles;
@http_handles = ();
undef $listener;

my ($redirect_target, $redirect_port, $redirected);
$redirect_target = AnyEvent::Socket::tcp_server "127.0.0.1", 0, sub {
   ++$redirected;
   close $_[0];
}, sub { $redirect_port = $_[2]; () };
$listener = AnyEvent::Socket::tcp_server "127.0.0.1", 0, sub {
   my $handle = AnyEvent::Handle->new (
      fh => $_[0], on_error => sub { $_[0]->destroy }, on_eof => sub { $_[0]->destroy },
   );
   push @http_handles, $handle;
   $handle->push_read (line => "\r\n\r\n", sub {
      $_[0]->push_write (
         "HTTP/1.1 302 Found\r\nContent-Length: 0\r\nConnection: close\r\n"
         . "Location: http://127.0.0.1:$redirect_port/\r\n\r\n"
      );
   });
}, sub { $port = $_[2]; () };
$client = AnyEvent::MCP::Client::HTTP->new (url => "http://127.0.0.1:$port/", bearer => "secret");
$client->{connected} = 1;
$client->{protocol_version} = "2026-07-28";
($success, $result) = wait_for (sub { $client->rpc ("ping", {}, $_[0]) });
ok !$success && !$redirected && $result->{message} =~ /302/, "redirect does not forward credentials";
$client->close;
$_->destroy for @http_handles;
undef $listener;
undef $redirect_target;
