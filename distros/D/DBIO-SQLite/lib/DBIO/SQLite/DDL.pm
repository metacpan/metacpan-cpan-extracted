package DBIO::SQLite::DDL;
# ABSTRACT: Generate SQLite DDL from DBIO Result classes

use strict;
use warnings;

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Schema::Type ();
use DBIO::SQLite::Adapter ();
use namespace::clean;

my $ADAPTER = DBIO::SQLite::Adapter->new;



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

    # Views: emit CREATE VIEW from the stored definition, after all
    # tables (they may reference any table). Virtual views are ORM-only
    # and have no database object to create.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = ref $table_name eq 'SCALAR' ? $$table_name : $table_name;
      next if ref $vname || $seen_view{$vname}++;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      push @view_stmts, sprintf 'CREATE VIEW %s AS %s;',
        _quote_ident($vname), $def;
      next;
    }

    # A scalar-ref name is either a literal table name (\'cd', emitted
    # unquoted) or an inline subquery source (\'(SELECT ...)'). Deref the
    # former; the latter has no table to create.
    if (ref $table_name eq 'SCALAR') {
      $table_name = $$table_name;
      next if $table_name =~ /\s|\(/;
    }
    next if ref $table_name;

    # Several result sources can map to the same physical table (e.g. a
    # Result subclass or a source_name alias). Emit each table once.
    next if $seen_table{$table_name}++;

    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    # Columns that participate in a UNIQUE constraint are implicitly NOT
    # NULL in well-formed schemas (a unique constraint permits any number
    # of NULLs, so NOT NULL is what makes the constraint meaningful). DBIO
    # schema definitions sometimes omit is_nullable on such columns and
    # rely on the unique declaration to convey it -- promote them to NOT
    # NULL so the storage layer reports the right is_nullable.
    my %unique_col;
    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        my $cols = $uniques{$uname};
        $unique_col{$_} = 1 for @$cols;
      }
    }

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = _sqlite_column_type($info);

      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;

      # A plain INTEGER PRIMARY KEY column is already a SQLite rowid alias --
      # no AUTOINCREMENT keyword needed. AUTOINCREMENT only adds the extra
      # guarantee that rowids are never reused after DELETE (tracked via
      # sqlite_sequence), which breaks tests that delete rows then re-insert
      # and expect the rowid to start back at 1. Emit plain PRIMARY KEY,
      # matching DBIx::Class / SQL::Translator's SQLite producer.
      if (
        @pk_cols == 1
        && $is_pk{$col_name}
        && uc($type) eq 'INTEGER'
        && $info->{is_auto_increment}
      ) {
        $def .= ' PRIMARY KEY';
      }

      my $is_nullable = exists $info->{is_nullable}
        ? $info->{is_nullable}
        : ($unique_col{$col_name} ? 0 : undef);
      $def .= ' NOT NULL' if defined $is_nullable && !$is_nullable;

      if (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        if (ref $dv eq 'SCALAR') {
          $def .= " DEFAULT $$dv";
        } elsif ($dv =~ /\A-?\d+(?:\.\d+)?\z/) {
          # Numeric literals: emit unquoted so that the storage layer
          # reports the default as the bare number, not a string.
          $def .= " DEFAULT $dv";
        } else {
          $def .= " DEFAULT '$dv'";
        }
      }

      push @col_defs, $def;
    }

    # Multi-column or non-INTEGER primary key: emit as a table-level constraint
    my $had_inline_pk = (@pk_cols == 1)
      && exists $is_pk{ $pk_cols[0] }
      && do {
        my $info = $source->column_info($pk_cols[0]);
        uc(_sqlite_column_type($info)) eq 'INTEGER' && $info->{is_auto_increment};
      };
    if (@pk_cols && !$had_inline_pk) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _quote_ident($_) } @pk_cols);
    }

    # Unique constraints declared via add_unique_constraint
    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        my $cols = $uniques{$uname};
        push @col_defs, sprintf '  UNIQUE (%s)',
          join(', ', map { _quote_ident($_) } @$cols);
      }
    }

    # Foreign keys derived from belongs_to relationships
    for my $rel ($source->relationships) {
      my $info = $source->relationship_info($rel);
      next unless $info && $info->{attrs} && $info->{attrs}{is_foreign_key_constraint};

      my $foreign = $info->{class};
      my $foreign_source = eval { $schema->source($foreign) }
        // eval { $schema->source($foreign =~ s/.*:://r) };
      next unless $foreign_source;

      my $cond = $info->{cond};
      next unless ref $cond eq 'HASH';

      my (@from, @to);
      for my $foreign_col (sort keys %$cond) {
        my $fcol = $foreign_col;
        $fcol =~ s/^foreign\.//;
        my $self_col = $cond->{$foreign_col};
        $self_col =~ s/^self\.//;
        push @to,   $fcol;
        push @from, $self_col;
      }

      # A literal table name (\'cd') arrives as a scalar ref; deref it so
      # the FK references the table, not "SCALAR(0x...)".
      my $foreign_name = $foreign_source->name;
      $foreign_name = $$foreign_name if ref $foreign_name eq 'SCALAR';

      push @col_defs, sprintf '  FOREIGN KEY (%s) REFERENCES %s(%s)',
        join(', ', map { _quote_ident($_) } @from),
        _quote_ident($foreign_name),
        join(', ', map { _quote_ident($_) } @to);
    }

    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);",
      _quote_ident($table_name), join(",\n", @col_defs);

    # Standalone (non-unique-constraint) indexes -- only if the result
    # class declares them via sqlite_indexes (parallel to pg_indexes)
    if ($result_class->can('sqlite_indexes')) {
      my $indexes = $result_class->sqlite_indexes;
      for my $idx_name (sort keys %$indexes) {
        my $idx = $indexes->{$idx_name};
        my $unique = $idx->{unique} ? 'UNIQUE ' : '';
        my $columns = join ', ',
          map { _quote_ident($_) } @{ $idx->{columns} // [] };
        my $sql = sprintf 'CREATE %sINDEX %s ON %s (%s)',
          $unique, _quote_ident($idx_name),
          _quote_ident($table_name), $columns;
        $sql .= " WHERE $idx->{where}" if $idx->{where};
        push @stmts, "$sql;";
      }
    }
  }

  return join "\n\n", @stmts, @view_stmts;
}

