use common::sense;
use Test::More;
use AnyEvent ();
use AnyEvent::MCP::Client::JSONL ();
use File::Temp ();
use File::Path ();
use IPC::Open3 ();
use Symbol ();

sub write_file {
   my ($file, $body) = @_;
   open my $fh, ">", $file or die "$file: $!";
   print {$fh} $body or die "$file: $!";
   close $fh or die "$file: $!";
}

sub shell_quote {
   my $text = shift;
   $text =~ s/'/'\\''/g;
   "'$text'"
}

sub wait_for {
   my ($start) = @_;
   my $cv = AnyEvent->condvar;
   my $timer = AnyEvent->timer (after => 30, cb => sub { $cv->send (undef) });
   $start->(sub { $cv->send ([@_]) });
   my $r = $cv->recv;
   die "eager broker test timeout\n" unless defined $r;
   @$r
}

sub await_file {
   my ($path) = @_;
   my $cv = AnyEvent->condvar;
   my ($tick, $timeout);
   $tick = AnyEvent->timer (after => 0, interval => 0.02, cb => sub {
      $cv->send (1) if -f $path;
   });
   $timeout = AnyEvent->timer (after => 30, cb => sub { $cv->send (0) });
   $cv->recv
}

my $dir = File::Temp::tempdir (CLEANUP => 1);
my $child = "$dir/child.pl";
write_file $child, q{
use common::sense;
use AnyEvent ();
use AnyEvent::MCP::Server::Simple;
my $marker = shift;
my $idle = shift;
my $force_stdio = shift;
mcp_config idle_exit => $idle if defined $idle;
open my $fh, ">", $marker or die "$marker: $!";
print {$fh} $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS};
close $fh;
END {
   if (defined $idle) {
      open my $fh, ">", "$marker.exited" or die $!;
      print {$fh} "exited\n";
      close $fh;
   }
}
mcp_tool probe => "probe startup", {}, sub {
   $_[0]->result ({
      prefix => $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS},
      protocol => $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL},
      pid => $$,
   });
};
mcp_tool slow => "delayed", {}, sub {
   my ($req) = @_;
   my $timer;
   $timer = AnyEvent->timer (after => 0.15, cb => sub {
      undef $timer;
      $req->result ({ pid => $$ });
   });
};
$force_stdio ? mcp_stdio () : mcp_start ();
};

my ($eager, $lazy) = ("$dir/eager", "$dir/lazy");
my $command = sub {
   my $file = shift;
   "stdio:" . join (" ", map shell_quote ($_), $^X, "-Ilib", $child, $file)
};

my $client = AnyEvent::MCP::Client::JSONL->new (
   command => [
      $^X, "-Ilib", "bin/mcp-multibroker",
      eager => "---", $^X, "-Ilib", $child, $eager, "---", "--eager",
      lazy  => $command->($lazy),
   ],
   env => {
      PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
      XDG_CONFIG_HOME => "$dir/config",
   },
);

my ($success, $result) = wait_for (sub { $client->connect ($_[0]) });
ok $success, "multibroker upstream connects without using downstream tools";
ok await_file ($eager), "eager stdio child starts before its first tool request";
ok !-e $lazy, "second stdio child remains lazy";

($success, $result) = wait_for (sub { $client->call ("eager.probe", {}, $_[0]) });
ok $success && $result->{structuredContent}{prefix} eq "eager"
   && $result->{structuredContent}{protocol} eq "stdio",
   "eager child handles MCP tools";

($success, $result) = wait_for (sub { $client->call ("lazy.probe", {}, $_[0]) });
ok $success && $result->{structuredContent}{prefix} eq "lazy",
   "lazy child starts when first used";
ok -f $lazy, "lazy child marker created only after first use";
$client->close;

# --required implies eager, even without an explicit --eager.
my $required_marker = "$dir/required";
my $required_client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker",
      required => "---", $^X, "-Ilib", $child, $required_marker, "---", "--required"],
   env => {
      PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
      XDG_CONFIG_HOME => "$dir/required-config",
   },
);
($success, $result) = wait_for (sub { $required_client->connect ($_[0]) });
ok $success && await_file ($required_marker), "--required implies eager startup";
($success, $result) = wait_for (sub { $required_client->call ("required.probe", {}, $_[0]) });
ok $success && $result->{structuredContent}{prefix} eq "required",
   "required child has initialized successfully";
