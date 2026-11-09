package DBIO::DuckDB::DDL;
# ABSTRACT: Generate DuckDB DDL from DBIO Result classes

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::DuckDB::DDL::Emit qw(
  quote_ident quote_table split_table column_def pk_clause unique_clause create_table create_index create_sequence fk_clause
);



sub install_ddl {
  my ($class, $schema) = @_;

  my @stmts;
  my %seen_table;
  my %seen_schema;
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
      push @view_stmts, sprintf 'CREATE VIEW %s AS %s;', quote_ident($vname), $def;
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
        if (ref $dv eq 'SCALAR') {
          $default = $$dv;
        }
        else {
          # A string literal: a quote inside it is doubled.
          (my $lit = $dv) =~ s/'/''/g;
          $default = "'$lit'";
        }
      }

      push @col_defs, column_def(
        name     => $col_name,
        type     => _duckdb_column_type($info),
        # ADR 0043 (core): canonical_column turns a MISSING is_nullable
        # into not_null=1, so a column without the key must deploy as
        # NOT NULL too -- not just one that says is_nullable => 0.
        not_null => (!$info->{is_nullable}),
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

    # Foreign keys: DuckDB enforces them (docs/adr/0001, addendum 2026-10-25).
    push @col_defs, _foreign_key_clauses($schema, $source, $table_name, \%seen_table);

    # table('other.t') is table t of schema other: the schema first, once
    # (karr k49, maintainer decision 2026-10-25).
    my ($table_schema) = split_table($table_name);
    push @stmts, 'CREATE SCHEMA IF NOT EXISTS ' . quote_ident($table_schema) . ';'
      if defined $table_schema && !$seen_schema{$table_schema}++;

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

    # Standalone indexes: the ones written by hand with duckdb_indexes, and
    # the canonical declarations of the result source (Cake idx, indices;
    # ADR 0061 in core, ADR 0008 here, karr k41). A canonical declaration of
    # the same name wins over the hand-written one.
    my %indexes;
    if ($result_class->can('duckdb_indexes')) {
      my $hand = $result_class->duckdb_indexes;
      $indexes{$_} = $hand->{$_} for keys %$hand;
    }
    # The own block takes `expression` only: DuckDB refuses a partial index
    # (WHERE) and has no USING clause. Any other key throws; so does a type
    # other than unique and any options -- never a plainer index than the
    # one declared. `expression` is the whole list between the parentheses
    # as written and stands in for `columns` (ADR 0008 addendum, karr k44).
    for my $decl ($source->index_declarations_for('duckdb', [qw(expression)])) {
      my $label = "index '$decl->{name}' of table '$table_name'";
      $source->throw_exception(
        "DuckDB cannot create $label with type '$decl->{type}': only a "
        . "plain or unique index exists in DuckDB"
      ) if defined $decl->{type} && lc $decl->{type} ne 'unique';
      my $opts = $decl->{options};
      $source->throw_exception(
        "DuckDB cannot create $label with options: it takes none"
      ) if defined $opts && length(
        ref $opts eq 'HASH'  ? join('', %$opts)
        : ref $opts eq 'ARRAY' ? join('', @$opts) : $opts
      );
      my $own = ($decl->{driver} || {})->{duckdb} || {};
      $source->throw_exception(
        "DuckDB cannot create $label with an empty expression"
      ) if defined $own->{expression} && $own->{expression} !~ /\S/;
      $indexes{ $decl->{name} } = {
        columns    => $decl->{columns},
        unique     => $decl->{unique},
        expression => $own->{expression},
      };
    }
    for my $idx_name (sort keys %indexes) {
      my $idx = $indexes{$idx_name};
      push @stmts, create_index(
        name    => $idx_name,
        table   => $table_name,
        columns    => $idx->{columns} // [],
        unique     => $idx->{unique},
        expression => $idx->{expression},
      );
    }
  }

  return join "

", @stmts, @view_stmts;
}


