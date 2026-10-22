use common::sense;
use Test::More;
BEGIN { delete $ENV{http_proxy} }
use AnyEvent ();
use AnyEvent::Util ();
use AnyEvent::Handle ();
use AnyEvent::MCP::Client::HTTP ();
use AnyEvent::MCP::Client::JSONL ();
use AnyEvent::MCP::Server::Permissions ();
use AnyEvent::MCP::File ();
use File::Temp ();
use File::Path ();
use Cwd ();
use JSON::XS ();
use MIME::Base64 ();
use IO::Socket::INET ();
use Socket ();
use Time::HiRes ();

my %utility;
for my $name (qw(find grep patch sed)) {
   my ($path) = grep -f && -x _, map "$_/$name", split /:/, $ENV{PATH};
   next unless $path && open my $fh, "-|", $path, "--version";
   my $version = do { local $/; <$fh> };
   $utility{$name} = $path if close $fh && $version =~ /GNU/;
}

sub wait_for {
   my ($start) = @_;
   my $cv = AnyEvent->condvar;
   my $timer = AnyEvent->timer (after => 30, cb => sub { die "Filesystem test timeout\n" });
   $start->(sub { $cv->send ([@_]) });
   @{$cv->recv}
}
sub write_file {
   my ($path, $text) = @_;
   open my $fh, ">", $path or die "$path: $!";
   print $fh $text;
   close $fh or die "$path: $!";
}
sub read_file {
   open my $fh, "<", $_[0] or die "$_[0]: $!";
   local $/;
   scalar <$fh>
}

my $dir = File::Temp::tempdir (CLEANUP => 1);
File::Path::mkpath (["$dir/work", "$dir/home", "$dir/config/anyevent-mcp/rules", "$dir/bin"], 0, 0700);
symlink $^X, "$dir/bin/perl" or die "$dir/bin/perl: $!";
socket my $agent, Socket::AF_UNIX (), Socket::SOCK_STREAM (), 0 or die $!;
bind $agent, Socket::sockaddr_un ("$dir/agent") or die $!;
File::Path::mkpath ("$dir/home/.ssh", 0, 0700);
write_file "$dir/home/.ssh/known_hosts", "test host key\n";
my $root = Cwd::abs_path ".";
my $patch = $utility{patch} && Cwd::abs_path $utility{patch};

