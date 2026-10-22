use common::sense;
use Test::More;
use File::Temp ();
use IPC::Open3 ();
use Symbol ();
use Getopt::Long ();
use AnyEvent::MCP::Config ();
use AnyEvent::MCP::Server::Simple;
use AnyEvent::MCP::Server::HTTP ();

Getopt::Long::Configure ("require_order");

{
   local @ARGV = ("--name", "demo", "--bind", ":31740", "--token", "first",
      "--token", "second", "--stdio", "--custom", "yes", "positional");
   my $custom;
   my %options = mcp_getoptions ({ usage => "usage example\n" }, "custom=s" => \$custom);
   is $options{name}, "demo", "shared name";
   is $options{bind}, ":31740", "shared bind";
   is_deeply $options{tokens}, ["first", "second"], "repeatable ordered tokens";
   ok $options{stdio}, "shared stdio";
   is $custom, "yes", "Getopt::Long application option";
   is_deeply \@ARGV, ["positional"], "require_order leaves positional arguments";
}

{
   local @ARGV = ("--name", "memory", "--custom-instructions", "Use for lasting memories.");
   my %options = mcp_getoptions;
   is $options{custom_instructions}, "Use for lasting memories.",
      "common custom-instructions option returns instance purpose";
}

{
   local @ARGV = ("--name", "example");
   my %options = mcp_getoptions ({ path => "/custom/", auth => "none" });
   is $options{path}, "/custom/", "custom endpoint path is returned for startup";
   is $options{auth}, "none", "explicit unauthenticated mode passed to startup";
}

{
   local @ARGV = ("--bad-option");
   my $error;
   {
      local *STDERR;
      open STDERR, ">", "/dev/null" or die "open /dev/null: $!";
      eval { mcp_getoptions ({ usage => "custom usage\n" }) };
      $error = $@;
   }
   like $error, qr/custom usage/, "usage shown on invalid options";
}

{
   local @ARGV = ("--name", "example");
   my %options = mcp_getoptions;
   is_deeply \%options, { name => "example" }, "no unnecessary option defaults";
}

my $dir = File::Temp::tempdir (CLEANUP => 1);
local $ENV{XDG_CONFIG_HOME} = $dir;
my $config = AnyEvent::MCP::Config->new (file => "$dir/anyevent-mcp/global.ini");

