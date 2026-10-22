use common::sense;
# the HTTP child uses a private loopback listener.
BEGIN { delete $ENV{http_proxy} }
use Test::More;
use AnyEvent ();
use AnyEvent::Util ();
use AnyEvent::MCP::Client::JSONL ();
use File::Temp ();
use File::Path ();
use IO::Socket::INET ();
use JSON::XS ();
use Time::HiRes ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
File::Path::mkpath (["$dir/home", "$dir/config"], 0, 0700);
my $helper = "$dir/form-helper";
sub write_file {
   my ($path, $text) = @_;
   open my $fh, ">", $path or die "$path: $!";
   print {$fh} $text;
   close $fh or die "$path: $!";
}
write_file $helper, "#!$^X\n" . q{
use common::sense;
use JSON::XS ();
local $/;
my $request = JSON::XS::decode_json <STDIN>;
open my $log, ">>", "$ENV{MCP_TEST_FORM_DIR}/requests" or die $!;
print {$log} JSON::XS::encode_json ($request), "\n";
close $log;
if ($request->{message} =~ /Wait for cancellation/) {
   open my $pid, ">", "$ENV{MCP_TEST_FORM_DIR}/waiting-pid" or die $!;
   print {$pid} "$$";
   close $pid;
   sleep 60;
}
open my $reply, "<", "$ENV{MCP_TEST_FORM_DIR}/reply" or die $!;
print scalar <$reply>;
};
chmod 0700, $helper or die $!;
write_file "$dir/anyevent-mcp-form-elicitation", "#!$^X\n" . q{
use common::sense;
use JSON::XS ();
open my $log, ">>", "$ENV{MCP_TEST_FORM_DIR}/modes" or die $!;
print {$log} JSON::XS::encode_json (\@ARGV), "\n";
close $log or die $!;
exec $^X, "$ENV{MCP_TEST_FORM_DIR}/form-helper";
die "exec: $!";
};
chmod 0700, "$dir/anyevent-mcp-form-elicitation" or die $!;
my %env = (
   HOME => "$dir/home", XDG_CONFIG_HOME => "$dir/config",
   PERL_ANYEVENT_MCP_ELICITATION_HELPER => $helper,
   MCP_TEST_FORM_DIR => $dir, PATH => "$dir:$ENV{PATH}",
);
write_file "$dir/reply", '{"action":"accept","content":{"choice":"Keep"}}';
my $args = { question => "Keep or replace?", options => [{ label => "Keep" }, { label => "Replace" }] };

sub wait_for {
   my ($start) = @_;
   my $cv = AE::cv;
   my $timer = AE::timer 30, 0, sub { $cv->croak ("Local form test timeout\n") };
   $start->(sub { $cv->send ([@_]) });
   @{$cv->recv}
}
sub question {
   my ($client, $name) = @_;
   my ($success, $result) = wait_for (sub { $client->call ($name || "ask-user", $args, $_[0]) });
   ok $success, "question transport completed";
   $result
}
sub requests {
   open my $fh, "<", "$dir/requests" or die $!;
   my @requests = map JSON::XS::decode_json ($_), <$fh>;
   close $fh;
   @requests
}
sub standalone {
   my ($mode, $caps, $legacy, $on_request) = @_;
   AnyEvent::MCP::Client::JSONL->new (
      command => [$^X, "-Ilib", "bin/mcp-ask-user", "--stdio", "--ask", $mode],
      env => \%env, client_capabilities => $caps,
      ($legacy ? (versions => ["2025-11-25"]) : ()),
      on_request => $on_request || sub { die "Local question reached upstream elicitation\n" },
   )
}

my $client = standalone ("helper", {}, 1);
my $result = question $client;
is $result->{structuredContent}{answer}, "Keep", "standalone local helper works for a legacy client";
write_file "$dir/reply", '{"action":"decline"}';
$result = question $client;
is $result->{structuredContent}{status}, "declined", "local decline is retained";
write_file "$dir/reply", '{"action":"cancel"}';
$result = question $client;
is $result->{structuredContent}{status}, "cancelled", "local cancel is distinct";
write_file "$dir/reply", '{"action":"accept","content":{"choice":"not offered"}}';
$result = question $client;
ok $result->{isError}, "standalone validates even a custom helper's choice";

my $form_args = {
   message => "Configure locally",
   requestedSchema => {
      type => "object", required => ["enabled", "count"],
      properties => {
         enabled => { type => "boolean" },
         count   => { type => "integer", minimum => 1 },
      },
   },
};
write_file "$dir/reply", '{"action":"accept","content":{"enabled":true,"count":2}}';
my ($form_ok, $form_result) = wait_for (sub {
   $client->call ("ask-form", $form_args, $_[0])
});
ok $form_ok, "generic local form works for a legacy client";
is_deeply $form_result->{structuredContent},
   { action => "accept", content => { enabled => JSON::XS::true, count => 2 } },
   "local form returns standard typed response";
my @form_requests = requests;
is_deeply $form_requests[-1], { mode => "form", %$form_args },
   "generic parameters reach the helper unchanged";
for my $action (qw(decline cancel)) {
   write_file "$dir/reply", JSON::XS::encode_json { action => $action };
   ($form_ok, $form_result) = wait_for (sub {
      $client->call ("ask-form", $form_args, $_[0])
   });
   is_deeply $form_result->{structuredContent}, { action => $action },
      "local generic form retains $action";
}
write_file "$dir/reply", '{"action":"accept","content":[]}';
($form_ok, $form_result) = wait_for (sub {
   $client->call ("ask-form", $form_args, $_[0])
});
ok $form_result->{isError}, "generic tool rejects a malformed custom helper response";
$client->close;