# This driver records the real bwrap argv and runs workers without namespaces.
# It tests routing, filesystem operations and approval boundaries; it does not
# claim to test kernel isolation.
write_file "$dir/bwrap", "#!$^X\n" . q{
use common::sense;
use JSON::XS ();
open my $log, ">>", "$ENV{PERL_ANYEVENT_MCP_TEST_FS_DIR}/sandbox.log" or die $!;
print $log JSON::XS::encode_json (\@ARGV), "\n";
close $log;
open my $pids, ">>", "$ENV{PERL_ANYEVENT_MCP_TEST_FS_DIR}/worker-pids" or die $!;
print {$pids} "$$\n";
close $pids or die $!;
while (@ARGV) {
   my $option = shift @ARGV;
   last if $option eq "--";
   if ($option =~ /\A--(?:ro-bind(?:-try)?|bind(?:-try)?)\z/) {
      my ($source, $destination) = splice @ARGV, 0, 2;
   } elsif ($option eq "--file") {
      my ($fd, $path) = splice @ARGV, 0, 2;
      die "Unexpected file mount $path\n" unless $path eq "/etc/passwd";
      open my $input, "<&=$fd" or die "passwd FD: $!";
      open my $output, ">", "$ENV{PERL_ANYEVENT_MCP_TEST_FS_DIR}/passwd.log" or die $!;
      print {$output} do { local $/; <$input> };
      close $output or die $!;
   } elsif ($option eq "--setenv") {
      my ($key, $value) = splice @ARGV, 0, 2;
      $ENV{$key} = $value;
   } elsif ($option eq "--chdir") {
      chdir shift @ARGV or die $!;
   } elsif ($option =~ /\A--(?:tmpfs|dev|proc|remount-ro|cap-drop)\z/) {
      shift @ARGV;
   } elsif ($option !~ /\A--(?:die-with-parent|new-session|unshare-[a-z-]+|disable-userns|clearenv)\z/) {
      die "Unknown sandbox option $option\n";
   }
}
$ENV{PATH} = $ENV{PERL_ANYEVENT_MCP_TEST_FS_SANDBOX_PATH}
   if exists $ENV{PERL_ANYEVENT_MCP_TEST_FS_SANDBOX_PATH};
if ((grep /\A#perl\n   binmode STDIN;/, @ARGV) && open my $mode_file, "<", "$ENV{PERL_ANYEVENT_MCP_TEST_FS_DIR}/response-mode") {
   chomp (my $mode = <$mode_file>);
   close $mode_file;
   unlink "$ENV{PERL_ANYEVENT_MCP_TEST_FS_DIR}/response-mode" or die $!;
   binmode STDIN;
   binmode STDOUT;
   $| = 1;
   4 == read STDIN, my $request, 4 or die "request header: $!";
   my $length = unpack "N", $request;
   $length == read STDIN, $request, $length or die "request body: $!";
   my $frame = pack "N/a*", pack "(w/a*)*", "+", "1", "one\ntwo\nthree\n";

   if ($mode eq "fragmented") {
      require Time::HiRes;
      for (split //, $frame) {
         print;
         Time::HiRes::sleep (0.005);
      }
   } else {
      $frame = (pack "N", 1 << 22) . ("X" x ((1 << 20) + 8192)) if $mode eq "oversized";
      $frame = pack "N/a*", pack "(w/a*)*", "?" if $mode eq "status";
      $frame = pack "N", 0 if $mode eq "empty";
      $frame .= "extra" if $mode eq "extra";
      print $frame;
      sleep 60;
      exit;
   }
}
exec @ARGV;
die "exec: $!";
};
chmod 0700, "$dir/bwrap" or die $!;

# Simulate a concurrent edit after GNU patch has produced its output.
write_file "$dir/bin/patch", "#!$^X\n" . q{
use common::sense;
my $path = $ARGV[-1];
system $ENV{PERL_ANYEVENT_MCP_TEST_FS_PATCH}, @ARGV;
my $status = $?;
if (!$status && $path =~ /stale\z/) {
   open my $fh, ">>", $path or die $!;
   print $fh "changed\n";
   close $fh;
}
exit ($status >> 8);
};
chmod 0700, "$dir/bin/patch" or die $!;
write_file "$dir/ask", "#!$^X\n" . q{
use common::sense;
use JSON::XS ();
local $/;
my $request = JSON::XS::decode_json <STDIN>;
print JSON::XS::encode_json {
   decision => "allow-once", sandbox_grants => $request->{sandbox_grants},
};
};
chmod 0700, "$dir/ask" or die $!;
write_file "$dir/work/read", "one\ntwo\nthree\n";
write_file "$dir/config/anyevent-mcp/rules/fs-default.ini",
   "[rule]\ndecision=allow\naction=read\nworkdir=$dir/work\nsandbox-grants=workdir-read\n";

# trusted stand-ins make argv and grant checks independent of installed VCS clients.
for my $backend (qw(git svn cvs hg)) {
   write_file "$dir/bin/$backend", "#!$^X\n" . q{
use common::sense;
use JSON::XS ();
(my $backend = $0) =~ s{.*/}{};
use Cwd ();
open my $cwd, ">", "$ENV{PERL_ANYEVENT_MCP_TEST_FS_DIR}/vcs-cwd.log" or die $!;
print {$cwd} Cwd::getcwd ();
close $cwd or die $!;
open my $fh, ">>", "$ENV{PERL_ANYEVENT_MCP_TEST_FS_DIR}/vcs.log" or die $!;
print {$fh} JSON::XS::encode_json ([$backend, @ARGV]), "\n";
close $fh or die $!;
print "header\nkeep: $backend\ntrailer\n";
print STDERR "vcs diagnostic\n";
exit ((grep $_ eq "diff", @ARGV) ? 1 : 0);
};
   chmod 0700, "$dir/bin/$backend" or die $!;
}

my @command = ($^X, "-Ilib", "bin/mcp-fs", "--stdio", "--ask", "mcp", "--bwrap", "$dir/bwrap", "$dir/work");
my %env = (
   HOME => "$dir/home", XDG_CONFIG_HOME => "$dir/config",
   SSH_AUTH_SOCK => "$dir/agent", MCP_TEST_INHERIT => "inherited value",
   PATH => "$dir/bin:$ENV{PATH}", PERL_ANYEVENT_MCP_TEST_FS_DIR => $dir, PERL_ANYEVENT_MCP_TEST_FS_PATCH => $patch || "",
   PERL_ANYEVENT_MCP_TEST_FS_SANDBOX_PATH => "$dir/bin:$ENV{PATH}",
   PERL_ANYEVENT_MCP_PERMISSION_HELPER => "$dir/ask",
);
my (@prompts, $reduce, $deny);
my $client = AnyEvent::MCP::Client::JSONL->new (
   command => \@command, env => \%env,
   client_capabilities => { elicitation => { form => {} } },
   on_request => sub {
      my ($client, $req) = @_;
      my $request = $req->{params}{_meta}{"anyevent-mcp/permission"}{request};
      push @prompts, $request;
      $req->reply ($deny ? { action => "decline" } : {
         action => "accept", content => {
            decision => "allow-once",
            sandbox_grants => join ",", @{$reduce ? ["workdir-read"] : $request->{sandbox_grants}},
         },
      });
   },
);
sub call {
   my ($tool, $args) = @_;
   my ($success, $result) = wait_for (sub { $client->call ($tool, $args, $_[0]) });
   die JSON::XS::encode_json $result unless $success;
   $result
}

my ($success, $tools) = wait_for (sub { $client->tools ($_[0]) });
my $tool_count = 14 - ($utility{find} ? 0 : 2) - ($utility{sed} ? 0 : 1)
   - ($utility{find} && $utility{grep} ? 0 : 1) - ($utility{patch} ? 0 : 1);
ok $success && @$tools == $tool_count, "module discovery lists available filesystem tools";
my @probes = map JSON::XS::decode_json ($_), split /\n/, read_file "$dir/sandbox.log";
ok (grep {
   index (join ("\0", @$_), "--setenv\0PATH\0/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin") >= 0
} @probes), "sandbox PATH prefers base-system bin/sbin pairs over local programs";
ok (grep { $_->[-30] eq "perl" && $_->[-29] eq "-e"
   && $_->[-28] =~ /use 5\.008004/ } @probes),
   "automatic Perl bootstrap and executable discovery run inside the sandbox";

my ($exec_tool) = grep $_->{name} eq "exec", @$tools;
ok $exec_tool->{inputSchema}{properties}{sandbox_grants}{description} =~ /replaces this default entirely/,
   "exec schema says explicit sandbox_grants replace default";
my @workdir_tool = grep exists $_->{inputSchema}{properties}{workdir}, @$tools;
ok @workdir_tool == $tool_count - 2 && !grep (
   !$_->{inputSchema}{properties}{workdir}{anyOf}
      || @{$_->{inputSchema}{properties}{workdir}{anyOf}} != 2, @workdir_tool),
   "all filesystem workdir selectors advertise integer or string";
my %tool = map { $_->{name} => $_ } @$tools;
ok $tool{"file-read"}{description} =~ /\{data: BASE64\}.*\{error: STRING\}/,
   "file-read description names structured success and error results";
ok $tool{"file-write"}{description} =~ /\{bytes: INTEGER\}.*\{error: STRING\}/,
   "file-write description names structured success and error results";
ok $tool{"path-op"}{description} =~ /first failure; earlier changes remain/,
   "path-op description warns about partial completion";
my $result = call workdirs => {};
ok $result->{structuredContent}{workdirs}{1} eq "$dir/work", "structured workdir result";
ok join (",", @{$result->{structuredContent}{vcs_backends}}) eq "cvs,git,hg,svn", "workdirs advertises available VCS clients";
ok JSON::XS::decode_json ($result->{content}[0]{text})->{workdirs}{1} eq "$dir/work",
   "old text JSON representation retained";
ok !-e "$dir/config/anyevent-mcp/global.ini", "stdio does not create global configuration";
ok !@{$result->{structuredContent}{workdir_vcs}{"$dir/work"}},
   "workdir without metadata reports no VCS";
File::Path::mkpath ("$dir/work/nested/.git", 0, 0700);
$result = call workdirs => {};
ok !@{$result->{structuredContent}{workdir_vcs}{"$dir/work"}},
   "workdir detection does not recurse into child repositories";
File::Path::rmtree ("$dir/work/nested");
File::Path::mkpath (["$dir/work/CVS", "$dir/work/.hg", "$dir/work/.svn"], 0, 0700);
write_file "$dir/work/.git", "gitdir: elsewhere\n";
$result = call workdirs => {};
ok join (",", @{$result->{structuredContent}{workdir_vcs}{"$dir/work"}}) eq "cvs,git,hg,svn"
   && !-e "$dir/vcs.log", "workdir detects multiple markers and Git metadata file without running clients";
unlink "$dir/work/.git" or die $!;
mkdir "$dir/work/.git" or die $!;
$result = call workdirs => {};
ok join (",", @{$result->{structuredContent}{workdir_vcs}{"$dir/work"}}) eq "cvs,git,hg,svn",
   "workdir detects Git metadata directory too";
File::Path::rmtree (["$dir/work/CVS", "$dir/work/.git", "$dir/work/.hg", "$dir/work/.svn"]);
$result = call workdirs => {};
ok !@{$result->{structuredContent}{workdir_vcs}{"$dir/work"}},
   "workdir detection reflects metadata removal on next listing";

$result = call "file-read" => { path => "read" };
!$result->{isError} or die JSON::XS::encode_json $result;
ok MIME::Base64::decode_base64 ($result->{structuredContent}{data}) eq "one\ntwo\nthree\n",
   "file read through sandbox worker";
ok !@prompts, "selected-workdir read rule applies without prompting";
my $worker_log = read_file "$dir/sandbox.log";
my $worker_argv = JSON::XS::decode_json ((split /\n/, $worker_log)[-1]);
ok $worker_argv->[-3] eq "$dir/bin/perl" && $worker_argv->[-2] eq "-e" && $worker_argv->[-1] =~ /\A#perl\n/,
   "worker executes the original symlink path, not its physical target";
my ($cached_pid) = (read_file "$dir/worker-pids") =~ /([0-9]+)\n\z/;
$result = call "file-read" => { path => "read" };
ok MIME::Base64::decode_base64 ($result->{structuredContent}{data}) eq "one\ntwo\nthree\n"
   && read_file ("$dir/sandbox.log") eq $worker_log,
   "successive compatible Perl calls reuse one sandbox worker";

SKIP: {
   skip "extended GNU sed tests (PERL_ANYEVENT_MCP_TESTS=1)", 16
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
   skip "GNU sed is unavailable", 16 unless $utility{sed};

   $result = call "read-lines" => { path => "read", ranges => ["2,3", "1"] };
   ok @{$result->{content}} == 4
      && !(grep $_->{type} ne "text", @{$result->{content}})
      && $result->{content}[0]{text} eq "[range=2,3]"
      && $result->{content}[1]{text} eq "two\nthree\n"
      && $result->{content}[2]{text} eq "[range=1]"
      && $result->{content}[3]{text} eq "one\n",
      "ordered ranges have separate metadata and unchanged source text entries";
   $result = call "read-lines" => {
      path => "read", ranges => ["2,3", "1"], linenums => JSON::XS::true,
   };
   is_deeply [map $_->{text}, @{$result->{content}}], [
      "[range=2,3]", "2:two\n3:three\n", "[range=1]", "1:one\n",
   ], "linenums prefixes absolute line numbers without padding, separately for each range";

   write_file "$dir/work/numbered-lines", "alpha\n\nomega";
   $result = call "read-lines" => {
      path => "numbered-lines", ranges => ["2,3", "1", "4"], linenums => JSON::XS::true,
   };
   is_deeply [map $_->{text}, @{$result->{content}}], [
      "[range=2,3]", "2:\n3:omega", "[range=1]", "1:alpha\n", "[range=4]", "",
   ], "linenums handles blank lines, missing final newline and out-of-range requests";

   ok join (",", @{$tool{"read-lines"}{inputSchema}{properties}{encoding}{enum}})
      eq "utf-8,latin1,base64"
      && $tool{"read-lines"}{inputSchema}{properties}{encoding}{default} eq "utf-8",
      "read-lines advertises three explicit byte representations with UTF-8 default";
   ok $tool{"read-lines"}{inputSchema}{properties}{linenums}{type} eq "boolean"
      && !$tool{"read-lines"}{inputSchema}{properties}{linenums}{default},
      "linenums is an optional boolean defaulting to false";

   my $binary_lines = "A\xff\x00\nB\xe4\nC\x80";
   write_file "$dir/work/binary-lines", $binary_lines;
   $result = call "read-lines" => { path => "binary-lines", ranges => ["1,3"] };
   ok $result->{isError} && $result->{content}[0]{text} =~ /UTF-8|utf-8|UTF8/,
      "default UTF-8 rejects invalid input instead of guessing an encoding";
   $result = call "read-lines" => { path => "binary-lines", ranges => ["1"], encoding => "utf-8" };
   ok $result->{isError}, "explicit UTF-8 also rejects invalid bytes";

   $result = call "read-lines" => {
      path => "binary-lines", ranges => ["2,3", "1"], encoding => "latin1",
   };
   ok !$result->{isError} && @{$result->{content}} == 4
      && $result->{content}[0]{text} eq "[range=2,3]"
      && $result->{content}[1]{text} eq "B\xe4\nC\x80"
      && $result->{content}[2]{text} eq "[range=1]"
      && $result->{content}[3]{text} eq "A\xff\x00\n",
      "Latin-1 keeps exact LF/NUL bytes and preserves missing final LF in the source entry";

   $result = call "read-lines" => {
      path => "binary-lines", ranges => ["2,3", "1"], encoding => "base64",
   };
   my $b64_first = MIME::Base64::encode_base64 ("B\xe4\nC\x80", "");
   my $b64_second = MIME::Base64::encode_base64 ("A\xff\x00\n", "");
   ok !$result->{isError} && @{$result->{content}} == 4
      && $result->{content}[0]{text} eq "[range=2,3]"
      && $result->{content}[1]{text} eq $b64_first
      && $result->{content}[2]{text} eq "[range=1]"
      && $result->{content}[3]{text} eq $b64_second,
      "base64 independently encodes exact raw bytes in separate metadata and source entries";
   $result = call "read-lines" => {
      path => "binary-lines", ranges => ["3"], encoding => "base64",
   };
   ok @{$result->{content}} == 2
      && $result->{content}[0]{text} eq "[range=3]"
      && $result->{content}[1]{text} eq MIME::Base64::encode_base64 ("C\x80", ""),
      "base64 preserves absence of the final newline inside the encoded bytes";
   $result = call "read-lines" => {
      path => "binary-lines", ranges => ["2,3"], encoding => "base64", linenums => JSON::XS::true,
   };
   ok !$result->{isError}
      && MIME::Base64::decode_base64 ($result->{content}[1]{text}) eq "2:B\xe4\n3:C\x80",
      "base64 encodes numbered lines while retaining raw bytes and unterminated final line";

   write_file "$dir/work/utf8-lines", "\xc3\xa4\n";
   $result = call "read-lines" => { path => "utf8-lines", ranges => ["1"] };
   ok !$result->{isError} && @{$result->{content}} == 2
      && $result->{content}[0]{text} eq "[range=1]"
      && $result->{content}[1]{text} eq chr (0xe4) . "\n",
      "valid UTF-8 is decoded into a separate source entry with default behavior unchanged";
   $result = call "read-lines" => { path => "utf8-lines", ranges => ["1"], encoding => "latin1" };
   ok !$result->{isError} && @{$result->{content}} == 2
      && $result->{content}[0]{text} eq "[range=1]"
      && $result->{content}[1]{text} eq "\xc3\xa4\n",
      "Latin-1 does not reinterpret valid UTF-8 byte sequences";
   $result = call "read-lines" => { path => "read", ranges => ["1"], encoding => "utf-16" };
   ok $result->{isError}, "unsupported read-lines encoding is rejected";

   my $large_bytes = "X" x ((1 << 20) + 100);
   write_file "$dir/work/large-lines", $large_bytes;
   $result = call "read-lines" => { path => "large-lines", ranges => ["1"], encoding => "base64" };
   my $large_b64 = MIME::Base64::encode_base64 (substr ($large_bytes, 0, 1 << 20), "");
   ok !$result->{isError} && @{$result->{content}} == 2
      && $result->{content}[0]{text} eq "[range=1 truncated=1]"
      && $result->{content}[1]{text} eq $large_b64,
      "base64 uses raw byte budget and puts truncated=1 only in range metadata";
   $result = call "read-lines" => {
      path => "large-lines", ranges => ["1"], encoding => "base64", linenums => JSON::XS::true,
   };
   ok !$result->{isError}
      && $result->{content}[0]{text} eq "[range=1 truncated=1]"
      && MIME::Base64::decode_base64 ($result->{content}[1]{text})
         eq "1:" . ("X" x ((1 << 20) - 2)),
      "numbering counts prefix bytes against the 1 MiB limit";

}

$result = call "file-write" => { path => "new", data => MIME::Base64::encode_base64 ("hello\n", "") };
ok $result->{structuredContent}{bytes} == 6 && read_file ("$dir/work/new") eq "hello\n",
   "write receives module result";

# the write worker's different grants evict the cached read worker.
my $evicted = AnyEvent->condvar;
my $eviction_deadline = AnyEvent->timer (after => 30, cb => sub { die "Worker eviction timeout\n" });
my $eviction_poll = AnyEvent->timer (after => 0, interval => 0.01, cb => sub {
   $evicted->send unless kill 0 => $cached_pid;
});
$evicted->recv;
undef $eviction_poll;
undef $eviction_deadline;
ok !(kill 0 => $cached_pid), "evicting an incompatible cached worker terminates and reaps it";

SKIP: {
   skip "extended GNU find test (PERL_ANYEVENT_MCP_TESTS=1)", 1
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
   skip "GNU find is unavailable", 1 unless $utility{find};

   $result = call list => {};
   ok $result->{content}[0]{text} =~ /\tnew\n/, "compact listing preserved";
}
SKIP: {
   skip "extended GNU find/grep tests (PERL_ANYEVENT_MCP_TESTS=1)", 7
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
   skip "GNU find/grep are unavailable", 7 unless $utility{find} && $utility{grep};

   $result = call find => { name => "rea" };
   ok $prompts[-1]{tool} eq "find" && !exists $prompts[-1]{subject}
      && !exists $prompts[-1]{subjects} && $prompts[-1]{paths}[0] eq "$dir/work"
      && $result->{content}[0]{text} =~ /\tread\n/,
      "filesystem prompts show affected paths without authorization scopes";
   $result = call grep => { path => ".", pattern => "two" };
   ok $result->{structuredContent}{stdout} =~ /read:2:two/, "grep worker result";
   $result = call grep => { path => "read", pattern => "absent-grep-pattern-2026" };
   ok !$result->{isError} && $result->{structuredContent}{stdout} eq ""
      && $result->{structuredContent}{stderr} eq "",
      "grep no match in one existing file is a successful empty result";
   $result = call grep => { path => ".", pattern => "absent-grep-pattern-2026" };
   ok !$result->{isError} && $result->{structuredContent}{stdout} eq "",
      "grep no matches in a directory is a successful empty result";
   $result = call grep => { path => "read", pattern => q{^absent-grep-pattern-2026$}, mode => "pcre" };
   ok !$result->{isError} && $result->{structuredContent}{stdout} eq "",
      "PCRE grep no matches is a successful empty result";
   $result = call grep => { path => "read", pattern => "[", mode => "pcre" };
   ok $result->{isError} && $result->{content}[0]{text} =~ /grep failed/,
      "malformed grep PCRE remains an error";
   $result = call grep => { path => "nonexistent-path", pattern => "two" };
   ok $result->{isError} && $result->{content}[0]{text} =~ /grep failed/,
      "find traversal failures remain errors";

}

my $before = @prompts;
$result = call "path-op" => { path => "new", rename => "renamed", reason => "Move the test file" };
ok !$result->{isError} && !-e "$dir/work/new" && -f "$dir/work/renamed", "rename succeeds with combined authority";
ok @prompts == $before + 1 && join (",", @{$prompts[-1]{paths}}) eq "$dir/work/new,$dir/work/renamed",
   "rename requests one approval displaying both affected paths";
ok $prompts[-1]{reason} eq "Move the test file\nPath: \"$dir/work/new\"\nOperations (in order):\n  rename: \"$dir/work/renamed\"",
   "rename prompt preserves the supplied reason and shows source, operation and resolved destination";
write_file "$dir/work/partial", "remove first\n";
$result = call "path-op" => { path => "partial", unlink => JSON::XS::true, chmod => "0600" };
ok $result->{isError} && !-e "$dir/work/partial",
   "path-op stops on a later error without rolling back successful unlink";
ok $prompts[-1]{reason} =~ /Operations \(in order\):\n  unlink\n  chmod: "0600"\z/,
   "path-op prompt shows every operation and argument in execution order";
$before = @prompts;
$result = call "path-op" => { path => "a/b", mkpath => "0700" };
ok -d "$dir/work/a/b" && @prompts == $before + 1, "mkpath requests combined authority once";
ok @{$prompts[-1]{paths}} == 1 && $prompts[-1]{paths}[0] eq "$dir/work/a/b",
   "mkpath authorizes the target without server-side ancestor probing";
$result = call "path-op" => { path => "deep/one/two", mkpath => "0755" };
ok !$result->{isError} && -d "$dir/work/deep/one/two"
   && ((stat "$dir/work/deep")[2] & 07777) == 0755
   && ((stat "$dir/work/deep/one/two")[2] & 07777) == 0755,
   "worker creates nested directories with the requested mode";
$result = call "path-op" => { path => "deep/one/two", mkpath => "0700" };
ok !$result->{isError} && ((stat "$dir/work/deep/one/two")[2] & 07777) == 0755,
   "mkpath leaves existing directories unchanged";
$result = call "path-op" => { path => "read/child", mkpath => "0700" };
ok $result->{isError} && !-e "$dir/work/read/child",
   "worker rejects a non-directory ancestor";

$before = @prompts;
$result = call stat => { paths => ["read", "renamed"] };
ok @{$result->{structuredContent}{result}} == 2 && @prompts == $before + 1,
   "multi-path stat requests combined authority once";
$before = @prompts;
$result = call "path-op" => { path => "renamed", rename => "$dir/home/moved" };
ok !$result->{isError} && !-e "$dir/work/renamed" && -f "$dir/home/moved",
   "rename executes across paths when the test sandbox permits it";
ok @prompts == $before + 1
   && join (",", @{$prompts[-1]{sandbox_grants}}) eq "homedir-write,workdir-write",
   "rename requests source and destination sandbox grants once";

$reduce = 1;
write_file "$dir/work/reduced", "keep\n";
$result = call "path-op" => { path => "reduced", rename => "not-created" };
ok $result->{isError} && -f "$dir/work/reduced" && !-e "$dir/work/not-created",
   "reduced mutation grant fails before side effects";
$result = call "file-write" => { path => "reduced", data => MIME::Base64::encode_base64 ("bad", "") };
ok $result->{isError} && read_file ("$dir/work/reduced") eq "keep\n",
   "single-path write rejects insufficient reduction";
$reduce = 0;
$deny = 1;
$result = call "path-op" => { path => "reduced", unlink => JSON::XS::true };
ok $result->{isError} && -f "$dir/work/reduced", "denial leaves file intact";
$deny = 0;

SKIP: {
   skip "extended GNU patch tests (PERL_ANYEVENT_MCP_TESTS=1)", 10
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
   skip "GNU patch is unavailable", 10 unless $utility{patch};

   $result = call "file-patch" => { path => "read", diff => "@@ -2 @@\n-two\n+TWO\n" };
   ok $result->{structuredContent}{bytes} == 14 && read_file ("$dir/work/read") eq "one\nTWO\nthree\n",
      "shared diff normalization and standalone worker validation";

   write_file "$dir/work/unicode", "plain\n";
   $result = call "file-patch" => { path => "unicode", diff => "@@ -1 @@\n-plain\n+caf\x{e9}\n" };
   ok !$result->{isError} && read_file ("$dir/work/unicode") eq "caf\xc3\xa9\n",
      "Unicode unified diff is encoded as UTF-8 bytes";
   ok $prompts[-1]{details}{"View patch"} eq "File: $dir/work/unicode\n\n@@ -1 @@\n-plain\n+caf\x{e9}\n",
      "patch details include the target and original Unicode diff";

   write_file "$dir/work/binary", "a\0\xff\n";
   my $binary_diff = "@@ -1 @@\n-a\0\xff\n+b\0\xfe\n";
   $result = call "file-patch" => { path => "binary", diff => MIME::Base64::encode_base64 ($binary_diff, "") };
   ok !$result->{isError} && read_file ("$dir/work/binary") eq "b\0\xfe\n",
      "base64 binary diff patches NULs and non-UTF-8 bytes";
   ok $prompts[-1]{details}{"View patch"} =~ /Raw patch: .* bytes.*-a\\x\{00\}\\x\{FF\}\n\+b\\x\{00\}\\x\{FE\}/s,
      "base64 binary patch details show decoded bytes with explicit escaping";

   write_file "$dir/work/base64-unicode", "plain\n";
   $result = call "file-patch" => { path => "base64-unicode",
      diff => MIME::Base64::encode_base64 ("@@ -1 @@\n-plain\n+caf\xc3\xa9\n", "") };
   ok !$result->{isError} && $prompts[-1]{details}{"View patch"} =~ /\+caf\x{e9}\n/,
      "valid UTF-8 base64 patches have readable Unicode details";

   $result = call "file-patch" => { path => "binary", diff => "not-base64!" };
   ok $result->{isError} && read_file ("$dir/work/binary") eq "b\0\xfe\n",
      "invalid base64 diff rejected without modifying file";

   $result = call "file-patch" => { path => "read", diff => "@@ -20 @@\n-TWO\n+bad\n" };
   ok $result->{structuredContent}{error} =~ /offset/ && read_file ("$dir/work/read") eq "one\nTWO\nthree\n",
      "excessive patch relocation leaves original intact";
   write_file "$dir/work/stale", "one\ntwo\n";
   $result = call "file-patch" => { path => "stale", diff => "@@ -2 @@\n-two\n+TWO\n" };
   ok $result->{structuredContent}{error} =~ /changed/ && read_file ("$dir/work/stale") eq "one\ntwo\nchanged\n",
      "concurrent edit prevents patch replacement";
   ok !glob ("$dir/work/*~~new~~*"), "failed patch temporary files are removed";

}

# output selection is shared by arbitrary exec and fixed VCS operations.
my $output_argv = [$^X, "-e", 'print "one\nkeep two\nkeep three\nlast"; print STDERR "unfiltered\n"; exit 7'];
SKIP: {
   skip "extended GNU grep output tests (PERL_ANYEVENT_MCP_TESTS=1)", 4
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
   skip "GNU grep is unavailable", 4 unless $utility{grep};

   $result = call exec => { argv => $output_argv, reason => "filter output", grep => "^keep", max_lines => 1 };
   ok $result->{structuredContent}{stdout} eq "keep two\n"
      && $result->{structuredContent}{stderr} eq "unfiltered\n", "exec filters stdout only before the line limit";
   ok $result->{structuredContent}{exit} == 7 && $result->{structuredContent}{stdout_truncated}
      && !$result->{structuredContent}{capture_truncated}, "postfilter limits preserve original exit status and capture completeness";
   my $output_subject = $prompts[-1]{subject};
   $result = call exec => { argv => $output_argv, reason => "different output filter", grep => "^absent" };
   ok $result->{structuredContent}{stdout} eq "" && $result->{structuredContent}{exit} == 7,
      "no grep matches is distinct from command success";
   ok $prompts[-1]{subject} eq $output_subject, "output options do not change the executable permission subject";
}

$result = call exec => { argv => [$^X, "-e", 'print "abcdef"; print STDERR "uvwxyz"'],
   reason => "independent byte budgets", max_bytes => 3 };
ok $result->{structuredContent}{stdout} eq "abc" && $result->{structuredContent}{stderr} eq "uvw"
   && $result->{structuredContent}{stdout_truncated} && $result->{structuredContent}{stderr_truncated},
   "stdout and stderr have independent return budgets";
$result = call exec => { argv => [$^X, "-e", 'binmode STDOUT; print "\xc3\xa4\xc3\xa4"'],
   reason => "UTF-8 clipping", max_bytes => 3 };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "\x{e4}" && $result->{structuredContent}{truncated},
   "byte clipping preserves a complete UTF-8 prefix";
SKIP: {
   skip "extended GNU grep output tests (PERL_ANYEVENT_MCP_TESTS=1)", 2
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
   skip "GNU grep is unavailable", 2 unless $utility{grep};

   $result = call exec => { argv => [$^X, "-e", 'print "x" x 1100000; print STDERR "visible\n"; exit 9'],
      reason => "bounded capture before filtering", grep => "^absent" };
   ok $result->{structuredContent}{stdout} eq "" && $result->{structuredContent}{stderr} eq "visible\n"
      && $result->{structuredContent}{capture_truncated} && $result->{structuredContent}{exit} == 9,
      "capture truncation is explicit even when no captured line matches";
   $result = call exec => { argv => $output_argv, reason => "invalid filter", grep => "(" };
   ok $result->{isError} && $result->{structuredContent}{filter_error}
      && $result->{structuredContent}{exit} == 7, "filter failure retains the original command status";
}

my $before_output = @prompts;
$result = call exec => { argv => $output_argv, reason => "invalid limit", max_bytes => 0 };
ok $result->{isError} && @prompts == $before_output, "invalid output limits fail before permission or execution";

for my $backend (qw(git svn cvs hg)) {
   $result = call "vcs-diff" => { backend => $backend, files => ["-strange"] };
   ok !$result->{isError} && $result->{structuredContent}{exit} == 1
      && $result->{structuredContent}{stdout} eq "header\nkeep: $backend\ntrailer\n", "$backend diff preserves differences status and output";
   ok $prompts[-1]{action} eq "vcs-diff" && $prompts[-1]{subject} eq $backend,
      "$backend diff uses a fixed-operation permission instead of arbitrary exec";
   ok join (",", sort @{$prompts[-1]{sandbox_grants}}) eq
      ($backend eq "cvs" ? "ssh-agent,workdir-read" : "workdir-read"),
      "$backend diff requests its fixed sandbox grants";
   my @log = split /\n/, read_file "$dir/vcs.log";
   my $argv = JSON::XS::decode_json $log[-1];
   ok $argv->[-1] eq ($backend eq "svn" ? "./-strange@" : "./-strange")
      && grep ($_ eq "--", @$argv), "$backend filenames cannot become options";
   $result = call "vcs-status" => { backend => $backend, max_lines => 1 };
   ok !$result->{isError} && $result->{structuredContent}{exit} == 0
      && $result->{structuredContent}{stdout} eq "header\n", "$backend status shares output limits";

   SKIP: {
      skip "extended GNU grep VCS test (PERL_ANYEVENT_MCP_TESTS=1)", 1
         unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
      skip "GNU grep is unavailable", 1 unless $utility{grep};

      $result = call "vcs-diff" => { backend => $backend, grep => "^keep" };
      ok !$result->{isError} && $result->{structuredContent}{exit} == 1
         && $result->{structuredContent}{stdout} eq "keep: $backend\n", "$backend diff shares postfiltering";
   }

}
File::Path::mkpath ("$dir/work/sub", 0, 0700);
for my $backend (qw(git svn cvs hg)) {
   $result = call "vcs-diff" => { backend => $backend, cwd => "sub", files => ["../-strange"] };
   my @log = split /\n/, read_file "$dir/vcs.log";
   my $argv = JSON::XS::decode_json $log[-1];
   ok !$result->{isError} && read_file ("$dir/vcs-cwd.log") eq "$dir/work/sub"
      && $argv->[-1] eq ($backend eq "svn" ? "./../-strange@" : "./../-strange")
      && $prompts[-1]{reason} =~ /\Q$dir\/work\/sub\E/,
      "$backend runs in cwd with relative filenames and displays command directory";
}
ok $tool{"vcs-diff"}{inputSchema}{properties}{cwd}{default} eq "."
   && $tool{"vcs-status"}{inputSchema}{properties}{cwd}{default} eq ".",
   "both VCS tools advertise cwd default";
my $before_vcs = read_file "$dir/vcs.log";
$result = call "vcs-status" => { backend => "git", cwd => "../home" };
ok $result->{isError} && read_file ("$dir/vcs.log") eq $before_vcs,
   "lexical cwd escape is rejected before execution";
symlink "$dir/home", "$dir/work/external-cwd" or die $!;
$result = call "vcs-status" => { backend => "git", cwd => "external-cwd" };
ok $result->{structuredContent}{exit} != 0 && read_file ("$dir/vcs.log") eq $before_vcs
   && $result->{structuredContent}{stderr} =~ /cwd must resolve within/,
   "worker rejects resolved cwd escape before starting VCS";
symlink "sub", "$dir/work/internal-cwd" or die $!;
$result = call "vcs-status" => { backend => "git", cwd => "internal-cwd" };
ok !$result->{isError} && read_file ("$dir/vcs-cwd.log") eq "$dir/work/sub",
   "internal cwd symlink is allowed";
$before_vcs = read_file "$dir/vcs.log";
$result = call "vcs-status" => { backend => "git", cwd => "missing-cwd" };
ok $result->{structuredContent}{exit} != 0 && read_file ("$dir/vcs.log") eq $before_vcs,
   "missing cwd cannot start VCS";
$result = call "vcs-diff" => { backend => "cvs", files => ["../outside"] };
ok $result->{isError} && read_file ("$dir/vcs.log") eq $before_vcs, "VCS paths cannot escape the selected workdir";
$reduce = 1;
$result = call "vcs-status" => { backend => "cvs" };
ok $result->{isError} && read_file ("$dir/vcs.log") eq $before_vcs, "reduced approval cannot omit CVS agent/network authority";
$reduce = 0;

$result = call exec => { argv => [$^X, "-e", 'print "worker\\n"'], reason => "test worker" };
ok $result->{structuredContent}{stdout} eq "worker\n" && !$result->{isError}, "arbitrary exec uses module permissions";
ok !exists $prompts[-1]{details}, "exec without stdin offers no viewer details";
ok $tool{exec}{inputSchema}{properties}{stdin_encoding}{enum}[2] eq "base64", "exec advertises stdin encoding choices";
my $short_stdin = "print qq(hello from stdin\n);\n";
$result = call exec => { argv => [$^X, "-"], stdin => $short_stdin,
   reason => "inspect stdin test" };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "hello from stdin\n"
   && $prompts[-1]{details}{"View stdin"} eq $short_stdin,
   "real exec passes original source to display-only details and runs it unchanged";
my $large_stdin = "x" x 65537;
$result = call exec => { argv => [$^X, "-e", 'local $/; my $s = <STDIN>; print length $s'],
   stdin => $large_stdin, reason => "inspect long input" };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "65537"
   && $prompts[-1]{details}{"View stdin"} eq $large_stdin,
   "long exec input reaches both the worker and display-only details intact";

my $hex_stdin = [$^X, "-e", 'binmode STDIN; local $/; print unpack "H*", <STDIN>'];
$result = call exec => { argv => $hex_stdin, stdin => "\x{e9}", reason => "UTF-8 input" };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "c3a9",
   "exec stdin defaults to UTF-8 bytes";
$result = call exec => { argv => $hex_stdin, stdin => "\x{e9}\x{ff}\0",
   stdin_encoding => "latin1", reason => "Latin-1 input" };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "e9ff00"
   && $prompts[-1]{details}{"View stdin"} =~ /latin1 stdin: 3 bytes.*\\x\{E9\}\\x\{FF\}\\x\{00\}/s,
   "Latin-1 converts Unicode code points losslessly and displays escaped bytes";
my $binary = pack "C*", 0, 255, 10, 92, 65;
$result = call exec => { argv => $hex_stdin, stdin => MIME::Base64::encode_base64 ($binary, ""),
   stdin_encoding => "base64", reason => "binary input" };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "00ff0a5c41"
   && $prompts[-1]{details}{"View stdin"} =~ /base64 stdin: 5 bytes.*\\x\{00\}\\x\{FF\}\\x\{0A\}\\x\{5C\}A/s,
   "Base64 decodes exact bytes; preview escapes control bytes and backslash";

my $prompts_before = @prompts;
my $sandbox_before = read_file "$dir/sandbox.log";
for my $invalid (
   { stdin_encoding => "latin1", stdin => "\x{100}" },
   { stdin_encoding => "base64", stdin => "!!!" },
   { stdin_encoding => "base64", stdin => "YQ==\n" },
   { stdin_encoding => "something", stdin => "abc" },
) {
   $result = call exec => { argv => $hex_stdin, %$invalid, reason => "reject bad stdin" };
   ok $result->{isError} && @prompts == $prompts_before
      && read_file ("$dir/sandbox.log") eq $sandbox_before,
      "invalid stdin encoding/data rejected before permission and worker";
}

my $preview_input = "\x00" x 4100;
$result = call exec => { argv => [$^X, "-e", 'binmode STDIN; local $/; print length <STDIN>'],
   stdin => MIME::Base64::encode_base64 ($preview_input, ""), stdin_encoding => "base64",
   reason => "bounded preview" };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "4100"
   && $prompts[-1]{details}{"View stdin"} =~ /4100 bytes.*limited to 4096 bytes/s
   && length ($prompts[-1]{details}{"View stdin"}) < 25000,
   "binary stdin preview is bounded without truncating worker input";

my $max_stdin = MIME::Base64::encode_base64 ("x" x (4 * 1024 * 1024), "");
$result = call exec => { argv => [$^X, "-e", 'binmode STDIN; local $/; print length <STDIN>'],
   stdin => $max_stdin, stdin_encoding => "base64", reason => "exact 4 MiB stdin" };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq (4 * 1024 * 1024),
   "maximum decoded stdin fits through the increased MCP message limit";

my $too_large_stdin = MIME::Base64::encode_base64 ("x" x (4 * 1024 * 1024 + 1), "");
$prompts_before = @prompts;
$result = call exec => { argv => $hex_stdin, stdin => $too_large_stdin,
   stdin_encoding => "base64", reason => "reject decoded oversize" };
ok $result->{isError} && @prompts == $prompts_before
   && $result->{content}[0]{text} =~ /stdin exceeds 4 MiB/,
   "stdin size limit applies to decoded bytes before permission";

$result = call exec => { argv => [$^X, "-e", 'print "diff\n"; warn "message\n"; exit 1'], reason => "nonzero is data" };
ok !$result->{isError} && $result->{structuredContent}{exit} == 1
   && $result->{structuredContent}{stdout} eq "diff\n"
   && $result->{structuredContent}{stderr} eq "message\n",
   "nonzero command exit returns ordinary structured data";
$result = call exec => {
   argv => [$^X, "-e", q{
      defined (my $pid = fork) or die $!;
      exit 7 if $pid;
      select undef, undef, undef, 0.1;
      print "late stdout\n";
      print STDERR "late stderr\n";
   }],
   reason => "test output after child exit",
};
ok !$result->{isError} && $result->{structuredContent}{exit} == 7
   && $result->{structuredContent}{stdout} eq "late stdout\n"
   && $result->{structuredContent}{stderr} eq "late stderr\n",
   "completion waits for both output streams after the child exits";

$result = call exec => {
   argv => [$^X, "-e", q{
      close STDIN;
      close STDOUT;
      close STDERR;
      select undef, undef, undef, 0.1;
      exit 9;
   }],
   reason => "test child exit after output closes",
};
ok !$result->{isError} && $result->{structuredContent}{exit} == 9
   && $result->{structuredContent}{stdout} eq ""
   && $result->{structuredContent}{stderr} eq "",
   "completion waits for child status after both output streams close";

$result = call exec => { argv => [$^X, "-e", 'kill TERM => $$'], reason => "signal is data" };
ok !$result->{isError} && $result->{structuredContent}{signal} == 15,
   "signal termination returns an ordinary process result";
SKIP: {
   skip "extended command timeout test (PERL_ANYEVENT_MCP_TESTS=1)", 1
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;

   $result = call exec => {
      argv => [$^X, "-e", '$| = 1; print "before timeout\n"; print STDERR "before timeout\n"; sleep 30'],
      timeout => 1, reason => "test timeout abandons output",
   };
   ok !$result->{isError} && $result->{structuredContent}{timed_out}
      && $result->{structuredContent}{truncated}
      && $result->{structuredContent}{exit} == 0
      && $result->{structuredContent}{signal} == 9
      && $result->{structuredContent}{stdout} eq "before timeout\n"
      && $result->{structuredContent}{stderr} eq "before timeout\n",
      "timeout returns captured output as truncated with the real child status";

}

my $sandbox = read_file "$dir/sandbox.log";
ok $sandbox =~ /--unshare-net/ && $sandbox =~ /--ro-bind/ && $sandbox =~ /--disable-userns/
   && $sandbox !~ /\/run\/anyevent-mcp\.pm/,
   "sandbox retains isolation flags without mounting application source";
ok $sandbox =~ /"--file","3","\/etc\/passwd"/, "sandbox supplies passwd via inherited descriptor";
ok read_file ("$dir/passwd.log") =~ /\Asandbox:x:\d+:\d+:Sandbox:\Q$dir\/home\E:\/bin\/sh\n\z/,
   "synthetic passwd exposes user identity and configured HOME only";

$result = call exec => { argv => [$^X, "-e", "print 300"], timeout => 300, reason => "test normal timeout limit" };
ok !$result->{isError} && !grep ($_ eq "long-running", @{$prompts[-1]{sandbox_grants}}),
   "normal timeout limit needs no long-running authority";
$sandbox = read_file "$dir/sandbox.log";
$deny = 1;
$result = call exec => { argv => [$^X, "-e", "print 301"], timeout => 301, reason => "test denied long timeout" };
ok $result->{isError} && read_file ("$dir/sandbox.log") eq $sandbox,
   "denied long timeout never starts a worker";
ok join (",", sort @{$prompts[-1]{sandbox_grants}}) eq "long-running,workdir-read",
   "long timeout automatically requests authority alongside sandbox sandbox_grants";
$deny = 0;
$result = call exec => {
   argv => [$^X, "-e", "print 21600"], sandbox_grants => [], timeout => 21600, reason => "test six-hour limit",
};
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "21600"
   && join (",", @{$prompts[-1]{sandbox_grants}}) eq "long-running",
   "six-hour timeout is accepted with long-running authority and a minimal sandbox";
$sandbox = read_file "$dir/sandbox.log";
$reduce = 1;
$result = call exec => { argv => [$^X, "-e", "print 301"], timeout => 301, reason => "test reduced long timeout" };
ok $result->{isError} && $result->{content}[0]{text} =~ /reduced below long-running/
   && read_file ("$dir/sandbox.log") eq $sandbox,
   "approval without long-running authority never starts a worker";
$reduce = 0;
my $prompt_count = @prompts;
$result = call exec => { argv => [$^X, "-e", "print 21601"], timeout => 21601, reason => "test excessive timeout" };
ok $result->{isError} && @prompts == $prompt_count && read_file ("$dir/sandbox.log") eq $sandbox,
   "timeout above six hours is rejected before asking or starting a worker";
my $cancel_cv = AnyEvent->condvar;
my $running = $client->call (exec => {
   argv => [$^X, "-e", 'open my $fh, ">", $ARGV[0] or die $!; print $fh $$; close $fh; sleep 30', "$dir/work/pid"],
   timeout => 21600, reason => "test cancellation with long-running authority",
}, sub { $cancel_cv->send ([@_]) });
my $ready = AnyEvent->condvar;
my $deadline = AnyEvent->timer (after => 30, cb => sub { die "Worker startup timeout\n" });
my $poll = AnyEvent->timer (after => 0, interval => 0.01, cb => sub {
   $ready->send if -s "$dir/work/pid";
});
$ready->recv;
undef $poll;
undef $deadline;
my $pid = read_file "$dir/work/pid";
$client->cancel ($running);
my $cancel = $cancel_cv->recv;
ok !$cancel->[0] && $cancel->[1]{cancelled}, "cancelled tool completes locally once";
$ready = AnyEvent->condvar;
$deadline = AnyEvent->timer (after => 30, cb => sub { die "Worker cancellation timeout\n" });
$poll = AnyEvent->timer (after => 0, interval => 0.01, cb => sub {
   $ready->send unless kill 0 => $pid;
});
$ready->recv;
undef $poll;
undef $deadline;
ok !(kill 0 => $pid), "cancellation terminates and reaps the worker";
$result = call workdirs => {};
ok $result->{structuredContent}{workdirs}{1} eq "$dir/work", "server survives worker cancellation";

SKIP: {
   skip "extended GNU sed permission test (PERL_ANYEVENT_MCP_TESTS=1)", 1
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
   skip "GNU sed is unavailable", 1 unless $utility{sed};

   $before = @prompts;
   $result = call "read-lines" => { path => "reduced", ranges => ["1"] };
   ok !$result->{isError} && @{$result->{content}} == 2
      && $result->{content}[0]{text} eq "[range=1]"
      && $result->{content}[1]{text} eq "keep\n"
      && @prompts == $before,
      "workdir-bound read rule applies to other files in the same workdir";

}

$client->close;

# Exercise response framing independently of the real Perl worker's writes.
write_file "$dir/work/framing", "one\ntwo\nthree\n";
for my $case (
   ["fragmented", undef],
   ["oversized", qr/sandbox perl stdout/],
   ["status", qr/invalid perl response status/],
   ["empty", qr/missing perl response status/],
   ["extra", qr/unexpected sandbox perl output/],
) {
   my ($mode, $error) = @$case;
   write_file "$dir/response-mode", "$mode\n";
   $client = AnyEvent::MCP::Client::JSONL->new (command => \@command, env => \%env);
   $result = call "file-read" => { path => "framing" };
   ok $error
      ? $result->{isError} && $result->{content}[0]{text} =~ $error
      : !$result->{isError}
         && MIME::Base64::decode_base64 ($result->{structuredContent}{data}) eq "one\ntwo\nthree\n",
      "$mode Perl response";
   $result = call "file-read" => { path => "framing" };
   ok !$result->{isError}
      && MIME::Base64::decode_base64 ($result->{structuredContent}{data}) eq "one\ntwo\nthree\n",
      "worker remains usable or is replaced after $mode response";
   $client->close;
}

# All-workdirs grants remain flat, but mount only the selected workdir when
# possible. Workdir identity is the original CLI argument, not the realpath.
File::Path::mkpath ("$dir/other", 0, 0700);
write_file "$dir/other/data", "other\n";
my $other_identity = "$dir/other/../other";
my @multi_prompts;
$client = AnyEvent::MCP::Client::JSONL->new (
   command => [@command, $other_identity], env => \%env,
   client_capabilities => { elicitation => { form => {} } },
   on_request => sub {
      my ($client, $req) = @_;
      my $request = $req->{params}{_meta}{"anyevent-mcp/permission"}{request};
      push @multi_prompts, $request;
      $req->reply ({
         action => "accept", content => {
            decision => "allow-once",
            sandbox_grants => join ",", @{$request->{sandbox_grants}},
         },
      });
   },
);
sub last_workdir_mounts {
   my @line = split /\n/, read_file "$dir/sandbox.log";
   my $argv = JSON::XS::decode_json $line[-1];
   my %mount;
   for my $i (0 .. $#$argv - 2) {
      next unless $argv->[$i] =~ /\A--(?:bind|ro-bind)\z/;
      next unless $argv->[$i+1] eq $argv->[$i+2];
      my $path = $argv->[$i+1];
      $mount{$path} = $argv->[$i] if $path eq "$dir/work" || $path eq "$dir/other";
   }
   \%mount
}
$result = call workdirs => {};
ok $result->{structuredContent}{workdirs}{2} eq $other_identity
   && $result->{structuredContent}{resolved_workdirs}{2} eq "$dir/other",
   "workdir identity retains verbatim CLI path while mounts use resolved path";
$result = call "file-read" => { path => "data", workdir => 2 };
my $mount = last_workdir_mounts ();
ok MIME::Base64::decode_base64 ($result->{structuredContent}{data}) eq "other\n"
   && @multi_prompts == 1 && $multi_prompts[-1]{workdir} eq $other_identity
   && $mount->{"$dir/other"} eq "--ro-bind" && !exists $mount->{"$dir/work"},
   "workdir A read rule does not authorize B; B alone is mounted read-only";
ok $multi_prompts[-1]{sandbox_grant_descriptions}{"workdir-read"}
      eq "Read files in selected workdir \"$other_identity\"",
   "workdir-read description shows verbatim configured workdir B";
$result = call "file-read" => { path => "data", workdir => $other_identity };
ok !$result->{isError} && MIME::Base64::decode_base64 ($result->{structuredContent}{data}) eq "other\n",
   "verbatim configured workdir path selects B";
$result = call "file-read" => { path => "data", workdir => "$dir/other" };
ok !$result->{isError} && MIME::Base64::decode_base64 ($result->{structuredContent}{data}) eq "other\n",
   "resolved workdir path selects B";
$result = call "file-read" => { path => "data", workdir => "2" };
ok !$result->{isError} && MIME::Base64::decode_base64 ($result->{structuredContent}{data}) eq "other\n",
   "numeric string workdir ID still selects B";
my $selector_prompts = @multi_prompts;
$result = call "file-read" => { path => "data", workdir => "$dir/removed" };
ok $result->{isError} && @multi_prompts == $selector_prompts
   && $result->{content}[0]{text} =~ /Unknown configured workdir/,
   "stale workdir path fails before permission rather than silently retargeting";
$result = call exec => { argv => [$^X, "-e", "print 1"], workdir => 1, reason => "read A" };
$mount = last_workdir_mounts ();
ok !$result->{isError} && $mount->{"$dir/work"} eq "--ro-bind" && !exists $mount->{"$dir/other"}
   && $multi_prompts[-1]{workdir} eq "$dir/work",
   "selected workdir A exec mounts only A and requests A-specific permission";
$result = call exec => { argv => [$^X, "-e", "print 2"], workdir => 2, reason => "read B" };
$mount = last_workdir_mounts ();
ok !$result->{isError} && $mount->{"$dir/other"} eq "--ro-bind" && !exists $mount->{"$dir/work"}
   && $multi_prompts[-1]{workdir} eq $other_identity,
   "selected workdir B exec mounts only B and requests B-specific permission";
$result = call exec => { argv => [$^X, "-e", "print 3"], workdir => 2,
   sandbox_grants => ["all-workdirs-read"], reason => "read all" };
$mount = last_workdir_mounts ();
ok !$result->{isError} && $mount->{"$dir/other"} eq "--ro-bind"
   && $mount->{"$dir/work"} eq "--ro-bind", "all-workdirs-read mounts both read-only";
ok !defined $multi_prompts[-1]{workdir}, "all-workdirs-read permission has no selected-workdir identity";
$result = call exec => { argv => [$^X, "-e", "print 4"], workdir => 2,
   sandbox_grants => ["all-workdirs-read", "workdir-write"], reason => "read all write B" };
$mount = last_workdir_mounts ();
ok !$result->{isError} && $mount->{"$dir/work"} eq "--ro-bind"
   && $mount->{"$dir/other"} eq "--bind"
   && $multi_prompts[-1]{workdir} eq $other_identity,
   "all-read plus selected-write mounts A read-only and B writable";
ok $multi_prompts[-1]{sandbox_grant_descriptions}{"workdir-write"}
      eq "Change files in selected workdir \"$other_identity\"",
   "mixed-mode workdir-write label identifies only the selected writable workdir";
$result = call exec => { argv => [$^X, "-e", "print 5"], workdir => 2,
   sandbox_grants => ["all-workdirs-write"], reason => "write all" };
$mount = last_workdir_mounts ();
ok !$result->{isError} && $mount->{"$dir/work"} eq "--bind"
   && $mount->{"$dir/other"} eq "--bind"
   && !defined $multi_prompts[-1]{workdir}, "all-workdirs-write mounts both writable without workdir identity";
$before = @multi_prompts;
$result = call stat => { workdir => 1, paths => ["read", "$dir/other/data"] };
ok $result->{isError} && @multi_prompts == $before,
   "multi-path stat crossing selected workdir rejected before permission";
write_file "$dir/work/cross-source", "cross\n";
$before = @multi_prompts;
$result = call "path-op" => { workdir => 1, path => "cross-source", rename => "$dir/other/moved" };
ok !$result->{isError} && !-e "$dir/work/cross-source" && -f "$dir/other/moved",
   "cross-workdir rename reaches the worker rather than being rejected lexically";
ok @multi_prompts == $before + 1 && !defined $multi_prompts[-1]{workdir}
   && join (",", @{$multi_prompts[-1]{sandbox_grants}}) eq "all-workdirs-write,workdir-write",
   "cross-workdir rename requests all-workdirs-write without a selected identity";
$client->close;

$client = AnyEvent::MCP::Client::JSONL->new (
   command => [@command[0 .. $#command - 1], $other_identity, "$dir/work"], env => \%env,
);
$result = call workdirs => {};
ok $result->{structuredContent}{workdirs}{1} eq "$dir/work"
   && $result->{structuredContent}{workdirs}{2} eq $other_identity,
   "IDs survive restart with reversed argument order";
$result = call "file-read" => { path => "read", workdir => 1 };
ok !$result->{isError} && MIME::Base64::decode_base64 ($result->{structuredContent}{data}) eq read_file ("$dir/work/read"),
   "persistent numeric ID selects the same path after reordering";
$client->close;

$client = AnyEvent::MCP::Client::JSONL->new (
   command => [@command[0 .. $#command - 1], $other_identity], env => \%env,
);
$result = call workdirs => {};
ok !exists $result->{structuredContent}{workdirs}{1}
   && $result->{structuredContent}{workdirs}{2} eq $other_identity,
   "single configured workdir retains its shared ID";
$result = call "file-read" => { path => "read", workdir => 1 };
ok $result->{isError} && $result->{content}[0]{text} =~ /Unknown workdir ID/,
   "registry entry outside configured workdirs grants no selector access";
$client->close;

# shorten only this test server's registry lifetime to exercise its actual timer.
my $timer_server = q{
   use AnyEvent::MCP::Workdirs ();
   my $new = \&AnyEvent::MCP::Workdirs::new;
   *AnyEvent::MCP::Workdirs::new = sub {
      my ($class, %kv) = @_;
      $new->($class, %kv, expiry => 1)
   };
   $0 = "bin/mcp-fs";
   do "./bin/mcp-fs";
   die $@ if $@;
};
$client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "-e", $timer_server, "--", @command[3 .. $#command]], env => \%env,
);
$result = call workdirs => {};
my $registry_file = "$dir/config/anyevent-mcp/fs-workdir-ids.json";
my $registry = JSON::XS::decode_json read_file $registry_file;
my $registered = time;
$registry->{1}[1] = 1;

{
   my $lock = AnyEvent::MCP::File::lock $registry_file;
   AnyEvent::MCP::File::replace $registry_file, JSON::XS::encode_json ($registry);
}

wait_for (sub {
   my ($done) = @_;
   my $timer; $timer = AE::timer 1, 0, sub {
      undef $timer;
      $done->();
   };
});
$registry = JSON::XS::decode_json read_file $registry_file;
ok $registry->{1}[1] >= $registered,
   "running server timer refreshes its workdir without tool use";
$client->close;

splice @command, 4, 2; # Legacy calls use the default local helper.
$client = AnyEvent::MCP::Client::JSONL->new (
   command => \@command, env => \%env, versions => ["2025-11-25"],
);
$result = call "file-write" => { path => "legacy", data => MIME::Base64::encode_base64 ("legacy", "") };
ok $result->{structuredContent}{bytes} == 6 && -f "$dir/work/legacy", "legacy client uses external asking helper";
$client->close;

# Unsandboxed tools must request the authority they actually have, not a
# misleading workdir-only grant. Reduced grants prevent worker startup.
my (@direct_requests, $full_grant);
my $direct_answer = sub {
   my ($client, $req) = @_;
   my $request = $req->{params}{_meta}{"anyevent-mcp/permission"}{request};
   push @direct_requests, $request;
   $req->reply ({
      action => "accept", content => {
         decision => "allow-once",
         sandbox_grants => join ",", @{$full_grant ? $request->{sandbox_grants} : ["workdir-write"]},
      },
   });
};
my @captured_server = (
   $^X, "-Ilib", "-e",
   'open STDERR, ">>", shift @ARGV or die $!; do shift @ARGV; die $@ if $@;',
   "$dir/unsandboxed.stderr", "$root/bin/mcp-fs", "--name", "default", "--quiet",
);
$client = AnyEvent::MCP::Client::JSONL->new (
   command => [@captured_server, "--stdio", "--ask", "mcp",
      "--sandbox=none", "--bwrap", "$dir/nonexistent-bwrap", "$dir/work"],
   env => \%env, client_capabilities => { elicitation => { form => {} } },
   on_request => $direct_answer,
);
$result = call "file-write" => { path => "direct-test", data => MIME::Base64::encode_base64 ("ok", "") };
ok $result->{isError} && !-e "$dir/work/direct-test",
   "unsandboxed file-write rejects insufficient sandbox grants";
my %requested = map { $_ => 1 } @{$direct_requests[-1]{sandbox_grants}};
ok $requested{"world-write"} && $requested{network} && $requested{"shared-tmp"}
   && $requested{"host-proc"} && $direct_requests[-1]{sandbox_implementation} =~ /UNSANDBOXED/,
   "unsandboxed permission prompt shows full host authority and implementation";
$full_grant = 1;
$result = call "file-write" => { path => "direct-test", data => MIME::Base64::encode_base64 ("ok", "") };
ok !$result->{isError} && read_file ("$dir/work/direct-test") eq "ok",
   "unsandboxed write executes only after approval of full authority";
$full_grant = 0;
my $direct_argv = [$^X, "-e", q{
   open my $fh, ">", "direct-exec-ran" or die $!;
   print {$fh} "ran";
   print "direct";
}];
$result = call exec => { argv => $direct_argv, sandbox_grants => [], reason => "direct test" };
ok $result->{isError} && !-e "$dir/work/direct-exec-ran",
   "explicitly minimal exec grants cannot narrow unsandboxed execution or start the command";
$full_grant = 1;
$result = call exec => { argv => $direct_argv, sandbox_grants => [], reason => "direct test" };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "direct" && -f "$dir/work/direct-exec-ran",
   "unsandboxed exec runs after full approval even with a narrow client request";
$client->close;

# Persist exactly this command with the full authority direct execution receives.
my @saved_command = (
   $^X, "-Ilib", "-e",
   'open STDERR, ">>", shift @ARGV or die $!; do shift @ARGV; die $@ if $@;',
   "$dir/saved.stderr", "$root/bin/mcp-fs", "--name", "saved-max",
   "--stdio", "--ask", "mcp", "--sandbox=none", "$dir/work",
);
my $saved_argv = [$^X, "-e", 'open my $fh, ">", $ARGV[0] or die $!; print {$fh} "saved"; print "saved"', "$dir/work/saved-max"];
my @save_stages;
$client = AnyEvent::MCP::Client::JSONL->new (
   command => \@saved_command, env => \%env,
   client_capabilities => { elicitation => { form => {} } },
   on_request => sub {
      my ($client, $req) = @_;
      my $meta = $req->{params}{_meta}{"anyevent-mcp/permission"};
      push @save_stages, $meta->{stage};
      my $request = $meta->{request};
      $req->reply ({
         action => "accept", content => {
            decision => "allow-always",
            ($meta->{stage} eq "rule" ? (
               sandbox_grants => join (",", @{$request->{sandbox_grants}}),
               subject => $request->{subjects}[0]{subject},
            ) : ()),
         },
      });
   },
);
$result = call exec => { argv => $saved_argv, sandbox_grants => [], reason => "save maximal direct grant" };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "saved"
   && read_file ("$dir/work/saved-max") eq "saved", "maximal direct grant executes the approved command";
is_deeply \@save_stages, ["choice", "rule"], "persistent direct approval uses both protected forms";
$client->close;
my $saved_rule = read_file "$dir/config/anyevent-mcp/rules/fs-saved-max.ini";
for my $grant (qw(world-write network shared-tmp host-proc)) {
   like $saved_rule, qr/^sandbox-grants=.*\b\Q$grant\E\b/m, "saved direct grant retains $grant";
}
unlink "$dir/work/saved-max" or die $!;
$client = AnyEvent::MCP::Client::JSONL->new (
   command => \@saved_command, env => \%env,
   client_capabilities => { elicitation => { form => {} } },
   on_request => sub { die "Saved maximal grant unexpectedly prompted\n" },
);
$result = call exec => { argv => $saved_argv, sandbox_grants => [], reason => "reuse maximal direct grant" };
ok !$result->{isError} && $result->{structuredContent}{stdout} eq "saved"
   && read_file ("$dir/work/saved-max") eq "saved", "restarted server reuses the saved maximal direct grant without prompting";
$client->close;

# An existing bubblewrap executable that fails must never cause direct fallback.
write_file "$dir/failing-bwrap", "#!$^X\n" . q{
open my $fh, ">>", "$ENV{PERL_ANYEVENT_MCP_TEST_FS_DIR}/bwrap-failures" or die $!;
print {$fh} "attempt\n";
close $fh or die $!;
print STDERR "deliberate bubblewrap failure\n";
exit 42;
};
chmod 0700, "$dir/failing-bwrap" or die $!;
for my $mode (qw(bwrap auto)) {
   $client = AnyEvent::MCP::Client::JSONL->new (
      command => [$^X, "-e",
         'open STDERR, ">", shift @ARGV or die $!; exec {$ARGV[0]} @ARGV; die $!;',
         "$dir/failing-startup-$mode", $^X, "-Ilib", "bin/mcp-fs", "--stdio", "--ask", "mcp",
         "--sandbox=$mode", "--bwrap", "$dir/failing-bwrap", "$dir/work"],
      env => \%env, client_capabilities => { elicitation => { form => {} } },
      on_request => $direct_answer,
   );
   my ($listed) = wait_for (sub { $client->tools ($_[0]) });
   ok !$listed && !-e "$dir/work/fallback-exec-$mode",
      "$mode fails startup when sandbox Perl cannot run, without direct fallback";
   my $stderr = read_file "$dir/failing-startup-$mode";
   like $stderr, qr/\Adeliberate bubblewrap failure\nPerl 'perl' cannot run in the worker environment\n\z/,
      "$mode captures and checks the expected startup diagnostics without printing them";
   $client->close;
}

$client = AnyEvent::MCP::Client::JSONL->new (
   command => [@captured_server, "--stdio", "--ask", "mcp",
      "--sandbox=auto", "--bwrap", "$dir/nonexistent-bwrap", "$dir/work"],
   env => \%env, client_capabilities => { elicitation => { form => {} } },
   on_request => $direct_answer,
);
$result = call "file-write" => { path => "auto-test", data => MIME::Base64::encode_base64 ("auto", "") };
ok !$result->{isError} && read_file ("$dir/work/auto-test") eq "auto"
   && $direct_requests[-1]{sandbox_implementation} =~ /UNSANDBOXED/,
   "auto mode without bubblewrap requests full authority and runs directly";
$client->close;
ok read_file ("$dir/unsandboxed.stderr") eq
   (((join "", map "$_: not detected or wrong version\n", grep !$utility{$_}, qw(find grep patch sed))
      . "mcp-fs: SANDBOX NONE - workers run with full host-user privileges\n") x 2),
   "both unsandboxed startup modes emit the expected warning";

my $old_sandbox_log = read_file "$dir/sandbox.log";
$client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-fs", "--stdio", "--ask", "mcp",
      "--sandbox=auto", "--bwrap", "$dir/bwrap", "$dir/work"],
   env => \%env, client_capabilities => { elicitation => { form => {} } },
   on_request => $direct_answer,
);
$result = call "file-read" => { path => "auto-test" };
ok !$result->{isError} && MIME::Base64::decode_base64 ($result->{structuredContent}{data}) eq "auto"
   && length (read_file "$dir/sandbox.log") > length $old_sandbox_log,
   "auto mode selects bubblewrap when present";
my $request_count = @direct_requests;
$result = call "file-write" => { path => "auto-write-test", data => MIME::Base64::encode_base64 ("ok", "") };
ok !$result->{isError} && @direct_requests == $request_count + 1
   && $direct_requests[-1]{sandbox_implementation} eq "bubblewrap"
   && !(grep $_ eq "world-write", @{$direct_requests[-1]{sandbox_grants}}),
   "auto mode with bubblewrap requests only sandboxed authority";
$client->close;

# The server instance name selects rules independently of the routing alias.
File::Path::mkpath ("$dir/config/anyevent-mcp/rules", 0, 0700);
write_file "$dir/config/anyevent-mcp/rules/fs-alias.ini", "[rule]\ndecision=deny\naction=^\nworkdir=$dir/work\n";
chmod 0600, "$dir/config/anyevent-mcp/rules/fs-alias.ini" or die $!;
$client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-fs", "--name", "alias", "--bwrap", "$dir/bwrap", "$dir/work"],
   env => { %env, PERL_ANYEVENT_MCP_MULTIBROKER_ALIAS => "alias", PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "stdio" },
);
$result = call "file-write" => { path => "alias-denied", data => "" };
ok $result->{isError} && !-e "$dir/work/alias-denied", "named service instance selects the ordered deny policy";
$client->close;

SKIP: {
   skip "extended GNU patch metadata test (PERL_ANYEVENT_MCP_TESTS=1)", 1
      unless ($ENV{PERL_ANYEVENT_MCP_TESTS} || 0) >= 1;
   skip "GNU patch is unavailable", 1 unless $utility{patch};

   # Metadata protection remains independent of permission approval.
   link "$dir/work/read", "$dir/work/linked" or die $!;
   $client = AnyEvent::MCP::Client::JSONL->new (
      command => \@command, env => \%env, versions => ["2025-11-25"],
   );
   $result = call "file-patch" => { path => "read", diff => "@@ -2 @@\n-TWO\n+two\n" };
   ok $result->{structuredContent}{error} =~ /multiply-linked/, "patch refuses multiply-linked files";
   $client->close;

}

# Discover the URL independently of normal HTTP startup.
my $probe = IO::Socket::INET->new (
   LocalAddr => "127.0.0.1", LocalPort => 0, Proto => "tcp", Listen => 1,
) or die "allocate filesystem test port: $!\n";
my $port = $probe->sockport;
close $probe;
my $bind = "127.0.0.1:$port";
my ($url, $url_error);
{
   local %ENV = (%ENV, %env, PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "");
   my $cv = AnyEvent::Util::run_cmd (
      [$^X, "-Ilib", "bin/mcp-fs", "--name", "default", "--bind", $bind, "--print-url"],
      ">" => \$url, "2>" => \$url_error,
   );
   $cv->recv == 0 or die "mcp-fs --print-url: $url_error\n";
}
chomp $url;
my ($http_pid, $stderr, $stdout);
END { kill TERM => $http_pid if $http_pid }
my $server_cv;
{
   local %ENV = (%ENV, %env, PERL_ANYEVENT_MCP_MULTIBROKER_PROTOCOL => "");
   $server_cv = AnyEvent::Util::run_cmd (
      [$^X, "-Ilib", "bin/mcp-fs", "--name", "default", "--bind", $bind,
         "--bwrap", "$dir/bwrap", "$dir/work"],
      "<" => "/dev/null", ">" => \$stdout, "2>" => \$stderr, '$$' => \$http_pid, close_all => 1,
   );
}
my $ready;
for (1 .. 1500) {
   $ready = IO::Socket::INET->new (PeerAddr => "127.0.0.1", PeerPort => $port, Proto => "tcp", Timeout => 1);
   last if $ready;
   Time::HiRes::sleep (0.02);
}
$ready or die "filesystem listener did not start: $!\n";
close $ready;
my $web = AnyEvent::MCP::Client::HTTP->new (url => $url);
($success, $result) = wait_for (sub { $web->call (workdirs => {}, $_[0]) });
ok $success && $result->{structuredContent}{workdirs}{1} eq "$dir/work", "explicitly discovered HTTP URL is usable";
$web->close;
kill TERM => $http_pid;
$server_cv->recv;
undef $http_pid;
ok !$stdout, "filesystem HTTP startup keeps stdout empty";
ok $stderr =~ /Permission rules: \Q$dir\E\/config\/anyevent-mcp\/rules\/fs-default\.ini/,
   "HTTP startup identifies the live permission rule file";

# Program mounts are merged with named-instance overrides; no implicit /opt.
File::Path::mkpath (["$dir/shared", "$dir/only", "$dir/suppressed"], 0, 0700);
write_file "$dir/config/anyevent-mcp/global.ini", <<EOF;
[program mcp-fs]
prepend-path = $dir/bin
mount.aa = ro:$dir/suppressed
mount.bb = rw:$dir/shared
env.aa = MCP_TEST_SUPPRESSED=program
env.bb = MCP_TEST_EXPLICIT=a value=with equals
env.cc = MCP_TEST_INHERIT
env.dd = SSH_AUTH_SOCK=/forbidden
executable.perl = $^X
[instance mounttest]
prepend-path =
mount.aa =
env.aa =
env.bb = MCP_TEST_EXPLICIT=instance value=with equals
mount.cc = ro:$dir/only
EOF
chmod 0600, "$dir/config/anyevent-mcp/global.ini" or die $!;
$full_grant = 1;
$client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-fs", "--name", "mounttest", "--stdio",
      "--ask", "mcp", "--bwrap", "$dir/bwrap", "$dir/work"],
   env => \%env, client_capabilities => { elicitation => { form => {} } },
   on_request => $direct_answer,
);
sub sandbox_args {
   my @lines = split /\n/, read_file "$dir/sandbox.log";
   JSON::XS::decode_json $lines[-1]
}
sub mount_for {
   my ($argv, $path) = @_;
   my @mount;
   for my $i (0 .. $#$argv - 2) {
      push @mount, $argv->[$i]
         if $argv->[$i] =~ /\A--(?:ro-bind|bind)(?:-try)?\z/
            && $argv->[$i+1] eq $path && $argv->[$i+2] eq $path;
   }
   $mount[-1]
}
sub private_tmp {
   my ($argv) = @_;
   for my $i (0 .. $#$argv - 1) {
      return 1 if $argv->[$i] eq "--tmpfs" && $argv->[$i+1] eq "/tmp";
   }
   0
}
$result = call workdirs => {};
ok join (",", map $_->[0], @{$result->{structuredContent}{mounts}}) eq "mount.bb,mount.cc"
   && !(grep $_ eq "/opt", @{$result->{structuredContent}{runtime_paths}}),
   "instance suppresses inherited mount; /opt is not automatic";
