use common::sense;
BEGIN { delete $ENV{http_proxy} }
use Test::More;
use AnyEvent ();
use AnyEvent::Handle ();
use AnyEvent::Socket ();
use AnyEvent::Util ();
use AnyEvent::MCP::Extension ();
use AnyEvent::MCP::Client::JSONL ();
use AnyEvent::MCP::Client::HTTP ();
use AnyEvent::MCP::Server::Connect ();
use AnyEvent::MCP::Server::Toolset ();
use File::Temp ();
use File::Path ();
use JSON::XS ();

sub wait_for {
   my ($start) = @_;

   my $cv = AE::cv;
   my $timeout = AE::timer 15, 0, sub { $cv->send (undef) };
   $start->(sub { $cv->send ([@_]) });

   my $result = $cv->recv;
   defined $result or die "Reverse connection test timeout\n";

   @$result
}

is_deeply [AnyEvent::MCP::Extension::parse_url ("http://[::1]:1234/cookie/files")],
   ["::1", 1234, "cookie", "files"], "extension URL carries host, token and alias";
is_deeply [AnyEvent::MCP::Extension::parse_url ("http://[::1]/cookie/files")],
   ["::1", 80, "cookie", "files"], "extension URL defaults to port 80";
is_deeply [AnyEvent::MCP::Extension::parse_url ("http://abc:443/_BDPejql_VZnuBaUwnD3n7znlOp863kgQSMmr2voTCc/abc")],
   ["abc", 443, "_BDPejql_VZnuBaUwnD3n7znlOp863kgQSMmr2voTCc", "abc"],
   "extension URL accepts an explicit port and underscore-prefixed token";
eval { AnyEvent::MCP::Extension::parse_url ("http://localhost:0/cookie/files") };
ok $@, "extension URL rejects port zero";
eval { AnyEvent::MCP::Extension::parse_url ("http://localhost:1234/cookie/") };
ok $@, "extension URL requires an alias";

# hello parsing must not lose a subsequent MCP message read from the same socket.
{
   my ($left, $right) = AnyEvent::Util::portable_socketpair;
   my $client;
   my ($notification) = wait_for (sub {
      my ($done) = @_;
      my $handle = AnyEvent::Handle->new (
         fh => $left,
         on_error => sub { die $_[2] },
         on_eof => sub { die "Unexpected extension EOF\n" },
      );
      AnyEvent::MCP::Extension::accept ($handle, ["cookie"], sub {
         my ($handle, $hello) = @_;
         $client = AnyEvent::MCP::Client::JSONL->new (
            on_notification => sub { $done->($_[1]) },
         );
         $client->attach ($handle);
      });
      my $bytes = JSON::XS::encode_json (["mcp-connect", "cookie", "pipe"]) . "\n"
         . JSON::XS::encode_json ({ jsonrpc => "2.0", method => "notifications/tools/list_changed",
              params => { padding => "x" x 8192 } }) . "\n";
      syswrite $right, $bytes;
   });
   is $notification, "notifications/tools/list_changed", "JSONL handoff preserves pipelined input";
   $client->close;
   close $right;
}

my $dir = File::Temp::tempdir (CLEANUP => 1);
local $ENV{XDG_CONFIG_HOME} = "$dir/config";
my $port;
my $reserved = AnyEvent::Socket::tcp_server "127.0.0.1", 0, sub {}, sub { $port = $_[2]; () };
undef $reserved;
my $url = "http://127.0.0.1:$port/cookie";

my $upstream = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker", "--stdio", "--listen",
      "--bind", "127.0.0.1:$port", "--token", "cookie", "--ask", "mcp"],
   client_capabilities => { elicitation => { form => {} } },
   on_request => sub { $_[1]->reply ({ action => "accept", content => { answer => "yes" } }) },
);
my ($success, $result) = wait_for (sub { $upstream->tools ($_[0]) });
ok $success && @$result == 4, "empty multibroker serves stdio while waiting for reverse servers";

my $web = AnyEvent::MCP::Client::HTTP->new (url => "$url/");
($success, $result) = wait_for (sub { $web->tools ($_[0]) });
ok $success && @$result == 4, "forced listener serves HTTP alongside stdio";

my $tools = AnyEvent::MCP::Server::Toolset->new;
$tools->tool (echo => "echo", {}, sub { $_[0]->result ($_[1]) });
$tools->tool (form => "form", {}, sub {
   my ($req) = @_;
   return $req->result ($req->{params}{inputResponses}{question})
      if exists $req->{params}{inputResponses};
   $req->reply ({
      resultType => "input_required", requestState => "state",
      inputRequests => { question => { method => "elicitation/create", params => {
         mode => "form", message => "Choose",
         requestedSchema => { type => "object", properties => { answer => { type => "string" } } },
      }}},
   });
});
my ($downstream, $slow_calls, $cancel_id, $cancelled, $waiting);
$tools->tool (wait => "wait", {}, sub {
   $waiting = $_[0];
   $waiting->{on_cancel} = sub { ++$cancelled; undef $waiting };
   AnyEvent::postpone (sub { $upstream->cancel ($cancel_id, "test cancellation") });
});
$tools->tool (disconnect => "disconnect", {}, sub {
   ++$slow_calls;
   AnyEvent::postpone (sub {
      $downstream->_close ($_) for values %{$downstream->{connections}};
   });
});
$downstream = AnyEvent::MCP::Server::Connect->new (connect => "$url/remote", toolsets => [$tools]);
$downstream->start;

