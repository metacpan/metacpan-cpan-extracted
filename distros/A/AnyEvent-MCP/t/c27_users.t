use common::sense;
use Test::More;
use File::Temp ();
use File::Path ();
use IPC::Open3 ();
use Symbol ();
use Socket ();

use AnyEvent::MCP::Config ();
use AnyEvent::MCP::Server::Permissions ();
use AnyEvent::MCP::Server ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
local $ENV{XDG_CONFIG_HOME} = $dir;
my $file = "$dir/anyevent-mcp/global.ini";
my $config = AnyEvent::MCP::Config->new (file => $file)->load->ensure_secret;

sub run {
   my @cmd = @_;
   my $err = Symbol::gensym;
   my $pid = IPC::Open3::open3 (undef, my $out, $err, $^X, "-Ilib", @cmd);
   local $/;
   my $stdout = <$out> // "";
   my $stderr = <$err> // "";
   waitpid $pid, 0;
   ($? >> 8, $stdout, $stderr)
}

sub cli {
   run "bin/anyevent-mcp", "--config", $file, @_
}

my ($help_status, $help_text, $help_errors) = cli "--help";
is $help_status, 0, "user management help succeeds: $help_errors";
like $help_text, qr/--program NAME.*select \[program NAME\]/,
   "help explains program scope";
like $help_text, qr/--instance NAME.*select \[instance NAME\]/,
   "help explains instance scope";
like $help_text, qr/anyevent-mcp --program mcp-fs create-user backup/,
   "help includes scoped user creation example";
($help_status, $help_text, $help_errors) = run "bin/mcp-multibroker", "--help";
is $help_status, 0, "multibroker help succeeds: $help_errors";
like $help_text, qr/--print-urls.*list URLs for all enabled users/,
   "multibroker help advertises plural URL printing";
like $help_text, qr/--print-url=chatgpt/, "multibroker help shows exact user selection";

my $users = $config->users ("test", "mcp-test");
is_deeply $users, { default => { scope => "global", generation => 1 } },
   "implicit default is an ordinary global generation-1 user";
my $original = $config->user_credentials ("test", "mcp-test")->[0][2];
like $original, qr/\A[A-Za-z0-9_-]{43}\z/, "default has a URL-safe token";
is $config->connect_user ("test", "mcp-test"), "default", "default connects";

{
   my $unicode_file = "$dir/anyevent-mcp/unicode.ini";
   my $comment = "# \x{e4}\x{1f431} comment\n";
   my $lock = AnyEvent::MCP::file_lock $unicode_file;
   AnyEvent::MCP::file_save $unicode_file, $comment . AnyEvent::MCP::file_load ($file)
      . "[extra]\nlabel = \x{e4}\x{1f431}\n";
   close $lock;
   my ($status, $out, $err) = run "bin/anyevent-mcp", "--config", $unicode_file, "create-user", "carol";
   is $status, 0, "user editor accepts Unicode configuration comments: $err";
   my $saved = AnyEvent::MCP::file_load $unicode_file;
   unlike $saved, qr/\Q$comment\E/, "canonical config rewrite drops comments";
   like $saved, qr/label = \x{e4}\x{1f431}/, "canonical config rewrite retains Unicode values";
   like $saved, qr/user\.carol\s*=\s*1/, "user editor still updates selected INI key";
}

my ($exit, $out, $err) = cli "create-user", "default";
isnt $exit, 0, "implicit default counts as an existing enabled user";
($exit, $out, $err) = cli "create-user", "alice";
is $exit, 0, "create global alice succeeds: $err";
$config = AnyEvent::MCP::Config->new (file => $file)->load;
is $config->users ("test", "mcp-test")->{alice}{scope}, "global", "global user inherited";
my $alice = $config->user_credentials ("test", "mcp-test")->[0][2];
my @creds = @{$config->user_credentials ("test", "mcp-test")};
is scalar @creds, 2, "both default and alice accepted";
is $creds[0][0], "default", "default comes first";
isnt $creds[1][2], $original, "user tokens differ";
isnt $creds[1][2], $config->user_credentials ("test", "other-program")->[1][2],
   "programs derive distinct credentials";
