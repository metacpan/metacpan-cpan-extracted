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

print "1..104\n";
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
use AnyEvent::MCP::Server::Permissions ();
use AnyEvent::MCP::Server::Simple;
my $cancelled = 0;
my $pending;
mcp_config instructions => $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS} eq "silent"
   ? undef : $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS};
mcp_config permissions => AnyEvent::MCP::Server::Permissions->new (
   actions => { read => "Read test value" },
);
mcp_tool echo => "echo", {}, sub {
   if ($_[1]{protected}) {
      $_[0]->require_permission ({
         tool => "echo", action => "read", sandbox_grants => [], reason => "Protected test value",
      });
   }
   $_[0]->progress (1, 2, "Child working") if $_[1]{progress};
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
mcp_start;
};

my $toolset = AnyEvent::MCP::Server::Toolset->new;
$toolset->tool (echo => "HTTP echo", { type => "object" }, sub {
   my ($req, $args) = @_;
   return $req->result ($args) unless $args->{progress};
   $req->progress (1, 2, "HTTP working");
   my $timer; $timer = AE::timer 0.3, 0, sub {
      undef $timer;
      $req->result ($args);
   };
});
$toolset->{tool}{echo}{definition}{annotations} = { readOnlyHint => JSON::XS::true };
$toolset->{tool}{echo}{definition}{inputSchema}{properties} = {
   nested => { type => "object", properties => {
      secret_marmot => { type => "string", description => "Chromatic wombat identifier" },
   }},
};
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
               sandbox_grants => ["read"], sandbox_grant_choices => ["read"], dimensions => {},
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
ok $success && $result->{content}[0]{text} =~ /Proxy MCP servers.*PREFIX\.TOOL/,
   "multibroker synthetic instructions are callable with custom routing";
($success, $result) = wait_for (sub {
   $client->call ("meta-instructions", { padding => "x" x (2 * 1024 * 1024) }, $_[0]);
});
ok $success && $result->{content}[0]{text} =~ /Proxy MCP servers/,
   "multibroker accepts upstream requests larger than 1 MiB";
ok !$tools{"list-tools"}{inputSchema}{additionalProperties},
   "list-tools schema forbids unknown arguments";
ok $tools{"http.echo"}{annotations}{readOnlyHint}, "tool definition extensions preserved";
($success, $result) = wait_for (sub { $client->call ("http.echo", { value => 42 }, $_[0]) });
ok $success && $result->{structuredContent}{value} == 42, "HTTP downstream call";
my @progress;
my ($progress_at, $done_at);
$client->{on_notification} = sub {
   my ($client, $method, $params) = @_;
   if ($method eq "notifications/progress") {
      push @progress, [$method, $params];
      $progress_at = Time::HiRes::time () if $params->{progressToken} eq "http-progress";
   }
};
($success, $result) = wait_for (sub {
   my ($done) = @_;
   $client->call ("http.echo", { progress => 1 }, sub {
      $done_at = Time::HiRes::time ();
      $done->(@_);
   }, _meta => { progressToken => "http-progress" });
});
ok $success && $result->{structuredContent}{progress}, "HTTP child returns after streamed notification";
ok @progress && $progress[-1][1]{progressToken} eq "http-progress"
   && $progress[-1][1]{message} eq "HTTP working", "HTTP SSE progress forwarded through multibroker";
ok defined $progress_at && $done_at - $progress_at > 0.1,
   "progress arrives over HTTP while downstream operation is still running";
@progress = ();
($success, $result) = wait_for (sub { $client->call ("http.caps", {}, $_[0]) });
ok $success && $result->{structuredContent}{extensions}{"anyevent-mcp/multibroker"}{version} == 1,
   "multibroker advertises versioned extension to HTTP downstream clients too";
($success, $result) = wait_for (sub { $client->call ("child.echo", {}, $_[0]) });
ok $success && $result->{structuredContent}{alias} eq "child"
   && $result->{structuredContent}{protocol} eq "stdio", "stdio child receives prefixed environment";
