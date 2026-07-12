package DBIO::Sybase::DDL;
# ABSTRACT: Generate Sybase ASE DDL from DBIO Result classes

use strict;
use warnings;

use Exporter 'import';
use DBIO::SQL::Util qw(_quote_ident);

our @EXPORT_OK = qw(sybase_column_type sybase_default_clause);



sub install_ddl {
  my ($class, $schema) = @_;
  my @stmts;
  my @view_stmts;
  my %seen_table;
  my %seen_view;

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    my $result_class = $source->result_class;
    my $table_name = $source->name;

    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = ref $table_name eq 'SCALAR' ? $$table_name : $table_name;
      next if ref $vname || $seen_view{$vname}++;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      push @view_stmts, sprintf 'CREATE VIEW %s AS %s;', _quote_ident($vname), $def;
      next;
    }

    # A scalar-ref name is either a literal table name (\'cd', emitted
    # unquoted) or an inline subquery source; deref the former, skip the latter.
    if (ref $table_name eq 'SCALAR') {
      $table_name = $$table_name;
      next if $table_name =~ /\s|\(/;
    }
    next if ref $table_name;

    # Several result sources can map to one physical table; emit it once.
    next if $seen_table{$table_name}++;

    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = sybase_column_type($info->{data_type});
      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;

      if ($info->{is_auto_increment}) {
        $def .= ' IDENTITY';  # Sybase autoincrement
      }

      $def .= ' NOT NULL' if defined $info->{is_nullable} && !$info->{is_nullable};

      $def .= sybase_default_clause($info->{default_value})
        unless $info->{is_auto_increment};

      push @col_defs, $def;
    }

    # Primary key constraint
    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _quote_ident($_) } @pk_cols);
    }

    my $qualified = _quote_ident($table_name);
    my $sql = sprintf "CREATE TABLE %s (\n%s\n);", $qualified, join(",\n", @col_defs);
    push @stmts, $sql;

    # Unique indexes (Sybase emits these as separate CREATE INDEX)
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      if ($info->{is_unique} || $info->{is_single_unique_key}) {
        push @stmts, sprintf 'CREATE UNIQUE INDEX %s ON %s (%s);',
          _quote_ident("${table_name}_${col_name}_idx"),
          $qualified,
          _quote_ident($col_name);
      }
    }
  }

  return join "

", @stmts, @view_stmts;
}


sub sybase_column_type {
  my ($data_type) = @_;
  my $type = lc($data_type // 'varchar');

  # Integer types
  return 'INT' if $type eq 'integer' || $type eq 'bigint';
  return 'SMALLINT' if $type eq 'smallint' || $type eq 'tinyint';
  return 'BIGINT' if $type eq 'bigserial' || $type eq 'serial';

  # Character types
  return 'VARCHAR(255)' if $type eq 'varchar' || $type eq 'nvarchar';
  return 'CHAR(1)' if $type eq 'char' || $type eq 'nchar';
  return 'TEXT' if $type eq 'text' || $type eq 'long';

  # Date/time types
  return 'DATETIME' if $type eq 'date' || $type eq 'timestamp' || $type eq 'datetime';
  return 'SMALLDATETIME' if $type eq 'smalldatetime';

  # Binary types
  return 'IMAGE' if $type eq 'bytea' || $type eq 'blob';
  return 'TEXT' if $type eq 'clob';

  # Numeric types
  return 'NUMERIC(18,6)' if $type eq 'numeric' || $type eq 'decimal';
  return 'FLOAT' if $type eq 'float' || $type eq 'real';
  return 'DOUBLE PRECISION' if $type eq 'double precision';

  # Boolean — Sybase has bit
  return 'BIT' if $type eq 'boolean';

  # Pass through unknown types as-is (uppercase)
  return uc($type);
}


sub sybase_default_clause {
  my ($dv) = @_;
  return '' unless defined $dv;
  return " DEFAULT $$dv" if ref $dv eq 'SCALAR';
  return '' if $dv eq 'null';
  return " DEFAULT '$dv'";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::DDL - Generate Sybase ASE DDL from DBIO Result classes

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::Sybase::DDL> generates Sybase ASE DDL from the DBIO schema class hierarchy.
It is the desired-state side of the test-deploy-and-compare strategy used by
L<DBIO::Sybase::Deploy>.

    my $ddl = DBIO::Sybase::DDL->install_ddl($schema);
    # CREATE TABLE ...; CREATE INDEX ...;

B<NOTE:> Sybase ASE does not support CHECK constraints in the same way as
other databases. Unique constraints are emitted as unique indexes instead.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::Sybase::DDL->install_ddl($schema);

Returns the full installation DDL as a single string. C<$schema> may be
a connected schema instance or a schema class name.

=func sybase_column_type

    my $sql_type = sybase_column_type($data_type);

Maps a logical DBIO C<data_type> to its Sybase ASE column type. Shared by
the DDL emitter and L<DBIO::Sybase::Diff::Table> so both sides of the
test-deploy-and-compare agree on type rendering. Exportable on request.

=func sybase_default_clause

    my $clause = sybase_default_clause($default_value);

Renders the C<DEFAULT> fragment for a column definition (with a leading
space), or the empty string when there is no default. A SCALAR ref is
emitted verbatim (SQL expression); the literal string C<'null'> yields no
clause; anything else is single-quoted. Shared by the DDL emitter and the
Diff table/column emitters so all three render defaults identically.
Exportable on request.

=seealso

=over

=item * L<DBIO::Sybase> - schema component

=item * L<DBIO::Sybase::Deploy> - uses this to generate DDL for deployment

=item * L<DBIO::Oracle::DDL> - sibling implementation

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
