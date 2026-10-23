use common::sense;
# These tests and their subprocesses connect to private loopback listeners.
BEGIN { delete $ENV{http_proxy} }
use AnyEvent ();
use AnyEvent::Handle ();
use AnyEvent::Util ();
use AnyEvent::MCP::Client::HTTP ();
use AnyEvent::MCP::Client::JSONL ();
use AnyEvent::MCP::Server::HTTP ();
use AnyEvent::MCP::Server::Toolset ();
use File::Temp ();
use File::Path ();
use IO::Socket::INET ();
use JSON::XS ();
use Time::HiRes ();

print "1..67\n";
my $test;
sub ok($$) {
   my ($condition, $name) = @_;
   print (($condition ? "ok " : "not ok "), ++$test, " - $name\n");
}
sub wait_for {
   my ($start) = @_;
   my $cv = AnyEvent->condvar;
   my $timer = AnyEvent->timer (after => 30, cb => sub { $cv->send (undef) });
   $start->(sub { $cv->send ([@_]) });
   my $result = $cv->recv;
   die "Broker test timeout\n" unless defined $result;
   @$result
}
sub write_file {
   my ($path, $text) = @_;
   open my $fh, ">", $path or die "$path: $!";
   print $fh $text;
   close $fh or die "$path: $!";
}
sub shell_quote {
   my ($text) = @_;
   $text =~ s/'/'\\''/g;
   "'$text'"
}

my $dir = File::Temp::tempdir (CLEANUP => 1);
local $ENV{XDG_CONFIG_HOME} = "$dir/config";
local $ENV{PERL_ANYEVENT_MCP_PERMISSION_HELPER} = "$dir/ask";
write_file "$dir/ask", "#!$^X\n" . q{
use JSON::XS ();
local $/;
my $request = JSON::XS::decode_json <STDIN>;
print JSON::XS::encode_json {
   decision => "allow-once", sandbox_grants => $request->{sandbox_grants},
};
};
chmod 0700, "$dir/ask" or die "chmod: $!";
write_file "$dir/child", q{
BEGIN { $ENV{PERL_ANYEVENT_LOG} = "filter=error log=error" } # fixture output is not under test.
use common::sense;
use AnyEvent ();
use AnyEvent::MCP::Server::Simple;
use JSON::XS ();
my $cancelled = 0;
my $pending;
mcp_config instructions => $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS} eq "silent"
   ? undef : $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS};
mcp_tool echo => "echo", {}, sub {
   $_[0]->result ({
      %{$_[1]},
      alias => $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS},
      protocol => $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL},
      extension => $_[0]{peer}{aemcp_multibroker},
      permission_ask => $ENV{PERL_ANYEVENT_MCP_PERMISSION_ASK},
   });
};
mcp_tool slow => "slow", {}, sub {
   $pending = $_[0];
   $pending->{on_cancel} = sub { ++$cancelled; undef $pending };
};
mcp_tool status => "status", {}, sub { $_[0]->result ({ cancelled => $cancelled }) };
mcp_tool legacy_permission => "legacy permission", {}, sub {
   my ($req) = @_;
   my $decision = $req->{params}{_meta}{"anyevent-mcp/permission"}{decision};
   return $req->result ($decision) if $decision;
   $req->reply ({
      isError => JSON::XS::true, content => [],
      _meta => { "anyevent-mcp/permission" => {
         version => 1, request => {
            action => "legacy-permission", action_matcher => "legacy-permission",
            sandbox_grants => ["read"], sandbox_grant_choices => ["read"], subjects => [],
         },
      }},
   });
};
mcp_start;
};

