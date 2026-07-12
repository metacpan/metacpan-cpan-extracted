package DBIO::MySQL::DDL;
# ABSTRACT: Generate MySQL/MariaDB DDL from DBIO Result classes

use strict;
use warnings;

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Schema::Type ();
use DBIO::MySQL::Adapter ();

my $ADAPTER = DBIO::MySQL::Adapter->new;



sub install_ddl {
  my ($class, $schema) = @_;

  my @stmts;
  my @view_stmts;
  my %seen_table;
  my %seen_view;

  for my $source_name (sort $schema->sources) {
    my $source = $schema->source($source_name);
    my $result_class = $source->result_class;
    my $table_name   = $source->name;

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
    my @pk_cols = $source->primary_columns;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = _mysql_column_type($info);

      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;
      $def .= ' NOT NULL' if defined $info->{is_nullable} && !$info->{is_nullable};
      $def .= ' AUTO_INCREMENT' if $info->{is_auto_increment};

      if (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        if (ref $dv eq 'SCALAR') {
          $def .= " DEFAULT $$dv";
        } else {
          $def .= " DEFAULT '$dv'";
        }
      }

      push @col_defs, $def;
    }

    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _quote_ident($_) } @pk_cols);
    }

    # Unique constraints
    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        my $cols = $uniques{$uname};
        push @col_defs, sprintf '  UNIQUE KEY %s (%s)',
          _quote_ident($uname),
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

    my $engine  = ($result_class->can('mysql_engine')  && $result_class->mysql_engine)  || 'InnoDB';
    my $charset = ($result_class->can('mysql_charset') && $result_class->mysql_charset) || 'utf8mb4';
    my $collate = ($result_class->can('mysql_collate') && $result_class->mysql_collate) || 'utf8mb4_unicode_ci';

    push @stmts, sprintf "CREATE TABLE %s (\n%s\n) ENGINE=%s DEFAULT CHARSET=%s COLLATE=%s;",
      _quote_ident($table_name),
      join(",\n", @col_defs),
      $engine, $charset, $collate;

    # MySQL-specific indexes via mysql_indexes (parallel to pg_indexes)
    if ($result_class->can('mysql_indexes')) {
      my $indexes = $result_class->mysql_indexes;
      for my $idx_name (sort keys %$indexes) {
        my $idx = $indexes->{$idx_name};
        my $unique = $idx->{unique} ? 'UNIQUE ' : '';
        my $type = $idx->{using} ? " USING $idx->{using}" : '';
        my $cols = join ', ',
          map { _quote_ident($_) } @{ $idx->{columns} // [] };
        push @stmts, sprintf 'CREATE %sINDEX %s ON %s (%s)%s;',
          $unique, _quote_ident($idx_name), _quote_ident($table_name), $cols, $type;
      }
    }
  }

  return join "

", @stmts, @view_stmts;
}

sub _mysql_column_type {
  my ($info) = @_;
  my $type = $info->{data_type} // 'text';

  # Pre-parameterized types pass through
  return $type if $type =~ /\(.+\)$/;

  # Portable base types: delegate to the adapter (single source of truth)
  if (DBIO::Schema::Type::is_base_type(lc $type)) {
    my $canon = eval { DBIO::Schema::Type::canonical_column('_', $info) };
    return $ADAPTER->to_native($canon) if $canon;
  }

  # Use size for varchar/varbinary/binary (non-base alias path)
  if ($info->{size} && $type =~ /^(varchar|varbinary|binary)$/i) {
    return "$type($info->{size})";
  }

  # Legacy / dialect alias names — only aliases, not the 8 base-type names
  my %type_map = (
    int        => 'int',
    bigint     => 'bigint',
    smallint   => 'smallint',
    tinyint    => 'tinyint',
    serial     => 'int',
    bigserial  => 'bigint',

    varchar    => 'varchar(255)',
    string     => 'text',

    float      => 'float',
    real       => 'double',
    'double precision' => 'double',
    decimal    => 'decimal(10,2)',

    bytea      => 'blob',

    date       => 'date',
    datetime   => 'datetime',
    time       => 'time',
    json       => 'json',
  );

  return $type_map{ lc $type } // $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::DDL - Generate MySQL/MariaDB DDL from DBIO Result classes

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::MySQL::DDL> generates a MySQL DDL script from a L<DBIO::Schema>
class hierarchy. It is the desired-state side of the
test-deploy-and-compare strategy used by L<DBIO::MySQL::Deploy>.

    my $ddl = DBIO::MySQL::DDL->install_ddl($schema);

The generated DDL is plain SQL, one C<CREATE TABLE> per source. Tables
default to C<ENGINE=InnoDB> and C<CHARSET=utf8mb4 COLLATE
utf8mb4_unicode_ci>. Result classes can override per-table via
C<mysql_engine>, C<mysql_charset>, C<mysql_collate> attributes.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::MySQL::DDL->install_ddl($schema);

Returns the full installation DDL as a single string.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
