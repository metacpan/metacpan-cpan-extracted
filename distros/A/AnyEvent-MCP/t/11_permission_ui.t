use common::sense;
use Test::More;
use Cwd ();
use AnyEvent::Util ();
use AnyEvent::MCP::Server::Permissions ();
use AnyEvent::MCP::Server::Request ();
use AnyEvent::MCP::Permissions::Ask ();
use File::Temp ();
use JSON::XS ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
my $json = JSON::XS->new->canonical;
my $request = {
   version => 1, action => "write", action_matcher => "write", subject => "/one/file",
   subjects => [
      { label => "This file", subject => "/one/file" },
      { label => "Containing directory", subject => "^/one/" },
   ],
   reason => "Change the file", sandbox_grants => ["write"], sandbox_grant_choices => ["read", "write"],
   sandbox_grant_descriptions => { read => "Read files", write => "Modify files" },
};

sub write_file {
   my ($path, $data) = @_;
   open my $fh, ">", $path or die $!;
   print {$fh} $data;
   close $fh or die $!;
}

write_file "$dir/yad", "#!$^X\n" . q{
use common::sense;
use JSON::XS ();
open my $fh, "<", $ENV{PERL_ANYEVENT_MCP_TEST_UI_QUEUE} or die $!;
local $/;
my $queue = JSON::XS::decode_json <$fh>;
close $fh;
my $response = shift @$queue or die "Unexpected YAD invocation";
open $fh, ">", $ENV{PERL_ANYEVENT_MCP_TEST_UI_QUEUE} or die $!;
print {$fh} JSON::XS::encode_json $queue;
close $fh;
open $fh, ">>", $ENV{PERL_ANYEVENT_MCP_TEST_UI_LOG} or die $!;
print {$fh} JSON::XS::encode_json (\@ARGV), "\n";
close $fh;
if (grep $_ eq "--text-info", @ARGV) {
   my ($filename) = map { /\A--filename=(.*)\z/ ? $1 : () } @ARGV;
   die "Viewer needs existing file\n" unless defined $filename && -f $filename;
   open my $viewer, "<", $filename or die $!;
   binmode $viewer;
   local $/;
   my $contents = <$viewer>;
   close $viewer;
   open my $viewlog, ">>", $ENV{PERL_ANYEVENT_MCP_TEST_VIEW_LOG} or die $!;
   print {$viewlog} JSON::XS::encode_json ({
      contents_hex => unpack ("H*", $contents),
      mode => ((stat $filename)[2] & 0777),
   }), "\n";
   close $viewlog;
}
if ($response->{click_view}) {
   require Text::ParseWords;
   my ($index) = grep $ARGV[$_] eq "--field=$response->{click_view}...:FBTN", 0 .. $#ARGV;
   die "No View stdin form button\n" unless defined $index;
   my $command = $ARGV[$index + 1];
   die "No View stdin action\n" unless defined $command;
   my @cmd = Text::ParseWords::shellwords ($command);
   die "Invalid viewer command\n" unless @cmd && $cmd[0] eq "yad";
   system { $cmd[0] } @cmd;
   die "Viewer did not complete\n" if $?;
}
if (grep $_ eq "--form", @ARGV) {
   for my $i (0 .. $#ARGV) {
      print "\x1f" if $ARGV[$i] =~ /\A--field=.*:(?:LBL|FBTN)\z/;
   }
}
print $response->{output};
exit $response->{status};
};
chmod 0700, "$dir/yad" or die $!;

local %ENV = (
   %ENV, PATH => "$dir:$ENV{PATH}", DISPLAY => ":test", WAYLAND_DISPLAY => "",
   PERL_ANYEVENT_MCP_TEST_UI_QUEUE => "$dir/queue",
   PERL_ANYEVENT_MCP_TEST_UI_LOG => "$dir/log",
   PERL_ANYEVENT_MCP_TEST_VIEW_LOG => "$dir/view_log",
);
my @prompt_options;
sub prompt {
   my ($request, @responses) = @_;
   write_file "$dir/queue", $json->encode (\@responses);
   my ($output, $error);
   my $input = AnyEvent::MCP::utf8enc ($json->encode ($request));
   my $status = AnyEvent::Util::run_cmd (
      [$^X, "-Ilib", "-MPOSIX", "-e",
         'defined POSIX::setsid () or die $!; do shift @ARGV; die $@ if $@;',
         "./bin/anyevent-mcp-askpermission", @prompt_options],
      "<" => \$input, ">" => \$output, "2>" => \$error,
   )->recv;
   is $status, 0, "helper returns a decision successfully";
   JSON::XS::decode_json $output
}

