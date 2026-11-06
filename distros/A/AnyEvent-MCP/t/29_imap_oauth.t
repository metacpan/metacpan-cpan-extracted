use common::sense;
use Test::More;
use File::Temp qw(tempdir);
use MIME::Base64 ();

use lib "lib";
use AnyEvent::MCP::File ();
use AnyEvent::MCP::IMAP::OAuth2 ();

my %kv = (
   method => "oauth2",
   server => "imap.example.org", user => "alice\@example.org",
   tls => "ssl", port => 993,
   "oauth-client-id" => "client-id",
   "oauth-client-secret" => "public-secret",
   "oauth-client-auth" => "client_secret_post",
   "oauth-authorization-endpoint" => "https://login.example.org/auth",
   "oauth-token-endpoint" => "https://login.example.org/token",
   "oauth-scope" => "mail.read offline_access",
   "oauth-redirect-uri" => "http://127.0.0.1:1",
   "oauth-pkce" => 1,
   "oauth-auth-access_type" => "offline",
);

my $oauth = "AnyEvent::MCP::IMAP::OAuth2";
my ($url, $state, $verifier) = $oauth->can ("authorize")->(\%kv);
like $url, qr{\Ahttps://login\.example\.org/auth\?}, "authorization URL uses configured endpoint";
like $url, qr/(?:\?|&)code_challenge_method=S256(?:&|\z)/, "uses PKCE S256";
like $url, qr/(?:\?|&)access_type=offline(?:&|\z)/, "sends generic authorization extras";
like $url, qr/redirect_uri=http%3A%2F%2F127\.0\.0\.1%3A1/, "form-encodes redirect URI";
is length $state, 43, "state has 256 random bits encoded as base64url";
is length $verifier, 43, "PKCE verifier has 256 random bits encoded as base64url";

my $redirect = "http://127.0.0.1:1/?code=abc%2F123&state=$state";
is $oauth->can ("callback_code")->(\%kv, $state, $redirect),
   "abc/123", "redirect extracts and URL-decodes authorization code";
for my $bad (
   "http://127.0.0.1:2/?code=abc&state=$state",
   "http://127.0.0.1:1/?code=abc&state=wrong",
   "http://127.0.0.1:1/?code=a&code=b&state=$state",
   "http://127.0.0.1:1/?code=abc&state=$state#fragment",
) {
   ok !eval { $oauth->can ("callback_code")->(\%kv, $state, $bad); 1 },
      "rejects invalid or altered OAuth redirect URL";
}

my @requests;
{
   no warnings "redefine";
   local *AnyEvent::HTTP::http_request = sub {
      my ($method, $endpoint, @args) = @_;
      my $cb = pop @args;
      my %args = @args;
      push @requests, [$method, $endpoint, \%args];
      my $body = $args{body};
      my $response = $body =~ /grant_type=authorization_code/
         ? '{"access_token":"first-access","refresh_token":"initial-refresh","token_type":"Bearer"}'
         : '{"access_token":"renewed-access","refresh_token":"rotated-refresh","token_type":"Bearer"}';
      $args{on_body}->($response, { Status => 200 });
      $cb->(undef, { Status => 200 });
      undef
   };

   my $granted = $oauth->can ("finish")->(\%kv, $state, $verifier, $redirect);
   is $granted->{access_token}, "first-access", "authorization code exchanged for access token";
   is $granted->{refresh_token}, "initial-refresh", "authorization code gets refresh token";
   is $requests[0][0], "POST", "token grant uses POST";
   is $requests[0][1], "https://login.example.org/token", "token grant uses configured endpoint";
   like $requests[0][2]{body}, qr/grant_type=authorization_code/, "authorization grant type";
   like $requests[0][2]{body}, qr/code_verifier=/, "PKCE verifier sent to token endpoint";
   like $requests[0][2]{body}, qr/client_secret=public-secret/, "client_secret_post configured";
   is $requests[0][2]{tls_ctx}, "high", "OAuth token HTTP uses verified TLS";
   is $requests[0][2]{recurse}, 0, "no redirect following for token endpoint";

   my $dir = tempdir (CLEANUP => 1);
   my $file = "$dir/account.ini";
   $kv{"oauth-refresh-token-base64"} = MIME::Base64::encode_base64 ("initial-refresh", "");
   my $lock = AnyEvent::MCP::File::lock $file;
   AnyEvent::MCP::File::replace $file, "[account]\n"
      . (join "", map "$_ = $kv{$_}\n", sort keys %kv);
   close $lock;

   is $oauth->can ("refresh")->($file, \%kv), "renewed-access", "refresh grant supplies access token";
   open my $fh, "<:raw", $file or die "$file: $!";
   my $saved = do { local $/; <$fh> };
   close $fh;
   like $saved, qr/oauth-refresh-token-base64 = /, "rotated refresh token persisted";
   unlike $saved, qr/initial-refresh|rotated-refresh|renewed-access/, "token values not persisted in cleartext";
   like $requests[1][2]{body}, qr/refresh_token=initial-refresh/, "refresh uses stored token";

   my $changed = { %kv, "oauth-client-id" => "other-client" };
   ok !eval { $oauth->can ("refresh")->($file, $changed); 1 },
      "reconnect refuses changed OAuth client registration";

   {
      local *AnyEvent::HTTP::http_request = sub {
         my ($method, $endpoint, @args) = @_;
         my $cb = pop @args;
         my %args = @args;
         push @requests, [$method, $endpoint, \%args];
         $args{on_body}->('{"access_token":"basic-access","token_type":"Bearer"}', { Status => 200 });
         $cb->(undef, { Status => 200 });
         undef
      };
      my %basic = (%kv, "oauth-client-auth" => "client_secret_basic");
      my $result = $oauth->can ("token")->(\%basic, grant_type => "refresh_token", refresh_token => "old");
      is $result->{access_token}, "basic-access", "client_secret_basic token response accepted";
      like $requests[-1][2]{headers}{Authorization}, qr/^Basic /, "basic client credentials sent in header";
      unlike $requests[-1][2]{body}, qr/client_secret/, "basic mode omits client secret from body";
   }

   {
      local *AnyEvent::HTTP::http_request = sub {
         my ($method, $endpoint, @args) = @_;
         my $cb = pop @args;
         my %args = @args;
         $args{on_body}->('{"error":"invalid_grant","error_description":"do not print secrets"}',
            { Status => 400 });
         $cb->(undef, { Status => 400 });
         undef
      };
      my $ok = eval { $oauth->can ("token")->(\%kv, grant_type => "refresh_token", refresh_token => "old"); 1 };
      ok !$ok, "failed token exchange rejects error response";
      like $@, qr/HTTP 400/, "token error identifies HTTP status";
      unlike $@, qr/do not print secrets/, "token error does not echo arbitrary provider error text";
   }

   {
      local *AnyEvent::HTTP::http_request = sub {
         my ($method, $endpoint, @args) = @_;
         my $cb = pop @args;
         my %args = @args;
         my $ok = $args{on_body}->("x" x 70000, { Status => 200 });
         $cb->(undef, { Status => $ok ? 200 : 598 });
         undef
      };
      my $ok = eval { $oauth->can ("token")->(\%kv, grant_type => "refresh_token", refresh_token => "old"); 1 };
      ok !$ok && $@ =~ /response too large/, "OAuth token response size is bounded";
   }
}

my $worker_tests = eval {
   require Mail::IMAPTalk;
   require IO::Socket::SSL;
   require Authen::SASL;
   require AnyEvent::MCP::Worker::IMAP;
   1
};
SKIP: {
   skip "optional IMAP worker dependencies not installed", 5 unless $worker_tests;

{
   package MockOAuthIMAP;
   our $sasl;
   sub new { bless {}, shift }
   sub capability { { "auth=xoauth2" => 1 } }
   sub authenticate {
      my ($self, $client) = @_;
      $sasl = $client->client_new ("imap", "imap.example.org")->client_start;
      1
   }
   sub uid { 1 }
   sub parse_mode { 1 }
   sub get_last_error { "fake auth error" }
}

{
   no warnings "redefine";
   local *Mail::IMAPTalk::new = sub { MockOAuthIMAP->new };
   my $settings = {
      server => "imap.example.org", port => 993, tls => "ssl",
      user => "alice\@example.org", method => "oauth2",
      oauth => \%kv, access_token => "first-access",
   };
   my $result = AnyEvent::MCP::Worker::IMAP::imap_connect ($settings);
   ok $result->{connected}, "OAuth2 IMAP worker authenticated";
   is $MockOAuthIMAP::sasl, "user=alice\@example.org\001auth=Bearer first-access\001\001",
      "worker uses XOAUTH2 token instead of password login";
}

{
   no warnings "redefine";
   local *Mail::IMAPTalk::new = sub { MockOAuthIMAP->new };
   local *AnyEvent::HTTP::http_request = sub {
      my ($method, $endpoint, @args) = @_;
      my $cb = pop @args;
      my %args = @args;
      $args{on_body}->('{"access_token":"worker-refreshed","refresh_token":"worker-rotated"}',
         { Status => 200 });
      $cb->(undef, { Status => 200 });
      undef
   };
   my $dir = tempdir (CLEANUP => 1);
   my $file = "$dir/account.ini";
   $kv{"oauth-refresh-token-base64"} = MIME::Base64::encode_base64 ("worker-original", "");
   my $lock = AnyEvent::MCP::File::lock $file;
   AnyEvent::MCP::File::replace $file, "[account]\n"
      . (join "", map "$_ = $kv{$_}\n", sort keys %kv);
   close $lock;

   my $settings = {
      server => "imap.example.org", port => 993, tls => "ssl",
      user => "alice\@example.org", method => "oauth2",
      oauth => \%kv, account_file => $file,
   };
   my $result = AnyEvent::MCP::Worker::IMAP::imap_connect ($settings);
   ok $result->{connected}, "worker obtains access token itself for a new IMAP session";
   is $MockOAuthIMAP::sasl, "user=alice\@example.org\001auth=Bearer worker-refreshed\001\001",
      "IMAP worker authenticates using the refreshed token";
   open my $fh, "<:raw", $file or die "$file: $!";
   my $saved = do { local $/; <$fh> };
   close $fh;
   like $saved, qr/\Q@{[MIME::Base64::encode_base64 ("worker-rotated", "")]}\E/,
      "worker's rotated refresh token persisted before IMAP authentication";
}
}
done_testing;
