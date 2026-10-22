use common::sense;
use AnyEvent ();
use AnyEvent::Handle ();
use AnyEvent::MCP::Server::Simple;
use AnyEvent::MCP::Server::HTTP ();
use AnyEvent::MCP::Server::Permissions ();
use AnyEvent::MCP::Config ();
use File::Temp ();
use IPC::Open3 ();
use Symbol ();
use JSON::XS ();
use MIME::Base64 ();
use Socket;

print "1..35\n";

my $test;
sub ok($$) {
   my ($condition, $name) = @_;

   print (($condition ? "ok " : "not ok "), ++$test, " - $name\n");
}

sub post {
   my ($server, $path, $authorization) = @_;

   socketpair my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
   $server->accept ($a);
   my $client = AnyEvent::Handle->new (fh => $b, on_error => sub { die $_[2] });
   my $cv = AnyEvent->condvar;
   my $timer = AnyEvent->timer (after => 30, cb => sub { die "HTTP timeout\n" });
   my $body = '{"jsonrpc":"2.0","id":1,"method":"ping"}';
   $client->push_write (
      "POST $path HTTP/1.1\r\nContent-Type: application/json\r\n"
      . "Content-Length: " . length ($body) . "\r\n"
      . (defined $authorization ? "Authorization: $authorization\r\n" : "")
      . "\r\n$body"
   );

   my ($header, $response);
   $client->push_read (line => "\r\n\r\n", sub {
      my ($handle, $text) = @_;
      $header = $text;
      my ($length) = $header =~ /Content-Length: ([0-9]+)/;
      $handle->push_read (chunk => $length, sub {
         $response = $_[1];
         $cv->send;
      });
   });
   $cv->recv;
   $client->destroy;
   $server->close;

   ($header, $response)
}

my $server = AnyEvent::MCP::Server::HTTP->new (
   port => 31740, path => "/", tokens => ["secret", "alternate"],
);
ok $server->url eq "http://127.0.0.1:31740/secret/", "cookie URL";
ok $server->url (0) eq "http://127.0.0.1:31740/", "clean URL";

my ($header, $body) = post ($server, "/secret/");
ok $header =~ m{HTTP/1.1 200}, "cookie authenticates";
ok JSON::XS::decode_json ($body)->{id} == 1, "authenticated RPC reply";
($header, $body) = post ($server, "/", "Bearer secret");
ok $header =~ m{HTTP/1.1 200}, "same token authenticates bearer";
($header, $body) = post ($server, "/", "bEaReR secret");
ok $header =~ m{HTTP/1.1 200}, "authentication scheme is case insensitive";
($header, $body) = post ($server, "/");
ok $header =~ m{HTTP/1.1 401}, "missing credential rejected";
ok $header =~ /WWW-Authenticate: Bearer/, "bearer challenge";
($header, $body) = post ($server, "/", "Bearer wrong");
ok $header =~ m{HTTP/1.1 401}, "wrong bearer rejected";
($header, $body) = post ($server, "/wrong/");
ok $header =~ m{HTTP/1.1 404}, "wrong cookie path rejected";

$server = AnyEvent::MCP::Server::HTTP->new (tokens => ["first", "second"]);
($header, $body) = post ($server, "/second/mcp/");
ok $header =~ m{HTTP/1.1 200}, "second token works in URL";
($header, $body) = post ($server, "/mcp/", "Bearer first");
ok $header =~ m{HTTP/1.1 200}, "first token works as bearer";
($header, $body) = post ($server, "/mcp/", "Basic YTpi");
ok $header =~ m{HTTP/1.1 401} && $header !~ /WWW-Authenticate: Basic/, "Basic authentication is not supported";

$server = AnyEvent::MCP::Server::HTTP->new (tokens => ["standalone"]);
($header, $body) = post ($server, "/mcp/");
ok $header =~ m{HTTP/1.1 401}, "embedded server with tokens rejects unauthenticated requests";
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", 
   host => "::1", port => 31740, handle => { tls => "accept" },
);
ok $server->url eq "https://[::1]:31740/mcp/", "IPv6 and TLS URL";
$server->{url_host} = "[::1]";
ok $server->url eq "https://[::1]:31740/mcp/", "prebracketed IPv6 URL host is not bracketed twice";
$server->{url_host} = "example.net";
$server->{url_scheme} = "http";
ok $server->url eq "http://example.net:31740/mcp/", "advertised URL overrides";
delete $server->{url_host};
$server->{host} = "0.0.0.0";
ok $server->url eq "http://" . (POSIX::uname)[1] . ":31740/mcp/", "wildcard nodename";
$server->{port} = 0;
eval { $server->url };
ok $@ =~ /port is not known/, "unknown port has no URL";

