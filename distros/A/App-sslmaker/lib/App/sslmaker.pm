package App::sslmaker;
use strict;
use warnings;

use Carp         qw(confess croak);
use Data::Dumper ();
use Path::Tiny;
use File::umask;

use constant DEBUG        => $ENV{SSLMAKER_DEBUG} || 0;
use constant DEFAULT_BITS => $ENV{SSLMAKER_BITS}  || 4096;
use constant DEFAULT_DAYS => $ENV{SSLMAKER_DAYS}  || 365;

our $VERSION = '0.20';
our $OPENSSL = $ENV{SSLMAKER_OPENSSL} || 'openssl';

my @CONFIG_TEMPLATE_KEYS = qw(bits cert crl_days days home key);

# heavily inspired by Mojo::Loader::_all()
my %DATA = do {
  seek DATA, 0, 0;
  my $data = join '', <DATA>;
  $data =~ s/^.*\n__DATA__\r?\n/\n/s;
  $data =~ s/\n__END__\r?\n.*$/\n/s;
  $data = [split /^@@\s*(.+?)\s*\r?\n/m, $data];
  shift @$data;    # first element is empty string
  @$data;
};

# need to be defined up front
sub openssl {
  my $cb   = ref $_[-1] eq 'CODE' ? pop   : sub { print STDERR $_[1] if DEBUG == 2 and length $_[1] };
  my $self = ref $_[0]            ? shift : __PACKAGE__;
  my $buf  = '';

  use IPC::Open3;
  use Symbol;
  $self->_d("\$ $OPENSSL @_") if DEBUG;
  my $OUT = gensym;
  my $pid = open3(undef, $OUT, $OUT, $OPENSSL => @_);

  while (1) {
    my $l = sysread $OUT, my $read, 8096;
    croak "$OPENSSL: $!" unless defined $l;
    last                 unless $l;
    $buf .= $read;
  }

  waitpid $pid, 0;
  return $self->$cb($buf) unless $?;
  croak $buf;
}

sub make_cert {
  my ($self, $args) = @_;
  my $asset = $args->{cert} ? Path::Tiny->new($args->{cert}) : Path::Tiny->tempfile;

  local $UMASK = 0222;    # make files with mode 444
  croak 'Parameter "subject" is required' unless my $subject = $self->_render_subject($self->subject, $args->{subject});
  openssl qw(req -new -sha256 -x509 -extensions v3_ca), (map { (-addext => $_) } grep {length} @{$args->{ext} || []}),
    -passin => $self->_passphrase($args->{passphrase}),
    -days   => $args->{days} || DEFAULT_DAYS,
    -key    => $args->{key},
    -out    => $asset->path,
    -subj   => $subject;

  return $asset;
}

sub make_crl {
  my ($self, $args) = @_;
  my $asset = $args->{crl} ? Path::Tiny->new($args->{crl}) : Path::Tiny->tempfile;

  local $UMASK = 0122;    # make files with mode 644

  openssl qw(ca -gencrl),
    -keyfile => $args->{key},
    -cert    => $args->{cert},
    $args->{passphrase} ? (-passin => $self->_passphrase($args->{passphrase})) : (), -out => $asset->path;

  return $asset;
}

sub make_csr {
  my ($self, $args) = @_;
  my $asset = $args->{csr} ? Path::Tiny->new($args->{csr}) : Path::Tiny->tempfile;

  local $UMASK = 0277;    # make files with mode 400

  croak 'Parameter "subject" is required' unless my $subject = $self->_render_subject($self->subject, $args->{subject});
  openssl qw(req -new -sha256), $args->{passphrase} ? (-passin => $self->_passphrase($args->{passphrase})) : (),
    (map { (-addext => $_) } grep {length} @{$args->{ext} || []}),
    -key  => $args->{key},
    -days => $args->{days} || DEFAULT_DAYS,
    -out  => $asset->path,
    -subj => $subject;

  return $asset;
}

sub make_directories {
  my ($self, $args) = @_;
  my $home = $self->_home($args);
  my $file;

  $home->mkpath;
  -w $home or croak "Can't write to $home";
  mkdir $home->child($_) for qw(certs csr crl newcerts private);
  chmod 0700, $home->child('private') or croak "Couldn't chmod 0700 'private' in $home";

  if ($args->{templates}) {
    local $UMASK = 0122;    # make files with mode 644
    $self->render_to_file('crlnumber',      $file, {}) unless -e ($file = $home->child('crlnumber'));
    $self->render_to_file('index.txt',      $file, {}) unless -e ($file = $home->child('index.txt'));
    $self->render_to_file('index.txt.attr', $file, {}) unless -e ($file = $home->child('index.txt.attr'));
    $self->render_to_file('serial',         $file, {}) unless -e ($file = $home->child('serial'));
  }

  return $args->{home};    # TBD, but will be true
}

