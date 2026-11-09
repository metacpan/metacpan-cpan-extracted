package DBIO::Informix::Types;
# ABSTRACT: Canonical Informix type vocabulary

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';
our @EXPORT_OK = qw(logical_for_coltype size_for_coltype ddl_type qualifier_for_coltype lob_kind is_numeric_type);


# Informix coltype (mod 256) -> logical type name. Measured against the
# syscolumns of Informix 15.0.1 (karr k20); 10 (DATETIME) and 41 (opaque)
# are refined in logical_for_coltype.
my %LOGICAL_FOR_COLTYPE = (
  0  => 'char',
  1  => 'smallint',
  2  => 'integer',
  3  => 'float',
  4  => 'smallfloat',
  5  => 'decimal',
  6  => 'serial',
  7  => 'date',
  8  => 'money',
  10 => 'datetime',
  11 => 'bytea',
  12 => 'text',
  13 => 'varchar',
  14 => 'interval',
  15 => 'nchar',
  16 => 'nvarchar',
  17 => 'int8',
  18 => 'serial8',
  19 => 'set',
  20 => 'multiset',
  21 => 'list',
  40 => 'lvarchar',
  45 => 'boolean',
  52 => 'bigint',
  53 => 'bigserial',
);

# syscolumns.extended_id of the fixed-length opaque types (coltype 41).
my %OPAQUE_FOR_EXTENDED_ID = (
  5  => 'boolean',
  10 => 'blob',
  11 => 'clob',
);

# DATETIME qualifier codes, as the nibbles of collength.
my %DT_QUALIFIER = (
  0 => 'year', 2 => 'month', 4 => 'day', 6 => 'hour', 8 => 'minute',
  10 => 'second', 11 => 'fraction(1)', 12 => 'fraction(2)',
  13 => 'fraction(3)', 14 => 'fraction(4)', 15 => 'fraction(5)',
);

# Logical type -> fixed (unsized) Informix SQL type string.
my %DDL_FIXED = (
  integer            => 'INTEGER',
  int                => 'INTEGER',
  tinyint            => 'SMALLINT',
  bool               => 'BOOLEAN',
  double             => 'DOUBLE PRECISION',
  float              => 'DOUBLE PRECISION',
  timestamp          => 'DATETIME YEAR TO FRACTION(5)',
  datetime           => 'DATETIME YEAR TO FRACTION(5)',
  blob               => 'BYTE',
  binary             => 'BYTE',
  varbinary          => 'BYTE',
  mediumtext         => 'TEXT',
  longtext           => 'TEXT',
  clob               => 'TEXT',
  bigint             => 'BIGINT',
  smallint           => 'SMALLINT',
  'double precision' => 'DOUBLE PRECISION',
  real               => 'REAL',
  date               => 'DATE',
  text               => 'TEXT',
  bytea              => 'BYTE',
);

# Logical type -> sized Informix SQL type. Rendered as TYPE(size), except
# decimal/numeric which take a [precision, scale] arrayref and render as
# TYPE(precision,scale).
my %DDL_SIZED = (
  varchar  => 'VARCHAR',
  'character varying' => 'VARCHAR',
  character => 'CHAR',
  string   => 'VARCHAR',
  nvarchar => 'VARCHAR',
  char     => 'CHAR',
  nchar    => 'CHAR',
  lvarchar => 'LVARCHAR',
  decimal  => 'DECIMAL',
  money    => 'MONEY',
  numeric  => 'NUMERIC',
);


