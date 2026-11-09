package DBIO::SQLite::DDL;
# ABSTRACT: Generate SQLite DDL from DBIO Result classes

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Schema::Type ();
use DBIO::SQLite::Adapter ();
use DBIO::SQLite::Util qw(
  default_literal_sql foreign_key_action quote_identifier refuse_qualified_name type_with_size
);
use namespace::clean;

my $ADAPTER = DBIO::SQLite::Adapter->new;



sub install_ddl {
  my ($class, $schema) = @_;

  my @stmts;
  my @view_stmts;
  my %seen_table;
  my %seen_view;

  # Sorted here as well as by a current core, for the same reason as the
  # relationships below.
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
      refuse_qualified_name(view => $table_name) unless ref $table_name;
      push @view_stmts, sprintf 'CREATE VIEW %s AS %s;',
        _name_sql($table_name), $def;
      next;
    }

    # A scalar-ref name is either a literal table name (\'cd', emitted
    # as given) or an inline subquery source (\'(SELECT ...)'). Deref the
    # former; the latter has no table to create.
    my $literal = ref $table_name eq 'SCALAR';
    if ($literal) {
      $table_name = $$table_name;
      next if $table_name =~ /\s|\(/;
    }
    next if ref $table_name;
    refuse_qualified_name(table => $table_name) unless $literal;

    # The name as the statements below write it: quoted, unless the schema
    # gave it as literal SQL.
    my $table_sql = $literal ? $table_name : quote_identifier($table_name);

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
      my $type = _sqlite_column_type($info, $col_name);

      my $def = sprintf '  %s %s', quote_identifier($col_name), $type;

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
      $def .= ' NOT NULL' if !$is_nullable;

      if (defined $info->{default_value}) {
        my $dv = $info->{default_value};
        if (ref $dv eq 'SCALAR') {
          $def .= " DEFAULT $$dv";
        } else {
          # A plain value. In a column with TEXT affinity it is a string and
          # is written as a string literal, also when it looks like a number:
          # bare, '007' would arrive as '7'. Anywhere else a number goes
          # bare, so that the storage layer reports the default as the number
          # and not a string, and anything else is the string literal, with
          # its apostrophes doubled (karr k57).
          $def .= ' DEFAULT ' . default_literal_sql($dv, $type);
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
        join(', ', map { quote_identifier($_) } @pk_cols);
    }

    # Unique constraints declared via add_unique_constraint
    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (sort keys %uniques) {
        next if $uname eq 'primary';
        my $cols = $uniques{$uname};
        push @col_defs, sprintf '  UNIQUE (%s)',
          join(', ', map { quote_identifier($_) } @$cols);
      }
    }

    # Foreign keys derived from belongs_to relationships, in the order of the
    # relationship names: a core before 7e64e7e6b (karr k74) hands them out in a
    # hash's order, which is another one in every process; a current one
    # (Changes under Fixes) sorts them itself, and this sort stays so the text
    # does not depend on which core runs. Sorted, a table with several keys has
    # the same text every time, and of two declarations of one key it is
    # always the first by name that writes the line. Two relationships with
    # different actions on one key still write both lines, now always in the
    # same order -- which makes what SQLite does with them reproducible and
    # decides nothing about whether they should be written (karr k74, open).
    my %seen_fk;
    for my $rel (sort $source->relationships) {
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

      # A literal table name (\'cd') arrives as a scalar ref and is written
      # as given, like in its own CREATE TABLE.
      my $key = sprintf 'FOREIGN KEY (%s) REFERENCES %s(%s)',
        join(', ', map { quote_identifier($_) } @from),
        _name_sql($foreign_source->name),
        join(', ', map { quote_identifier($_) } @to);
      my $actions = _fk_action('ON DELETE', $info->{attrs}{on_delete}, $rel, $table_name)
        . _fk_action('ON UPDATE', $info->{attrs}{on_update}, $rel, $table_name);

      # Several relationships can declare the same key -- same columns, same
      # target, same actions in whichever letter case. It is one key and is
      # written once (karr k74). The same columns and target with different
      # actions are not the same line, and each is still written.
      next if $seen_fk{ $key . lc $actions }++;

      push @col_defs, "  $key$actions";
    }

    push @stmts, sprintf "CREATE TABLE %s (\n%s\n);",
      $table_sql, join(",\n", @col_defs);

    # Standalone (non-unique-constraint) indexes: the ones written by hand
    # with sqlite_index, and the canonical declarations of the result source
    # (Cake idx, indices; ADR 0061 in core, karr k77). A canonical declaration
    # of the same name wins over the hand-written one.
    my %indexes;
    if ($result_class->can('sqlite_indexes')) {
      my $hand = $result_class->sqlite_indexes;
      $indexes{$_} = $hand->{$_} for keys %$hand;
    }
    # The helper refuses an entry that carries only another driver's block
    # and an unknown key in the own block (core k333); its message is passed
    # through. An empty own block is the plain index.
    for my $decl ($source->index_declarations_for('sqlite', [qw(where expression)])) {
      my $own = ($decl->{driver} || {})->{sqlite} || {};
      $indexes{ $decl->{name} } = {
        columns    => $decl->{columns},
        unique     => $decl->{unique},
        expression => $own->{expression},
        where      => $own->{where},
      };
    }
    # The columns of every unique constraint of the table, written above as
    # a UNIQUE line, which SQLite backs with an index of its own. A plain
    # index over exactly those columns would be a second one for the same
    # lookups and is not written (karr k79), whether it says UNIQUE or not.
    # An expression or a WHERE is a different object.
    my %uniq_cols;
    if ($source->can('unique_constraints')) {
      my %uniques = $source->unique_constraints;
      for my $uname (keys %uniques) {
        next if $uname eq 'primary';
        $uniq_cols{ join "\0", @{ $uniques{$uname} } } = 1;
      }
    }

    for my $idx_name (sort keys %indexes) {
      my $idx = $indexes{$idx_name};
      next if !defined $idx->{expression} && !$idx->{where}
        && $uniq_cols{ join "\0", @{ $idx->{columns} // [] } };
      my $unique = $idx->{unique} ? 'UNIQUE ' : '';
      my $columns = defined $idx->{expression}
        ? $idx->{expression}
        : join ', ', map { quote_identifier($_) } @{ $idx->{columns} // [] };
      my $sql = sprintf 'CREATE %sINDEX %s ON %s (%s)',
        $unique, quote_identifier($idx_name), $table_sql, $columns;
      $sql .= " WHERE $idx->{where}" if $idx->{where};
      push @stmts, "$sql;";
    }
  }

  return join "\n\n", @stmts, @view_stmts;
}

# The name of a source as a statement writes it. A plain name is an identifier
# and is quoted. A scalar ref is literal SQL by the schema's own declaration
# and goes in as given -- \'main.cd' is the table cd of the schema main, and
# quoting the whole of it would name another table.
sub _name_sql {
  my ($name) = @_;
  return ref $name eq 'SCALAR' ? $$name : quote_identifier($name);
}

# The " ON DELETE x" / " ON UPDATE x" tail of a FOREIGN KEY line: the action
# the belongs_to declares (karr k66), checked against SQLite's five actions and
# written as declared (karr k88). Not declared -- absent, undef, '' -- is no
# clause, and so is NO ACTION in any letter case, which is what the key has
# without one. An
# unknown word throws, naming the value and the relationship.
sub _fk_action {
  my ($event, $action, $rel, $table) = @_;
  $action = foreign_key_action($action, "relationship '$rel' of table '$table'");
  return '' if !defined $action || uc $action eq 'NO ACTION';
  return " $event $action";
}

sub _sqlite_column_type {
  my ($info, $column_name) = @_;
  my $type = $info->{data_type} // 'TEXT';

  # Pre-parameterized types pass through unchanged
  return $type if $type =~ /\(.+\)$/;

  # Portable base types: delegate to the adapter for the single source of truth.
  # No eval: the type is a base type, so the one thing canonical_column can
  # refuse is a size of a form it cannot read, and that refusal is the answer
  # -- falling on to the alias path wrote another type instead (karr k75).
  if (DBIO::Schema::Type::is_base_type(lc $type)) {
    my $canon = DBIO::Schema::Type::canonical_column($column_name // '_', $info);
    return $ADAPTER->to_native($canon);
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

  # Parametrize legacy-mapped native types when a size is declared -- DBD::SQLite's
  # column_info reports COLUMN_SIZE from the declared VARCHAR(N)/CHAR(N)/NUMERIC(P,S),
  # and downstream consumers (e.g. tests, schema diffs) expect it back.
  if (defined $info->{size} && $native =~ /^(?:VARCHAR|CHAR|CHARACTER)$/i) {
    $native .= "($info->{size})";
  }
  elsif (ref $info->{size} eq 'ARRAY' && $native =~ /^(?:NUMERIC|DECIMAL)$/i) {
    $native .= '(' . join(',', @{ $info->{size} }) . ')';
  }
  # A type this map has no opinion about is written as declared, and so is its
  # size: BIT(8), TINYINT(1). The mapped names above stay as they are -- an
  # integer alias is INTEGER whatever its size, which is what keeps a key
  # column the rowid alias.
  elsif (!exists $type_map{ lc $type }
      && defined $info->{size}
      && (!ref $info->{size} || ref $info->{size} eq 'ARRAY')) {
    $native = type_with_size($native, $info->{size});
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

version 0.900004

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
primary key, unique constraints, foreign keys), C<CREATE INDEX> and
C<CREATE VIEW>.

=head2 Indexes

C<CREATE INDEX> comes from two declarations: C<sqlite_index>
(L<DBIO::SQLite::Result>) and the index declaration of the result source that
C<idx> of L<DBIO::Cake> and C<indices> write (C<index_declarations>, ADR 0061
in core). The latter gives name, columns and C<unique>, and its own
C<< driver => { sqlite => {...} } >> block gives C<expression> and C<where>.
An empty C<< sqlite => {} >> is the plain index. Where both declarations use the
same name, the canonical declaration wins. An entry that carries only another
driver's block, such as C<< pg => { where => ... } >>, and an unknown key in the
own block are refused with an exception naming the index (maintainer decision
2026-10-12, C<index_declarations_for> of L<DBIO::ResultSource>); the
diff builds its desired model from this DDL and refuses the same.

An index over exactly the columns of a unique constraint of the same table is
not written, plain or declared C<unique>: the C<UNIQUE> line already has the
index SQLite keeps for it, and a second one is a duplicate. The
columns must be the same list in the same order, and an index with an
expression or a C<where> is another object and is written.

=head2 Identifiers

Every name is written in double quotes -- the table, its columns, the columns
of a key or a unique constraint, the table and the columns a foreign key points
at, an index, a view:

    CREATE TABLE "order" (
      "id" INTEGER PRIMARY KEY NOT NULL,
      "group" VARCHAR(20) NOT NULL,
      "customer_id" INTEGER NOT NULL,
      UNIQUE ("group"),
      FOREIGN KEY ("customer_id") REFERENCES "customer"("id")
    );

    CREATE INDEX "index" ON "order" ("customer_id");

Always, and not only where a name needs it: a reserved word has the shape of
any other name, and written bare C<CREATE TABLE order (...)> is a syntax error.
A double quote inside a name is doubled (L<DBIO::SQLite::Util/quote_identifier>).
SQLite does not fold the letter case of a name, so the quotes change nothing
about which table or column is meant: C<"Item"> is the table C<Item>, and a
statement that names it C<item> finds it as before.

A table or view name given as a string is one name. SQLite has no schemas to
qualify it with, so a string with a dot in it -- C<< table('other.t') >> -- is
refused, naming the table and the scalar-ref form below, before a statement is
written; the foreign keys, the indexes and the desired model of a diff go
through this method and so refuse the same. A virtual view has no database
object and no name to refuse.

Three things are not names and are written as the schema gives them:

=over 4

=item * a table or view name given as a B<scalar ref>, which is literal SQL by
the schema's own declaration -- C<< __PACKAGE__->table(\'cd') >> is written
C<CREATE TABLE cd>, C<< __PACKAGE__->table(\'main.cd') >> is written
C<CREATE TABLE main.cd> and creates the table C<cd>. The same text names the
table for its indexes and behind the C<REFERENCES> of a foreign key that points
at it. Nothing is made of it: SQLite takes no schema prefix behind
C<REFERENCES>, so a key cannot point at a table that is named with one;

=item * the C<expression> and the C<where> of a C<sqlite_indexes> entry
(L<DBIO::SQLite::Result>) and a view's definition, which are SQL;

=item * a column's type, and a default given as a scalar ref.

=back

This is about the DDL. The queries of the ORM are written by the SQL maker,
and how those quote a name is its business and that of the C<quote_names>
connect attribute, not this module's.

A database deployed by an earlier version has its names bare in the statements
C<sqlite_master> keeps. They are the same tables, columns and indexes, and
L<DBIO::Deploy::Base/upgrade> finds nothing to do for them
(L<DBIO::SQLite::Diff::Index/What counts as a changed index>).

=head2 Column sizes

A column's C<size> is written into its type: a length for C<varchar>, C<char>,
C<character> and every type the driver has no name of its own for -- C<bit>
with C<< size => 8 >> is C<BIT(8)>, C<tinyint> with C<< size => 1 >>
C<TINYINT(1)> -- and precision and scale as C<< size => [ 10, 2 ] >> for
C<numeric> and C<decimal>. An integer alias SQLite maps to C<INTEGER>
(C<bigint>, C<smallint>, C<int>) is C<INTEGER> whatever its size, which keeps a
key column the rowid alias. L<DBIO::SQLite::Introspect> reads the size back
out of the type, so a deploy diffs empty against its own declaration.

SQLite does B<not enforce> a declared length: eleven characters are stored in
a C<CHARACTER(10)>, and the driver writes no C<CHECK> constraint to change
that (maintainer decision 2026-10-12). The size is the declared type, and
what the column is reported as, nothing more.

=head2 Column defaults

A column's C<default_value> is written after C<DEFAULT> in one of two ways:

    default_value => 5                       # DEFAULT 5
    default_value => "it's"                  # DEFAULT 'it''s'
    default_value => '007'                   # DEFAULT '007' in a char, varchar
                                             # or text column, DEFAULT 007 in
                                             # an integer one
    default_value => \'CURRENT_TIMESTAMP'    # DEFAULT CURRENT_TIMESTAMP
    default_value => \"(datetime('now'))"    # DEFAULT (datetime('now'))

A plain value is a value, and the column says of which kind. In a column with
TEXT affinity -- one whose type, as it is written into the C<CREATE TABLE>,
holds C<CHAR>, C<CLOB> or C<TEXT> and no C<INT>
(L<DBIO::SQLite::Util/type_affinity>) -- it is a string and is always written as
a string literal, with every apostrophe in it doubled, also when it looks like a
number: bare, C<DEFAULT 007> would give every row the text C<7>. In any other
column a number is written bare and anything else as that string literal. Either
way the column's default is the value that was declared
(L<DBIO::SQLite::Util/default_literal_sql>). A scalar ref is literal SQL and
goes into the statement as it is -- an expression needs its own parentheses, as
SQLite's grammar asks for them.

A database deployed by an earlier version has the digits of such a default
bare in its text columns. Where that is the same default -- an integer without
a leading zero, C<DEFAULT 10> -- the next L<DBIO::Deploy::Base/upgrade> finds
nothing to do. Where it is not -- C<DEFAULT 007>, C<DEFAULT 1.50> -- it rebuilds
the table with the default that was declared; the rows that are there keep what
they hold. L<DBIO::SQLite::Diff::Column/What counts as a changed column> has
the rule.

=head2 Foreign keys and their actions

A C<belongs_to> is written as a C<FOREIGN KEY (...) REFERENCES ...> table
constraint, unless it sets C<< is_foreign_key_constraint => 0 >>. The
C<on_delete> and C<on_update> attributes of the relationship follow it as
C<ON DELETE> / C<ON UPDATE>, as declared:

    __PACKAGE__->belongs_to(owner => 'MyApp::DB::Result::Owner', 'owner_id',
      { on_delete => 'CASCADE', on_update => 'CASCADE' });

    # FOREIGN KEY ("owner_id") REFERENCES "owner"("id") ON DELETE CASCADE ON UPDATE CASCADE

=over 4

=item * An attribute that is absent, C<undef> or C<''> writes no clause. The
key then has SQLite's default, C<NO ACTION>.

=item * The value is checked (L<DBIO::SQLite::Util/foreign_key_action>): C<SET
NULL>, C<SET DEFAULT>, C<CASCADE>, C<RESTRICT> or C<NO ACTION>, in either letter
case and with any white space between the words. It is written as declared (white space collapsed).
C<NO ACTION> is the default of a key and writes no clause. Any other word dies
with a L<DBIO::Exception> that names the value and the relationship, so a typo
is refused when the DDL is generated.

=item * Nothing is derived from the other side of the relationship. A
C<has_many> has C<< cascade_delete => 1 >> by default, and that is the ORM
deleting the related rows; it does not make the key C<ON DELETE CASCADE>. The
autodetection L<DBIO::Relationship::Base> describes for C<on_delete> /
C<on_update> is not performed.

=back

The keys of a table are written in the order of the names of their
relationships, so the statement is the same every time it is generated.

A key that several relationships declare -- the same columns, the same target
table and columns, the same actions in whichever letter case -- is one key and
is written once, by the first of them. Relationships over the same columns and
target that declare different actions each write their own line, and SQLite
keeps a foreign key for each; whether that should be refused instead is open.

SQLite runs these actions only on a connection that enforces foreign keys --
C<PRAGMA foreign_keys = ON>, see
L<DBIO::SQLite::Storage/connect_call_use_foreign_keys>.

An action reaches a table when the table is created, by an install or by an
upgrade that adds it, and it reaches a table that is already deployed by the
next L<DBIO::Deploy::Base/upgrade>: L<DBIO::SQLite::Diff> compares the foreign
keys of a table that exists on both sides -- columns, target and both actions
-- and rebuilds the table when they differ
(L<DBIO::SQLite::Diff/When a table is rebuilt>). So a database deployed before
this module wrote C<ON DELETE> / C<ON UPDATE> gets the actions its
relationships declare, and adding, changing or removing C<on_delete> /
C<on_update>, or C<is_foreign_key_constraint>, is picked up. SQLite has no
statement that changes a foreign key in place, so each such change is a
rebuild of the table that holds the key.

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
