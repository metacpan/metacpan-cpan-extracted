use common::sense;
use AnyEvent ();
use AnyEvent::MCP::Server ();
use AnyEvent::MCP::Server::Permissions ();
use JSON::XS ();

print "1..45\n";
my $test;
sub ok($$) {
   print (($_[0] ? "ok " : "not ok "), ++$test, " - $_[1]\n");
}

my ($attempts, $effects, $prompts, $held);
my $permissions = AnyEvent::MCP::Server::Permissions->new (
   sandbox_grants => { read => [], write => ["read"] },
   ask => sub {
      ++$prompts;
      $_[1]->(1, { decision => "allow-once", sandbox_grants => ["read"] });
   },
);
my $server = AnyEvent::MCP::Server->new (
   permissions => $permissions,
   on_tools_call => sub {
      my ($server, $req, $args) = @_;
      ++$attempts;
      my @grants;
      for my $path (@{$args->{paths}}) {
         push @grants, $req->require_permission ({
            action => $req->{tool},
            dimensions => { subject => { label => "File", value => $path,
               choices => [{ label => "this file", match => $path }],
            } },
            sandbox_grants => ["write"], reason => "use $path",
         });
      }
      ++$effects;
      $req->result ({ grants => \@grants });
   },
);
my $id;
sub call {
   my ($params, $modern, $caps) = @_;
   $params = JSON::XS::decode_json (JSON::XS::encode_json $params);
   $params->{_meta} = {
      "io.modelcontextprotocol/protocolVersion" => "2026-07-28",
      "io.modelcontextprotocol/clientCapabilities" => $caps // { elicitation => { form => {} } },
      %{$params->{_meta} || {}},
   } if $modern;
   my ($reply, $req);
   $req = $server->rpc (
      { jsonrpc => "2.0", id => ++$id, method => "tools/call", params => $params },
      sub { $reply = defined $_[0] ? $_[0]{result} : undef }, protocol_version => "2025-11-25",
   );
   ($reply, $req)
}
my $params = { name => "move", arguments => { paths => ["/one", "/two"] } };
my ($result, $req) = call ($params);
ok $result->{structuredContent} && $effects == 1, "local retry completes once";
ok $attempts == 3 && $prompts == 2, "checks stop at the first missing permission";
ok join (",", map $_->[0], @{$result->{structuredContent}{grants}}) eq "read,read",
   "both reduced grants survive retries";
($result, $req) = call ($params);
ok $effects == 2 && $prompts == 4, "one-time grants do not authorize another call";

$permissions->{ask} = sub { ++$prompts; $_[1]->(1, { decision => "deny-once" }) };
($result, $req) = call ($params);
ok $result->{isError} && $effects == 2 && $prompts == 5, "denial does not retry or execute";

$permissions->{ask} = sub { $held = $_[1] };
($result, $req) = call ($params);
ok !defined $result && !$req->{finished}, "asynchronous asking leaves request outstanding";
$req->cancel;
$held->(1, { decision => "allow-once", sandbox_grants => ["read"] });
ok $req->{cancelled} && $effects == 2, "late approval after cancellation does not execute";

$permissions->{ask} = sub {
   $permissions->save ([{ decision => "deny", action => "^" }]);
   $_[1]->(1, { decision => "allow-once", sandbox_grants => ["read"] });
};
($result, $req) = call ($params);
ok $result->{isError} && $effects == 2, "new denial supersedes pending approval";
$permissions->save ([]);

# Modern asking returns challenges; the client repeats the whole call.
$permissions->{ask} = "mcp";
$attempts = $effects = 0;
($result, $req) = call ($params, 1);
ok $result->{resultType} eq "input_required" && !$effects && $attempts == 1,
   "first modern challenge precedes side effects";
my $first = $result->{requestState};
sub answer {
   my ($state) = @_;
   return { %$params, requestState => $state, inputResponses => {
      permission => { action => "accept", content => {
         decision => "allow-once", sandbox_grants => "read",
      } },
   } }
}
($result, $req) = call (answer ($first), 1);
ok $result->{resultType} eq "input_required" && !$effects && $attempts == 2,
   "second modern check retains first approval";
