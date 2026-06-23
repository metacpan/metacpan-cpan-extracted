package DBIO::MSSQL::DDL;
# ABSTRACT: Generate MSSQL DDL from DBIO Result classes

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(_mssql_column_type _quote_ident);

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Schema::Type ();
use DBIO::MSSQL::Adapter ();

my $ADAPTER = DBIO::MSSQL::Adapter->new;



sub install_ddl {
  my ($class, $schema) = @_;

  my @stmts;
  my %seen_table;
  my @view_stmts;
  my %seen_view;

  for my $source_name (_topo_sort_sources($schema)) {
    my $source       = $schema->source($source_name);
    my $result_class = $source->result_class;
    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = _resolve_table_name($source->name);
      next if !defined $vname || $seen_view{$vname}++;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      push @view_stmts, sprintf 'CREATE VIEW %s AS %s;', _quote_ident($vname), $def;
      next;
    }

    my $table_name   = _resolve_table_name($source->name);

    # Virtual / view source whose name is inline SQL: skip here.
    next unless defined $table_name;

    # Multiple Result classes may share one physical table.
    next if $seen_table{$table_name}++;

    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = _mssql_column_type($info);

      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;

      $def .= ' NOT NULL' if defined $info->{is_nullable} && !$info->{is_nullable};

      if ($info->{is_auto_increment}) {
        $def .= ' IDENTITY(1,1)';
      } elsif (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        if (ref $dv eq 'SCALAR') {
          $def .= " DEFAULT $$dv";
        } else {
          $def .= " DEFAULT $dv";
        }
      }

      push @col_defs, $def;
    }

    if (@pk_cols) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _quote_ident($_) } @pk_cols);
    }

    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        my $cols = $uniques{$uname};
        push @col_defs, sprintf '  UNIQUE (%s)',
          join(', ', map { _quote_ident($_) } @$cols);
      }
    }

    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);",
      _quote_ident($table_name), join(",\n", @col_defs);

    # Standalone indexes declared via mssql_indexes class method.
    if ($result_class->can('mssql_indexes')) {
      my $indexes = $result_class->mssql_indexes;
      for my $idx_name (sort keys %$indexes) {
        my $idx = $indexes->{$idx_name};
        my $unique = $idx->{unique} ? 'UNIQUE ' : '';
        my $kind = $idx->{kind} || '';
        my $kind_sql = $kind eq 'clustered' ? 'CLUSTERED' : $kind eq 'nonclustered' ? 'NONCLUSTERED' : '';
        my $columns = join ', ',
          map { _quote_ident($_) } @{ $idx->{columns} // [] };
        my $sql = sprintf 'CREATE %sINDEX %s ON %s %s(%s)',
          $unique, _quote_ident($idx_name),
          _quote_ident($table_name), $kind_sql ? "$kind_sql " : '', $columns;
        push @stmts, "$sql;";
      }
    }
  }

  return join "

", @stmts, @view_stmts;
}

sub _resolve_table_name {
  my ($name) = @_;
  return $name unless ref $name;
  return undef unless ref $name eq 'SCALAR';
  my $v = $$name;
  return undef unless defined $v;
  return $v if $v =~ /\A\w+\z/;
  return undef;
}

sub _topo_sort_sources {
  my ($schema) = @_;

  my %deps;
  my %by_table;
  my @sources = sort $schema->sources;

  for my $name (@sources) {
    my $s = $schema->source($name);
    my $t = _resolve_table_name($s->name);
    next unless defined $t;
    $by_table{$t} //= $name;
  }

  for my $name (@sources) {
    my $s = $schema->source($name);
    next unless defined _resolve_table_name($s->name);
    $deps{$name} ||= {};
    for my $rel ($s->relationships) {
      my $info = $s->relationship_info($rel);
      next unless $info && $info->{attrs}
               && $info->{attrs}{is_foreign_key_constraint};
      my $foreign = $info->{class};
      my $fs = eval { $schema->source($foreign) }
            // eval { $schema->source($foreign =~ s/.*:://r) };
      next unless $fs;
      my $ft = _resolve_table_name($fs->name);
      next unless defined $ft;
      my $owner = $by_table{$ft};
      next unless $owner;
      next if $owner eq $name;
      $deps{$name}{$owner} = 1;
    }
  }

  my @out;
  my %visited;
  my $visit;
  $visit = sub {
    my ($n) = @_;
    return if $visited{$n}++;
    for my $d (sort keys %{ $deps{$n} || {} }) {
      $visit->($d);
    }
    push @out, $n;
  };
  $visit->($_) for @sources;
  return @out;
}

sub _mssql_column_type {
  my ($info) = @_;
  my $type = $info->{data_type} // 'nvarchar';

  # Pre-parameterized types pass through (e.g. varchar(255), numeric(10,2)).
  return $type if $type =~ /\(.+\)$/;

  # Portable base types: delegate to the adapter (single source of truth,
  # shared shape with DBIO::MySQL / DBIO::PostgreSQL). Introspected live
  # types arrive as dialect names (int, nvarchar, datetime, ...) which are
  # not base-type names, so they fall through to the alias map below.
  if (DBIO::Schema::Type::is_base_type(lc $type)) {
    my $canon = eval { DBIO::Schema::Type::canonical_column('_', $info) };
    return $ADAPTER->to_native($canon) if $canon;
  }

  # Dialect / alias names only (the eight base-type names are handled
  # above). Maps legacy and cross-engine spellings to MSSQL natives.
  my %type_map = (
    # integers
    tinyint   => 'tinyint',
    smallint  => 'smallint',
    int       => 'int',
    bigint    => 'bigint',
    serial    => 'int',
    bigserial => 'bigint',

    # floats / decimals
    real              => 'real',
    float             => 'float',
    'double precision'=> 'float',
    decimal           => 'numeric',

    # strings
    string     => 'nvarchar',
    varchar    => 'nvarchar',
    ntext      => 'ntext',

    # booleans
    bool    => 'bit',

    # blobs
    bytea      => 'varbinary',
    tinyblob   => 'varbinary',
    mediumblob => 'varbinary',
    longblob   => 'varbinary',
    binary     => 'binary',
    varbinary  => 'varbinary',

    # temporal
    date        => 'date',
    time        => 'time',
    datetime    => 'datetime',
    timestamptz => 'datetimeoffset',
    'timestamp with time zone' => 'datetimeoffset',
    smalldatetime => 'smalldatetime',
  );

  my $mapped = $type_map{ lc $type } // $type;

  # Append length to types that take one (char/varchar/binary families).
  # MSSQL reports nvarchar(max)/varbinary(max) as size -1, so only emit a
  # length for positive sizes.
  if ($mapped =~ /^(?:n?char|n?varchar|binary|varbinary)$/i) {
    my $size = $info->{size};
    return "$mapped($size)" if defined $size && $size > 0;
  }

  return $mapped;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::DDL - Generate MSSQL DDL from DBIO Result classes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::MSSQL::DDL> generates a MSSQL DDL script from a L<DBIO::Schema>
class hierarchy. It is the desired-state side of the test-deploy-and-
compare strategy used by L<DBIO::MSSQL::Deploy>.

    my $ddl = DBIO::MSSQL::DDL->install_ddl($schema_class_or_instance);

The output is plain SQL, suitable for executing one statement at a time
against a fresh MSSQL database. Emits C<CREATE TABLE> (inline columns,
primary key, unique, foreign keys) and C<CREATE INDEX>.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::MSSQL::DDL->install_ddl($schema);

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
