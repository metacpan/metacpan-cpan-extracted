use common::sense;
use Test::More;
# These tests and their subprocesses connect to private loopback listeners.
BEGIN { delete $ENV{http_proxy} }
use AnyEvent ();
use AnyEvent::MCP::Server::Permissions ();
use AnyEvent::MCP::Permissions::Ask ();
use AnyEvent::MCP::Server::HTTP ();
use AnyEvent::MCP::Server ();
use AnyEvent::MCP::Server::Toolset ();
use AnyEvent::MCP::Client::HTTP ();
use File::Temp ();
use JSON::XS ();

sub wait_for {
   my ($start) = @_;
   my $cv = AnyEvent->condvar;
   my $timer = AnyEvent->timer (after => 30, cb => sub { die "Permission test timeout\n" });
   $start->(sub { $cv->send ([@_]) });
   @{$cv->recv}
}

my $dir = File::Temp::tempdir (CLEANUP => 1);
local $ENV{XDG_CONFIG_HOME} = $dir;
my $graph = { read => [], write => ["read"], all => ["write"] };
sub with_dim {
   my ($request, $name, $value, $choices) = @_;
   +{ %$request, dimensions => {
      %{$request->{dimensions} || {}},
      $name => {
         %{$request->{dimensions}{$name}},
         value => $value,
         choices => defined $choices ? $choices : [{ label => "any", match => "^" }],
      },
   } }
}

my $request = {
   action => "read",
   dimensions => { subject => {
      label => "File", value => "/one/file",
      choices => [
         { label => "file", match => "/one/file" },
         { label => "directory", match => "^/one/" },
      ],
   } },
   sandbox_grants => ["write"], reason => "read the file",
};
my $p = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph);
ok !-e "$dir/anyevent-mcp", "unnamed permissions access no configuration";
ok keys (%{$p->closure (["all"])}) == 3, "capability implication closure";
my $grant = $p->check ($request);
ok $grant->{decision} eq "ask", "default asks";
ok join (",", @{$grant->{request}{sandbox_grant_choices}}) eq "all,read,write", "offered all sandbox_grants";
my $prepared = $grant->{request};
my $decision = AnyEvent::MCP::Permissions::Ask::build ($prepared, {
   decision => "allow-once", sandbox_grants => ["read"],
});
$grant = $p->resolve ($request, { request => $prepared, decision => $decision });
ok $grant->{decision} eq "allow" && join (",", @{$grant->{sandbox_grants}}) eq "read", "reduced one-time grant";
ok $p->check ($request)->{decision} eq "ask", "one-time grant not saved";

my $broader = $p->resolve ($request, { request => $prepared, decision => { decision => "allow-once", sandbox_grants => ["all"] } });
ok join (",", @{$broader->{sandbox_grants}}) eq "write", "broad selection cannot enlarge current grant";
eval { $p->resolve ($request, { request => { %$prepared, reason => "different" }, decision => $decision }) };
ok $@ =~ /does not match/, "approval bound to exact prepared request";
eval { $p->check (with_dim ($request, "subject", "/one/file", [{ label => "other", match => "/other" }])) };
ok $@ =~ /scope does not match/, "offered scope must cover request";

my $default_request = {
   %$request,
   dimensions => { subject => {
      %{$request->{dimensions}{subject}},
      default => "^/one/",
   } },
};
my $default_prepared = $p->check ($default_request)->{request};
my $default_schema = AnyEvent::MCP::Permissions::Ask::schema ($default_prepared, "rule",
   { decision => "allow-always" });
is $default_schema->{properties}{dim_subject}{default}, "^/one/",
   "permission dimension advertises a default matcher independent of choice order";
is +(AnyEvent::MCP::Permissions::Ask::schema ($prepared, "rule",
   { decision => "allow-always" }))->{properties}{dim_subject}{default}, "/one/file",
   "without explicit default the first dimension choice stays selected";
for my $bad ("/not-offered", undef, [], "") {
   my $invalid = { %$default_request, dimensions => { subject => {
      %{$default_request->{dimensions}{subject}}, default => $bad,
   } } };
   eval { $p->check ($invalid) };
   like $@, qr/default was not offered/, "reject invalid dimension default";
}

# One obsolete saved rule invalidates the entire policy, without aborting checks.
my $bad_file = "$dir/bad-rules.ini";
my $file_perm = AnyEvent::MCP::Server::Permissions->new (file => $bad_file, sandbox_grants => $graph);
my $write_bad = sub {
   open my $fh, ">:raw", $bad_file or die $!;
   print {$fh} $_[0];
   close $fh or die $!;
};
$write_bad->("[rule]\ndecision=allow\naction=read\nsandbox-grants=write\n\n"
   . "[rule]\ndecision=deny\naction=^\nsubject=/old\n");
is_deeply $file_perm->rules, [], "one obsolete rule invalidates the entire saved policy";
is $file_perm->check ($request)->{decision}, "ask",
   "no earlier allow rule survives the invalid ruleset";
{
   open my $fh, "<:raw", $bad_file or die $!;
   my $raw = do { local $/; <$fh> };
   close $fh;
   like $raw, qr/^subject=\/old$/m, "invalid read preserves original file";
}
$write_bad->("[rule]\ndecision=deny\naction=^\n\n"
   . "[rule]\ndecision=allow\naction=read\nmatch.subject=^[\nsandbox-grants=write\n");
is_deeply $file_perm->rules, [], "invalid matcher discards all saved rules";
$write_bad->("[rule]\ndecision=deny\naction=^\n\n[unexpected]\naction=read\n");
is_deeply $file_perm->rules, [], "invalid INI section discards all saved rules";
$write_bad->("[rule]\ndecision=deny\naction=^\n\n"
   . "[rule]\ndecision=allow\naction=read\nexpires=bad\nsandbox-grants=write\n");
