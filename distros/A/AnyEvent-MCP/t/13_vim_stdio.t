use common::sense;
use Test::More;
use JSON::XS ();
use IPC::Open3 ();
use IO::Select ();
use IO::Socket::INET ();
use POSIX qw(WNOHANG);
use Time::HiRes ();
use File::Temp ();
use File::Path ();
use Symbol ();

my $dir = File::Temp::tempdir (CLEANUP => 1);
File::Path::mkpath (["$dir/home", "$dir/config"], 0, 0700);
local $ENV{HOME} = "$dir/home";
local $ENV{XDG_CONFIG_HOME} = "$dir/config";

sub free_port {
   my $socket = IO::Socket::INET->new (
      LocalAddr => "127.0.0.1", LocalPort => 0,
      Proto => "tcp", Listen => 1,
   ) or die "cannot allocate TCP test port: $!";
   my $port = $socket->sockport;
   close $socket;
   $port
}

sub start_child {
   my ($use_env) = @_;
   my $port = free_port;
   local $ENV{PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL} = $use_env ? "stdio" : "";
   my $err = Symbol::gensym;
   my $pid = IPC::Open3::open3 (my $in, my $out, $err,
      $^X, "-Ilib", "bin/mcp-vim", "--bind", "127.0.0.1:$port", ($use_env ? () : ("--stdio")));
   my $old = select $in;
   $| = 1;
   select $old;
   ($pid, $in, $out, $err, $port)
}

sub rpc {
   my ($in, $out, $id, $method, $params) = @_;
   print {$in} JSON::XS::encode_json ({
      jsonrpc => "2.0", id => $id, method => $method, params => $params,
   }), "\n" or die "cannot send JSONL test request: $!";
   return unless IO::Select->new ($out)->can_read (30);
   my $line = <$out>;
   return unless defined $line;
   eval { JSON::XS::decode_json $line }
}

sub wait_exit {
   my ($pid) = @_;
   for (1 .. 1500) {
      my $w = waitpid ($pid, WNOHANG);
      return $? >> 8 if $w == $pid;
      Time::HiRes::sleep (0.02);
   }
   kill TERM => $pid;
   waitpid ($pid, 0);
   -1
}

for my $use_env (0, 1) {
   my $kind = $use_env ? "multibroker environment" : "explicit --stdio";
   my ($pid, $in, $out, $err, $port) = start_child ($use_env);

   my $init = rpc ($in, $out, 1, "initialize", {
      protocolVersion => "2025-11-25",
      capabilities => {}, clientInfo => { name => "stdio-test", version => "0" },
   });

   is $init->{id}, 1, "$kind: JSONL initialize response";
   ok !$init->{error} && $init->{result}{serverInfo},
      "$kind: valid MCP server metadata";

   my $tools = rpc ($in, $out, 2, "tools/list", {});
   is $tools->{id}, 2, "$kind: JSONL tools/list response";
   is_deeply [sort map $_->{name}, @{$tools->{result}{tools} || []}],
      [sort qw(targets state open read-lines grep apply-diff substitute undo redo save set-cursor ex meta-instructions)],
      "$kind: exposes thirteen unprefixed Vim tools including metadata";
   my ($substitute) = grep $_->{name} eq "substitute", @{$tools->{result}{tools} || []};
   ok defined $substitute && index ($substitute->{description}, q{\%^\_.*\%$}) >= 0,
      "$kind: substitute description preserves Vim regex backslashes and end anchor";
   ok !$tools->{error},
      "$kind: tools/list returned without an error";

   # The stdio transport must not prevent the normal Vim/browser TCP listener.
   my $sock;
   for (1 .. 1500) {
      $sock = IO::Socket::INET->new (
         PeerAddr => "127.0.0.1", PeerPort => $port,
         Proto => "tcp", Timeout => 1,
      );
      last if $sock;
      Time::HiRes::sleep (0.02);
   }
   ok $sock, "$kind: TCP listener remains available";
   if ($sock) {
      $sock->autoflush (1);
      print {$sock}
         "POST / HTTP/1.1\r\nHost: localhost\r\n"
         . "Content-Type: application/json\r\nContent-Length: 2\r\n\r\n{}";
      my $response = IO::Select->new ($sock)->can_read (30) ? <$sock> : undef;
      like $response, qr{\AHTTP/1\.1 401\b},
         "$kind: TCP listener still serves authenticated MCP HTTP";
      close $sock;
   } else {
      fail "$kind: HTTP listener response";
   }

   close $in;
   is wait_exit ($pid), 0, "$kind: stdin EOF stops the child cleanly";
   my $extra = <$out>;
   ok !defined $extra, "$kind: no extraneous stdout after final MCP response";
   close $out;
   close $err;
}

done_testing;