sub make_key {
  my ($self, $args) = @_;
  my $asset = $args->{key} ? Path::Tiny->new($args->{key}) : Path::Tiny->tempfile;
  my $passphrase;

  local $UMASK = 0277;     # make files with mode 400

  if ($passphrase = $args->{passphrase}) {
    $passphrase = $self->_passphrase($passphrase);
    Path::Tiny->new($1)->spew({binmode => ':raw'}, $self->_random_passphrase(64))
      if $passphrase =~ m!^file:(.+)! and !-e $1;
  }

  openssl 'genrsa', $passphrase ? (-aes256 => -passout => $passphrase) : (),
    -out => $asset->path,
    $args->{bits} || DEFAULT_BITS;

  return $asset;
}

# copy/paste from Mojo::Base::new()
sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

sub render_to_file {
  my $stash = pop;
  my ($self, $name, $path) = @_;
  my $template = $self->_render_template($name, $stash);
  my $asset;

  $asset = $path ? Path::Tiny->new($path) : Path::Tiny->tempfile;
  $asset->spew({binmode => ":raw"}, $template);
  $asset;
}

sub revoke_cert {
  my ($self, $args) = @_;
  my $home = $self->_home($args);

  local $args->{crl} = $args->{crl} || $home->child('crl.pem');

  openssl qw(ca), $args->{passphrase} ? (-passin => $self->_passphrase($args->{passphrase})) : (),
    -revoke => $args->{revoke};

  return $self->make_crl($args);    # TBD, but will be true
}

sub sign_csr {
  my ($self, $args) = @_;
  my $asset = $args->{cert} ? Path::Tiny->new($args->{cert}) : Path::Tiny->tempfile;

  local $UMASK = 0222;              # make files with mode 444

  openssl qw(ca -batch -notext -md sha256),
    -keyfile    => $args->{ca_key},
    -cert       => $args->{ca_cert},
    -passin     => $self->_passphrase($args->{passphrase}),
    -extensions => $args->{extensions} || 'usr_cert',
    -out        => $asset->path,
    -in         => $args->{csr};

  return $asset;
}

sub subject {
  my $self = shift;
  return $self->{subject} // $ENV{SSLMAKER_SUBJECT} // '' unless @_;
  $self->{subject} = $self->_render_subject(@_);
  return $self;
}

