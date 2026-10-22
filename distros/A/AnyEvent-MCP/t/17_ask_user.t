use common::sense;
use Test::More;
use AnyEvent ();
use AnyEvent::MCP::Client::JSONL ();

my @command = ($^X, "-Ilib", "bin/mcp-ask-user", "--stdio", "--ask", "mcp");
my $direct_client = AnyEvent::MCP::Client::JSONL->new (
   command => \@command,
   client_capabilities => { elicitation => { form => {} } },
);
my $legacy_client = AnyEvent::MCP::Client::JSONL->new (
   command => \@command,
   versions => ["2025-11-25"],
);

sub wait_for {
   my ($start) = @_;
   my $cv = AnyEvent->condvar;
   my $timeout = AnyEvent->timer (after => 8, cb => sub { die "ask-user test timeout\n" });
   $start->(sub { $cv->send ([@_]) });
   @{$cv->recv}
}

my $options = [
   { label => "Keep existing", description => "Preserve the current workdir" },
   { label => "Create new", description => "Start from scratch" },
];
my $args = { id => "path_choice", header => "Workdir", question => "Which workdir?", options => $options };

sub call {
   my ($arguments, $extra, $caps, $legacy, $name) = @_;
   $caps = { elicitation => { form => {} } } unless defined $caps;
   my $params = {
      name => $name || "ask-user", arguments => $arguments,
      %{$extra || {}},
      (!$legacy ? (_meta => {
         "io.modelcontextprotocol/clientCapabilities" => $caps,
         %{$extra->{_meta} || {}},
      }) : ()),
   };
   my ($success, $result) = wait_for (sub {
      ($legacy ? $legacy_client : $direct_client)->rpc ("tools/call", $params, $_[0])
   });
   die "ask-user transport failure: " . ($result->{message} // "") . "\n" unless $success;
   $result
}

sub resume {
   my ($result, $contents, $arguments, $caps) = @_;
   call ($arguments || $args, {
      requestState => $result->{requestState},
      inputResponses => { question => $contents },
   }, $caps)
}

my $first = call ($args);
is $first->{resultType}, "input_required", "initial call requests human input";
like $first->{requestState}, qr/\Aae-mcp-question:[0-9a-f]{64}\z/,
   "continuation uses unpredictable token";
my $prompt = $first->{inputRequests}{question};
is $prompt->{method}, "elicitation/create", "native MCP elicitation, not YAD";
is $prompt->{params}{mode}, "form", "uses form elicitation";
is_deeply $prompt->{params}{requestedSchema}{properties}{choice}{enum},
   ["Keep existing", "Create new"], "choice values come from the supplied labels";
like $prompt->{params}{message}, qr/Preserve the current workdir/,
   "descriptions appear in question text";
ok $prompt->{params}{requestedSchema}{properties}{free_text},
   "alternative free text field is always available";

my $answered = resume ($first, { action => "accept",
   content => { choice => "Keep existing" } });
is_deeply $answered->{structuredContent}, {
   id => "path_choice", status => "answered", answer => "Keep existing", source => "choice",
}, "chosen answer is returned in structured tool result";

my $replay = resume ($first, { action => "accept", content => { choice => "Create new" } });
ok $replay->{isError} && $replay->{content}[0]{text} =~ /Invalid or expired/,
   "continuation token cannot be reused";

my $free = call ($args);
my $custom = resume ($free, { action => "accept",
   content => { choice => "Keep existing", free_text => "Use current parent directory" } });
is $custom->{structuredContent}{answer}, "Use current parent directory",
   "free text overrides an optional choice";
is $custom->{structuredContent}{source}, "free_text",
   "free text is identified without inventing a choice";

my $open = { id => "free", question => "Please explain" };
my $plain = call ($open);
is_deeply $plain->{inputRequests}{question}{params}{requestedSchema}{required},
   ["free_text"], "free-text-only question requires a written answer";
my $text = resume ($plain, { action => "accept", content => { free_text => "Explanation" } }, $open);
is $text->{structuredContent}{answer}, "Explanation", "free text without choices is accepted";

my $empty = call ($args);
my $noanswer = resume ($empty, { action => "accept", content => {} });
ok $noanswer->{isError} && $noanswer->{content}[0]{text} =~ /No answer/,
   "empty response is rejected rather than fabricating a choice";

my $declined = call ($args);
my $d = resume ($declined, { action => "decline" });
is $d->{structuredContent}{status}, "declined", "decline is not mistaken for an answer";
my $cancelled = call ($args);
my $c = resume ($cancelled, { action => "cancel" });
is $c->{structuredContent}{status}, "cancelled", "cancel is distinct from decline";

my $changed = call ($args);
my $bad = resume ($changed, { action => "accept", content => { choice => "Keep existing" } },
   { %$args, question => "Something else" });
ok $bad->{isError}, "continuation is bound to the original call";
ok resume ($changed, { action => "decline" })->{isError},
   "modified arguments consume the continuation token";

my $unavailable = call ($args, {}, {});
ok $unavailable->{isError}
   && $unavailable->{content}[0]{text} =~ /unavailable/,
   "no advertised form capability returns a clear tool error";
my $url_only = call ($args, {}, { elicitation => { url => {} } });
ok $url_only->{isError}
   && $url_only->{content}[0]{text} =~ /unavailable/,
   "URL-only elicitation is insufficient for form questions";
my $implicit = call ($args, {}, { elicitation => {} });
is $implicit->{resultType}, "input_required",
   "empty elicitation capability implies form support for compatibility";
my $implicit_done = resume ($implicit, { action => "accept",
   content => { choice => "Create new" } }, undef, { elicitation => {} });
is $implicit_done->{structuredContent}{answer}, "Create new",
   "empty elicitation capabilities work through the complete round trip";
my $work_initial = call ($args, { _meta => {
   progressToken => "first-request",
   "io.modelcontextprotocol/clientInfo" => { name => "ChatGPT Work", version => "1" },
} });
my $work_resumed = call ($args, {
   requestState => $work_initial->{requestState},
   inputResponses => { question => {
      action => "accept", content => { choice => "Keep existing" },
   } },
   _meta => {
      progressToken => "resumed-request",
      "io.modelcontextprotocol/clientInfo" => { name => "ChatGPT Work", version => "2" },
   },
}, { elicitation => {} });
is $work_resumed->{structuredContent}{answer}, "Keep existing",
   "ask-user continuation ignores mutable request metadata, preserving original choice";

my $old = call ($args, {}, {}, 1);
ok $old->{isError}, "legacy clients receive a clear error rather than YAD";
my $duplicate = call ({ question => "Pick one", options => [
   { label => "Same" }, { label => "Same" },
] });
ok $duplicate->{isError}, "duplicate option labels are rejected";

my $form_args = {
   message => "Configure the test",
   requestedSchema => {
      type => "object", required => ["enabled", "count", "note"],
      properties => {
         enabled => { type => "boolean", default => JSON::XS::false },
         count   => { type => "integer", minimum => 1, maximum => 10 },
         note    => { type => "string", title => "Notes" },
      },
   },
};
my $form_content = { enabled => JSON::XS::true, count => 3, note => "\x{03c0}\nsecond line" };
sub form_call {
   my ($args, $extra, $caps, $legacy) = @_;

   call ($args, $extra, $caps, $legacy, "ask-form")
}
sub form_resume {
   my ($challenge, $response, $args) = @_;

   form_call ($args || $form_args, {
      requestState => $challenge->{requestState},
      inputResponses => { form => $response },
   })
}

my $form = form_call ($form_args);
is $form->{resultType}, "input_required", "generic form requests input";
like $form->{requestState}, qr/\Aae-mcp-form:[0-9a-f]{64}\z/, "form continuation has its own token prefix";
is_deeply $form->{inputRequests}{form}{params}, {
   mode => "form", %$form_args,
}, "generic schema and message reach native elicitation unchanged";
my $form_answer = form_resume ($form, { action => "accept", content => $form_content });
is_deeply $form_answer->{structuredContent}, { action => "accept", content => $form_content },
   "generic result preserves field names, booleans, numbers, Unicode and multiline text";
ok form_resume ($form, { action => "decline" })->{isError}, "form token cannot be reused";
for my $action (qw(decline cancel)) {
   my $challenge = form_call ($form_args);
   is_deeply form_resume ($challenge, { action => $action })->{structuredContent},
      { action => $action }, "$action is a distinct standard form response";
}
my $changed_form = form_call ($form_args);
ok form_resume ($changed_form, { action => "accept", content => $form_content }, {
   %$form_args, requestedSchema => { type => "object", properties => {} },
})->{isError}, "form continuation is bound to the supplied schema";
ok form_resume ($changed_form, { action => "decline" })->{isError},
   "changed form consumes its continuation";
my $cross_tool = form_call ($form_args);
ok resume ($cross_tool, { action => "accept", content => { choice => "Keep existing" } })->{isError},
   "form token cannot authorize the question tool";

for my $response (
   { action => "bogus" }, { action => "accept", content => [] }, {},
) {
   my $challenge = form_call ($form_args);
   ok form_resume ($challenge, $response)->{isError}, "malformed generic response is rejected";
}
ok form_call ({ %$form_args, message => [] })->{isError}, "generic form rejects a non-text message";
ok form_call ({ message => "Invalid", requestedSchema => { type => "string" } })->{isError},
   "generic form requires an object schema";
ok form_call ($form_args, {}, {})->{isError}, "generic native form requires client capability";
ok form_call ($form_args, {}, {}, 1)->{isError}, "generic native form rejects a legacy client";

# Actually cross two stdio processes: client -> multibroker -> mcp-ask-user.
# The upstream client must receive the downstream elicitation and its answer
# must be routed back to the same child's continuation token.
my $elicited = 0;
my $client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker", "--ask", "mcp", "questions",
      "stdio:" . join (" ", $^X, "-Ilib", "bin/mcp-ask-user")],
   env => { PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
   client_capabilities => { elicitation => { form => {} } },
   on_request => sub {
      my ($client, $req) = @_;
      ++$elicited;
      is $req->{method}, "elicitation/create",
         "upstream receives original child's elicitation request";
      $req->reply ({ action => "accept", content =>
         exists $req->{params}{requestedSchema}{properties}{count}
            ? $form_content : { choice => "Create new" },
      });
   },
);
my $cv = AnyEvent->condvar;
my $timer = AnyEvent->timer (after => 10, cb => sub { $cv->send ([0, "timed out"]) });
$client->call ("questions.ask-user", $args, sub { $cv->send ([@_]) });
my ($success, $through) = @{$cv->recv};
ok $success && $through->{structuredContent}{answer} eq "Create new"
   && $elicited == 1,
   "native elicitation and response round-trip through the real multibroker";