isnt $creds[1][2], $config->user_credentials ("other", "mcp-test")->[1][2],
   "instances derive distinct credentials";

($exit, $out, $err) = cli "create-user", "alice";
isnt $exit, 0, "duplicate create rejected";
($exit, $out, $err) = cli "revoke-user", "alice";
is $exit, 0, "revoke succeeds: $err";
$config = AnyEvent::MCP::Config->new (file => $file)->load;
is $config->users ("test", "mcp-test")->{alice}{generation}, -1, "revoke preserves generation";
is scalar @{$config->user_credentials ("test", "mcp-test")}, 1, "revoked token no longer accepted";
($exit, $out, $err) = cli "create-user", "alice";
is $exit, 0, "recreate revoked user succeeds: $err";
$config = AnyEvent::MCP::Config->new (file => $file)->load;
is $config->users ("test", "mcp-test")->{alice}{generation}, 2, "counter increased";
isnt $config->user_credentials ("test", "mcp-test")->[1][2], $creds[1][2],
   "revoked credential does not reappear";

($exit, $out, $err) = cli "--program", "mcp-test", "create-user", "alice";
is $exit, 0, "program override created: $err";
$config = AnyEvent::MCP::Config->new (file => $file)->load;
is $config->users ("test", "mcp-test")->{alice}{scope}, "program", "program takes precedence";
is $config->users ("test", "other-program")->{alice}{scope}, "global",
   "other program still inherits global";
($exit, $out, $err) = cli "--instance", "test", "revoke-user", "alice";
is $exit, 0, "local disable shadows inherited alice: $err";
$config = AnyEvent::MCP::Config->new (file => $file)->load;
is $config->users ("test", "mcp-test")->{alice}{generation}, -1, "instance deny shadows program";
is scalar @{$config->user_credentials ("test", "mcp-test")}, 1, "shadowed user not accepted";
($exit, $out, $err) = cli "--instance", "test", "create-user", "alice";
is $exit, 0, "instance re-enable works";
$config = AnyEvent::MCP::Config->new (file => $file)->load;
is $config->users ("test", "mcp-test")->{alice}{scope}, "instance", "instance takes precedence";
is $config->users ("test", "mcp-test")->{alice}{generation}, 2, "instance restarts at generation 2";

($exit, $out, $err) = cli "revoke-user", "default";
is $exit, 0, "implicit default can be revoked";
$config = AnyEvent::MCP::Config->new (file => $file)->load;
is_deeply $config->user_credentials ("another", "mcp-test")->[0][0], "alice",
   "other users work without default";
my %test_http = $config->http_settings ("test");
is scalar @{$test_http{connect_tokens}}, 0,
   "revoked default cannot register auxiliary connections";
($exit, $out, $err) = cli "create-user", "default";
is $exit, 0, "default can be rotated back into existence";
$config = AnyEvent::MCP::Config->new (file => $file)->load;
is $config->users ("test", "mcp-test")->{default}{generation}, 2, "default rotated";

my $original_request = { action => "read", dimensions => {
   user => { label => "Fake", value => "instance:admin", choices => [] },
} };
my $bound = AnyEvent::MCP::Server::Permissions::_user_request (
   { user => "global:alice" }, $original_request);
is $bound->{action}, "read", "permission binding preserves original request";
is $bound->{dimensions}{user}{value}, "global:alice", "tool-supplied user is replaced";
is $bound->{dimensions}{user}{default}, "global:alice",
   "exact user scope uses the permission engine's literal matcher convention";
my $exact = AnyEvent::MCP::Server::Permissions::_regex ($bound->{dimensions}{user}{default});
ok "global:alice" =~ $exact, "exact user matcher accepts its own identity through permission regex rules";
ok "global:alice2" !~ $exact, "exact user matcher rejects a different identity";
ok "global:bob" !~ $exact, "exact user matcher rejects another user";
my $all = AnyEvent::MCP::Server::Permissions::_regex ($bound->{dimensions}{user}{choices}[1]{match});
ok "global:alice" =~ $all, "all-users matcher accepts current identity";
my $scope = AnyEvent::MCP::Server::Permissions->new;
is $scope->check ({ %$bound, reason => "scope test", sandbox_grants => [] })->{decision},
   "ask", "managed user scope passes actual permission request validation";