sub _sqlite_column_type {
  my ($info) = @_;
  my $type = $info->{data_type} // 'TEXT';

  # Pre-parameterized types pass through unchanged
  return $type if $type =~ /\(.+\)$/;

  # Portable base types: delegate to the adapter for the single source of truth
  if (DBIO::Schema::Type::is_base_type(lc $type)) {
    my $canon = eval { DBIO::Schema::Type::canonical_column('_', $info) };
    return $ADAPTER->to_native($canon) if $canon;
  }

  # Legacy / dialect aliases: keep familiar SQLite-dialect names so that
  # introspection round-trips cleanly (e.g. VARCHAR stays VARCHAR, not TEXT).
  my %type_map = (
    bigint     => 'INTEGER',
    smallint   => 'INTEGER',
    int        => 'INTEGER',
    serial     => 'INTEGER',
    bigserial  => 'INTEGER',

    varchar    => 'VARCHAR',
    char       => 'CHAR',
    string     => 'TEXT',

    real       => 'REAL',
    float      => 'REAL',
    'double precision' => 'REAL',

    decimal    => 'NUMERIC',

    bytea      => 'BLOB',

    date       => 'DATE',
    datetime   => 'DATETIME',
    time       => 'TIME',
  );

  my $native = $type_map{ lc $type } // uc $type;

  # Parametrize character types when a size is declared -- DBD::SQLite's
  # column_info reports COLUMN_SIZE from the declared VARCHAR(N)/CHAR(N),
  # and downstream consumers (e.g. tests, schema diffs) expect it back.
  if (defined $info->{size} && $native =~ /^(?:VARCHAR|CHAR)$/i) {
    $native .= "($info->{size})";
  }

  return $native;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::SQLite::DDL - Generate SQLite DDL from DBIO Result classes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::SQLite::DDL> generates a SQLite DDL script from the L<DBIO::Schema>
class hierarchy. It is the desired-state side of the test-deploy-and-compare
strategy used by L<DBIO::SQLite::Deploy>.

    my $ddl = DBIO::SQLite::DDL->install_ddl($schema_class_or_instance);
    # CREATE TABLE ...; CREATE INDEX ...; ...

The output is plain SQL, suitable for executing one statement at a time
against a fresh SQLite database.

SQLite has neither schemas nor sequences nor functions/triggers/RLS, so
the generated DDL is much smaller than the PostgreSQL equivalent. The
only constructs emitted are C<CREATE TABLE> (with inline columns,
primary key, unique constraints, foreign keys) and C<CREATE INDEX>.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::SQLite::DDL->install_ddl($schema);

Returns the full installation DDL as a single string. C<$schema> may be
a connected schema instance or a schema class name.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