$result = call exec => { argv => [$^X, "-e", "print 1"], reason => "mount read" };
my $argv = sandbox_args ();
ok !$result->{isError} && mount_for ($argv, "$dir/shared") eq "--bind"
   && mount_for ($argv, "$dir/only") eq "--ro-bind"
   && !mount_for ($argv, "$dir/suppressed") && private_tmp ($argv),
   "ordinary grants get writable and read-only mounts with private tmp";
ok scalar (grep $_ eq "--file", @$argv),
   "ordinary grants supply synthetic passwd";
$result = call exec => { argv => [$^X, "-e", "print 2"], reason => "read host",
   sandbox_grants => ["world-read"] };
$argv = sandbox_args ();
ok !$result->{isError} && mount_for ($argv, "/") eq "--ro-bind-try"
   && mount_for ($argv, "$dir/shared") eq "--bind"
   && !mount_for ($argv, "$dir/only") && !private_tmp ($argv),
   "world-read retains writable exception and host tmp";
ok !(grep $_ eq "--file", @$argv),
   "world-read leaves host passwd visible";
$result = call exec => { argv => [$^X, "-e", "print 3"], reason => "write host",
   sandbox_grants => ["world-write"] };
$argv = sandbox_args ();
ok !$result->{isError} && mount_for ($argv, "/") eq "--bind-try"
   && !mount_for ($argv, "$dir/shared") && !mount_for ($argv, "$dir/only")
   && !private_tmp ($argv), "world-write ignores configured mounts and private tmp";
