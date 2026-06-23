package DBIO::PostgreSQL::DDL;
# ABSTRACT: Generate PostgreSQL DDL from DBIO schema classes

use strict;
use warnings;

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::Schema::Type ();
use DBIO::PostgreSQL::Adapter ();
use DBIO::PostgreSQL::Introspect ();

my $ADAPTER = DBIO::PostgreSQL::Adapter->new;



sub install_ddl {
  my ($class, $schema) = @_;
  my @stmts;
  my @view_stmts;
  my %seen_table;
  my %seen_view;

  # 1. Extensions
  for my $ext ($schema->pg_extensions) {
    push @stmts, "CREATE EXTENSION IF NOT EXISTS \"$ext\";";
  }

  # 2. Schemas (namespaces)
  for my $ns ($schema->pg_schemas) {
    next if $ns eq 'public'; # public always exists
    push @stmts, sprintf 'CREATE SCHEMA IF NOT EXISTS %s;', _quote_ident($ns);
  }

  # 3. Types from PgSchema classes
  for my $ns ($schema->pg_schemas) {
    my $pg_schema_class = $schema->pg_schema_class($ns);
    next unless $pg_schema_class;

    # Enums
    for my $def (@{ $pg_schema_class->_pg_enum_defs }) {
      my ($name, $values) = @$def;
      my $vals = join ', ', map { "'$_'" } @$values;
      push @stmts, sprintf "CREATE TYPE %s.%s AS ENUM (%s);",
        _quote_ident($ns), _quote_ident($name), $vals;
    }

    # Composite types
    for my $def (@{ $pg_schema_class->_pg_type_defs }) {
      my ($name, $fields) = @$def;
      my @attrs;
      for my $fname (sort keys %$fields) {
        push @attrs, sprintf '  %s %s', _quote_ident($fname), $fields->{$fname};
      }
      push @stmts, sprintf "CREATE TYPE %s.%s AS (\n%s\n);",
        _quote_ident($ns), _quote_ident($name), join(",\n", @attrs);
    }

    # Functions
    for my $def (@{ $pg_schema_class->_pg_function_defs }) {
      my ($name, $sql) = @$def;
      $sql =~ s/^\s+|\s+$//g;
      $sql .= ';' unless $sql =~ /;\s*$/;
      push @stmts, $sql;
    }
  }

  # 3b. Auto-generate CREATE TYPE for Cake-style enum columns
  #     (data_type => 'enum' with extra->{list} but no pg_enum_type)
  {
    my @sources = $schema->sources;
    for my $source_name (sort @sources) {
      my $source = $schema->source($source_name);
      my $result_class = $source->result_class;
      my $table_name = $source->name;

      # Only real tables carry enum columns worth a CREATE TYPE; views and
      # subquery sources (scalar-ref name) have no backing table.
      next if $source->isa('DBIO::ResultSource::View') || ref $table_name;

      my $pg_schema_name = $result_class->can('pg_schema')
        ? $result_class->pg_schema : undef;

      for my $col_name ($source->columns) {
        my $info = $source->column_info($col_name);
        next unless ($info->{data_type} // '') eq 'enum';
        next if $info->{pg_enum_type};                       # already declared via PgSchema
        next unless $info->{extra} && $info->{extra}{list};  # need values

        # Generate a type name: {table}_{column}_enum
        my $type_name = "${table_name}_${col_name}_enum";
        my $qualified = $pg_schema_name
          ? sprintf('%s.%s', _quote_ident($pg_schema_name), _quote_ident($type_name))
          : _quote_ident($type_name);

        my $vals = join ', ', map { "'$_'" } @{ $info->{extra}{list} };
        push @stmts, sprintf "CREATE TYPE %s AS ENUM (%s);", $qualified, $vals;

        # Set pg_enum_type so _pg_column_type picks it up
        $info->{pg_enum_type} = $pg_schema_name
          ? "$pg_schema_name.$type_name"
          : $type_name;
      }
    }
  }

  # 4. Tables from Result classes
  my @sources = $schema->sources;
  for my $source_name (sort @sources) {
    my $source = $schema->source($source_name);
    my $result_class = $source->result_class;

    my $table_name = $source->name;
    my $pg_schema_name;
    if ($result_class->can('pg_schema')) {
      $pg_schema_name = $result_class->pg_schema;
    }

    # Views: emit CREATE VIEW after all tables; skip virtual views.
    if ($source->isa('DBIO::ResultSource::View')) {
      next if $source->can('is_virtual') && $source->is_virtual;
      my $vname = ref $table_name eq 'SCALAR' ? $$table_name : $table_name;
      next if ref $vname;
      my $vqual = $pg_schema_name ? "$pg_schema_name.$vname" : $vname;
      next if $seen_view{$vqual}++;
      my $def = $source->can('view_definition') ? $source->view_definition : undef;
      next unless defined $def && length $def;
      push @view_stmts, sprintf 'CREATE VIEW %s AS %s;', $vqual, $def;
      next;
    }

    # A scalar-ref name is either a literal table name (\'cd') or an inline
    # subquery source; deref the former, skip the latter.
    if (ref $table_name eq 'SCALAR') {
      $table_name = $$table_name;
      next if $table_name =~ /\s|\(/;
    }
    next if ref $table_name;

    my $qualified = $pg_schema_name
      ? "$pg_schema_name.$table_name"
      : $table_name;

    # Multiple result sources can map to one physical table; emit it once.
    next if $seen_table{$qualified}++;

    # Column definitions
    my @col_defs;
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      my $type = _pg_column_type($info);
      my $def = sprintf '  %s %s', _quote_ident($col_name), $type;
      $def .= ' NOT NULL' if defined $info->{is_nullable} && !$info->{is_nullable};
      if ($info->{is_auto_increment} && $type !~ /^(?:big)?serial$/) {
        # DBIO convention: auto-increment columns are GENERATED ALWAYS AS
        # IDENTITY unless the user explicitly opts into BY DEFAULT via
        # extra->{identity} = 'd'. ALWAYS prevents accidental client-side
        # inserts, matches the DBIx::Class::ResultSource default, and is
        # what DBIO::PostgreSQL::Diff::target_from_compiled synthesizes
        # (so the round-trip diff against the introspected source is
        # empty for the default schema).
        my $kind = DBIO::PostgreSQL::Introspect->identity_kind(
          $info->{extra} && $info->{extra}{identity}
        ) // 'ALWAYS';
        $def .= " GENERATED $kind AS IDENTITY";
      }
      elsif (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        if (ref $dv eq 'SCALAR') {
          $def .= " DEFAULT $$dv";
        } else {
          $def .= " DEFAULT '$dv'";
        }
      }
      push @col_defs, $def;
    }

    # Primary key
    my @pk = $source->primary_columns;
    if (@pk) {
      push @col_defs, sprintf '  PRIMARY KEY (%s)',
        join(', ', map { _quote_ident($_) } @pk);
    }

    # Unique constraints declared via add_unique_constraint / Cake's `unique`.
    # The 'primary' constraint is auto-added by set_primary_key and already
    # emitted above as PRIMARY KEY, so it must be skipped here.
    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        my $cols = $uniques{$uname};
        push @col_defs, sprintf '  CONSTRAINT %s UNIQUE (%s)',
          _quote_ident($uname),
          join(', ', map { _quote_ident($_) } @$cols);
      }
    }

    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);",
      $qualified, join(",\n", @col_defs);

    # PostgreSQL-specific indexes
    if ($result_class->can('pg_indexes')) {
      my $indexes = $result_class->pg_indexes;
      for my $idx_name (sort keys %$indexes) {
        my $idx = $indexes->{$idx_name};
        my $using = $idx->{using} ? " USING $idx->{using}" : '';
        my $columns;
        if ($idx->{expression}) {
          $columns = $idx->{expression};
        } else {
          $columns = join(', ', @{ $idx->{columns} // [] });
        }
        my $unique = $idx->{unique} ? 'UNIQUE ' : '';
        my $sql = sprintf 'CREATE %sINDEX %s ON %s%s (%s)',
          $unique, _quote_ident($idx_name), $qualified, $using, $columns;
        if ($idx->{with}) {
          my @with_parts;
          for my $k (sort keys %{ $idx->{with} }) {
            push @with_parts, "$k = $idx->{with}{$k}";
          }
          $sql .= ' WITH (' . join(', ', @with_parts) . ')';
        }
        $sql .= " WHERE $idx->{where}" if $idx->{where};
        push @stmts, "$sql;";
      }
    }

    # Triggers
    if ($result_class->can('pg_triggers')) {
      my $triggers = $result_class->pg_triggers;
      for my $trg_name (sort keys %$triggers) {
        my $trg = $triggers->{$trg_name};
        my $for_each = $trg->{for_each} || 'ROW';
        push @stmts, sprintf 'CREATE TRIGGER %s %s %s ON %s FOR EACH %s EXECUTE FUNCTION %s;',
          _quote_ident($trg_name), $trg->{when}, $trg->{event},
          $qualified, $for_each, $trg->{execute};
      }
    }

    # RLS
    if ($result_class->can('pg_rls') && $result_class->pg_rls) {
      my $rls = $result_class->pg_rls;
      if ($rls->{enable}) {
        push @stmts, sprintf 'ALTER TABLE %s ENABLE ROW LEVEL SECURITY;', $qualified;
      }
      if ($rls->{force}) {
        push @stmts, sprintf 'ALTER TABLE %s FORCE ROW LEVEL SECURITY;', $qualified;
      }
      if ($rls->{policies}) {
        for my $pol_name (sort keys %{ $rls->{policies} }) {
          my $pol = $rls->{policies}{$pol_name};
          my $sql = sprintf 'CREATE POLICY %s ON %s',
            _quote_ident($pol_name), $qualified;
          $sql .= sprintf ' FOR %s', $pol->{for} if $pol->{for} && $pol->{for} ne 'ALL';
          if ($pol->{roles} && @{ $pol->{roles} }) {
            $sql .= sprintf ' TO %s', join(', ', @{ $pol->{roles} });
          }
          $sql .= sprintf ' USING (%s)', $pol->{using} if $pol->{using};
          $sql .= sprintf ' WITH CHECK (%s)', $pol->{with_check} if $pol->{with_check};
          push @stmts, "$sql;";
        }
      }
    }

    # CHECK constraints
    if ($result_class->can('pg_check_constraints')) {
      my $checks = $result_class->pg_check_constraints;
      for my $name (sort keys %$checks) {
        my $entry = $checks->{$name};
        my $expr  = $entry->{definition};
        $expr = "CHECK ($expr)" unless $expr =~ /^\s*CHECK\b/i;
        push @stmts, sprintf 'ALTER TABLE %s ADD CONSTRAINT %s %s;',
          $qualified, _quote_ident($name), $expr;
      }
    }

    # Raw trailing DDL (e.g. cross-table FKs that DBIO::PostgreSQL::DDL does
    # not auto-generate from belongs_to)
    if ($result_class->can('pg_extra_ddl')) {
      my $extra = $result_class->pg_extra_ddl;
      for my $sql (@$extra) {
        my $stmt = $sql;
        $stmt =~ s/\s*;\s*\z//;
        push @stmts, "$stmt;";
      }
    }
  }

  # 5. Settings
  my $settings = $schema->pg_settings;
  if ($settings && %$settings) {
    for my $key (sort keys %$settings) {
      push @stmts, sprintf "ALTER DATABASE CURRENT SET %s = '%s';",
        $key, $settings->{$key};
    }
  }

  # 6. Search path
  my @search_path = $schema->pg_search_path;
  if (@search_path) {
    push @stmts, sprintf "SET search_path TO %s;",
      join(', ', @search_path);
  }

  return join("\n\n", @stmts, @view_stmts) . "\n";
}