is_deeply $file_perm->rules, [], "invalid expiry discards all saved rules";
my $bad_prepared = $file_perm->check ($request)->{request};
my $bad_answer = AnyEvent::MCP::Permissions::Ask::build ($bad_prepared, {
   decision => "allow-always", sandbox_grants => ["write"], dim_subject => "/one/file",
});
$file_perm->resolve ($request, { request => $bad_prepared, decision => $bad_answer });
is $file_perm->check ($request)->{decision}, "allow",
   "normal approval replaces invalid saved rules";
is_deeply $file_perm->rules, [$bad_answer->{rule}],
   "new save silently discards previous invalid rules";

$p->save ([
   { decision => "allow", action => "read", "match.subject" => "/one/file", "sandbox-grants" => "all" },
   { decision => "deny", action => "^" },
]);
ok $p->check ($request)->{decision} eq "allow", "first matching allowance wins";
ok $p->check ({ %$request, action => "other" })->{decision} eq "deny", "blanket denial";
$p->save ([
   { decision => "deny", action => "^" },
   { decision => "allow", action => "read", "sandbox-grants" => "all" },
]);
ok $p->check ($request)->{decision} eq "deny", "earlier denial wins";
$p->save ([{ decision => "ask", action => "^" }, { decision => "deny", action => "^" }]);
ok $p->check ($request)->{decision} eq "ask", "ordered ask overrides later denial";

$p = AnyEvent::MCP::Server::Permissions->new (name => "example", sandbox_grants => $graph);
$prepared = $p->check ($request)->{request};
$decision = AnyEvent::MCP::Permissions::Ask::build ($prepared, {
   decision => "allow-always", sandbox_grants => ["write"], dim_subject => "^/one/",
});
$p->resolve ($request, { request => $prepared, decision => $decision });
ok -f $p->{file} && !((stat $p->{file})[2] & 077), "private persistent rule file";
ok !-e "$p->{file}.lock", "permission persistence uses no separate lock file";
chmod 0666, $p->{file} or die $!;
ok $p->check ($request)->{decision} eq "allow", "user-selected rule permissions are accepted";
ok $p->check (with_dim ($request, "subject", "/one/other"))->{decision} eq "allow", "offered broad scope persisted";
ok $p->check (with_dim ($request, "subject", "/two/file", []))->{decision} eq "ask", "persistent scope does not expand";
my $deny_request = { %$request, action => "other" };
$prepared = $p->check ($deny_request)->{request};
$decision = AnyEvent::MCP::Permissions::Ask::build ($prepared, {
   decision => "deny-always", dim_subject => "/one/file",
});
$p->resolve ($deny_request, { request => $prepared, decision => $decision });
is +((stat $p->{file})[2] & 0777), 0666, "rule saves preserve the existing mode";
ok $p->check ($deny_request)->{decision} eq "deny", "persistent denial";
$p->save ([]);
$prepared = $p->check ($request)->{request};
$p->save ([{ decision => "deny", action => "^" }]);
ok $p->resolve ($request, { request => $prepared, decision => { decision => "allow-once", sandbox_grants => ["write"] } })->{decision} eq "deny",
   "policy change supersedes pending answer";

$p->save ([]);
$prepared = $p->check ($request)->{request};
my $decline = AnyEvent::MCP::Permissions::Ask::decision ($prepared, { action => "decline" });
ok $decline->{decision} eq "deny-once", "elicitation decline means denial";
my $broader_form = AnyEvent::MCP::Permissions::Ask::decision ($prepared, {
   action => "accept", content => { decision => "allow-once", sandbox_grants => "all" },
});
ok $broader_form->{sandbox_grants}[0] eq "all", "form can select broader future allowance";
my $schema = AnyEvent::MCP::Permissions::Ask::schema ($prepared);
my $rule_schema = AnyEvent::MCP::Permissions::Ask::schema ($prepared, "rule", {
   decision => "allow-always",
});
ok !exists $schema->{properties}{subject}
   && !exists $schema->{properties}{sandbox_grants}
   && $schema->{properties}{message}
   && $rule_schema->{properties}{dim_subject}{enum}[1] eq "^/one/",
   "only rule stage exposes persistent scope and editable grants";

my ($success, $result);
my $helper = AnyEvent::MCP::Permissions::Ask->new (helper => [$^X, "-e", '
   local $/; my $request = <STDIN>;
   print qq({"decision":"deny-once"});
']);
($success, $result) = wait_for (sub { $helper->ask ($prepared, $_[0]) });
ok $success && $result->{decision} eq "deny-once", "external helper JSON exchange";
$helper = AnyEvent::MCP::Permissions::Ask->new (helper => [$^X, "-e", 'local $/; scalar <STDIN>; print "garbage"']);
($success, $result) = wait_for (sub { $helper->ask ($prepared, $_[0]) });
ok !$success && $result =~ /Invalid.*JSON/, "malformed helper response rejected";
$helper = AnyEvent::MCP::Permissions::Ask->new (helper => [$^X, "-e", 'sleep 30'], timeout => 0.02);
($success, $result) = wait_for (sub { $helper->ask ($prepared, $_[0]) });
ok !$success && $result =~ /timed out/, "helper deadline";
$helper = AnyEvent::MCP::Permissions::Ask->new (helper => [$^X, "-e", 'local $/; scalar <STDIN>; print "x" x 100'], max_size => 10);
($success, $result) = wait_for (sub { $helper->ask ($prepared, $_[0]) });
ok !$success && $result =~ /size limit/, "helper output bounded";

$p = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph, ask => "mcp");
my ($effects, $prompts, $captured_state);
my $server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_call => sub {
   my ($server, $req, $args) = @_;
   $p->require ($req, {
      action => $req->{tool}, sandbox_grants => ["write"], reason => "change value",
   }, sub {
      my ($success, $grant) = @_;
      return $req->error ($grant) unless $success;
      ++$effects;
      $req->result ({ sandbox_grants => $grant, value => $args->{value} });
   });
});
$server->listen;
my $client = AnyEvent::MCP::Client::HTTP->new (
   url => $server->url, client_capabilities => { elicitation => { form => {} } },
   on_request => sub {
      ++$prompts;
      $_[1]->reply ({ action => "accept", content => { decision => "allow-once", sandbox_grants => "read" } });
   },
);
($success, $result) = wait_for (sub { $client->call (change => { value => 42 }, $_[0]) });
ok $success && $result->{structuredContent}{value} == 42 && $effects == 1, "MCP permission continuation executes once";
ok $prompts == 1 && $result->{structuredContent}{sandbox_grants}[0] eq "read", "MCP grant reduction reaches tool";