is +(AnyEvent::MCP::Server::Permissions->new)->{ask}, "helper", "approval defaults to a local helper";
my $decision = prompt $request, { status => 4, output => "Do it, wrong file\x1f\n" };
is_deeply $decision, { decision => "allow-once", sandbox_grants => ["write"] },
   "allow-once uses requested grants and discards denial reason";
{
   open my $log, "<", "$dir/log" or die $!;
   my $args = $json->decode (scalar <$log>);
   close $log;
   my @labels = grep /\A--field=.*:LBL\z/, @$args;
   is_deeply \@labels, ["--field=Action: write:LBL", "--field=Subject: /one/file:LBL",
      "--field=Reason: Change the file:LBL"], "request context is read-only labels";
   ok !(grep /\A--field=.*:CHK\z/, @$args) && !(grep /\A--field=.*:CB\z/, @$args),
      "initial YAD dialog has no grant or rule-scope selectors";
   ok +(grep $_ eq "--field=Denial reason (optional)", @$args),
      "denial reason appears in form above decision buttons";
   is_deeply [grep /\A--button=/, @$args], [
      "--button=Deny once:0", "--button=Deny always...:6",
      "--button=Allow always...:8", "--button=Allow once:4",
   ], "one-time decisions are at the outside edges";
   ok +(grep /\A--text=Required grants: write\z/, @$args),
      "requested grants appear as a read-only compact line";
   ok +(grep $_ eq "--focus-field=4", @$args),
      "initial focus is in optional message field";
}

my $multiline = { %$request, reason => "Execute in Vim\n\necho 'hello'\x1b" };
like AnyEvent::MCP::Permissions::Ask::message ($multiline),
   qr/Reason: Execute in Vim\n\necho 'hello'\\u\{1B\}/,
   "MCP and terminal reasons preserve newlines and escape terminal controls";
prompt $multiline, { status => 0, output => "\x1f\n" };
{
   open my $log, "<", "$dir/log" or die $!;
   my $line;
   $line = $_ while <$log>;
   close $log;
   my $args = $json->decode ($line);
   ok +(grep $_ eq "--field=Reason: Execute in Vim\n\necho 'hello'\\\\u{1B}:LBL", @$args),
      "YAD reason preserves line breaks and protects escaped controls from YAD decoding";
}

# Display-only input can be viewed without dismissing the approval form.
# The fake YAD "clicks" View stdin, launches the separate text-info viewer,
# then continues the original approval.
my $source = "\x{03c0}\nprint \"ok\";\0\x1b"; # Unicode plus controls
my $preview = {
   %$request,
   details => { "View stdin" => $source },
};
my $viewed = prompt $preview,
   { status => 4, output => "Approved after viewing\x1f\n", click_view => "View stdin" },
   { status => 0, output => "" };
is_deeply $viewed, { decision => "allow-once", sandbox_grants => ["write"] },
   "separate viewer leaves original approval decision unchanged";
{
   open my $log, "<", "$dir/log" or die $!;
   my @entries = map $json->decode ($_), <$log>;
   close $log;
   my $form = $entries[-2];
   my $popup = $entries[-1];
   ok +(grep $_ eq "--field=View stdin...:FBTN", @$form),
      "approval dialog has an inline View stdin button";
   is_deeply [grep /\A--button=/, @$form], [
      "--button=Deny once:0", "--button=Deny always...:6",
      "--button=Allow always...:8", "--button=Allow once:4",
   ], "viewer never shifts or replaces any approval decision buttons";
   ok +(grep $_ eq "--text-info", @$popup),
      "click opens a YAD text-info dialog";
   ok +(grep $_ eq "--fontname=Monospace 11", @$popup),
      "popup uses a monospace source viewer";
   ok +(grep /--field=View stdin: .* characters, .* UTF-8 bytes:LBL/, @$form),
      "approval dialog identifies stdin without embedding its source";
   unlike $json->encode ($form), qr/print \\"ok\\"/,
      "source is not interpolated into the main dialog command line";
   open my $fh, "<", "$dir/view_log" or die $!;
   my $details = $json->decode (scalar <$fh>);
   close $fh;
   is $details->{mode}, 0600, "popup reads a private mode-0600 file";
   my $visible = pack "H*", $details->{contents_hex};
   is AnyEvent::MCP::utf8dec ($visible),
      AnyEvent::MCP::Permissions::Ask::detail_text ("View stdin", $source),
      "popup shows Unicode source and visibly escapes control characters";
}
my $truncated = prompt {
   %$preview, details => { "View stdin" => "first chunk" . ("x" x 65536) },
}, { status => 0, output => "\x1f\n", click_view => "View stdin" },
   { status => 0, output => "" };
