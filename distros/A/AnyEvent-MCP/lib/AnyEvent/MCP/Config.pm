=head1 NAME

AnyEvent::MCP::Config - named servers and derived MCP credentials

=head1 SYNOPSIS

   use AnyEvent::MCP::Config;

   my $config = AnyEvent::MCP::Config->global;
   my $token = $config->credential ("token", "agni");
   my $url = $config->http_url ("agni", undef, path => "/");

=head1 DESCRIPTION

An MCP server and its clients often need matching credentials. Rather than
maintaining a separate password for each server and user, this module can
derive them from one private master secret. The invoked program basename,
instance name, optional username and credential purpose each contribute to
the result. Instances default to C<default>; different programs still derive
different credentials for that instance name.

The shared file format is described in L<AnyEvent::MCP/GLOBAL CONFIGURATION>.
Loading this module does not read any files. The first call to C<global>
reads the configuration, ensures a master secret exists and caches the object
for the process.

A missing secret is generated using C<AnyEvent::MCP::random_bytes> and saved
when possible. Saving failure produces a warning; the generated secret remains
usable in this process, but another process might derive different credentials.
A supplied invalid secret is an error. Changing or losing the master secret
invalidates all credentials derived from it.

Derivation uses C<derive_secret> with the random master key.
The application namespace, purpose, program, instance name and username are
separately length-prefixed, so distinct contexts derive different credentials.
Deriving a password does not create an account or configure the server to
accept it: authentication still belongs to the server.

=head1 METHODS

=over

=item $config = AnyEvent::MCP::Config->global (file => $file)

Returns the cached global configuration. The first call accepts the same
arguments as C<new>; later calls return the same object without rereading
the file. Call this explicitly during program startup.

=item $config = AnyEvent::MCP::Config->new (file => $file)

Reads C<$file>, or the default file when omitted, and ensures a master
secret exists. Unlike C<global>, each call creates an independent object.
A missing file is allowed; other read errors are fatal. Sections are available
as C<< $config->{section}{$section} >>, each a hash reference of string
values. Named servers use C<[instance NAME]>.

=item $config = AnyEvent::MCP::Config->init (file => $file)

Explicitly creates the configuration file with a random secret, mode 0600.
Creates missing parent directories with mode 0700. Fails if the file already
exists, so it cannot accidentally replace an existing secret.

=item $bytes = $config->derive_secret ($length, @info)

=item $bytes = AnyEvent::MCP::Config->derive_secret ($length, @info)

Derive C<$length> secret bytes from the configuration's master secret and
an ordered list of context byte strings C<@info>. The class form uses
C<global>, loading the default configuration on first use and reusing it
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
is optional. The default server credential is derived with no username.

Credentials use the context C<("anyevent-mcp", "token", PROGRAM, NAME, USER)>.
PROGRAM is the invoked basename, with a trailing C<.pl> or C<.perl> removed.
Changing the program or instance name changes the credential.
A credential derived with C<$username> is B<not> automatically accepted
by the server. This method neither requires a server section nor configures
authentication.

=item $program = AnyEvent::MCP::Config::program_name ()

Returns the invoked program basename, stripping C<.pl> or C<.perl>.
An inline Perl invocation uses C<perl>. This identity also selects the
C<[program PROGRAM]> configuration section; it is independent of routing aliases.

=item $name = AnyEvent::MCP::Config::server_name ($name)

Validate a service-instance name, or use C<default> if undefined.
Names consist of an ASCII letter or underscore followed by letters, digits,
underscores or hyphens.

=item @options = AnyEvent::MCP::Config::http_getopt (\$name, \$bind, \$print_url, \@tokens)

Return standard C<Getopt::Long> options referring to the caller's scalars.

=item $port = $config->server_port ($name)

Derive a stable default port in 16384..32767 from the master secret and
program basename and service-instance name. Collisions produce ordinary listener bind errors.

=item %settings = $config->http_settings ($name, $bind)

Resolve HTTP settings from C<[instance NAME]> and an optional command-line
C<bind> override. The default is IPv4 loopback and the name-derived port.
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

=cut

package AnyEvent::MCP::Config;

use common::sense;
use AnyEvent::MCP ();
use Digest::SHA ();
use MIME::Base64 ();
use File::Basename ();
use File::Path ();
use Fcntl qw(O_WRONLY O_RDWR O_CREAT O_EXCL LOCK_EX);
use Errno qw(ENOENT);
use AnyEvent::Socket ();

our @ISA = qw(AnyEvent::MCP::Base);

sub _file {
   my $dir = $ENV{XDG_CONFIG_HOME}
      || ($ENV{HOME} || die "HOME is not set\n") . "/.config";

   "$dir/anyevent-mcp/global.ini"
}

my $global;

sub global {
   my $class = shift;

   $global ||= $class->new (@_)
}