$client->{on_request} = sub { ++$prompts; $_[1]->reply ({ action => "decline" }) };
($success, $result) = wait_for (sub { $client->call (change => {}, $_[0]) });
ok $success && $result->{isError} && $effects == 1, "MCP decline denies without executing";

($success, $result) = wait_for (sub { $client->rpc ("tools/call", { name => "change", arguments => { value => 7 } }, $_[0]) });
$captured_state = $result->{requestState};
ok $success && $result->{resultType} eq "input_required", "raw call exposes permission challenge";
my $continuation = {
   name => "change", arguments => { value => 8 }, requestState => $captured_state,
   inputResponses => { permission => { action => "accept", content => { decision => "allow-once", sandbox_grants => "write" } } },
};
($success, $result) = wait_for (sub { $client->rpc ("tools/call", $continuation, $_[0]) });
ok $success && $result->{isError} && $effects == 1, "permission state cannot approve changed arguments";
$continuation->{arguments}{value} = 7;
($success, $result) = wait_for (sub { $client->rpc ("tools/call", $continuation, $_[0]) });
ok $result->{isError} && $effects == 1, "consumed state cannot be replayed";

$client->close;
$server->close;
my $local_asks = 0;
$p = AnyEvent::MCP::Server::Permissions->new (
   sandbox_grants => $graph, ask => sub { ++$local_asks; $_[1]->(1, { decision => "allow-once", sandbox_grants => ["read"] }) },
);
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_call => sub {
   my ($server, $req) = @_;
   $p->require ($req, { action => "read", sandbox_grants => ["read"], reason => "read" }, sub {
      $_[0] ? $req->result ({ allowed => 1 }) : $req->error ($_[1]);
   });
});
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (url => $server->url);
($success, $result) = wait_for (sub { $client->call (read => {}, $_[0]) });
ok $success && $result->{structuredContent}{allowed} && $local_asks == 1, "pluggable asynchronous asking callback";
$client->close;
$server->close;

$p = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph, ask => "auto", helper => [$^X, "-e", '
   local $/; scalar <STDIN>; print qq({"decision":"allow-once","sandbox_grants":["read"]});
']);
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", versions => ["2025-06-18"], on_tools_call => sub {
   my ($server, $req) = @_;
   $p->require ($req, { action => "read", sandbox_grants => ["read"], reason => "read" }, sub {
      $_[0] ? $req->result ({ allowed => 1 }) : $req->error ($_[1]);
   });
});
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (url => $server->url);
($success, $result) = wait_for (sub { $client->call (read => {}, $_[0]) });
ok $success && $result->{structuredContent}{allowed}, "legacy request falls back to helper";
$client->close;
$server->close;

# Validate every stored rule, including rules after a matching denial.
$p = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph);
$p->{rules} = [{ decision => "deny", action => "^" }, { decision => "allow", action => "read", "sandbox-grants" => "bad" }];
eval { $p->check ($request) };
ok $@ =~ /Unknown/, "invalid later rule is not hidden";
$p->{rules} = [{ action => "read", "sandbox-grants" => "write" }];
eval { $p->check ($request) };
ok $@ =~ /decision/, "rule without decision is rejected before release";
$p->{rules} = [{ decision => "allow", action => "read", "sandbox-grants" => "write" }];
ok $p->check ($request)->{decision} eq "allow", "explicit decision and action permit the grant";
$p->{rules} = [];
$prepared = $p->check ($request)->{request};
eval { AnyEvent::MCP::Permissions::Ask::build ($prepared, { decision => "allow-always", sandbox_grants => ["read"], dim_subject => "^/" }) };
ok $@ =~ /not offered/, "unoffered persistent scope rejected";
my $valid_scope = AnyEvent::MCP::Permissions::Ask::build ($prepared, {
   decision => "allow-always", sandbox_grants => ["write"], dim_subject => "/one/file",
});
eval { $p->resolve ($request, { request => $prepared,
   decision => { %$valid_scope, rule => { %{$valid_scope->{rule}}, unrelated => "surprise" } },
}) };
ok $@ =~ /Invalid persistent permission rule/ && !@{$p->rules},
   "unexpected persistent rule fields cannot introduce additional authority";
$p->{sandbox_grants}{read} = ["write"];
ok keys (%{$p->closure (["read"])}) == 2, "cyclic implications terminate";

