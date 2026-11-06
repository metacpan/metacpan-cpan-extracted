package AnyEvent::MCP::IMAP::Providers;

use common::sense;
use HTTP::Tiny ();
use JSON::XS ();

my $oauth_source = "https://raw.githubusercontent.com/mozilla/releases-comm-central/master/mailnews/base/src/OAuth2Providers.sys.mjs";
my $ispdb = "https://autoconfig.thunderbird.net/";

sub read_file {
   my ($file) = @_;
   open my $fh, "<:raw", $file or die "$file: $!\n";
   local $/;
   <$fh>
}

sub download {
   my ($url) = @_;
   my $res = HTTP::Tiny->new (
      timeout => 8, verify_SSL => 1, max_redirect => 0, max_size => 1_000_000,
   )->get ($url);
   $res->{success} ? $res->{content} : undef
}

sub parse_index {
   my ($json) = @_;
   my $domains = JSON::XS::decode_json ($json);
   ref $domains eq "ARRAY" or die "Invalid Thunderbird ISPDB index\n";
   [grep !ref && valid_domain ($_) && !/\.test\z/, @$domains]
}

# Only recognize Thunderbird's declarative literal data; never execute JavaScript.
sub parse_oauth {
   my ($source) = @_;

   my %scopes;
   while ($source =~ /^const\s+([A-Z_]+_SCOPES)\s*=\s*(\{.*?^\};|"[^"]*";)/msg) {
      my ($name, $value) = ($1, $2);
      if ($value =~ /^\{/) {
         my %scope = $value =~ /\b(imap|extra)\s*:\s*"([^"]*)"/g;
         $scopes{$name} = \%scope;
      } else {
         ($scopes{$name}) = $value =~ /^"([^"]*)"/;
      }
   }

   my ($hostnames) = $source =~ /\bvar\s+kHostnames\s*=\s*new Map\(\[\s*(.*?)^\]\);/ms
      or die "Thunderbird kHostnames layout changed\n";
   my ($issuers) = $source =~ /\bvar\s+kIssuers\s*=\s*new Map\(\[\s*(.*?)^\]\);/ms
      or die "Thunderbird kIssuers layout changed\n";

   my %issuer;
   while ($issuers =~ /\[\s*"([^"]+)"\s*,\s*\{\s*(.*?)^\s*\},?\s*\]/msg) {
      my ($name, $fields) = ($1, $2);
      my %fields;
      while ($fields =~ /\b(clientId|clientSecret|authorizationEndpoint|tokenEndpoint|redirectionEndpoint|usePKCE)\s*:\s*(?:"([^"]*)"|\x60([^\x60]*)\x60|(true|false))/g) {
         $fields{$1} = defined $2 ? $2 : defined $3 ? $3 : $4;
      }
      $issuer{$name} = \%fields;
   }
   %issuer or die "Thunderbird kIssuers entries not recognized\n";

   my %result;
   while ($hostnames =~ /\[\s*"([^"]+)"\s*,\s*\[\s*"([^"]+)"\s*,\s*(?:"([^"]*)"|([A-Z_]+_SCOPES)(?:\.(\w+))?)\s*\]\s*\]/mg) {
      my ($host, $name, $literal, $constant, $field) = ($1, $2, $3, $4, $5);
      my $scope = defined $literal ? $literal : $scopes{$constant};
      $scope = $scope->{$field || "imap"} . (defined $scope->{extra} ? " $scope->{extra}" : "")
         if ref $scope eq "HASH" && (!$field || $field eq "imap");
      next if ref $scope || !defined $scope || !length $scope;
      my $data = $issuer{$name} or next;
      $data->{clientId} && $data->{authorizationEndpoint} && $data->{tokenEndpoint} or next;
      $result{$host} = { %$data, issuer => $name, scope => $scope };
   }

   %result or die "Thunderbird hostname/scope entries not recognized\n";
   \%result
}