my $toolset = AnyEvent::MCP::Server::Toolset->new;
$toolset->tool (echo => "HTTP echo", { type => "object" }, sub { $_[0]->result ($_[1]) });
$toolset->{tool}{echo}{definition}{annotations} = { readOnlyHint => JSON::XS::true };
$toolset->tool (caps => "sandbox_grants", {}, sub {
   $_[0]->result ($_[0]{params}{_meta}{"io.modelcontextprotocol/clientCapabilities"});
});
$toolset->tool (fail => "failure", {}, sub { $_[0]->error ("backend failure") });
$toolset->tool (challenge => "input challenge", {}, sub {
   my ($req) = @_;
   if (exists $req->{params}{inputResponses}) {
      return $req->result ({
         response => $req->{params}{inputResponses}{permission},
         state => $req->{params}{requestState},
      })
   }
   $req->reply ({
      resultType => "input_required", requestState => "opaque",
      inputRequests => { permission => {
         method => "elicitation/create", params => {
            mode => "form", message => "permission",
            requestedSchema => { type => "object", properties => {} },
            _meta => { "anyevent-mcp/permission" => { version => 1, request => {
               action => "challenge", action_matcher => "challenge",
               sandbox_grants => ["read"], sandbox_grant_choices => ["read"], subjects => [],
            }}},
         },
      }},
   });
});
my $http = AnyEvent::MCP::Server::HTTP->new (
   toolsets => [$toolset], tokens => ["secret"], instructions => "HTTP instructions",
);
$http->listen;
my @command = (
   $^X, "-Ilib", "bin/mcp-multibroker", "--ask", "mcp",
   http => $http->url (0), "--bearer", "secret",
   child => "stdio:" . join (" ", map { shell_quote $_ } $^X, "-Ilib", "$dir/child"),
);
sub client {
   AnyEvent::MCP::Client::JSONL->new (
      command => \@command,
      env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
      @_,
   )
}
my $client = client;
my ($success, $result) = wait_for (sub { $client->tools ($_[0]) });
ok $success && @$result == 13, "combined tool listing";
my %tools = map { $_->{name} => $_ } @$result;
ok exists $tools{"http.echo"} && exists $tools{"child.echo"} && exists $tools{"call-tool"}
   && exists $tools{"child.meta-instructions"} && exists $tools{"meta-instructions"}, "namespaces and builtins";
($success, $result) = wait_for (sub { $client->call ("child.meta-instructions", {}, $_[0]) });
ok $success && $result->{content}[0]{text} eq "child", "downstream synthetic instructions are callable";
($success, $result) = wait_for (sub { $client->call ("meta-instructions", {}, $_[0]) });
ok $success && $result->{content}[0]{text} =~ /Multibroker proxies multiple MCP servers/,
   "multibroker synthetic instructions are callable with custom routing";
ok !$tools{"list-tools"}{inputSchema}{additionalProperties},
   "list-tools schema forbids unknown arguments";
ok $tools{"http.echo"}{annotations}{readOnlyHint}, "tool definition extensions preserved";
($success, $result) = wait_for (sub { $client->call ("http.echo", { value => 42 }, $_[0]) });
ok $success && $result->{structuredContent}{value} == 42, "HTTP downstream call";
($success, $result) = wait_for (sub { $client->call ("http.caps", {}, $_[0]) });
ok $success && $result->{structuredContent}{extensions}{"anyevent-mcp/multibroker"}{version} == 1,
   "multibroker advertises versioned extension to HTTP downstream clients too";
($success, $result) = wait_for (sub { $client->call ("child.echo", {}, $_[0]) });
ok $success && $result->{structuredContent}{alias} eq "child"
   && $result->{structuredContent}{protocol} eq "stdio", "stdio child receives prefixed environment";
ok $result->{structuredContent}{extension},
   "stdio child negotiates multibroker extension during discovery";
my $ask_client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker", "--ask", "auto", child => $command[-1]],
   env => {
      PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
      PERL_ANYEVENT_MCP_PERMISSION_ASK => "helper",
   },
);
($success, $result) = wait_for (sub { $ask_client->call ("child.echo", {}, $_[0]) });
ok $success && $result->{structuredContent}{permission_ask} eq "auto",
   "multibroker --ask auto overrides parent environment for spawned stdio child";
