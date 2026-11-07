use common::sense;
use Test::More;

BEGIN {
   plan skip_all => "mock remote shell test requires POSIX sh and fork"
      if $^O eq "MSWin32" || !-x "/bin/sh";
}
use AnyEvent ();
use AnyEvent::MCP::Client::JSONL ();
use File::Temp ();
use Cwd ();
use MIME::Base64 ();
use JSON::XS ();

sub put {
   my ($path, $data) = @_;
   open my $fh, ">:raw", $path or die "$path: $!";
   print {$fh} $data or die "$path: $!";
   close $fh or die "$path: $!";
}
sub get {
   open my $fh, "<:raw", $_[0] or die "$_[0]: $!";
   local $/;
   scalar <$fh>
}
sub call {
   my ($client, $tool, $args) = @_;
   my $cv = AE::cv;
   my $timer = AE::timer 30, 0, sub { die "remote filesystem test timed out\n" };
   $client->call ($tool, $args, sub { $cv->send ([@_]) });
   my ($ok, $result) = @{$cv->recv};
   $ok or die JSON::XS::encode_json ($result);
   $result
}

my $dir = Cwd::abs_path File::Temp::tempdir (CLEANUP => 1);
mkdir "$dir/work" or die $!;
mkdir "$dir/home" or die $!;
mkdir "$dir/config" or die $!;
mkdir "$dir/work/.git" or die $!;
mkdir "$dir/required" or die $!;
mkdir "$dir/optional" or die $!;
mkdir "$dir/config/anyevent-mcp" or die $!;
put "$dir/config/anyevent-mcp/global.ini", <<EOF;
[program mcp-fs]
executable.perl = $^X
mount.required = ro:$dir/required
mount-try.missing = ro:$dir/optional-later
mount-try.present = rw:$dir/optional
EOF
put "$dir/work/quote'file", "remote bytes\n";
put "$dir/rsh", "#!$^X\n" . q{
   shift @ARGV if $ARGV[0] eq "-x";
   my $host = shift;
   $host eq "mock" || $host eq "mock2" or die "wrong remote host $host\n";
   @ARGV == 1 or die "wrong remote shell argv\n";
   length ($ARGV[0]) < 256 or die "remote command exceeds rsh length limit\n";
   # An ssh-agent used locally for transport authentication is not forwarded
   # automatically. The mock must emulate a remote environment without it.
   delete $ENV{SSH_AUTH_SOCK};
   umask 027;
   open my $log, ">>", $ENV{FS_REMOTE_LOG} or die $!;
   print {$log} "connect\n";
   close $log;
   exec "/bin/sh", "-c", $ARGV[0];
   die "remote shell: $!";
};
chmod 0700, "$dir/rsh" or die $!;

# A stand-in for bubblewrap that records its mounts and invokes the worker.
# It tests argument transport and FD 3, not kernel namespace enforcement.
put "$dir/bwrap", "#!$^X\n" . q{
   while (@ARGV) {
      my $option = shift @ARGV;
      last if $option eq "--";
      if ($option =~ /\A--(?:ro-bind(?:-try)?|bind(?:-try)?)\z/) {
         my ($source, $target) = splice @ARGV, 0, 2;
         $source ne "__MCP_REMOTE_AGENT__" or die "unsubstituted SSH agent placeholder\n";
         open my $log, ">>", $ENV{FS_REMOTE_MOUNT_LOG} or die $!;
         print {$log} "$option\t$source\t$target\n" or die $!;
         close $log or die $!;
      } elsif ($option eq "--file") {
         my ($fd, $path) = splice @ARGV, 0, 2;
         $path eq "/etc/passwd" or die "unexpected --file $path\n";
         open my $fh, "<&=$fd" or die "passwd fd: $!";
         local $/;
         my $passwd = <$fh>;
         $passwd =~ /\Asandbox:x:\d+:\d+:Sandbox:/ or die "invalid remote passwd\n";
         open my $out, ">", $ENV{FS_REMOTE_PASSWD} or die $!;
         print {$out} $passwd;
         close $out;
      } elsif ($option eq "--setenv") {
         my ($name, $value) = splice @ARGV, 0, 2;
         $ENV{$name} = $value;
      } elsif ($option eq "--chdir") {
         chdir (shift @ARGV) or die "chdir: $!";
      } elsif ($option =~ /\A--(?:tmpfs|dev|proc|remount-ro|cap-drop)\z/) {
         shift @ARGV;
      } elsif ($option !~ /\A--(?:die-with-parent|new-session|unshare-[a-z-]+|disable-userns|clearenv)\z/) {
         die "unknown bwrap argument '$option'\n";
      }
   }
   exec @ARGV;
   die "remote worker exec: $!";
};
chmod 0700, "$dir/bwrap" or die $!;