sub command {
   my ($script, @argv) = @_;
   my $err = Symbol::gensym;
   my $pid = IPC::Open3::open3 (my $in, my $out, $err,
      $^X, "-Ilib", "-MAnyEvent::MCP::Server::Simple",
      "-e", $script,
      "--", @argv);
   close $in;
   local $/;
   my $stdout = <$out>;
   my $stderr = <$err>;
   waitpid $pid, 0;
   ($? >> 8, $stdout // "", $stderr // "")
}

my $script = 'mcp_getoptions ({ usage => "usage in subprocess\n", path => "/custom/" });';
my ($status, $out, $err) = command ($script, "--name", "demo", "--bind", ":31740",
   "--token", "first", "--token", "second", "--print-url");
is $status, 0, "shared print-url exits without starting a listener";
is $out, "http://127.0.0.1:31740/first/custom/\n", "print-url uses first CLI token and effective URL";
is $err, "", "print-url has no diagnostics";

($status, $out) = command ($script, "--name", "demo", "--help");
is $status, 0, "standard --help succeeds";
like $out, qr/\Ausage in subprocess\n\nCommon options:\n/,
   "shared help includes usage and common option heading";
like $out, qr/--name NAME\s+Select named configuration/,
   "common --name option documented";
like $out, qr/--token TOKEN\s+Set an accepted token/,
   "common repeatable token option documented";

unlike $out, qr/--listen/, "common parser does not advertise --listen";
($status, $out, $err) = command ($script, "--listen");
ok $status && $err =~ /Unknown option: listen/, "common parser rejects --listen";

my $rich = 'my $extra; mcp_getoptions ({'
   . 'usage => "Usage: fixture [OPTION]...\\n", '
   . 'description => "A test server.", '
   . 'option_heading => "Fixture options:", '
   . 'options => [["--extra VALUE", "A configurable value"]], '
   . 'examples => "  fixture --extra yes"}, '
   . '"extra=s" => \\$extra);';
($status, $out, $err) = command ($rich, "--help");
ok !$status && !$err && $out =~ /Fixture options:.*--extra VALUE.*A configurable value/s
   && $out =~ /Examples:\n  fixture --extra yes/, "caller option descriptions and examples appear";

($status, $out, $err) = command ($script, "--name", "demo", "--bind", ":0", "--print-url");
ok $status && $err =~ /port is not known/, "ephemeral port cannot be printed offline";

open my $fh, ">>", "$dir/anyevent-mcp/global.ini" or die $!;
print {$fh} "\n[instance named]\npath = /named/\n";
close $fh or die $!;
($status, $out, $err) = command ('mcp_getoptions;', "--name", "named",
   "--bind", ":31740", "--token", "static", "--print-url");
is $status, 0, "named endpoint URL discovery succeeds";
is $out, "http://127.0.0.1:31740/static/named/\n",
   "shared print-url retains named server path";

open $fh, ">>", "$dir/anyevent-mcp/global.ini" or die $!;
print {$fh} "\n[program perl]\ncustom_instructions = Program purpose\n"
   . "[instance named]\ncustom_instructions = Instance purpose\n";
close $fh or die $!;

my $probe = 'mcp_config instructions => "Operating rules", short_instructions => "Discover tools"; '
   . 'my %options = mcp_getoptions; '
   . 'mcp_start %options, auth => "none", port => 0, on_start => sub { '
   . 'print $_[0]{instructions}, "\\n"; $_[0]->close };';
($status, $out, $err) = command ($probe, "--name", "other");
is $status, 0, "program-level custom instructions start";
my $hint = "\n\nFull instructions: meta-instructions tool description.\n";
is $out, "Program purpose\n\nDiscover tools$hint", "program-level purpose advertised";
($status, $out, $err) = command ($probe, "--name", "named");
is $status, 0, "instance-level custom instructions start";
is $out, "Instance purpose\n\nDiscover tools$hint", "instance setting overrides program setting";
($status, $out, $err) = command ($probe, "--name", "named", "--custom-instructions", "CLI purpose");
is $status, 0, "CLI custom instructions start";
is $out, "CLI purpose\n\nDiscover tools$hint", "CLI purpose overrides instance setting";

for my $bad (
   {},
   { tokens => [] },
   { tokens => ["good", "bad/token"] },
   { auth => "unknown" },
   { auth => "none", tokens => ["x"] },
) {
   eval { AnyEvent::MCP::Server::HTTP->new (%$bad) };
   ok $@, "insecure or invalid constructor rejected";
}

my $open = AnyEvent::MCP::Server::HTTP->new (port => 31740, auth => "none");
is $open->{auth}, "none", "unauthenticated HTTP requires explicit opt-out";
is $open->url, "http://127.0.0.1:31740/mcp/", "unauthenticated URL has no secret segment";

my $secured = AnyEvent::MCP::Server::HTTP->new (port => 31740, tokens => ["first", "second"]);
is $secured->url, "http://127.0.0.1:31740/first/mcp/", "first token advertised";
is $secured->url (0), "http://127.0.0.1:31740/mcp/", "clean URL available";

is $config->http_url ("demo", ":31740", path => "/", auth => "none"),
   "http://127.0.0.1:31740/", "explicit unauthenticated URL contains no token";

my %http = $config->http_settings ("demo");
is $config->credential ("token", "demo"), $http{tokens}[0],
   "derived default uses token HKDF purpose";

my $unstable = AnyEvent::MCP::Config->new (file => "$dir/anyevent-mcp/global.ini");
my $first = substr $unstable->{section}{global}{secret}, 0, 1;
substr ($unstable->{section}{global}{secret}, 0, 1) = $first eq "0" ? "1" : "0";
eval { $unstable->http_url ("demo", ":31740", path => "/") };
like $@, qr/not persistently stored/, "derived URL refuses an unstable master secret";
is $unstable->http_url ("demo", ":31740", path => "/", tokens => ["fixed"]),
   "http://127.0.0.1:31740/fixed/", "static token URL does not need persistent HKDF secret";

my ($started, $mode);
{
   open my $fh, ">>", "$dir/anyevent-mcp/global.ini" or die $!;
   print {$fh} <<'INI';

[program perl]
auto-rule.30 = deny *,exec,*
auto-rule.10 = allow *,read,workdir-read
auto-rule.20 = allow *,write,workdir-write

[instance named]
auto-rule.20 = deny *,write,workdir-write
auto-rule.30 =
auto-rule.40 = allow tabs
INI
   close $fh or die $!;
   local $0 = "perl"; # match the -e program name used by the child probes.
   my $configured = AnyEvent::MCP::Config->new (file => "$dir/anyevent-mcp/global.ini");
   is_deeply [$configured->auto_rules ("other")], [
      ["allow", "*,read,workdir-read"],
      ["allow", "*,write,workdir-write"],
      ["deny", "*,exec,*"],
   ], "program-level permission rules sorted by key";
   is_deeply [$configured->auto_rules ("named")], [
      ["allow", "*,read,workdir-read"],
      ["deny", "*,write,workdir-write"],
      ["allow", "tabs"],
   ], "instance overrides, removes, and adds inherited permission rules";
   $configured->{section}{"instance named"}{"auto-rule.40"} = "bad";
   eval { $configured->auto_rules ("named") };
   like $@, qr/Invalid configured automatic permission rule/, "invalid configured rule rejected";
}

my $auto_probe = q{
   require AnyEvent::MCP::Server::Permissions;
   my %options = mcp_getoptions;
   my $p = AnyEvent::MCP::Server::Permissions->new (
      sandbox_grants => {
         "workdir-read" => [],
         "workdir-write" => ["workdir-read"],
      },
   );
   mcp_start %options, permissions => $p, auth => "none", port => 0, on_start => sub {
      print join (" ", map {
         $p->check ({ action => $_->[0], sandbox_grants => $_->[1], reason => "test" }, $_->[2])->{decision}
      } (["read", ["workdir-write"], "x"], ["write", ["workdir-write"], "x"],
         ["exec", [], "x"], ["inspect", [], "tabs"])), "\n";
      $_[0]->close;
   };
};
my ($autostatus, $autoout, $autoerr) = command ($auto_probe, "--name", "named");
ok !$autostatus && !$autoerr && $autoout eq "ask deny ask allow\n",
   "mcp_start loads ordered instance defaults and leaves unmatched requests to prompting";
($autostatus, $autoout, $autoerr) = command ($auto_probe, "--name", "named",
   "--auto-allow=*,write,*");
ok !$autostatus && !$autoerr && $autoout eq "ask allow ask allow\n",
   "CLI rule takes precedence over named program/instance defaults";

mcp_start
   name => "explicit_no_auth",
   auth => "none", port => 0,
   on_start => sub {
      $started = 1;
      $mode = $_[0]{auth};
      $_[0]->close;
   };
ok $started && $mode eq "none", "Simple supports deliberate auth none without inherited tokens";

for my $program (qw(mcp-fs mcp-ask-user mcp-multibroker mcp-vim mcp-webbrowser)) {
   my $err = Symbol::gensym;
   my $pid = IPC::Open3::open3 (my $in, my $out, $err,
      $^X, "-Ilib", "bin/$program", "--help");
   close $in;
   local $/;
   my $help = <$out> // "";
   my $stderr = <$err> // "";
   waitpid $pid, 0;
   is $? >> 8, 0, "$program --help exits successfully";
   like $help, qr/\AUsage: .+\n/, "$program has GNU-style synopsis";
   like $help, qr/\nCommon options:\n.*--token TOKEN/s,
      "$program includes shared MCP options";
   like $help, qr/\nExamples:\n/, "$program includes practical examples"
      unless $program eq "mcp-webbrowser";
   if ($program eq "mcp-multibroker") {
      like $help, qr/--listen/, "$program advertises its optional HTTP listener";
   } else {
      unlike $help, qr/--listen/, "$program does not advertise --listen";
   }
   like $help, qr/--bind ADDRESS/, "$program retains configurable bind address";
   like $help, qr/Filesystem options:/, "filesystem options documented"
      if $program eq "mcp-fs";
   if ($program eq "mcp-multibroker") {
      like $help, qr/\nBroker-wide options:\n\s+--ask MODE\b/,
         "multibroker --ask is documented as broker-wide";
      like $help, qr/\nDownstream options \(after the URL or closing ---\):\n\s+--eager\b.*\n\s+--bearer TOKEN\b/s,
         "multibroker --eager and --bearer are explicitly downstream options";
      unlike $help, qr/Downstream options[^\n]*\n\s+--ask MODE\b/,
         "multibroker --ask is not mislabeled as a downstream option";
   }
}

my $tool_probe = q{
   mcp_tool "sample" => "Explain this tool.", {
      type => "object",
      properties => {
         path => { type => "string", description => "Selected path" },
         choice => { type => "string", enum => ["a", "b"], default => "a" },
         ids => { type => "array", items => { type => "integer" } },
         target => { anyOf => [{ type => "integer" }, { type => "string" }] },
      },
      required => ["path", "target"],
   }, sub {};
   my %opts = mcp_getoptions;
   mcp_start %opts;
};
($status, $out, $err) = command ($tool_probe, "--tool-help");
is $status, 0, "tool-help exits without starting server";
like $out, qr/\Asample\n  Explain this tool\./,
   "tool-help reads actual registered description";
like $out, qr/path  string  required\n    Selected path/,
   "tool-help prints required argument and its description";
like $out, qr/choice  string  optional \(default: "a"; values: a, b\)/,
   "tool-help prints defaults and allowed values";
like $out, qr/ids  array\[integer\]  optional/,
   "tool-help formats array element types";
like $out, qr/target  integer\|string  required/,
   "tool-help prints union types";
is $err, "", "tool-help does not start a listener or produce diagnostics";

my %tool_name = (
   "mcp-fs" => "workdirs", "mcp-vim" => "targets",
   "mcp-webbrowser" => "tabs", "mcp-ask-user" => "ask-user",
   "mcp-multibroker" => "discover-brokers",
);
for my $program (sort keys %tool_name) {
   my $error = Symbol::gensym;
   my @extra = $program eq "mcp-fs" ? ("--sandbox", "none", ".") : ();
   my $pid = IPC::Open3::open3 (my $in, my $stdout, $error,
      $^X, "-Ilib", "bin/$program", "--tool-help", @extra);
   close $in;
   local $/;
   my $output = <$stdout> // "";
   my $stderr = <$error> // "";
   waitpid $pid, 0;
   ok !$? && $output =~ /\A\Q$tool_name{$program}\E\n/ && $output =~ /  [a-z_-]+  /,
      "$program prints registered tools with arguments and exits";
}

local $ENV{PERL_ANYEVENT_LOG} = ""; # test the default logger, not the harness filter.
my $log_probe = q{
   use JSON::XS ();
   my %options = mcp_getoptions;
   my $req = {
      method => "tools/call", tool => "file-patch",
      args => { path => "lib/Foo.pm" },
      on_reply => sub {},
   };
   mcp_log_request (undef, $req);
   mcp_log_request (undef, $req); # permission retry
   $req->{on_reply}->($req, {
      isError => 1, content => [{ text => "hunk failed\nadditional detail" }],
   });
   mcp_log_request (undef, {
      method => "tools/call", tool => "path-op",
      args => {workdir => 4, path => "foo", unlink => JSON::XS::true,
         rmdir => JSON::XS::false, mkpath => "0700", symlink => "x" x 200, chmod => "0600", rename => "bar"},
      on_reply => sub {},
   });
   mcp_log_request (undef, {
      method => "tools/call", tool => "ex",
      args => { target => "editor", command => "echo 1\n" . ("x" x 300) },
      on_reply => sub {},
   });
   mcp_log_request (undef, {
      method => "tools/call", tool => "exec",
      args => {workdir => 1, argv => ["perl", "-e", "print qq(hello\nworld)", "x" x 140, "ignored"]},
      on_reply => sub {},
   });
   mcp_log_request (undef, {
      method => "tools/call", tool => "grep",
      args => {workdir => 1, path => "t", pattern => "foo\n" . ("y" x 200)},
      on_reply => sub {},
   });
   AE::log error => "diagnostic failure";
};
($status, $out, $err) = command ($log_probe, "--name", "example");
is $status, 0, "activity log probe exits cleanly";
like $err, qr/\A\d\d \d\d:\d\d:\d\d\.\d\d [^\s]+\/example\[\d+\] file-patch path=lib\/Foo\.pm\n/,
   "default activity log has short process-wide timestamp and process identity";
is scalar (() = $err =~ /file-patch path=lib\/Foo\.pm/g), 1,
   "a permission retry does not duplicate activity logging";
like $err, qr/file-patch failed: hunk failed\n/,
   "asynchronous-style tool error replies are logged without their long details";
like $err, qr/path-op workdir=4 path=foo unlink mkpath=0700 symlink=x{80} chmod=0600 rename=bar\n/,
   "path-op logs operations in execution order, omitting false flags and truncating long operands";
like $err, qr/ex target=editor command="echo 1\\nx{193}"\.\.\.\n/,
   "Ex log preview preserves escaped newlines and limits command text to 200 characters";
like $err, qr/exec workdir=1 argv="perl" "-e" "print qq\(hello\\nworld\)" "x{80}"\.\.\. \.\.\.\n/,
   "exec logs several JSON-quoted arguments, caps long ones and marks omitted arguments";
like $err, qr/grep workdir=1 path=t pattern="foo\\ny{156}"\.\.\.\n/,
   "grep logs the bounded search pattern with escaped newlines";
like $err, qr/\d\d \d\d:\d\d:\d\d\.\d\d [^\s]+\/example\[\d+\] error main: diagnostic failure\n/,
   "ordinary diagnostics use the same process-wide formatter";
($status, $out, $err) = command ($log_probe, "--quiet");
is $status, 0, "--quiet exits normally";
unlike $err, qr/file-patch|path-op|ex target=/, "--quiet suppresses activity and tool errors";
like $err, qr/error main: diagnostic failure/, "--quiet leaves normal diagnostics alone";

{
   local $ENV{PERL_ANYEVENT_LOG} = "log=file=$dir/activity.log";
   ($status, $out, $err) = command ($log_probe . q{
      my $cv = AE::cv;
      my $timer = AE::timer 0.2, 0, sub { $cv->send };
      $cv->recv;
   }, "--name", "redirect");
}
is $status, 0, "explicit AnyEvent::Log redirection succeeds";
is $err, "", "log=file sends activity and diagnostics away from stderr";
open my $fh, "<", "$dir/activity.log" or die $!;
local $/;
my $redirected = <$fh>;
close $fh;
like $redirected, qr/redirect\[\d+\] file-patch path=lib\/Foo.pm/,
   "activity uses existing AnyEvent::Log file destination";
like $redirected, qr/redirect\[\d+\] error main: diagnostic failure/,
   "diagnostics use the same existing AnyEvent::Log file destination";

done_testing;
