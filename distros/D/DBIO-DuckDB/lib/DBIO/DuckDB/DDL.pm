package DBIO::DuckDB::DDL;
# ABSTRACT: Generate DuckDB DDL from DBIO Result classes

use strict;
use warnings;

use DBIO::SQL::Util qw(_quote_ident);
use DBIO::DuckDB::DDL::Emit qw(
  column_def pk_clause unique_clause create_table create_index create_sequence
);



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

    # Virtual / view source whose name is inline SQL: skip here. A
    # CREATE VIEW path can come later.
    next unless defined $table_name;

    # Multiple Result classes may share one physical table (e.g. Artist /
    # ArtistSubclass / SourceNameArtists all map to the "artist" table).
    # Emit CREATE TABLE only once per distinct table name.
    next if $seen_table{$table_name}++;

    my @col_defs;
    my %is_pk;
    my @pk_cols = $source->primary_columns;
    @is_pk{@pk_cols} = (1) x @pk_cols;

    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);

      # Resolve the DEFAULT fragment. DuckDB prefers sequences, so a
      # simple auto-increment becomes a generated-by-sequence default;
      # a dedicated sequence per table keeps round-trip predictable.
      my $default;
      if ($info->{is_auto_increment}) {
        if (_is_guid_type($info)) {
          # A UUID column cannot default from an integer sequence; DuckDB
          # generates GUIDs with uuid().
          $default = 'uuid()';
        }
        else {
          my $seq = "${table_name}_${col_name}_seq";
          $default = sprintf q{nextval('%s')}, $seq;
        }
      }
      elsif (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        $default = ref $dv eq 'SCALAR' ? $$dv : "'$dv'";
      }

      push @col_defs, column_def(
        name     => $col_name,
        type     => _duckdb_column_type($info),
        not_null => (defined $info->{is_nullable} && !$info->{is_nullable}),
        default  => $default,
      );
    }

    push @col_defs, pk_clause(@pk_cols) if @pk_cols;

    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        push @col_defs, unique_clause(@{ $uniques{$uname} });
      }
    }

    # Foreign keys are intentionally NOT emitted in install DDL.
    #
    # DuckDB does not enforce FK constraints at runtime (as of 1.x), but
    # it IS strict at CREATE TABLE time: the referenced column tuple
    # must match a primary key or unique constraint on the parent table
    # *in the same column order*. DBIO result classes often declare FKs
    # with alphabetically-sorted condition hashes that do not match the
    # parent PK order, which DuckDB rejects.
    #
    # Since the constraint has no runtime effect anyway, we skip it here
    # and rely on application logic for referential integrity. The
    # introspect/diff layer can still round-trip FKs if a user adds them
    # via raw SQL.

    # Emit any required sequences BEFORE the table.
    for my $col_name ($source->columns) {
      my $info = $source->column_info($col_name);
      next unless $info->{is_auto_increment};
      next if _is_guid_type($info);  # GUID auto columns default via uuid(), no sequence
      my $seq = "${table_name}_${col_name}_seq";
      # Start high enough that test fixtures / manual inserts with small
      # explicit IDs don't collide with nextval(). DuckDB sequences do
      # not auto-advance on manual inserts the way PG IDENTITY columns
      # do, so we bias the range instead.
      push @stmts, create_sequence(name => $seq, start => 1000000);
    }

    push @stmts, create_table($table_name, @col_defs);

    # Standalone indexes declared via duckdb_indexes class method.
    if ($result_class->can('duckdb_indexes')) {
      my $indexes = $result_class->duckdb_indexes;
      for my $idx_name (sort keys %$indexes) {
        my $idx = $indexes->{$idx_name};
        push @stmts, create_index(
          name    => $idx_name,
          table   => $table_name,
          columns => $idx->{columns} // [],
          unique  => $idx->{unique},
        );
      }
    }
  }

  return join "

", @stmts, @view_stmts;
}

sub _resolve_table_name {
  my ($name) = @_;
  # Plain string: real table name.
  return $name unless ref $name;
  return undef unless ref $name eq 'SCALAR';
  # SCALAR ref: either a pointer to a plain identifier (DBIx::Class test
  # idiom for "this is a real table whose name happens to come from a
  # ref") or inline SQL for a virtual view. Treat word-only content as
  # a real identifier; anything else (whitespace, SELECT, parens) is a
  # virtual view and is skipped.
  my $v = $$name;
  return undef unless defined $v;
  return $v if $v =~ /\A\w+\z/;
  return undef;
}