ok !(grep $_ eq "--file", @$argv),
   "world-write leaves host passwd visible";
$result = call exec => { argv => [$^X, "-e", "print 4"], reason => "shared temp",
   sandbox_grants => ["workdir-read", "shared-tmp"] };
$argv = sandbox_args ();
ok !$result->{isError} && mount_for ($argv, "/tmp") eq "--bind-try"
   && mount_for ($argv, "/var/tmp") eq "--bind-try",
   "shared-tmp retains independent authority";

sub sandbox_env {
   my ($argv) = @_;

   my %env;
   for my $i (0 .. $#$argv - 2) {
      $env{$argv->[$i+1]} = $argv->[$i+2] if $argv->[$i] eq "--setenv";
   }
   \%env
}
my $child_env = sandbox_env $argv;
ok $child_env->{PATH} eq "/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin",
   "empty instance prepend-path overrides program setting and restores the base PATH";
ok $child_env->{MCP_TEST_EXPLICIT} eq "instance value=with equals",
   "instance environment overrides preserve literal spaces and equals signs";
ok $child_env->{MCP_TEST_INHERIT} eq "inherited value", "bare environment names inherit server values";
ok !exists $child_env->{MCP_TEST_SUPPRESSED}, "empty instance environment entry suppresses program default";
ok !exists $child_env->{SSH_AUTH_SOCK}, "configured environment cannot expose agent without grant";
$result = call exec => { argv => [$^X, "-e", "print 5"], reason => "agent access",
   sandbox_grants => ["workdir-read", "ssh-agent"] };
