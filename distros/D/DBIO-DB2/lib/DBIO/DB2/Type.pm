package DBIO::DB2::Type;
# ABSTRACT: DB2 column type utilities

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp ();
use DBIO::Exception ();
use Exporter 'import';

our @EXPORT_OK = qw(_db2_column_type _db2_mapped_type);

# Types Db2 writes without a length: INTEGER(4), DATE(4) or XML(0) is a syntax
# error (SQL0104N), whatever size came with the column. A size does come with
# every one of them from the catalog -- SYSCAT.COLUMNS.LENGTH is the storage
# length (SMALLINT 2, INTEGER 4, BIGINT 8, REAL 4, DOUBLE 8, DATE 4, TIME 3,
# XML 0) and DBIO::DB2::Introspect::Columns carries it as the column's size --
# and one can come from a result class written for another engine
# (data_type => 'integer', size => 11). Keyed by the mapped name: the catalog's
# DOUBLE arrives here as DOUBLE PRECISION; the catalog's BOOLEAN carries a LENGTH
# of 1 and BOOLEAN(1) is SQL0104N. Measured on Db2 12.1.5 (karr k41).
my %NO_LENGTH = map { $_ => 1 } (
  'SMALLINT', 'INTEGER', 'BIGINT', 'REAL', 'DOUBLE PRECISION',
  'DATE', 'TIME', 'XML', 'BOOLEAN',
);

# Types Db2 refuses without a length (SQL0604N), keyed by the mapped name:
# varchar and json arrive as VARCHAR. No length is guessed for them (karr k45);
# text without a length is a CLOB (karr k57). CHAR (= CHAR(1)), BINARY (= BINARY(1)), BLOB and CLOB are valid bare and not listed.
my %NEEDS_LENGTH = map { $_ => 1 } ('VARCHAR', 'VARBINARY');

# Byte limits of the binary types, measured on Db2 12.1.5 (karr k55): BINARY(n) takes
# n <= 255, VARBINARY(n) n <= 32672; above, SQL0604N. A binary above the first is
# written as the VARBINARY it can only be; above the second there is nothing to map to.
my $BINARY_MAX    = 255;
my $VARBINARY_MAX = 32672;

# Db2 has no INTERVAL, ENUM or BIT type (SQL0204N / SQL0104N); there is nothing
# to map them to (karr k57: enum and bit were written as they came and left to
# the server to refuse).
my %UNSUPPORTED = map { $_ => 1 } ('INTERVAL', 'ENUM', 'BIT');

my %type_map = (
  tinyint   => 'SMALLINT',
  smallint  => 'SMALLINT',
  int       => 'INTEGER',
  integer   => 'INTEGER',
  bigint    => 'BIGINT',
  serial    => 'INTEGER',
  bigserial => 'BIGINT',
  real      => 'REAL',
  float     => 'FLOAT',
  double    => 'DOUBLE PRECISION',
  'double precision' => 'DOUBLE PRECISION',
  numeric   => 'DECIMAL',
  decimal   => 'DECIMAL',
  decfloat  => 'DECFLOAT',
  text      => 'VARCHAR',
  varchar   => 'VARCHAR',
  char      => 'CHAR',
  clob      => 'CLOB',
  boolean   => 'BOOLEAN',
  bool      => 'BOOLEAN',
  blob      => 'BLOB',
  binary    => 'BINARY',
  varbinary => 'VARBINARY',
  date      => 'DATE',
  time      => 'TIME',
  datetime  => 'TIMESTAMP',
  timestamp => 'TIMESTAMP',
  timestamptz => 'TIMESTAMP',
  'timestamp with time zone' => 'TIMESTAMP',
  interval  => 'INTERVAL',
  uuid      => 'CHAR(16)',
  json      => 'VARCHAR',
);

# The name a data_type maps to, with no size and no refusal. For callers that
# only classify a type (the character-type test of DBIO::DB2::DDL).
sub _db2_mapped_type {
  my ($type) = @_;
  $type //= 'VARCHAR';
  return $type if $type =~ /\(.+\)$/;
  return $type_map{ lc $type } // uc $type;
}

# $column (optional, third argument) only names the column in a refusal.
sub _db2_column_type {
  my ($info, $size, $column) = @_;

  # Support both hashref form (DDL.pm) and ($type, $size) form (Diff modules)
  if (ref $info eq 'HASH') {
    $size = $info->{size};
    $info = $info->{data_type};
  }

  my $type = $info // 'VARCHAR';

  return $type if $type =~ /\(.+\)$/;


  # A size of more than one part comes as an array reference (the core form:
  # numeric(10,2) is size => [10, 2]) and is written with a comma.
  $size = join ',', @$size if ref $size eq 'ARRAY';

  my $mapped = $type_map{ lc $type } // uc $type;

  # text without a size is the type that holds a string of any length, a CLOB
  # (karr k57, maintainer decision); nothing is guessed, there is no bound to
  # guess. With a size it stays a VARCHAR(n) below.
  return 'CLOB' if lc($type) eq 'text' && !(defined $size && length $size);

  my $where = defined $column ? " (column $column)" : '';
  # A refusal is a DBIO::Exception (the convention of DBIO::Test::Conformance):
  # the driver's decision, thrown before the server is asked.
  DBIO::Exception->throw("Db2 has no $type type$where; it is refused, there is nothing to map it to")
    if $UNSUPPORTED{$mapped};
  DBIO::Exception->throw("Type $type$where needs a size: Db2 refuses $mapped without a length (SQL0604N) and none is guessed")
    if $NEEDS_LENGTH{$mapped} && !(defined $size && length $size);

  return $mapped unless defined $size && length $size;
  return $mapped if $NO_LENGTH{$mapped};

  if (($mapped eq 'BINARY' || $mapped eq 'VARBINARY') && $size =~ /\A\d+\z/) {
    Carp::croak("Type $type$where of size $size is beyond what Db2 holds: VARBINARY takes at most $VARBINARY_MAX bytes "
      . "(SQL0604N); use a blob for more")
      if $size > $VARBINARY_MAX;
    return "VARBINARY($size)" if $mapped eq 'BINARY' && $size > $BINARY_MAX;
  }
  return "$mapped($size)";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Type - DB2 column type utilities

=head1 VERSION

version 0.900004

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
