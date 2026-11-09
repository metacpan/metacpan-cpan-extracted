package DBIO::Firebird::Type;
# ABSTRACT: Firebird type-system mapping (introspection + DDL directions)

use strict;
use warnings;

our $VERSION = '0.900004';

use Exporter 'import';

our @EXPORT_OK = qw(sql_type_from_rdb ddl_type_from_info render_size is_boolean_type is_binary_type is_numeric_type lob_kind);


# rdb$field_type number -> bare SQL type name (no size/precision; size is
# carried separately in the introspected model). Numbers as the server stores
# them in rdb$fields; the sub_type/charset-dependent ones (7/8/16/26 numeric
# and decimal, 14/37 binary, 261 blob) are resolved in sql_type_from_rdb.
my %RDB_TYPE = (
  7   => 'smallint',
  8   => 'integer',
  9   => 'quad',
  10  => 'float',
  12  => 'date',
  13  => 'time',
  14  => 'char',
  16  => 'bigint',
  23  => 'boolean',
  24  => 'decfloat',
  26  => 'int128',
  27  => 'double precision',
  28  => 'time with time zone',
  29  => 'timestamp with time zone',
  35  => 'timestamp',
  37  => 'varchar',
  40  => 'cstring',
  261 => 'blob',
);

# Exact-number storage types; rdb$field_sub_type 1 = NUMERIC, 2 = DECIMAL,
# 0 = the plain integer type.
my %NUMERIC_STORAGE = map { $_ => 1 } (7, 8, 16, 26);

# rdb$character_set_id of OCTETS: CHAR/VARCHAR columns in it are BINARY/VARBINARY.
my $CHARSET_OCTETS = 1;