$argv = sandbox_args ();
my $agent_mount;
for my $i (0 .. $#$argv - 2) {
   $agent_mount = $argv->[$i] if $argv->[$i+1] eq "$dir/agent"
      && $argv->[$i+2] eq "/run/anyevent-mcp/ssh-agent";
}
ok !$result->{isError} && $agent_mount eq "--ro-bind", "agent grant binds only the selected socket at private path";
$child_env = sandbox_env $argv;
ok $child_env->{SSH_AUTH_SOCK} eq "/run/anyevent-mcp/ssh-agent",
   "agent grant sets sandbox socket path despite configured override";
ok !(grep $_ eq "--unshare-net", @$argv) && !mount_for ($argv, "$dir/home"),
   "agent grant implies network without mounting home";
ok mount_for ($argv, "$dir/home/.ssh/known_hosts") eq "--ro-bind-try",
   "agent grant exposes known_hosts read-only";
$client->close;

$client = AnyEvent::MCP::Client::JSONL->new (
   command => \@command, env => { %env, SSH_AUTH_SOCK => "$dir/work/read" },
   client_capabilities => { elicitation => { form => {} } }, on_request => $direct_answer,
);
($success) = wait_for (sub { $client->tools ($_[0]) });
$success or die "invalid-agent test server did not initialize\n";
my $before_agent = read_file "$dir/sandbox.log";
$result = call exec => { argv => [$^X, "-e", "print 6"], reason => "invalid agent socket",
   sandbox_grants => ["workdir-read", "ssh-agent"] };