# Route a modern permission request to a client-side external prompt.
my $prompt_runs = 0;
$p = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph, ask => "mcp");
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_call => sub {
   my ($server, $req) = @_;
   $p->require ($req, { action => "read", sandbox_grants => ["read"], reason => "read" }, sub {
      $_[0] ? $req->result ({ allowed => 1 }) : $req->error ($_[1]);
   });
});
$server->listen;
$client = AnyEvent::MCP::Client::HTTP->new (
   url => $server->url, client_capabilities => { elicitation => { form => {} } },
   on_request => sub {
      ++$prompt_runs;
      AnyEvent::MCP::Permissions::Ask->elicitation ($_[1], helper => [$^X, "-e", '
         local $/; scalar <STDIN>;
         print qq({"decision":"allow-once","sandbox_grants":["read"]});
      ']);
   },
);
($success, $result) = wait_for (sub { $client->call (read => {}, $_[0]) });
ok $success && $result->{structuredContent}{allowed} && $prompt_runs == 1, "client helper answers MCP permission prompt";
$client->close;
$server->close;

# Cancellation ends a running local helper and calls completion only once.
$helper = AnyEvent::MCP::Permissions::Ask->new (helper => [$^X, "-e", 'sleep 30']);
my $completions = 0;
$helper->ask ($prepared, sub { ++$completions; ($success, $result) = @_ });
$helper->cancel;
$helper->cancel;
ok !$success && $result =~ /cancelled/ && $completions == 1, "helper cancellation completes once";

SKIP: {
   skip "extended helper descendant test (PERL_ANYEVENT_MCP_TESTS=1)", 1 unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;

   # A reaped parent may leave a descendant holding stdout open.
   $helper = AnyEvent::MCP::Permissions::Ask->new (timeout => 0.05, helper => [$^X, "-e", '
      local $/; scalar <STDIN>;
      if (!fork) { sleep 1; exit }
      exit;
   ']);
   ($success, $result) = wait_for (sub { $helper->ask ($prepared, $_[0]) });
   ok !$success && $result =~ /timed out/ && !$helper->{pid}, "reaped helper PID is not retained while output remains open";

}

# Two processes append different grants without losing either update.
my $file = "$dir/concurrent.ini";
my $shared = AnyEvent::MCP::Server::Permissions->new (file => $file, sandbox_grants => { read => [] });
my @children;
for my $tool (qw(one two)) {
   my $request = { action => $tool, sandbox_grants => ["read"], reason => $tool };
   my $prepared = $shared->check ($request)->{request};
   my $pid = fork;
   die $! unless defined $pid;
   if (!$pid) {
      $shared->resolve ($request, {
         request => $prepared,
         decision => { decision => "allow-always", sandbox_grants => ["read"],
            rule => { decision => "allow", action => $tool, "sandbox-grants" => "read" } },
      });
      exit 0;
   }
   push @children, $pid;
}
my $statuses = 0;
for my $pid (@children) {
   waitpid $pid, 0;
   $statuses ||= $?;
}
ok !$statuses && @{$shared->rules} == 2, "locked concurrent persistence keeps both rules";
ok $shared->check ({ action => "one", sandbox_grants => ["read"], reason => "one" })->{decision} eq "allow"
   && $shared->check ({ action => "two", sandbox_grants => ["read"], reason => "two" })->{decision} eq "allow",
   "both concurrent grants usable";

# Workdir identity is just another dimension.
my $wperm = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph);
my $raw_workdir = "/projects/../projects/a";
my $wreq = { action => "read", sandbox_grants => ["read"], reason => "selected workdir",
   dimensions => { workdir => { label => "Workdir", value => $raw_workdir,
      choices => [
         { label => "This workdir", match => $raw_workdir },
         { label => "Any workdir", match => "^" },
      ],
   } },
};
$wperm->save ([{ decision => "allow", action => "read",
   "match.workdir" => $raw_workdir, "sandbox-grants" => "read" }]);
is $wperm->check ($wreq)->{decision}, "allow", "selected workdir matches";
is $wperm->check (with_dim ($wreq, "workdir", "/projects/b"))->{decision}, "ask",
   "other workdir does not match";
my %unscoped = (%$wreq, dimensions => {});
is $wperm->check (\%unscoped)->{decision}, "ask", "missing workdir does not match";
$wperm->save ([]);
my $wprepared = $wperm->check ($wreq)->{request};
my $workdir_form = AnyEvent::MCP::Permissions::Ask::schema ($wprepared, "rule",
   { decision => "allow-always" });
is_deeply $workdir_form->{properties}{dim_workdir}{enum}, [$raw_workdir, "^"],
   "native form advertises workdir matcher choices";
my $wdecision = AnyEvent::MCP::Permissions::Ask::build ($wprepared, {
   decision => "allow-always", sandbox_grants => ["read"], dim_workdir => "^",
});
is $wdecision->{rule}{"match.workdir"}, "^", "any workdir is explicit matcher";
$wperm->resolve ($wreq, { request => $wprepared, decision => $wdecision });
is $wperm->check (with_dim ($wreq, "workdir", "/projects/future"))->{decision}, "allow",
   "any-workdir matcher includes future workdirs";
{
   local $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS} = "second-fs";
   $wperm->save ([]);
   my $alias_request = $wperm->check ($wreq)->{request};
   is $alias_request->{multibroker_alias}, "second-fs", "alias included in permission display";
}
# Independent origin and subject dimensions share one matching mechanism.
my $origin_perm = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph);
my $origin_req = {
   action => "exec", sandbox_grants => [], reason => "execute browser code",
   dimensions => {
      subject => { label => "Code", value => 'execute:"tab":"code"',
         choices => [{ label => "this code", match => 'execute:"tab":"code"' }] },
      origin => { label => "Origin", value => "https://example.com:8443",
         choices => [
            { label => "exact", match => "https://example.com:8443" },
            { label => "any port", match => '^https:\/\/example\.com(?::[0-9]+)?\z' },
            { label => "any origin", match => "^" },
         ] },
   },
};
my $origin_prepared = $origin_perm->check ($origin_req)->{request};
my $origin_schema = AnyEvent::MCP::Permissions::Ask::schema ($origin_prepared, "rule",
   { decision => "allow-always" });
is_deeply $origin_schema->{properties}{dim_origin}{enum},
   [map $_->{match}, @{$origin_req->{dimensions}{origin}{choices}}],
   "native rule editor exposes origin scopes";
my $origin_decision = AnyEvent::MCP::Permissions::Ask::build ($origin_prepared, {
   decision => "allow-always", sandbox_grants => [],
   dim_subject => $origin_req->{dimensions}{subject}{value},
   dim_origin => $origin_req->{dimensions}{origin}{value},
});
$origin_perm->resolve ($origin_req, { request => $origin_prepared, decision => $origin_decision });
is $origin_perm->check ($origin_req)->{decision}, "allow", "exact origin rule matches";
is $origin_perm->check (with_dim ($origin_req, "origin", "https://example.com:9443"))->{decision}, "ask",
   "exact origin does not cover another port";
is $origin_perm->check (with_dim ($origin_req, "subject", "other"))->{decision}, "ask",
   "origin permission cannot bypass subject identity";
$origin_perm->save ([]);
$origin_prepared = $origin_perm->check ($origin_req)->{request};
$origin_decision = AnyEvent::MCP::Permissions::Ask::decision ($origin_prepared, {
   action => "accept", content => {
      decision => "allow-always", sandbox_grants => "",
      dim_subject => $origin_req->{dimensions}{subject}{value},
      dim_origin => $origin_req->{dimensions}{origin}{choices}[1]{match},
   },
}, "rule", { decision => "allow-always" });
$origin_perm->resolve ($origin_req, { request => $origin_prepared, decision => $origin_decision });
is $origin_perm->check (with_dim ($origin_req, "origin", "https://example.com:9443"))->{decision},
   "allow", "any-port origin scope allows another port";
is $origin_perm->check (with_dim ($origin_req, "origin", "http://example.com:8443"))->{decision},
   "ask", "any-port scope preserves scheme";
$origin_perm->save ([]);
eval { AnyEvent::MCP::Permissions::Ask::build ($origin_prepared, {
   decision => "allow-always", sandbox_grants => [],
   dim_subject => $origin_req->{dimensions}{subject}{value}, dim_origin => "https://other.example",
}) };
like $@, qr/scope was not offered/, "forged origin scope rejected";
$origin_perm->save ([{ decision => "allow", action => "exec", "sandbox-grants" => "" }]);
is $origin_perm->check ($origin_req)->{decision}, "allow", "explicit unscoped manual rule matches";

# Exercise the native MCP elicitation path with an external permission helper.
# Both the helper's rule and the relayed MCP response must retain origin.
my $relay_perm = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph, ask => "mcp");
$server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_call => sub {
   my ($server, $req) = @_;
   $relay_perm->require ($req, $origin_req, sub {
      $_[0] ? $req->result ({ allowed => 1 }) : $req->error ($_[1]);
   });
});
$server->listen;
my $relay_forms = 0;
$client = AnyEvent::MCP::Client::HTTP->new (
   url => $server->url, client_capabilities => { elicitation => { form => {} } },
   on_request => sub {
      ++$relay_forms;
      AnyEvent::MCP::Permissions::Ask->elicitation ($_[1], helper => [
         $^X, "-Ilib", "-MJSON::XS", "-MAnyEvent::MCP::Permissions::Ask", "-e", '
            my $request = JSON::XS::decode_json (do { local $/; <STDIN> });
            my $result = $request->{_permission_stage} eq "rule"
               ? AnyEvent::MCP::Permissions::Ask::build ($request, {
                    decision => "allow-always", sandbox_grants => [],
                    dim_subject => $request->{dimensions}{subject}{choices}[0]{match},
                    dim_origin => $request->{dimensions}{origin}{choices}[0]{match},
                 }, "rule", $request->{_permission_selection})
               : { decision => "allow-always" };
            print JSON::XS::encode_json $result;
         ',
      ]);
   },
);
($success, $result) = wait_for (sub { $client->call (execute => {}, $_[0]) });
ok $success && $result->{structuredContent}{allowed} && $relay_forms == 2,
   "external helper completes both MCP permission forms with origin scope";