sub parse_ispdb {
   my ($xml, $email) = @_;
   require XML::LibXML;
   length $xml <= 1_000_000 or die "Autoconfig XML too large\n";
   my $doc = XML::LibXML->load_xml (
      string => $xml, no_network => 1, load_ext_dtd => 0, expand_entities => 0,
   );
   $doc->documentElement->nodeName eq "clientConfig"
      or die "Not a Thunderbird autoconfig document\n";

   my @servers;
   for my $server ($doc->findnodes ("/clientConfig/emailProvider/incomingServer[\@type='imap']")) {
      my %info = (
         server => $server->findvalue ("./hostname"),
         port => $server->findvalue ("./port"),
         tls => $server->findvalue ("./socketType"),
         user => $server->findvalue ("./username"),
      );
      my @auth = map $_->textContent, $server->findnodes ("./authentication");
      my @methods;
      push @methods, "oauth2" if grep $_ eq "OAuth2", @auth;
      push @methods, "password" if grep $_ eq "password-cleartext", @auth;
      next unless @methods;
      $info{tls} = $info{tls} eq "SSL" ? "ssl" : $info{tls} eq "STARTTLS" ? "starttls" : next;
      $info{port} =~ /^\d+$/ && $info{port} >= 1 && $info{port} <= 65535 or next;
      if (defined $email) {
         my ($local, $domain) = split /\@/, $email, 2;
         for my $key (qw(server user)) {
            $info{$key} =~ s/%EMAILADDRESS%/$email/g;
            $info{$key} =~ s/%EMAILLOCALPART%/$local/g;
            $info{$key} =~ s/%EMAILDOMAIN%/$domain/g;
         }
      }
      delete $info{user} if $info{user} =~ /%/;
      next if $info{server} !~ /\A[A-Za-z0-9.-]+\z/;
      $info{methods} = \@methods;
      push @servers, \%info;
   }
   +{
      name => scalar $doc->findvalue ("/clientConfig/emailProvider/displayName"),
      servers => \@servers,
      notes => [map $_->textContent, $doc->findnodes ("/clientConfig/emailProvider/enable/instruction[not(\@lang)]")],
      links => [map $_->getAttribute ("visiturl"), $doc->findnodes ("/clientConfig/emailProvider/enable[\@visiturl]")],
   }
}

sub valid_domain {
   $_[0] =~ /\A(?=.{1,253}\z)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+\z/
}

sub find_oauth {
   my ($all, @hosts) = @_;
   for my $host (@hosts) {
      next unless defined $host;
      return $all->{$host} if $all->{$host};
      for my $name (keys %$all) {
         return $all->{$name} if $host eq "imap.$name";
      }
   }
   undef
}

sub quote {
   my ($s) = @_;
   return $s if $s =~ /\A[-A-Za-z0-9_@%+=:,\.\/]+\z/;
   $s =~ s/'/'\\''/g;
   "'$s'"
}