ok $result->{isError} && read_file ("$dir/sandbox.log") eq $before_agent,
   "invalid agent socket fails before starting sandbox";
$client->close;

# A symlinked executable selects configuration by invoked basename, not
# by the hardcoded mcp-fs implementation or by its resolved source path.
File::Path::mkpath ("$dir/symlink-only", 0, 0700);
symlink "$root/bin/mcp-fs", "$dir/boogey" or die $!;
open my $config_out, ">>", "$dir/config/anyevent-mcp/global.ini" or die $!;
print {$config_out} "\n[program boogey]\nmount.symlink = rw:$dir/symlink-only\n";
close $config_out or die $!;
$client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "$dir/boogey", "--stdio",
      "--ask", "mcp", "--bwrap", "$dir/bwrap", "$dir/work"],
   env => \%env, client_capabilities => { elicitation => { form => {} } },
   on_request => $direct_answer,
);
$result = call workdirs => {};
ok join (",", map $_->[0], @{$result->{structuredContent}{mounts}}) eq "mount.symlink"
   && $result->{structuredContent}{mounts}[0][2] eq "$dir/symlink-only",
   "program defaults use invoked basename even for a symlink";
$client->close;

# The server's host PATH must not decide which worker executables exist.
File::Path::mkpath ("$dir/sandbox-bin", 0, 0700);
symlink $^X, "$dir/sandbox-bin/inside-perl" or die $!;
symlink "$dir/bin/git", "$dir/sandbox-bin/git" or die $!;

