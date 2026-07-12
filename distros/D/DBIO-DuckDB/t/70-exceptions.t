#!/usr/bin/env perl
# t/70-exceptions.t — DBIO::DuckDB::Storage routes errors through the
# DBIO::Exception taxonomy (throw_exception), not plain croak. Former
# croak sites must now throw a DBIO::Exception object catchable with
# $e->isa('DBIO::Exception').

use strict;
use warnings;
use Test::More;
use Scalar::Util ();
use DBIO::DuckDB::Test;

my $schema  = DBIO::DuckDB::Test->init_schema(no_populate => 1);
my $storage = $schema->storage;

# Trigger $code, return the thrown error ($@) or undef if none.
sub thrown {
  my ($code) = @_;
  my $err;
  eval { $code->(); 1 } or $err = $@;
  return $err;
}

# Assert $err is a DBIO::Exception object whose message matches $re.
sub is_dbio_exception {
  my ($err, $re, $name) = @_;
  ok Scalar::Util::blessed($err) && $err->isa('DBIO::Exception'),
    "$name throws a DBIO::Exception object"
    or diag "got: " . (defined $err ? $err : '(no exception)');
  like "$err", $re, "$name preserves the message text";
}

# --- argument / usage error -------------------------------------------

is_dbio_exception(
  thrown(sub { $storage->duckdb_appender() }),
  qr/Usage: \$storage->duckdb_appender/,
  'duckdb_appender without table',
);

is_dbio_exception(
  thrown(sub { $storage->duckdb_read_csv() }),
  qr/Usage: \$storage->duckdb_read_csv/,
  'duckdb_read_csv without path',
);

# --- invalid-identifier validation ------------------------------------

is_dbio_exception(
  thrown(sub { $storage->duckdb_install_extension('not a name!') }),
  qr/invalid extension name/,
  'duckdb_install_extension with invalid name',
);

is_dbio_exception(
  thrown(sub { $storage->quack_attach('quack:localhost:9500', as => '1invalid') }),
  qr/invalid catalog alias/,
  'quack_attach with invalid alias',
);

# --- quack address validation -----------------------------------------

is_dbio_exception(
  thrown(sub { $storage->quack_attach('notquack:localhost', as => 'remote') }),
  qr/must start with 'quack:'/,
  'quack_attach with non-quack address',
);

done_testing;