$required_client->close;

# Required children must also cause a nonzero broker exit when they die later.
my $crashing_child = "$dir/crash-child.pl";
write_file $crashing_child, q{
use common::sense;
use AnyEvent ();
use AnyEvent::MCP::Server::Simple;
mcp_tool probe => "probe", {}, sub { $_[0]->result ({ ok => 1 }) };
my $timer = AnyEvent->timer (after => 0.5, cb => sub { exit 17 });
mcp_start;
};
my $broker_exit = sub {
   my (@args) = @_;
   my $err = Symbol::gensym;
   local $ENV{XDG_CONFIG_HOME} = "$dir/required-config";
   my $pid = IPC::Open3::open3 (my $in, my $out, $err,
      $^X, "-Ilib", "bin/mcp-multibroker", "--stdio", @args);
   require Time::HiRes;
   require POSIX;
   my ($status, $finished);
   my $deadline = Time::HiRes::time () + 10;
   while (Time::HiRes::time () < $deadline) {
      if (waitpid ($pid, POSIX::WNOHANG ()) == $pid) {
         $status = $? >> 8;
         $finished = 1;
         last;
      }
      Time::HiRes::sleep (0.02);
   }
   unless ($finished) {
      kill TERM => $pid;
      waitpid ($pid, 0);
   }
   close $in;
   close $out;
   local $/;
   my $diagnostic = <$err> // "";
   close $err;
   ($status, $diagnostic)
};
my ($exit_status, $error_text) = $broker_exit->(
   bad => "---", $^X, "-e", "exit 13", "---", "--required"
);
ok defined $exit_status && $exit_status == 1 && $error_text =~ /bad: required child/,
   "required child startup failure exits multibroker with error";
($exit_status, $error_text) = $broker_exit->(
   crash => "---", $^X, "-Ilib", $crashing_child, "---", "--required"
);
ok defined $exit_status && $exit_status == 1 && $error_text =~ /crash: required child/,
   "unexpected death after required child startup exits multibroker with error";

($exit_status, $error_text) = $broker_exit->(
   http => "http://127.0.0.1:12345/", "--required"
);
ok defined $exit_status && $exit_status != 0
   && $error_text =~ /--required requires a stdio broker/,
   "HTTP children cannot be marked required";

# A flag after a broker pair belongs to that pair, not to the entire command.
# --eager is invalid for HTTP and must not silently enable any stdio peer.
my $stderr = Symbol::gensym;
my $pid = IPC::Open3::open3 (my $in, my $out, $stderr,
   $^X, "-Ilib", "bin/mcp-multibroker",
   http => "http://127.0.0.1:12345/", "--eager",
);
close $in;
local $/;
my $diagnostic = <$stderr>;
my $status = waitpid ($pid, 0);
ok $status == $pid && ($? >> 8) != 0
   && $diagnostic =~ /--eager requires a stdio broker/,
   "HTTP --eager is rejected with useful error";
close $out;
close $stderr;

# Direct argv preserves every byte without shell evaluation or option stealing.
my $argv_child = "$dir/argv child.pl";
write_file $argv_child, q{
use common::sense;
use AnyEvent::MCP::Server::Simple;
mcp_tool argv => "argv bytes", {}, sub {
   $_[0]->result ({
      argv => [map unpack ("H*", $_), @ARGV],
      alias => $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS},
      protocol => $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL},
   });
};
mcp_start;
};
my @args = ("", "white space", "'\"\\", "--", "--eager", "--required", "--bearer", "--ask", "*", "\xce\xbb", "\xff",
   "; touch $dir/shell-ran", "\$(touch $dir/shell-ran)", "> $dir/shell-ran");
$client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-multibroker",
      direct => "---", $^X, "-Ilib", $argv_child, @args, "---",
      shell => "stdio:" . join (" ", map shell_quote ($_), $^X, "-Ilib", $argv_child, "---"),
   ],
   env => {
      PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
      XDG_CONFIG_HOME => "$dir/argv-config",
   },
);
($success, $result) = wait_for (sub { $client->call ("direct.argv", {}, $_[0]) });
ok $success, "direct argv child responds";
is_deeply $result->{structuredContent}{argv}, [map unpack ("H*", $_), @args],
   "direct argv preserves empty arguments, option names, shell syntax and non-ASCII bytes";