$ask_client->close;

$ask_client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker", child => $command[-1]],
   env => {
      PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
      PERL_ANYEVENT_MCP_PERMISSION_ASK => "mcp",
   },
);
($success, $result) = wait_for (sub { $ask_client->call ("child.echo", {}, $_[0]) });
ok $success && $result->{structuredContent}{permission_ask} eq "mcp",
   "plain multibroker inherits generic permission mode without --ask";
$ask_client->close;
($success, $result) = wait_for (sub {
   $client->call ("call-tool", { name => "child.echo", arguments => { wrapped => 1 } }, $_[0]);
});
ok $success && $result->{structuredContent}{wrapped}, "call-tool wrapper";
($success, $result) = wait_for (sub { $client->call ("discover-brokers", {}, $_[0]) });
ok $success && $result->{structuredContent}{http} eq "HTTP instructions"
   && $result->{structuredContent}{child} eq "child", "discover instructions";
($success, $result) = wait_for (sub { $client->call ("list-tools", {}, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 13, "list-tools builtin";
($success, $result) = wait_for (sub { $client->call ("list-tools", { broker => "child" }, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 5
   && !grep ($_->{name} !~ /\Achild\./, @{$result->{structuredContent}{tools}}),
   "list-tools with broker returns only that exact downstream broker";
($success, $result) = wait_for (sub { $client->call ("list-tools", { broker => "http" }, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 4
   && !grep ($_->{name} !~ /\Ahttp\./, @{$result->{structuredContent}{tools}}),
   "list-tools with another broker excludes local and other downstream tools";
($success, $result) = wait_for (sub { $client->call ("list-tools", { broker => "absent" }, $_[0]) });
ok $success && $result->{isError}, "list-tools rejects unknown exact broker name";
($success, $result) = wait_for (sub { $client->call ("list-tools", { broker => "child", bogus => 1 }, $_[0]) });
ok $success && $result->{isError}
   && $result->{content}[0]{text} =~ /Unknown list-tools argument 'bogus'/,
   "list-tools rejects unrecognized input fields instead of ignoring them";
($success, $result) = wait_for (sub { $client->call ("missing.tool", {}, $_[0]) });
ok $success && $result->{isError}, "unknown route is a tool error";
($success, $result) = wait_for (sub { $client->call ("call-tool", { name => "call-tool" }, $_[0]) });
ok $success && $result->{isError}, "recursive wrapper rejected";
($success, $result) = wait_for (sub { $client->call ("http.fail", {}, $_[0]) });
ok $success && $result->{isError} && $result->{content}[0]{text} eq "backend failure", "downstream tool error preserved";
($success, $result) = wait_for (sub {
   $client->rpc ("tools/call", { name => "http.challenge", arguments => {} }, $_[0]);
});
ok $success && $result->{resultType} eq "input_required" && $result->{requestState} eq "opaque",
   "raw modern challenge forwarded";
my $inputs = 0;
$client->{client_capabilities} = { elicitation => { form => {} } };
$client->{on_request} = sub {
   ++$inputs;
   $_[1]->reply ({ action => "accept", content => { decision => "allow-once", sandbox_grants => "read" } });
};
($success, $result) = wait_for (sub { $client->call ("http.challenge", {}, $_[0]) });
ok $success && $inputs == 1 && $result->{structuredContent}{state} eq "opaque"
   && $result->{structuredContent}{response}{content}{decision} eq "allow-once", "input response and state round trip";
($success, $result) = wait_for (sub {
   $client->call ("http.caps", {}, $_[0], _meta => {
      "io.modelcontextprotocol/clientCapabilities" => { testing => { value => 17 } },
   });
});
ok $success && $result->{structuredContent}{testing}{value} == 17
   && !exists $result->{structuredContent}{elicitation}, "per-call sandbox_grants preserved";
($success, $result) = wait_for (sub { $client->call ("child.legacy-permission", {}, $_[0]) });
ok $success && $result->{structuredContent}{decision} eq "allow-once", "old stdio permission helper bridge";

my $cancel_cv = AnyEvent->condvar;
my $id = $client->call ("child.slow", {}, sub { $cancel_cv->send ([@_]) });
# A second request proves the first has reached the child before cancellation.
wait_for (sub { $client->call ("child.status", {}, $_[0]) });
$client->cancel ($id);
my $cancel = $cancel_cv->recv;
ok !$cancel->[0] && $cancel->[1]{cancelled}, "local cancellation completes once";
($success, $result) = wait_for (sub { $client->call ("child.status", {}, $_[0]) });
ok $success && $result->{structuredContent}{cancelled} == 1, "cancellation reaches downstream request";
($success, $result) = wait_for (sub { $client->call ("child.echo", { after => 1 }, $_[0]) });
ok $success && $result->{structuredContent}{after}, "connection survives cancellation";
$client->close;

$client = client (versions => ["2025-11-25"]);
($success, $result) = wait_for (sub { $client->call ("http.challenge", {}, $_[0]) });
ok $success && $result->{structuredContent}{response}{content}{decision} eq "allow-once",
   "legacy caller uses local helper for modern input";
($success, $result) = wait_for (sub { $client->call ("http.caps", {}, $_[0]) });
ok $success && !exists $result->{structuredContent}{elicitation},
   "explicit mcp mode does not advertise upstream form support for a legacy caller";
$client->close;

# A failed child must not hide the tools and instructions of reachable peers.
my $partial = AnyEvent::MCP::Client::JSONL->new (
   command => [@command, gone => "stdio:/bin/false", silent => $command[-1]],
   env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
);
($success, $result) = wait_for (sub { $partial->tools ($_[0]) });
ok $success && @$result == 17, "unreachable peer omitted from listing";
($success, $result) = wait_for (sub { $partial->call ("discover-brokers", {}, $_[0]) });
ok $success && ref $result->{structuredContent}{gone} eq "HASH"
   && $result->{structuredContent}{gone}{error} =~ /\S/
   && $result->{structuredContent}{http} eq "HTTP instructions",
   "unreachable broker reports error alongside successful broker instructions";
ok $success && exists $result->{structuredContent}{silent}
   && !defined $result->{structuredContent}{silent},
   "reachable broker without instructions remains explicitly null";
$partial->close;
# Explicit local interfaces apply to permission forms from HTTP children too.
write_file "$dir/anyevent-mcp-askpermission", "#!$^X\n" . q{
use JSON::XS ();
local $/;
my $request = JSON::XS::decode_json <STDIN>;
open my $log, ">", $ENV{MCP_TEST_UI_LOG} or die $!;
print {$log} JSON::XS::encode_json (\@ARGV);
close $log or die $!;
print JSON::XS::encode_json { decision => "allow-once", sandbox_grants => $request->{sandbox_grants} };
};
chmod 0700, "$dir/anyevent-mcp-askpermission" or die $!;
for my $mode (qw(tty yad)) {
   my $local = AnyEvent::MCP::Client::JSONL->new (
      command => [$^X, "-Ilib", "bin/mcp-multibroker", "--ask", $mode,
         http => $http->url (0), "--bearer", "secret"],
      env => {
         PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
         PERL_ANYEVENT_MCP_PERMISSION_HELPER => "$dir/not-a-custom-helper",
         PATH => "$dir:$ENV{PATH}", MCP_TEST_UI_LOG => "$dir/ui-log",
      },
      on_request => sub { die "Explicit local permission reached upstream\n" },
   );
   my ($success, $result) = wait_for (sub { $local->call ("http.challenge", {}, $_[0]) });
   ok $success && $result->{structuredContent}{response}{content}{decision} eq "allow-once",
      "$mode handles an HTTP child's permission locally";
   open my $log, "<", "$dir/ui-log" or die $!;
   my $argv = JSON::XS::decode_json do { local $/; <$log> };
   close $log;
   ok @$argv == 1 && $argv->[0] eq "--$mode", "$mode selects its built-in permission renderer";
   $local->close;
}

# Broker management tools are normal activity; prefixed downstream tools
# remain trace-only, independently of the downstream server's own logging.
sub broker_log {
   my ($spec) = @_;

   my $file = "$dir/broker-" . ++$main::log_id . ".log";
   my $logged = client (env => {
      PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
      PERL_ANYEVENT_LOG => "log=file=$file $spec",
   });
   wait_for (sub { $logged->call ("child.echo", {}, $_[0]) });
   wait_for (sub { $logged->call ("call-tool", {name => "child.echo"}, $_[0]) });
   wait_for (sub { $logged->call ("discover-brokers", {}, $_[0]) });
   wait_for (sub { $logged->call ("list-tools", {}, $_[0]) });
   wait_for (sub { $logged->tools ($_[0]) });
   $logged->close;
   open my $fh, "<", $file or die "$file: $!";
   local $/;
   <$fh>
}
my $default_log = broker_log "";
ok $default_log =~ /mcp-multibroker\/default\[\d+\] call-tool name=child\.echo\n/,
   "call-tool activity identifies its downstream tool";
ok $default_log =~ /mcp-multibroker\/default\[\d+\] discover-brokers\n/,
   "direct discover-brokers invocation appears in broker activity";
ok $default_log =~ /mcp-multibroker\/default\[\d+\] list-tools\n/,
   "direct list-tools invocation appears in broker activity";
ok $default_log !~ /mcp-multibroker\/default\[\d+\] (?:child\.echo|child\.meta-instructions)\b/,
   "normal broker activity excludes prefixed downstream tool calls";
ok $default_log =~ /mcp-multibroker\/default\[\d+\] debug main: multibroker list-tools\n/,
   "multibroker diagnostics default to debug, even with a configured file destination";
my $trace_log = broker_log "filter=trace";
ok $trace_log =~ /mcp-multibroker\/default\[\d+\] trace main: multibroker child\.echo\n/,
   "explicit trace configuration reveals proxied tool calls";
my @traces = $trace_log =~ /trace main: multibroker child\.echo\n/g;
ok @traces == 2,
   "direct proxying and call-tool forwarding each generate one trace message";
my $info_log = broker_log "filter=info";
ok $info_log !~ /debug main: multibroker list-tools/,
   "explicit filter level overrides broker's default debug";
ok $info_log =~ /mcp-multibroker\/default\[\d+\] call-tool name=child\.echo\n/,
   "management activity remains visible with a restricted diagnostic filter";

# The broker accepts underscore spellings for hyphenated aliases, without
# changing names returned by discovery or overriding an exact alias.
my $aliased = AnyEvent::MCP::Client::JSONL->new (
   command => [@command, "dash-name" => $command[-1]],
   env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
);
($success, $result) = wait_for (sub { $aliased->call ("list-tools", {broker => "dash_name"}, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 5
   && !grep ($_->{name} !~ /\Adash-name\./, @{$result->{structuredContent}{tools}}),
   "list-tools accepts an underscore alias but returns real tool names";
($success, $result) = wait_for (sub { $aliased->call ("dash_name.echo", {}, $_[0]) });
ok $success && $result->{structuredContent}{alias} eq "dash-name",
   "direct prefixed calls accept underscore aliases";
($success, $result) = wait_for (sub {
   $aliased->call ("call-tool", { name => "dash_name.echo" }, $_[0])
});
ok $success && $result->{structuredContent}{alias} eq "dash-name",
   "call-tool accepts underscore aliases";
$aliased->close;

my $exact = AnyEvent::MCP::Client::JSONL->new (
   command => [@command, "dash-name" => $command[-1], "dash_name" => $command[-1]],
   env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
);
($success, $result) = wait_for (sub { $exact->call ("dash_name.echo", {}, $_[0]) });
ok $success && $result->{structuredContent}{alias} eq "dash_name",
   "an exact underscore alias takes precedence over the hyphen fallback";
$exact->close;

# Two delayed HTTP peers must receive discovery concurrently.
my (%pending, %timers, %parallel);
my @delayed_servers;
for my $label (qw(first second)) {
   my $server = AnyEvent::MCP::Server::HTTP->new (
      auth => "none",
      on_http_request => sub {
         my ($server, $request, $reply) = @_;
         my $message = eval { JSON::XS::decode_json $request->{body} };
         my $method = $message->{method} // "";
         return 0 unless $method eq "server/discover" || $method eq "tools/list";

         my $group = $method eq "server/discover" ? "discover" : "tools";
         push @{$pending{$group}}, [$reply, $message->{id}, $label];
         $parallel{$group} = 1 if @{$pending{$group}} == 2;
         $timers{$group} ||= AnyEvent->timer (after => 0.15, cb => sub {
            for my $item (@{delete $pending{$group} || []}) {
               my ($send, $id, $name) = @$item;
               my $result = $group eq "discover"
                  ? { supportedVersions => ["2026-07-28"], capabilities => { tools => {} },
                      instructions => $name }
                  : { tools => [{ name => "echo", description => $name,
                      inputSchema => { type => "object" } }] };
               $result->{resultType} = "complete";
               $result->{_meta} = { "io.modelcontextprotocol/serverInfo" =>
                  { name => $name, version => "0" } };
               $send->(200, "OK", {}, JSON::XS::encode_json ({
                  jsonrpc => "2.0", id => $id, result => $result,
               }));
            }
            delete $timers{$group};
         });
         1
      },
   );
   $server->listen;
   push @delayed_servers, $server;
}
my $parallel_client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker",
      first => $delayed_servers[0]->url (0),
      second => $delayed_servers[1]->url (0)],
   env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
);
($success, $result) = wait_for (sub { $parallel_client->call ("discover-brokers", {}, $_[0]) });
ok $success && $parallel{discover}
   && $result->{structuredContent}{first} eq "first"
   && $result->{structuredContent}{second} eq "second",
   "discover-brokers contacts independent HTTP peers concurrently";
($success, $result) = wait_for (sub { $parallel_client->call ("list-tools", {}, $_[0]) });
my @remote = grep /\A(?:first|second)\./, map $_->{name}, @{$result->{structuredContent}{tools} || []};
ok $success && $parallel{tools}
   && join (",", @remote) eq "first.echo,second.echo",
   "list-tools contacts peers concurrently but retains sorted tool order";
$parallel_client->close;
$_->close for @delayed_servers;

$http->close;

my $pure_stdio = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker", child => $command[-1]],
   env => {
      PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
      XDG_CONFIG_HOME => "$dir/stdio_config",
   },
);
($success, $result) = wait_for (sub { $pure_stdio->tools ($_[0]) });
ok $success && @$result == 9, "broker with only stdio children";
ok !-e "$dir/stdio_config", "pure stdio broker reads no global configuration";
$pure_stdio->close;


# Test named bind configuration and command-line precedence with ephemeral ports.
for my $cli (1, 0) {
   my $probe = IO::Socket::INET->new (
      LocalAddr => "127.0.0.1", LocalPort => 0, Proto => "tcp", Listen => 1,
   ) or die "allocate test port: $!\n";
   my $port = $probe->sockport;
   close $probe;
   my @auth_options = $cli ? ("--token", "upstream-first", "--token", "upstream-second") : ();
   File::Path::mkpath ("$dir/http_config/$cli/anyevent-mcp", 0, 0700);
   write_file "$dir/http_config/$cli/anyevent-mcp/global.ini",
      "[instance default]\nbind = " . ($cli ? "127.0.0.2:$port" : "127.0.0.1:$port") . "\n";
   chmod 0600, "$dir/http_config/$cli/anyevent-mcp/global.ini" or die "chmod: $!";
   my ($url, $url_error);
   {
      local $ENV{XDG_CONFIG_HOME} = "$dir/http_config/$cli";
      my $cv = AnyEvent::Util::run_cmd (
         [$^X, "-Ilib", "bin/mcp-multibroker", @auth_options, ($cli ? ("--bind=127.0.0.1:$port") : ()), "--print-url"],
         ">" => \$url, "2>" => \$url_error,
      );
      $cv->recv == 0 or die "multibroker --print-url: $url_error\n";
   }
   chomp $url;
   my $pid;
   END { kill TERM => $pid if $pid }
   my $server_cv;
   my $stdout;
   {
      local %ENV = (
         %ENV,
         PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "",
         XDG_CONFIG_HOME => "$dir/http_config/$cli",
      );
      $server_cv = AnyEvent::Util::run_cmd (
         [$^X, "-Ilib", "bin/mcp-multibroker", @auth_options, ($cli ? ("--bind=127.0.0.1:$port") : ()), child => $command[-1]],
         "<" => "/dev/null", ">" => \$stdout, '$$' => \$pid, close_all => 1,
      );
   }
   $server_cv->cb (sub { undef $pid });
   ok $url =~ m{\Ahttp://127\.0\.0\.1:}, "--bind overrides configured address"
      if $cli;
   my ($printed_port, $path) = $url =~ m{\Ahttp://127\.0\.0\.1:([0-9]+)(/.*)\z};
   $printed_port == $port or die "--print-url returned wrong port\n";
   my $socket;
   for (1 .. 1500) {
      $socket = IO::Socket::INET->new (PeerAddr => "127.0.0.1", PeerPort => $port, Proto => "tcp", Timeout => 1);
      last if $socket;
      Time::HiRes::sleep (0.02);
   }
   $socket or die "CORS test socket: $!\n";
   print {$socket}
      "OPTIONS $path HTTP/1.1\r\nHost: localhost\r\n"
      . "Origin: http://localhost:5001\r\n"
      . "Access-Control-Request-Method: POST\r\n"
      . "Access-Control-Request-Headers: content-type,authorization\r\n\r\n";
   my $preflight;
   {
      local $/ = "\r\n\r\n";
      $preflight = <$socket>;
   }
   close $socket;
   my $allowed = "*";
   ok $preflight =~ /HTTP\/1\.1 204/ && $preflight =~ /^Access-Control-Allow-Origin: \Q$allowed\E\r?$/m,
      "CORS preflight allows any origin by default";
   my $web = AnyEvent::MCP::Client::HTTP->new (url => $url);
   ($success, $result) = wait_for (sub { $web->call ("child.echo", { web => 1 }, $_[0]) });
   ok $success && $result->{structuredContent}{web}, ($cli ? "CLI bind overrides named bind; cookie URL works" : "named bind works; cookie URL works");
   $web->close;
   my ($clean, $token) = $url =~ m{\A(https?://[^/]+/)([^/]+)/\z};
   $web = AnyEvent::MCP::Client::HTTP->new (url => $clean, bearer => $token);
   ($success, $result) = wait_for (sub { $web->call ("child.echo", { bearer => 1 }, $_[0]) });
   ok $success && $result->{structuredContent}{bearer}, "same token authenticates clean URL as bearer";
   $web->close;
   if ($cli) {
      $web = AnyEvent::MCP::Client::HTTP->new (url => $clean, bearer => "upstream-second");
      ($success, $result) = wait_for (sub { $web->call ("child.echo", { alternate => 1 }, $_[0]) });
      ok $success && $result->{structuredContent}{alternate}, "second upstream --token authenticates";
      $web->close;
   }
   ok -f "$dir/http_config/$cli/anyevent-mcp/global.ini", "default HTTP startup stores its master secret";
   kill TERM => $pid if $pid;
   wait_for (sub {
      my ($done) = @_;
      $server_cv->cb (sub { undef $pid; $done->(1, $_[0]->recv) });
   });
   ok !$stdout, "HTTP broker startup keeps stdout empty";
}