is $truncated->{decision}, "deny-once", "viewing incomplete input does not force approval";
{
   open my $fh, "<", "$dir/view_log" or die $!;
   my $line;
   $line = $_ while <$fh>;
   close $fh;
   my $info = $json->decode ($line);
   like AnyEvent::MCP::utf8dec (pack "H*", $info->{contents_hex}),
      qr/65547 characters.*WARNING: INCOMPLETE PREVIEW.*first chunk/s,
      "UI bounds complete detail text and conspicuously warns about the incomplete preview";
}

my $patch_details = {
   %$request,
   details => {
      "View patch" => "File: /one/file\n\n@@ -1 @@\n-old\n+new\n",
      "More: context" => "second detail\n",
   },
};
my $patch_decision = prompt $patch_details,
   { status => 0, output => "Wrong change\x1f\n", click_view => "View patch" },
   { status => 0, output => "" };
is_deeply $patch_decision, { decision => "deny-once", message => "Wrong change" },
   "multiple generic details preserve denial reason and decision";
{
   open my $log, "<", "$dir/log" or die $!;
   my @entries = map $json->decode ($_), <$log>;
   close $log;
   is_deeply [grep /:FBTN\z/, @{$entries[-2]}],
      ["--field=More\\\\u{3A} context...:FBTN", "--field=View patch...:FBTN"],
      "generic labels are sorted, protect YAD syntax and receive UI ellipses";
}
like AnyEvent::MCP::Permissions::Ask::message ($patch_details),
   qr/View patch: .*File: \/one\/file.*-old\n\+new\n/s,
   "native MCP and terminal messages include the generic patch preview";
like AnyEvent::MCP::Permissions::Ask::detail_text ("Long", "x" x 65537),
   qr/65537 characters.*INCOMPLETE PREVIEW.*(?:x{16384}){4}\z/s,
   "shared detail formatter bounds the visible preview";
my $invalid = eval {
   AnyEvent::MCP::Server::Permissions->new->check ({
      action => "read", sandbox_grants => [], reason => "invalid detail",
      details => { Broken => [] },
   });
   1
};
ok !$invalid && $@ =~ /detail must be text/, "permission boundary rejects non-text details";

my $path_request = {
   %$request, subject => undef, subjects => [], paths => ["/one/file", "/two/file"],
};
$decision = prompt $path_request, { status => 0, output => "Use a different file\x1f\n" };
is_deeply $decision, { decision => "deny-once", message => "Use a different file" },
   "denial immediately returns optional human message";
my $configured_path = "/projects/../projects/code";
my $scoped_description = {
   %$path_request, sandbox_grants => ["write"],
   sandbox_grant_descriptions => {
      read => "Read files in selected workdir \"$configured_path\"",
      write => "Change files in selected workdir \"$configured_path\"",
   },
};
my $shared_message = AnyEvent::MCP::Permissions::Ask::message ($scoped_description);
like $shared_message, qr/\APermission request\nRequested sandbox grants: write\n/,
   "MCP and TTY display requested grants near top of prompt";

my $elicitation_schema = AnyEvent::MCP::Permissions::Ask::schema ($scoped_description);
ok $elicitation_schema->{properties}{message}
   && !exists $elicitation_schema->{properties}{sandbox_grants}
   && !exists $elicitation_schema->{properties}{subject},
   "MCP choice form has only message and decision";
my $rule_schema = AnyEvent::MCP::Permissions::Ask::schema ($scoped_description, "rule",
   { decision => "allow-always", message => "Thanks" });
ok $rule_schema->{properties}{sandbox_grants}{default} eq "write",
   "MCP rule form defaults grant selection to the original request";

my $workdir_request = {
   %$request, name => "default", workdir => "/projects/one",
   multibroker_alias => "cerebro-fs",
};
like AnyEvent::MCP::Permissions::Ask::message ($workdir_request),
   qr/Server: "default".*Multibroker alias: "cerebro-fs".*Workdir: "\/projects\/one"/s,
   "native and terminal permission prompts distinguish multibroker aliases";
