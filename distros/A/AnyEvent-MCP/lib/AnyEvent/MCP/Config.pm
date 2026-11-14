=head1 NAME

AnyEvent::MCP::Config - named servers and derived MCP credentials

=head1 SYNOPSIS

   use AnyEvent::MCP::Config;

   my $config = AnyEvent::MCP::Config::global_config;
   my $token = $config->user_credentials ("agni")->[0][2];
   my $url = $config->http_url ("agni", undef, path => "/");

=head1 DESCRIPTION

An MCP server and its clients often need matching credentials. Rather than
maintaining a separate password for each server and user, this module can
derive them from one private master secret. Users are defined by
C<user.NAME = GENERATION> in C<[global]>, C<[program PROGRAM]> or
C<[instance NAME]>, in that order of precedence. An absent global
C<user.default> is implicitly enabled at generation 1.

The shared file format is described in L<AnyEvent::MCP/GLOBAL CONFIGURATION>.
Loading this module does not read any files. C<global_config> loads the
configuration, ensures a persistent master secret exists and caches the
initialized object for the process.

A missing secret is generated using C<AnyEvent::MCP::random_bytes> and
appended under a file lock. Failure to save the secret is fatal, rather
than using a temporary secret that other processes cannot reproduce.
A supplied invalid secret is an error. Changing or losing the master
secret invalidates all credentials derived from it.

Derivation uses C<derive_secret> with the random master key.
The application namespace, purpose, program, instance name and username are
separately length-prefixed, so distinct contexts derive different credentials.
Deriving a password does not create an account or configure the server to
accept it: authentication still belongs to the server.

=head1 METHODS

=over

=item $config = AnyEvent::MCP::Config::global_config (file => $file)

Return the process-global configuration object, loaded and initialized.
The first call accepts the same arguments as C<new>, and ensures that the
master secret is persistently stored. Later calls return the same object
without rereading or reinitializing it.

=item $config = AnyEvent::MCP::Config->new (file => $file)

Construct an independent configuration object without reading or writing
the file. C<$file> defaults to the global configuration path.

=item $config->load

Reload the file, replacing the object's sections. A missing file yields an
empty configuration; other read and parsing errors are fatal. Sections are
available as C<< $config->{section}{$section} >>, each a hash reference of
string values. Named servers use C<[instance NAME]>. An optional raw file
handle can be supplied when the caller already holds the file lock.

=item $config->save

Write the loaded sections back as canonical UTF-8 INI text, sorting
sections and keys. Comments and original formatting are not retained.
The caller must hold C<AnyEvent::MCP::file_lock> through the update.
Returns the configuration object.

=item $config->ensure_secret

Ensure that C<[global]> contains a valid persistent master secret. If
missing, lock and reread the file, generate a secret only if still absent,
and append it without changing other settings. Fail if it cannot be saved
or is invalid. Returns the configuration object.

=item $bytes = $config->derive_secret ($length, @info)

=item $bytes = AnyEvent::MCP::Config->derive_secret ($length, @info)

Derive C<$length> secret bytes from the configuration's master secret and
an ordered list of context byte strings C<@info>. The class form uses
C<global_config>, loading the default configuration on first use and reusing it
thereafter. The object form uses that object's configuration, including
one loaded from an explicit file.

The same master secret and context always produce the same bytes. Use a
distinctive application/purpose string as the first context field, followed
by names or other values identifying the result:

   my $secret = AnyEvent::MCP::Config->derive_secret (
      32, "my application token v1", AnyEvent::MCP::utf8enc ($name)
   );

The result contains raw bytes; encode it yourself if a printable token is
needed. This method does not add the result to a server's accepted tokens.

The fixed C<anyevent-mcp> context field is prepended automatically.
Context fields are separately length-prefixed, so C<("ab", "c")> and
C<("a", "bc")> have different contexts. Encode character strings explicitly,
for example with C<AnyEvent::MCP::utf8enc>. Context arguments are left
unchanged.

C<$length> must be an integer in 0..16320; zero returns an empty string.
Shorter results are prefixes of longer results for the same master secret
and context. Use distinct context fields for different purposes, rather
than relying on different lengths to separate them.

Derivation uses HKDF-SHA512 expansion, with each context field prefixed by
its four-byte big-endian byte length. Changing or losing the master secret
changes every result derived from it.

=item $credential = $config->credential ($purpose, $name, $username)