sub wait_alias {
   my ($alias) = @_;

   wait_for (sub {
      my ($done) = @_;
      my $busy;
      my $timer; $timer = AE::timer 0, .03, sub {
         return if $busy++;
         $upstream->call ("list-tools", { broker => $alias }, sub {
            my ($success, $result) = @_;
            $busy = 0;
            if ($success && !$result->{isError}) {
               undef $timer;
               $done->();
            }
         });
      };
   });
}

wait_alias "remote";
($success, $result) = wait_for (sub { $upstream->call ("remote.echo", { value => 42 }, $_[0]) });
ok $success && $result->{structuredContent}{value} == 42, "reverse server is discovered and callable";
($success, $result) = wait_for (sub { $upstream->call ("remote.form", {}, $_[0]) });
ok $success && $result->{structuredContent}{action} eq "accept"
   && $result->{structuredContent}{content}{answer} eq "yes", "reverse connection forwards forms upstream";
{
   local $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL} = "stdio";
   ok !$downstream->request_idle_exit, "reverse connection never gains spawned-child shutdown authority";
}

($success, $result) = wait_for (sub {
   $cancel_id = $upstream->call ("remote.wait", {}, $_[0]);
});
ok !$success, "upstream cancellation completes its reverse call";
($success, $result) = wait_for (sub { $upstream->call ("remote.echo", {}, $_[0]) });
is $cancelled, 1, "cancellation reaches the reverse server";

sub rejected {
   my ($hello) = @_;

   my ($closed) = wait_for (sub {
      my ($done) = @_;
      my $handle;
      my $guard; $guard = AnyEvent::Socket::tcp_connect "127.0.0.1", $port, sub {
         undef $guard;
         $_[0] or die "connect: $!";
         $handle = AnyEvent::Handle->new (
            fh => $_[0],
            on_read => sub { $handle->destroy; $done->(0) },
            on_eof => sub { $handle->destroy; $done->(1) },
            on_error => sub { $handle->destroy; $done->(1) },
         );
         $handle->push_write (JSON::XS::encode_json ($hello) . "\n");
      };
   });
   $closed
}

ok rejected (["mcp-connect", "wrong", "unauthorized"]), "bad token is rejected before registration";
ok rejected (["unknown", "cookie", "unknown"]), "unknown extension protocol is rejected";
ok rejected (["mcp-connect", "cookie", ["not-an-alias"]]), "non-string alias is rejected";
ok rejected ([0, ["mcp-connect", "cookie", "wrapped"]]), "Vim-style outer envelope is not an extension hello";
ok rejected (["mcp-connect", "cookie", "remote"]), "occupied alias is rejected";

($success, $result) = wait_for (sub { $upstream->call ("remote.disconnect", {}, $_[0]) });
ok !$success || $result->{isError}, "disconnect fails the outstanding call";
wait_alias "remote";
($success, $result) = wait_for (sub { $upstream->call ("remote.echo", { value => 43 }, $_[0]) });
ok $success && $result->{structuredContent}{value} == 43, "reverse server reconnects under the same alias";
is $slow_calls, 1, "disconnected operations are never replayed";

File::Path::mkpath ("$dir/work", 0, 0700);
my ($pid, $stdout, $stderr);
my $child = AnyEvent::Util::run_cmd (
   [$^X, "-Ilib", "bin/mcp-fs", "--connect", "$url/files", "--sandbox", "none", "$dir/work"],
   "<" => "/dev/null", ">" => \$stdout, "2>" => \$stderr, '$$' => \$pid,
);
wait_alias "files";
($success, $result) = wait_for (sub { $upstream->call ("files.workdirs", {}, $_[0]) });
ok $success && grep ($_ eq "$dir/work", values %{$result->{structuredContent}{workdirs}}),
   "mcp-fs --connect works through shared startup";
kill TERM => $pid;
$child->recv;
is $stdout, "", "reverse server does not emit protocol on stdout";

File::Path::mkpath ("$dir/config/anyevent-mcp/rules", 0, 0700);
SKIP: {
skip "WebSocket modules not installed", 2 unless eval {
   require AnyEvent::WebSocket::Server;
   require AnyEvent::WebSocket::Message;
   1
};
open my $rules, ">", "$dir/config/anyevent-mcp/rules/webbrowser-default.ini" or die $!;
print {$rules} "[rule]\ndecision=allow\naction=read\nsandbox-grants=\n";
close $rules or die $!;
$child = AnyEvent::Util::run_cmd (
   [$^X, "-Ilib", "bin/mcp-webbrowser", "--connect", "$url/browser", "--bind", "127.0.0.1:0"],
   "<" => "/dev/null", ">" => \$stdout, "2>" => \$stderr, '$$' => \$pid,
);
wait_alias "browser";
($success, $result) = wait_for (sub { $upstream->call ("browser.tabs", {}, $_[0]) });
ok $success && !@{$result->{structuredContent}{tabs}},
   "mcp-webbrowser --connect serves MCP while retaining its browser listener";
kill TERM => $pid;
$child->recv;
unlike $stderr, qr/EV: error|already finished|Can't call/, "reverse browser shutdown has no callback errors";
}

$downstream->close;
$web->close;
$upstream->close;

done_testing;