# Program defaults apply to instances without an explicit override.
$client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-fs", "--name", "program-path",
      "--stdio", "--ask", "mcp", "--bwrap", "$dir/bwrap", "$dir/work"],
   env => \%env, client_capabilities => { elicitation => { form => {} } },
   on_request => $direct_answer,
);
$result = call workdirs => {};
my $program_path = sandbox_env (sandbox_args ());
ok !$result->{isError} && $program_path->{PATH} eq "$dir/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin",
   "program prepend-path appends one separator before the fixed PATH";
$client->close;

open $config_out, ">>", "$dir/config/anyevent-mcp/global.ini" or die $!;
print {$config_out} "\n[instance sandbox-path]\nexecutable.perl = inside-perl\nprepend-path = $dir/sandbox-bin::\n";
close $config_out or die $!;
ok !grep ($_ eq "$dir/sandbox-bin", split /:/, $env{PATH}),
   "inside-only configured interpreter is absent from host PATH";
my %path_env = %env;
delete $path_env{PERL_ANYEVENT_MCP_TEST_FS_SANDBOX_PATH};
$client = AnyEvent::MCP::Client::JSONL->new (
   command => [$^X, "-Ilib", "bin/mcp-fs", "--name", "sandbox-path",
      "--stdio", "--ask", "mcp", "--bwrap", "$dir/bwrap", "$dir/work"],
   env => \%path_env,
   client_capabilities => { elicitation => { form => {} } },
   on_request => $direct_answer,
);
$result = call "file-read" => { path => "read" };
my $inside_worker = sandbox_args ();
ok sandbox_env ($inside_worker)->{PATH} eq "$dir/sandbox-bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin",
   "trailing colons in prepend-path do not create empty PATH entries";