sub _pg_column_type {
  my ($info) = @_;
  my $type = $info->{data_type};

  # Handle enum types
  if ($type eq 'enum' && $info->{pg_enum_type}) {
    return $info->{pg_enum_type};
  }

  # Handle composite types
  if ($type eq 'composite' && $info->{pg_type_name}) {
    return $info->{pg_type_name};
  }

  # Handle arrays
  return $type if $type =~ /\[\]$/;

  # Handle parameterized types (varchar(N), numeric(P,S), vector(N))
  return $type if $type =~ /\(.+\)$/;

  # Portable base types: delegate to the adapter (single source of truth)
  if (DBIO::Schema::Type::is_base_type(lc $type)) {
    my $canon = DBIO::Schema::Type::canonical_column('_', $info);
    return $ADAPTER->to_native($canon);
  }

  # Legacy PG-dialect aliases: pass through as their native PG names
  my %type_map = (
    bigint            => 'bigint',
    smallint          => 'smallint',
    serial            => 'serial',
    bigserial         => 'bigserial',
    varchar           => 'character varying',
    float             => 'double precision',
    real              => 'real',
    date              => 'date',
    'timestamp with time zone' => 'timestamp with time zone',
    timestamptz       => 'timestamp with time zone',
    uuid              => 'uuid',
    json              => 'json',
    jsonb             => 'jsonb',
    bytea             => 'bytea',
    inet              => 'inet',
    cidr              => 'cidr',
    macaddr           => 'macaddr',
    tsvector          => 'tsvector',
    tsquery           => 'tsquery',
    xml               => 'xml',
    money             => 'money',
    interval          => 'interval',
    point             => 'point',
    line              => 'line',
    lseg              => 'lseg',
    box               => 'box',
    path              => 'path',
    polygon           => 'polygon',
    circle            => 'circle',
  );

  return $type_map{$type} // $type;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::DDL - Generate PostgreSQL DDL from DBIO schema classes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::PostgreSQL::DDL> generates PostgreSQL DDL statements directly from
DBIO schema and result classes, without going through SQL::Translator. This
produces correct, PostgreSQL-native SQL that preserves all PostgreSQL-specific
features.

The generated DDL is used by L<DBIO::PostgreSQL::Deploy/install> for fresh
installs and by the test-deploy side of L<DBIO::PostgreSQL::Deploy/diff> for
upgrade diffing. Reach for this class directly when you want the raw SQL text;
use L<DBIO::PostgreSQL::Deploy> when you want database orchestration.

=head1 METHODS

=head2 install_ddl

    my $sql = DBIO::PostgreSQL::DDL->install_ddl($schema);

Generates a complete PostgreSQL DDL script for the connected schema object.
The script is ordered to satisfy dependencies:

=over 4

=item 1. C<CREATE EXTENSION IF NOT EXISTS> statements

=item 2. C<CREATE SCHEMA IF NOT EXISTS> statements (skipping C<public>)

=item 3. Enum types, composite types, and functions from L<DBIO::PostgreSQL::PgSchema> subclasses

=item 4. C<CREATE TABLE> statements with columns, primary keys, indexes, triggers, and RLS from L<DBIO::PostgreSQL::Result> classes

=item 5. C<ALTER DATABASE CURRENT SET> for C<pg_settings>

=item 6. C<SET search_path TO> from C<pg_search_path>

=back

Returns the DDL as a single string with statements separated by blank lines.

=seealso

=over 4

=item * L<DBIO::PostgreSQL> - schema component that calls C<pg_install_ddl>

=item * L<DBIO::PostgreSQL::Deploy> - uses C<install_ddl> for fresh installs and diff

=item * L<DBIO::PostgreSQL::PgSchema> - source of enum, type, and function definitions

=item * L<DBIO::PostgreSQL::Result> - source of table, index, trigger, and RLS definitions

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
