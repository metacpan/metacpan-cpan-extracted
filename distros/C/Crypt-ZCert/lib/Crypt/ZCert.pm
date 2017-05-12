package Crypt::ZCert;
$Crypt::ZCert::VERSION = '0.003002';
use v5.10;
use Carp;
use strictures 2;

use FFI::Raw;

use Convert::Z85;
use Text::ZPL;

use Try::Tiny;

use List::Objects::WithUtils;

use List::Objects::Types  -types;
use Types::Path::Tiny     -types;
use Types::Standard       -types;


use Moo; use MooX::late;

has adjust_permissions => (
  is          => 'ro',
  isa         => Bool,
  builder     => sub { 1 },
);

has ignore_existing => (
  is          => 'ro',
  isa         => Bool,
  builder     => sub { 0 },
);

has public_file => (
  lazy        => 1,
  is          => 'ro',
  isa         => Maybe[Path],
  coerce      => 1,
  predicate   => 1,
  builder     => sub { undef },
);

has secret_file => (
  lazy        => 1,
  is          => 'ro',
  isa         => Maybe[Path],
  coerce      => 1,
  predicate   => 1,
  builder     => sub {
    my ($self) = @_;
    $self->has_public_file ? $self->public_file . '_secret' : undef
  },
);


has public_key_z85 => (
  lazy        => 1,
  is          => 'ro',
  isa         => Str,
  writer      => '_set_public_key_z85',
  builder     => sub {
    my ($self) = @_;
    my $keypair = $self->generate_keypair;
    $self->_set_secret_key_z85( $keypair->secret );
    $keypair->public
  },
);

has secret_key_z85 => (
  lazy        => 1,
  is          => 'ro',
  isa         => Str,
  writer      => '_set_secret_key_z85',
  builder     => sub {
    my ($self) = @_;
    my $keypair = $self->generate_keypair;
    $self->_set_public_key_z85( $keypair->public );
    $keypair->secret
  },
);

has public_key => (
  lazy        => 1,
  is          => 'ro',
  isa         => Defined,
  builder     => sub { decode_z85 $_[0]->public_key_z85 },
);

has secret_key => (
  lazy        => 1,
  is          => 'ro',
  isa         => Defined,
  builder     => sub { decode_z85 $_[0]->secret_key_z85 },
);

has metadata => (
  lazy        => 1,
  is          => 'ro',
  isa         => HashObj,
  coerce      => 1,
  builder     => sub { +{} },
);

has zmq_soname => (
  is          => 'ro',
  isa         => Str,
  builder     => sub {
    # Early 4.x installs as libzmq.so.3 ->
    state $search = [ qw/
      libzmq.so.4
      libzmq.so.4.0.0
      libzmq.so.3
      libzmq.so
      libzmq.4.dylib
      libzmq.3.dylib
      libzmq.dylib
    / ];

    my ($soname, $zmq_vers);
    SEARCH: for my $maybe (@$search) {
      try {
        $zmq_vers = FFI::Raw->new(
          $maybe, zmq_version =>
            FFI::Raw::void,
            FFI::Raw::ptr,
            FFI::Raw::ptr,
            FFI::Raw::ptr,
        );
        $soname = $maybe;
      };
      last SEARCH if defined $soname;
    } # SEARCH
    croak "Failed to locate a suitable libzmq in your linker's search path"
      unless defined $soname;

    my ($maj, $min, $pat) = map {; pack 'i!', $_ } (0, 0, 0);
    $zmq_vers->(
      map {; unpack 'L!', pack 'P', $_ } $maj, $min, $pat
    );
    ($maj, $min, $pat) = map {; unpack 'i!', $_ } $maj, $min, $pat;
    unless ($maj >= 4) {
      my $vstr = join '.', $maj, $min, $pat;
      croak "This library requires ZeroMQ 4+ but you only have $vstr"
    }

    $soname
  },
);

has _zmq_errno => (
  lazy        => 1,
  is          => 'ro',
  isa         => Object,
  builder     => sub {
    FFI::Raw->new(
      shift->zmq_soname, zmq_errno => FFI::Raw::int
    )
  },
);

has _zmq_strerr => (
  lazy        => 1,
  is          => 'ro',
  isa         => Object,
  builder     => sub {
    FFI::Raw->new(
      shift->zmq_soname, zmq_strerror => FFI::Raw::str, FFI::Raw::int
    )
  },
);