sub _topo_sort_sources {
  my ($schema) = @_;

  my %deps;             # source_name => { dep_source_name => 1 }
  my %by_table;         # table_name  => first source_name seen
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
      # Depend on whichever source "owns" the foreign table.
      my $owner = $by_table{$ft};
      next unless $owner;
      next if $owner eq $name;  # self-reference
      $deps{$name}{$owner} = 1;
    }
  }

  # Kahn's algorithm with stable alphabetical tiebreak.
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

sub _duckdb_column_type {
  my ($info) = @_;
  my $type = $info->{data_type} // 'VARCHAR';

  return $type if $type =~ /\(.+\)$/;

  my %type_map = (
    # integers
    tinyint   => 'TINYINT',
    smallint  => 'SMALLINT',
    int       => 'INTEGER',
    integer   => 'INTEGER',
    bigint    => 'BIGINT',
    hugeint   => 'HUGEINT',
    serial    => 'INTEGER',
    bigserial => 'BIGINT',

    # floats / decimals
    real              => 'REAL',
    float             => 'FLOAT',
    double            => 'DOUBLE',
    'double precision'=> 'DOUBLE',
    money             => 'DECIMAL(19,4)',  # DuckDB has no MONEY type
    numeric           => 'DECIMAL',
    decimal           => 'DECIMAL',

    # strings
    text       => 'VARCHAR',
    string     => 'VARCHAR',
    varchar    => 'VARCHAR',
    char       => 'VARCHAR',
    character  => 'VARCHAR',
    clob       => 'VARCHAR',
    tinytext   => 'VARCHAR',
    mediumtext => 'VARCHAR',
    longtext   => 'VARCHAR',
    ntext      => 'VARCHAR',

    # booleans
    boolean => 'BOOLEAN',
    bool    => 'BOOLEAN',

    # blobs
    blob       => 'BLOB',
    bytea      => 'BLOB',
    tinyblob   => 'BLOB',
    mediumblob => 'BLOB',
    longblob   => 'BLOB',
    binary     => 'BLOB',
    varbinary  => 'BLOB',
    'bit varying' => 'BLOB',

    # temporal
    date        => 'DATE',
    time        => 'TIME',
    datetime    => 'TIMESTAMP',
    timestamp   => 'TIMESTAMP',
    timestamptz => 'TIMESTAMPTZ',
    'timestamp with time zone' => 'TIMESTAMPTZ',
    interval    => 'INTERVAL',

    # misc
    uuid             => 'UUID',
    guid             => 'UUID',
    uniqueidentifier => 'UUID',  # MSSQL/Sybase GUID type -> DuckDB native UUID
    json => 'JSON',
  );

  return $type_map{ lc $type } // uc $type;
}

# A GUID-family column maps to DuckDB's native UUID type, which (unlike an
# integer surrogate key) cannot take a nextval() sequence default — its
# auto-generated value comes from uuid() instead.
sub _is_guid_type {
  my $info = shift;
  return ( ($info->{data_type} // '') =~ /\A(?:uniqueidentifier|guid|uuid)\z/i );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::DDL - Generate DuckDB DDL from DBIO Result classes

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::DuckDB::DDL> generates a DuckDB DDL script from a L<DBIO::Schema>
class hierarchy. It is the desired-state side of the test-deploy-and-
compare strategy used by L<DBIO::DuckDB::Deploy>.

    my $ddl = DBIO::DuckDB::DDL->install_ddl($schema_class_or_instance);

The output is plain SQL, suitable for executing one statement at a time
against a fresh DuckDB database. Emits C<CREATE TABLE> (inline columns,
primary key, unique, foreign keys) and C<CREATE INDEX>.

DuckDB has real sequences and real schemas (namespaces), but for the
first cut we mirror the dbio-sqlite shape and emit only tables + indexes.
Sequences can be added later when the ResultSource metadata carries them.

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::DuckDB::DDL->install_ddl($schema);

Returns the full installation DDL as a single string.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