my %env = (
   HOME => "$dir/home",
   XDG_CONFIG_HOME => "$dir/config",
   PATH => $ENV{PATH},
   FS_REMOTE_LOG => "$dir/rsh.log",
   FS_REMOTE_PASSWD => "$dir/passwd",
   FS_REMOTE_MOUNT_LOG => "$dir/mounts.log",
);
my @base = ($^X, "-Ilib", "bin/mcp-fs", "--stdio", "--auto-allow", "*,*,*",
   "-h", "mock", "-e", "$dir/rsh", "--bwrap", "$dir/bwrap");

my $client = AnyEvent::MCP::Client::JSONL->new (
   command => [@base, "$dir/work"], env => \%env,
);
my $r = call $client, workdirs => {};
is $r->{structuredContent}{host}, "mock", "remote host exposed";
is $r->{structuredContent}{rsh}, "$dir/rsh", "remote shell exposed";
is $r->{structuredContent}{resolved_workdirs}{1}, "$dir/work", "remote workdir resolved at startup";
is $r->{structuredContent}{umask}, "0027", "workdirs reports remote shell umask, not the local one";
is_deeply $r->{structuredContent}{workdir_vcs}{"$dir/work"}, ["git"], "remote VCS marker discovered";
is get ("$dir/rsh.log"), "connect\n", "startup uses one remote shell connection";
ok !-e "$dir/optional-later"
   && join (",", map $_->[0], @{$r->{structuredContent}{mounts}})
      eq "mount-try.missing,mount-try.present,mount.required",
   "remote startup retains optional missing mount without probing it";

rmdir "$dir/work/.git" or die $!;
$r = call $client, workdirs => {};
is_deeply $r->{structuredContent}{workdir_vcs}{"$dir/work"}, ["git"], "remote markers remain static";
is get ("$dir/rsh.log"), "connect\n", "workdirs uses cached remote snapshot";

$r = call $client, "file-read" => { path => "quote'file" };
ok !$r->{isError} && MIME::Base64::decode_base64 ($r->{structuredContent}{data}) eq "remote bytes\n",
   "file-read survives remote shell quoting";
my $mounts = get ("$dir/mounts.log");
ok index ($mounts, "--ro-bind-try\t$dir/optional-later\t$dir/optional-later\n") >= 0
   && index ($mounts, "--bind-try\t$dir/optional\t$dir/optional\n") >= 0
   && index ($mounts, "--ro-bind\t$dir/required\t$dir/required\n") >= 0,
   "remote worker receives required and optional mounts with the correct bwrap options";
my $before = () = $mounts =~ /\Q$dir\/optional-later\E/g;
mkdir "$dir/optional-later" or die $!;
$r = call $client, exec => { argv => [$^X, "-e", "print 1"], reason => "Optional remote mount appeared" };
$mounts = get ("$dir/mounts.log");
my $after = () = $mounts =~ /\Q$dir\/optional-later\E/g;
ok !$r->{isError} && $after > $before,
   "optional mount remains a bwrap try mount on later remote worker invocations";
like get ("$dir/passwd"), qr/\Asandbox:x:\d+:\d+:Sandbox:/, "synthetic passwd passed to remote bwrap";