sub print_login {
   my ($name, $server, $method, $oauth) = @_;
   my @kv = (method => $method);
   for my $key (qw(server tls port user)) {
      push @kv, $key => $server->{$key} if defined $server->{$key};
   }
   if ($method eq "oauth2") {
      push @kv, "oauth-client-id" => $oauth->{clientId};
      push @kv, "oauth-client-secret" => $oauth->{clientSecret} if defined $oauth->{clientSecret};
      push @kv, "oauth-authorization-endpoint" => $oauth->{authorizationEndpoint};
      push @kv, "oauth-token-endpoint" => $oauth->{tokenEndpoint};
      push @kv, "oauth-scope" => $oauth->{scope};
      push @kv, "oauth-pkce" => $oauth->{usePKCE} && $oauth->{usePKCE} eq "true" ? 1 : 0;
      my $redirect = $oauth->{redirectionEndpoint} || "http://127.0.0.1";
      $redirect .= ":1" if $redirect =~ m{\Ahttp://(?:127\.0\.0\.1|localhost)\z};
      push @kv, "oauth-redirect-uri" => $redirect;
   }
   print "mcp-imap --name ", quote ($name), " login", @kv ? " \\\n" : "\n";
   while (@kv) {
      my ($key, $value) = splice @kv, 0, 2;
      print "  $key ", quote ($value), @kv ? " \\\n" : "\n";
   }
}

sub run {
   my ($name, $provider_file, $ispdb_file, @args) = @_;
   @args <= 1 or die "Usage: mcp-imap [OPTION]... providers [SEARCH]\n";
   my $search = $args[0];
   my $email;
   if (defined $search && $search =~ /\A([^\s\@]+)\@([A-Za-z0-9.-]+)\z/) {
      $email = $search;
      $search = $2;
   }

   my $source = defined $provider_file ? read_file ($provider_file) : download ($oauth_source);
   my $oauth = defined $source ? parse_oauth ($source) : {};
   my $index = defined $provider_file || defined $ispdb_file ? [] :
      parse_index (download ($ispdb . "generated_files.json") || "[]");
   my %known = map +($_ => 1), (@$index, keys %$oauth);
   delete @known{grep /^(?:smtp|pop|pop3|carddav|carddav-personal|caldav|graph|www\.googleapis|apidata)\.|\.test\z/, keys %known};
   my @domains = sort grep !defined $search
      || index (lc $_, lc $search) >= 0
      || ($oauth->{$_} && index (lc $oauth->{$_}{issuer}, lc $search) >= 0), keys %known;

   my @exact = defined $search ? grep lc $_ eq lc $search, @domains : ();
   @domains = @exact if @exact;
   if (!defined $search || @domains > 1 || !@domains && !valid_domain ($search)) {
      @domains or die "No matching providers\n";
      print "Thunderbird mail providers (", scalar @domains, " matches):\n";
      printf "  %-32s %s\n", $_, $oauth->{$_} ? "OAuth: $oauth->{$_}{issuer}" : "ISPDB"
         for @domains;
      print "\nSpecify a domain or email address to generate login commands.\n";
      return;
   }
   my $domain = @domains == 1 ? $domains[0] : $search;
   valid_domain ($domain) or die "Invalid provider domain\n";

   my ($xml, $origin);
   if (defined $ispdb_file) {
      $xml = read_file ($ispdb_file);
      $origin = "local XML ($ispdb_file)";
   } else {
      for my $url (
         "https://autoconfig.$domain/mail/config-v1.1.xml",
         "https://$domain/.well-known/autoconfig/mail/config-v1.1.xml",
         $ispdb . "v1.1/$domain",
      ) {
         $xml = download ($url);
         if (defined $xml) {
            $origin = $url;
            last;
         }
      }
   }

   my $config = defined $xml ? parse_ispdb ($xml, $email) :
      { name => "", servers => [], notes => [], links => [] };
   print "Provider: $domain", $config->{name} ? " ($config->{name})" : "", "\n";
   print "IMAP configuration: ", $origin || "not found", "\n";
   print "OAuth reference: $oauth_source\n"
      if find_oauth ($oauth, $domain, map $_->{server}, @{$config->{servers}});
   print "No IMAP autoconfiguration found; server, TLS and port require manual setup.\n"
      unless @{$config->{servers}};
   print "Setup: $_\n" for grep length, @{$config->{notes}};
   print "Setup URL: $_\n" for grep length, @{$config->{links}};

   my @servers = @{$config->{servers}};
   push @servers, { server => $domain =~ /^imap\./ ? $domain : undef,
                    methods => ["oauth2"] }
      if !@servers && find_oauth ($oauth, $domain);
   @servers or die "No supported IMAP configuration for $domain\n";

   for my $server (@servers) {
      my $o = find_oauth ($oauth, $domain, $server->{server});
      print "\nIMAP $server->{server}:$server->{port} ($server->{tls}), authentication: ",
         join (", ", @{$server->{methods}}), "\n"
         if defined $server->{server} && defined $server->{port};
      for my $method (@{$server->{methods}}) {
         if ($method eq "oauth2" && !$o) {
            print "OAuth2 advertised, but no usable Thunderbird client registration was found.\n";
            next;
         }
         print "\n# ", $method eq "oauth2" ? "OAuth2" : "Password", ":\n";
         print "# Thunderbird's OAuth client registration may not be authorized for other applications.\n"
            if $method eq "oauth2";
         print "# OAuth2 requires a refresh token; provider-specific offline access parameters may be needed.\n"
            if $method eq "oauth2";
         print_login ($name, $server, $method, $o);
      }
   }
}

1;
