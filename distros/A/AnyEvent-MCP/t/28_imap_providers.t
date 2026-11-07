use common::sense;
use Test::More;
use File::Temp qw(tempfile);

BEGIN {
   eval { require XML::LibXML; require HTTP::Tiny; 1 }
      or plan skip_all => "Provider discovery dependencies unavailable";
}

use lib "lib";
require AnyEvent::MCP::IMAP::Providers;

my $source = <<'JS';
const SAMPLE_SCOPES = {
  imap: "mail.read",
  extra: "offline_access",
};
var kHostnames = new Map([
  ["example.com", ["login.example.com", SAMPLE_SCOPES]],
  ["imap.example.net", ["login.example.com", "simple-scope"]],
  ["smtp.example.com", ["login.example.com", SAMPLE_SCOPES]],
]);
var kIssuers = new Map([
  [
    "login.example.com",
    {
      name: "login.example.com",
      clientId: "client'123",
      authorizationEndpoint: "https://login.example.com/auth",
      tokenEndpoint: "https://login.example.com/token",
      usePKCE: true,
    },
  ],
]);
JS

my $xml = <<'XML';
<clientConfig version="1.1">
  <emailProvider id="example.com">
    <incomingServer type="pop3"><hostname>pop.example.com</hostname></incomingServer>
    <incomingServer type="imap">
      <hostname>imap.%EMAILDOMAIN%</hostname>
      <port>993</port><socketType>SSL</socketType>
      <username>%EMAILADDRESS%</username>
      <authentication>OAuth2</authentication>
      <authentication>password-cleartext</authentication>
    </incomingServer>
  </emailProvider>
</clientConfig>
XML

my $parsed = AnyEvent::MCP::IMAP::Providers::parse_oauth ($source);
is $parsed->{"example.com"}{issuer}, "login.example.com", "issuer lookup";
is $parsed->{"example.com"}{scope}, "mail.read offline_access", "IMAP + extra scope";
is $parsed->{"imap.example.net"}{scope}, "simple-scope", "literal scope";
is $parsed->{"example.com"}{clientId}, "client'123", "client id parsed";
like eval { AnyEvent::MCP::IMAP::Providers::parse_oauth ("// changed"); 1 } ? "" : $@,
   qr/kHostnames/, "changed JavaScript layout rejected";

my $server = AnyEvent::MCP::IMAP::Providers::parse_ispdb ($xml, "somebody\@example.com");
is_deeply $server->{servers}[0], {
   server => "imap.example.com", port => 993, tls => "ssl", user => "somebody\@example.com",
   methods => [qw(oauth2 password)],
}, "ISPDB XML placeholders and connection data";

$server = AnyEvent::MCP::IMAP::Providers::parse_ispdb ($xml);
is scalar @{$server->{servers}}, 0, "unresolved hostname placeholder is not invented";

is_deeply AnyEvent::MCP::IMAP::Providers::parse_index ('["a.com","b.de","invalid/x"]'),
   [qw(a.com b.de)], "ISPDB directory index parsed and validated";

SKIP: {
   skip "mcp-imap CLI dependencies unavailable", 18
      unless eval {
         require AnyEvent::Fork::Early;
         require AnyEvent::Fork;
         require AnyEvent::Fork::RPC;
         require Term::ReadKey;
         1
      };

   my ($jsfh, $jsfile) = tempfile ();
   my ($xmlfh, $xmlfile) = tempfile ();
   print $jsfh $source;
   print $xmlfh $xml;
   close $jsfh;
   close $xmlfh;
   
   sub run_cli {
      my (@args) = @_;
      open my $fh, "-|", $^X, "-Ilib", "bin/mcp-imap",
         "--name", "sample", "--provider-file", $jsfile,
         "--ispdb-file", $xmlfile, "providers", @args
         or die "Cannot execute mcp-imap: $!";
      my $out = do { local $/; <$fh> };
      close $fh;
      ($out, $? >> 8)
   }
   
   my ($out, $status) = run_cli ();
   is $status, 0, "provider list succeeded";
   like $out, qr/example\.com/, "list contains domain";
   like $out, qr/imap\.example\.net/, "list contains IMAP host";
   unlike $out, qr/^\s+smtp\.example\.com/m, "list excludes SMTP hostname";
   
   ($out, $status) = run_cli ("alice\@example.com");
   is $status, 0, "provider command succeeded";
   like $out, qr/^\s+method oauth2/m, "suggests method oauth2";
   like $out, qr/^\s+server imap\.example\.com/m, "uses ISPDB hostname";
   like $out, qr/^\s+user alice\@example\.com/m, "substitutes email address";
   like $out, qr/^\s+oauth-scope 'mail\.read offline_access'/m, "uses IMAP scope plus extra";
   like $out, qr/^\s+oauth-client-id 'client'\\''123'/m, "shell-quotes client id";
   like $out, qr/^mcp-imap --name sample login/m, "unquotes safe account name";
   like $out, qr/^\s+oauth-redirect-uri http:\/\/127\.0\.0\.1:1/m, "defaults to blocked loopback port";
   like $out, qr/# OAuth2:/, "OAuth command identified";
   like $out, qr/# Password:\nmcp-imap --name sample login/, "password fallback has runnable syntax";
   like $out, qr/# Password:\nmcp-imap --name sample login \\\n  method password/m,
      "password fallback explicitly selects method";
   unlike $out, qr/# Password:\nmcp-imap.*?method oauth2/s, "password fallback avoids OAuth keys";
   
   ($out, $status) = run_cli ("example");
   is $status, 0, "ambiguous search lists candidates";
   like $out, qr/Specify a domain or email/, "ambiguous search does not invent a choice";
}

is AnyEvent::MCP::IMAP::Providers::quote ("'"), q(''\'''), "POSIX shell quoting";
is AnyEvent::MCP::IMAP::Providers::quote ("http://127.0.0.1:1"), "http://127.0.0.1:1",
   "safe URL needs no quotes";
is AnyEvent::MCP::IMAP::Providers::quote ("a b"), "'a b'", "space still requires shell quoting";

my $password_only = <<'XML';
<clientConfig version="1.1"><emailProvider id="gmx.test">
  <displayName>Test ISP</displayName>
  <incomingServer type="imap"><hostname>imap.mail.example</hostname><port>993</port>
    <socketType>SSL</socketType><username>%EMAILADDRESS%</username>
    <authentication>password-cleartext</authentication></incomingServer>
  <incomingServer type="imap"><hostname>imap.mail.example</hostname><port>143</port>
    <socketType>STARTTLS</socketType><username>%EMAILADDRESS%</username>
    <authentication>password-cleartext</authentication></incomingServer>
  <enable visiturl="https://mail.example/enable"><instruction>Enable IMAP in settings</instruction></enable>
</emailProvider></clientConfig>
XML
my $ordinary = AnyEvent::MCP::IMAP::Providers::parse_ispdb ($password_only, "test\@gmx.de");
is scalar @{$ordinary->{servers}}, 2, "password-only provider retains both IMAP alternatives";
is_deeply [map $_->{tls}, @{$ordinary->{servers}}], [qw(ssl starttls)], "TLS alternatives retained";
is_deeply $ordinary->{servers}[0]{methods}, ["password"], "password-only provider supported";
is_deeply $ordinary->{notes}, ["Enable IMAP in settings"], "provider enable instructions retained";
is_deeply $ordinary->{links}, ["https://mail.example/enable"], "provider setup URL retained";

done_testing;
