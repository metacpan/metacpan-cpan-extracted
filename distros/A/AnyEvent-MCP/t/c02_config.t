use common::sense;
use AnyEvent::MCP::Config ();
use Digest::SHA ();
use MIME::Base64 ();
use File::Temp ();
use IPC::Open3 ();
use Symbol ();
use Pod::Checker ();

print "1..104\n";

my $test;
sub ok($$) {
   my ($condition, $name) = @_;

   print (($condition ? "ok " : "not ok "), ++$test, " - $name\n");
}

my $dir = File::Temp::tempdir (CLEANUP => 1);
my $file = "$dir/config/global.ini";
my $config = AnyEvent::MCP::Config->new (file => $file);
ok !-e $file, "constructor has no filesystem side effects";
$config->load;
ok !-e $file && !%{$config->{section}}, "loading a missing config leaves it empty";
$config->ensure_secret;

ok -f $file, "explicit initialization";
ok !((stat $file)[2] & 077), "private file";
ok $config->{section}{global}{secret} =~ /\A[0-9a-f]{128}\z/, "master secret size";

my $token = $config->credential ("token", "agni", "alice");
ok $token eq $config->credential ("token", "agni", "alice"), "stable derivation";
ok $token =~ /\A[A-Za-z0-9_-]{43}\z/, "URL-safe credential";
eval { $config->credential ("cookie", "agni", "alice") };
ok $@ =~ /Unknown credential purpose/, "obsolete HKDF purpose rejected";
ok $token ne $config->credential ("token", "other", "alice"), "server separation";
ok $token ne $config->credential ("token", "agni", "bob"), "user separation";
ok $token ne $config->credential ("token", "agni"), "anonymous credential differs";
ok $token eq AnyEvent::MCP::Config->new (file => $file)->load->credential ("token", "agni", "alice"), "reload";

$config->ensure_secret;
ok $token eq $config->credential ("token", "agni", "alice"), "ensure_secret is idempotent";
ok $token eq AnyEvent::MCP::Config->new (file => $file)->load->credential ("token", "agni", "alice"), "secret unchanged";

open my $fh, ">>", $file or die $!;
print {$fh} <<'EOF';
[instance agni]
tokens = first,second
[mcp-fs]
utility = /path with spaces/tool
exports = /one, /two
literal = value;#still-value
[users]
alice = administrator
EOF
close $fh or die $!;

$config = AnyEvent::MCP::Config->new (file => $file)->load;
my $port = $config->server_port ("demo");
ok $port >= 16384 && $port <= 32767, "default port is in the fixed HKDF range";
ok $port == $config->server_port ("demo"), "same name derives same port";
ok $port == AnyEvent::MCP::Config->new (file => $file)->load->server_port ("demo"),
   "default port persists across processes";
my %http = $config->http_settings ("demo");
ok $http{host} eq "127.0.0.1" && $http{port} == $port, "default listener is IPv4 loopback";
ok @{$http{tokens}} == 1 && $http{tokens}[0] eq $config->user_credentials ("demo")->[0][2],
   "default listener has one derived URL/bearer token";

$config->{section}{"instance demo"}{bind} = "127.0.0.2:43001";
%http = $config->http_settings ("demo");
ok $http{host} eq "127.0.0.2" && $http{port} == 43001, "named bind is loaded";
%http = $config->http_settings ("demo", "[::1]");
ok $http{host} eq "::1" && $http{port} == 43001,
   "host-only command-line bind inherits configured port";
%http = $config->http_settings ("demo", "127.0.0.1:43002");
ok $http{host} eq "127.0.0.1" && $http{port} == 43002, "full CLI bind overrides named bind";
%http = $config->http_settings ("demo", ":43003");
ok $http{host} eq "127.0.0.1" && $http{port} == 43003, "port-only bind defaults to loopback";
%http = $config->http_settings ("demo", "localhost:43005");
ok $http{url_host} eq "localhost" && $http{port} == 43005
   && ($http{host} eq "127.0.0.1" || $http{host} eq "::1"), "hostname bind resolves to numeric address";