$bound = AnyEvent::MCP::Server::Permissions::_user_request ({}, $original_request);
ok !exists $bound->{dimensions}{user}, "unidentified request gets no fabricated user";

{
   my $graph = { read => [], write => ["read"], host => ["write"] };
   my $request = { action => "exec", reason => "test", sandbox_grants => ["host"] };
   my $permissions = AnyEvent::MCP::Server::Permissions->new (
      sandbox_grants => $graph,
      rules => [{ decision => "deny", action => '^exec\z', "sandbox-grants" => "write" }],
   );
   is $permissions->check ($request)->{decision}, "deny",
      "saved workdir-write denial also denies stronger host permission";

   $permissions = AnyEvent::MCP::Server::Permissions->new (
      sandbox_grants => $graph,
      rules => [{ decision => "allow", action => '^exec\z', "sandbox-grants" => "write" }],
   );
   is $permissions->check ($request)->{decision}, "ask",
      "saved workdir-write allowance cannot authorize stronger host permission";
}


($exit, $out, $err) = run "bin/mcp-fs", "--print-url=alice";
is $exit, 0, "print-url for named user succeeds: $err";
like $out, qr/\Ahttps?:\/\/\S+\/\s+# user global:alice/m, "printed URL names its principal";
($exit, $out, $err) = run "bin/mcp-fs", "--print-url=unknown";
isnt $exit, 0, "unknown user selector fails";

{
   socket my $listener, Socket::AF_INET (), Socket::SOCK_STREAM (), 0
      or die "reserve TCP port: $!";
   bind $listener, Socket::pack_sockaddr_in (0, Socket::inet_aton ("127.0.0.1"))
      or die "bind reserved port: $!";
   listen $listener, 1 or die "listen reserved port: $!";
   my ($port) = Socket::unpack_sockaddr_in (getsockname $listener);

   ($exit, $out, $err) = run "bin/mcp-multibroker",
      "--bind", "127.0.0.1:$port", "--print-urls=alice";
   is $exit, 0, "plural URL option succeeds even with the address already listening: $err";
   like $out, qr{\Ahttp://127\.0\.0\.1:$port/[A-Za-z0-9_-]{43}/  \# user global:alice\n\z},
      "URL for occupied port is derived without attempting to bind";

   ($exit, $out, $err) = run "bin/mcp-multibroker",
      "--bind", "127.0.0.1:$port", "--print-url";
   is $exit, 0, "original singular option also prints without binding: $err";
   like $out, qr/\# user global:default \(connect\)/, "unfiltered listing identifies connection user";
   close $listener;
}

my $meta = {
   "io.modelcontextprotocol/protocolVersion" => "2026-07-28",
   "io.modelcontextprotocol/clientCapabilities" => { elicitation => { form => {} } },
};
sub asserted_user {
   my ($ask, $value, $sent) = @_;
   my $server = AnyEvent::MCP::Server->new (
      permissions => AnyEvent::MCP::Server::Permissions->new (ask => $ask),
      on_request => sub {
         my ($srv, $req) = @_;
         $req->reply ({ user => $req->{user} });
      },
   );
   my $reply;
   $server->rpc ({
      jsonrpc => "2.0", id => 1, method => "tools/call",
      params => {
         name => "example", arguments => {},
         _meta => { %$meta, "anyevent-mcp/user" => $sent },
      },
   }, sub { $reply = $_[0] },
      peer => {}, user => $value, protocol_version => "2026-07-28");
   $reply
}

is asserted_user ("mcp", "global:default", "global:alice")->{result}{user},
   "global:alice", "trusted MCP client can assert original user";
is asserted_user ("helper", "global:default", "global:alice")->{result}{user},
   "global:default", "default helper mode ignores asserted user";
is asserted_user ("auto", "global:default", "global:alice")->{result}{user},
   "global:alice", "auto with native forms trusts the peer";
ok !defined asserted_user ("mcp", "global:default", undef)->{result}{user},
   "trusted proxy can assert an explicitly anonymous caller";
like asserted_user ("mcp", "global:default", "admin!")->{error}{message},
   qr/Invalid delegated user/, "malformed trusted identity rejected";

done_testing;