is $relay_perm->rules->[0]{"match.origin"}, $origin_req->{dimensions}{origin}{value},
   "helper-selected origin survives native elicitation and is persisted";
is $relay_perm->check ({
   %{with_dim ($origin_req, "origin", "https://other.example")},
})->{decision}, "ask", "relayed origin rule cannot authorize another origin";
$client->close;
$server->close;

# A dimension with a name unknown to the engine works without special cases.
my $custom_perm = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph);
my $custom_req = {
   action => "read", sandbox_grants => [], reason => "custom resource",
   dimensions => { tenant => {
      label => "Tenant", value => "acme",
      choices => [
         { label => "This tenant", match => "acme" },
         { label => "Any tenant", match => "^" },
      ],
   } },
};
my $custom_prepared = $custom_perm->check ($custom_req)->{request};
my $custom_schema = AnyEvent::MCP::Permissions::Ask::schema ($custom_prepared,
   "rule", { decision => "allow-always" });
is_deeply $custom_schema->{properties}{dim_tenant}{enum}, ["acme", "^"],
   "unknown named dimension appears automatically in native rule editor";
my $custom_decision = AnyEvent::MCP::Permissions::Ask::build ($custom_prepared, {
   decision => "allow-always", sandbox_grants => [], dim_tenant => "acme",
});
$custom_perm->resolve ($custom_req, { request => $custom_prepared, decision => $custom_decision });
is $custom_perm->rules->[0]{"match.tenant"}, "acme",
   "unknown dimension matcher persists under generic rule key";
is $custom_perm->check (with_dim ($custom_req, "tenant", "other"))->{decision}, "ask",
   "saved arbitrary dimension cannot authorize another identity";
eval { $custom_perm->check ({ %$custom_req, subject => "old field" }) };
like $@, qr/Obsolete permission request scope/, "obsolete request scope fails closed";
eval { $custom_perm->check ({ %$custom_req, dimensions => { tenant => {
   label => "Tenant", value => "acme", choices => [{ label => "wrong", match => "other" }],
} } }) };
like $@, qr/scope does not match/, "unmatched arbitrary dimension choice rejected";