write_file "$dir/reply", '{"action":"accept","content":{"choice":"Keep"}}';
$client = standalone ("auto", {});
$result = question $client;
is $result->{structuredContent}{answer}, "Keep", "standalone auto falls back when no forms are advertised";
$client->close;

my @before = requests;
my $elicited;
$client = standalone ("auto", { elicitation => { form => {} } }, 0, sub {
   ++$elicited;
   $_[1]->reply ({ action => "decline" });
});
$result = question $client;
my @after = requests;
ok $elicited == 1 && $result->{structuredContent}{status} eq "declined" && @before == @after,
   "auto native decline never falls back to a local helper";
$client->close;

sub broker {
   my ($mode, $caps, $legacy, $url) = @_;
   AnyEvent::MCP::Client::JSONL->new (
      command => [$^X, "-Ilib", "bin/mcp-multibroker", "--stdio", "--ask", $mode, "questions",
         $url || "stdio:$^X -Ilib bin/mcp-ask-user"],
      env => \%env, client_capabilities => $caps,
      ($legacy ? (versions => ["2025-11-25"]) : ()),
      on_request => sub { die "Broker local question reached upstream elicitation\n" },
   )
}
for my $case (
   ["helper", { elicitation => { form => {} } }, 0],
   ["helper", {}, 0],
   ["helper", {}, 1],
   ["auto", {}, 0],
) {
   $client = broker (@$case);
   $result = question $client, "questions.ask-user";
   is $result->{structuredContent}{answer}, "Keep",
      "broker $case->[0] handles the child form locally despite upstream capability differences";
   my @requests = requests;
   like $requests[-1]{message}, qr/\AServer: questions\n\n/, "broker identifies the requesting child";
   $client->close;
}

for my $mode (qw(tty yad)) {
   local $env{PERL_ANYEVENT_MCP_ELICITATION_HELPER} = "$dir/not-a-custom-helper";
   for my $through_broker (0, 1) {
      $client = $through_broker ? broker ($mode, {}) : standalone ($mode, {});
      $result = question $client, $through_broker ? "questions.ask-user" : "ask-user";
      is $result->{structuredContent}{answer}, "Keep", "$mode works through the selected built-in form helper";
      open my $log, "<", "$dir/modes" or die $!;
      my @modes = map JSON::XS::decode_json ($_), <$log>;
      close $log;
      is_deeply $modes[-1], ["--$mode"], "$mode is forced without consulting the custom helper";
      $client->close;
   }
}

SKIP: {
   skip "extended form helper cancellation tests (PERL_ANYEVENT_MCP_TESTS=1)", 3 unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;

   $client = broker ("helper", {});
   $args->{question} = "Wait for cancellation";
   my $cancelled = AE::cv;
   my $operation = $client->call ("questions.ask-user", $args, sub { $cancelled->send ([@_]) });
   my $poll;
   wait_for (sub {
      my $done = shift;
      $poll = AE::timer 0, 0.01, sub {
         return unless -s "$dir/waiting-pid";
         undef $poll;
         $done->(1);
      };
   });
   open my $pidfile, "<", "$dir/waiting-pid" or die $!;
   my $helper_pid = <$pidfile>;
   close $pidfile;
   $client->cancel ($operation);
   my $cancel = $cancelled->recv;
   ok !$cancel->[0] && $cancel->[1]{cancelled}, "broker question cancellation reaches the caller";
   wait_for (sub {
      my $done = shift;
      $poll = AE::timer 0, 0.01, sub {
         return if kill 0, $helper_pid;
         undef $poll;
         $done->(1);
      };
   });
   ok !kill (0, $helper_pid), "broker cancels and reaps the active form helper";
   $args->{question} = "Keep or replace?";
   $result = question $client, "questions.ask-user";
   is $result->{structuredContent}{answer}, "Keep", "prompt queue remains usable after cancellation";
   $client->close;

}

# Independently running HTTP servers delegate to the broker too.
my $listener = IO::Socket::INET->new (
   LocalAddr => "127.0.0.1", LocalPort => 0, Proto => "tcp", Listen => 1,
) or die $!;
my $port = $listener->sockport;
close $listener;
my ($pid, $stdout, $stderr);
my $server = AnyEvent::Util::run_cmd (
   [$^X, "-Ilib", "bin/mcp-ask-user", "--ask", "mcp", "--bind", "127.0.0.1:$port", "--token", "form-test"],
   env => \%env, "<" => "/dev/null", ">" => \$stdout, "2>" => \$stderr, '$$' => \$pid,
);
my $ready;
for (1 .. 1500) {
   $ready = IO::Socket::INET->new (PeerAddr => "127.0.0.1", PeerPort => $port, Proto => "tcp");
   last if $ready;
   Time::HiRes::sleep (0.02);
}
ok $ready, "standalone HTTP question server is listening";
close $ready if $ready;
$client = broker ("helper", {}, 0, "http://127.0.0.1:$port/form-test/");
$result = question $client, "questions.ask-user";
is $result->{structuredContent}{answer}, "Keep", "broker handles an independent HTTP child's form locally";
$client->close;
kill TERM => $pid if $pid;
$server->recv;

done_testing;