Derives a 32-byte credential, returned as unpadded URL-safe Base64.
C<$purpose> is C<token>. C<$name> is the instance name, and C<$username>
is optional. This is the older unmanaged derivation API; its result is not
automatically accepted by a server. Managed credentials are enumerated by
C<user_credentials>.

Credentials use the context C<("anyevent-mcp", "token", PROGRAM, NAME, USER)>.
PROGRAM is the invoked basename, with a trailing C<.pl> or C<.perl> removed.
Changing the program or instance name changes the credential.
A credential derived with C<$username> is B<not> automatically accepted
by the server. This method neither requires a server section nor configures
authentication.

=item $users = $config->users ($instance, $program)

Return effective user definitions keyed by username, each with C<scope>
(global, program or instance) and signed C<generation>. Inheritance is
global, program, instance; a negative generation disables without fallback.

=item $credentials = $config->user_credentials ($instance, $program)

Return enabled users as C<[[USERNAME, PRINCIPAL, TOKEN]...]> with default
first. The principal is C<global:NAME>, C<program:NAME>, or C<instance:NAME>.
HKDF context includes program, instance, scope, user and generation. Rotating
a generation changes the token but preserves saved user permissions.

=item $user = $config->connect_user ($instance, $program)

Return the username allowed to register private Vim, browser WebSocket, or
multibroker reverse-MCP connections. C<connect_user> inherits through the
usual scopes and defaults to C<default>. Revoking that user disables these
connections until its generation is renewed or another user is selected.

=item $program = AnyEvent::MCP::Config::program_name ()

Returns the invoked program basename, stripping C<.pl> or C<.perl>.
An inline Perl invocation uses C<perl>. This identity also selects the
C<[program PROGRAM]> configuration section; it is independent of routing aliases.

=item $user = AnyEvent::MCP::Config::user_name ($user)

Validate a managed username (ASCII letter or underscore, followed by
letters, digits, underscores or hyphens). Instance names are validated by
L<AnyEvent::MCP/SMALL UTILITIES>.

=item @options = AnyEvent::MCP::Config::http_getopt (\$name, \$bind, \$print_url, \@tokens)

Return standard C<Getopt::Long> options referring to the caller's scalars.

=item $port = $config->server_port ($name)

Derive a stable default port in 16384..32767 from the master secret and
program basename and service-instance name. Collisions produce ordinary listener bind errors.

=item %settings = $config->http_settings ($name, $bind, $default_port)

Resolve HTTP settings from C<[instance NAME]> and an optional command-line
C<bind> override. The default is IPv4 loopback and the name-derived port;
an optional C<default_port> replaces the derived port when no bind port
is specified.
The bind setting accepts C<ADDRESS:PORT>, C<[IPv6]:PORT>, C<ADDRESS>,
and C<:PORT> (which keeps the default loopback address).
Hostnames are resolved once when settings are obtained; their original
spelling is advertised unless C<url_host> overrides it. The returned options
include C<name>, C<host>, C<port> and C<tokens>, plus configured C<path>,
C<url_host> and C<url_scheme>. This does not start a listener.

=item @rules = $config->auto_rules ($name)

Return ordered automatic permission rules from C<[program PROGRAM]> and
C<[instance NAME]>. C<auto-rule.SUFFIX = allow|deny TOOL[,ACTION[,CAPABILITY]]>
entries are sorted by key. The suffix is an arbitrary ordering label; instance
entries override matching program entries, and an empty value disables an
inherited entry. Command-line rules take precedence over these defaults.

=item $url = $config->http_url ($name, $bind, %options)

Format a URL containing the first accepted token, without listening.
Port zero cannot be used because the kernel has not yet selected a port.
When the token is derived, the master secret must be persistently stored,
so the next process derives the same URL. Explicit static tokens and
C<auth =E<gt> "none"> do not require that persistence check.

=back

=head1 INI FUNCTIONS

These functions work with Unicode character strings, not octets. Use
L<AnyEvent::MCP/file_load> and L<AnyEvent::MCP/file_save> for UTF-8
file I/O. Binary values belong in Base64 or hexadecimal form.

=over

=item $sections = AnyEvent::MCP::Config::parse_ini ($text, $filename)

Parse Unicode INI text into C<[[NAME, {KEY =E<gt> VALUE}], ...]>.
Sections retain file order, including repeated section names and the
initial unnamed section C<"">. Duplicate keys within one section use
the final value. C<$filename> is optional, for line-numbered errors.

=item $merged = AnyEvent::MCP::Config::merge_sections ($sections, $default)