# Human permission messages work on allows and denies.
my $reason_perm = AnyEvent::MCP::Server::Permissions->new (
   name => "reasoned-denial", sandbox_grants => $graph,
);
my $reason_req = {
   action => "read", paths => ["/root/SCHMORP-PERL.md"],
   sandbox_grants => ["read"], reason => "read the file",
};
my $reason_prepared = $reason_perm->check ($reason_req)->{request};
my $intermediate = AnyEvent::MCP::Permissions::Ask::decision ($reason_prepared, {
   action => "accept", content => { decision => "deny-always", message => "Use the Vim buffer instead" },
}, "choice");
ok $intermediate->{decision} eq "deny-always"
   && $intermediate->{message} eq "Use the Vim buffer instead",
   "first native MCP form records message and selects rule editing";
my $reason_schema = AnyEvent::MCP::Permissions::Ask::schema ($reason_prepared, "rule", $intermediate);
ok +($reason_schema->{properties}{path}{default} eq "/root/SCHMORP-PERL.md"
   && (grep $_ eq "back", @{$reason_schema->{properties}{decision}{enum}})),
   "rule form offers exact-file scope and Back";
my $reason_decision = AnyEvent::MCP::Permissions::Ask::decision ($reason_prepared, {
   action => "accept", content => {
      decision => "deny-always", path => "/root/SCHMORP-PERL.md",
   },
}, "rule", $intermediate);
$grant = $reason_perm->resolve ($reason_req, {
   request => $reason_prepared, decision => $reason_decision,
});
ok $grant->{decision} eq "deny" && $grant->{message} eq "Use the Vim buffer instead",
   "denial returns user-provided message immediately";
ok $reason_perm->rules->[0]{path} eq "/root/SCHMORP-PERL.md"
   && $reason_perm->rules->[0]{message} eq "Use the Vim buffer instead",
   "persistent deny stores exact path and message";
my $reopened = AnyEvent::MCP::Server::Permissions->new (
   name => "reasoned-denial", sandbox_grants => $graph,
);
$grant = $reopened->check ($reason_req);
ok $grant->{decision} eq "deny" && $grant->{message} eq "Use the Vim buffer instead",
   "later model instances receive persisted denial message";
ok $reopened->check ({ %$reason_req, paths => ["/root/another-file"] })->{decision} eq "ask",
   "exact-file denial does not broaden to neighboring filenames";
ok $reopened->check ({ %$reason_req, sandbox_grants => ["write"],
   paths => ["/root/SCHMORP-PERL.md", "/root/another-file"] })->{decision} eq "deny",
   "exact-file denial still applies to multi-path requests needing broader grants";
eval { $reopened->require_permission ({}, $reason_req) };
ok $@ =~ /Permission denied: Use the Vim buffer instead/,
   "synchronous tool errors expose persisted denial message";
eval { AnyEvent::MCP::Permissions::Ask::build ($reason_prepared, {
   decision => "deny-always", path => "/root/another-file",
}) };
ok $@ =~ /Unrequested denial path/, "persistent path scope must be requested";

my $allowed_with_reason = AnyEvent::MCP::Permissions::Ask::decision ($reason_prepared, {
   action => "accept", content => { decision => "allow-once", message => "Should not be attached" },
}, "choice");
ok $allowed_with_reason->{decision} eq "allow-once"
   && !exists $allowed_with_reason->{message},
   "approval ignores the denial-only message from form answers";


{
   local $ENV{PERL_ANYEVENT_MCP_PERMISSION_ASK} = "auto";
   my $p = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph);
   ok $p->{ask} eq "auto", "environment defaults generic permission prompting to auto";
   $p = AnyEvent::MCP::Server::Permissions->new (ask => "helper", sandbox_grants => $graph);
   ok $p->{ask} eq "helper", "explicit ask overrides generic environment default";
   $p = AnyEvent::MCP::Server::Permissions->new (ask => sub {}, sandbox_grants => $graph);
   ok ref $p->{ask} eq "CODE", "custom asking callback overrides generic environment mode";
}
{
   local $ENV{PERL_ANYEVENT_MCP_PERMISSION_ASK} = "invalid";
   eval { AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph) };
   ok $@ =~ /Invalid permission ask mode/, "invalid permission ask environment fails promptly";
}
{
   local $ENV{PERL_ANYEVENT_MCP_PERMISSION_ASK} = "";
   my $p = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph);
   ok $p->{ask} eq "helper", "empty environment leaves local helper as default";
}

{
   mkdir "$dir/modes" or die $!;
   open my $fh, ">", "$dir/modes/anyevent-mcp-askpermission" or die $!;
   print {$fh} "#!$^X\n", q{
use common::sense;
use JSON::XS ();
local $/;
my $request = JSON::XS::decode_json <STDIN>;
open my $log, ">", "$ENV{MCP_TEST_PERMISSION_MODE_LOG}" or die $!;
print {$log} JSON::XS::encode_json (\@ARGV);
close $log or die $!;
print JSON::XS::encode_json { decision => "allow-once", sandbox_grants => $request->{sandbox_grants} };
};
   close $fh or die $!;
   chmod 0700, "$dir/modes/anyevent-mcp-askpermission" or die $!;
   local $ENV{PATH} = "$dir/modes:$ENV{PATH}";
   local $ENV{MCP_TEST_PERMISSION_MODE_LOG} = "$dir/mode-log";
   local $ENV{PERL_ANYEVENT_MCP_PERMISSION_HELPER} = "$dir/not-a-custom-helper";

   for my $mode (qw(tty yad)) {
      my $permissions = AnyEvent::MCP::Server::Permissions->new (ask => $mode, sandbox_grants => { read => [] });
      my $server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_call => sub {
         my ($server, $req) = @_;
         $permissions->require ($req, { action => "read", sandbox_grants => ["read"], reason => "test explicit prompt mode" }, sub {
            $_[0] ? $req->result ({ allowed => 1 }) : $req->error ($_[1]);
         });
      });
      $server->listen;
      my $client = AnyEvent::MCP::Client::HTTP->new (url => $server->url);
      my ($success, $result) = wait_for (sub { $client->call (read => {}, $_[0]) });
      ok $success && $result->{structuredContent}{allowed}, "$mode permission mode uses the built-in helper";
      open my $log, "<", "$dir/mode-log" or die $!;
      my $argv = JSON::XS::decode_json do { local $/; <$log> };
      close $log;
      is_deeply $argv, ["--$mode"], "$mode permission mode forces its interface and bypasses the custom helper";
      $client->close;
      $server->close;
   }
}