sub with_config {
  my ($self, $cb, $args) = @_;
  my $key = join ':', 'config', map { ($_, $args->{$_} // ''); } @CONFIG_TEMPLATE_KEYS;

  local $args->{home} = $self->_home($args);

  {
    local $UMASK = 0177;    # read/write for current user
    $self->{$key} ||= $self->render_to_file('openssl.cnf', $args);
  }

  local $ENV{OPENSSL_CONF} = $self->{$key}->path;
  return $self->$cb($args);
}

sub _cat {
  my $self = shift;
  my $dest = pop;

  open my $DEST, '>', $dest or croak "Couldn't write $dest: $!";
  local @ARGV = @_;
  print $DEST $_ for <>;
  close $DEST or croak "Couldn't close $dest: $!";
  return $dest;
}

sub _d {
  return 0 unless DEBUG;
  my ($self, $msg) = @_;
  print STDERR "$msg\n";
  return 0;
}

sub _home {
  my ($self, $args) = @_;
  return Path::Tiny->new($args->{home})              if exists $args->{home};
  return Path::Tiny->new($args->{ca_key})->parent(2) if $args->{ca_key};
  return Path::Tiny->new($args->{key})->parent(2)    if $args->{key};
  croak '$SSLMAKER_HOME is required';
}

sub _parse_subject {
  my ($self, $val) = @_;
  return $val if ref $val eq 'HASH';

  # /C=US/ST=Texas/L=Dallas/O=Company/OU=Department/CN=example.com/emailAddress=admin@example.com
  # Subject: C = US, ST = Texas, L = Dallas, O = Company, OU = Department, CN = superduper
  my $re = index($val, '/') == 0 ? qr{/([A-Za-z]+)=([^/]*)} : qr{([A-Za-z]+)\s*=\s*([^,]*)};
  my %subject;
  $subject{$1} = $2 while $val =~ /$re/g;
  return \%subject;
}

sub _passphrase {
  my ($self, $phrase) = @_;

  croak 'Parameter "passphrase" is required' unless defined $phrase and length $phrase;
  return croak "SCALAR is not yet supported" if ref $phrase eq 'SCALAR';
  return "file:$phrase";
}

sub _random_passphrase {
  my ($self, $length) = @_;
  my @chr = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
  join '', map { $chr[rand @chr] } 1 .. $length;
}

sub _read_subject_from_cert {
  my ($self, $cert) = @_;
  my %subject;

  # Subject: C = US, ST = Texas, L = Dallas, O = Company, OU = Department, CN = superduper
  return openssl qw(x509 -noout -text -in), $cert => sub {
    print STDERR $_[1]               if DEBUG == 2 and length $_[1];
    return $self->_parse_subject($1) if $_[1] =~ m!Subject:\s+(.+)!;
  };

  die qq(Could not read subject from "$cert".);
}

sub _render_subject {
  my $self = shift;

  my %subject;
  for my $i (@_) {
    next unless $i;
    $self->_d(qq(# Subject from @{[-r $i ? 'file' : 'data']} "$i")) if DEBUG == 2;
    my $s = -r $i ? $self->_read_subject_from_cert($i) : $self->_parse_subject($i);
    map { $self->_d(sprintf '- %-12s %s', "$_:", "$s->{$_}") } sort keys %$s if DEBUG == 2;
    $subject{$_} = $s->{$_} for keys %$s;
  }

  return join '/', '', map {"$_=$subject{$_}"} grep { defined $subject{$_} } qw(C ST L O OU CN emailAddress);
}

# used in script/sslmaker
sub _render_template {
  my ($self, $name, $stash) = @_;
  my $template = $DATA{$name} // confess "No such template: $name";
  $template =~ s!<%=\s*([^%]+)\s*%>!{eval $1 // confess $@}!ges;    # super cheap template parser
  $template;
}

1;

=encoding utf8

=head1 NAME

App::sslmaker - Be your own SSL certificate authority

=head1 VERSION

0.16

=head1 DESCRIPTION

L<App::sslmaker> is a module that provide methods for acting as your own
L<CA|http://en.wikipedia.org/wiki/Certificate_authority> (certificate authority).
It can creating SSL keys, certificates and signing requests. The methods
should have good defaults and "just work", so you don't have to worry about
the details. "Just work" depends on safe defaults, which will change when
new and more secure standards come along.

The openssl commands are based on the instructions from
L<https://jamielinux.com/docs/openssl-certificate-authority/>.

This module is used by the C<sslmaker> command line application, but can also
act as a standalone toolkit.

=head1 DISCLAIMER

This module is based on tips and tricks from online resources, and has been
reviewed by security experts. Even so, the L</AUTHOR> of this application or
any parts involved cannot be held responsible for the security of your
server, application or other parts that use the files generated by this
library.

=head1 SYNOPSIS

  $ sslmaker <action> [options]

  # 1. Initial CA setup
  # 1a. The CA admin generates root CA key and certificate
  $ sslmaker root --subject "/C=US/ST=Texas/L=Dallas/O=Company/OU=Department/CN=superduper"

  # 1b. The CA admin generates intermediate CA key and certificate
  # Uses the --subject from root CA by default
  $ sslmaker intermediate

  # 2. Client certificate setup
  # 2a. The client generates a server key and certificate signing request
  # Can be done on any other server
  # Uses the --subject from intermediate CA if available
  $ sslmaker generate <cn>
  $ sslmaker generate www.example.com

  # 2b. The client sends the signing request file to the CA admin

  # 3. CA sign and revoke process
  # 3a. The CA admin signs the certificate request
  $ sslmaker sign www.example.com.csr.pem
  $ sslmaker sign www.example.com.csr.pem [outfile]

  # 3b. The CA admin sends back the signed certificate which the client can use

  # 3c. The CA can revoke a certificate
  $ sslmaker revoke <infile>
  $ sslmaker revoke /etc/ssl/sslmaker/newcerts/1000.pem

  # 4. Utility commands
  # 4a. Create dhparam file
  $ sslmaker dhparam
  $ sslmaker dhparam /etc/ssl/sslmaker/dhparam.pem 2048

  # 4b. Show the manual for App::sslmaker
  $ sslmaker man

=head1 ENVIRONMENT VARIABLES

=over 2

=item * SSLMAKER_BITS

Default bits for a generated certificate. Default is 4096.

=item * SSLMAKER_DAYS

Default days before expiring a generated certificate. Default is 365.

=item * SSLMAKER_DEBUG

Setting this to "0" will output less debug information from C<sslmaker>.

=item * SSLMAKER_HOME

Used by the C<sslmaker> script as default home directory. Default is either
"/etc/pki/sslmaker" or "/etc/ssl/sslmaker".

Directory structure is:

  # generated by "sslmaker root"
  $SSLMAKER_HOME/root/ca.cert.pem
  $SSLMAKER_HOME/root/ca.key.pem
  $SSLMAKER_HOME/root/crlnumber
  $SSLMAKER_HOME/root/index.txt
  $SSLMAKER_HOME/root/index.txt.attr
  $SSLMAKER_HOME/root/passphrase
  $SSLMAKER_HOME/root/serial

  # generated by "sslmaker intermediate"
  $SSLMAKER_HOME/certs/ca-chain.cert.pem
  $SSLMAKER_HOME/certs/ca.cert.pem
  $SSLMAKER_HOME/certs/ca.csr.pem
  $SSLMAKER_HOME/private/ca.key.pem
  $SSLMAKER_HOME/private/passphrase
  $SSLMAKER_HOME/root/newcerts/1000.pem
  $SSLMAKER_HOME/crlnumber
  $SSLMAKER_HOME/index.txt
  $SSLMAKER_HOME/index.txt.attr
  $SSLMAKER_HOME/serial

  # generated by "sslmaker sign"
  $SSLMAKER_HOME/newcerts/1000.pem

  # generated by "sslmaker dhparam"
  $SSLMAKER_HOME/dhparam.pem

NOTE! After running "sslmaker intermediate", then it is highly suggested to
move "$SSLMAKER_HOME/root/" to a safe location, such as a memory stick. You can
revoke any of the child certificates if they are compromised, but if you loose
the root key, then all is lost.

=item * SSLMAKER_OPENSSL

Default to "openssl". Can be set to a custom path if "openssl" is not in
C<PATH>.

=item * SSLMAKER_SUBJECT

Used as default subject, unless specified.

=back

=head2 SEE ALSO

=over 4

=item * L<https://jamielinux.com/docs/openssl-certificate-authority/>

=item * L<https://www.digitalocean.com/community/tutorials/openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs>

=item * L<http://en.wikipedia.org/wiki/Certificate_authority>

=item * L<Easy RSA|https://github.com/OpenVPN/easy-rsa>

=back

=head1 METHODS

=head2 make_cert

  $asset = $self->make_cert({
              key        => "/path/to/private/input.key.pem",
              passphrase => "/path/to/passphrase.txt",
              days       => $number_of_days, # default: 365
              subject    => '/C=NO/ST=Oslo', # optional
              ext        => ["subjectAltName = DNS:example.com"], # optional
            });

This method will generate a SSL certificate using a C<key> generated by
L</make_key>. C<passphrase> should match the argument given to L</make_key>.
An optional C<subject> can be provided. The subject string will be merged with the
L</subject> attribute. C<days> can be used to set how many days the certificate
should be valid.

The returned C<$asset> is a L<Path::Tiny> object which holds the generated certificate
file. It is possible to specify the location of this object by passing on C<cert> to
this method.

=head2 make_crl

  $asset = $self->make_crl({
              key        => "/path/to/private/input.key.pem",
              cert       => "/path/to/cefrt/input.cert.pem",
              passphrase => "/path/to/passphrase.txt", # optional
            });

This method will generate a certificate revocation list (CRL) using a C<key> generated
by L</make_key>. C<passphrase> should match the argument given to L</make_key>.

The returned C<$asset> is a L<Path::Tiny> object which holds the generated certificate
file. It is possible to specify the location of this object by passing on C<crl> to
this method.

You can inspect the generated asset using the command
C<openssl crl -in $crl_asset -text>.

See also L</revoke_cert>.

=head2 make_csr

  $asset = $self->make_csr({
              key        => "/path/to/private/input.key.pem",
              passphrase => "/path/to/passphrase.txt",
              subject    => '/C=NO/ST=Oslo',
              days       => $number_of_days, # default: 365
              ext        => ["subjectAltName=DNS:example.com"], # optional
            });

This method will generate a SSL certificate signing request using a C<key>
generated by L</make_key>. C<passphrase> is only required if the C<key> was
generated with a C<passphrase>.  An optional C<subject> can be provided.
The subject string will be merged with the L</subject> attribute.

The returned C<$asset> is a L<Path::Tiny> object which holds the generated
signing request file. It is possible to specify the location of this object
by passing on C<csr> to this method.

=head2 make_directories

  $self->make_directories({
    home      => "/path/to/pki",
    templates => 1, # default: false
  });

Used to generate a suitable file structure, which reflect what C<openssl.cnf>
expects. Set C<$emplates> to a true value to generate L<files|/render_to_file>.

  $home/          # need to be writable by current user
  $home/certs/
  $home/crl/
  $home/newcerts/
  $home/private/  # will have mode 700
  # optional templates
  $home/index.txt
  $home/serial

=head2 make_key

  $asset = $self->make_key({
              passphrase => "/path/to/passphrase.txt", # optional
              bits       => 8192, # default: 4096
            });

This method will generate a SSL key.

The key will be protected with C<passphrase> if given as input. In addition
if C<passphrase> does not exist, it will be created with a random passphrase.

The returned C<$asset> is a L<Path::Tiny> object which holds the generated key.
It is possible to specify the location of this object by passing on C<key> to
this method.

=head2 new

  $self = App::sslmaker->new(%args);
  $self = App::sslmaker->new(\%args);

Object constructor.

=head2 openssl

  $self->openssl(@args);
  $self->openssl(@args, sub { ... });
  App::sslmaker::openssl(@args);
  App::sslmaker::openssl(@args, sub { ... });

Used to run the application C<openssl>. The callback defined at the end is
optional, but will be called with the complete output from the openssl
command. C<$?> is also available for inspection.

The C<openssl> application must exist in path or defined by setting the
C<SSLMAKER_OPENSSL> environment variable before loading this module.

=head2 render_to_file

  $asset = $self->render_to_file($template, \%stash);
  $asset = $self->render_to_file($template, $out_file, \%args);

This method can render a C<$template> to either a temp file or C<$out_file>.
The C<$template> will have access to C<%stash> and C<$self>.

See L</TEMPLATES> for list of valid templates.

=head2 revoke_cert

  $self->with_config(
    revoke_cert => {
      key    => "/path/to/private/ca.key.pem",
      cert   => "/path/to/certs/ca.cert.pem",
      crl    => "/path/to/crl.pem",
      revoke => "/path/to/newcerts/1000.pem",
    },
  );

This method can revoke a certificate. It need to be run either with
C<OPENSSL_CONF> or inside L</with_config>.

=head2 sign_csr

  $asset = $self->sign_csr({
              csr        => "/path/to/certs/input.csr.pem",
              ca_key     => "/path/to/private/ca.key.pem",
              ca_cert    => "/path/to/certs/ca.cert.pem",
              passphrase => "/path/to/passphrase.txt",
              extensions => "v3_ca", # default: usr_cert
            });

This method will sign a C<csr> file generated by L</make_csr>. C<ca_key> and
C<passphrase> is the same values as you would provide L</make_key> and
C<ca_cert> is the output from L</make_cert>.

The returned C<$asset> is a L<Path::Tiny> object which holds the generated
certificate. It is possible to specify the location of this object by
passing on C<cert> to this method.

=head2 subject

  $self = $self->subject(@subjects);
  $self = $self->subject("/C=NO/ST=Oslo/L=Oslo/O=Example/OU=Prime/emailAddress=admin@example.com", ...);
  $str = $self->subject;

Holds the default subject field for the certificate. Can be set by passing in a
list of subject strings, hashes or paths to certificate files. The list will
get merged, soo the last one overrides the one before.

=head2 with_config

  $any = $self->with_config($method => \%args);

Used to call a L<method|/METHODS> with a temp L</openssl.cnf>
file. The C<%stash> in the template will be constructed from the C<%args>,
which is also passed on to the next C<$method>. Example:

  $asset = $self->with_config(make_key => {
              home       => "/path/to/pki",
              passphrase => "/path/to/pki/private/passphrase.txt",
              bits       => 8192,
           });

The config file will be removed when C<$self> go out of scope.

An alternative to this method is to set the C<OPENSSL_CONF> environment
variable before calling C<$method>:

  local $ENV{OPENSSL_CONF} = "/path/to/openssl.cnf";
  $asset = $self->make_key({...});

=head1 TEMPLATES

L</render_to_file> can render these templates, which is bundled with this module:

=over 4

=item * crlnumber

Creates a file which stores the SSL CRL number. If C<n> is present in
C<%stash>, it will be used as the start number, which defaults to 1000.

=item * index.txt

This is currently just an empty file.

=item * nginx.config

Used to render an example nginx config. C<%stash> should contain C<cert>,
C<client_certificate>, C<crl>, C<key>, C<server_name> and C<verify_client>.

=item * openssl.cnf

Creates a config file for openssl. TODO: Descrive stash values.

=item * serial

Creates a file which stores the SSL serial number. If C<n> is present in
C<%stash>, it will be used as the start number, which defaults to 1000.

=back

=head1 COPYRIGHT AND LICENCE

=head2 Code

Copyright (C) Jan Henning Thorsen

The code is free software, you can redistribute it and/or modify it under the
terms of the Artistic License version 2.0.

=head2 Documentation

Documentation is licensed under the terms of Creative Commons
Attribution-ShareAlike 3.0 Unported license.

The documentation is put together by Jan Henning Thorsen, with citations from
Jamie Nguyen's website L<https://jamielinux.com/>.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

__DATA__
@@ crlnumber
<%= $stash->{n} || 1000 %>
@@ index.txt
@@ index.txt.attr
@@ serial
<%= $stash->{n} || 1000 %>
@@ nginx.config
server {
  listen 443;
  server_name <%= $stash->{domain} || 'example.com' %>;

  ssl on;
  ssl_certificate_key <%= $stash->{key} %>;
  ssl_certificate <%= $stash->{cert} %>;
  ssl_client_certificate <%= $stash->{ca_cert} %>;
  ssl_crl <%= $stash->{crl} || 'TODO' %>;
  ssl_verify_client <%= $stash->{verify_client} || 'optional' %>;
  ssl_verify_depth 2;

  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header X-Forwarded-Proto "https";
    proxy_set_header X-SSL-Client-S-DN $ssl_client_s_dn; # /C=US/ST=Florida/L=Orlando/O=CLIENT NAME/CN=CLIENT NAME
    proxy_set_header X-SSL-Client-Verified $ssl_client_verify; # SUCCESS, FAILED, NONE
  }
}
@@ openssl.cnf
HOME = <%= Path::Tiny->new($stash->{home})->absolute->stringify %>
RANDFILE = $ENV::HOME/.rnd

[ ca ]
default_ca = CA_default
unique_subject = <%= $stash->{unique_subject} || "no" %>

[ CA_default ]
copy_extensions = copy
dir = <%= Path::Tiny->new($stash->{home})->absolute->stringify %>
certs = $dir/certs
crl_dir = $dir/crl
database = $dir/index.txt
new_certs_dir = $dir/newcerts
certificate = <%= $stash->{cert} || '$dir/certs/ca.cert.pem' %>
serial = $dir/serial
crlnumber = $dir/crlnumber
crl = <%= $stash->{crl} || '$dir/crl.pem' %>
private_key = <%= $stash->{key} || '$dir/private/ca.key.pem' %>
RANDFILE = $dir/private/.rand
crl_extensions = crl_ext
name_opt = ca_default
cert_opt = ca_default
default_days = <%= $stash->{days} || DEFAULT_DAYS %>
default_crl_days = <%= $stash->{crl_days} || 30 %>
default_md = <%= $stash->{default_md} || 'sha256' %>
preserve = no
policy = policy_anything
x509_extensions = basic_exts

[ basic_exts ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always

[ custom_req_extensions ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints = CA:true
keyUsage = cRLSign, keyCertSign

[ policy_anything ]
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = optional
emailAddress = optional

[ req ]
default_bits = <%= $stash->{bits} || DEFAULT_BITS %>
default_md = sha1
default_keyfile = privkey.pem
distinguished_name = req_distinguished_name
attributes = req_attributes
string_mask = utf8only
x509_extensions = custom_req_extensions

[ req_distinguished_name ]

[ req_attributes ]

[ usr_cert ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
nsComment = "OpenSSL Generated Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical,CA:true
keyUsage = cRLSign, keyCertSign

[ crl_ext ]
authorityKeyIdentifier=keyid:always,issuer:always

[ proxy_cert_ext ]
basicConstraints = CA:FALSE
nsComment = "OpenSSL Generated Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
proxyCertInfo = critical,language:id-ppl-anyLanguage,pathlen:3,policy:foo