ok $config->http_url ("demo", "127.0.0.1:43004", path => "/") eq
   "http://127.0.0.1:43004/" . $config->user_credentials ("demo")->[0][2] . "/",
   "printable URL uses effective settings and stable token";
eval { $config->http_url ("demo", ":0", path => "/") };
ok $@ =~ /port is not known/, "port zero cannot yield an offline URL";
my $special = "user\@doom.example+test";
ok AnyEvent::MCP::instance_name ($special) eq $special, "instance names accept email-like characters";
$config->{section}{"instance $special"}{bind} = "127.0.0.1:43006";
my %special_http = $config->http_settings ($special);
ok $special_http{port} == 43006 && $special_http{host} eq "127.0.0.1", "email-like name selects INI section";
ok $config->user_credentials ($special)->[0][2] ne $config->user_credentials ("user")->[0][2],
   "email-like name derives distinct credentials";
my $punct = ".@+-";
ok !(grep { !eval { AnyEvent::MCP::instance_name ("x${_}y"); 1 } } split //, $punct),
   "small unquoted-shell-friendly punctuation set is allowed";
ok AnyEvent::MCP::instance_name ("2test") eq "2test"
   && AnyEvent::MCP::instance_name ("_private") eq "_private", "leading digit or underscore is valid";
ok !(grep { eval { AnyEvent::MCP::instance_name ($_); 1 } }
   ("\@host", ".hidden", "bad/name", "bad!name", "bad%name", "bad=expr", "bad^name", "bad#name", "bad`name")),
   "invalid leading punctuation, path separators and shell metacharacters rejected";
for my $name ("bad name", "bad\\name", "bad:colon", "bad\"quote") {
   eval { AnyEvent::MCP::instance_name ($name) };
   ok $@ =~ /Invalid MCP server name/, "invalid instance name $name rejected";
}
eval { $config->http_settings ("demo", ":65536") };
ok $@ =~ /Invalid MCP bind/, "invalid explicit bind ports are rejected";
my ($n, $b, $u, @tokens);
my %getopt = AnyEvent::MCP::Config::http_getopt (\$n, \$b, \$u, \@tokens);
ok $getopt{"name=s"} == \$n && $getopt{"bind=s"} == \$b && $getopt{"print-url|print-urls:s"} == \$u
   && $getopt{"token=s@"} == \@tokens, "shared Getopt options refer directly to caller lexicals";

ok $config->{section}{"mcp-fs"}{utility} eq "/path with spaces/tool", "arbitrary section and spaces";
ok $config->{section}{"mcp-fs"}{exports} eq "/one, /two", "uninterpreted list value";
ok $config->{section}{"mcp-fs"}{literal} eq "value;#still-value", "literal comment characters";

%http = $config->http_settings ("agni");
ok join (",", @{$http{tokens}}) eq "first,second", "named tokens preserve order";
ok $config->http_url ("agni", "127.0.0.1:43004", path => "/") eq
   "http://127.0.0.1:43004/first/", "named URL uses first token";
ok $config->http_url ("agni", "127.0.0.1:43004", path => "/", tokens => ["override"]) eq
   "http://127.0.0.1:43004/override/", "explicit tokens override named URL token";

chmod 0644, $file or die $!;
eval { AnyEvent::MCP::Config->new (file => $file)->load };
ok !$@, "user-selected configuration permissions are accepted";

sub command {
   my @args = @_;
   my $err = Symbol::gensym;
   my $pid = IPC::Open3::open3 (my $in, my $out, $err,
      $^X, "-Ilib", "bin/anyevent-mcp", "--config", $file, @args);
   close $in;
   local $/;
   my $stdout = <$out>;
   my $stderr = <$err>;
   waitpid $pid, 0;

   ($? >> 8, $stdout, $stderr)
}

my ($status, $output) = command ("password", "agni", "alice");
ok $status, "Basic password command is removed";
($status, $output) = command ("token", "agni");
ok $status && !$output, "token command removed";
($status, $output) = command ("url", "agni");
ok $status && !$output, "URL command removed";
($status, $output) = command ("--help");
ok !$status && $output =~ /Usage: anyevent-mcp/, "help command";
($status, $output) = command ("unknown");
ok $status, "invalid command";
($status, $output) = command ("init");
ok !$status, "init command idempotently ensures existing configuration";

{
   local $ENV{HOME};
   local $ENV{XDG_CONFIG_HOME};
   ok (AnyEvent::MCP::Config->new (file => $file)->load->credential ("token", "agni", "alice") eq $token,
      "explicit config needs no HOME");
}

ok !Pod::Checker::podchecker ("lib/AnyEvent/MCP/Config.pm"), "configuration POD";
ok !Pod::Checker::podchecker ("bin/anyevent-mcp"), "utility POD";
($status, $output) = command ("cookie", "agni");
ok $status && !$output, "cookie command removed";

ok length (AnyEvent::MCP::random_bytes 64) == 64, "random byte count";
ok AnyEvent::MCP::random_bytes (0) eq "", "zero random bytes";
eval { AnyEvent::MCP::random_bytes (-1) };
ok $@, "invalid random byte count";

# verify the framed application/program/instance domains against direct HMAC.
my $master = pack "H*", $config->{section}{global}{secret};
my $expected_token = MIME::Base64::encode_base64 (
   substr (Digest::SHA::hmac_sha512 (
      (pack "(N/a*)*", "anyevent-mcp", "token", AnyEvent::MCP::Config::program_name (), "agni", "alice") . "\1", $master
   ), 0, 32), ""
);
$expected_token =~ y!+/=!-_!d;
ok $token eq $expected_token, "credential context contains namespace, purpose, program, instance and username";
ok $port == 16384 + ((unpack "n", Digest::SHA::hmac_sha512 (
   (pack "(N/a*)*", "anyevent-mcp", "port", AnyEvent::MCP::Config::program_name (), "demo") . "\1", $master
)) & 16383), "port context contains namespace, purpose, program and instance";

ok AnyEvent::MCP::instance_name (undef) eq "default", "omitted instance name is default";
ok AnyEvent::MCP::instance_name ("default") eq AnyEvent::MCP::instance_name (undef),
   "explicit and omitted default names agree";
eval { AnyEvent::MCP::Config::user_name ("foo\@bar") };
ok $@ =~ /Invalid MCP user name/, "managed usernames keep strict grammar";
{
   local $0 = "/some/path/mcp-fs.pl";
   ok AnyEvent::MCP::Config::program_name () eq "mcp-fs", "program identity uses invoked basename without Perl suffix";
   my $fs_token = $config->credential ("token", "default");
   local $0 = "/some/path/mcp-vim";
   ok $fs_token ne $config->credential ("token", "default"), "default credentials differ across programs";
}
{
   local $0 = "/some/path/program-one";
   my $one = $config->server_port ("default");
   local $0 = "/some/path/program-two";
   my $two = $config->server_port ("default");
   ok $one == 16384 + ((unpack "n", Digest::SHA::hmac_sha512 (
         (pack "(N/a*)*", "anyevent-mcp", "port", "program-one", "default") . "\1", $master
      )) & 16383)
      && $two == 16384 + ((unpack "n", Digest::SHA::hmac_sha512 (
         (pack "(N/a*)*", "anyevent-mcp", "port", "program-two", "default") . "\1", $master
      )) & 16383), "default port derivation uses each program identity (collisions remain possible)";
}
{
   local $0 = "/some/path/program-settings";
   local $config->{section}{"program program-settings"} = { bind => "127.0.0.2:43100", tokens => "program-token" };
   local $config->{section}{"instance default"} = { tokens => "instance-token" };
   my %http = $config->http_settings (undef);
   ok $http{host} eq "127.0.0.2" && $http{port} == 43100 && $http{tokens}[0] eq "instance-token",
      "program settings supply defaults and instance default overrides them";
}

my $key = pack "C*", 0 .. 63;
my $derivation = AnyEvent::MCP::Config->new (file => $file);
$derivation->{section}{global}{secret} = unpack "H*", $key;
my $bytes = $derivation->derive_secret (64, "ab", "c");
ok $bytes eq Digest::SHA::hmac_sha512 (
   (pack "(N/a*)*", "anyevent-mcp", "ab", "c") . "\1", $key
), "derive_secret frames context fields before expansion";
ok length ($derivation->derive_secret (130, "ab", "c")) == 130, "derive across digest blocks";
ok $derivation->derive_secret (32, "ab", "c") eq substr ($bytes, 0, 32),
   "shorter derivations are prefixes";
ok $bytes ne $derivation->derive_secret (64, "a", "bc"), "context field boundaries separate domains";
ok $derivation->derive_secret (32) ne $derivation->derive_secret (32, ""),
   "empty context field differs from an absent field";
ok $derivation->derive_secret (0, "test") eq "", "derive zero bytes";
ok length ($derivation->derive_secret (16320, "test")) == 16320, "derive maximum byte count";
eval { $derivation->derive_secret (-1, "test") };
ok $@ =~ /length must be an integer/, "negative derivation length rejected";
eval { $derivation->derive_secret (16321, "test") };
ok $@ =~ /length must be an integer/, "derivation cannot exceed the block counter";
eval { $derivation->derive_secret (1.5, "test") };
ok $@ =~ /length must be an integer/, "fractional derivation length rejected";
{
   local $derivation->{section}{global}{secret} = "invalid";
   eval { $derivation->derive_secret (32, "test") };
   ok $@ =~ /missing or invalid secret/, "derivation rejects an invalid master secret";
}

my $automatic = "$dir/automatic/global.ini";
my $auto = AnyEvent::MCP::Config->new (file => $automatic)->load->ensure_secret;
ok -f $automatic && !((stat $automatic)[2] & 077), "automatic private creation";
ok $auto->credential ("token", "example") eq
   AnyEvent::MCP::Config->new (file => $automatic)->load->credential ("token", "example"),
   "automatic secret persists";

my $sections = AnyEvent::MCP::Config::parse_ini ("root = first\nroot = last\n[rule]\na=one\n[rule]\na=two\n", "test.ini");
ok @$sections == 3 && $sections->[0][0] eq "" && $sections->[0][1]{root} eq "last",
   "INI unnamed section and last duplicate key win";
ok $sections->[1][0] eq "rule" && $sections->[1][1]{a} eq "one"
   && $sections->[2][0] eq "rule" && $sections->[2][1]{a} eq "two",
   "INI parser preserves repeated section ordering";
my $roundtrip = AnyEvent::MCP::Config::parse_ini (AnyEvent::MCP::Config::serialize_ini $sections);
ok @$roundtrip == 3 && $roundtrip->[1][1]{a} eq "one" && $roundtrip->[2][1]{a} eq "two",
   "INI serializer preserves repeated sections and their order";
my $merged = AnyEvent::MCP::Config::merge_sections ($sections, "global");
ok $merged->{global}{root} eq "last" && $merged->{rule}{a} eq "two",
   "INI section merging maps unnamed section and uses last repeated section";
eval { AnyEvent::MCP::Config::serialize_ini [["rule", { broken => "x\ny" }]] };
ok $@ =~ /Invalid INI value/, "INI serializer rejects multiline values";
eval { AnyEvent::MCP::Config::serialize_ini [["rule", { "#ignored" => "value" }]] };
ok $@ =~ /Invalid INI key/, "INI serializer rejects keys which would parse as comments";
eval { AnyEvent::MCP::Config::parse_ini ("[rule]\na=b\nbroken\n", "bad.ini") };
ok $@ =~ /bad\.ini:3: invalid INI line/,
   "INI errors report filename and line";
$sections = AnyEvent::MCP::Config::parse_ini "";
ok @$sections == 1 && $sections->[0][0] eq "" && !%{$sections->[0][1]},
   "empty INI has an empty unnamed section";

my $unicode_ini = "[text]\nvalue = \x{e4}\x{1f431}\n";
$sections = AnyEvent::MCP::Config::parse_ini $unicode_ini;
ok $sections->[1][1]{value} eq "\x{e4}\x{1f431}",
   "common INI parser handles Unicode text";
my $unicode_config = "$dir/unicode.ini";
my $lock = AnyEvent::MCP::file_lock $unicode_config;
AnyEvent::MCP::file_save $unicode_config, $unicode_ini;
close $lock;
ok AnyEvent::MCP::file_load ($unicode_config) eq $unicode_ini,
   "shared UTF-8 text loader and saver round-trip non-ASCII characters";
open $fh, "<:raw", $unicode_config or die $!;
ok AnyEvent::MCP::file_load ($unicode_config, $fh) eq $unicode_ini,
   "UTF-8 loader can read an already open filehandle without closing it";
close $fh;
my $invalid_utf8 = "$dir/invalid-utf8.ini";
my $invalid_lock = AnyEvent::MCP::file_lock $invalid_utf8;
AnyEvent::MCP::file_replace $invalid_utf8, "[text]\nvalue = \xff\n";
close $invalid_lock;
ok !eval { AnyEvent::MCP::file_load $invalid_utf8; 1 },
   "shared UTF-8 text loader rejects invalid encoding";
my $cfg = AnyEvent::MCP::Config->new (file => $unicode_config)->load;
ok $cfg->{section}{text}{value} eq "\x{e4}\x{1f431}",
   "global configuration uses the same shared UTF-8 INI parser";
ok $cfg->ensure_secret->{section}{global}{secret} eq
   AnyEvent::MCP::Config->new (file => $unicode_config)->load->{section}{global}{secret},
   "secret creation re-reads Unicode INI bytes and persists the generated secret";

my $partial = "$dir/partial.ini";
open $fh, ">", $partial or die $!;
print {$fh} "# keep this comment\n[mcp-fs]\nexports = /one, /two\n";
close $fh;
chmod 0600, $partial;
my $filled = AnyEvent::MCP::Config->new (file => $partial)->load->ensure_secret;
ok $filled->{section}{"mcp-fs"}{exports} eq "/one, /two", "preserve settings while adding secret";
open $fh, "<", $partial or die $!;
my $first = <$fh>;
close $fh;
ok $first eq "# keep this comment\n", "preserve configuration comments";

my $cached = AnyEvent::MCP::Config::global_config (file => $automatic);
ok $cached == AnyEvent::MCP::Config::global_config (), "global configuration cached";
{
   local $ENV{HOME};
   local $ENV{XDG_CONFIG_HOME};
   ok (AnyEvent::MCP::Config->derive_secret (32, "test") eq $cached->derive_secret (32, "test"),
      "class derivation reuses the cached global configuration");
}
ok $config->derive_secret (32, "test") ne AnyEvent::MCP::Config->derive_secret (32, "test"),
   "explicit configuration derives from its own master secret";

{
   local *File::Path::mkpath = sub { die "cannot create configuration directory\n" };
   my $unwritten = AnyEvent::MCP::Config->new (file => "$dir/unsaved/global.ini")->load;
   ok !-e $unwritten->{file}, "construct and load do not create a file";
   eval { $unwritten->ensure_secret };
   ok $@ =~ /cannot create configuration directory/, "secret persistence failure is fatal";
}

{
   local *AnyEvent::MCP::random_bytes = sub { die "random source unavailable\n" };
   eval { AnyEvent::MCP::Config->new (file => "$dir/no-random.ini")->load->ensure_secret };
   ok $@ =~ /random source unavailable\nSupply a securely generated/, "randomness failure explains manual secret";
}

open $fh, ">", "$dir/invalid.ini" or die $!;
print {$fh} "[global]\nsecret = invalid\n";
close $fh;
chmod 0600, "$dir/invalid.ini";
eval { AnyEvent::MCP::Config->new (file => "$dir/invalid.ini")->load->ensure_secret };
ok $@ =~ /invalid secret/, "invalid supplied secret rejected";
ok !Pod::Checker::podchecker ("lib/AnyEvent/MCP.pm"), "global configuration POD";