# Expiry is filtered on each read; disk cleanup waits for an ordinary save.
{
   my $permissions = AnyEvent::MCP::Server::Permissions->new (
      name => "expiry", sandbox_grants => $graph,
   );
   my $now = time;
   my $future = $now + 86400;
   my @rules = (
      { decision => "deny", action => "^", expires => 0 },
      { decision => "ask", action => "^", expires => $now },
      { decision => "allow", action => "read", "sandbox-grants" => "write", expires => $future },
      { decision => "deny", action => "^" },
   );
   $permissions->save (\@rules);
   is_deeply $permissions->rules, [@rules[2, 3]], "reads omit expired allow/deny/ask rules, including expires=now";
   is $permissions->check ($request)->{decision}, "allow", "expired denials and asks do not hide a later allowance";
   open my $fh, "<", $permissions->{file} or die $!;
   my $raw = do { local $/; <$fh> };
   close $fh or die $!;
   like $raw, qr/^expires=0$/m, "reading rules does not rewrite the file";

   my $reopened = AnyEvent::MCP::Server::Permissions->new (
      name => "expiry", sandbox_grants => $graph,
   );
   is_deeply $reopened->rules, [@rules[2, 3]], "expiry timestamp survives a new permission engine";
   $permissions->save ([{ %{$rules[2]}, expires => 0 }, $rules[3]]);
   is $reopened->check ($request)->{decision}, "deny", "next check rereads and skips an expired allowance";
   $permissions->save ($permissions->rules);
   open $fh, "<", $permissions->{file} or die $!;
   $raw = do { local $/; <$fh> };
   close $fh or die $!;
   unlike $raw, qr/^expires=/m, "ordinary save removes expired rules from disk";

   my $memory = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph, rules => \@rules);
   is_deeply $memory->rules, [@rules[2, 3]], "in-memory rules use the same expiry filtering";
   for my $bad (undef, "", "-1", "1.5", "tomorrow", []) {
      $memory->{rules} = [{ decision => "deny", action => "^", expires => $bad }];
      eval { $memory->rules };
      like $@, qr/Invalid permission rule expiry/, "invalid expiry is rejected on read";
   }

   my $schema = AnyEvent::MCP::Permissions::Ask::schema ($prepared, "rule", { decision => "allow-always" });
   is_deeply $schema->{properties}{lifetime}{enum}, ["indefinite", "900", "57600"],
      "native rule form offers the three agreed lifetimes";
   is $schema->{properties}{lifetime}{default}, "indefinite", "native lifetime defaults to indefinite";
   ok !exists AnyEvent::MCP::Permissions::Ask::schema ($prepared)->{properties}{lifetime},
      "initial decision form does not offer rule lifetime";

   for my $choice (qw(allow-always deny-always)) {
      for my $lifetime ("indefinite", "900", "57600") {
         $permissions->save ([]);
         my $prepared = $permissions->check ($request)->{request};
         my $before = time;
         my $decision = AnyEvent::MCP::Permissions::Ask::decision ($prepared, {
            action => "accept", content => {
               decision => $choice, sandbox_grants => "write", dim_subject => "/one/file", lifetime => $lifetime,
            },
         }, "rule", { decision => $choice });
         $permissions->resolve ($request, { request => $prepared, decision => $decision });
         my $saved = $permissions->rules->[0];
         if ($lifetime eq "indefinite") {
            ok !exists $saved->{expires}, "$choice indefinite rule omits expires";
         } else {
            ok $saved->{expires} >= $before + $lifetime && $saved->{expires} <= time + $lifetime,
               "$choice persists $lifetime seconds as an absolute Unix timestamp";
         }
      }
   }
   for my $bad ("", "3600", "forever", []) {
      eval { AnyEvent::MCP::Permissions::Ask::build ($prepared, {
         decision => "deny-always", dim_subject => "/one/file", lifetime => $bad,
      }) };
      like $@, qr/Invalid permission rule lifetime/, "unoffered lifetime is rejected";
   }
}