my $second = $result->{requestState};
ok $first ne $second, "each challenge has a fresh continuation";
($result, $req) = call (answer ($second), 1);
ok $result->{resultType} eq "complete" && $effects == 1 && $attempts == 3,
   "modern retry executes only after both approvals";
ok join (",", map $_->[0], @{$result->{structuredContent}{grants}}) eq "read,read",
   "modern continuation keeps reduced grants";
($result, $req) = call (answer ($second), 1);
ok $result->{isError} && $effects == 1, "continuation cannot be replayed";
($result, $req) = call ($params, 1);
ok $result->{resultType} eq "input_required" && $effects == 1,
   "modern grants do not leak into another call";
my $state = $result->{requestState};
my $changed = answer ($state);
$changed->{arguments} = { paths => ["/other"] };
($result, $req) = call ($changed, 1);
ok $result->{isError} && $effects == 1, "continuation rejects changed arguments";
($result, $req) = call (answer ($state), 1);
ok $result->{isError}, "invalid continuation attempt consumes token";

($result, $req) = call ($params, 1);
$state = $result->{requestState};
my $decline = answer ($state);
$decline->{inputResponses}{permission} = { action => "decline" };
($result, $req) = call ($decline, 1);
ok $result->{isError} && $effects == 1, "modern decline stops without execution";

# Recheck an earlier grant when policy changes while a later prompt is open.
($result, $req) = call ($params, 1);
($result, $req) = call (answer ($result->{requestState}), 1);
$state = $result->{requestState};
$permissions->save ([{ decision => "deny", action => "move", "match.subject" => "/one" }]);
($result, $req) = call (answer ($state), 1);
ok $result->{isError} && $effects == 1, "earlier one-time approval cannot bypass new policy";
$permissions->save ([]);

$permissions->{ask} = "auto";
$permissions->{helper} = [$^X, "-e",
   'local $/; scalar <STDIN>; print qq({"decision":"allow-once","sandbox_grants":["read"]})'];
my $cv = AnyEvent->condvar;
my $timer = AnyEvent->timer (after => 30, cb => sub { die "Permission retry timeout\n" });
$server->rpc (
   { jsonrpc => "2.0", id => ++$id, method => "tools/call", params => $params },
   sub { $cv->send ($_[0]{result}) }, protocol_version => "2025-11-25",
);
$result = $cv->recv;
ok $result->{structuredContent} && $effects == 2, "legacy helper retries multiple checks";
ok join (",", map $_->[0], @{$result->{structuredContent}{grants}}) eq "read,read",
   "legacy helper retains reduced grants";

$server->{on_tools_call} = sub { die "ordinary tool failure\n" };
($result, $req) = call ($params);
ok $result->{isError} && $result->{content}[0]{text} =~ /ordinary tool failure/,
   "ordinary exceptions remain tool errors";
delete $server->{permissions};
$server->{on_tools_call} = sub {
   $_[1]->require_permission ({ action => "read", sandbox_grants => ["read"], reason => "read" });
};
($result, $req) = call ($params);
ok $result->{isError} && $result->{content}[0]{text} =~ /no permission configuration/,
   "missing permission configuration fails closed";

# The explicit callback interface also works with server-owned permissions.
$server->{permissions} = $permissions;
$permissions->{ask} = "mcp";
$server->{on_tools_call} = sub {
   my ($server, $req) = @_;
   $permissions->require ($req, { action => "read", sandbox_grants => ["read"], reason => "read" }, sub {
      $_[0] ? $req->result ({ allowed => 1 }) : $req->error ($_[1]);
   });
};
($result, $req) = call ($params, 1);
($result, $req) = call (answer ($result->{requestState}), 1);
ok $result->{structuredContent}{allowed}, "callback interface honours resumed grant";