# The upstream caller's capabilities, not the broker's own advertised
# capabilities or any cached peer state, decide whether each call may elicit.
$client->{client_capabilities} = {};
($success, $through) = wait_for (sub {
   $client->call ("questions.ask-user", $args, $_[0])
});
ok $success && $through->{isError}
   && $through->{content}[0]{text} =~ /elicitation is unavailable/
   && $elicited == 1,
   "multibroker rejects unsupported per-request caller without eliciting";

$client->{client_capabilities} = { elicitation => {} };
($success, $through) = wait_for (sub {
   $client->call ("questions.ask-user", $args, $_[0])
});
ok $success && $through->{structuredContent}{answer} eq "Create new"
   && $elicited == 2,
   "same upstream connection then accepts implicit form elicitation";
# A raw multi-round-trip request through the multibroker can change _meta
# between the initial call and the response (as Work-like clients may do).
($success, $through) = wait_for (sub {
   $client->rpc ("tools/call", {
      name => "questions.ask-user", arguments => $args,
      _meta => { progressToken => "first-hop" },
   }, $_[0]);
});
is $through->{resultType}, "input_required",
   "broker delivers initial challenge for raw Work-like tool call";
my $broker_state = $through->{requestState};
($success, $through) = wait_for (sub {
   $client->rpc ("tools/call", {
      name => "questions.ask-user", arguments => $args,
      requestState => $broker_state,
      inputResponses => { question => {
         action => "accept", content => { choice => "Keep existing" },
      } },
      _meta => { progressToken => "second-hop" },
   }, $_[0]);
});
ok $success && $through->{structuredContent}{answer} eq "Keep existing",
   "multibroker forwards Work-like changed metadata without losing question continuation";
($success, $through) = wait_for (sub {
   $client->call ("questions.ask-form", $form_args, $_[0])
});
ok $success, "generic form transport crosses the real multibroker";
is_deeply $through->{structuredContent}, { action => "accept", content => $form_content },
   "generic form content survives the real client/broker/child round trip";
$client->close;
$direct_client->close;
$legacy_client->close;

done_testing;