ok !$result->{isError} && $inside_worker->[-3] eq "$dir/sandbox-bin/inside-perl",
   "worker uses the executable found only in the sandbox PATH";
$result = call "vcs-status" => { backend => "git" };
my $inside_vcs = sandbox_args ();
ok !$result->{isError} && (grep $_ eq "$dir/sandbox-bin/git", @$inside_vcs),
   "VCS client selection also follows sandbox PATH";
$client->close;

open $config_out, ">>", "$dir/config/anyevent-mcp/global.ini" or die $!;
print {$config_out} "\n[instance missing-perl]\nexecutable.perl = /no/such/perl\n";
close $config_out or die $!;
{
   local %ENV = (%ENV, %env);
   my $pid = open my $fh, "-|";
   defined $pid or die $!;
   unless ($pid) {
      open STDERR, ">&STDOUT" or die $!;
      exec {$^X} $^X, "-Ilib", "bin/mcp-fs", "--name", "missing-perl",
         "--stdio", "--bwrap", "$dir/bwrap", "$dir/work";
      die $!;
   }
   my $output = do { local $/; <$fh> };
   ok !close $fh && $output =~ /Perl '\/no\/such\/perl' cannot run in the worker environment/,
      "missing mandatory sandbox Perl aborts startup with a useful diagnostic";
   open $fh, "-|", $^X, "-Ilib", "bin/mcp-fs", "--name", "missing-perl",
      "--sandbox=none", "--exec-cmd", "", "--", $^X, "-e", 'print "exec-cmd-ok"' or die $!;
   $output = do { local $/; <$fh> };
   ok close $fh && $output eq "exec-cmd-ok",
      "--exec-cmd works without a usable worker Perl";
}

done_testing;