ok $result->{structuredContent}{extension},
   "stdio child negotiates multibroker extension during discovery";
($success, $result) = wait_for (sub {
   $client->call ("child.echo", { progress => 1 }, $_[0], _meta => { progressToken => "child-progress" });
});
ok $success && $result->{structuredContent}{progress}, "stdio child returns after notification";
ok @progress && $progress[-1][1]{progressToken} eq "child-progress"
   && $progress[-1][1]{message} eq "Child working", "stdio progress forwarded through multibroker";
delete $client->{on_notification};
my $ask_client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker", "--ask", "auto", child => $command[-1]],
   env => {
      PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
      PERL_ANYEVENT_MCP_PERMISSION_ASK => "helper",
   },
);
($success, $result) = wait_for (sub { $ask_client->call ("child.echo", {}, $_[0]) });
ok $success && $result->{structuredContent}{permission_ask} eq "mcp",
   "multibroker --ask auto makes spawned child delegate permissions by MCP";
($success, $result) = wait_for (sub { $ask_client->call ("child.echo", { protected => 1 }, $_[0]) });
ok $success && $result->{structuredContent}{protected},
   "spawned child permission prompt is handled locally by auto-mode multibroker";
$ask_client->close;

$ask_client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker", child => $command[-1]],
   env => {
      PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
      PERL_ANYEVENT_MCP_PERMISSION_ASK => "helper",
   },
);
($success, $result) = wait_for (sub { $ask_client->call ("child.echo", {}, $_[0]) });
ok $success && $result->{structuredContent}{permission_ask} eq "mcp",
   "default multibroker delegates child permission prompts despite inherited helper mode";
($success, $result) = wait_for (sub { $ask_client->call ("child.echo", { protected => 1 }, $_[0]) });
ok $success && $result->{structuredContent}{protected},
   "default multibroker handles delegated child permission prompt locally";
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
($success, $result) = wait_for (sub { $client->call ("search-tools", { query => "HTTP echo" }, $_[0]) });
ok $success && !$result->{isError}
   && (grep $_->{name} eq "http.echo", @{$result->{structuredContent}{tools}})
   && $result->{structuredContent}{total_matches} >= 1,
   "BM25 tool search finds a matching downstream tool";
($success, $result) = wait_for (sub { $client->call ("search-tools", { query => "search" }, $_[0]) });
ok $success && !$result->{isError}
   && !grep ($_->{name} !~ /\./, @{$result->{structuredContent}{tools}}),
   "search excludes the broker's own directly exposed tools";