$permissions->{ask} = sub { die "prompt failed\n" };
$server->{on_tools_call} = sub {
   $_[1]->require_permission ({ action => "read", sandbox_grants => ["read"], reason => "read" });
};
($result, $req) = call ($params);
ok $result->{isError} && $result->{content}[0]{text} =~ /prompt failed/,
   "prompt exception completes as a tool error";


# Native MCP: four choices, optional message, and a rule-editing second form.
$permissions->save ([]);
$permissions->{ask} = "mcp";
my $denial_effects = 0;
my $denied_path = "/root/SCHMORP-PERL.md";
$server->{on_tools_call} = sub {
   my ($server, $req, $args) = @_;
   $req->require_permission ({
      action => "read", paths => [$args->{path} // $denied_path],
      sandbox_grants => ["read"], reason => "read file",
   });
   ++$denial_effects;
   $req->result ({ allowed => 1 });
};
my $rp = { name => "read", arguments => {} };
my $reply_with = sub {
   my ($state, $content) = @_;
   call ({
      %$rp, requestState => $state, inputResponses => {
         permission => { action => "accept", content => $content },
      },
   }, 1)
};
($result, $req) = call ($rp, 1);
ok $result->{resultType} eq "input_required"
   && $result->{inputRequests}{permission}{params}{requestedSchema}{properties}{message},
   "native MCP first form exposes optional message";
my $first_choice = $result->{requestState};
($result, $req) = $reply_with->($first_choice, {
   decision => "deny-always", message => "Use the Vim buffer instead",
});
ok $result->{resultType} eq "input_required"
   && $result->{inputRequests}{permission}{params}{requestedSchema}{properties}{path}
   && $result->{inputRequests}{permission}{params}{message} =~ /Denial reason: Use the Vim buffer instead/
   && !$result->{inputRequests}{permission}{params}{requestedSchema}{properties}{message}
   && !$denial_effects,
   "Deny always opens rule form showing inherited reason read-only, without executing";
my $rule_state = $result->{requestState};
($result, $req) = $reply_with->($rule_state, { decision => "back" });
ok $result->{resultType} eq "input_required"
   && $result->{inputRequests}{permission}{params}{requestedSchema}{properties}{message}{default}
      eq "Use the Vim buffer instead"
   && !$denial_effects,
   "Back restores original message and approval form";
($result, $req) = $reply_with->($result->{requestState}, {
   decision => "deny-always", message => "Use the Vim buffer instead",
});
ok $result->{resultType} eq "input_required"
   && $result->{requestState} ne $rule_state,
   "returning to rule editor creates a fresh token";
($result, $req) = $reply_with->($result->{requestState}, {
   decision => "deny-always", path => $denied_path,
});
ok $result->{isError} && $result->{content}[0]{text} =~ /Use the Vim buffer instead/
   && !$denial_effects,
   "persistent refusal returns human message to requesting model";
ok $permissions->rules->[0]{path} eq $denied_path
   && $permissions->rules->[0]{message} eq "Use the Vim buffer instead",
   "human message and exact-file scope persisted";
($result, $req) = call ($rp, 1);
ok $result->{isError} && $result->{content}[0]{text} =~ /Use the Vim buffer instead/
   && !$denial_effects,
   "future identical requests receive saved message without prompting";
($result, $req) = call ({ name => "read", arguments => { path => "/root/other" } }, 1);
ok $result->{resultType} eq "input_required" && !$denial_effects,
   "persistent denied path leaves other paths unaffected";
($result, $req) = $reply_with->($first_choice, { decision => "allow-once" });
ok $result->{isError} && !$denial_effects,
   "first continuation token is unusable after entering rule stage";

# An approval must leave the tool's result untouched, even if a client
# sends a denial-only reason along with an allowed decision.
$permissions->save ([]);
($result, $req) = call ($rp, 1);
($result, $req) = $reply_with->($result->{requestState}, {
   decision => "allow-once", message => "Do it, wrong file buddy",
});
ok $result->{structuredContent}{allowed} && $denial_effects == 1
   && @{$result->{content}} == 1
   && $result->{content}[0]{text} !~ /wrong file buddy/,
   "allow-once ignores denial-only reason and leaves tool result unchanged";

# An allow-always rule must not persist a denial reason.
$permissions->save ([]);
($result, $req) = call ($rp, 1);
($result, $req) = $reply_with->($result->{requestState}, {
   decision => "allow-always", message => "Careful, check the filename",
});
ok $result->{resultType} eq "input_required"
   && $result->{inputRequests}{permission}{params}{requestedSchema}{properties}{sandbox_grants},
   "Allow always opens rule editor with editable grants";
($result, $req) = $reply_with->($result->{requestState}, {
   decision => "allow-always", sandbox_grants => "read",
});
ok $result->{structuredContent}{allowed}
   && @{$result->{content}} == 1
   && !exists $permissions->rules->[0]{message},
   "allow-always saves no denial reason and leaves current result untouched";
($result, $req) = call ($rp, 1);
ok $result->{structuredContent}{allowed}
   && @{$result->{content}} == 1,
   "saved allow rule leaves future tool results untouched";


# Multiple successive approval decisions must not introduce messages
# into the tool result, even if the client submitted denial-only reasons.
$permissions->save ([]);
$server->{on_tools_call} = sub {
   my ($server, $req, $args) = @_;
   for my $path ("/first", "/second") {
      $req->require_permission ({
         action => "read", paths => [$path], sandbox_grants => ["read"],
         reason => "Inspect $path",
      });
   }
   $req->result ({ done => 1 });
};
($result, $req) = call ($rp, 1);
ok $result->{resultType} eq "input_required",
   "multiple permissions initially challenge the first request";
($result, $req) = $reply_with->($result->{requestState}, {
   decision => "allow-once", message => "First message",
});
ok $result->{resultType} eq "input_required",
   "second permission challenges without losing first approval";
($result, $req) = $reply_with->($result->{requestState}, {
   decision => "allow-once", message => "Second message",
});
ok $result->{structuredContent}{done}
   && @{$result->{content}} == 1
   && $result->{content}[0]{text} !~ /First message|Second message/,
   "multiple approvals never inject denial reasons into tool content";

# Generic native permissions accept elicitation:{} (implicit form) but not
# URL-only clients. Neither check is a connection-global switch.
$permissions->{ask} = "mcp";
$permissions->save ([]);
($result, $req) = call ($params, 1, { elicitation => {} });
ok $result->{resultType} eq "input_required",
   "native permission form supports implicit elicitation:{} capability";
($result, $req) = call ($params, 1, { elicitation => { url => {} } });
ok $result->{isError} && $result->{content}[0]{text} =~ /elicitation is unavailable/,
   "native permission form rejects URL-only elicitation capability";

# Work and other clients can change per-request metadata (such as clientInfo,
# progressToken, and capability declarations) when retrying with inputResponses.
# These are not stable identities or authorization properties.
($result, $req) = call ({ %$rp, _meta => {
   progressToken => "initial", "io.modelcontextprotocol/clientInfo" => {
      name => "Work", version => "1",
   },
} }, 1);
my $changed_meta_state = $result->{requestState};
my $metadata_retry = {
   %$rp, requestState => $changed_meta_state, inputResponses => {
      permission => { action => "accept", content => {
         decision => "allow-once", sandbox_grants => "read",
      } },
   },
};
$metadata_retry->{_meta} = {
   progressToken => "retry",
   "io.modelcontextprotocol/clientInfo" => { name => "Work", version => "2" },
};
($result, $req) = call ($metadata_retry, 1, { elicitation => {} });
ok $result->{resultType} eq "input_required",
   "continuation accepts changed client metadata and capability advertisement";
($result, $req) = call ({
   %$rp, requestState => $result->{requestState}, inputResponses => {
      permission => { action => "accept", content => {
         decision => "allow-once", sandbox_grants => "read",
      } },
   },
}, 1);
ok $result->{structuredContent}{done},
   "metadata-changed continuation still completes after remaining approvals";