$decision = prompt $workdir_request,
   { status => 8, output => "\x1f\n" },
   { status => 8, output => "TRUE\x1fFALSE\x1f2\x1f1\x1f1\x1f\n" };
ok $decision->{workdir_scope} eq "all" && !exists $decision->{rule}{workdir},
   "YAD can explicitly save a rule for all current and future workdirs";
{
   open my $log, "<", "$dir/log" or die $!;
   my @entries = map $json->decode ($_), <$log>;
   close $log;
   ok +(grep $_ eq "--field=Multibroker alias: cerebro-fs:LBL", @{$entries[-2]}),
      "YAD initial dialog displays the actual multibroker alias";
   ok +(grep $_ eq "--field=Workdir scope:CB", @{$entries[-1]})
      && +(grep /Any configured workdir, including future ones/, @{$entries[-1]}),
      "YAD rule editor offers the broader workdir scope";
}
$decision = prompt $workdir_request,
   { status => 8, output => "\x1f\n" },
   { status => 8, output => "TRUE\x1fTRUE\x1f1\x1f1\x1f1\x1f\n" };
is $decision->{rule}{workdir}, "/projects/one",
   "YAD workdir scope defaults to the selected workdir";

my $unsafe = prompt {
   %$request,
   sandbox_implementation => "NONE - UNSANDBOXED (full host-user privileges)",
   action_description => "Modify existing resources",
}, { status => 0, output => "\x1f\n" };
is $unsafe->{decision}, "deny-once", "unsandboxed prompt preserves refusal";
{
   open my $log, "<", "$dir/log" or die $!;
   my $line;
   $line = $_ while <$log>;
   close $log;
   my $args = $json->decode ($line);
   ok +(grep /--title=UNSANDBOXED MCP permission required/, @$args)
      && +(grep /WARNING: NO SANDBOX/, @$args),
      "unsandboxed helper prominently warns about full host-user authority";
   ok +(grep /^--field=Sandbox: NONE - UNSANDBOXED/, @$args),
      "unsandboxed implementation is displayed as a read-only label";
}

$decision = prompt $request,
   { status => 8, output => "Please review\x1f\n" },
   { status => 8, output => "TRUE\x1fFALSE\x1f2\x1f1\x1f\n" };
is $decision->{decision}, "allow-always", "Allow always enters separate rule dialog";
is $decision->{rule}{subject}, "^/one/", "rule editor chooses future scope";
is $decision->{rule}{"sandbox-grants"}, "read", "rule editor can reduce grants";
ok !exists $decision->{rule}{message}, "allow rule does not retain a denial reason";
{
   open my $log, "<", "$dir/log" or die $!;
   my $last;
   $last = $_ while <$log>;
   close $log;
   my $args = $json->decode ($last);
   is_deeply [grep /\A--field=.*:CHK\z/, @$args], [
      "--field=read - Read files:CHK", "--field=write - Modify files:CHK",
   ], "grant checkboxes only appear in rule editor";
   ok +(grep $_ eq "--field=Rule scope:CB", @$args),
      "rule scope selector appears only in rule editor";
   is_deeply [grep /\A--button=/, @$args], [
      "--button=Back:10", "--button=Save rule:8",
   ], "rule editor has Back and Save rule";
}


for my $case ([2, 900], [3, 57600]) {
   my ($index, $seconds) = @$case;
   my $before = time;
   my $answer = prompt $request,
      { status => 8, output => "\x1f\n" },
      { status => 8, output => "TRUE\x1fFALSE\x1f1\x1f$index\x1f\n" };
   ok $answer->{rule}{expires} >= $before + $seconds
      && $answer->{rule}{expires} <= time + $seconds,
      "YAD creates an allowance lasting $seconds seconds";
   is $answer->{lifetime}, "$seconds", "YAD retains lifetime for native elicitation forwarding";
}

$decision = prompt $request,
   { status => 6, output => "Temporary denial\x1f\n" },
   { status => 8, output => "1\x1f2\x1f\n" };