$r = call $client, "file-write" => {
   path => "new", data => MIME::Base64::encode_base64 ("written\n", ""),
};
ok !$r->{isError} && get ("$dir/work/new") eq "written\n", "file-write executes remotely";
$r = call $client, "stat" => { paths => ["new"] };
ok !$r->{isError} && $r->{structuredContent}{result}[0]{type} eq "file", "remote stat works";

my $cv = AE::cv;
$client->tools (sub { $cv->send ([@_]) });
my ($found, $tools) = @{$cv->recv};
$found or die "remote tools/list failed";
my %available = map { $_->{name} => 1 } @$tools;
SKIP: {
   skip "GNU find unavailable remotely", 1 unless $available{list};
   $r = call $client, list => { path => "." };
   ok !$r->{isError} && $r->{content}[0]{text} =~ /quote'file/,
      "external GNU find operates through the remote sandbox";
}
SKIP: {
   skip "GNU sed unavailable remotely", 1 unless $available{"read-lines"};
   $r = call $client, "read-lines" => { path => "quote'file", ranges => ["1"] };
   ok !$r->{isError} && $r->{content}[1]{text} eq "remote bytes\n",
      "external GNU sed operates through the remote sandbox";
}
SKIP: {
   skip "GNU grep/find unavailable remotely", 1 unless $available{grep};
   $r = call $client, grep => { path => ".", pattern => "remote bytes" };
   ok !$r->{isError} && $r->{structuredContent}{stdout} =~ /quote'file:1:remote bytes/,
      "external GNU grep operates through the remote sandbox";
}
SKIP: {
   skip "GNU patch unavailable remotely", 1 unless $available{"file-patch"};
   $r = call $client, "file-patch" => {
      path => "quote'file", diff => "@@ -1 @@\n-remote bytes\n+patched bytes\n",
   };
   ok !$r->{isError} && get ("$dir/work/quote'file") eq "patched bytes\n",
      "file-patch uses the existing sandboxed Perl worker remotely";
}

$r = call $client, exec => { argv => [$^X, "-e", 'print "remote exec\n"'], reason => "Test command" };
ok !$r->{isError} && $r->{structuredContent}{stdout} eq "remote exec\n", "remote command output preserved";
$r = call $client, exec => {
   argv => [$^X, "-e", 'binmode STDIN; local $/; print <STDIN>'],
   stdin => "stdin survives the launcher\n", reason => "Test remote stdin",
};
ok !$r->{isError} && $r->{structuredContent}{stdout} eq "stdin survives the launcher\n",
   "remote launcher leaves command stdin unread";
$r = call $client, exec => {
   argv => [$^X, "-e", 'print join "|", @ARGV',
      "__MCP_REMOTE_AGENT__", "--setenv", "SSH_AUTH_SOCK", "literal"],
   reason => "Keep ordinary command arguments untouched",
};
ok !$r->{isError}
   && $r->{structuredContent}{stdout} eq "__MCP_REMOTE_AGENT__|--setenv|SSH_AUTH_SOCK|literal",
   "remote launcher does not reinterpret untrusted command arguments";
$r = call $client, "path-op" => { path => "new", rename => "renamed" };
ok !$r->{isError} && get ("$dir/work/renamed") eq "written\n", "remote path mutation works";
$r = call $client, exec => {
   argv => [$^X, "-e", 'print exists $ENV{SSH_AUTH_SOCK} ? "agent" : "no-agent"'],
   sandbox_grants => ["ssh-agent"], reason => "Check absent remote SSH agent",
};
ok !$r->{isError} && $r->{structuredContent}{stdout} eq "no-agent",
   "remote ssh-agent grant tolerates an absent forwarded agent";
$client->close;

mkdir "$dir/config/anyevent-mcp/rules" or die $!;
put "$dir/config/anyevent-mcp/rules/fs-default.ini",
   "[rule]\ndecision=allow\naction=read\nmatch.workdir=$dir/work\nsandbox-grants=workdir-read\n";