sub sql_type_from_rdb {
  my ($type_num, $sub_type, $charset_id) = @_;
  $type_num //= -1;
  $sub_type //= 0;

  if ($NUMERIC_STORAGE{$type_num} && ($sub_type == 1 || $sub_type == 2)) {
    return $sub_type == 1 ? 'numeric' : 'decimal';
  }
  if ($type_num == 261) {
    return $sub_type == 1 ? 'blob sub_type text' : 'blob';
  }
  if (($type_num == 14 || $type_num == 37) && ($charset_id // -1) == $CHARSET_OCTETS) {
    return $type_num == 14 ? 'binary' : 'varbinary';
  }
  return $RDB_TYPE{$type_num} // 'varchar';
}


sub ddl_type_from_info {
  my ($info) = @_;
  my $type = lc($info->{data_type} // 'varchar');
  my $size = $info->{size};
  return 'INTEGER' if $type eq 'integer' || $type eq 'int';
  return 'BIGINT' if $type eq 'bigint';
  return 'SMALLINT' if $type eq 'smallint' || $type eq 'tinyint';
  return 'BIGINT' if $type eq 'bigserial' || $type eq 'serial';
  # the core canon: string without a size is text, with one it is VARCHAR(n)
  return defined $size ? 'VARCHAR' . render_size($size) : 'BLOB SUB_TYPE TEXT' if $type eq 'string';
  return 'VARCHAR' . (render_size($size) || '(255)')
    if $type eq 'varchar' || $type eq 'nvarchar' || $type eq 'character varying';
  return 'CHAR' . (render_size($size) || '(1)') if $type eq 'char' || $type eq 'nchar' || $type eq 'character';
  return 'BINARY' . (render_size($size) || '(1)') if $type eq 'binary';
  return 'VARBINARY' . (render_size($size) || '(255)') if $type eq 'varbinary';
  return 'BLOB' if $type eq 'bytea' || $type eq 'blob';
  return 'BLOB SUB_TYPE TEXT'
    if $type eq 'text' || $type eq 'clob' || $type eq 'long' || $type eq 'mediumtext' || $type eq 'longtext';
  return 'DATE' if $type eq 'date';
  return 'TIMESTAMP' if $type eq 'datetime' || $type eq 'timestamp';
  return 'TIMESTAMP WITH TIME ZONE' if $type eq 'timestamptz';
  return 'DOUBLE PRECISION' if $type eq 'double precision' || $type eq 'double' || $type eq 'float' || $type eq 'real';
  return 'DECIMAL' . (render_size($size) || '(18,6)') if $type eq 'numeric' || $type eq 'decimal';
  return 'BOOLEAN' if is_boolean_type($type);
  return uc($type);
}


sub is_boolean_type {
  my ($data_type) = @_;
  return 0 unless defined $data_type;
  return lc($data_type) =~ /\A(?:boolean|bool)\z/ ? 1 : 0;
}


sub is_binary_type {
  my ($data_type) = @_;
  return 0 unless defined $data_type;
  return ddl_type_from_info({ data_type => $data_type }) =~ /\A(?:BLOB\z|BINARY\b|VARBINARY\b)/ ? 1 : 0;
}


sub is_numeric_type {
  my ($data_type) = @_;
  return 0 unless defined $data_type;
  return ddl_type_from_info({ data_type => $data_type }) =~ /\A(?:SMALLINT|INTEGER|BIGINT|DECIMAL|DOUBLE PRECISION)\b/ ? 1 : 0;
}


sub lob_kind {
  my ($data_type, $size) = @_;
  return undef unless defined $data_type;
  my $ddl = ddl_type_from_info({ data_type => $data_type, size => $size });
  return $ddl eq 'BLOB SUB_TYPE TEXT' ? 'text'
       : $ddl eq 'BLOB'               ? 'binary'
       :                                undef;
}


sub render_size {
  my ($size) = @_;
  return '' unless defined $size;
  return "($size->[0],$size->[1])" if ref $size eq 'ARRAY';
  return "($size)";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::Type - Firebird type-system mapping (introspection + DDL directions)

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Single home for the Firebird type system. Three mappings used to live in three
modules pulling in different directions:

=over 4

=item * L<DBIO::Firebird::Introspect::Columns> mapped C<rdb$field_type> numbers
to SQL type names (the I<introspection> direction).

=item * L<DBIO::Firebird::DDL> mapped DBIO/SQL::Translator C<data_type> values to
Firebird DDL types (the I<deploy> direction).

=item * L<DBIO::Firebird::Diff::Table> rendered C<(size)> suffixes inline.

=back

Centralizing them removes a class of bug: introspection used to fold the size
into the type string (C<"decimal(18,6)">) I<and> set a separate C<size> field,
so C<Diff::Table> emitted the size twice (C<"decimal(18,6)(18,6)">). The
introspection mapping here returns the bare type; size is carried separately in
the model and rendered via L</render_size>.

=head1 METHODS

=head2 sql_type_from_rdb

    my $type = sql_type_from_rdb($field_type, $field_sub_type, $character_set_id);

Maps the C<rdb$fields> triple C<rdb$field_type>, C<rdb$field_sub_type> and
C<rdb$character_set_id> to a bare SQL type name (e.g. C<'integer'>,
C<'numeric'>, C<'varbinary'>). The sub type separates C<numeric> (1) and
C<decimal> (2) from the integer type that stores them, and
C<blob sub_type text> (1) from binary C<blob>; the character set C<OCTETS>
turns C<char>/C<varchar> into C<binary>/C<varbinary>. Unknown types fall back
to C<'varchar'>.

=head2 ddl_type_from_info

    my $ddl_type = ddl_type_from_info($column_info);

Maps a DBIO / L<SQL::Translator> C<column_info> hashref to a concrete Firebird
DDL type string (e.g. C<'INTEGER'>, C<'VARCHAR(255)'>). Size-parameterizable
types (C<varchar>/C<nvarchar>, C<char>/C<nchar>, C<numeric>/C<decimal>) render
C<< $info->{size} >> via L</render_size>, falling back to a sane default only
when C<size> is undef.

The aliases of L<DBIO::Schema::Type> arrive as Firebird has them:
C<character> and C<character varying> keep their C<size> (C<CHAR(n)>,
C<VARCHAR(n)>; the bare keyword used to be written without it, and C<CHAR>
alone is C<CHAR(1)>), C<binary>/C<varbinary> likewise, C<double> is C<DOUBLE
PRECISION> (C<DOUBLE> alone is a syntax error), C<real> likewise, as the core canon has it (not
Firebird's own C<REAL>, a 4-byte C<FLOAT>), C<tinyint> is C<SMALLINT>,
C<bool> C<BOOLEAN>, C<string> is C<VARCHAR(n)> with a C<size> and the text type
C<BLOB SUB_TYPE TEXT> without one (in the core canon a string is text),
C<mediumtext>/C<longtext> C<BLOB SUB_TYPE TEXT>, C<timestamptz> C<TIMESTAMP WITH TIME
ZONE> (a column of that type is refused by L<DBIO::Firebird::DDL/install_ddl>,
which the DBD cannot read or write). A name that is none of these
is written upper-cased and the server judges it. C<bit> and C<enum> are not
mapped here: L<DBIO::Firebird::DDL/install_ddl> refuses them.

C<boolean> becomes C<BOOLEAN>, the native type of Firebird 3 and later. Firebird
3 is the minimum version this driver supports; Firebird 2.5, which has no
BOOLEAN, is not supported. The rules of the Diff against a live
server are measured on Firebird 5.0.4 only.

=head2 is_boolean_type

    is_boolean_type($data_type);

True when a column of this C<data_type> is written as C<BOOLEAN> (C<boolean>
and its alias C<bool>, any case). The one question the guards of the driver
ask (the default literal in L<DBIO::Firebird::DDL>, the translation
of C<'true'> / C<'false'> in L<DBIO::Firebird::Storage::InterBase>): they ask
about the mapped type, not about one spelling of it, so an alias cannot walk
past them.

=head2 is_binary_type

    is_binary_type($data_type);

True when a column of this C<data_type> holds bytes, not text: C<blob>,
C<bytea>, C<binary> and C<varbinary> (the types C<ddl_type_from_info> writes as
C<BLOB>, C<BINARY(n)> and C<VARBINARY(n)>). The storage does not flag the values
of such a column as UTF-8 text.

=head2 is_numeric_type

    is_numeric_type($data_type);

True when a column of this C<data_type> is written as an integer, a
C<NUMERIC> / C<DECIMAL> or a floating point type (C<integer>, C<int>,
C<smallint>, C<bigint>, C<tinyint>, C<serial>, C<numeric>, C<decimal>,
C<float>, C<double>, C<real>, ...). The storage refuses a bound value that is no
number for such a column.

=head2 lob_kind

    lob_kind($data_type, $size);   # 'text', 'binary' or undef

C<'text'> for a column written as C<BLOB SUB_TYPE TEXT> (C<text>, C<clob>,
C<mediumtext>, C<longtext>, a C<string> without a size), C<'binary'> for a
C<BLOB> (C<blob>, C<bytea>), undef for everything else. The comparison of a
BLOB with a bound value is written for these two kinds.

=head2 render_size

    my $suffix = render_size($size);   # "(255)", "(10,2)", or ""

Renders a model C<size> field as a SQL size suffix. A scalar yields C<"(n)">,
an arrayref yields C<"(p,s)">, and C<undef> yields the empty string.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