sub new {
   my ($class, %kv) = @_;

   my $self = $class->SUPER::new (section => {}, %kv);
   $self->{file} = _file unless exists $self->{file};

   if (open my $fh, "<:encoding(UTF-8)", $self->{file}) {
      $self->_read ($fh);
      close $fh or die "$self->{file}: $!\n";
   } else {
      die "$self->{file}: $!\n" unless $! == ENOENT;
   }

   $self->_ensure_secret;

   $self->{section}{global}{secret} =~ /\A[0-9a-fA-F]{128}\z/
      or die "$self->{file}: invalid secret; supply 128 hexadecimal digits\n";

   $self
}

sub _read {
   my ($self, $fh) = @_;

   local $/;
   AnyEvent::MCP::parse_ini scalar (<$fh>), sub {
      my ($name, $kv) = @_;
      my $section = $self->{section}{$name || "global"} ||= {};
      %$section = (%$section, %$kv);
   }, $self->{file};

}

sub _ensure_secret {
   my ($self) = @_;

   return if exists $self->{section}{global}{secret};

   my $secret = eval { unpack "H*", AnyEvent::MCP::random_bytes 64 };
   die "$@Supply a securely generated 128-digit hexadecimal secret in $self->{file}\n"
      if $@;

   eval {
      File::Path::mkpath (File::Basename::dirname ($self->{file}), 0, 0700);
      sysopen my $fh, $self->{file}, O_RDWR | O_CREAT, 0600
         or die "$self->{file}: $!\n";
      flock $fh, LOCK_EX or die "$self->{file}: $!\n";
      binmode $fh, ":encoding(UTF-8)";

      my $disk = bless { file => $self->{file}, section => {} }, ref $self;
      $disk->_read ($fh);

      unless (exists $disk->{section}{global}{secret}) {
         seek $fh, 0, 2 or die "$self->{file}: $!\n";
         print {$fh} "\n[global]\nsecret = $secret\n"
            or die "$self->{file}: $!\n";
         $disk->{section}{global}{secret} = $secret;
      }

      close $fh or die "$self->{file}: $!\n";
      $self->{section} = $disk->{section};
      1
   } or warn "Cannot save MCP master secret; credentials may only be stable for this process: $@";

   $self->{section}{global}{secret} = $secret
      unless exists $self->{section}{global}{secret};
}

sub init {
   my ($class, %kv) = @_;

   my $file = exists $kv{file} ? $kv{file} : _file;

   my $secret = AnyEvent::MCP::random_bytes 64;

   File::Path::mkpath (File::Basename::dirname ($file), 0, 0700);

   sysopen my $fh, $file, O_WRONLY | O_CREAT | O_EXCL, 0600
      or die "$file: $!\n";

   print {$fh} "[global]\nsecret = ", unpack ("H*", $secret), "\n"
      or die "$file: $!\n";
   close $fh or die "$file: $!\n";

   $class->new (file => $file)
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

   $self = $self->global unless ref $self;

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

sub server_name {
   my ($name) = @_;

   $name = "default" unless defined $name;

   $name =~ /\A[A-Za-z_][A-Za-z0-9_-]*\z/
      or die "Invalid MCP server name '$name'\n";

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

sub http_getopt {
   my ($name, $bind, $print_url, $tokens) = @_;

   "name=s" => $name, "bind=s" => $bind, "print-url" => $print_url, "token=s@" => $tokens
}

sub auto_rules {
   my ($self, $name) = @_;
   my %settings = (
      %{$self->{section}{"program " . program_name ()} || {}},
      %{$self->{section}{"instance " . server_name ($name)} || {}},
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

   $name = server_name $name;

   16384 + (
      (unpack "n", $self->derive_secret (
         2,
         "port",
         (AnyEvent::MCP::utf8enc program_name),
         (AnyEvent::MCP::utf8enc $name))
   ) & 16383)
}

sub http_settings {
   my ($self, $name, $bind) = @_;

   $name = server_name $name;
   my $settings = {
      %{ $self->{section}{"program " . program_name ()} },
      %{ $self->{section}{"instance $name"} },
   };
   my $port = $self->server_port ($name);
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
         qw(path url_host url_scheme)),
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

   $kv{tokens} = [exists $settings->{tokens}
      ? split /\s*,\s*/, $settings->{tokens}, -1
      : $self->credential ("token", $name)];

   %kv
}

sub http_url {
   my ($self, $name, $bind, %options) = @_;

   $name = server_name $name;

   # only a derived token depends on the master secret surviving this process.
   if (($options{auth} || "") ne "none"
      && !exists $options{tokens}
      && !exists $self->{section}{"instance $name"}{tokens}
      && !exists $self->{section}{"program " . program_name ()}{tokens}) {
      my $stored = (ref $self)->new (file => $self->{file});
      $stored->{section}{global}{secret} eq $self->{section}{global}{secret}
         or die "MCP master secret is not persistently stored in $self->{file}\n";
   }

   require AnyEvent::MCP::Server::HTTP;
   my %http = $self->http_settings ($name, $bind);
   delete $http{tokens} if ($options{auth} || "") eq "none";

   AnyEvent::MCP::Server::HTTP->new (%http, %options)->url
}


1