# A local helper answering a native rule form must retain its selected lifetime.
{
   my $permissions = AnyEvent::MCP::Server::Permissions->new (sandbox_grants => $graph, ask => "mcp");
   my $server = AnyEvent::MCP::Server::HTTP->new (auth => "none", on_tools_call => sub {
      my ($server, $req) = @_;
      $permissions->require ($req, { action => "read", sandbox_grants => ["read"], reason => "temporary read" }, sub {
         $_[0] ? $req->result ({ allowed => 1 }) : $req->error ($_[1]);
      });
   });
   $server->listen;
   my $client = AnyEvent::MCP::Client::HTTP->new (
      url => $server->url, client_capabilities => { elicitation => { form => {} } },
      on_request => sub {
         AnyEvent::MCP::Permissions::Ask->elicitation ($_[1], helper => [$^X, "-Ilib", "-e", '
            use JSON::XS ();
            use AnyEvent::MCP::Permissions::Ask ();
            local $/;
            my $request = JSON::XS::decode_json <STDIN>;
            print JSON::XS::encode_json (AnyEvent::MCP::Permissions::Ask::build ($request, {
               decision => "allow-always", sandbox_grants => ["read"], lifetime => "57600",
            }, $request->{_permission_stage}, $request->{_permission_selection}));
         ']);
      },
   );
   my $before = time;
   my ($success, $result) = wait_for (sub { $client->call (read => {}, $_[0]) });
   ok $success && $result->{structuredContent}{allowed}, "native staged permission succeeds through local helper";
   ok $permissions->rules->[0]{expires} >= $before + 57600
      && $permissions->rules->[0]{expires} <= time + 57600,
      "native helper forwarding retains the selected 16-hour lifetime";
   $client->close;
   $server->close;
}

# Ordered command-line rules match dispatched tool, action and grant closure.
# They precede saved rules but do not bypass the permission checks themselves.
{
   my $perm = AnyEvent::MCP::Server::Permissions->new (
      sandbox_grants => $graph,
      auto_rules => [
         ["deny", "read-lines,write,read"],
         ["allow", "read_lines,read,write"],
         ["deny", "unchecked"],
         ["allow", "*,inspect,*"],
      ],
      rules => [{ decision => "deny", action => "^" }],
   );
   my $call = { action => "read", tool => "unchecked", sandbox_grants => ["write"], reason => "test" };
   is_deeply $perm->check ($call, "read-lines"),
      { decision => "allow", sandbox_grants => ["write"] },
      "auto allow uses the dispatched tool, normalizes underscores, and overrides saved deny";
   is $perm->check ($call, "read_lines")->{decision}, "allow",
      "underscored dispatched names match too";
   is $perm->check ({ %$call, action => "write" }, "read-lines")->{decision}, "deny",
      "earlier matching deny wins for an action and implied read grant";
   is $perm->check ($call, "unchecked")->{decision}, "deny",
      "auto deny uses actual tool, not the request-supplied display label";
   is $perm->check ($call, "read")->{decision}, "deny",
      "named tools are exact and unmatched rules fall through to saved policy";
   is $perm->check ({ %$call, sandbox_grants => ["all"] }, "read-lines")->{decision}, "deny",
      "allow ceiling refuses broader required authority";
   is $perm->check ({ %$call, sandbox_grants => [] }, "read-lines")->{decision}, "allow",
      "allow ceiling includes requests with no capabilities";
   is $perm->check ({ %$call, action => "inspect", sandbox_grants => ["all"] }, "other")->{decision}, "allow",
      "capability wildcard matches arbitrary grants on allow";
   eval { $perm->check ({ %$call, sandbox_grants => ["invalid"] }, "read-lines") };
   like $@, qr/Unknown sandbox grant/, "automatic approval still validates sandbox grants";
   eval { $perm->check ({ %$call, action => "" }, "read-lines") };
   like $@, qr/Permission action/, "automatic approval still validates action";

   for my $bad ("", "a,,b", "read*,read", "read lines", "a,b,c,d", "a,read,", "a,*,nonexistent") {
      eval { $perm->auto_rules ([["allow", $bad]]) };
      like $@, qr/(?:Invalid automatic permission rule|Unknown sandbox grant)/,
         "invalid automatic rule '$bad' rejected";
   }
   $perm->auto_rules ([
      ["deny", "*,*,read"], ["allow", "*"],
   ]);
   is $perm->check ({ %$call, sandbox_grants => ["write"] }, "arbitrary")->{decision}, "deny",
      "deny capability fires when requested authority implies it";
   is $perm->check ({ %$call, sandbox_grants => [] }, "arbitrary")->{decision}, "allow",
      "deny named capability does not match an empty grant set";
   $perm->auto_rules ([["deny", "*,*,*"], ["allow", "*"]]);
   is $perm->check ({ %$call, sandbox_grants => [] }, "arbitrary")->{decision}, "deny",
      "deny wildcard matches even zero capabilities";
   $perm->auto_rules ([["allow", "*"], ["deny", "*,*,*"]]);
   is $perm->check ({ %$call, sandbox_grants => ["all"] }, "arbitrary")->{decision}, "allow",
      "allow wildcard matches any capability and earlier allow wins";
   $perm->auto_rules ([]);
   is $perm->check ($call, "read-lines")->{decision}, "deny",
      "empty command-line rule list falls through to saved rules";

   $perm->auto_rules ([["allow", "read_lines,read,write"], ["deny", "unchecked"]]);
   my $toolset = AnyEvent::MCP::Server::Toolset->new;
   my $runs = 0;
   $toolset->tool (read_lines => "read", {}, sub {
      my ($req) = @_;
      my $grants = $req->require_permission ({
         tool => "wrong-label", action => "read", sandbox_grants => ["write"], reason => "read",
      });
      ++$runs;
      $req->result ({ grants => $grants });
   });
   $toolset->tool (unchecked => "no explicit permission check", {}, sub {
      ++$runs;
      $_[0]->result ({ ok => 1 });
   });
   my $server = AnyEvent::MCP::Server->new (toolsets => [$toolset], permissions => $perm);
   my $rpc = sub {
      my ($name) = @_;
      my $reply;
      $server->rpc ({
         jsonrpc => "2.0", id => 1, method => "tools/call",
         params => { name => $name, arguments => {} },
      }, sub { $reply = shift }, protocol_version => "2025-11-25");
      $reply
   };
   my $reply = $rpc->("read-lines");
   is_deeply $reply->{result}{structuredContent}{grants}, ["write"],
      "auto-allowed tool executes with requested grants despite persistent deny";
   is $runs, 1, "allowed tool ran once";
   $reply = $rpc->("unchecked");
   ok $reply->{result}{structuredContent}{ok},
      "tool without permission checks runs despite auto-deny";
   is $runs, 2, "unchecked callback executed";
   $perm->auto_rules ([["deny", "read-lines"]]);
   $reply = $rpc->("read-lines");
   like $reply->{result}{content}[0]{text}, qr/Permission denied/,
      "auto-deny is enforced when a tool reaches its permission check";
   is $runs, 2, "denied checked callback not executed";
}

done_testing;
