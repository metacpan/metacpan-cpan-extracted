package DBIO::Firebird::Type;
# ABSTRACT: Firebird type-system mapping (introspection + DDL directions)

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(sql_type_from_rdb ddl_type_from_info render_size);


# rdb$field_type number -> bare SQL type name (no size/precision; size is
# carried separately in the introspected model). $sub_type is accepted for
# forward compatibility (blob text vs binary distinction) but not yet used.
my %RDB_TYPE = (
  7   => 'smallint',
  8   => 'integer',
  9   => 'bigint',
  10  => 'float',
  12  => 'date',
  13  => 'time',
  14  => 'timestamp',
  16  => 'decimal',
  21  => 'quad',
  27  => 'double precision',
  35  => 'timestamp',           # legacy
  37  => 'varchar',
  40  => 'cstring',
  261 => 'blob sub_type text',
  270 => 'blob',
);


sub sql_type_from_rdb {
  my ($type_num, $sub_type) = @_;
  return $RDB_TYPE{$type_num} // 'varchar';
}


sub ddl_type_from_info {
  my ($info) = @_;
  my $type = lc($info->{data_type} // 'varchar');
  return 'INTEGER' if $type eq 'integer' || $type eq 'bigint' || $type eq 'smallint';
  return 'BIGINT' if $type eq 'bigserial' || $type eq 'serial';
  return 'VARCHAR(255)' if $type eq 'varchar' || $type eq 'nvarchar';
  return 'CHAR(1)' if $type eq 'char' || $type eq 'nchar';
  return 'BLOB' if $type eq 'bytea' || $type eq 'blob';
  return 'BLOB SUB_TYPE TEXT' if $type eq 'text' || $type eq 'clob' || $type eq 'long';
  return 'DATE' if $type eq 'date' || $type eq 'datetime' || $type eq 'timestamp';
  return 'DOUBLE PRECISION' if $type eq 'double precision' || $type eq 'float';
  return 'DECIMAL(18,6)' if $type eq 'numeric' || $type eq 'decimal';
  return 'SMALLINT' if $type eq 'boolean';
  return uc($type);
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

version 0.900000

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

=func sql_type_from_rdb

    my $type = sql_type_from_rdb($field_type, $field_sub_type);

Maps an C<rdb$field_type> number to a bare SQL type name (e.g. C<'integer'>,
C<'decimal'>). Unknown types fall back to C<'varchar'>.

=func ddl_type_from_info

    my $ddl_type = ddl_type_from_info($column_info);

Maps a DBIO / L<SQL::Translator> C<column_info> hashref to a concrete Firebird
DDL type string (e.g. C<'INTEGER'>, C<'VARCHAR(255)'>).

=func render_size

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