has _zmq_curve_keypair => (
  lazy        => 1,
  is          => 'ro',
  isa         => Object,
  builder     => sub {
    FFI::Raw->new(
      shift->zmq_soname, zmq_curve_keypair =>
        FFI::Raw::int,  # <- rc
        FFI::Raw::ptr,  # -> pub key ptr
        FFI::Raw::ptr,  # -> sec key ptr
    )
  },
);


sub BUILD {
  my ($self) = @_;
  $self->_read_cert unless $self->ignore_existing;
}

sub _read_cert {
  my ($self) = @_;

  return unless $self->has_secret_file or $self->has_public_file;

  if (!$self->secret_file->exists) {
    if ($self->public_file && $self->public_file->exists) {
      # public_file exists, secret_file does not, do the safe thing and
      # refuse to overwrite existing public_file:
      my $secfile = $self->secret_file . '';
      my $pubfile = $self->public_file . '';
      confess "Found 'public_file' but not 'secret_file'; ",
              "Check your key file paths, remove the 'public_file', ",
              "or specify 'ignore_existing => 1' to overwrite ",
              "(pub: $pubfile) (sec: $secfile)"
    }
    return
  }
  
  if ($self->public_file && !$self->public_file->exists) {
    warn "Found 'secret_file' but not 'public_file': ".$self->public_file,
         " -- you may want to call a commit()"
  }

  if (!$self->public_file) {
    warn "No 'public_file' specified; commit() will fail!"
  }

  my $secdata = decode_zpl( $self->secret_file->slurp );
  
  $secdata->{curve} ||= +{};
  my $pubkey = $secdata->{curve}->{'public-key'};
  my $seckey = $secdata->{curve}->{'secret-key'};
  unless ($pubkey && $seckey) {
    confess "Invalid ZCert; ".
      "expected 'curve' section containing 'public-key' & 'secret-key'"
  }
  $self->_set_public_key_z85($pubkey);
  $self->_set_secret_key_z85($seckey);
  $self->metadata->set(%{ $secdata->{metadata} }) 
    if $secdata->{metadata} and keys %{ $secdata->{metadata} };
}

sub generate_keypair {
  my ($self) = blessed $_[0] ? $_[0] : $_[0]->new;

  my ($pub, $sec) = (
    FFI::Raw::memptr(41), FFI::Raw::memptr(41)
  );

  if ( $self->_zmq_curve_keypair->($pub, $sec) == -1 ) {
    my $errno  = $self->_zmq_errno->();
    my $errstr = $self->_zmq_strerr->($errno);
    confess "libzmq zmq_curve_keypair failed: $errstr ($errno)"
  }

  hash(
    public => $pub->tostr,
    secret => $sec->tostr,
  )->inflate
}

sub export_zcert {
  my ($self) = @_;

  my $data = +{
    curve    => +{ 'public-key' => $self->public_key_z85 },
    metadata => $self->metadata,
  };
  my $public = encode_zpl $data;
  $data->{curve}->{'secret-key'} = $self->secret_key_z85;
  my $secret = encode_zpl $data;

  hash(
    public => $public,
    secret => $secret,
  )->inflate
}

sub commit {
  my ($self) = @_;

  confess "commit() called but no public_file / secret_file set"
    unless $self->has_public_file
      and  $self->public_file
      and  $self->secret_file;

  my $zcert = $self->export_zcert;
  
  $self->public_file->spew( $zcert->public );
  $self->secret_file->spew( $zcert->secret );
  $self->secret_file->chmod(0600) if $self->adjust_permissions;

  $self
}


print
  qq[<OvrLrdQ> only copy of keys to decrypt inside encrypted duplicity backup\n],
  qq[<Schroedingers_hat> Yo dawg, I herd you liked encryption so I put yo keys],
  qq[ in yo encrypted file so you can decrypt while....damnit.\n]
unless caller; 1;

=pod

=for Pod::Coverage BUILD has_\w+_file

=head1 NAME

Crypt::ZCert - Manage ZeroMQ 4+ ZCert CURVE keys and certificates