sub logical_for_coltype {
  my ($coltype, $collength, $extended_id) = @_;

  if (($coltype == 10 || $coltype == 14) && defined $collength) {
    my $q = qualifier_for_coltype($coltype, $collength);
    return ($coltype == 10 ? 'datetime ' : 'interval ') . lc $q if defined $q;
  }
  if ($coltype == 41) {
    return $OPAQUE_FOR_EXTENDED_ID{ $extended_id // 0 } // 'unknown';
  }
  return $LOGICAL_FOR_COLTYPE{$coltype} // 'unknown';
}



sub qualifier_for_coltype {
  my ($coltype, $collength) = @_;
  return undef unless defined $collength && ($coltype == 10 || $coltype == 14);

  my ($fc, $lc) = (($collength >> 4) & 15, $collength & 15);
  my ($first, $last) = @DT_QUALIFIER{ $fc, $lc };
  return undef unless defined $first && defined $last;

  if ($coltype == 14) {
    my $digits = $collength >> 8;
    # the digits of the fields after the first, from the one after $fc to $lc
    my $rest = 0;
    for my $code (sort { $a <=> $b } grep { $_ > $fc && $_ <= $lc } keys %DT_QUALIFIER) {
      $rest += $code >= 11 ? $code - 10 : 2;
    }
    my $lead = $digits - $rest;
    $first =~ s/\A(\w+)/$1($lead)/ if $lead > 0 && $fc < 11;
  }
  return uc "$first TO $last";
}


sub size_for_coltype {
  my ($coltype, $collength) = @_;
  return undef unless defined $collength;

  return $collength & 255 if $coltype == 13 || $coltype == 16;
  return $collength       if $coltype == 0 || $coltype == 15 || $coltype == 40;
  if ($coltype == 5 || $coltype == 8) {
    my ($p, $s) = ($collength >> 8, $collength & 255);
    return $s == 255 ? [ $p ] : [ $p, $s ];
  }
  return undef;
}


sub ddl_type {
  my ($logical, $size) = @_;
  my $lc = lc($logical // 'varchar');

  # string without a size is a TEXT; a VARCHAR holds 255 characters at most,
  # a longer one is an LVARCHAR (up to 32739)
  return 'TEXT' if $lc eq 'string' && !defined $size;
  if (($lc eq 'varchar' || $lc eq 'nvarchar' || $lc eq 'string' || $lc eq 'character varying')
      && defined $size && !ref $size && $size > 255) {
    return sprintf 'LVARCHAR(%d)', $size;
  }

  if (exists $DDL_SIZED{$lc}) {
    return sprintf '%s(%s)', $DDL_SIZED{$lc}, join ',', @$size
      if ref $size eq 'ARRAY';
    return sprintf '%s(%d)', $DDL_SIZED{$lc}, ($size // 255);
  }

  return $DDL_FIXED{$lc} if exists $DDL_FIXED{$lc};

  return $logical // 'VARCHAR';
}


sub lob_kind {
  my ($data_type, $size) = @_;
  return undef unless defined $data_type;
  my $lc = lc $data_type;
  return 'text'   if $lc =~ /\A(?:text|clob|mediumtext|longtext)\z/ or ($lc eq 'string' and !defined $size);
  return 'binary' if $lc =~ /\A(?:blob|bytea|binary|varbinary|byte)\z/;
  return undef;
}


sub is_numeric_type {
  my ($data_type) = @_;
  return 0 unless defined $data_type;
  return lc($data_type) =~ /\A(?:integer|int|smallint|tinyint|bigint|int8|serial|serial8|bigserial|decimal|numeric|money|float|double|double precision|real|smallfloat)\z/ ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::Types - Canonical Informix type vocabulary

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Informix::Types> is the single source of truth for the Informix type
vocabulary. It maps both ends of the introspect/deploy round-trip:

=over 4

=item * the Informix C<syscolumns.coltype> number (already taken modulo 256)
to a B<logical type name> (C<logical_for_coltype>, with C<size_for_coltype> for the size), used by
L<DBIO::Informix::Introspect::Columns>;

=item * a logical type name to the Informix B<SQL type string> emitted in
DDL (C<ddl_type>), used by L<DBIO::Informix::DDL>.

=back

The logical type name is the shared contract between the two sides. Keeping
both mappings here means a new type is added in one place, not two.

=head1 METHODS

=head2 logical_for_coltype

    my $logical = logical_for_coltype($coltype, $collength, $extended_id);

Maps an Informix C<coltype> number (taken modulo 256) to a logical type
name. A DATETIME comes out with its qualifiers decoded from C<$collength>
(C<datetime year to second>); a fixed-length opaque type (coltype 41) is told
apart by C<$extended_id> (C<boolean>, C<blob>, C<clob>). Returns
C<'unknown'> for an unmapped coltype.

=head2 qualifier_for_coltype

    my $q = qualifier_for_coltype($coltype, $collength);   # 'YEAR TO DAY'

The qualifier of a DATETIME (C<$coltype> 10) or INTERVAL (14) column, decoded
from C<$collength>, as the SQL writes it after the type or after a literal
(C<DATETIME(2026-01-01) YEAR TO DAY>). The first field of an INTERVAL carries
its leading precision (C<DAY(3) TO DAY>, C<YEAR(4) TO MONTH>): C<collength>
holds the number of digits of the whole value in its high byte, the later
fields are two digits each and a fraction its own. Undef for another type or
a code it does not know.

=head2 size_for_coltype

    my $size = size_for_coltype($coltype, $collength);

The C<size> of the introspected model from C<syscolumns.collength>, or
undef for a type without one: the maximum of a C<varchar>/C<nvarchar>
(collength is C<min * 256 + max>), the length of a C<char>, C<nchar> or
C<lvarchar>, and C<[precision, scale]> of a C<decimal> or C<money>
(collength is C<precision * 256 + scale>; scale 255 is a floating
C<decimal(p)> and gives C<[precision]>).

=head2 ddl_type

    my $sql_type = ddl_type($logical, $size);

Maps a logical type name to the Informix SQL type string for DDL. Sized
types (C<varchar>, C<char>, C<lvarchar>, ...) render as C<TYPE($size)>,
defaulting to 255 when no size is given. C<decimal>/C<numeric> take
C<$size> as a C<[precision, scale]> arrayref and render as
C<TYPE(precision,scale)>. Unknown logical types pass through unchanged
(preserving their original case).

=head2 lob_kind

    lob_kind($data_type, $size);   # 'text', 'binary' or undef

C<'text'> for a column written as C<TEXT> (C<text>, C<clob>, C<mediumtext>,
C<longtext>, a C<string> without a size), C<'binary'> for a C<BYTE> (C<blob>,
C<bytea>, C<binary>, C<varbinary>, C<byte>), undef for everything else. Informix
takes neither of the two in a comparison (-615), and a parameter for them is
bound with an explicit type (L<DBIO::Informix::Storage/bind_attribute_by_data_type>).

=head2 is_numeric_type

    is_numeric_type($data_type);

True when a column of this C<data_type> holds a number (the integer types,
C<serial>, C<decimal>, C<numeric>, C<money>, the floating point types). The
storage refuses a bound value that is no number for such a column.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