Return a hash mapping section names to key/value hashes, with later
sections overriding earlier ones. When C<$default> is given, unnamed
sections use that name (C<global> for global configuration and
C<account> for IMAP accounts). Use the original ordered list instead
for files where repeated sections are meaningful, such as permission rules.

=item $text = AnyEvent::MCP::Config::serialize_ini ($sections)

Serialize an ordered section list to canonical INI text. Section order
is preserved; keys within each section are sorted. Values must be
single-line character strings. Comments and whitespace formatting
are deliberately not preserved on rewrite.

=back

=cut

package AnyEvent::MCP::Config;

use common::sense;

use Digest::SHA ();
use MIME::Base64 ();
use File::Basename ();
use Errno qw(ENOENT);

use AnyEvent::Socket ();
use AnyEvent::MCP ();

our @ISA = qw(AnyEvent::MCP::Base);

sub parse_ini {
   my ($text, $file) = @_;
   $file //= "INI";
   my @sections = (["", {}]);
   my $line = 0;

   for (split /\n/, $text) {
      ++$line;
      s/\r\z//;
      next if /\A\s*(?:[#;]|\z)/;
      if (/\A\s*\[([^\]\r\n]+)\]\s*\z/) {
         push @sections, [$1, {}];
      } elsif (/\A\s*([^=\s]+)\s*=\s*(.*?)\s*\z/) {
         $sections[-1][1]{$1} = $2;
      } else {
         die "$file:$line: invalid INI line\n";
      }
   }

   \@sections
}

sub merge_sections {
   my ($sections, $default) = @_;
   my %merged;

   for (@$sections) {
      my ($name, $kv) = @$_;
      $name = $default if defined $default && $name eq "";
      my $values = $merged{$name} ||= {};
      %$values = (%$values, %$kv);
   }

   \%merged
}

sub serialize_ini {
   my ($sections) = @_;

   join "", map {
      my ($name, $values) = @$_;
      $name !~ /[\]\r\n]/ or die "Invalid INI section name\n";
      (length $name ? "[$name]\n" : "")
         . (join "", map {
            length && !/[=\s]/ && !/\A[#;]/
               or die "Invalid INI key\n";
            my $value = $values->{$_};
            defined $value && !ref $value && $value !~ /[\r\n]/
               or die "Invalid INI value for $_\n";
            "$_ = $value\n"
         } sort keys %$values)
         . "\n"
   } @$sections
}

sub _file {
   my $dir = $ENV{XDG_CONFIG_HOME}
      || ($ENV{HOME} || die "HOME is not set\n") . "/.config";

   "$dir/anyevent-mcp/global.ini"
}

my $global;

sub global_config {
   $global //= __PACKAGE__->new (@_)->load->ensure_secret
}

sub new {
   my ($class, %kv) = @_;

   my $self = $class->SUPER::new (section => {}, %kv);
   $self->{file} = _file unless exists $self->{file};
   $self
}

sub load {
   my ($self, $fh) = @_;
   $self->{section} = {};

   unless ($fh) {
      open $fh, "<:raw", $self->{file} or do {
         die "$self->{file}: $!\n" unless $! == ENOENT;
         return $self
      };
   }

   seek $fh, 0, 0 or die "$self->{file}: $!\n";
   $self->{section} = merge_sections (parse_ini (AnyEvent::MCP::file_load ($self->{file}, $fh), $self->{file}), "global");
   close $fh or die "$self->{file}: $!\n" unless @_ > 1;

   $self
}

sub save {
   my ($self) = @_;

   AnyEvent::MCP::file_save $self->{file},
      serialize_ini [map [$_, $self->{section}{$_}], sort keys %{$self->{section}}];
   $self
}

sub ensure_secret {
   my ($self) = @_;

   unless (exists $self->{section}{global}{secret}) {
      my $lock = AnyEvent::MCP::file_lock $self->{file};
      $self->load ($lock);

      unless (exists $self->{section}{global}{secret}) {
         my $secret = eval { unpack "H*", AnyEvent::MCP::random_bytes 64 };
         die "$@Supply a securely generated 128-digit hexadecimal secret in $self->{file}\n"
            if $@;
         seek $lock, 0, 2 or die "$self->{file}: $!\n";
         print {$lock} "\n[global]\nsecret = $secret\n" or die "$self->{file}: $!\n";
         $self->{section}{global}{secret} = $secret;
      }

      close $lock or die "$self->{file}: $!\n";
   }

   $self->{section}{global}{secret} =~ /\A[0-9a-fA-F]{128}\z/
      or die "$self->{file}: invalid secret; supply 128 hexadecimal digits\n";
   $self
}

sub _prk_derive_secret($$@) {
   my ($prk, $length, @info) = @_;

   64 == length $prk
      or die "derive_secret: key length must be 64 octets\n";
   $length =~ /\A[0-9]+\z/ && $length <= 255 * 64
      or die "derive_secret: length must be an integer in 0..16320\n";

   my $info = pack "(N/a*)*", "anyevent-mcp", @info;
   my $t   = "";
   my $okm = "";
   my $i   = 0;

   while ($length > length $okm) {
      $t = Digest::SHA::hmac_sha512 $t . $info . chr ++$i, $prk;
      $okm .= $t;
   }

   substr $okm, 0, $length
}

sub derive_secret {
   my ($self, $length, @info) = @_;

   $self = global_config () unless ref $self;

   my $secret = $self->{section}{global}{secret};
   $secret =~ /\A[0-9a-fA-F]{128}\z/
      or die "$self->{file}: missing or invalid secret\n";

   _prk_derive_secret (pack ("H*", $secret), $length, @info)
}

sub program_name {
   my $name = File::Basename::basename ($0);
   $name =~ s/\.(?:pl|perl)\z//;
   $name eq "-e" ? "perl" : $name
}

sub user_name {
   my ($name) = @_;

   defined $name && $name =~ /\A[A-Za-z_][A-Za-z0-9_-]*\z/
      or die "Invalid MCP user name\n";

   $name
}

sub credential {
   my ($self, $purpose, $name, $username) = @_;

   $username = "" unless defined $username;

   $purpose eq "token"
      or die "Unknown credential purpose '$purpose'\n";

   my $credential = MIME::Base64::encode_base64 (
      $self->derive_secret (
         32,
         $purpose,
         (AnyEvent::MCP::utf8enc program_name),
         (AnyEvent::MCP::utf8enc $name),
         (AnyEvent::MCP::utf8enc $username)
      ), ""
   );
   $credential =~ y!+/=!-_!d;

   $credential
}

sub users {
   my ($self, $name, $program) = @_;

   $name = AnyEvent::MCP::instance_name $name;
   $program //= program_name;
   my %users = (default => { scope => "global", generation => 1 });

   for my $entry (
      ["global", $self->{section}{global}],
      ["program", $self->{section}{"program $program"}],
      ["instance", $self->{section}{"instance $name"}],
   ) {
      my ($scope, $section) = @$entry;
      next unless $section;

      for my $key (grep /\Auser\./, keys %$section) {
         my ($user) = $key =~ /\Auser\.([A-Za-z_][A-Za-z0-9_-]*)\z/
            or die "Invalid MCP user '$key'\n";
         my $generation = $section->{$key};
         $generation =~ /\A-?[1-9][0-9]*\z/ && length $generation < 18
            or die "Invalid MCP user generation for '$key'\n";
         $users{$user} = { scope => $scope, generation => $generation };
      }
   }

   \%users
}

sub user_credentials {
   my ($self, $name, $program) = @_;

   $name = AnyEvent::MCP::instance_name $name;
   $program //= program_name;
   my $users = $self->users ($name, $program);
   my @credentials;

   for my $user (sort { ($a ne "default") <=> ($b ne "default") || $a cmp $b } keys %$users) {
      my $info = $users->{$user};
      next unless $info->{generation} > 0;
      my $token = MIME::Base64::encode_base64 ($self->derive_secret (
         32, "user-token-v1", AnyEvent::MCP::utf8enc ($program),
         AnyEvent::MCP::utf8enc ($name), $info->{scope},
         AnyEvent::MCP::utf8enc ($user), "$info->{generation}"
      ), "");
      $token =~ y!+/=!-_!d;
      push @credentials, [$user, "$info->{scope}:$user", $token];
   }

   \@credentials
}

sub connect_user {
   my ($self, $name, $program) = @_;

   $name = AnyEvent::MCP::instance_name $name;
   $program //= program_name;
   my $user = $self->{section}{"instance $name"}{connect_user}
      // $self->{section}{"program $program"}{connect_user}
      // $self->{section}{global}{connect_user} // "default";
   user_name $user
}

sub http_getopt {
   my ($name, $bind, $print_url, $tokens) = @_;

   "name=s" => $name, "bind=s" => $bind, "print-url|print-urls:s" => $print_url, "token=s@" => $tokens
}

sub auto_rules {
   my ($self, $name) = @_;
   my %settings = (
      %{$self->{section}{"program " . program_name ()} || {}},
      %{$self->{section}{"instance " . AnyEvent::MCP::instance_name ($name)} || {}},
   );
   my @rules;

   for my $key (sort grep /\Aauto-rule\./, keys %settings) {
      $key =~ /\Aauto-rule\.(.+)\z/
         or die "Invalid automatic permission rule key '$key'\n";
      my $value = $settings{$key};
      next unless length $value;
      my ($decision, $spec) = $value =~ /\A(allow|deny)\s+(\S+)\z/
         or die "Invalid configured automatic permission rule '$key'\n";
      push @rules, [$decision, $spec];
   }

   @rules
}

sub server_port {
   my ($self, $name) = @_;

   $name = AnyEvent::MCP::instance_name $name;

   16384 + (
      (unpack "n", $self->derive_secret (
         2,
         "port",
         (AnyEvent::MCP::utf8enc program_name),
         (AnyEvent::MCP::utf8enc $name))
   ) & 16383)
}

sub http_settings {
   my ($self, $name, $bind, $default_port) = @_;

   $name = AnyEvent::MCP::instance_name $name;
   my $settings = {
      %{ $self->{section}{"program " . program_name ()} },
      %{ $self->{section}{"instance $name"} },
   };
   my $port = $default_port // $self->server_port ($name);
   my $configured = $settings->{bind} // "127.0.0.1:$port";
   $configured = "127.0.0.1$configured" if $configured =~ /\A:[0-9]+\z/;
   my ($configured_host, $configured_port) = AnyEvent::Socket::parse_hostport $configured, $port;
   defined $configured_host && defined $configured_port
      && $configured_port =~ /\A[0-9]+\z/ && $configured_port <= 65535
      or die "Invalid MCP bind address '$configured'\n";

   $bind = $configured unless defined $bind;
   $bind = "127.0.0.1$bind" if $bind =~ /\A:[0-9]+\z/;

   my ($host, $service) = AnyEvent::Socket::parse_hostport $bind, $configured_port;
   defined $host && defined $service && $service =~ /\A[0-9]+\z/ && $service <= 65535
      or die "Invalid MCP bind address '$bind'\n";

   my %kv = (
      (map { exists $settings->{$_} ? ($_ => $settings->{$_}) : () }
         qw(path url_host url_scheme tls_cert tls_key)),
      name => $name,
      host => $host,
      port => $service,
   );

   unless (AnyEvent::Socket::parse_address $host) {
      my $cv = AnyEvent->condvar;
      AnyEvent::Socket::resolve_sockaddr $host, $service, "tcp", 0, 0, $cv;
      my ($resolved) = $cv->recv;
      $resolved or die "Cannot resolve MCP bind host '$host'\n";

      my (undef, $address) = AnyEvent::Socket::unpack_sockaddr $resolved->[3];
      $kv{url_host} //= $host;
      $kv{host} = AnyEvent::Socket::format_address $address;
   }

   if (exists $settings->{tokens}) {
      $kv{tokens} = [split /\s*,\s*/, $settings->{tokens}, -1];
      $kv{connect_tokens} = $kv{tokens};
   } else {
      my $credentials = $self->user_credentials ($name);
      $kv{tokens} = [map $_->[2], @$credentials];
      $kv{token_users} = { map { $_->[2] => $_->[1] } @$credentials };
      my $connect = $self->connect_user ($name);
      $kv{connect_tokens} = [map $_->[2], grep $_->[0] eq $connect, @$credentials];
   }

   %kv
}

sub http_url {
   my ($self, $name, $bind, %options) = @_;

   $name = AnyEvent::MCP::instance_name $name;

   # only a derived token depends on the master secret surviving this process.
   if (($options{auth} || "") ne "none"
      && !exists $options{tokens}
      && !exists $self->{section}{"instance $name"}{tokens}
      && !exists $self->{section}{"program " . program_name ()}{tokens}
      && !exists $self->{section}{global}{tokens}) {
      my $stored = (ref $self)->new (file => $self->{file})->load;
      $stored->{section}{global}{secret} eq $self->{section}{global}{secret}
         or die "MCP master secret is not persistently stored in $self->{file}\n";
   }

   require AnyEvent::MCP::Server::HTTP;
   my %http = $self->http_settings ($name, $bind, delete $options{default_port});
   delete $http{tokens} if ($options{auth} || "") eq "none";

   AnyEvent::MCP::Server::HTTP->new (%http, %options)->url
}


1
