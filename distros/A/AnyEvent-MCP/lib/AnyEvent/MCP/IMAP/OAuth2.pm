package AnyEvent::MCP::IMAP::OAuth2;

use common::sense;
use AnyEvent ();
use AnyEvent::HTTP ();
use AnyEvent::MCP ();
use AnyEvent::MCP::File ();
use Digest::SHA ();
use MIME::Base64 ();
use JSON::XS ();
use Encode ();

sub encode {
   my ($str) = @_;
   $str = Encode::encode_utf8 ($str) if utf8::is_utf8 ($str);
   $str =~ s/([^A-Za-z0-9._~-])/sprintf "%%%02X", ord $1/ge;
   $str
}

sub form {
   my (%pairs) = @_;
   join "&", map +(encode $_) . "=" . (encode $pairs{$_}), sort keys %pairs
}

sub decode {
   my ($str) = @_;
   $str =~ /%(?![a-fA-F0-9]{2})/ and die "Invalid OAuth redirect URL encoding\n";
   $str =~ tr/+/ /;
   $str =~ s/%([a-fA-F0-9]{2})/chr hex $1/ge;
   $str
}

sub b64url {
   my ($bytes) = @_;
   my $s = MIME::Base64::encode_base64 ($bytes, "");
   $s =~ tr{+/}{-_};
   $s =~ s/=+\z//;
   $s
}

