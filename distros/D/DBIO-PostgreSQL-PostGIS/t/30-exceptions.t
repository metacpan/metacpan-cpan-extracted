use strict;
use warnings;
use Test::More;

# t/30-exceptions.t — DBIO::PostgreSQL::PostGIS routes error throws through
# the DBIO::Exception taxonomy (CurtisPoe review #5, F21). Former croak-only
# paths now produce DBIO::Exception objects catchable with
#   $@->isa('DBIO::Exception')
# and preserve the original message text.

use Scalar::Util ();
use DBIO::Exception;
use DBIO::PostgreSQL::PostGIS;
use DBIO::PostgreSQL::PostGIS::Geometry;
use DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder;

my $G = 'DBIO::PostgreSQL::PostGIS::Geometry';
my $D = 'DBIO::PostgreSQL::PostGIS::Codec::WKB::Decoder';

# --- helpers ------------------------------------------------------------

# Trigger $code, return $@ (the thrown object) or undef if no exception.
sub thrown {
  my ($code) = @_;
  my $err;
  eval { $code->(); 1 } or $err = $@;
  return $err;
}

# Assert $err is a DBIO::Exception object and its stringification matches $re.
sub is_dbio_exception {
  my ($err, $re, $name) = @_;
  ok(Scalar::Util::blessed($err) && $err->isa('DBIO::Exception'),
    "$name throws a DBIO::Exception object")
    or diag 'got: ' . (defined $err ? $err : '(no exception)');
  like("$err", $re, "$name preserves the message text");
}

# --- Geometry.pm: 4 former croak sites ----------------------------------

subtest 'from_wkt with undef input' => sub {
  is_dbio_exception(
    thrown(sub { $G->from_wkt(undef) }),
    qr/from_wkt requires a WKT string/,
    'from_wkt(undef)',
  );
};

subtest 'from_ewkt with undef input' => sub {
  is_dbio_exception(
    thrown(sub { $G->from_ewkt(undef) }),
    qr/from_ewkt requires an EWKT string/,
    'from_ewkt(undef)',
  );
};

subtest 'from_geojson with missing type' => sub {
  is_dbio_exception(
    thrown(sub { $G->from_geojson({ coordinates => [0, 0] }) }),
    qr/from_geojson: missing 'type'/,
    'from_geojson(missing type)',
  );
};

subtest 'from_geojson with unsupported type' => sub {
  is_dbio_exception(
    thrown(sub { $G->from_geojson({ type => 'FeatureCollection', coordinates => [] }) }),
    qr/from_geojson: unsupported type 'FeatureCollection'/,
    'from_geojson(unsupported type)',
  );
};

# --- Codec/WKB/Decoder.pm: 3 former croak sites ------------------------

subtest 'decode_hex: empty input' => sub {
  is_dbio_exception(
    thrown(sub { $D->decode_hex('') }),
    qr/decode_hex: empty input/,
    'decode_hex("")',
  );
};

subtest 'decode_hex: invalid byte_order' => sub {
  # byte_order byte = 0x02 is not 0 or 1
  my $hex = unpack('H*', pack('C', 0x02));
  is_dbio_exception(
    thrown(sub { $D->decode_hex($hex) }),
    qr/decode_hex: invalid byte_order/,
    'decode_hex(bad byte_order)',
  );
};

subtest 'decode_hex: underrun' => sub {
  # 1 byte (byte_order=1) is too short to read a uint32 type field -> underrun
  my $hex = unpack('H*', pack('C', 0x01));
  is_dbio_exception(
    thrown(sub { $D->decode_hex($hex) }),
    qr/decode_hex: underrun at pos 1/,
    'decode_hex(underrun)',
  );
};

# --- Storage: _ensure_postgis_extension fail-fast ----------------------
#
# A small fake storage subclass overrides dbh_do to invoke the code ref
# with a fake dbh whose selectrow_array consults an in-memory response
# table. No real database is required.

{
  package _PostgisExt::FakeDbh;
  sub new {
    my ($class, %r) = @_;
    return bless { responses => { %r } }, $class;
  }
  sub selectrow_array {
    my ($self, $sql) = @_;
    if ($sql =~ /pg_extension/) {
      return $self->{responses}{ext_present} ? (1) : ();
    }
    if ($sql =~ /current_database/) {
      my $n = $self->{responses}{dbname};
      return defined $n ? ($n) : ();
    }
    return ();
  }
}

{
  # DBIO::PostgreSQL::PostGIS::Storage is now a plain storage LAYER (core #70):
  # it no longer subclasses a driver storage, so it carries neither `new` nor
  # `throw_exception`. Mirror the composed reality (layer over driver storage)
  # by inheriting the layer first, then the real PostgreSQL driver storage --
  # exactly the MRO DBIO::Storage::Composed synthesises. The layer's
  # `_ensure_postgis_extension` resolves `throw_exception`/`dbh_do` through the
  # driver base at runtime, as it does under composition.
  package _PostgisExt::TestStorage;
  use base qw( DBIO::PostgreSQL::PostGIS::Storage DBIO::PostgreSQL::Storage );
  use mro 'c3';

  sub dbh_do {
    my ($self, $code) = @_;
    return $code->(undef, $self->{_fake_dbh});
  }
  sub _set_responses {
    my ($self, %r) = @_;
    $self->{_fake_dbh} = _PostgisExt::FakeDbh->new(%r);
    return $self;
  }
}

sub make_storage {
  my (%r) = @_;
  return _PostgisExt::TestStorage->new->_set_responses(%r);
}

subtest 'extension installed: no exception' => sub {
  my $storage = make_storage(ext_present => 1, dbname => 'gisdb');
  my $err;
  eval { $storage->_ensure_postgis_extension; 1 } or $err = $@;
  ok(!$err, '_ensure_postgis_extension is a no-op when postgis is installed')
    or diag "got: $err";
};

subtest 'extension missing: throws DBIO::Exception with clear message' => sub {
  my $storage = make_storage(ext_present => 0, dbname => 'nope');
  is_dbio_exception(
    thrown(sub { $storage->_ensure_postgis_extension }),
    qr/PostGIS extension is not installed on database 'nope'.*DBIO::PostgreSQL::PostGIS/s,
    '_ensure_postgis_extension when postgis is missing',
  );
};

subtest 'extension missing, dbname undef: message still names the extension' => sub {
  my $storage = make_storage(ext_present => 0, dbname => undef);
  is_dbio_exception(
    thrown(sub { $storage->_ensure_postgis_extension }),
    qr/PostGIS extension is not installed/,
    '_ensure_postgis_extension (no dbname)',
  );
};

done_testing;