# The same named profile intentionally applies to local and remote instances.
my $shared = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..3], "--ask", "mcp", @base[6..$#base], "$dir/work"],
   env => \%env,
);
$r = call $shared, "file-read" => { path => "renamed" };
ok !$r->{isError} && MIME::Base64::decode_base64 ($r->{structuredContent}{data}) eq "written\n",
   "same --name intentionally shares broad saved rules across hosts";
$shared->close;

my @prompts;
my $answer_prompt = sub {
      my ($client, $req) = @_;
      my $request = $req->{params}{_meta}{"anyevent-mcp/permission"}{request};
      push @prompts, $request;
      $req->reply ({
         action => "accept", content => {
            decision => "allow-once", sandbox_grants => join ",", @{$request->{sandbox_grants}},
         },
      });
};
my $prompted = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..3], "--ask", "mcp", "--name", "remote-prompt",
      @base[6..$#base], "$dir/work"],
   env => \%env, client_capabilities => { elicitation => { form => {} } },
   on_request => $answer_prompt,
);
$r = call $prompted, "file-read" => { path => "renamed" };
ok !$r->{isError} && @prompts == 1, "remote read requests permission";
is $prompts[0]{dimensions}{host}{value}, "remote mock",
   "remote host permission identity excludes transport";
is_deeply $prompts[0]{dimensions}{host}{choices}, [
   { label => "This host", match => "remote mock" },
   { label => "All hosts", match => "^" },
], "host scope offers a specific host and an explicit all-hosts choice";
is $prompts[0]{dimensions}{workdir}{value}, "$dir/work",
   "remote workdir is a plain logical path, independent of host";
$prompted->close;

my $alternate_rsh = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..3], "--ask", "mcp", "--name", "remote-prompt",
      "-h", "mock", "-e", "$dir/rsh -x", "--bwrap", "$dir/bwrap", "$dir/work"],
   env => \%env, client_capabilities => { elicitation => { form => {} } },
   on_request => $answer_prompt,
);
$r = call $alternate_rsh, "file-read" => { path => "renamed" };
ok !$r->{isError} && @prompts == 2,
   "same remote host remains accessible using another remote-shell command";
is $prompts[1]{dimensions}{host}{value}, $prompts[0]{dimensions}{host}{value},
   "host permission identity is unchanged across remote transports";
is $prompts[1]{dimensions}{workdir}{value}, $prompts[0]{dimensions}{workdir}{value},
   "remote workdir permission identity is unchanged across transports";
$alternate_rsh->close;

my $other = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..5], "-h", "mock2", "-e", "$dir/rsh -x", "--bwrap", "$dir/bwrap", "$dir/work"],
   env => \%env,
);
$r = call $other, workdirs => {};
my ($other_id) = keys %{$r->{structuredContent}{resolved_workdirs}};
is $other_id, 1, "same absolute workdir on a second host has the same compact ID";
is $r->{structuredContent}{host}, "mock2", "host identity is reported independently of workdir ID";
$r = call $other, "file-read" => { path => "renamed" };
ok !$r->{isError} && MIME::Base64::decode_base64 ($r->{structuredContent}{data}) eq "written\n",
   "remote-shell arguments are parsed without involving the local shell";
$other->close;

my $local = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..5], "--bwrap", "$dir/bwrap", "$dir/work"],
   env => \%env,
);
$r = call $local, workdirs => {};
is_deeply $r->{structuredContent}{resolved_workdirs}, { 1 => "$dir/work" },
   "local and remote instances compress the same logical pathname to the same ID";
$local->close;

my $local_old_rule = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..3], "--ask", "mcp", "--bwrap", "$dir/bwrap", "$dir/work"],
   env => \%env,
);
$r = call $local_old_rule, "file-read" => { path => "renamed" };
ok !$r->{isError}, "old workdir-only saved rule applies both locally and remotely";
$local_old_rule->close;