sub source_schemas {
  my ($class, $schema) = @_;
  my %seen;
  for my $source_name ($schema->sources) {
    my $source = $schema->source($source_name);
    next if $source->isa('DBIO::ResultSource::View');
    my $name = _resolve_table_name($source->name);
    next unless defined $name;
    my ($ns) = split_table($name);
    $seen{$ns} = 1 if defined $ns;
  }
  return sort keys %seen;
}

# The FOREIGN KEY clauses of a table, one per belongs_to relationship that is
# a foreign key constraint, in the order of the relationship names, the same
# key once however many relationships declare it. DuckDB takes a key only to
# the columns of a PRIMARY KEY or UNIQUE constraint of the parent, in that
# constraint's own order (measured, libduckdb 1.5.3: "does not have a primary
# key or unique constraint on the columns b,a" for a key written (b,a) to a
# key (a,b)), so the column pairs are laid out in the order of the parent's
# key and not in the alphabetical one of the condition. CASCADE, SET NULL and
# SET DEFAULT are refused by DuckDB's parser; they are refused here first,
# before any statement, naming table and column.
my %FK_ACTION_OK = ('RESTRICT' => 1, 'NO ACTION' => 1);
my $FK_DOC = 'https://duckdb.org/docs/stable/sql/constraints#foreign-keys';