is $result->{structuredContent}{alias}, "direct", "direct argv child inherits its alias";
is $result->{structuredContent}{protocol}, "stdio", "direct argv child inherits its stdio protocol";
ok !-e "$dir/shell-ran", "child arguments are not evaluated as shell source";
($success, $result) = wait_for (sub { $client->call ("shell.argv", {}, $_[0]) });
ok $success, "legacy shell entry following direct argv still works";
is_deeply $result->{structuredContent}{argv}, [unpack "H*", "---"],
   "legacy shell form can pass the reserved delimiter as an argument";
$client->close;

for my $case (
   [["child", "---", "---"], qr/Empty stdio argv/],
   [["child", "---", "", "---"], qr/Empty stdio argv/],
   [["child", "---", $^X], qr/Missing closing ---/],
   [["child", "---", $^X, "---", "--bearer", "token"], qr/Authentication options require an HTTP broker/],
   [["child", "---", $^X, "---", "--unknown-child-option"], qr/Unknown option/],
) {
   my $stderr = Symbol::gensym;
   my $pid = IPC::Open3::open3 (my $in, my $out, $stderr,
      $^X, "-Ilib", "bin/mcp-multibroker", "--stdio", @{$case->[0]});
   close $in;
   local $/;
   my $diagnostic = <$stderr>;
   my $status = waitpid ($pid, 0);
   ok $status == $pid && ($? >> 8) != 0 && $diagnostic =~ $case->[1],
      "malformed argv entry or misplaced downstream option is rejected";
   close $out;
   close $stderr;
}

SKIP: {
   skip "extended idle lifetime tests (PERL_ANYEVENT_MCP_TESTS=1)", 7 unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;

   my $idle = "$dir/idle";
   my $idle_command = $command->($idle) . " 0.05";
   $client = AnyEvent::MCP::Client::JSONL->new (
      command => [$^X, "-Ilib", "bin/mcp-multibroker", idle => $idle_command],
      env => {
         PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
         XDG_CONFIG_HOME => "$dir/idle-config",
      },
   );
   ($success, $result) = wait_for (sub { $client->call ("idle.slow", {}, $_[0]) });
   my $first_pid = $result->{structuredContent}{pid};
   ok $success && $first_pid, "long-running request survives configured idle interval";
   ok await_file ("$idle.exited"), "managed idle shutdown terminates child gracefully";
   ($success, $result) = wait_for (sub { $client->call ("idle.probe", {}, $_[0]) });
   ok $success && $result->{structuredContent}{pid} != $first_pid,
      "next access reconnects after managed idle shutdown";
   $client->close;

   my $required_idle = "$dir/required-idle";
   $client = AnyEvent::MCP::Client::JSONL->new (
      command => [$^X, "-Ilib", "bin/mcp-multibroker",
         idle => $command->($required_idle) . " 0.05", "--required"],
      env => {
         PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio",
         XDG_CONFIG_HOME => "$dir/required-idle-config",
      },
   );
   ($success, $result) = wait_for (sub { $client->call ("idle.slow", {}, $_[0]) });
   $first_pid = $result->{structuredContent}{pid};
   ok await_file ("$required_idle.exited"),
      "required child may exit after explicitly accepted managed idle shutdown";
   ($success, $result) = wait_for (sub { $client->call ("idle.probe", {}, $_[0]) });
   ok $success && $result->{structuredContent}{pid} != $first_pid,
      "required child reconnects after managed idle shutdown without killing broker";
   $client->close;

   my $plain_marker = "$dir/plain";
   my $plain = AnyEvent::MCP::Client::JSONL->new (
      command => [$^X, "-Ilib", $child, $plain_marker, "0.05", "stdio"],
   );
   ($success, $result) = wait_for (sub { $plain->call ("probe", {}, $_[0]) });
   $first_pid = $result->{structuredContent}{pid};
   ok $success && $first_pid, "ordinary MCP client starts idle_exit-configured server";
   my $cv = AnyEvent->condvar;
   my $wait = AnyEvent->timer (after => 0.2, cb => sub { $cv->send });
   $cv->recv;
   ($success, $result) = wait_for (sub { $plain->call ("probe", {}, $_[0]) });
   ok $success && $result->{structuredContent}{pid} == $first_pid
      && !-f "$plain_marker.exited",
      "no idle exit for ordinary stdio client without multibroker handshake";
   $plain->close;

}

done_testing;