my $local_prompt = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..3], "--ask", "mcp", "--name", "remote-prompt",
      "--bwrap", "$dir/bwrap", "$dir/work"],
   env => \%env, client_capabilities => { elicitation => { form => {} } },
   on_request => $answer_prompt,
);
$r = call $local_prompt, "file-read" => { path => "renamed" };
ok !$r->{isError} && @prompts == 3, "new local approval requests a host dimension";
is $prompts[2]{dimensions}{host}{value}, "local", "local host has its own permission identity";
is_deeply $prompts[2]{dimensions}{host}{choices}, [
   { label => "This host", match => "local" },
   { label => "All hosts", match => "^" },
], "new local rule defaults to this host but may cover all hosts";
is $prompts[2]{dimensions}{workdir}{value}, "$dir/work", "local workdir uses the same plain path";
$local_prompt->close;

symlink "$dir/work", "$dir/alias" or die "remote workdir symlink: $!";
my $aliased = AnyEvent::MCP::Client::JSONL->new (
   command => [@base, "$dir/alias"], env => \%env,
);
$r = call $aliased, workdirs => {};
my ($alias_id) = keys %{$r->{structuredContent}{workdirs}};
ok $alias_id != 1 && $r->{structuredContent}{resolved_workdirs}{$alias_id} eq "$dir/work"
   && $r->{structuredContent}{workdirs}{$alias_id} eq "$dir/alias",
   "remote workdir identity retains the logical symlink while mounts use its physical target";
$r = call $aliased, "file-read" => { path => "renamed" };
ok !$r->{isError} && MIME::Base64::decode_base64 ($r->{structuredContent}{data}) eq "written\n",
   "physically resolved remote workdir is usable for subsequent operations";
$aliased->close;

mkdir "$dir/alternate" or die $!;
unlink "$dir/alias" or die $!;
symlink "$dir/alternate", "$dir/alias" or die $!;
my $moved_alias = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..5], "-h", "mock2", "-e", "$dir/rsh", "--bwrap", "$dir/bwrap", "$dir/alias"],
   env => \%env,
);
$r = call $moved_alias, workdirs => {};
is $r->{structuredContent}{workdirs}{$alias_id}, "$dir/alias",
   "identical logical workdir gets the same ID even when its physical target differs between hosts";
is $r->{structuredContent}{resolved_workdirs}{$alias_id}, "$dir/alternate",
   "remote host independently resolves the physical workdir used for mounts";
$moved_alias->close;

my $direct = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..5], "-h", "mock", "-e", "$dir/rsh", "--sandbox=none", "$dir/work"],
   env => \%env,
);
$r = call $direct, "file-read" => { path => "renamed" };
ok !$r->{isError} && MIME::Base64::decode_base64 ($r->{structuredContent}{data}) eq "written\n",
   "remote unsandboxed mode works";
$direct->close;

my $auto = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..5], "-h", "mock", "-e", "$dir/rsh",
      "--sandbox=auto", "--bwrap", "$dir/does-not-exist", "$dir/work"],
   env => \%env,
);
$r = call $auto, "file-read" => { path => "renamed" };
ok !$r->{isError} && MIME::Base64::decode_base64 ($r->{structuredContent}{data}) eq "written\n",
   "remote sandbox=auto falls back to full-authority mode when bwrap is absent";
$auto->close;

put "$dir/broken-bwrap", "#!$^X\nexit 19;\n";
chmod 0700, "$dir/broken-bwrap" or die $!;
my $broken = AnyEvent::MCP::Client::JSONL->new (
   command => [@base[0..5], "-h", "mock", "-e", "$dir/rsh",
      "--sandbox=auto", "--bwrap", "$dir/broken-bwrap", "$dir/work"],
   env => \%env,
);
$r = call $broken, "file-read" => { path => "renamed" };
ok $r->{isError}, "remote sandbox=auto does not fall back when bwrap is present but fails";
$broken->close;

done_testing;