sub https {
   my ($url) = @_;
   defined $url && $url =~ m{\Ahttps://[A-Za-z0-9.-]+(?::[0-9]+)?(?:/|\?|\z)}i
      && $url !~ /[\s\x00-\x1f\x7f#@]/
      or die "OAuth endpoint must be an HTTPS URL with a hostname\n";
   $url
}

sub validate {
   my ($kv) = @_;
   for my $key (qw(oauth-client-id oauth-authorization-endpoint oauth-token-endpoint oauth-scope oauth-redirect-uri)) {
      defined $kv->{$key} && !ref $kv->{$key} && length $kv->{$key}
         or die "Missing $key for OAuth2 login\n";
   }
   https $kv->{"oauth-authorization-endpoint"};
   https $kv->{"oauth-token-endpoint"};
   $kv->{"oauth-redirect-uri"} =~ m{\A(?:https://[A-Za-z0-9.-]+(?::[0-9]+)?(?:/[^\s?#]*)?|http://(?:127\.0\.0\.1|localhost)(?::[0-9]+)?(?:/[^\s?#]*)?)\z}i
      or die "OAuth redirect URI must be HTTPS or HTTP loopback, without a query or fragment\n";
   for my $key (qw(oauth-client-id oauth-scope oauth-client-secret)) {
      next unless defined $kv->{$key};
      $kv->{$key} !~ /[\r\n\x00]/ or die "Invalid $key\n";
   }
   $kv->{"oauth-pkce"} //= 1;
   $kv->{"oauth-pkce"} =~ /\A[01]\z/ or die "oauth-pkce must be 0 or 1\n";
   $kv->{"oauth-client-auth"} //= defined $kv->{"oauth-client-secret"} ? "client_secret_post" : "none";
   $kv->{"oauth-client-auth"} =~ /\A(?:none|client_secret_post|client_secret_basic)\z/
      or die "Invalid oauth-client-auth\n";
   $kv->{"oauth-client-auth"} eq "none" || defined $kv->{"oauth-client-secret"}
      or die "OAuth client-secret required for chosen client authentication\n";
   $kv->{"oauth-sasl"} //= "xoauth2";
   $kv->{"oauth-sasl"} =~ /\A(?:xoauth2|oauthbearer)\z/i or die "Invalid oauth-sasl\n";
   for my $key (grep /^oauth-auth-/, keys %$kv) {
      my ($param) = $key =~ /\Aoauth-auth-([A-Za-z0-9_]+)\z/
         or die "Invalid OAuth authorization parameter $key\n";
      $param !~ /\A(?:client_id|redirect_uri|response_type|scope|state|code_challenge|code_challenge_method)\z/
         or die "OAuth parameter $param is reserved\n";
      defined $kv->{$key} && !ref $kv->{$key} && $kv->{$key} !~ /[\r\n\x00]/
         or die "Invalid $key\n";
   }
   $kv
}

sub authorize {
   my ($kv) = @_;
   validate $kv;
   my $state = b64url (AnyEvent::MCP::random_bytes 32);
   my $verifier = $kv->{"oauth-pkce"} ? b64url (AnyEvent::MCP::random_bytes 32) : undef;
   my %params = (
      response_type => "code",
      client_id => $kv->{"oauth-client-id"},
      redirect_uri => $kv->{"oauth-redirect-uri"},
      scope => $kv->{"oauth-scope"},
      state => $state,
      (defined $verifier ? (
         code_challenge => b64url (Digest::SHA::sha256 ($verifier)),
         code_challenge_method => "S256",
      ) : ()),
   );
   for my $key (grep /^oauth-auth-/, keys %$kv) {
      (my $param = $key) =~ s/^oauth-auth-//;
      $params{$param} = $kv->{$key};
   }
   my $url = $kv->{"oauth-authorization-endpoint"};
   $url .= ($url =~ /\?/ ? "&" : "?") . form (%params);
   ($url, $state, $verifier)
}

sub callback_code {
   my ($kv, $state, $url) = @_;
   my $base = $kv->{"oauth-redirect-uri"};
   my $query;
   if ($url =~ /^\Q$base\E\?([^#]*)\z/) {
      $query = $1;
   } elsif ($base =~ m{://[^/]+\z} && $url =~ /^\Q$base\E\/\?([^#]*)\z/) {
      $query = $1; # browsers may add / to an empty HTTP path
   } else {
      die "OAuth redirect URI does not match configured URI\n";
   }
   my %params;
   for my $pair (split /&/, $query) {
      my ($key, $value) = split /=/, $pair, 2;
      $key = decode ($key);
      defined $value or die "Malformed OAuth redirect query\n";
      exists $params{$key} and die "Duplicate OAuth redirect parameter $key\n";
      $params{$key} = decode ($value);
   }
   defined $params{state} && $params{state} eq $state
      or die "OAuth state mismatch\n";
   if (defined $params{error}) {
      die "OAuth authorization failed: $params{error}\n";
   }
   defined $params{code} && length $params{code}
      or die "OAuth redirect lacks authorization code\n";
   $params{code}
}

sub token {
   my ($kv, %grant) = @_;
   validate $kv;
   my %data = (
      %grant,
      client_id => $kv->{"oauth-client-id"},
   );
   $data{client_secret} = $kv->{"oauth-client-secret"}
      if $kv->{"oauth-client-auth"} eq "client_secret_post";
   my %headers = (
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "application/json",
   );
   if ($kv->{"oauth-client-auth"} eq "client_secret_basic") {
      $headers{Authorization} = "Basic " . MIME::Base64::encode_base64 (
         encode ($kv->{"oauth-client-id"}) . ":" . encode ($kv->{"oauth-client-secret"}), ""
      );
   }

   my $body = "";
   my $oversize;
   my $cv = AE::cv;
   my $guard = AnyEvent::HTTP::http_request
      POST => $kv->{"oauth-token-endpoint"},
      body => form (%data),
      headers => \%headers,
      recurse => 0, persistent => 0, proxy => undef, tls_ctx => "high", timeout => 30,
      on_body => sub {
         $oversize = 1, return 0 if length ($body) + length ($_[0]) > 65536;
         $body .= $_[0];
         1
      },
      sub { $cv->send ($_[1]) };
   my $hdr = $cv->recv;
   undef $guard;
   $oversize and die "OAuth token response too large\n";
   my $status = $hdr->{Status} || 0;
   $status >= 200 && $status < 300 or die "OAuth token endpoint returned HTTP $status\n";
   my $result = eval { JSON::XS::decode_json ($body) };
   ref $result eq "HASH" && defined $result->{access_token} && !ref $result->{access_token}
      && length $result->{access_token}
      or die "OAuth token endpoint returned no valid access token\n";
   !defined $result->{token_type} || lc $result->{token_type} eq "bearer"
      or die "OAuth token endpoint returned a non-Bearer token\n";
   if (exists $result->{refresh_token}) {
      defined $result->{refresh_token} && !ref $result->{refresh_token}
         && length $result->{refresh_token}
         or die "OAuth token endpoint returned invalid refresh token\n";
   }
   $result
}

sub finish {
   my ($kv, $state, $verifier, $url) = @_;
   my $code = callback_code ($kv, $state, $url);
   token ($kv,
      grant_type => "authorization_code",
      code => $code,
      redirect_uri => $kv->{"oauth-redirect-uri"},
      (defined $verifier ? (code_verifier => $verifier) : ()),
   )
}

sub refresh {
   my ($file, $kv) = @_;
   my $lock = AnyEvent::MCP::File::lock $file;
   open my $fh, "<:raw", $file or die "$file: $!\n";
   local $/;
   my $data = <$fh>;
   close $fh;
   my %current;
   AnyEvent::MCP::parse_ini $data, sub {
      my ($section, $values) = @_;
      $section eq "" || $section eq "account" or die "$file: invalid account section\n";
      %current = (%current, %$values);
   }, $file;
   for my $key (qw(method server user tls port oauth-client-id oauth-client-secret
                   oauth-client-auth oauth-token-endpoint oauth-scope oauth-sasl)) {
      ($current{$key} // "") eq ($kv->{$key} // "")
         or die "IMAP OAuth account changed; restart mcp-imap\n";
   }
   my $encoded = $current{"oauth-refresh-token-base64"};
   defined $encoded && $encoded =~ /\A[A-Za-z0-9+\/]*={0,2}\z/
      or die "Missing OAuth refresh token; run mcp-imap login again\n";
   my $old = MIME::Base64::decode_base64 ($encoded);
   length $old or die "Empty OAuth refresh token\n";
   my $new = token ($kv, grant_type => "refresh_token", refresh_token => $old);
   if (defined $new->{refresh_token} && $new->{refresh_token} ne $old) {
      $current{"oauth-refresh-token-base64"} = MIME::Base64::encode_base64 ($new->{refresh_token}, "");
      AnyEvent::MCP::File::replace $file, "[account]\n"
         . (join "", map "$_ = $current{$_}\n", sort keys %current);
   }
   close $lock;
   $new->{access_token}
}

1;