ok $decision->{rule}{expires} >= time + 899, "YAD supports expiring deny rules";
{
   open my $log, "<", "$dir/log" or die $!;
   my $last;
   $last = $_ while <$log>;
   close $log;
   my $args = $json->decode ($last);
   ok +(grep $_ eq "--field=Rule lifetime:CB", @$args),
      "YAD rule form offers a lifetime selector";
   ok +(grep $_ eq "^Indefinite\x1f900 seconds\x1f16 hours", @$args),
      "YAD offers exactly indefinite, 900 seconds and 16 hours";
}

# In native elicitation the server requests rule details in a separate round.
$decision = prompt { %$request, _permission_stage => "choice" },
   { status => 8, output => "Not a denial\x1f\n" };
is_deeply $decision, { decision => "allow-always" },
   "native choice stage defers rule editor instead of opening it twice";
$decision = prompt { %$request, _permission_stage => "rule",
   _permission_selection => { decision => "allow-always" } },
   { status => 8, output => "TRUE\x1fTRUE\x1f2\x1f1\x1f\n" };
is $decision->{rule}{subject}, "^/one/",
   "separate native rule stage saves the selected scope";
is $decision->{rule}{"sandbox-grants"}, "read,write",
   "separate native rule stage saves the selected grants";

$decision = prompt { %$request, _permission_stage => "choice" },
   { status => 6, output => "Do not repeat\x1f\n" };
is_deeply $decision, { decision => "deny-always", message => "Do not repeat" },
   "native deny-always choice also skips rule editor and retains reason";
$decision = prompt { %$request, _permission_stage => "rule",
   _permission_selection => $decision },
   { status => 8, output => "1\x1f1\x1f\n" };
is $decision->{rule}{message}, "Do not repeat",
   "separate native deny rule stage retains the previous reason";

my $expanded = prompt { %$request, sandbox_grant_choices => [qw(network read write)] },
   { status => 8, output => "Broad rule\x1f\n" },
   { status => 8, output => "TRUE\x1fFALSE\x1fTRUE\x1f2\x1f1\x1f\n" };
is_deeply $expanded->{sandbox_grants}, [qw(network write)],
   "rule editor can grant beyond current request";
is $expanded->{rule}{"sandbox-grants"}, "network,write",
   "broader grants are persisted for future invocations";

$decision = prompt $request,
   { status => 6, output => "Not there\x1f\n" },
   { status => 8, output => "1\x1f1\x1f\n" };
is_deeply $decision->{rule}, {
   decision => "deny", action => "write", subject => "/one/file",
   "sandbox-grants" => "write", message => "Not there",
}, "Deny always creates a rule including user message";
{
   open my $log, "<", "$dir/log" or die $!;
   my $last;
   $last = $_ while <$log>;
   close $log;
   my $args = $json->decode ($last);
   ok +(grep $_ eq "--text=Configure which future requests this rule covers.\nDenial reason: Not there", @$args),
      "YAD rule editor displays inherited denial reason read-only";
}

my $exact = { %$path_request, paths => ["/root/SCHMORP-PERL.md"] };
$decision = prompt $exact,
   { status => 6, output => "Use the Vim buffer instead\x1f\n" },
   { status => 8, output => "1\x1f1\x1f\n" };
is $decision->{rule}{path}, "/root/SCHMORP-PERL.md",
   "rule editor defaults to exact file for deny-always";

$decision = prompt $exact,
   { status => 8, output => "Noted\x1f\n" },
   { status => 10, output => "" },
   { status => 4, output => "Updated\x1f\n" };
is_deeply $decision, { decision => "allow-once", sandbox_grants => ["write"] },
   "Back returns to approval dialog and permits an allowance without a message";

$decision = prompt { %$exact, _permission_stage => "rule",
   _permission_selection => { decision => "deny-always", message => "From stage one" } },
   { status => 8, output => "1\x1f1\x1f\n" };
ok $decision->{rule}{path} eq "/root/SCHMORP-PERL.md"
   && $decision->{message} eq "From stage one",
   "local helper can answer native MCP rule stage using prior message";

$decision = prompt $request, { status => 052, output => "" };
is_deeply $decision, { decision => "deny-once" }, "closing YAD denies once";
$decision = prompt $request, { status => 4, output => "stray\x1fgarbage" };
is $decision->{decision}, "allow-once", "unused trailing output cannot alter initial grant";