=head1 SYNOPSIS

  use Crypt::ZCert;

  my $zcert = Crypt::ZCert->new(
    public_file => "/foo/mycert",
    # Optionally specify a secret file;
    # defaults to "${public_file}_secret":
    secret_file => "/foo/sekrit",
  );

  # Loaded from existing 'secret_file' if present,
  # generated via libzmq's zmq_curve_keypair(3) if not:
  my $pubkey = $zcert->public_key;
  my $seckey = $zcert->secret_key;

  # ... or as the original Z85:
  my $pub_z85 = $zcert->public_key_z85;
  my $sec_z85 = $zcert->secret_key_z85;

  # Alter metadata:
  $zcert->metadata->set(foo => 'bar');

  # Commit certificate to disk
  # (as '/foo/mycert', '/foo/mycert_secret' pair)
  # Without '->new(adjust_permissions => 0)', _secret becomes chmod 0600:
  $zcert->commit;

  # Retrieve a public/secret ZCert file pair (as ZPL) without writing:
  my $certdata = $zcert->export_zcert;
  my $pubdata  = $certdata->public;
  my $secdata  = $certdata->secret;

  # Retrieve a newly-generated key pair (no certificate):
  my $keypair = Crypt::ZCert->new->generate_keypair;
  my $pub_z85 = $keypair->public;
  my $sec_z85 = $keypair->secret;

=head1 DESCRIPTION

A module for managing ZeroMQ "ZCert" certificates and calling
L<zmq_curve_keypair(3)> from L<libzmq|http://www.zeromq.org> to generate CURVE
keys.

=head2 ZCerts

ZCert files are C<ZPL> format (see L<Text::ZPL>) with two subsections,
C<curve> and C<metadata>. The C<curve> section specifies C<public-key> and
C<secret-key> names whose values are C<Z85>-encoded (see L<Convert::Z85>) CURVE
keys.

On disk, the certificate is stored as two files; a L</public_file> (containing
only the public key) and a L</secret_file> (containing both keys).

Also see: L<http://czmq.zeromq.org/manual:zcert>

=head2 ATTRIBUTES

=head3 public_file

The path to the public ZCert.

Coerced to a L<Path::Tiny>.

Predicate: C<has_public_file>

=head3 secret_file

The path to the secret ZCert; defaults to appending '_secret' to
L</public_file>.

Coerced to a L<Path::Tiny>.

Predicate: C<has_secret_file>

=head3 adjust_permissions

If boolean true, C<chmod> will be used to attempt to set the L</secret_file>'s
permissions to C<0600> after writing.

=head3 ignore_existing

If boolean true, any existing L</public_file> / L</secret_file> will not be
read; calling a L</commit> will cause a forcible key regeneration and rewrite
of the existing certificate files.

(Obviously, this should be used with caution.)

=head3 public_key

The public key, as a binary string.

If none is specified at construction-time and no L</secret_file> exists, a new
key pair is generated via L<zmq_curve_keypair(3)> and L</secret_key> is set
appropriately.

=head3 secret_key

The secret key, as a binary string.

If none is specified at construction-time and no L</secret_file> exists, a new
key pair is generated via L<zmq_curve_keypair(3)> and L</public_key> is set
appropriately.

=head3 public_key_z85

The L</public_key>, as a C<Z85>-encoded ASCII string (see L<Convert::Z85>).

=head3 secret_key_z85

The L</secret_key>, as a C<Z85>-encoded ASCII string (see L<Convert::Z85>).

=head3 metadata

  # Get value:
  my $foo = $zcert->metadata->get('foo');

  # Iterate over metadata:
  my $iter = $zcert->metadata->iter;
  while ( my ($key, $val) = $iter->() ) {
    print "$key -> $val\n";
  }

  # Update metadata & write to disk:
  $zcert->metadata->set(foo => 'bar');
  $zcert->commit;

The certificate metadata, as a L<List::Objects::WithUtils::Hash>.

If the object is constructed from an existing L</public_file> /
L</secret_file>, metadata key/value pairs in the loaded file will override
key/value pairs that were previously set in a passed C<metadata> hash.

=head3 zmq_soname

The C<libzmq> dynamic library name; by default, the newest available library
is chosen.

=head2 METHODS

=head3 commit

Write L</public_file> and L</secret_file> to disk.

=head3 export_zcert

Generate and return the current ZCert; the certificate is represented as a
struct-like object with two accessors, B<public> and B<secret>, containing
ZPL-encoded ASCII text:

  my $certdata = $zcert->export_zcert;
  my $public_zpl = $certdata->public;
  my $secret_zpl = $certdata->secret;

=head3 generate_keypair

Generate and return a new key pair via L<zmq_curve_keypair(3)>; if called as
an instance method, the current ZCert object remains unchanged.

The returned key pair is a struct-like object with two accessors, B<public>
and B<secret>:

  my $keypair = $zcert->generate_keypair;
  my $pub_z85 = $keypair->public;
  my $sec_z85 = $keypair->secret;

Can be called as either a class or instance method.

=head1 SEE ALSO

L<Text::ZPL>

L<Convert::Z85>

L<POEx::ZMQ>

L<ZMQ::FFI>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