my $dir = File::Temp::tempdir (CLEANUP => 1);
local $ENV{XDG_CONFIG_HOME} = $dir;
local $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL};
my $printed = "";
{
   local *STDOUT;
   open STDOUT, ">", \$printed or die $!;
   my $timer;
   mcp_start name => "example", on_start => sub {
      $server = $_[0];
      $timer = AnyEvent->timer (after => 0.01, cb => sub { $server->close });
   };
}
ok $server->isa ("AnyEvent::MCP::Server::HTTP"), "normal startup uses HTTP";
ok $server->{port} && $printed eq "", "HTTP startup leaves stdout empty";
my $config = AnyEvent::MCP::Config->global;
ok $server->{tokens}[0] eq $config->credential ("token", "example"),
   "startup token matches derived utility";
ok $server->{server_info}{name} eq "example", "startup server identity";
$server->close;

my $err = Symbol::gensym;
my $pid = IPC::Open3::open3 (my $in, my $out, $err, $^X, "-Ilib", "-e", '
   use AnyEvent::MCP::Server::Simple;
   $ENV{XDG_CONFIG_HOME} = $ARGV[0];
   $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL} = "stdio";
   mcp_start;
', "$dir/stdio");
print {$in} "{\"jsonrpc\":\"2.0\",\"id\":42,\"method\":\"ping\"}\n";
$in->flush;
close $in;
local $/;
my $output = <$out>;
my $errors = <$err>;
waitpid $pid, 0;
ok !$? && !$errors, "multibroker startup succeeds";
ok eval { JSON::XS::decode_json ($output)->{id} == 42 }, "stdio output contains only RPC";
ok !-e "$dir/stdio", "stdio does not access global configuration";

$err = Symbol::gensym;
$pid = do {
   local $ENV{PERL_ANYEVENT_LOG} = ""; # inspect the normal activity log.
   IPC::Open3::open3 ($in, $out, $err, $^X, "-Ilib", "-e", '
   use AnyEvent::MCP::Server::Simple;
   my $timer;
   mcp_tool delayed => "delayed", {}, sub {
      my ($req) = @_;
      $timer = AnyEvent->timer (after => 0.03, cb => sub {
         $req->reply ({ content => [{ type => "text", text => "x" x 200000 }] });
      });
   };
   mcp_stdio;
   print STDERR "stopped\\n";
   ');
};
print {$in} JSON::XS::encode_json ({
   jsonrpc => "2.0", id => 1, method => "initialize", params => {
      protocolVersion => "2025-11-25", clientInfo => {}, capabilities => {},
   },
}), "\n";
print {$in} JSON::XS::encode_json ({
   jsonrpc => "2.0", id => 2, method => "tools/call", params => { name => "delayed" },
}), "\n";
close $in;
$output = <$out>;
$errors = <$err>;
waitpid $pid, 0;
ok !$? && $errors =~ /\bdelayed\b.*\nstopped\n\z/s,
   "mcp_stdio logs tool activity and returns after input EOF";
my @messages = map JSON::XS::decode_json ($_), split /\n/, $output;
ok @messages == 2 && $messages[1]{id} == 2
   && length $messages[1]{result}{content}[0]{text} == 200000,
   "EOF waits for an asynchronous reply and drains large output";

my ($started, $closed, $timer);
mcp_http auth => "none", port => 0, on_start => sub {
   my ($server) = @_;
   ++$started;
   $timer = AnyEvent->timer (after => 0.01, cb => sub { $server->close });
}, on_close => sub { ++$closed };
ok $started == 1 && $closed == 1, "mcp_http blocks through startup and returns on close";

eval { mcp_http auth => "none", port => 0, on_start => sub { die "startup failed\n" } };
ok $@ =~ /startup failed/, "startup hook exception closes the server and propagates";

{
   local @ARGV = ("--auto-deny=*,write", "--auto-allow=read_lines,read",
      "--auto-deny=*,*,*");
   my %options = mcp_getoptions ({ name => "auto-test" });
   ok JSON::XS::encode_json ($options{auto_rules}) eq JSON::XS::encode_json ([
      ["deny", "*,write"], ["allow", "read_lines,read"], ["deny", "*,*,*"],
   ]), "CLI collects repeatable allow/deny rules in original order";

   my $perm = AnyEvent::MCP::Server::Permissions->new (
      rules => [{ decision => "deny", action => "^" }],
   );
   my $timer;
   mcp_http %options, auth => "none", port => 0, permissions => $perm,
      on_start => sub {
         my ($server) = @_;
         $timer = AnyEvent->timer (after => 0.01, cb => sub { $server->close });
      };
   my $call = { action => "read", sandbox_grants => [], reason => "test" };
   ok $perm->check ($call, "read-lines")->{decision} eq "allow",
      "Simple starter installs ordered allow rule";
   ok $perm->check ({ %$call, action => "write" }, "read-lines")->{decision} eq "deny",
      "earlier auto-deny takes precedence over later allow";
   ok $perm->check ($call, "exec")->{decision} eq "deny",
      "later wildcard deny catches unmatched tools";

   my $created;
   mcp_http auth => "none", port => 0, auto_rules => [["deny", "*"]],
      on_start => sub {
         my ($server) = @_;
         $created = $server->{permissions};
         $timer = AnyEvent->timer (after => 0.01, cb => sub { $server->close });
      };
   ok $created && $created->check ($call, "anything")->{decision} eq "deny",
      "Simple starter creates a permission engine for automatic denial";
}