($success, $result) = wait_for (sub { $client->call ("search-tools", { query => "secret marmot" }, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 1
   && $result->{structuredContent}{tools}[0]{name} eq "http.echo"
   && $result->{structuredContent}{tools}[0]{inputSchema}{properties}{nested}{properties}{secret_marmot}{description}
      eq "Chromatic wombat identifier",
   "nested argument names are indexed and full definitions are returned";
($success, $result) = wait_for (sub { $client->call ("search-tools", { query => "zzzznomatchzzzz" }, $_[0]) });
ok $success && !@{$result->{structuredContent}{tools}} && !$result->{structuredContent}{total_matches},
   "unmatched query returns empty results";
($success, $result) = wait_for (sub { $client->call ("search-tools", { query => "   " }, $_[0]) });
ok $success && $result->{isError}, "search requires nonempty keywords";
($success, $result) = wait_for (sub { $client->call ("list-tools", { broker => "child" }, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 4
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

# Hidden brokers remain discoverable and callable, but do not advertise tools.
my $hidden_http = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker",
      http => $http->url (0), "--bearer", "secret", "--hidden",
      child => $command[-1]],
   env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
);
($success, $result) = wait_for (sub { $hidden_http->tools ($_[0]) });
ok $success && @$result == 9 && !grep (/\Ahttp\./, map $_->{name}, @$result),
   "HTTP hidden child omitted from normal tools/list";
($success, $result) = wait_for (sub { $hidden_http->call ("list-tools", {}, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 9
   && !grep (/\Ahttp\./, map $_->{name}, @{$result->{structuredContent}{tools}}),
   "unfiltered list-tools omits hidden child";
($success, $result) = wait_for (sub { $hidden_http->call ("list-tools", { broker => "http" }, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 4
   && !grep ($_->{name} !~ /\Ahttp\./, @{$result->{structuredContent}{tools}}),
   "explicit list-tools includes hidden HTTP child";
($success, $result) = wait_for (sub { $hidden_http->call ("search-tools", { query => "chromatic WOMBAT" }, $_[0]) });
ok $success && !$result->{isError}
   && @{$result->{structuredContent}{tools}} == 1
   && $result->{structuredContent}{tools}[0]{name} eq "http.echo"
   && $result->{structuredContent}{tools}[0]{annotations}{readOnlyHint},
   "search includes hidden brokers, preserves full definitions, and matches case-insensitively";
($success, $result) = wait_for (sub { $hidden_http->call ("discover-brokers", {}, $_[0]) });
ok $success && $result->{structuredContent}{http} =~ /Hidden tools; use list-tools broker=http/
   && $result->{structuredContent}{http} =~ /HTTP instructions/
   && $result->{structuredContent}{child} eq "child", "discover-brokers identifies hidden child";
($success, $result) = wait_for (sub { $hidden_http->call ("http.echo", { direct => 1 }, $_[0]) });
ok $success && $result->{structuredContent}{direct}, "hidden HTTP child callable directly";
($success, $result) = wait_for (sub {
   $hidden_http->call ("call-tool", { name => "http.echo", arguments => { wrapped => 1 } }, $_[0]);
});
ok $success && $result->{structuredContent}{wrapped}, "hidden HTTP child callable through call-tool";
$hidden_http->close;

my $hidden_stdio = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker",
      http => $http->url (0), "--bearer", "secret",
      child => "---", $^X, "-Ilib", "$dir/child", "---", "--hidden"],
   env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
);
($success, $result) = wait_for (sub { $hidden_stdio->tools ($_[0]) });
ok $success && @$result == 9 && !grep (/\Achild\./, map $_->{name}, @$result),
   "hidden stdio child omitted from normal tools/list";
($success, $result) = wait_for (sub { $hidden_stdio->call ("list-tools", {}, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 9,
   "unfiltered list-tools omits hidden stdio child";
($success, $result) = wait_for (sub { $hidden_stdio->call ("list-tools", { broker => "child" }, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 4,
   "explicit list-tools includes hidden stdio child";
($success, $result) = wait_for (sub { $hidden_stdio->call ("discover-brokers", {}, $_[0]) });
ok $success && $result->{structuredContent}{child} =~ /Hidden tools; use list-tools broker=child/,
   "discover-brokers identifies hidden stdio child";
($success, $result) = wait_for (sub { $hidden_stdio->call ("child.echo", { direct => 1 }, $_[0]) });
ok $success && $result->{structuredContent}{direct}, "hidden stdio child callable directly";
($success, $result) = wait_for (sub {
   $hidden_stdio->call ("call-tool", { name => "child.echo", arguments => { wrapped => 1 } }, $_[0]);
});
ok $success && $result->{structuredContent}{wrapped}, "hidden stdio child callable through call-tool";
$hidden_stdio->close;

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
   my ($client, $req) = @_;
   ++$inputs;
   my $grants = $req->{params}{_meta}{"anyevent-mcp/permission"}{request}{sandbox_grants};
   $req->reply ({ action => "accept", content => { decision => "allow-once", sandbox_grants => join ",", @$grants } });
};
($success, $result) = wait_for (sub { $client->call ("http.challenge", {}, $_[0]) });
ok $success && $inputs == 1 && $result->{structuredContent}{state} eq "opaque"
   && $result->{structuredContent}{response}{content}{decision} eq "allow-once", "input response and state round trip";
($success, $result) = wait_for (sub { $client->call ("child.echo", { protected => 1 }, $_[0]) });
ok $success && $inputs == 2 && $result->{structuredContent}{protected},
   "spawned child permission prompt forwarded through mcp-mode multibroker";
($success, $result) = wait_for (sub {
   $client->call ("http.caps", {}, $_[0], _meta => {
      "io.modelcontextprotocol/clientCapabilities" => { testing => { value => 17 } },
   });
});
ok $success && $result->{structuredContent}{testing}{value} == 17
   && !exists $result->{structuredContent}{elicitation}, "per-call sandbox_grants preserved";

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
ok $success && @$result == 16, "unreachable peer omitted from listing";
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
ok $success && @{$result->{structuredContent}{tools}} == 4
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

my $none_client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker", "--ask", "none",
      http => $http->url (0), "--bearer", "secret",
      child => $command[-1]],
   env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
);
($success, $result) = wait_for (sub { $none_client->call ("http.challenge", {}, $_[0]) });
ok $success && $result->{structuredContent}{response}{action} eq "decline",
   "broker --ask none auto-declines downstream elicitation requests";
($success, $result) = wait_for (sub {
   $none_client->call ("child.echo", { protected => 1 }, $_[0]);
});
ok $success && $result->{isError},
   "broker --ask none declines child permission requests without executing";
$none_client->close;

my $bulk = AnyEvent::MCP::Server::Toolset->new;
$bulk->tool (huge => "elephant", {
   type => "object", properties => {
      payload => { type => "string", description => "elephant " . ("z" x 20000) },
   },
}, sub { $_[0]->result ({}) });
for my $i (0 .. 24) {
   $bulk->tool (sprintf ("heavy%02d", $i), "heavy", {
      type => "object", properties => {
         payload => { type => "string", description => "heavy " . ("q" x 3700) },
      },
   }, sub { $_[0]->result ({}) });
}
for my $i (0 .. 29) {
   $bulk->tool (sprintf ("widget%02d", $i), $i == 29 ? "needle needle needle" : "needle",
      { type => "object" }, sub { $_[0]->result ({}) });
}
my $bulk_server = AnyEvent::MCP::Server::HTTP->new (toolsets => [$bulk], auth => "none");
$bulk_server->listen;
my $bulk_client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker", bulk => $bulk_server->url (0)],
   env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
);
($success, $result) = wait_for (sub { $bulk_client->call ("search-tools", { query => "needle" }, $_[0]) });
ok $success && @{$result->{structuredContent}{tools}} == 25
   && $result->{structuredContent}{total_matches} == 30,
   "search returns top 25 of 30 matching definitions";
ok $result->{structuredContent}{tools}[0]{name} eq "bulk.widget29"
   && $result->{structuredContent}{tools}[1]{name} eq "bulk.widget00"
   && $result->{structuredContent}{tools}[24]{name} eq "bulk.widget23",
   "BM25 rewards term frequency and breaks equal scores by tool name";
($success, $result) = wait_for (sub { $bulk_client->call ("search-tools", { query => "elephant" }, $_[0]) });
my $large = $result->{structuredContent}{tools}[0];
ok $success && $large->{name} eq "bulk.huge" && $large->{schema_omitted}
   && !$large->{inputSchema} && $large->{retrieve}{arguments}{broker} eq "bulk"
   && $large->{retrieve}{arguments}{name} eq "huge", "oversized tool summarized with retrieval";
($success, $result) = wait_for (sub {
   $bulk_client->call ("list-tools", { broker => "bulk", name => "huge" }, $_[0]);
});
ok $success && @{$result->{structuredContent}{tools}} == 1
   && length ($result->{structuredContent}{tools}[0]{inputSchema}{properties}{payload}{description}) > 20000,
   "retrieve exactly one complete oversized schema";
($success, $result) = wait_for (sub { $bulk_client->call ("search-tools", { query => "heavy" }, $_[0]) });
my $heavy = $result->{structuredContent};
ok $success && @{$heavy->{tools}} == 25 && $heavy->{total_matches} == 25,
   "large search retains all 25 ranked candidates";
ok length (JSON::XS::encode_json ($heavy)) <= 65536, "64 KiB structured result budget";
ok scalar (grep $_->{inputSchema}, @{$heavy->{tools}})
   && scalar (grep $_->{schema_omitted}, @{$heavy->{tools}}),
   "full definitions prioritized before summarized later matches";
($success, $result) = wait_for (sub {
   $bulk_client->call ("list-tools", { broker => "bulk", name => "missing" }, $_[0]);
});
ok $success && !@{$result->{structuredContent}{tools}}, "unknown single tool returns empty list";
($success, $result) = wait_for (sub { $bulk_client->call ("list-tools", { name => "huge" }, $_[0]) });
ok $success && $result->{isError}, "single-tool lookup requires broker";
$bulk_client->close;
$bulk_server->close;

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
   $url =~ s/\s+# user [^\n]*\z//;
   my $pid;
   END { kill TERM => $pid if $pid }
   my $server_cv;
   my ($stdout, $stderr);
   {
      local %ENV = (
         %ENV,
         PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "",
         XDG_CONFIG_HOME => "$dir/http_config/$cli",
      );
      $server_cv = AnyEvent::Util::run_cmd (
         [$^X, "-Ilib", "bin/mcp-multibroker", @auth_options, ($cli ? ("--bind=127.0.0.1:$port") : ()), child => $command[-1]],
         "<" => "/dev/null", ">" => \$stdout, "2>" => \$stderr, '$$' => \$pid, close_all => 1,
      );
   }
   $server_cv->cb (sub { undef $pid });
   my $http_failures = 0;
   my $http_diag = sub {
      my ($step, $value) = @_;
      ++$http_failures;
      print STDERR "multibroker HTTP cli=$cli $step: ", JSON::XS::encode_json ($value), "\n";
   };
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
   my $preflight_ok = $preflight =~ /HTTP\/1\.1 204/
      && $preflight =~ /^Access-Control-Allow-Origin: \Q$allowed\E\r?$/m;
   ok $preflight_ok, "CORS preflight allows any origin by default";
   $http_diag->("preflight", $preflight) unless $preflight_ok;
   my $web = AnyEvent::MCP::Client::HTTP->new (url => $url);
   ($success, $result) = wait_for (sub { $web->call ("child.echo", { web => 1 }, $_[0]) });
   my $http_ok = $success && $result->{structuredContent}{web};
   ok $http_ok, ($cli ? "CLI bind overrides named bind; cookie URL works" : "named bind works; cookie URL works");
   $http_diag->("cookie", [$success, $result]) unless $http_ok;
   $web->close;
   my ($clean, $token) = $url =~ m{\A(https?://[^/]+/)([^/]+)/\z};
   $web = AnyEvent::MCP::Client::HTTP->new (url => $clean, bearer => $token);
   ($success, $result) = wait_for (sub { $web->call ("child.echo", { bearer => 1 }, $_[0]) });
   $http_ok = $success && $result->{structuredContent}{bearer};
   ok $http_ok, "same token authenticates clean URL as bearer";
   $http_diag->("bearer", [$success, $result]) unless $http_ok;
   $web->close;
   if ($cli) {
      $web = AnyEvent::MCP::Client::HTTP->new (url => $clean, bearer => "upstream-second");
      ($success, $result) = wait_for (sub { $web->call ("child.echo", { alternate => 1 }, $_[0]) });
      $http_ok = $success && $result->{structuredContent}{alternate};
      ok $http_ok, "second upstream --token authenticates";
      $http_diag->("second token", [$success, $result]) unless $http_ok;
      $web->close;
   }
   ok -f "$dir/http_config/$cli/anyevent-mcp/global.ini", "default HTTP startup stores its master secret";
   kill TERM => $pid if $pid;
   my ($ended, $exit) = wait_for (sub {
      my ($done) = @_;
      $server_cv->cb (sub { undef $pid; $done->(1, $_[0]->recv) });
   });
   ok !$stdout, "HTTP broker startup keeps stdout empty";
   print STDERR "multibroker HTTP cli=$cli server exit=$exit stderr: ",
      JSON::XS::encode_json (substr ($stderr // "", 0, 4096)), "\n" if $http_failures;
}