sub _foreign_key_clauses {
  my ($schema, $source, $table_name, $created) = @_;
  my (@clauses, %seen);

  for my $rel (sort $source->relationships) {
    my $info = $source->relationship_info($rel);
    next unless $info && $info->{attrs} && $info->{attrs}{is_foreign_key_constraint};

    my $foreign = $info->{class};
    my $fs = eval { $schema->source($foreign) }
          // eval { $schema->source($foreign =~ s/.*:://r) };
    next unless $fs;
    next if $fs->isa('DBIO::ResultSource::View');   # no key to a view
    my $foreign_table = _resolve_table_name($fs->name);
    next unless defined $foreign_table;

    my $cond = $info->{cond};
    next unless ref $cond eq 'HASH';

    # A table is created whole and DuckDB cannot add a foreign key to one that
    # exists, so a key to a table that does not exist yet -- the two point at
    # each other, directly or through others -- cannot be written.
    $source->throw_exception(sprintf
      "DuckDB cannot create the foreign key of relationship '%s' of table '%s': "
      . "it points to table '%s', which points back to it (directly or "
      . "through other tables) -- both are created whole and DuckDB cannot add "
      . "a foreign key to a table that exists (%s). Declare one of the two "
      . "relationships with is_foreign_key_constraint => 0",
      $rel, $table_name, $foreign_table,
      'https://duckdb.org/docs/stable/sql/statements/alter_table')
      if $foreign_table ne $table_name && !$created->{$foreign_table};

    my %to_from;
    for my $fcol (keys %$cond) {
      (my $to   = $fcol)         =~ s/^foreign\.//;
      (my $from = $cond->{$fcol}) =~ s/^self\.//;
      $to_from{$to} = $from;
    }
    my @to_sorted = sort keys %to_from;

    # the key of the parent that has exactly these columns
    my %keys;
    $keys{primary} = [ $fs->primary_columns ];
    if ($fs->can('unique_constraints')) {
      my %u = $fs->unique_constraints;
      $keys{$_} //= $u{$_} for sort keys %u;
    }
    my ($key) = grep {
      my $cols = $keys{$_};
      @$cols == @to_sorted && join("\0", sort @$cols) eq join("\0", @to_sorted)
    } 'primary', sort grep { $_ ne 'primary' } keys %keys;
    $source->throw_exception(sprintf
      "DuckDB cannot create the foreign key of relationship '%s' of table '%s': "
      . "the columns %s of table '%s' are neither its PRIMARY KEY or UNIQUE "
      . "constraint, and DuckDB takes a foreign key only to one of those (%s)",
      $rel, $table_name, join(', ', map { "'$_'" } @to_sorted), $foreign_table, $FK_DOC)
      unless defined $key;
    my @to   = @{ $keys{$key} };
    my @from = map { $to_from{$_} } @to;

    my %action;
    for my $event (qw(delete update)) {
      my $value = $info->{attrs}{"on_$event"};
      next unless defined $value && length $value;
      (my $word = uc $value) =~ s/\s+/ /g;
      $word =~ s/^ | $//g;
      unless ($FK_ACTION_OK{$word}) {
        $source->throw_exception(sprintf
          "DuckDB cannot create the foreign key of relationship '%s' (%s): "
          . "ON %s %s is not available, DuckDB takes RESTRICT and NO ACTION only "
          . "and refuses CASCADE, SET NULL and SET DEFAULT (%s)",
          $rel, join(', ', map { "$table_name.$_" } @from), uc $event, $word, $FK_DOC);
      }
      $action{$event} = $word;
    }

    my $clause = fk_clause(
      from => \@from, to_table => $foreign_table, to => \@to,
      on_delete => $action{delete}, on_update => $action{update},
    );
    next if $seen{ lc $clause }++;
    push @clauses, $clause;
  }

  return @clauses;
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

  # ENUM: DuckDB takes the values in the type, ENUM('a', 'b'); a quote in a
  # value is doubled.
  if (lc $type eq 'enum') {
    my $list = ($info->{extra} || {})->{list};
    return $type unless ref $list eq 'ARRAY' && @$list;
    return 'ENUM(' . join(', ', map { (my $v = $_) =~ s/'/''/g; "'$v'" } @$list) . ')';
  }

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

  my $mapped = $type_map{ lc $type } // uc $type;

  # %type_map above collapses every varchar/char/text-family alias to a
  # bare VARCHAR and numeric/decimal to a bare DECIMAL, dropping any
  # declared $info->{size}. Re-attach it now that the DuckDB-native name
  # is known. (money's DECIMAL(19,4) already has parens and is excluded
  # since it isn't string-equal to bare 'DECIMAL'.)
  if (defined $info->{size}) {
    if ($mapped eq 'VARCHAR' && !ref $info->{size}) {
      $mapped .= "($info->{size})";
    }
    elsif ($mapped eq 'DECIMAL' && ref $info->{size} eq 'ARRAY') {
      $mapped .= '(' . join(',', @{ $info->{size} }) . ')';
    }
  }

  return $mapped;
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

version 0.900004

=head1 DESCRIPTION

C<DBIO::DuckDB::DDL> generates a DuckDB DDL script from a L<DBIO::Schema>
class hierarchy. It is the desired-state side of the test-deploy-and-
compare strategy used by L<DBIO::DuckDB::Deploy>.

    my $ddl = DBIO::DuckDB::DDL->install_ddl($schema_class_or_instance);

The output is plain SQL, suitable for executing one statement at a time
against a fresh DuckDB database. Emits C<CREATE SEQUENCE> (one per integer
auto-increment column, C<START 1000000>), C<CREATE TABLE> (inline columns,
primary key, unique constraints), C<CREATE INDEX> and C<CREATE VIEW> for
non-virtual views. Foreign keys are not emitted (see
F<docs/adr/0001-foreign-keys-omitted-from-install-ddl.md>).

Indexes come from the canonical declaration of the result source
(C<idx>, C<indices>; C<index_declarations_for('duckdb')>) and from a
hand-written C<duckdb_indexes> class method; on the same name the canonical
one wins. The own block C<< driver => { duckdb => { expression => ... } } >>
gives an expression index: the value is the whole list between the
parentheses, as DuckDB takes it (C<'lower(b)'>, C<'a, lower(b)'>), and stands
in for C<columns>. DuckDB has neither partial indexes nor index types, so a
C<where> or any other key, a C<type> other than C<unique> and any C<options>
throw (F<docs/adr/0008-index-declarations-are-read-canonically.md>).

=head1 METHODS

=head2 install_ddl

    my $ddl = DBIO::DuckDB::DDL->install_ddl($schema);

Returns the full installation DDL as a single string.

=head2 source_schemas

    my @schemas = DBIO::DuckDB::DDL->source_schemas($schema);

The schemas other than C<main> that the tables of the sources live in: the
C<other> of a source declared C<< table('other.t') >>, sorted, each once.
L<DBIO::DuckDB::Deploy> hands them to L<DBIO::DuckDB::Introspect>, which reads
only those besides C<main>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