{
   local $ENV{DISPLAY} = "";
   local $ENV{WAYLAND_DISPLAY} = "wayland-test";
   $decision = prompt $request, { status => 0, output => "\x1f\n" };
   is $decision->{decision}, "deny-once", "Wayland enables the graphical helper";
}
{
   local $ENV{DISPLAY} = "";
   local $ENV{WAYLAND_DISPLAY} = "";
   local $ENV{GDK_BACKEND} = "broadway";
   $decision = prompt $request, { status => 4, output => "Ready\x1f\n" };
   ok $decision->{decision} eq "allow-once" && !exists $decision->{message},
      "YAD is tried without DISPLAY/WAYLAND_DISPLAY, and allow ignores reason";
   $decision = prompt $request, { status => 1, output => "" };
   is_deeply $decision, { decision => "deny-once" }, "failed YAD falls back to missing tty";
}
$decision = prompt $request, { status => 1, output => "" };
is_deeply $decision, { decision => "deny-once" }, "unavailable YAD and terminal denies once";

$decision = prompt { %$request, rules_file => "$dir/rules.ini" },
   { status => 10, output => "" };
is_deeply $decision, { decision => "deny-once" }, "approval dialog has no rule management button";

# Rule deletion is a standalone command, by configured profile or explicit path.
{
   local $ENV{XDG_CONFIG_HOME} = "$dir/config";
   local $ENV{PATH} = "$dir:" . Cwd::abs_path ("bin") . ":$ENV{PATH}";
   mkdir "$dir/config" or die $!;
   mkdir "$dir/config/anyevent-mcp" or die $!;
   mkdir "$dir/config/anyevent-mcp/rules" or die $!;
   my $file = "$dir/config/anyevent-mcp/rules/fs-default.ini";
   write_file $file, "[rule]\ndecision=allow\naction=one\nsandbox-grants=\n\n[rule]\ndecision=deny\naction=two\n";
   chmod 0600, $file or die $!;
   write_file "$dir/queue", $json->encode ([
      { status => 2, output => "1\x1f\n" },
      { status => 0, output => "" },
   ]);
   my ($output, $error);
   my $status = AnyEvent::Util::run_cmd ([$^X, "-Ilib", "bin/anyevent-mcp", "manage-rules", "fs-default"],
      ">" => \$output, "2>" => \$error)->recv;
   is $status, 0, "anyevent-mcp manage-rules fs-default starts standalone rule manager";
   my $permissions = AnyEvent::MCP::Server::Permissions->new (file => $file);
   is_deeply $permissions->rules, [{ decision => "deny", action => "two" }],
      "short-name rule manager locates correct profile and deletes selected rule";
   write_file "$dir/queue", $json->encode ([{ status => 0, output => "" }]);
   $status = AnyEvent::Util::run_cmd ([$^X, "-Ilib", "bin/anyevent-mcp", "manage-rules-file", $file],
      ">" => \$output, "2>" => \$error)->recv;
   is $status, 0, "manage-rules-file accepts an explicit permission file path";
   $status = AnyEvent::Util::run_cmd ([$^X, "-Ilib", "bin/anyevent-mcp", "manage-rules", "../untrusted"],
      ">" => \$output, "2>" => \$error)->recv;
   isnt $status, 0, "short-name rule manager rejects paths and traversal";
   # Moving changes precedence, so check both directions against a real file.
   my $initial = "[rule]\ndecision=deny\naction=one\n\n[rule]\ndecision=deny\naction=two\n\n[rule]\ndecision=deny\naction=three\n\n";
   write_file $file, $initial;
   my $run = sub {
      my ($command, @args) = @_;
      my ($out, $err);
      my $rc = AnyEvent::Util::run_cmd ([$^X, "-Ilib", "bin/anyevent-mcp", $command, @args],
         ">" => \$out, "2>" => \$err)->recv;
      ($rc, $err // "")
   };
   write_file "$dir/queue", $json->encode ([{ status => 4, output => "2\x1f\n" }, { status => 0, output => "" }]);
   ($status, $error) = $run->("manage-rules", "fs-default");
   is $status, 0, "Move up completes";
   is_deeply [map $_->{action}, @{$permissions->rules}], [qw(two one three)],
      "Move up changes saved rule precedence";
   write_file "$dir/queue", $json->encode ([{ status => 6, output => "1\x1f\n" }, { status => 0, output => "" }]);
   ($status, $error) = $run->("manage-rules", "fs-default");
   is $status, 0, "Move down completes";
   is_deeply [map $_->{action}, @{$permissions->rules}], [qw(one two three)],
      "Move down restores saved rule order";

   my $editor_script = "#!$^X\n" . q{
use strict; use warnings;
my $mode = $ENV{ANYEVENT_MCP_TEST_EDITOR_MODE} // "append";
die "editor was not given the original rules file\n" unless $ARGV[-1] eq $ENV{ANYEVENT_MCP_TEST_EDITOR_TARGET};
exit 7 if $mode eq "fail";
open my $fh, ">>", $ARGV[-1] or die $!;
print {$fh} $mode eq "invalid" ? "this is not an INI rule\n"
   : "\n[rule]\ndecision=deny\naction=edited\n";
close $fh or die $!;
if ($mode eq "conflict") {
   open my $original, ">>", $ENV{ANYEVENT_MCP_TEST_EDITOR_TARGET} or die $!;
   print {$original} "\n[rule]\ndecision=deny\naction=concurrent\n";
   close $original or die $!;
}
};
   write_file "$dir/mock-editor", $editor_script;
   chmod 0700, "$dir/mock-editor" or die $!;
   local $ENV{VISUAL} = "$dir/mock-editor --with-option";
   local $ENV{EDITOR} = "/nonexistent/editor";
   local $ENV{ANYEVENT_MCP_TEST_EDITOR_MODE} = "append";
   local $ENV{ANYEVENT_MCP_TEST_EDITOR_TARGET} = $file;

   write_file $file, $initial;
   ($status, $error) = $run->("edit-rules", "fs-default");
   is $status, 0, "edit-rules uses VISUAL with arguments";
   is_deeply [map $_->{action}, @{$permissions->rules}], [qw(one two three edited)],
      "editor modifies the actual rule file, retaining rule ordering";
   is +(stat $file)[2] & 077, 0, "edited rule file remains private";

   write_file $file, $initial;
   $ENV{ANYEVENT_MCP_TEST_EDITOR_MODE} = "fail";
   ($status, $error) = $run->("edit-rules-file", $file);
   isnt $status, 0, "failed editor is reported as an error";
   is_deeply [map $_->{action}, @{$permissions->rules}], [qw(one two three)],
      "failed editor does not change the original rules";

   $ENV{ANYEVENT_MCP_TEST_EDITOR_MODE} = "invalid";
   ($status, $error) = $run->("edit-rules", "fs-default");
   is $status, 0, "editor's successful save is authoritative, without wrapper validation";
   {
      open my $invalid_fh, "<", $file or die $!;
      local $/;
      my $edited_text = <$invalid_fh>;
      close $invalid_fh;
      like $edited_text, qr/this is not an INI rule\n\z/,
         "even invalid syntax remains in directly edited file";
   }
   my $parsed = eval { $permissions->rules; 1 };
   ok !$parsed, "permission parser rejects invalid edited rules when later read";

   write_file $file, $initial;
   $ENV{ANYEVENT_MCP_TEST_EDITOR_MODE} = "conflict";
   ($status, $error) = $run->("edit-rules", "fs-default");
   is $status, 0, "wrapper delegates concurrent changes to the editor";
   is_deeply [map $_->{action}, @{$permissions->rules}], [qw(one two three edited concurrent)],
      "editor writes directly and preserves both modifications";

   $ENV{ANYEVENT_MCP_TEST_EDITOR_MODE} = "append";
   write_file $file, $initial;
   write_file "$dir/sensible-editor", $editor_script;
   chmod 0700, "$dir/sensible-editor" or die $!;
   $ENV{VISUAL} = "/nonexistent/visual";
   ($status, $error) = $run->("edit-rules", "fs-default");
   is $status, 0, "falls back from missing VISUAL/EDITOR to sensible-editor";
   ok +(grep $_->{action} eq "edited", @{$permissions->rules}),
      "sensible-editor fallback edits the requested profile";

   write_file $file, $initial;
   unlink "$dir/sensible-editor" or die $!;
   write_file "$dir/vi", $editor_script;
   chmod 0700, "$dir/vi" or die $!;
   local $ENV{PATH} = $dir;
   my ($out, $err);
   $status = AnyEvent::Util::run_cmd ([$^X, "-Ilib", "bin/anyevent-mcp-askpermission", "--edit-rules", $file],
      ">" => \$out, "2>" => \$err)->recv;
   is $status, 0, "falls back to vi when no other editor exists";
   ok +(grep $_->{action} eq "edited", @{$permissions->rules}),
      "vi fallback edits the requested rule file";

}

# A remote prepared request must not choose a local rules file.
my ($success, $result);
my $helper = AnyEvent::MCP::Permissions::Ask->new (helper => [$^X, "-MJSON::XS", "-e", q{
   local $/; my $request = decode_json <STDIN>;
   print encode_json { decision => "deny-once", saw_file => exists $request->{rules_file} ? 1 : 0 };
}]);
my $cv = AE::cv;
$helper->ask ({ %$request, rules_file => "/untrusted" }, sub { $cv->send ([@_]) });
($success, $result) = @{$cv->recv};
ok $success && !$result->{saw_file}, "forwarded request cannot select a local rules file";

# Client sandbox_grants cannot switch the default approval authority.
my $p = AnyEvent::MCP::Server::Permissions->new (
   sandbox_grants => { read => [] },
   helper => [$^X, "-e", 'local $/; scalar <STDIN>; print qq({"decision":"deny-once"});'],
);
my $req = AnyEvent::MCP::Server::Request->new (
   protocol_version => "2026-07-28", params => {
      _meta => { "io.modelcontextprotocol/clientCapabilities" => { elicitation => { form => {} } } },
   },
   on_reply => sub { die "Default policy delegated approval to the client\n" },
);
$cv = AE::cv;
$p->require ($req, { action => "read", sandbox_grants => ["read"], reason => "Test local approval" },
   sub { $cv->send ([@_]) });
($success, $result) = @{$cv->recv};
ok !$success && $result eq "Permission denied", "default stays local when the client advertises elicitation";

my $broad = AnyEvent::MCP::Server::Permissions->new (
   sandbox_grants => { read => [], write => ["read"], network => [] },
   sandbox_grant_descriptions => { read => "Read files" },
   actions => { write => "Modify resources" },
   sandbox_implementation => "bubblewrap",
);
my $wanted = {
   action => "write", sandbox_grants => ["read"], reason => "Read this file",
   sandbox_grant_descriptions => { read => "Misleading untrusted label" },
   action_description => "Misleading untrusted action label",
   sandbox_implementation => "NONE - misleading",
};
my $prepared = $broad->check ($wanted)->{request};
is $prepared->{action_description}, "Modify resources", "action description comes from the server";
is $prepared->{sandbox_implementation}, "bubblewrap", "sandbox implementation comes from the server";
is_deeply $prepared->{sandbox_grant_choices}, [qw(network read write)], "selector offers all known sandbox_grants";
is_deeply $prepared->{sandbox_grant_descriptions}, { read => "Read files" },
   "capability descriptions come from the server, not the tool request";
my $dynamic = AnyEvent::MCP::Server::Permissions->new (
   sandbox_grants => { read => [] },
   sandbox_grant_descriptions => sub {
      my ($request) = @_;
      { read => "Read " . $request->{selected_workdir} }
   },
);
is_deeply $dynamic->check ({ %$wanted, action => "read",
   selected_workdir => "/code", sandbox_grant_descriptions => { read => "forged" } })->{request}{sandbox_grant_descriptions},
   { read => "Read /code" }, "trusted per-request descriptions cannot be overridden by tool request";
my $answer = AnyEvent::MCP::Permissions::Ask::build ($prepared, {
   decision => "allow-always", sandbox_grants => [qw(read network)],
});
my $granted = $broad->resolve ($wanted, { request => $prepared, decision => $answer });
is_deeply $granted->{sandbox_grants}, ["read"], "broader saved allowance does not enlarge current grant";
is $broad->rules->[0]{"sandbox-grants"}, "read,network", "full selection is saved for the future";
is +($broad->check ({ %$wanted, sandbox_grants => ["network"] })->{decision}), "allow",
   "future request uses broader persisted allowance";

{
   @prompt_options = ("--tty");
   my $before = -s "$dir/log";
   my $answer = prompt $request;
   is_deeply $answer, { decision => "deny-once" }, "forced tty denies without a controlling terminal";
   is -s "$dir/log", $before, "forced tty never invokes YAD";
}
{
   @prompt_options = ("--yad");
   my $answer = prompt $request, { status => 4, output => "forced\x1f\n" };
   is $answer->{decision}, "allow-once", "forced YAD accepts a valid permission answer";
   $answer = prompt $request, { status => 1 };
   is_deeply $answer, { decision => "deny-once" }, "forced YAD denies when it cannot start";
}

done_testing;
